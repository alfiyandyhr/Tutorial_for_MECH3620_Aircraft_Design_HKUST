import numpy as np
import matplotlib.pyplot as plt
from mech3620_models import US_Standard_1976_Atmosphere


# ==========
# Constants
# ==========
g = 9.81  # m/s^2
KG_TO_LB = 2.20462
LB_TO_KG = 1 / KG_TO_LB
FT_TO_M = 0.3048
M_TO_FT = 1 / FT_TO_M
NMI_TO_KM = 1.852


# ====================
# Helper Functions
# ====================


def get_empty_weight_fraction(W_TO_kg):
    """
    Uses Raymer's equation for Jet Transport: We/W0 = A * W0^C
    Coefficients are typically for Imperial units (lb).
    """
    # Raymer Jet Transport Coefficients (Imperial)
    A = 1.02
    C = -0.06
    
    W_TO_lb = W_TO_kg * KG_TO_LB
    
    # Calculate fraction
    We_frac = A * (W_TO_lb ** C)
    
    return We_frac


def get_mission_fuel_fraction(SFC_cruise_per_s, SFC_loiter_per_s, LD_cruise, LD_loiter, v_cruise_mps,
                              dist_leg_1_m, dist_leg_2_m, dist_alternate_m, time_hold_s):
    """
    Calculates the total weight ratio (W_final / W_initial) for the mission using Roskam's approximation

    # Range Requirements: HKG -> CRK (Clark) is approx 1050 km
    # Additional Requirement: Round trip without refueling (dist_leg_1 + dist_leg_2)

    # Reserve Requirements (ICAO)
    # 1. Alternate (Assume 200 nmi / ~370 km)
    # 2. Holding (30-45 mins)
    # 3. Contingency (Usually 5% of trip fuel, handled via safety factor)

    Mission Profile:
    1. Warmup (Leg 1)
    2. Taxi (Leg 1)
    3. Takeoff (Leg 1)
    4. Climb (Leg 1)
    5. Cruise (Leg 1)
    6. Descent (Leg 1)
    7. Landing (Outstation - No Refuel)
    8. Warmup (Leg 2) - conservative, engine might be off, but APU might still be on
    9. Taxi (Leg 2)
    10. Takeoff (Leg 2)
    11. Climb (Leg 2)
    12. Cruise (Leg 2)
    13. Alternate (Cruise)
    14. Loiter (Hold)
    15. Landing (HKG)

    """

    beta = {}

    # Segment 1: Warmup (Leg 1)
    beta['w_1'] = 0.990
    
    # Segment 2: Taxi (Leg 1)
    beta['w_2'] = 0.990

    # Segment 3: Takeoff (Leg 1)
    beta['w_3'] = 0.995

    # Segment 4: Climb (Leg 1)
    beta['w_4'] = 0.980
    
    # Segment 5: Cruise (Leg 1) - Breguet
    # Wi+1/Wi = exp(-R * SFC / (V * L/D))
    beta['w_5'] = np.exp(-(dist_leg_1_m * SFC_cruise_per_s) / (v_cruise_mps * LD_cruise))
    
    # Segment 6: Descent (Leg 1)
    beta['w_6'] = 0.990

    # Segment 7: Landing (Outstation - No Refuel)
    beta['w_7'] = 0.992

    # Segment 8: Warmup (Leg 2)
    beta['w_8'] = 0.990

    # Segment 9: Taxi (Leg 2)
    beta['w_9'] = 0.990

    # Segment 10: Takeoff (Leg 2)
    beta['w_10'] = 0.995

    # Segment 11: Climb (Leg 2)
    beta['w_11'] = 0.980

    # Segment 12: Cruise (Leg 2) - Breguet
    beta['w_12'] = np.exp(-(dist_leg_2_m * SFC_cruise_per_s) / (v_cruise_mps * LD_cruise))
    
    # Segment 13: Alternate (Cruise to alternate)
    beta['w_13'] = np.exp(-(dist_alternate_m * SFC_cruise_per_s) / (v_cruise_mps * LD_cruise))
    
    # Segment 14: Loiter (Endurance, hold)
    # Wi+1/Wi = exp(-E * SFC / L/D)
    beta['w_14'] = np.exp(-(time_hold_s * SFC_loiter_per_s) / LD_loiter)
    
    # Segment 10: Landing (HKG)
    beta['w_15'] = 0.992

    # Total Mission Weight Ratio (Product of all segments)
    # Mff = W_landing / W_takeoff
    Mff = float(np.prod(list(beta.values())))

    # Fuel Fraction = 1 - Mff
    # Add 1% for trapped fuel + 5% contingency on calculated fuel
    fuel_fraction = (1 - Mff) * 1.06

    return fuel_fraction, beta


def calc_mtow_req(W_payload, W_crew, We_frac, Wf_frac):
    """
    The Governing Equation:
    W0 = (W_payload + W_crew) / (1 - Wf/W0 - We/W0)
    """
    denominator = 1 - Wf_frac - We_frac
    if denominator <= 0:
        return np.inf  # Impossible design
    return (W_payload + W_crew) / denominator


def solve_fixed_point(w_guess_kg, W_payload, W_crew, Wf_frac, max_iter=50, tol=1e-4):
    history = []
    w_current = w_guess_kg
    
    for i in range(max_iter):
        history.append(w_current)
        
        # 1. Calculate Empty Weight Fraction based on current Guess
        We_frac = get_empty_weight_fraction(w_current)
        
        # 2. Calculate new MTOW
        w_new = calc_mtow_req(W_payload, W_crew, We_frac, Wf_frac)
        
        # 3. Check Convergence
        err = abs((w_new - w_current) / w_current)
        if err < tol:
            history.append(w_new)
            return w_new, history, i
            
        w_current = w_new
        
    return w_current, history, max_iter


def residual_func(w_guess_kg, W_payload, W_crew, Wf_frac):

    We_frac = get_empty_weight_fraction(w_guess_kg)
    
    # Rearranging W0 = (W_pay + W_crew) / (1 - Wf - We)
    # to: W0 * (1 - Wf - We) - (W_pay + W_crew) = 0
    
    lhs = w_guess_kg * (1 - Wf_frac - We_frac)
    rhs = W_payload + W_crew
    return lhs - rhs


def solve_bisection(a, b, W_payload, W_crew, Wf_frac, max_iter=50, tol=1e-4):
    history = []
    
    if residual_func(a, W_payload, W_crew, Wf_frac) * residual_func(b, W_payload, W_crew, Wf_frac) >= 0:
        print("Bisection method fails: Root not bracketed.")
        return None, [], 0
        
    for i in range(max_iter):
        c = (a + b) / 2.0
        history.append(c)
        
        res_c = residual_func(c, W_payload, W_crew, Wf_frac)
        
        if abs(res_c) < tol or (b - a) / 2 < tol:
            return c, history, i
            
        if residual_func(a, W_payload, W_crew, Wf_frac) * res_c < 0:
            b = c
        else:
            a = c
            
    return c, history, max_iter


# =============================================
# Wrapper for Preliminary Weight Estimation
# =============================================


def perform_preliminary_weight_estimation(
        engine_data: dict, aero_data: dict, mission_req: dict,
        W_guess_fp_kg=20000.0, W_a_bi_kg=10000.0, W_b_bi_kg=60000.0,
        verbose=True, plot=True
):
    
    # Unpacking parameters
    SFC_cruise_per_s = engine_data['SFC_cruise_per_hour'] / 3600.0
    SFC_loiter_per_s = engine_data['SFC_loiter_per_hour'] / 3600.0
    LD_max = aero_data['LD_max']
    LD_cruise = aero_data['LD_cruise_factor'] * LD_max
    LD_loiter = 1.0 * LD_max
    n_pax = mission_req['n_pax']
    W_pax_unit_kg = mission_req['W_pax_unit_kg']
    n_crew = mission_req['n_crew']
    W_crew_unit_kg = mission_req['W_crew_unit_kg']
    cruise_mach = mission_req['cruise_mach']
    cruise_altitude_m = mission_req['cruise_altitude_ft'] * FT_TO_M
    dist_leg_1_m = mission_req['dist_leg_1_km'] * 1000.0
    dist_leg_2_m = mission_req['dist_leg_2_km'] * 1000.0
    dist_alternate_m = mission_req['dist_alternate_km'] * 1000.0
    time_hold_s = mission_req['time_hold_min'] * 60

    # Speed at cruise
    v_sound = US_Standard_1976_Atmosphere().compute_constants(cruise_altitude_m, 0.0)['v_sound']
    v_cruise_mps = cruise_mach * v_sound  # m/s

    # Fuel weight fraction
    Wf_frac, betas = get_mission_fuel_fraction(SFC_cruise_per_s, SFC_loiter_per_s, LD_cruise, LD_loiter, v_cruise_mps,
                                               dist_leg_1_m, dist_leg_2_m, dist_alternate_m, time_hold_s)

    # Payload: n_pax * W_pax_unit_kg; i.e., 70 * (90 + 15)
    W_payload = n_pax * W_pax_unit_kg  # kg

    # Crew: n_crew * W_crew_unit_kg; i.e., 4 * (90 + 15)
    W_crew = n_crew * W_crew_unit_kg  # kg
    
    # --- Run Fixed Point ---
    mtow_fp, hist_fp, iters_fp = solve_fixed_point(W_guess_fp_kg, W_payload, W_crew, Wf_frac)

    # --- Run Bisection ---
    mtow_bi, hist_bi, iters_bi = solve_bisection(W_a_bi_kg, W_b_bi_kg, W_payload, W_crew, Wf_frac)

    # MTOW is taken as average between the two methods ---
    mtow = 0.5 * (mtow_fp + mtow_bi)

    We_frac_final = get_empty_weight_fraction(mtow)
    
    W_empty = mtow * We_frac_final
    W_fuel = mtow * Wf_frac

    weight_breakdown = {'payload': W_payload,
                        'crew': W_crew,
                        'fuel': W_fuel,
                        'empty': W_empty,
                        'total': mtow}

    if verbose:
        print("-" * 50)
        print("PRELIMINARY WEIGHT ESTIMATION: PROJECT RJ")
        print(f"Mission: Round Trip HKG-CRK-HKG ({dist_leg_1_m/1000.0} km x 2)")
        print(f"Payload: {W_payload} kg ({n_pax} Pax)")
        print("-" * 50)

        print(f"[Fixed Point] MTOW: {mtow_fp:.2f} kg ({iters_fp} iterations)")
        print(f"[Bisection]   MTOW: {mtow_bi:.2f} kg ({iters_bi} iterations)")
        print(f"[Average]     MTOW: {mtow:.2f} kg")

        # --- Check Constraints ---
        MAX_MTOW_CONSTRAINT = 35000.0
        print("-" * 50)
        if mtow < MAX_MTOW_CONSTRAINT:
            print("SUCCESS: Design is under the 35,000 kg limit.")
            print(f"Margin: {MAX_MTOW_CONSTRAINT - mtow:.2f} kg")
        else:
            print("WARNING: Design exceeds 35,000 kg limit!")
            print(f"Excess: {mtow - MAX_MTOW_CONSTRAINT:.2f} kg")
            print("Suggestion: Improve L/D, Reduce SFC, or use composites (reduce A).")

        print("-" * 50)
        print("WEIGHT BREAKDOWN:")
        print(f"  Payload: {W_payload:.1f} kg")
        print(f"  Crew:    {W_crew:.1f} kg")
        print(f"  Fuel:    {W_fuel:.1f} kg (Fraction: {Wf_frac:.3f})")
        print(f"  Empty:   {W_empty:.1f} kg (Fraction: {We_frac_final:.3f})")
        print(f"  TOTAL:   {mtow:.1f} kg")
        print("-" * 50)
        print("FUEL ECONOMY:")
        print(f"  Fuel weight per seat-kilometer: {W_fuel/(n_pax * (dist_leg_1_m + dist_leg_2_m + dist_alternate_m)/1000.0):.6f} kg/seat-km")

    # --- Plotting ---
    if plot:
        plt.figure(figsize=(10, 5))
        
        # Plot Fixed Point
        plt.subplot(1, 2, 1)
        plt.plot(hist_fp, 'o-', label='Fixed Point')
        plt.axhline(mtow_fp, color='k', linestyle='--', alpha=0.5, label='Converged')
        plt.title("Fixed Point Iteration")
        plt.xlabel("Iteration")
        plt.ylabel("MTOW (kg)")
        plt.grid(True)
        plt.legend(loc='lower right')
        
        # Plot Bisection
        plt.subplot(1, 2, 2)
        plt.plot(hist_bi, 'x-', color='orange', label='Bisection')
        plt.axhline(mtow_bi, color='k', linestyle='--', alpha=0.5, label='Converged')
        plt.title("Bisection Method")
        plt.xlabel("Iteration")
        plt.grid(True)
        plt.legend(loc='lower right')
        
        plt.tight_layout()
        plt.show()

    return weight_breakdown


# ===============================
# Main Execution & Visualization
# ===============================


if __name__ == "__main__":
    
    engine_data = {
        'SFC_cruise_per_hour': 0.5,
        'SFC_loiter_per_hour': 0.4
    }

    aero_data = {
        'LD_max': 14.0,
        'LD_cruise_factor': 0.866
    }

    mission_req = {
        'n_pax': 70,
        'W_pax_unit_kg': 90.0 + 15.0,
        'n_crew': 4,
        'W_crew_unit_kg': 90.0 + 15.0,
        'cruise_mach': 0.78,
        'cruise_altitude_ft': 35000.0,
        'dist_leg_1_km': 1050.0,
        'dist_leg_2_km': 1050.0,
        'dist_alternate_km': 200 * NMI_TO_KM,
        'time_hold_min': 45.0
    }

    perform_preliminary_weight_estimation(engine_data, aero_data, mission_req,
                                          W_guess_fp_kg=20000.0, W_a_bi_kg=10000.0, W_b_bi_kg=60000.0,
                                          verbose=True, plot=True)
