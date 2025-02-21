from pyxdsm.XDSM import XDSM, OPT, SOLVER, FUNC, IFUNC, LEFT

figure_sets = [['WeightEstimationXDSM', False, False, False, False],
			   ['MissionSegmentWeightXDSM', False, True, True, True],
			   ['FuelWeightXDSM', True, False, True, True],
			   ['TakeoffWeightXDSM', True, True, False, True],
			   ['EmptyWeightXDSM', True, True, True, False],
			   ['TakeoffEmptyWeightXDSM', True, True, False, False]]

for figure_set in figure_sets:

	# Change `use_sfmath` to False to use computer modern
	x = XDSM(use_sfmath=True)

	# Systems
	x.add_system("mission_segment", FUNC, (r'\text{Mission Segment}', r'\text{Weight Fraction}'), stack=True, faded=figure_set[1])
	x.add_system('fuel', FUNC, (r'\text{Fuel Weight}', r'\text{Estimation}'), faded=figure_set[2])
	x.add_system('takeoff', IFUNC, (r'\text{Takeoff Weight }', r'\text{Estimation}'), faded=figure_set[3])
	x.add_system('empty', FUNC, (r'\text{Empty Weight}', r'\text{Estimation}'), faded=figure_set[4])

	# Connections
	x.connect('takeoff', 'empty', r'W_\mathrm{TO}')
	x.connect('mission_segment', 'fuel', r'WFs')
	x.connect('fuel', 'takeoff', r'W_\mathrm{f}/W_\mathrm{TO}')
	x.connect('empty', 'takeoff', r'W_\mathrm{e}/W_\mathrm{TO}')

	# Processes
	x.add_process(['mission_segment', 'fuel', 'takeoff', 'empty', 'takeoff'])

	# Inputs
	x.add_input('mission_segment', r'\text{Mission Data}')
	x.add_input('takeoff', r'W_\text{crew}, W_\text{payload}, W_{\mathrm{TO}_\text{init}}')

	# Outputs
	x.add_output('takeoff', r'W_\mathrm{TO}^*')

	# Write file
	x.write(figure_set[0], build=True, cleanup=True, quiet=False, outdir='.')