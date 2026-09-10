import math

# =========================
# Units / constants
# =========================
g = 9.80665
ft_to_m = 0.3048
kt_to_mps = 0.514444
rho0 = 1.225  # kg/m^3 at sea level ISA

# =========================
# ISA atmosphere (up to ~20 km)
# Returns: T [K], p [Pa], rho [kg/m^3], a [m/s]
# =========================
def isa_atmosphere(h_m):
    # Simple ISA: troposphere to 11 km, then isothermal to 20 km
    # Good enough for conceptual TTC.
    R = 287.05287
    gamma = 1.4
    T0 = 288.15
    p0 = 101325.0
    L = -0.0065  # K/m (troposphere)

    if h_m < 11000.0:
        T = T0 + L * h_m
        p = p0 * (T / T0) ** (-g / (L * R))
    else:
        T11 = T0 + L * 11000.0
        p11 = p0 * (T11 / T0) ** (-g / (L * R))
        T = T11
        p = p11 * math.exp(-g * (h_m - 11000.0) / (R * T))

    rho = p / (R * T)
    a = math.sqrt(gamma * R * T)
    return T, p, rho, a

# =========================
# Aircraft / aero assumptions
# =========================
m_to = 35000.0  # kg (MTOW cap in the project)
W = m_to * g    # N

WS = 5000.0     # N/m^2  <-- assumed W/S
S = W / WS      # wing area from W/S

TW = 0.33       # <-- assumed T/W at sea-level static (total thrust / weight)
T_sl_total = TW * W  # N, total takeoff thrust at sea level static (all engines)

# Drag polar (conceptual)
CD0_clean = 0.022
dCD0_takeoff = 0.015  # extra drag in takeoff/cleanup segment
AR = 9.5
e = 0.82
k = 1.0 / (math.pi * AR * e)

# CLmax for takeoff config (used only to estimate V2)
CLmax_TO = 2.0

# =========================
# Thrust lapse model (very simplified)
# =========================
def thrust_available(h_m, mach, thrust_mode="CLB"):
    """
    Returns thrust [N].
    thrust_mode: "TO" or "CLB"
    """
    _, _, rho, _ = isa_atmosphere(h_m)
    sigma = rho / rho0

    # Rating factor: climb thrust slightly below takeoff rating
    rating = 1.00 if thrust_mode == "TO" else 0.90

    # Simple lapse: turbofan thrust decreases with density and Mach
    lapse = (sigma ** 0.80) * max(0.10, (1.0 - 0.30 * mach))
    return T_sl_total * rating * lapse

# =========================
# Speed schedule definition
# We command TAS; schedule specified as IAS/Mach.
# =========================
def vstall_to_ias(mass_kg):
    # Use sea-level density for a representative Vstall_TO estimate
    W_local = mass_kg * g
    Vstall = math.sqrt(2.0 * W_local / (rho0 * S * CLmax_TO))  # m/s (TAS at SL)
    # At sea level, IAS ~ TAS
    return Vstall


Vstall_sl = vstall_to_ias(m_to)
V2 = 1.20 * Vstall_sl
V2p10 = V2 + 10.0 * kt_to_mps

Vfs = 180.0 * kt_to_mps  # assumed "flaps-up" IAS target during cleanup
IAS_250 = 250.0 * kt_to_mps
IAS_300 = 300.0 * kt_to_mps
M_climb = 0.74

h_liftoff = 0.0
h_400ft = 400.0 * ft_to_m
h_1500ft = 1500.0 * ft_to_m
h_10kft = 10000.0 * ft_to_m
h_target = 35000.0 * ft_to_m  # FL350 in meters


def tas_from_ias(ias_mps, h_m):
    # Treat IAS ~ EAS. TAS = EAS / sqrt(sigma).
    _, _, rho, _ = isa_atmosphere(h_m)
    sigma = rho / rho0
    return ias_mps / math.sqrt(max(1e-6, sigma))


def tas_from_mach(mach, h_m):
    _, _, _, a = isa_atmosphere(h_m)
    return mach * a


def commanded_tas(h_m):
    """
    Piecewise schedule:
      - 0 to 400 ft: hold V2+10 (IAS)
      - 400 to 1500 ft: accelerate linearly in IAS from V2+10 to Vfs
      - 1500 ft to 10k: 250 KIAS
      - 10k to crossover: 300 KIAS
      - crossover to FL350: Mach 0.74
    """
    if h_m <= h_400ft:
        return tas_from_ias(V2p10, h_m), "TOCFG", "TO"
    elif h_m <= h_1500ft:
        frac = (h_m - h_400ft) / max(1e-6, (h_1500ft - h_400ft))
        ias = V2p10 + frac * (Vfs - V2p10)
        return tas_from_ias(ias, h_m), "TOCFG", "TO"
    elif h_m <= h_10kft:
        return tas_from_ias(IAS_250, h_m), "CLEAN", "CLB"
    else:
        # above 10k: either 300 KIAS or Mach 0.74 depending on crossover
        return None, None, None  # handled with crossover logic below

# =========================
# Compute crossover altitude for 300 KIAS <-> Mach 0.74
# Find h where Mach( TAS_from_IAS(300) ) == 0.74
# =========================
def mach_at_ias(h_m, ias_mps):
    V = tas_from_ias(ias_mps, h_m)
    _, _, _, a = isa_atmosphere(h_m)
    return V / a


def find_crossover_alt(h_low_m=10000*ft_to_m, h_high_m=45000*ft_to_m):
    target = M_climb
    lo, hi = h_low_m, h_high_m
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        f_lo = mach_at_ias(lo, IAS_300) - target
        f_mid = mach_at_ias(mid, IAS_300) - target
        if f_lo * f_mid <= 0:
            hi = mid
        else:
            lo = mid
    return 0.5 * (lo + hi)


h_xover = find_crossover_alt()


def commanded_tas_above_10k(h_m):
    if h_m < h_xover:
        return tas_from_ias(IAS_300, h_m), "CLEAN", "CLB"
    else:
        return tas_from_mach(M_climb, h_m), "CLEAN", "CLB"

# =========================
# Drag model
# =========================
def drag_force(h_m, V_tas, config="CLEAN"):
    _, _, rho, _ = isa_atmosphere(h_m)
    q = 0.5 * rho * V_tas**2

    CD0 = CD0_clean + (dCD0_takeoff if config == "TOCFG" else 0.0)

    # Assume small climb angle => L ~ W, so CL = W / (q S)
    CL = W / max(1e-6, (q * S))
    CD = CD0 + k * CL**2
    D = q * S * CD
    return D, CL, CD

# =========================
# Time integration
# Using energy equation:
#   Ps = (T - D)*V / W
#   dh/dt = Ps - (V/g)*(dV/dt)
# We command V toward schedule via a first-order lag with time constant tau.
# =========================
def simulate_time_to_climb(dt=0.5, tau=12.0, t_max=4000.0):
    h = h_liftoff
    t = 0.0

    # initialize at commanded speed
    Vcmd, cfg, mode = commanded_tas(h)
    V = Vcmd

    history = []

    while h < h_target and t < t_max:
        if h <= h_10kft:
            Vcmd, cfg, mode = commanded_tas(h)
        else:
            Vcmd, cfg, mode = commanded_tas_above_10k(h)

        # simple speed control (you can add accel limits if you want)
        dVdt = (Vcmd - V) / max(1e-6, tau)

        # atmosphere and Mach
        _, _, _, a = isa_atmosphere(h)
        mach = V / max(1e-6, a)

        # forces
        T = thrust_available(h, mach, thrust_mode=mode)
        D, CL, CD = drag_force(h, V, config=cfg)

        # specific excess power
        Ps = (T - D) * V / W  # m/s

        # climb rate from energy equation
        dhdt = Ps - (V / g) * dVdt

        # Prevent non-physical descent if schedule demands too much
        # (If this triggers, your design point likely fails TTC / climb capability.)
        dhdt = max(0.0, dhdt)

        # integrate
        V += dVdt * dt
        h += dhdt * dt
        t += dt

        history.append((t, h, V, Vcmd, mach, T, D, CL, CD, dhdt))

        # quick stop if stuck
        if len(history) > 50:
            if all(row[-1] < 0.1 for row in history[-50:]):  # <0.1 m/s climb rate
                break

    return t, h, h_xover, history

# =========================
# Run
# =========================
if __name__ == "__main__":
    t_sec, h_final, h_xover_m, hist = simulate_time_to_climb()

    print("=== Assumed sizing ===")
    print(f"MTOW mass         : {m_to:,.0f} kg")
    print(f"W/S               : {WS:,.0f} N/m^2  ->  S = {S:,.1f} m^2")
    print(f"T/W (SL static)   : {TW:.2f}  ->  T_sl,total = {T_sl_total/1000:,.1f} kN")
    print()
    print("=== Schedule params (derived/assumed) ===")
    print(f"Vstall_TO (SL)    : {Vstall_sl/kt_to_mps:,.1f} kt")
    print(f"V2                : {V2/kt_to_mps:,.1f} kt")
    print(f"V2+10             : {V2p10/kt_to_mps:,.1f} kt")
    print(f"Vfs (assumed)     : {Vfs/kt_to_mps:,.1f} kt")
    print(f"Crossover altitude: {h_xover_m/ft_to_m:,.0f} ft (300 KIAS == M0.74)")
    print()
    print("=== Result ===")
    print(f"Reached altitude  : {h_final/ft_to_m:,.0f} ft")
    print(f"Time to climb     : {t_sec/60.0:,.2f} min")

    # If you want a quick sanity check on final climb rate:
    if hist:
        dhdt_end = hist[-1][-1]
        print(f"End climb rate    : {dhdt_end:,.2f} m/s ({dhdt_end*196.85:,.0f} ft/min)")
