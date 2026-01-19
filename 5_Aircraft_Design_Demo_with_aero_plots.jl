### A Pluto.jl notebook ###
# v0.19.40

#> [frontmatter]
#> title = "Overall Aircraft Design Demo"
#> layout = "layout.jlhtml"
#> tags = ["aerofuse"]
#> description = ""

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ d3da7be0-aef5-4ea1-9655-00714ac25557
using AeroFuse

# ╔═╡ ef767260-419e-4029-b7cd-c202790668a5
using Plots

# ╔═╡ 6f7b9b78-02af-43f1-8f71-8da6f8ac9aea
using DataFrames

# ╔═╡ 5693bae3-e676-497c-baef-c84472270cef
begin
	using PlutoUI
	TableOfContents()
end

# ╔═╡ 50f026a9-84f2-4152-a1f6-b3c55c84e8ea
md"""# AeroFuse: Aircraft Design Demo

**Author**: [Arjit SETH](https://godot-bloggy.xyz), Research Assistant, MAE, HKUST.

"""

# ╔═╡ 47df8df1-3923-44a1-a19e-845246737b1e
gr(
	size = (900, 700),  # INCREASE THE SIZE FOR THE PLOTS HERE.
	palette = :tab20    # Color scheme for the lines and markers in plots
)

# ╔═╡ f5aadd23-1d7b-4c3b-be6e-111e431357e1
md"## Aircraft Geometry"

# ╔═╡ f6a0b7bc-4722-49d9-98c8-37822febca88
md"""

Here, we'll refer to a passenger jet (based on a Boeing 777), but you can modify it to your design specifications.

![](https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/dc763bf2-302c-46be-8a52-4cb7c11598e5/d74vi3c-372cf93b-f4ad-4046-85e3-49f667d3c55a.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcL2RjNzYzYmYyLTMwMmMtNDZiZS04YTUyLTRjYjdjMTE1OThlNVwvZDc0dmkzYy0zNzJjZjkzYi1mNGFkLTQwNDYtODVlMy00OWY2NjdkM2M1NWEucG5nIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.bS5c5rkhqB2yoaOmIeRut7TgVsqgnPIfMOBSgYOO-TI)

"""

# ╔═╡ 343af23b-4c4d-422b-81d2-4bc4e5407dac
md"""### Fuselage"""

# ╔═╡ 2ef0a234-499b-4e23-b7d7-c3fcadd14752
# Fuselage definition
fuse = HyperEllipseFuselage(
    radius = 3.04,          # Radius, m
    length = 63.5,          # Length, m
    x_a    = 0.15,          # Start of cabin, ratio of length
    x_b    = 0.7,           # End of cabin, ratio of length
    c_nose = 1.6,            # Curvature of nose
    c_rear = 1.3,           # Curvature of rear
    d_nose = -0.5,          # "Droop" or "rise" of nose, m
    d_rear = 1.0,           # "Droop" or "rise" of rear, m
    position = [0.,0.,0.]   # Set nose at origin, m
)

# ╔═╡ 26d5c124-3da7-4a5a-b06e-38627b2dd8ac
begin
	# Compute geometric properties
	ts = 0:0.01:1                # Distribution of sections for nose, cabin and rear
	S_f = wetted_area(fuse, ts) # Surface area, m²
	V_f = volume(fuse, ts)      # Volume, m³
end

# ╔═╡ e8a84941-3ab0-461c-9ab8-cb0b5515989f
md"You can access the position by the `.affine.translation` attribute."

# ╔═╡ 9860d2fa-b497-4377-afe7-367b4a00e50d
fuse.affine.translation # Coordinates of nose

# ╔═╡ ef839605-88c5-4469-ae55-47961eb5417b
# Get coordinates of rear end
fuse_end = fuse.affine.translation + [ fuse.length, 0., 0. ]

# ╔═╡ 635f6baa-e360-45b2-87de-fedf1ec52b4a
fuse_end.x 	# Access x-coordinate

# ╔═╡ 65661116-c2a5-4684-aa1d-8514e6310025
md"""

!!! warning
	You may have to change the fuselage dimensions when estimating weight, balance and stability according to the design requirements!
"""

# ╔═╡ 74330174-edfd-4e13-8bc1-f8c80c163be0
md"### Wing"

# ╔═╡ 1bf4c10a-1801-41be-b06f-677f44a156a7
# begin
# 	# AIRFOIL PROFILES
# 	foil_w_r = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737a-il")) # Root
# 	foil_w_m = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737b-il")) # Midspan
# 	foil_w_t = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737c-il")) # Tip
# end

# ╔═╡ 751bf100-1de9-48b0-aeed-c31e3a590521
begin
	# AIRFOIL PROFILES
	foil_w_r = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737a-il")) # Root
	foil_w_m = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737b-il")) # Midspan
	foil_w_t = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737c-il")) # Tip
end

# ╔═╡ 7758fb66-991d-49f7-b8f8-a3549fb0e340
# Wing
wing = Wing(
    foils       = [foil_w_r, foil_w_m, foil_w_t], # Airfoils (root to tip)
    chords      = [14.0, 9.73, 1.43561],        # Chord lengths
    spans       = [14.0, 46.9] / 2,             # Span lengths
    dihedrals   = fill(6, 2),                   # Dihedral angles (deg)
    sweeps      = fill(35.6, 2),                # Sweep angles (deg)
    w_sweep     = 0.,                           # Leading-edge sweep
    symmetry    = true,                         # Symmetry

	# Orientation
    angle       = 3,       # Incidence angle (deg)
    axis        = [0, 1, 0], # Axis of rotation, x-axis
    position    = [0.35fuse.length, 0., -2.5]
)

# ╔═╡ d61de21f-5d28-4bd9-8b41-0d0be92f9e76
b_w = span(wing) # Span length, m

# ╔═╡ d54578a4-d0e6-4b18-bc13-477467b2a058
S_w = projected_area(wing) # Area, m

# ╔═╡ 79dd19b4-10cc-44a8-ba62-4a7ef1ceb752
c_w = mean_aerodynamic_chord(wing) # Mean aerodynamic chord, m

# ╔═╡ d154be95-8350-4c38-8b02-10595d9764cd
mac_w = mean_aerodynamic_center(wing, 0.25) # Mean aerodynamic center (25%), m

# ╔═╡ 958906a9-75c3-4ead-aafe-2596623b89c0
mac40_wing = mean_aerodynamic_center(wing, 0.4) # Mean aerodynamic center (40%), m

# ╔═╡ 35a249a3-7272-435a-a5d3-5e8ba8a655ca
md"""

!!! warning
	You may have to change the wing size and locations when estimating weight, balance and stability!
"""

# ╔═╡ bec4f70a-7ff0-4c0e-8759-758a95831e46
md"### Engines"

# ╔═╡ cd2e5706-bfc9-4fca-90bd-70460198c9ee
md"We can place the engines based on the wing and fuselage geometry."

# ╔═╡ 187d4c9e-e366-4395-9b3e-b0cefbf9ce5d
wing_coo = coordinates(wing) # Get leading and trailing edge coordinates. First row is leading edge, second row is trailing edge.

# ╔═╡ 82731c8d-7819-42d3-afd1-eabfbad8303b
wing_coo[1,:] # Get leading edge coordinates

# ╔═╡ da2ef327-9171-4daf-98e2-ed679d6f84e2
begin
	# Example:
	eng_L = wing_coo[1,2] - [1, 0., 0.] # Left engine, at mid-section leading edge
	eng_R = wing_coo[1,4] - [1, 0., 0.] # Right engine, at mid-section leading edge
end

# ╔═╡ 79a60ed4-5281-4261-90fb-5f2bfc928758
md"""

!!! warning
	You may have to change the engine locations when estimating weight, balance and stability!
"""

# ╔═╡ 3dd1f51b-26e2-44f1-b754-fb58612e7d7c
md"### Stabilizers"

# ╔═╡ 63a82ccb-21e4-4edc-81df-cd9f84953372
md"#### Horizontal Tail"

# ╔═╡ 647698ec-1f80-4ddd-ae98-f40a05ea75c6
con_foil = control_surface(naca4(0,0,1,2), hinge = 0.75, angle = -10.)

# ╔═╡ fbeb3c61-6c88-4aa5-9925-3510a00e366e
htail = WingSection(
    area        = 101,  			# Area (m²). HOW DO YOU DETERMINE THIS?
    aspect      = 6.2,  			# Aspect ratio
    taper       = 0.4,  			# Taper ratio
    dihedral    = 7.,   			# Dihedral angle (deg)
    sweep       = 35.,  			# Sweep angle (deg)
    w_sweep     = 0.,   			# Leading-edge sweep
    root_foil   = con_foil, 	# Root airfoil
	tip_foil    = con_foil, 	# Tip airfoil
    symmetry    = true,

    # Orientation
    angle       = 5,  # Incidence angle (deg). HOW DO YOU DETERMINE THIS?
    axis        = [0., 1., 0.], # Axis of rotation, y-axis
    position    = fuse_end - [ 10., 0., 0.], # HOW DO YOU DETERMINE THIS?
)

# ╔═╡ 7432a455-aff6-4a22-8576-9249f67b5dd7
b_h = span(htail)

# ╔═╡ 25fb28f6-4571-4b87-8a7d-9465eae537de
S_h = projected_area(htail)

# ╔═╡ c1ed6eb3-a0c7-484e-a511-2e13df3a2040
c_h = mean_aerodynamic_chord(htail)

# ╔═╡ 185f315c-ccc9-4c9c-be91-f30c8046b27a
mac_h = mean_aerodynamic_center(htail)

# ╔═╡ 8ab5fc32-41f1-4492-bc35-7d0cb5864162
V_h = S_h / S_w * (mac_h.x - mac_w.x) / c_w

# ╔═╡ 79978d9e-c28a-4787-9d6a-ac753331111e
md"#### Vertical Tail"

# ╔═╡ 72c1cb62-58da-40c8-a5ff-5f9325360fe8
vtail = WingSection(
    area        = 56.1, 			# Area (m²). # HOW DO YOU DETERMINE THIS?
    aspect      = 1.5,  			# Aspect ratio
    taper       = 0.4,  			# Taper ratio
    sweep       = 44.4, 			# Sweep angle (deg)
    w_sweep     = 0.,   			# Leading-edge sweep
    root_foil   = naca4(0,0,0,9), 	# Root airfoil
	tip_foil    = naca4(0,0,0,9), 	# Tip airfoil

    # Orientation
    angle       = 90.,       # To make it vertical
    axis        = [1, 0, 0], # Axis of rotation, x-axis
    position    = htail.affine.translation - [2.,0.,-1.] # HOW DO YOU DETERMINE THIS?
) # Not a symmetric surface

# ╔═╡ 02dcefce-3b27-441f-a76b-9dba2c7b2b72
b_v = span(vtail)

# ╔═╡ 659c3d72-85e2-4f39-aa49-cbc83066c345
S_v = projected_area(vtail)

# ╔═╡ a259c6c0-939e-4af0-a1d4-11d088b4c7db
c_v = mean_aerodynamic_chord(vtail)

# ╔═╡ 8effef36-3f6c-4179-877d-3f0e03863a22
mac_v = mean_aerodynamic_center(vtail)

# ╔═╡ edd73ae8-6bf2-4585-9275-166e3ee7a017
V_v = S_v / S_w * (mac_v.x - mac_w.x) / b_w

# ╔═╡ f2587d9c-8028-46f7-9610-869d9eb15c73
md"""

!!! warning
	You may have to change the tail size and locations when estimating weight, balance and stability!

"""

# ╔═╡ 117d30e6-1252-4198-b348-6a1e5e798070
md"### Visualization"

# ╔═╡ 5342b18a-7fe2-46b4-a53f-91399797b971
md"""## Aerodynamic Analysis

!!! info
	Refer to the **Aerodynamic Analysis** tutorial in the AeroFuse documentation to understand this process: [https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-aircraft/](https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-aircraft/)

"""

# ╔═╡ a26930b4-f8aa-41bf-8375-fac549980ca3
md"### Meshing"

# ╔═╡ 21b17672-2800-4876-a83a-b04f5b94cf76
wing_mesh = WingMesh(wing, 
	[8,16], # Number of spanwise panels
	10,     # Number of chordwise panels
    span_spacing = Uniform() # Spacing: Uniform() or Cosine()
)

# ╔═╡ bfdc099a-bdac-4b8f-8ef8-a1c2003c6d43
htail_mesh = WingMesh(htail, [10], 8)

# ╔═╡ b61af5cc-a240-4670-93d0-aeb01208d01d
vtail_mesh = WingMesh(vtail, [8], 6)

# ╔═╡ 696e35a8-1ece-4a7b-a160-ec6d2a3134c0
md"### Vortex Lattice Method"

# ╔═╡ cb819012-a6cd-462e-bee1-c118ba8f3caf
md"The vortex lattice method (VLM) provides decent estimations of the aerodynamic lift and stability in the preliminary design stages."

# ╔═╡ b672ad66-01a4-48b3-a169-02d97d4b9baa
# Define aircraft
ac = ComponentVector(# ASSEMBLE MESHES INTO AIRCRAFT
	wing  = make_horseshoes(wing_mesh),   # Wing
	htail = make_horseshoes(htail_mesh),  # Horizontal Tail
	vtail = make_horseshoes(vtail_mesh)   # Vertical Tail
)

# ╔═╡ 5b611e79-5689-4a33-929e-5c77dee7f958
# Define freestream conditions
fs = Freestream(
	alpha = 0.0, # Angle of attack, deg. HOW DO YOU CHOOSE THIS?
	beta = 0.0,  # Angle of sideslip, deg.
) 

# ╔═╡ c429a2d2-69b9-437d-a138-efee4b118016
M = 0.84 # Operating Mach number.

# ╔═╡ 36b197b3-1971-4c73-96ec-7370002ade1e
# ╠═╡ disabled = true
#=╠═╡
# Define reference values
refs = References(
	density = 0.35, # Density at cruise altitude.
					# HOW DO YOU CALCULATE THIS BASED ON THE ALTITUDE?
	
	speed = M * 330., # HOW DO YOU DETERMINE THE SPEED?

	# Set reference quantities to wing dimensions.
	area = projected_area(wing), 			# Area, m²
	chord = mean_aerodynamic_chord(wing),   # Chord, m
	span = span(wing), 						# Span, m
	
	location = fuse.affine.translation, # From the nose as reference (origin)
)
  ╠═╡ =#

# ╔═╡ dfd216a0-817c-43b2-bb0a-e2f5bb28650d
md"""### Aerodynamic Coefficients

Two methods are provided for obtaining the force and moment coefficients from the VLM analysis.

"""

# ╔═╡ c736beb7-6714-4931-9e35-e452a9647682
md"#### Nearfield"

# ╔═╡ f0ba714d-2710-4558-b078-24ae0faeb1e0
md"#### Farfield"

# ╔═╡ 81b627fb-263f-44fb-8e4e-4a4fe075dbc0
md"""

!!! tip
	Use the farfield coefficients for the induced drag, as they are usually much more accurate than the nearfield coefficients.

"""

# ╔═╡ 3be74cb9-4e2f-483a-ac57-0b80732218e0
md"""## Weight and Balance Estimation

The component weights of the aircraft are some of the largest contributors to the longitudinal stability characteristics.

![](https://raw.githubusercontent.com/HKUST-OCTAD-LAB/MECH3620Materials/main/pics/777200LRMoments.svg)

Recall the definition of the center of gravity (CG):
```math
\mathbf{r}_\text{cg} = \frac{\sum_i \mathbf{M}_i}{\sum_i W_i} = \frac{\sum_i W_i \ (\mathbf{r}_{\text{cg}})_i}{\sum_i W_i}, \quad \mathbf{r} = \begin{bmatrix}
  x \\ y \\ z
\end{bmatrix}
```

where $W_i$ represents the weight for each component and $(\mathbf r_{\text{cg}})_i$ is the position vector between the origin and the CG of the $i$th component. The product in the form $W_i(\mathbf r_{\text{cg}})_i$ is also referred to as the moment $\mathbf M_i$ induced by the $i$th component.

"""

# ╔═╡ c2f25eac-7453-420a-bcda-ad70a438358f
md"### Statistical Weight Estimation"

# ╔═╡ 08c88bf1-72f9-4e54-926f-b8f8fdbb8179
# WRITE STATISTICAL WEIGHT ESTIMATION FORMULAS AND COMPUTATIONS

# ╔═╡ 07971f8e-fd34-4292-a021-278b567ee3ef


# ╔═╡ 737189fe-e73d-4dbc-a172-da713925bd1d
md"#### Component Weight Build-up"

# ╔═╡ 521c7938-d392-4831-b62b-bd4221cff162
md"Based on the statistical weight estimation method and weight estimation of other components, you can determine most of the weights and assign them to variables."

# ╔═╡ ddfa28f9-de7c-4faa-a998-bdfa1a17a223
g = 9.81 # Gravitational acceleration, m/s²

# ╔═╡ 091fdf20-508c-48a1-aaa5-ad13722a540b
lb_ft2_to_kg_m2 = 4.88243 # Convert lb/ft² to kg/m²

# ╔═╡ 70d90871-53ab-402a-9a6d-1dd727e5c6d0
begin
	# Weights
	#====================================================#
	
	# THIS HAS BEEN DONE BASED ON PRELIMINARY ESTIMATION. 
	# YOU MUST REVISE IT BASED ON STATISTICAL WEIGHTS.

	TOGW 	= 347458 * g # Takeoff gross weight, N
	W_other = 0.17 * TOGW # All other components

	# Engine
	W_engine 	 = 8762 * g # GE90-110B1 engine weight (single), N
	W_engine_fac = 1.3 * W_engine # Scaling factor for engine weight

	# Lifting surfaces (HINT: REPLACE WITH STATISTICAL WEIGHTS)
	W_wing 	= S_w * 10 * lb_ft2_to_kg_m2 * g
	W_htail = S_h * 5.5 * lb_ft2_to_kg_m2 * g
	W_vtail = S_v * 5.5 * lb_ft2_to_kg_m2 * g
	W_fuse 	= S_f * 5.0 * lb_ft2_to_kg_m2 * g

	# Landing gear
	W_nLG = 0.043 * 0.15 * TOGW # Nose
	W_mLG = 0.043 * 0.85 * TOGW # Main landing gear

	# THERE ARE MORE COMPONENT WEIGHTS YOU NEED TO ACCOUNT FOR!!!
	# HINT: PASSENGERS??? LUGGAGE??? FUEL???
end

# ╔═╡ 5838b73b-a044-4f63-b3b8-88c5b96e0f83
md"### Component Locations"

# ╔═╡ 27e4439a-9f40-40a9-8603-e80161da8004
md"Now determine and modify the locations of each component sensibly."

# ╔═╡ 3c345c72-12cd-4573-a957-5bc5fe3caeb0
begin
	# Locations
	#====================================================#

	# THIS HAS BEEN DONE BASED ON PRELIMINARY ESTIMATION. 
	# YOU MUST REVISE IT FOR THE BALANCE AND STABILITY OF YOUR AIRCRAFT.
	
	r_w = mean_aerodynamic_center(wing, 0.4)   # Wing, 40% MAC
	r_h = mean_aerodynamic_center(htail, 0.4)  # HTail, 40% MAC
	r_v = mean_aerodynamic_center(vtail, 0.4)  # VTail, 40% MAC

	r_eng_L = wing_coo[1,2] - [1., 0., 0.]     # Engine, near wing LE
	r_eng_R = wing_coo[1,4] - [1., 0., 0.] 	   # Engine, near wing LE

	# Nose location 
	r_nose 	= fuse.affine.translation

	# Fuselage centroid (50% L_f)
	r_fuse 	= r_nose + [fuse.length / 2, 0., 0.]

	# All-other component centroid (40% L_f)
	r_other = r_nose + [0.4 * fuse.length, 0., 0.]

	# Nose landing gear centroid (15% L_f)
	r_nLG  	= r_nose + [0.15 * fuse.length, 0., -fuse.radius]

	# Main landing gear centroid (50% L_f)
	r_mLG 	= r_nose + [0.5 * fuse.length, 0., -fuse.radius]

	# THERE ARE MORE COMPONENT LOCATIONS YOU NEED TO ACCOUNT FOR!!!
end;

# ╔═╡ 14a79c53-1d0a-438e-8a9b-e7dafbef1322
md"### Center of Gravity Calculation"

# ╔═╡ 7a05752f-522c-4f5e-84fc-bd9624deb07e
md"Finally, assemble this information into a dictionary."

# ╔═╡ c197c2fd-cd78-4aa6-83c1-bb34d6579c80
# Component weight and location dictionary
W_pos = Dict(
	# "Component"   => (Weight, Location)
	"Engine L CG" 	=> (W_engine_fac, r_eng_L),
	"Engine R CG" 	=> (W_engine_fac, r_eng_R),
	"Wing CG"   	=> (W_wing, r_w), 
	"HTail CG"  	=> (W_htail, r_h), 
	"VTail CG"  	=> (W_vtail, r_v),
	"Fuse CG"   	=> (W_fuse, r_fuse),
	"All-Else CG" 	=> (W_other, r_other),
	"Nose LG CG" 	=> (W_nLG, r_nLG), 
	"Main LG CG" 	=> (W_mLG, r_mLG),
);

# ╔═╡ dc99a9c2-cb70-4498-b9ed-6295fff11884
keys(W_pos) # Get keys

# ╔═╡ a34e91e7-927e-4b0a-b72b-0813e098f000
values(W_pos) # Get values

# ╔═╡ 516a6341-aa4d-4811-aaa1-c65ed92b0357
 # Total weight evaluation using array comprehension, N
W_tot = sum(W_i for (W_i, r_i) in values(W_pos))

# ╔═╡ ff34f0e0-dc07-467a-88cb-6d287ba4463b
m_tot = W_tot / g 	# Total mass, kg

# ╔═╡ 774c9f2b-3e2f-4f74-bf22-28745063cfae
M_tot = sum(W_i * r_i for (W_i, r_i) in values(W_pos)) # Total moment, N-m

# ╔═╡ 38e5cf39-0766-400b-9312-e39b673faac6
md"""

!!! tip
	Check whether the sum of the weights matches the estimated total weight! It may not be exactly close because:

	1. You have used statistical estimations for many of the weights.
	2. You may not have accounted for all the relatively heavy components.

"""

# ╔═╡ f1b551ba-4f27-4bec-af09-7554c2e76045
# CG estimation, m
r_cg = M_tot / W_tot

# ╔═╡ 6e8dead0-6af0-4324-928d-e19b295c9b5b
x_cg = r_cg.x  # x-component

# ╔═╡ 140c3020-58b1-439b-9772-7b17b5915b40
md"""## Stability Analysis

!!! info
	Refer to the **Aerodynamic Stability Analysis** tutorial in the AeroFuse documentation to understand this process: [https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-stability/](https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-stability/)

"""

# ╔═╡ 10632c4e-7aa0-4f99-a9ff-39ccad2da377
md"""### Static Margin Estimation

In addition to the weights, the aerodynamic forces depicted are also major contributors to the stability of a conventional aircraft configuration.

![](https://raw.githubusercontent.com/HKUST-OCTAD-LAB/MECH3620Materials/main/pics/777200LR.svg)

**CAD Source:** [https://grabcad.com/library/boeing-777-200](https://grabcad.com/library/boeing-777-200)

This interrelationship between aerodynamics and weights on stability is expressed via the static margin.

```math
\text{Static Margin} = \frac{x_{np} - x_{cg}}{\bar c} 
```

We need to determine both of these locations: the center of gravity $x_{cg}$ and the neutral point $x_{np}$.
"""

# ╔═╡ 7867678b-5910-45a5-a8fd-59ace4d0dc7b
md"""

#### Neutral Point

The neutral point is:
```math
\frac{x_{np}}{\bar c} = -\left(\frac{\partial C_m}{\partial C_L} + \frac{\partial C_{m_f}}{\partial C_L}\right)
```
where $\partial C_m / \partial C_L$ is the moment-lift derivative excluding the fuselage contribution, and $\partial C_{m_f} / \partial C_L$ is the moment-lift derivative contributed by the fuselage.

"""

# ╔═╡ d02fe0a3-3523-4239-9b74-bf4e00b5e891
md"""First, we need to compute the aerodynamic stability derivatives:

```math
	\frac{\partial C_m}{\partial C_L} \approx \frac{C_{m_\alpha}}{C_{L_\alpha}}
```

"""

# ╔═╡ 8bcd6ea1-6711-4a0c-8f1c-bba12e843808
md"""
!!! info
	Enable the "Stability" checkbox in the plotting toggles to run the stability analysis.
"""

# ╔═╡ 37d4a03a-af97-4208-bfa1-6bb057f0f988
md""" ##### Fuselage Contribution
The moment-lift derivative of the fuselage is estimated via slender-body theory, which primarily depends on the volume of the fuselage. 

```math
\frac{\partial C_{m_f}}{\partial C_L} \approx \frac{2\mathcal V_f}{S_w \bar{c}C_{L_{\alpha_w}}} 
```

!!! tip 
	For estimating the volume without using [AeroFuse](https://github.com/GodotMisogi/AeroFuse.jl), you can initially approximate the fuselage as a square prism of length $L_f$ with maximum width $w_f$ (hence, $\mathcal V_f \approx w_f^2 L_f$) and introduce a form factor $K_f$ as a correction factor for the volume of the actual shape.
	```math
	\frac{\partial C_{m_f}}{\partial C_L} \approx \frac{K_f w_f^2 L_f}{S_w \bar{c}C_{L_{\alpha_w}}}
	```

	Your notes provide the empirical estimation of $K_f$.
"""

# ╔═╡ 97929c85-54c0-4976-95b6-d70364c68035
# FUSELAGE CM-CL DERIVATIVE
function fuse_Cm_CL(
		V_f, 	# Fuselage volume
		Sw, 	# Wing area 
		c_bar, 	# Mean aerodynamic chord
		CL_a_w 	# Lift curve slope
	)

	# Compute fuselage moment-lift derivative
	dCMf_dCL = 2 * V_f / (Sw * c_bar * CL_a_w)
	
	return dCMf_dCL
end

# ╔═╡ 072e8834-0a19-456a-b818-f436a847490b
# savefig(plt_vlm, "my_aircraft.png") # TO SAVE THE FIGURE

# ╔═╡ 0859eeeb-0dbf-4f39-a7a4-a5f828726b16
md"### Dynamic Stability"

# ╔═╡ 50751fc6-5704-4487-ba2f-9f37c21fbdfc
begin
	Ixx = span(wing) / √12 
	Iyy = chords(wing)[1] / √12 # Moment of inertia in x-z plane
	Izz = span(wing) / √12
end

# ╔═╡ 90ac16c3-37d4-42ae-a9ed-4572c49397dc
md"## Drag Estimation"

# ╔═╡ 27c05748-4570-4420-af08-15fd2a31a373
md"""

The total drag coefficient can be estimated by breaking down the drag contributions from the components:

```math
C_{D_0} = C_{D_{0,f}} + C_{D_{0,w}} + C_{D_{0,ht}} + C_{D_{0,vt}} + C_{D_{0,LG}} + C_{D_{0,N}} + C_{D_{0,S}} + C_{D_{0, HLD}} + \dots
```

"""

# ╔═╡ 05fd1ff1-b47d-4452-b0c0-b4a39a5b3d7e
md">AeroFuse provides the following `parasitic_drag_coefficient` function for estimating $C_{D_0}$ of the fuselage and wing components.
>
> This estimation can depend on whether the flow is laminar or turbulent. For high Reynolds numbers (i.e., $Re \geq 2\times 10^6$), the flow over all surfaces is usually fully turbulent."

# ╔═╡ 0c614e7c-27d9-45cf-90a2-699a02493a72
x_tr = 0.0 # Transition location to turbulent flow as ratio of chord length. 
# 0 = fully turbulent, 1 = fully laminar

# ╔═╡ 04f09813-3514-4e81-93ce-a3bf28610537
md"""We can sum the contributions from the components considered.

"""

# ╔═╡ 71a51430-9b8c-4f22-b41d-3a1532df159c
md"""
!!! danger "Alert!"
	You will have to determine the parasitic drag coefficients of the other terms (landing gear, high-lift devices, etc.) for your design on your own following the lecture notes and references.

	The summation also does not account for interference between various components, e.g. wing and fuselage junction. You may have to consider "correction factors" ($K_c$ in the notes) as multipliers following the references.
"""

# ╔═╡ e6439db0-d98a-4ae5-b706-c606f1caea4a
md"Based on this total drag coefficient, we can estimate the revised lift-to-drag ratio."

# ╔═╡ dee2f972-3b85-473b-adc1-5c3888c5daa0
md"# Plot Definition"

# ╔═╡ be8235a9-2633-41ac-a6d1-d2330d7146f9
begin
	φ_s 			= @bind φ Slider(0:1e-2:90, default = 15)
	ψ_s 			= @bind ψ Slider(0:1e-2:90, default = 30)
	aero_flag 		= @bind aero CheckBox(default = true)
	stab_flag 		= @bind stab CheckBox(default = true)
	weights_flag 	= @bind weights CheckBox(default = false)
	strm_flag 		= @bind streams CheckBox(default = false)
end;

# ╔═╡ f020f165-37f9-45ed-8d21-1e8fc8e1591a
toggles = md"""
φ: $(φ_s)
ψ: $(ψ_s)

Panels: $(aero_flag)
Weights: $(weights_flag)
Stability: $(stab_flag)
Streamlines: $(strm_flag)
"""

# ╔═╡ 6075b162-6315-4bd8-bdff-007f3a278b66
toggles

# ╔═╡ 0418bc57-5b5f-4348-95a9-25bb5bce2af4
toggles

# ╔═╡ 9ac640ed-b400-46f8-89bc-650a5d2801ff
toggles

# ╔═╡ a62696dc-171a-4978-8de9-0ab643987b41
toggles

# ╔═╡ 5d5a0da9-07e0-4be1-ba9c-a854299cd23f
toggles

# ╔═╡ 81f5072b-46e2-466f-8a76-b984d7f3b75e
toggles

# ╔═╡ 623332dc-d56a-478e-84ac-32fe9123c0c2
toggles

# ╔═╡ 06427107-e04a-44d0-9db1-76a9c7519895
toggles

# ╔═╡ f7d454c6-43a6-4818-b20a-6950323f6365
refs = References(
	speed    = 150.0, 							# Reference speed, m/s
	density  = 1.225, 							# Reference density, kg/m³
	area     = projected_area(wing), 			# Reference area, m²
	span     = span(wing), 						# Reference span, m
	chord    = mean_aerodynamic_chord(wing), 	# Reference chord, m
	location = mean_aerodynamic_center(wing) 	# Moment reference point, m
 )

# ╔═╡ e358c252-4592-4ae6-bd90-bf237dc3ee1d
# Run vortex lattice analysis
sys = solve_case(ac, fs, refs,
		name = "Boing",
		compressible = true,
	)

# ╔═╡ 9b09f4bb-f7a9-460c-aa99-18a78f60ed4c
nfs = nearfield(sys) # Nearfield coefficients (force and moment coefficients)

# ╔═╡ e4cdffdb-33ca-4280-b8cf-965642bdc3af
nfs.CX # Induced drag coefficient (nearfield)

# ╔═╡ aa92101c-7cd1-4c80-8296-15fa126bac25
nfs.CZ # Lift coefficient (nearfield)

# ╔═╡ f9f88f4c-9cf7-466b-b70a-5331eb2cbb5c
nfs.Cm # Pitching moment coefficient

# ╔═╡ 0521760f-4ba0-4910-bf9d-8f345a5616a3
ffs = farfield(sys) # Farfield coefficients (no moment coefficients)

# ╔═╡ 0088977f-7cde-4c9b-9bce-c4977f62a3f7
ffs.CDi # Induced drag coefficient (farfield)

# ╔═╡ 84352c40-13f2-45c3-9244-d996a67777b8
ffs.CL # Lift coefficient (farfield)

# ╔═╡ c60041fa-242f-4847-8ba1-e0bb12c0aeb4
ffs.CL / ffs.CDi # Lift-to-induced drag ratio

# ╔═╡ c0fcf470-4f20-4bbc-adad-dbf82492b1fb
print_coefficients(nfs, ffs)

# ╔═╡ 94e99222-efff-400d-b8b7-d378c53c8e9d
if stab
	# Evaluate the aerodynamic stability derivatives
	dvs = freestream_derivatives(
		sys, 					 # Input the aerodynamics (VortexLatticeSystem)
		# print_components = true, # Print derivatives for all components
		print = true, 		 # Print derivatives for only the aircraft
		farfield = true, 		 # Farfield derivatives (usually unnecessary)
	)
end

# ╔═╡ 6a292063-5989-4058-ab5c-898b1de0de73
if stab
	## Calculate longitudinal stability quantities
	#==============================================#
	
	ac_dvs = dvs.aircraft # Access the derivatives of the aircraft

	# Fuselage correction (COMPUTED USING FUSELAGE VOLUME AT THE BEGINNING)
	Cm_fuse_CL = fuse_Cm_CL(V_f, S_w, c_w, dvs.wing.CZ_al) # Fuselage Cm/CL
	
	x_np = -refs.chord * (ac_dvs.Cm_al / ac_dvs.CZ_al + Cm_fuse_CL) # Neutral point
	x_cp = -refs.chord * ac_dvs.Cm / ac_dvs.CZ # Center of pressure
	
	# Stability position vectors
	r_np = refs.location + [x_np, 0, 0]
	r_cp = refs.location + [x_cp, 0, 0]
	
	SM = (r_np - r_cg).x / refs.chord * 100 # Static margin (%)
end

# ╔═╡ 9e2fbbbb-5c69-4ed2-887f-4913db2d0153
begin
	# Plot meshes
	plt_vlm = plot(
	    # aspect_ratio = 1,
	    xaxis = "x", yaxis = "y", zaxis = "z",
	    zlim = (-0.5, 0.5) .* span(wing_mesh),
	    camera = (φ, ψ),
	)

	# Surfaces
	if aero
		plot!(fuse, label = "Fuselage", alpha = 0.6)
		plot!(wing_mesh, label = "Wing", mac = false)
		plot!(htail_mesh, label = "Horizontal Tail", mac = false)
		plot!(vtail_mesh, label = "Vertical Tail", mac = false)
	else
		plot!(fuse, alpha = 0.3, label = "Fuselage")
		plot!(wing, 0.4, label = "Wing MAC 40%") 			 
		plot!(htail, 0.4, label = "Horizontal Tail MAC 40%") 
		plot!(vtail, 0.4, label = "Vertical Tail MAC 40%")
	end

	# CG
	scatter!(Tuple(r_cg), label = "Center of Gravity (CG)")
	
	# Streamlines
	if streams
		plot!(sys, wing_mesh, 
			span = 4, # Number of points over each spanwise panel
			dist = 40., # Distance of streamlines
			num = 50, # Number of points along streamline
		)
	end

	# Weights
	if weights
		# Iterate over the dictionary
		[ scatter!(Tuple(pos), label = key) for (key, (W, pos)) in W_pos ]
	end

	# Stability
	if stab
		scatter!(Tuple(r_np), label = "Neutral Point (SM = $(round(SM; digits = 2))%)")
		# scatter!(Tuple(r_np_lat), label = "Lat. Neutral Point)")
		scatter!(Tuple(r_cp), label = "Center of Pressure")
	end
end

# ╔═╡ c44ee57c-0cba-4436-9557-b0c7eaf77c62
plt_vlm

# ╔═╡ 312a08dc-7316-44e3-b026-b6ecd95e1abd
plt_vlm

# ╔═╡ 6085715c-9ab0-4fe8-b159-9a814bc572e8
plt_vlm

# ╔═╡ 07842e70-6c91-47cf-b480-28c690e4c0ab
plt_vlm

# ╔═╡ 2dedcfbb-7998-4767-a904-9930bf9bc796
plt_vlm

# ╔═╡ d71d2ebc-0406-4bad-99f4-2ec06d7ec759
plt_vlm

# ╔═╡ 61ec2044-e93e-4a70-8408-8cd48cc4f784
plt_vlm

# ╔═╡ f43d6358-5f1f-40e9-896f-37038ad04986
plt_vlm

# ╔═╡ 7a96bdd1-65b5-48cf-8ebc-36f0ba216965
lon_dvs = longitudinal_stability_derivatives(ac_dvs, refs.speed, W_tot, Iyy, dynamic_pressure(refs), refs.area, refs.chord)

# ╔═╡ 31cdcfd6-70b1-4bef-aecd-78c5d359540c
A_lon = longitudinal_stability_matrix(lon_dvs..., refs.speed, g)

# ╔═╡ 38185599-aa95-4716-9b2e-1af3b2548396
lat_dvs = lateral_stability_derivatives(ac_dvs, refs.speed, W_tot, Ixx, Izz, dynamic_pressure(refs), refs.area, refs.span)

# ╔═╡ da3ec2a7-109b-4f8e-bd5e-521e257b8693
A_lat = lateral_stability_matrix(lat_dvs..., refs.speed, g)

# ╔═╡ de956d60-60b6-47cf-baa6-0cc65ac45877
CD0_fuse = parasitic_drag_coefficient(fuse, refs, x_tr) # Fuselage

# ╔═╡ bc4e06d3-1429-40f2-a2cc-d8c5c2e26872
CD0_wing = parasitic_drag_coefficient(wing_mesh, refs, x_tr) # Wing

# ╔═╡ e8cb0195-51d7-41e9-9e69-7c79e2f5d35f
CD0_htail = parasitic_drag_coefficient(htail_mesh, refs, x_tr) # HTail

# ╔═╡ 27a240c4-b201-4a49-b784-c454ff0f1575
CD0_vtail = parasitic_drag_coefficient(vtail_mesh, refs, x_tr) # VTail

# ╔═╡ 6717ffeb-626b-4ec0-a70d-3727dc8a4f0e
# Summed. YOU MUST ADD MORE BASED ON YOUR COMPONENTS (NACELLE, ETC.)
CD0 = CD0_fuse + CD0_wing + CD0_htail + CD0_vtail

# ╔═╡ e0614b11-3e67-4ce5-90ab-14e245449fcb
CD = CD0 + ffs.CDi # Evaluate total drag coefficient

# ╔═╡ 46433eaf-fc72-4f4f-8dd7-811f4579b5f0
LD_visc = ffs.CL / CD # Evaluate lift-to-drag ratio

# ╔═╡ 4ea94f81-6c34-4c90-a7d4-08bc4927ffae
aircraft = ComponentVector(# some_name = object
	wing = make_horseshoes(wing_mesh),
)

# ╔═╡ 534c46b8-6761-4367-ab1d-e02c241ba9fb
system = solve_case(
	aircraft, # Vortex system as ComponentVector
	fs, 	  # Freestream condition
	refs, 	  # Reference values
	compressible = true, # Compressibility correction
)

# ╔═╡ 6ddf1d64-3880-41db-a31e-40527de5eb16
print_coefficients(system, components = true)

# ╔═╡ 114f5397-b579-4e84-a07a-2187d265117f
nf_coeffs = nearfield(system)

# ╔═╡ a809880f-3a5e-4cee-82f2-18df84796424
L_over_D = nf_coeffs.CZ / nf_coeffs.CX # Lift-to-induced drag ratio

# ╔═╡ a6cd0e16-7a30-4645-a374-38056a40373a
CDi, CY, CL, Cl, Cm, Cn = nf_coeffs # Assign coefficients to variable names

# ╔═╡ 5cea7195-796e-472d-9168-41fb113a7140
function vary_alpha(
		ac,  # Input: Aircraft as a ComponentVector
		α,   # Input: Angle of attack (deg)
		refs # Input: Reference values
   ) 

	# Define freestream with provided angle of attack input.
	fs = Freestream(alpha = α)

	# Solve the case with this freestream condition, and the provided aircraft and reference values.
	system = solve_case(ac, fs, refs, 
		compressible = true
	)

	# Output: Return the system
	return system
end

# ╔═╡ 10815637-b194-49e6-95de-fd74c8a3294a
nearfield(vary_alpha(aircraft, 1.0, refs)) # Example run

# ╔═╡ c2bef0d3-6e6c-4c86-95d7-7b31bd6589e1
function plot_wingload(wing_loads)
    plt_CD = plot(wing_loads[:,1], wing_loads[:,2], ylabel = "CDi", label = "")
    plt_CY = plot(wing_loads[:,1], wing_loads[:,3], ylabel = "CY", label = "")
    plt_CL = begin 
        plot(wing_loads[:,1], wing_loads[:,4], ylabel = "CL", label = "") # CL
        plot!(wing_loads[:,1], wing_loads[:,5], label = "CL_norm") # CL normalized
    end

    # Combine plots
    plot(plt_CD, plt_CY, plt_CL, layout = (3,1), xlabel = "y")
end

# ╔═╡ 6d4960fc-ca67-4a4d-9dee-1722251e40f4


# ╔═╡ e966a3ac-9464-4479-8002-7ae0ed764b9e
alphas = -5:0.5:5 # Angle of attack range

# ╔═╡ 7df3b4cf-22a3-4ca3-a068-13ed7ea94457
systems = [ vary_alpha(aircraft, alpha, refs) for alpha in alphas ];

# ╔═╡ a4d83bde-3857-4abb-bd8a-2af178799360
coeffs = [ nearfield(sys) for sys in systems ]

# ╔═╡ 752ac72f-e22f-4079-8737-bf2d4afa3586
CDis = [ coeff.CX for coeff in coeffs ]

# ╔═╡ 552eaae0-fa30-4b33-a3e9-bf4f3cce8a0b
CLs = [ coeff.CZ for coeff in coeffs ]

# ╔═╡ 050426ca-2091-45c8-9ddd-a898a93b7133
CFs, CMs = surface_coefficients(system; axes = Wind()) # Get coefficients over the surfaces in wind axes

# ╔═╡ d2720c67-73c3-4149-abad-47edb1ac742f
wing_loads = spanwise_loading(wing_mesh, refs, CFs.wing, system.circulations.wing)

# ╔═╡ 183abad4-ad8d-41b8-a0fc-b1217f728b9e
plot_wingload(wing_loads)

# ╔═╡ 0483cc5d-175d-40a5-8cb1-571e98097a0f
function plot_aero(alphas, CLs, CDis)
    plot1 = plot(alphas, CLs, ylabel = "CL", xlabel = "α", label = "")

    plot2 = plot(CDis, CLs, label = "", xlabel = "CDi", ylabel = "CL", title  = "Drag Polar")
	
    plot(plot1, plot2, layout = (2, 1)) 
end


# ╔═╡ a2f75346-2a05-4570-ab7d-54c0cf3bcf89
plot_aero(alphas, CLs, CDis)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AeroFuse = "477c59f4-51f5-487f-bf1e-8db39645b227"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
AeroFuse = "~0.4.10"
DataFrames = "~1.5.0"
Plots = "~1.38.10"
PlutoUI = "~0.7.50"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.1"
manifest_format = "2.0"
project_hash = "f8dd1cb7fab0d816e795b151cf3504e3eabd9a0d"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Accessors]]
deps = ["Compat", "CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "LinearAlgebra", "MacroTools", "Requires", "Test"]
git-tree-sha1 = "c7dddee3f32ceac12abd9a21cd0c4cb489f230d2"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.29"

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    IntervalSetsExt = "IntervalSets"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cc37d689f599e8df4f464b2fa3870ff7db7492ef"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.6.1"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AeroFuse]]
deps = ["Accessors", "ComponentArrays", "CoordinateTransformations", "DelimitedFiles", "DiffResults", "ForwardDiff", "Interpolations", "LabelledArrays", "LinearAlgebra", "MacroTools", "PrettyTables", "RecipesBase", "Roots", "Rotations", "SparseArrays", "SplitApplyCombine", "StaticArrays", "Statistics", "StatsBase", "StructArrays", "Test", "TimerOutputs"]
git-tree-sha1 = "3d24e1869cb0e1b3fe4160da7f6fd495da38e493"
uuid = "477c59f4-51f5-487f-bf1e-8db39645b227"
version = "0.4.10"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SnoopPrecompile", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "38911c7737e123b28182d89027f4216cfc8a9da7"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.4.3"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "43b1a4a8f797c1cddadf60499a8a077d4af2cd2d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.7"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c6d890a52d2c4d55d326439580c3b8d0875a77d9"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.7"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "be6ab11021cd29f0344d5c4357b163af05a48cba"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.21.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.CommonSolve]]
git-tree-sha1 = "9441451ee712d1aec22edad62db1a9af3dc8d852"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.3"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "7a60c856b9fa189eb34f5f8a6f6b5529b7942957"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.6.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.0+0"

[[deps.ComponentArrays]]
deps = ["ArrayInterface", "ChainRulesCore", "ForwardDiff", "Functors", "LinearAlgebra", "Requires", "StaticArrayInterface"]
git-tree-sha1 = "891f08177789faff56f0deda1e23615ec220ce44"
uuid = "b0b7db55-cfe3-40fc-9ded-d10e2dbeff66"
version = "0.13.12"

    [deps.ComponentArrays.extensions]
    ComponentArraysConstructionBaseExt = "ConstructionBase"
    ComponentArraysGPUArraysExt = "GPUArrays"
    ComponentArraysRecursiveArrayToolsExt = "RecursiveArrayTools"
    ComponentArraysReverseDiffExt = "ReverseDiff"
    ComponentArraysSciMLBaseExt = "SciMLBase"
    ComponentArraysStaticArraysExt = "StaticArrays"

    [deps.ComponentArrays.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    GPUArrays = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SciMLBase = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.CompositionsBase]]
git-tree-sha1 = "455419f7e328a1a2493cabc6428d79e951349769"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.1"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "b306df2650947e9eb100ec125ff8c65ca2053d30"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.1.1"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "89a9db8d28102b094992472d333674bd1a83ce2a"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.1"

    [deps.ConstructionBase.extensions]
    IntervalSetsExt = "IntervalSets"
    StaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.CoordinateTransformations]]
deps = ["LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "681ea870b918e7cff7111da58791d7f718067a19"
uuid = "150eb455-5306-5404-9cee-2592286d6298"
version = "0.6.2"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "aa51303df86f8626a962fccb878430cdb0a97eee"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.5.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.Dictionaries]]
deps = ["Indexing", "Random", "Serialization"]
git-tree-sha1 = "e82c3c97b5b4ec111f3c1b55228cebc7510525a2"
uuid = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
version = "0.3.25"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "a4ad7ef19d2cdc2eff57abbbe68032b1cd0bd8f8"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.13.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.ExprTools]]
git-tree-sha1 = "c1d06d129da9f55715c6c212866f5b1bddc5fa00"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.9"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "00e252f4d706b3d55a8863432e742bf5717b498d"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.35"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Functors]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "478f8c3145bb91d82c2cf20433e8c1b30df454cc"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.4.4"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "1cd7f0af1aa58abc02ea1d872953a97359cb87fa"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.4"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "efaac003187ccc71ace6c755b197284cd4811bfe"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.72.4"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4486ff47de4c18cb511a0da420efebb314556316"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.72.4+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "d3b3624125c1474292d0d8ed0f65554ac37ddb23"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "69182f9a2d6add3736b7a06ab6416aafdeec2196"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.8.0"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.Indexing]]
git-tree-sha1 = "ce1566720fd6b19ff3411404d4b977acd4814f9f"
uuid = "313cdc1a-70c2-5d6a-ae34-0150d3930a38"
version = "1.1.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "6667aadd1cdee2c6cd068128b3d226ebc4fb0c67"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.9"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "f377670cda23b6b7c1c0b3893e37451c5c1a2185"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.5"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6f2675ef130a300a112286de91973805fcc5ffbc"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.91+0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LabelledArrays]]
deps = ["ArrayInterface", "ChainRulesCore", "ForwardDiff", "LinearAlgebra", "MacroTools", "PreallocationTools", "RecursiveArrayTools", "StaticArrays"]
git-tree-sha1 = "cd04158424635efd05ff38d5f55843397b7416a9"
uuid = "2ee39098-c373-598a-b85f-a56591580800"
version = "1.14.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "8c57307b5d9bb3be1ff2da469063628631d4d51e"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.21"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    DiffEqBiologicalExt = "DiffEqBiological"
    ParameterizedFunctionsExt = "DiffEqBase"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    DiffEqBase = "2b5f629d-d688-5b77-993f-72d75c75574e"
    DiffEqBiological = "eb300fae-53e8-50a0-950c-e21f52c2b7e0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "0a1b7c2863e44523180fdb3146534e265a91870b"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.23"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "cedb76b37bc5a6c702ade66be44f831fa23c681e"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "82d7c9e310fe55aa54996e6f7f94674e2a38fcb4"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.9"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "7fb975217aea8f1bb360cf1dde70bad2530622d2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9ff31d101d987eb9d66bd8b176ac7c277beccd09"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.20+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "478ac6c952fddd4399e71d4779797c538d0ff2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.8"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "1f03a2d339f42dca4a4da149c7e15e9b896ad899"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.1.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "f92e1315dadf8c46561fb9396e525f7200cdc227"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.5"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Preferences", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SnoopPrecompile", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "5434b0ee344eaf2854de251f326df8720f6a7b55"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.38.10"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "5bb5129fdd62a2bbbe17c2756932259acf467386"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.50"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PreallocationTools]]
deps = ["Adapt", "ArrayInterface", "ForwardDiff", "Requires"]
git-tree-sha1 = "f739b1b3cc7b9949af3b35089931f2b58c289163"
uuid = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
version = "0.4.12"

    [deps.PreallocationTools.extensions]
    PreallocationToolsReverseDiffExt = "ReverseDiff"

    [deps.PreallocationTools.weakdeps]
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "2e47054ffe7d0a8872e977c0d09eb4b3d162ebde"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.0.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "548793c7859e28ef026dba514752275ee871169f"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "0c03844e2231e12fda4d0086fd7cbe4098ee8dc5"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+2"

[[deps.Quaternions]]
deps = ["LinearAlgebra", "Random", "RealDot"]
git-tree-sha1 = "da095158bdc8eaccb7890f9884048555ab771019"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.7.4"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "6d7bb727e76147ba18eed998700998e17b8e4911"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.4"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "Requires", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "68078e9fa9130a6a768815c48002d0921a232c11"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.38.4"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "90bc7a7c96410424509e4263e277e43250c05691"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Roots]]
deps = ["ChainRulesCore", "CommonSolve", "Printf", "Setfield"]
git-tree-sha1 = "2505d1dcab54520ed5e0a12583f2877f68bec704"
uuid = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
version = "2.0.13"

    [deps.Roots.extensions]
    RootsForwardDiffExt = "ForwardDiff"
    RootsIntervalRootFindingExt = "IntervalRootFinding"

    [deps.Roots.weakdeps]
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalRootFinding = "d2bf35a9-74e0-55ec-b149-d360ff49b807"

[[deps.Rotations]]
deps = ["LinearAlgebra", "Quaternions", "Random", "StaticArrays", "Statistics"]
git-tree-sha1 = "72a6abdcd088764878b473102df7c09bbc0548de"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.4.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "30449ee12237627992a99d5e30ae63e4d78cd24a"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "77d3c4726515dca71f6d80fbb5e251088defe305"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.18"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "ef28127915f4229c971eb43f3fc075dd3fe91880"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.2.0"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.SplitApplyCombine]]
deps = ["Dictionaries", "Indexing"]
git-tree-sha1 = "48f393b0231516850e39f6c756970e7ca8b77045"
uuid = "03a91e81-4c3e-53e1-a0a4-9c0c8f19dd66"
version = "1.2.2"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "08be5ee09a7632c32695d954a602df96a877bf0d"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.8.6"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "Requires", "SnoopPrecompile", "SparseArrays", "Static", "SuiteSparse"]
git-tree-sha1 = "33040351d2403b84afce74dae2e22d3f5b18edcb"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.4.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "c262c8e978048c2b095be1672c9bee55b4619521"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.24"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "45a7769a04a3cf80da1c1c7c60caf932e6f4c9f7"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.6.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "GPUArraysCore", "StaticArraysCore", "Tables"]
git-tree-sha1 = "521a0e828e98bb69042fec1809c1b5a680eb7389"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.15"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.SymbolicIndexingInterface]]
deps = ["DocStringExtensions"]
git-tree-sha1 = "f8ab052bfcbdb9b48fad2c80c873aa0d0344dfe5"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.2.2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "f548a9e9c490030e545f72074a41edfd0e5bcdd7"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.23"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "ed8d92d9774b077c53e1da50fd81a36af3744c1c"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "868e669ccb12ba16eaf50cb2957ee2ff61261c56"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.29.0+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9ebfc140cc56e8c2156a15ceac2f0302e327ac0a"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+0"
"""

# ╔═╡ Cell order:
# ╟─50f026a9-84f2-4152-a1f6-b3c55c84e8ea
# ╠═d3da7be0-aef5-4ea1-9655-00714ac25557
# ╠═ef767260-419e-4029-b7cd-c202790668a5
# ╠═6f7b9b78-02af-43f1-8f71-8da6f8ac9aea
# ╠═47df8df1-3923-44a1-a19e-845246737b1e
# ╟─f5aadd23-1d7b-4c3b-be6e-111e431357e1
# ╟─f6a0b7bc-4722-49d9-98c8-37822febca88
# ╟─343af23b-4c4d-422b-81d2-4bc4e5407dac
# ╠═2ef0a234-499b-4e23-b7d7-c3fcadd14752
# ╠═6075b162-6315-4bd8-bdff-007f3a278b66
# ╠═c44ee57c-0cba-4436-9557-b0c7eaf77c62
# ╠═26d5c124-3da7-4a5a-b06e-38627b2dd8ac
# ╟─e8a84941-3ab0-461c-9ab8-cb0b5515989f
# ╠═9860d2fa-b497-4377-afe7-367b4a00e50d
# ╠═ef839605-88c5-4469-ae55-47961eb5417b
# ╠═635f6baa-e360-45b2-87de-fedf1ec52b4a
# ╟─65661116-c2a5-4684-aa1d-8514e6310025
# ╟─74330174-edfd-4e13-8bc1-f8c80c163be0
# ╠═1bf4c10a-1801-41be-b06f-677f44a156a7
# ╠═751bf100-1de9-48b0-aeed-c31e3a590521
# ╠═0418bc57-5b5f-4348-95a9-25bb5bce2af4
# ╠═312a08dc-7316-44e3-b026-b6ecd95e1abd
# ╠═6ddf1d64-3880-41db-a31e-40527de5eb16
# ╠═7758fb66-991d-49f7-b8f8-a3549fb0e340
# ╠═183abad4-ad8d-41b8-a0fc-b1217f728b9e
# ╠═a2f75346-2a05-4570-ab7d-54c0cf3bcf89
# ╠═d61de21f-5d28-4bd9-8b41-0d0be92f9e76
# ╠═d54578a4-d0e6-4b18-bc13-477467b2a058
# ╠═79dd19b4-10cc-44a8-ba62-4a7ef1ceb752
# ╠═d154be95-8350-4c38-8b02-10595d9764cd
# ╠═958906a9-75c3-4ead-aafe-2596623b89c0
# ╟─35a249a3-7272-435a-a5d3-5e8ba8a655ca
# ╟─bec4f70a-7ff0-4c0e-8759-758a95831e46
# ╟─cd2e5706-bfc9-4fca-90bd-70460198c9ee
# ╠═187d4c9e-e366-4395-9b3e-b0cefbf9ce5d
# ╠═82731c8d-7819-42d3-afd1-eabfbad8303b
# ╠═da2ef327-9171-4daf-98e2-ed679d6f84e2
# ╟─79a60ed4-5281-4261-90fb-5f2bfc928758
# ╟─3dd1f51b-26e2-44f1-b754-fb58612e7d7c
# ╟─63a82ccb-21e4-4edc-81df-cd9f84953372
# ╠═647698ec-1f80-4ddd-ae98-f40a05ea75c6
# ╠═fbeb3c61-6c88-4aa5-9925-3510a00e366e
# ╠═9ac640ed-b400-46f8-89bc-650a5d2801ff
# ╠═6085715c-9ab0-4fe8-b159-9a814bc572e8
# ╠═7432a455-aff6-4a22-8576-9249f67b5dd7
# ╠═25fb28f6-4571-4b87-8a7d-9465eae537de
# ╠═c1ed6eb3-a0c7-484e-a511-2e13df3a2040
# ╠═185f315c-ccc9-4c9c-be91-f30c8046b27a
# ╠═8ab5fc32-41f1-4492-bc35-7d0cb5864162
# ╟─79978d9e-c28a-4787-9d6a-ac753331111e
# ╠═72c1cb62-58da-40c8-a5ff-5f9325360fe8
# ╠═02dcefce-3b27-441f-a76b-9dba2c7b2b72
# ╠═659c3d72-85e2-4f39-aa49-cbc83066c345
# ╠═a259c6c0-939e-4af0-a1d4-11d088b4c7db
# ╠═8effef36-3f6c-4179-877d-3f0e03863a22
# ╠═edd73ae8-6bf2-4585-9275-166e3ee7a017
# ╟─f2587d9c-8028-46f7-9610-869d9eb15c73
# ╟─117d30e6-1252-4198-b348-6a1e5e798070
# ╠═a62696dc-171a-4978-8de9-0ab643987b41
# ╠═07842e70-6c91-47cf-b480-28c690e4c0ab
# ╟─5342b18a-7fe2-46b4-a53f-91399797b971
# ╟─a26930b4-f8aa-41bf-8375-fac549980ca3
# ╠═21b17672-2800-4876-a83a-b04f5b94cf76
# ╠═bfdc099a-bdac-4b8f-8ef8-a1c2003c6d43
# ╠═b61af5cc-a240-4670-93d0-aeb01208d01d
# ╟─696e35a8-1ece-4a7b-a160-ec6d2a3134c0
# ╟─cb819012-a6cd-462e-bee1-c118ba8f3caf
# ╠═b672ad66-01a4-48b3-a169-02d97d4b9baa
# ╠═5b611e79-5689-4a33-929e-5c77dee7f958
# ╠═c429a2d2-69b9-437d-a138-efee4b118016
# ╠═36b197b3-1971-4c73-96ec-7370002ade1e
# ╠═e358c252-4592-4ae6-bd90-bf237dc3ee1d
# ╟─dfd216a0-817c-43b2-bb0a-e2f5bb28650d
# ╟─c736beb7-6714-4931-9e35-e452a9647682
# ╠═9b09f4bb-f7a9-460c-aa99-18a78f60ed4c
# ╠═e4cdffdb-33ca-4280-b8cf-965642bdc3af
# ╠═aa92101c-7cd1-4c80-8296-15fa126bac25
# ╠═f9f88f4c-9cf7-466b-b70a-5331eb2cbb5c
# ╟─f0ba714d-2710-4558-b078-24ae0faeb1e0
# ╠═0521760f-4ba0-4910-bf9d-8f345a5616a3
# ╠═0088977f-7cde-4c9b-9bce-c4977f62a3f7
# ╠═84352c40-13f2-45c3-9244-d996a67777b8
# ╟─81b627fb-263f-44fb-8e4e-4a4fe075dbc0
# ╠═c60041fa-242f-4847-8ba1-e0bb12c0aeb4
# ╠═c0fcf470-4f20-4bbc-adad-dbf82492b1fb
# ╠═5d5a0da9-07e0-4be1-ba9c-a854299cd23f
# ╠═2dedcfbb-7998-4767-a904-9930bf9bc796
# ╟─3be74cb9-4e2f-483a-ac57-0b80732218e0
# ╟─c2f25eac-7453-420a-bcda-ad70a438358f
# ╠═08c88bf1-72f9-4e54-926f-b8f8fdbb8179
# ╠═07971f8e-fd34-4292-a021-278b567ee3ef
# ╟─737189fe-e73d-4dbc-a172-da713925bd1d
# ╟─521c7938-d392-4831-b62b-bd4221cff162
# ╠═ddfa28f9-de7c-4faa-a998-bdfa1a17a223
# ╠═091fdf20-508c-48a1-aaa5-ad13722a540b
# ╠═70d90871-53ab-402a-9a6d-1dd727e5c6d0
# ╟─5838b73b-a044-4f63-b3b8-88c5b96e0f83
# ╟─27e4439a-9f40-40a9-8603-e80161da8004
# ╠═3c345c72-12cd-4573-a957-5bc5fe3caeb0
# ╠═81f5072b-46e2-466f-8a76-b984d7f3b75e
# ╠═d71d2ebc-0406-4bad-99f4-2ec06d7ec759
# ╟─14a79c53-1d0a-438e-8a9b-e7dafbef1322
# ╟─7a05752f-522c-4f5e-84fc-bd9624deb07e
# ╠═c197c2fd-cd78-4aa6-83c1-bb34d6579c80
# ╠═dc99a9c2-cb70-4498-b9ed-6295fff11884
# ╠═a34e91e7-927e-4b0a-b72b-0813e098f000
# ╠═516a6341-aa4d-4811-aaa1-c65ed92b0357
# ╠═ff34f0e0-dc07-467a-88cb-6d287ba4463b
# ╠═774c9f2b-3e2f-4f74-bf22-28745063cfae
# ╟─38e5cf39-0766-400b-9312-e39b673faac6
# ╠═f1b551ba-4f27-4bec-af09-7554c2e76045
# ╠═6e8dead0-6af0-4324-928d-e19b295c9b5b
# ╠═623332dc-d56a-478e-84ac-32fe9123c0c2
# ╠═61ec2044-e93e-4a70-8408-8cd48cc4f784
# ╟─140c3020-58b1-439b-9772-7b17b5915b40
# ╟─10632c4e-7aa0-4f99-a9ff-39ccad2da377
# ╟─7867678b-5910-45a5-a8fd-59ace4d0dc7b
# ╟─d02fe0a3-3523-4239-9b74-bf4e00b5e891
# ╠═94e99222-efff-400d-b8b7-d378c53c8e9d
# ╟─8bcd6ea1-6711-4a0c-8f1c-bba12e843808
# ╟─37d4a03a-af97-4208-bfa1-6bb057f0f988
# ╠═97929c85-54c0-4976-95b6-d70364c68035
# ╠═6a292063-5989-4058-ab5c-898b1de0de73
# ╠═06427107-e04a-44d0-9db1-76a9c7519895
# ╠═f43d6358-5f1f-40e9-896f-37038ad04986
# ╠═072e8834-0a19-456a-b818-f436a847490b
# ╟─0859eeeb-0dbf-4f39-a7a4-a5f828726b16
# ╠═50751fc6-5704-4487-ba2f-9f37c21fbdfc
# ╠═7a96bdd1-65b5-48cf-8ebc-36f0ba216965
# ╠═31cdcfd6-70b1-4bef-aecd-78c5d359540c
# ╠═38185599-aa95-4716-9b2e-1af3b2548396
# ╠═da3ec2a7-109b-4f8e-bd5e-521e257b8693
# ╟─90ac16c3-37d4-42ae-a9ed-4572c49397dc
# ╟─27c05748-4570-4420-af08-15fd2a31a373
# ╟─05fd1ff1-b47d-4452-b0c0-b4a39a5b3d7e
# ╠═0c614e7c-27d9-45cf-90a2-699a02493a72
# ╠═de956d60-60b6-47cf-baa6-0cc65ac45877
# ╠═bc4e06d3-1429-40f2-a2cc-d8c5c2e26872
# ╠═e8cb0195-51d7-41e9-9e69-7c79e2f5d35f
# ╠═27a240c4-b201-4a49-b784-c454ff0f1575
# ╠═6717ffeb-626b-4ec0-a70d-3727dc8a4f0e
# ╟─04f09813-3514-4e81-93ce-a3bf28610537
# ╠═e0614b11-3e67-4ce5-90ab-14e245449fcb
# ╟─71a51430-9b8c-4f22-b41d-3a1532df159c
# ╟─e6439db0-d98a-4ae5-b706-c606f1caea4a
# ╠═46433eaf-fc72-4f4f-8dd7-811f4579b5f0
# ╟─dee2f972-3b85-473b-adc1-5c3888c5daa0
# ╠═be8235a9-2633-41ac-a6d1-d2330d7146f9
# ╟─f020f165-37f9-45ed-8d21-1e8fc8e1591a
# ╠═9e2fbbbb-5c69-4ed2-887f-4913db2d0153
# ╠═5693bae3-e676-497c-baef-c84472270cef
# ╠═f7d454c6-43a6-4818-b20a-6950323f6365
# ╠═4ea94f81-6c34-4c90-a7d4-08bc4927ffae
# ╠═534c46b8-6761-4367-ab1d-e02c241ba9fb
# ╠═114f5397-b579-4e84-a07a-2187d265117f
# ╠═a809880f-3a5e-4cee-82f2-18df84796424
# ╠═a6cd0e16-7a30-4645-a374-38056a40373a
# ╠═5cea7195-796e-472d-9168-41fb113a7140
# ╠═10815637-b194-49e6-95de-fd74c8a3294a
# ╠═c2bef0d3-6e6c-4c86-95d7-7b31bd6589e1
# ╠═6d4960fc-ca67-4a4d-9dee-1722251e40f4
# ╠═e966a3ac-9464-4479-8002-7ae0ed764b9e
# ╠═7df3b4cf-22a3-4ca3-a068-13ed7ea94457
# ╠═a4d83bde-3857-4abb-bd8a-2af178799360
# ╠═752ac72f-e22f-4079-8737-bf2d4afa3586
# ╠═552eaae0-fa30-4b33-a3e9-bf4f3cce8a0b
# ╠═050426ca-2091-45c8-9ddd-a898a93b7133
# ╠═d2720c67-73c3-4149-abad-47edb1ac742f
# ╠═0483cc5d-175d-40a5-8cb1-571e98097a0f
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
