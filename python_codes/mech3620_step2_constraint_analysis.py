import numpy as np
import matplotlib.pyplot as plt
from mech3620_models import (
    US_Standard_1976_Atmosphere,
    calc_TOP_given_BFL_requirement,
    calc_thrust_lapse
)
from mech3620_step1_preliminary_weight_estimation import get_mission_fuel_fraction

# ==========
# Constants
# ==========
g = 9.81
FT_TO_M = 0.3048
NMI_TO_KM = 1.852


# =====================
# Constraint Equations
# =====================


def constraint_takeoff(ws_range, takeoff_field_length_m, n_engine, CL_MAX_TO):
    """
    Constraint 1: Takeoff Field Length
    """
    rho0 = 1.225  # kg/m3
    rho_to = US_Standard_1976_Atmosphere().compute_constants(altitude=0.0, delta_T_celsius=15)['rho']
    sigma_to = rho_to / rho0

    # Required Takeoff Parameter
    TOP_lbf_p_ft2 = calc_TOP_given_BFL_requirement(takeoff_field_length_m, n_engine)
    NPM2_TO_LBfPFT2 = 0.0929 / 4.448  # lbf per ft^2
    tw_takeoff = ws_range * NPM2_TO_LBfPFT2 / (sigma_to * CL_MAX_TO * TOP_lbf_p_ft2)
    return tw_takeoff


def constraint_climb(ws_range, type, n_engine, Weight_factor, is_MCT, is_OEI, CD0_clean, AR_wing, CL_max_climb, D_aero_coeffs_at_climb):
    """
    Constraint 2: Climb performances

    type: type of climb based on FAR 25 requirements
    n_engine: number of engines
    Weight_factor: cumulative weight fraction compared to the takeoff weight (beta = beta1 * beta2 * ... * beta_n)
    is_MCT: is maximum continuous thrust
    is_OEI: is one engine inoperative
    """

    if type == 'Takeoff Climb OEI':
        """
        FAR 25.111
         > OEI, remaining engines at takeoff thrust/power
         > Takeoff flaps, retracted landing gear
         > Maximum takeoff weight
        """
        k_s = 1.2
        aero = D_aero_coeffs_at_climb['flaps_at_5_deg_gear_up']
        if n_engine == 2:
            gamma = 0.012
        elif n_engine == 3:
            gamma = 0.015
        elif n_engine == 4:
            gamma = 0.017
        else:
            raise ValueError('n_engine > 4 is not supported')

    elif type == 'Transition Climb OEI':
        """
        FAR 25.121
         > OEI, remaining engines at takeoff thrust/power
         > Takeoff flaps, landing gear down
         > Maximum takeoff weight
        """
        k_s = 1.15
        aero = D_aero_coeffs_at_climb['flaps_at_10_deg_gear_down']
        if n_engine == 2:
            gamma = 0.000
        elif n_engine == 3:
            gamma = 0.003
        elif n_engine == 4:
            gamma = 0.005
        else:
            raise ValueError('n_engine > 4 is not supported')

    elif type == 'Second Climb OEI':
        """
        FAR 25.121
         > OEI, remaining engines at takeoff thrust/power
         > Takeoff flaps, retracted landing gear
         > Maximum takeoff weight
        """
        k_s = 1.2
        aero = D_aero_coeffs_at_climb['flaps_at_5_deg_gear_up']
        if n_engine == 2:
            gamma = 0.024
        elif n_engine == 3:
            gamma = 0.027
        elif n_engine == 4:
            gamma = 0.030
        else:
            raise ValueError('n_engine > 4 is not supported')

    elif type == 'Enroute Climb OEI':
        """
        FAR 25.121
         > OEI, remaining engines at takeoff thrust/power
         > Retracted flaps, retracted landing gear
         > Maximum takeoff weight
        """
        k_s = 1.25
        aero = D_aero_coeffs_at_climb['flaps_at_0_deg']
        if n_engine == 2:
            gamma = 0.012
        elif n_engine == 3:
            gamma = 0.015
        elif n_engine == 4:
            gamma = 0.017
        else:
            raise ValueError('n_engine > 4 is not supported')

    elif type == 'Balked Landing Climb AEO':
        """
        FAR 25.119
         > AEO, all engines at takeoff thrust/power
         > Landing flaps, landing gear down
         > Maximum landing weight
        """
        k_s = 1.3
        aero = D_aero_coeffs_at_climb['flaps_at_10_deg_gear_down']
        gamma = 0.032

    elif type == 'Balked Landing Climb OEI':
        """
        FAR 25.121
         > OEI, remaining engines at takeoff thrust/power
         > Approach flaps, retracted landing gear (Prof. Rhea's lecture note made a mistake here)
         > Maximum landing weight
        """
        k_s = 1.5
        aero = D_aero_coeffs_at_climb['flaps_at_10_deg_gear_up']
        # aero = D_aero_coeffs_at_climb['flaps_at_10_deg_gear_down']
        if n_engine == 2:
            gamma = 0.021
        elif n_engine == 3:
            gamma = 0.024
        elif n_engine == 4:
            gamma = 0.027
        else:
            raise ValueError('n_engine > 4 is not supported')

    # Drag
    Delta_CD0 = aero[0]
    e = aero[1]
    CD0_climb = CD0_clean + Delta_CD0
    K_climb = 1 / (np.pi * e * AR_wing)  # induced drag factor

    # OEI
    OEI_factor = n_engine / (n_engine - 1) if is_OEI else 1.0

    # Maximum continuous thrust
    MCT_factor = 1 / 0.94 if is_MCT else 1.0

    # General Climb Constraint
    tw_climb = k_s**2 * CD0_climb / CL_max_climb + K_climb * CL_max_climb / k_s**2 + gamma
    tw_climb = (1 / 0.8) * MCT_factor * OEI_factor * Weight_factor * tw_climb

    return np.full_like(ws_range, tw_climb)


def constraint_landing(beta_land, landing_field_length_m, CL_max_land):
    """
    Constraint 3: Landing Field Length
    Using the Prof. Rhea's Lecture Note formula structure for landing wing Loading (N/m^2).
    
    Formula: S_ground = 5 * (W/S) / (g * sigma * CL_max)
    S_FL = (S_ground + S_air_distance) / 0.6
    """

    rho0 = 1.225  # kg/m3
    rho_land = US_Standard_1976_Atmosphere().compute_constants(altitude=0.0, delta_T_celsius=15)['rho']
    sigma_land = rho_land / rho0
    
    # Air distance approx (S_a) for jet
    S_a = 300.0
    
    # Available ground roll distance
    # S_ground_available = (s_FL * 0.6) - S_a
    s_ground_avail = (landing_field_length_m * 0.6) - S_a
    
    # Solve for Wing Loading (kg/m^2)
    # s_ground = 5 * (W_L/S) / (sigma * g * CL)
    # (W_L/S) = s_ground * sigma * g * CL / 5
    
    ws_land_at_landing_weight = (s_ground_avail * sigma_land * g * CL_max_land) / 5.0
    
    # Convert back to MTOW basis
    ws_mtow_limit = ws_land_at_landing_weight / beta_land

    print(sigma_land, CL_max_land, g)
    
    return ws_mtow_limit


def constraint_cruise(ws_range, cruise_altitude_m, cruise_mach, beta, K_clean, CD0_clean):
    """
    Constraint 4: Cruise Speed
    """
    aero_cr = US_Standard_1976_Atmosphere().compute_constants(altitude=cruise_altitude_m, delta_T_celsius=0)
    rho_cr = aero_cr['rho']
    v_sound_cr = aero_cr['v_sound']
    q_cr = 0.5 * rho_cr * (cruise_mach * v_sound_cr)**2

    alpha = calc_thrust_lapse(cruise_altitude_m, cruise_mach * v_sound_cr, delta_T_celsius=0.0, throttle=0.9)

    tw_cruise = (beta / alpha) * ((q_cr * CD0_clean) / (beta * ws_range) + (K_clean * beta / q_cr) * ws_range)
    return tw_cruise


def constraint_ceiling(ws_range, ceiling_altitude_m, beta, K_clean, CD0_clean):
    """
    Constraint 4: Service Ceiling with 0.1% gradient
    """
    G = 0.001  # margin
    aero_ce = US_Standard_1976_Atmosphere().compute_constants(altitude=ceiling_altitude_m, delta_T_celsius=0)
    rho_ce = aero_ce['rho']
    
    q_ce_optimal = beta * ws_range * np.sqrt(K_clean / CD0_clean)
    v_ce = np.sqrt(2 * q_ce_optimal / rho_ce)

    tw_ceil = np.full_like(ws_range, 0.0)
    for i, v in enumerate(v_ce):
        alpha = calc_thrust_lapse(ceiling_altitude_m, v, delta_T_celsius=0.0, throttle=1.0)
        # alpha = (rho_ce / 1.225)**0.8  # does not consider velocity lapse
        tw_ceil[i] = beta / alpha * (2 * np.sqrt(K_clean * CD0_clean) + G)
    return tw_ceil

# ================================
# Wrapper for Constraint Analysis
# ================================


def perform_constraint_analysis(ws_range, engine_data: dict, aero_data: dict, mission_req: dict,
                                plot=True, verbose=True):
    
    # Unpacking parameters
    SFC_cruise_per_s = engine_data['SFC_cruise_per_hour'] / 3600.0
    SFC_loiter_per_s = engine_data['SFC_loiter_per_hour'] / 3600.0
    n_engine = engine_data['n_engine']
    AR_wing = aero_data['AR_wing']
    K_clean = 1.0 / (np.pi * aero_data['e_clean'] * aero_data['AR_wing'])
    CD0_clean = aero_data['CD0_clean']
    LD_max = aero_data['LD_max']
    LD_cruise = aero_data['LD_cruise_factor'] * LD_max
    CL_max_takeoff = aero_data['CL_max_takeoff']
    CL_max_land = aero_data['CL_max_land']
    CL_max_climb = aero_data['CL_max_climb']
    D_aero_coeffs_at_climb = aero_data['D_aero_coeffs_at_climb']
    LD_loiter = 1.0 * LD_max
    cruise_mach = mission_req['cruise_mach']
    cruise_altitude_m = mission_req['cruise_altitude_ft'] * FT_TO_M
    ceiling_altitude_m = mission_req['ceiling_altitude_ft'] * FT_TO_M
    dist_leg_1_m = mission_req['dist_leg_1_km'] * 1000.0
    dist_leg_2_m = mission_req['dist_leg_2_km'] * 1000.0
    dist_alternate_m = mission_req['dist_alternate_km'] * 1000.0
    time_hold_s = mission_req['time_hold_min'] * 60
    takeoff_field_length_m = mission_req['takeoff_field_length_m']
    landing_field_length_m = mission_req['landing_field_length_m']

    # Speed at cruise
    v_sound = US_Standard_1976_Atmosphere().compute_constants(cruise_altitude_m, 0.0)['v_sound']
    v_cruise_mps = cruise_mach * v_sound  # m/s

    # Fuel weight fraction
    Wf_frac, betas = get_mission_fuel_fraction(SFC_cruise_per_s, SFC_loiter_per_s, LD_cruise, LD_loiter, v_cruise_mps,
                                               dist_leg_1_m, dist_leg_2_m, dist_alternate_m, time_hold_s)

    # At the start of the mission segment
    beta_takeoff = betas['w_1'] * betas['w_2']
    beta_land_outstation = betas['w_1'] * betas['w_2'] * betas['w_3'] * betas['w_4'] * betas['w_5'] * betas['w_6']  # Landing weight fraction (tankering)
    beta_cruise = betas['w_1'] * betas['w_2'] * betas['w_3'] * betas['w_4']  # leg 1
    beta_climb = betas['w_1'] * betas['w_2'] * betas['w_3']  # leg 1

    # Calculate Constraints
    ws_land = constraint_landing(beta_land_outstation, landing_field_length_m, CL_max_land)
    ws_range = np.sort(np.unique(np.append(ws_range, ws_land)))
    tw_to = constraint_takeoff(ws_range, takeoff_field_length_m, n_engine, CL_max_takeoff)
    beta_cl1 = 0.99 * beta_climb
    beta_cl2 = 0.99 * beta_cl1
    beta_cl3 = 0.98 * beta_cl2
    beta_cl4 = 0.98 * beta_cl3
    tw_cl1 = constraint_climb(ws_range, 'Takeoff Climb OEI', n_engine=2, Weight_factor=beta_cl1, is_MCT=False, is_OEI=True,
                              CD0_clean=CD0_clean, AR_wing=AR_wing, CL_max_climb=CL_max_climb,
                              D_aero_coeffs_at_climb=D_aero_coeffs_at_climb)
    tw_cl2 = constraint_climb(ws_range, 'Transition Climb OEI', n_engine=2, Weight_factor=beta_cl2, is_MCT=False, is_OEI=True,
                              CD0_clean=CD0_clean, AR_wing=AR_wing, CL_max_climb=CL_max_climb,
                              D_aero_coeffs_at_climb=D_aero_coeffs_at_climb)
    tw_cl3 = constraint_climb(ws_range, 'Second Climb OEI', n_engine=2, Weight_factor=beta_cl3, is_MCT=False, is_OEI=True,
                              CD0_clean=CD0_clean, AR_wing=AR_wing, CL_max_climb=CL_max_climb,
                              D_aero_coeffs_at_climb=D_aero_coeffs_at_climb)
    tw_cl4 = constraint_climb(ws_range, 'Enroute Climb OEI', n_engine=2, Weight_factor=beta_cl4, is_MCT=True, is_OEI=True,
                              CD0_clean=CD0_clean, AR_wing=AR_wing, CL_max_climb=CL_max_climb,
                              D_aero_coeffs_at_climb=D_aero_coeffs_at_climb)
    tw_cl5 = constraint_climb(ws_range, 'Balked Landing Climb AEO', n_engine=2, Weight_factor=beta_land_outstation, is_MCT=False, is_OEI=False,
                              CD0_clean=CD0_clean, AR_wing=AR_wing, CL_max_climb=CL_max_climb,
                              D_aero_coeffs_at_climb=D_aero_coeffs_at_climb)
    tw_cl6 = constraint_climb(ws_range, 'Balked Landing Climb OEI', n_engine=2, Weight_factor=beta_land_outstation, is_MCT=False, is_OEI=True,
                              CD0_clean=CD0_clean, AR_wing=AR_wing, CL_max_climb=CL_max_climb,
                              D_aero_coeffs_at_climb=D_aero_coeffs_at_climb)
    tw_cruise = constraint_cruise(ws_range, cruise_altitude_m, cruise_mach, beta_cruise, K_clean, CD0_clean)
    tw_ceil = constraint_ceiling(ws_range, ceiling_altitude_m, beta_cruise, K_clean, CD0_clean)
    
    # Find Design Points (Intersections of Constraints)

    # Design Point 1
    # We are constrained by Landing W/S and Takeoff T/W
    design_ws1 = ws_land
    design_tw1 = np.interp(design_ws1, ws_range, tw_to)

    # Design Point 2
    # We are constrained by climb max T/W and max W/S between Takeoff and Landing
    design_tw2 = np.max([tw_cl1, tw_cl2, tw_cl3, tw_cl4, tw_cl5, tw_cl6])
    design_ws2 = min(np.interp(design_tw2, tw_to, ws_range), ws_land)

    # Design Point 3
    # We are constrained by climb max T/W and Cruise W/S
    design_tw3 = np.max([tw_cl1, tw_cl2, tw_cl3, tw_cl4, tw_cl5, tw_cl6])
    diff = tw_cruise - design_tw3

    # indices where curve crosses the horizontal line
    idx = np.where(np.sign(diff[:-1]) != np.sign(diff[1:]))[0]

    if len(idx) == 0:
        raise ValueError("No intersection found in ws_range")
    # pick the left intersection (usually the relevant one); use idx[-1] for right one
    i = idx[0]

    # linear interpolation for ws at intersection
    x0, x1 = ws_range[i], ws_range[i + 1]
    y0, y1 = tw_cruise[i], tw_cruise[i + 1]
    design_ws3 = x0 + (design_tw3 - y0) * (x1 - x0) / (y1 - y0)

    if plot:
        # --- Plotting ---
        plt.figure(figsize=(10, 7))
        
        plt.plot(ws_range, tw_cl1, label='Climb 1: Takeoff OEI', linestyle='-', color='orange')
        plt.plot(ws_range, tw_cl2, label='Climb 2: Transition OEI', linestyle='-', color='red')
        plt.plot(ws_range, tw_cl3, label='Climb 3: Second OEI', linestyle='-', color='grey')
        plt.plot(ws_range, tw_cl4, label='Climb 4: Enroute OEI', linestyle='-', color='purple')
        plt.plot(ws_range, tw_cl5, label='Climb 5: Balked AEO', linestyle='-')
        plt.plot(ws_range, tw_cl6, label='Climb 6: Balked OEI', linestyle='-')
        plt.plot(ws_range, tw_cruise, label=f'Cruise Speed (M{cruise_mach})', color='green')
        plt.plot(ws_range, tw_ceil, label=f'Service Ceiling ({int(mission_req["ceiling_altitude_ft"]/1000)}k ft)', color='magenta', linestyle='-')
        
        plt.plot(ws_range, tw_to, label='Takeoff Field Length', color='blue')
        plt.axvline(x=ws_land, color='black', linestyle='-', label='Landing Field Length')
        
        # Design Point
        plt.scatter(design_ws1, design_tw1, color='blue', s=100, zorder=10, label=f'Design Point 1 ({design_ws1:.2f}, {design_tw1:.3f})')
        plt.scatter(design_ws2, design_tw2, color='red', s=100, zorder=10, label=f'Design Point 2 ({design_ws2:.2f}, {design_tw2:.3f})')
        plt.scatter(design_ws3, design_tw3, color='green', s=100, zorder=10, label=f'Design Point 3 ({design_ws3:.2f}, {design_tw3:.3f})')
        
        # Feasible Region
        tw_combined = np.maximum.reduce([tw_to, tw_cl1, tw_cl2, tw_cl3, tw_cl4, tw_cl5, tw_cl6, tw_cruise, tw_ceil])
        plt.fill_between(ws_range, tw_combined, 1.0, where=(ws_range <= ws_land), color='green', alpha=0.1)

        plt.title('Constraint Analysis', fontsize=16)
        plt.xlabel(r'Wing Loading $W_\text{TO}/S$ (N/m$^2$)', fontsize=12)
        plt.ylabel(r'Thrust-to-Weight Ratio $T_\text{SL}/W_\text{TO}$', fontsize=12)
        plt.ylim(0.1, 0.6)
        plt.xlim(1000, 6000)
        plt.grid(True, linestyle='--', alpha=0.6)
        plt.legend(loc='upper left')
        plt.show()

    if verbose:
        print(f"Design Point 1: W/S = {design_ws1:.2f} N/m^2, T/W = {design_tw1:.4f}")
        print(f"Design Point 2: W/S = {design_ws2:.2f} N/m^2, T/W = {design_tw2:.4f}")
        print(f"Design Point 3: W/S = {design_ws3:.2f} N/m^2, T/W = {design_tw3:.4f}")

    design_points = {}
    design_points['dp1'] = {'W/S': design_ws1, 'T/W': design_tw1}
    design_points['dp2'] = {'W/S': design_ws2, 'T/W': design_tw2}
    design_points['dp3'] = {'W/S': design_ws3, 'T/W': design_tw3}

    return design_points


# ===============================
# Main Execution & Visualization
# ===============================


if __name__ == "__main__":

    engine_data = {
        'SFC_cruise_per_hour': 0.5,
        'SFC_loiter_per_hour': 0.4,
        'n_engine': 2
    }

    aero_data = {
        'AR_wing': 9.0,
        'e_clean': 0.82,
        'CD0_clean': 0.022,
        'LD_max': 14.0,
        'LD_cruise_factor': 0.866,
        'CL_max_takeoff': 1.8,
        'CL_max_climb': 1.4,
        'CL_max_land': 2.8,
        'D_aero_coeffs_at_climb': {
            # Delta_CD0 and Oswald coeffs at climb configurations
            'flaps_at_0_deg': [0, 0.85],
            'flaps_at_5_deg_gear_down': [0.035, 0.85],
            'flaps_at_5_deg_gear_up': [0.010, 0.85],
            'flaps_at_10_deg_gear_down': [0.055, 0.75],
            'flaps_at_10_deg_gear_up': [0.030, 0.75]
        }
    }

    mission_req = {
        'n_pax': 70,
        'W_pax_unit_kg': 90.0 + 15.0,
        'n_crew': 4,
        'W_crew_unit_kg': 90.0 + 15.0,
        'cruise_mach': 0.78,
        'cruise_altitude_ft': 35000.0,
        'ceiling_altitude_ft': 41000.0,
        'dist_leg_1_km': 1050.0,
        'dist_leg_2_km': 1050.0,
        'dist_alternate_km': 200 * NMI_TO_KM,
        'time_hold_min': 45.0,
        'takeoff_field_length_m': 1800.0,  # m (ISA+15)
        'landing_field_length_m': 1600.0   # m (ISA+15)
    }

    # Range of wing loading (N/m^2)
    ws_range = np.linspace(1000, 6000, 100)

    perform_constraint_analysis(ws_range, engine_data, aero_data, mission_req, plot=True, verbose=True)
