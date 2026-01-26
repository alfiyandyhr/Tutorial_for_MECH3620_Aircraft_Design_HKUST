from pyxdsm.XDSM import XDSM, OPT, SOLVER, FUNC, IFUNC, LEFT

# Change `use_sfmath` to False to use computer modern
x = XDSM(use_sfmath=True)

# Systems
x.add_system('opt', OPT, [r'\text{($T/W$) and ($W/S$)}', r'\text{Optimization}'])
x.add_system('aero', FUNC, [r'\text{Drag}', r'\text{Polar}'])
x.add_system('stall', IFUNC, [r'\text{Stall Speed}', r'\text{Constraint}'])
x.add_system('climb', IFUNC, [r'\text{Climb}', r'\text{Constraints}'], stack=True)
x.add_system('cruise', IFUNC, [r'\text{Cruise}', r'\text{Constraint}'])
x.add_system('others', IFUNC, [r'\text{Other Mission}', r'\text{Constraints}'], stack=True)

# Connections
x.connect('opt', 'climb', r'(W/S)', stack=True)
x.connect('opt', 'cruise', r'(W/S)')
x.connect('opt', 'others', r'(W/S)', stack=True)
x.connect('aero', 'stall', r'C_{D_0}, k')
x.connect('aero', 'climb', r'C_{D_0}, k', stack=True)
x.connect('aero', 'cruise', r'C_{D_0}, k')
x.connect('aero', 'others', r'C_{D_0}, k', stack=True)
x.connect('stall', 'opt', r'(W/S)_\text{stall}')
x.connect('climb', 'opt', r'(T/W)_\text{climb}', stack=True)
x.connect('cruise', 'opt', r'(T/W)_\text{cruise}')
x.connect('others', 'opt', r'(T/W)_\text{others}', stack=True)

# Inputs
x.add_input('opt', r'(T/W)_0, (W/S)_0')
x.add_input('aero', [r'c_f, S_\text{wet}/S_\text{ref}', r'AR, e, C_{L_{\alpha=0}}'])
x.add_input('stall', r'C_{L_\text{max}}, V_\text{stall}')
x.add_input('climb', r'V_{R/C}')
x.add_input('cruise', r'V_\text{cruise}')
x.add_input('others', r'\mathbf{V_\text{others}}, ...')

# Outputs
x.add_output('opt', r'(T/W)^*, (W/S)^*')

# Write file
x.write('ConstraintAnalysisXDSM', build=True, cleanup=True, quiet=False, outdir='.')
