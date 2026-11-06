class_name LivingCityController
extends Node3D

## Master Cyberpunk City Simulation Engine for "Neo-Veridia // Sector-9".
## Implements 4 interdependent simulation layers:
## 1. Urban Weather & Atmosphere: Dynamic Acid-Rain downpours, Neon Mist, and Golden/Violet Cyber-Dusk cycles.
## 2. Citizen AI & Character Ecosystem:
##    - Commuters & Corporate Workers (walking to bus stops, queuing to board transit, ducking under awnings in rain)
##    - Street Vendors & Shopkeepers (tending steaming ramen/cyber-kiosk stalls)
##    - Autonomous Law-Enforcement Security Drones (hovering 3D drones with sweeping volumetric scanner beams that track speeding cars)
##    - Subculture Drifters (socializing in neon alleyways & bioluminescent plazas)
##    - Reactive Micro-Interactions (dodging & startling when the player's car speeds close by)
## 3. Traffic & Transportation Systems (The Moving Veins):
##    - Elevated Superconducting Mag-Lev Trains gliding along Sector 3 guideways
##    - Autonomous Street Fleet (Public Buses stopping at stations for 4s, Cyber-Taxis, Kei Trucks, Police Cruisers, and weaving Scooter Couriers)
##    - Dynamic Intersection Traffic Signals (Green -> Amber -> Red cycling, vehicle braking/queuing at red lights, and horn honking)
## 4. Multi-Layered Procedural Audio Bed:
##    - District-shifting Cyberpunk Synthwave Sub-Bass Pad, Mag-Lev hum, Security Drone rotor chirp, Dual-Tone Cyber-Horns, Wail Sirens, and 60Hz Neon Buzz.

enum WeatherState {
	NEON_MIST,
	ACID_RAIN,
	CYBER_CLEAR
}

enum CitizenRole {
	COMMUTER,
	SKYBRIDGE_COMMUTER,
	VENDOR,
	DRIFTER,
	TERRACE_COMMUTER
}

## Each pedestrian has a personality that decides how they react to the player's car.
enum Persona {
	TIMID,     # Notices a car early and jumps back well clear
	CURIOUS,   # Leans toward the road to watch the car go by
	OBLIVIOUS, # Barely notices; keeps walking
	FRIENDLY,  # Stops and waves the car through
}

## Each traffic vehicle drives with an attitude of its own.
enum TrafficPersona {
	POLITE,     # Eases off and pulls aside to let the player past
	AGGRESSIVE, # Speeds up to hold its line and honks a lot
	TOURIST,    # Drifts slowly along, unhurried
	COURIER,    # Weaves through gaps (scooters)
}

var main_node: Node
var track_len: float = 2800.0
var road_half: float = 11.5
var _time: float = 0.0

# 1. Dynamic Weather & Acid-Rain Particle System (defaults to clear golden-hour haze like reference image)
var weather_state: int = WeatherState.CYBER_CLEAR
var _weather_timer: float = 0.0
var _rain_particles: GPUParticles3D
var _synth_player: AudioStreamPlayer

# 2. Moving Elevated Monorail Trains (full-loop elevated guideway at y = 13.6m)
var _el_trains: Array[Dictionary] = []
var _el_start_offset: float = 20.0
var _el_end_offset: float = 2780.0
var _el_lateral: float = -13.2
var _el_height: float = 13.65

# 3. Citizen AI Ecosystem (Commuters, Vendors, Drifters & Skybridge Walkers)
var _citizens: Array[Dictionary] = []
var _bus_stop_offsets: Array[float] = []
var _awning_offsets: Array[float] = []

# 4. Autonomous Hovering Security Drones
var _security_drones: Array[Dictionary] = []

# 5. Autonomous Traffic Fleet & Intersection Signal Network
var _traffic_vehicles: Array[Dictionary] = []
var _traffic_signals: Array[Dictionary] = []
var _horn_stream: AudioStreamWAV
var _ped_persona_seq: int = 0

# 6. Dynamic Lighting (Quad-Strobes, Flickering Neon, Holographic Portals)
var _strobe_lights: Array[Dictionary] = []
var _neon_lights: Array[Dictionary] = []
var _holo_materials: Array[StandardMaterial3D] = []


func setup(p_main: Node) -> void:
	main_node = p_main
	track_len = float(main_node.get("track_length"))
	road_half = float(main_node.get("ROAD_HALF_WIDTH"))
	_el_start_offset = 0.0
	_el_end_offset = track_len
	_el_lateral = road_half + 2.0
	_el_height = 11.2
	_horn_stream = _create_horn_wav()
	_setup_cyberpunk_synth_bed()


## Builds a sleek 5-car white-and-silver futuristic Shinkansen / Mag-Lev bullet monorail train (matching the reference image)
func spawn_bullet_monorail_train(track_root: Node3D, start_offset: float, speed: float, dir: float) -> void:
	var body_white := StandardMaterial3D.new()
	body_white.albedo_color = Color(0.95, 0.96, 0.98)
	body_white.metallic = 0.32
	body_white.roughness = 0.14
	body_white.clearcoat_enabled = true
	body_white.clearcoat = 0.92
	body_white.clearcoat_roughness = 0.05

	var roof_silver := StandardMaterial3D.new()
	roof_silver.albedo_color = Color(0.74, 0.78, 0.84)
	roof_silver.metallic = 0.72
	roof_silver.roughness = 0.20

	var skirt_dark := StandardMaterial3D.new()
	skirt_dark.albedo_color = Color(0.14, 0.16, 0.20)
	skirt_dark.metallic = 0.82
	skirt_dark.roughness = 0.28

	var glass_dark := StandardMaterial3D.new()
	glass_dark.albedo_color = Color(0.04, 0.08, 0.14)
	glass_dark.metallic = 0.94
	glass_dark.roughness = 0.06
	glass_dark.clearcoat_enabled = true
	glass_dark.clearcoat = 0.95

	var stripe_cyan := StandardMaterial3D.new()
	stripe_cyan.albedo_color = Color(0.0, 0.88, 1.0)
	stripe_cyan.emission_enabled = true
	stripe_cyan.emission = Color(0.0, 0.88, 1.0)
	stripe_cyan.emission_energy_multiplier = 2.4

	var headlight_mat := StandardMaterial3D.new()
	headlight_mat.albedo_color = Color(1.0, 0.98, 0.90)
	headlight_mat.emission_enabled = true
	headlight_mat.emission = Color(1.0, 0.96, 0.85)
	headlight_mat.emission_energy_multiplier = 4.2

	# Spawn 5 articulated monorail cars that independently follow the guideway curve
	for car_idx in [-2, -1, 0, 1, 2]:
		var car_root := Node3D.new()
		car_root.name = "BulletMonorailCar_%d_%d" % [_el_trains.size(), car_idx + 2]

		# Lower Mag-Lev bogie saddle skirt wrapping the concrete guideway beam
		var skirt := BoxMesh.new()
		skirt.size = Vector3(2.68, 0.72, 9.75)
		skirt.material = skirt_dark
		var sk_inst := MeshInstance3D.new()
		sk_inst.mesh = skirt
		sk_inst.position = Vector3(0.0, 0.35, 0.0)
		car_root.add_child(sk_inst)

		var hull := BoxMesh.new()
		hull.size = Vector3(2.58, 2.25, 9.8)
		hull.material = body_white
		var h_inst := MeshInstance3D.new()
		h_inst.mesh = hull
		h_inst.position = Vector3(0.0, 1.32, 0.0)
		car_root.add_child(h_inst)

		var roof := BoxMesh.new()
		roof.size = Vector3(2.15, 0.36, 9.5)
		roof.material = roof_silver
		var r_inst := MeshInstance3D.new()
		r_inst.mesh = roof
		r_inst.position = Vector3(0.0, 2.58, 0.0)
		car_root.add_child(r_inst)

		var win_band := BoxMesh.new()
		win_band.size = Vector3(2.65, 0.84, 8.9)
		win_band.material = glass_dark
		var w_inst := MeshInstance3D.new()
		w_inst.mesh = win_band
		w_inst.position = Vector3(0.0, 1.66, 0.0)
		car_root.add_child(w_inst)

		var trim := BoxMesh.new()
		trim.size = Vector3(2.68, 0.16, 9.85)
		trim.material = stripe_cyan
		var t_inst := MeshInstance3D.new()
		t_inst.mesh = trim
		t_inst.position = Vector3(0.0, 0.86, 0.0)
		car_root.add_child(t_inst)

		# Inter-car articulated accordion bellows gangway
		if car_idx < 2:
			var bellows := BoxMesh.new()
			bellows.size = Vector3(2.32, 2.05, 0.85)
			bellows.material = skirt_dark
			var b_inst := MeshInstance3D.new()
			b_inst.mesh = bellows
			b_inst.position = Vector3(0.0, 1.32, 5.2)
			car_root.add_child(b_inst)

		# Sculpted aerodynamic Shinkansen nose cone on lead (+2) and tail (-2) cars
		if abs(car_idx) == 2:
			var nose_sign: float = signf(float(car_idx))
			var nose := BoxMesh.new()
			nose.size = Vector3(2.36, 1.55, 2.8)
			nose.material = body_white
			var n_inst := MeshInstance3D.new()
			n_inst.mesh = nose
			n_inst.position = Vector3(0.0, 0.98, nose_sign * 6.0)
			car_root.add_child(n_inst)

			var nose_tip := BoxMesh.new()
			nose_tip.size = Vector3(1.95, 0.92, 1.8)
			nose_tip.material = body_white
			var nt_inst := MeshInstance3D.new()
			nt_inst.mesh = nose_tip
			nt_inst.position = Vector3(0.0, 0.68, nose_sign * 7.8)
			car_root.add_child(nt_inst)

			var cockpit := BoxMesh.new()
			cockpit.size = Vector3(2.22, 0.78, 2.4)
			cockpit.material = glass_dark
			var c_inst := MeshInstance3D.new()
			c_inst.mesh = cockpit
			c_inst.rotation_degrees.x = nose_sign * 16.0
			c_inst.position = Vector3(0.0, 1.65, nose_sign * 5.4)
			car_root.add_child(c_inst)

			var hlight := BoxMesh.new()
			hlight.size = Vector3(1.85, 0.18, 0.16)
			hlight.material = headlight_mat
			var hl_inst := MeshInstance3D.new()
			hl_inst.mesh = hlight
			hl_inst.position = Vector3(0.0, 0.85, nose_sign * 8.68)
			car_root.add_child(hl_inst)

		track_root.add_child(car_root)
		register_el_train(car_root, start_offset + float(car_idx) * 10.4, speed, dir)


func _setup_acid_rain_particles() -> void:
	_rain_particles = GPUParticles3D.new()
	_rain_particles.name = "CyberpunkAcidRain"
	_rain_particles.amount = 1400
	_rain_particles.lifetime = 0.85
	_rain_particles.visibility_aabb = AABB(Vector3(-45.0, -20.0, -45.0), Vector3(90.0, 50.0, 90.0))

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(38.0, 2.0, 38.0)
	pmat.direction = Vector3(-0.08, -1.0, 0.05).normalized()
	pmat.spread = 2.5
	pmat.initial_velocity_min = 26.0
	pmat.initial_velocity_max = 32.0
	pmat.gravity = Vector3(0.0, -18.0, 0.0)
	_rain_particles.process_material = pmat

	var drop_mesh := BoxMesh.new()
	drop_mesh.size = Vector3(0.018, 0.65, 0.018)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.albedo_color = Color(0.45, 0.88, 1.0, 0.38)
	drop_mesh.material = drop_mat
	_rain_particles.draw_pass_1 = drop_mesh
	add_child(_rain_particles)


func _setup_cyberpunk_synth_bed() -> void:
	_synth_player = AudioStreamPlayer.new()
	_synth_player.name = "CyberpunkDistrictSynth"
	_synth_player.stream = _create_cyberpunk_synth_wav()
	_synth_player.volume_db = -15.0
	_synth_player.autoplay = true
	add_child(_synth_player)


func register_bus_stop(offset: float) -> void:
	_bus_stop_offsets.append(offset)


func register_awning(offset: float) -> void:
	_awning_offsets.append(offset)


func register_el_train(node: Node3D, start_offset: float, speed: float, dir: float) -> void:
	# Undercarriage cyan superconducting Mag-Lev plasma glow + warm cabin light + rail hum
	var maglev_glow := OmniLight3D.new()
	maglev_glow.light_color = Color(0.0, 0.92, 1.0)
	maglev_glow.light_energy = 4.2
	maglev_glow.omni_range = 22.0
	maglev_glow.position = Vector3(0.0, -0.4, 0.0)
	node.add_child(maglev_glow)

	var cabin_light := OmniLight3D.new()
	cabin_light.light_color = Color(1.0, 0.88, 0.72)
	cabin_light.light_energy = 2.6
	cabin_light.omni_range = 16.0
	cabin_light.position = Vector3(0.0, 1.2, 0.0)
	node.add_child(cabin_light)

	var audio := AudioStreamPlayer3D.new()
	audio.stream = _create_train_rumble_wav()
	audio.unit_size = 25.0
	audio.max_distance = 110.0
	audio.volume_db = -6.0
	audio.autoplay = true
	node.add_child(audio)

	_el_trains.append({
		"node": node,
		"offset": start_offset,
		"speed": speed,
		"dir": dir
	})


func register_pedestrian(node: Node3D, offset: float, lat: float, speed: float, dir: float, base_scale: float, phase: float, role: int = CitizenRole.COMMUTER, elev_y: float = 0.40, bridge_span: float = 0.0, z_local: float = 0.0) -> void:
	# Commuters are dealt a personality in rotation so the street feels mixed; others are stationary.
	var persona: int = Persona.OBLIVIOUS
	if role == CitizenRole.COMMUTER or role == CitizenRole.SKYBRIDGE_COMMUTER or role == CitizenRole.TERRACE_COMMUTER:
		persona = _ped_persona_seq % 4
		_ped_persona_seq += 1
	_citizens.append({
		"node": node,
		"offset": offset,
		"base_lat": lat,
		"lat": lat,
		"speed": speed,
		"dir": dir,
		"scale": base_scale,
		"phase": phase,
		"role": role,
		"elev_y": elev_y,
		"bridge_span": bridge_span,
		"z_local": z_local,
		"wait_timer": 0.0,
		"dodge_timer": 0.0,
		"watch_timer": 0.0,
		"wave_timer": 0.0,
		"persona": persona
	})


func spawn_security_drone(track_root: Node3D, offset: float, lat: float, patrol_speed: float, dir: float, seed_phase: float) -> void:
	var drone_root := Node3D.new()
	drone_root.name = "CyberSecurityDrone_%d" % _security_drones.size()

	# Armored dark-chrome spherical chassis
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.10, 0.12, 0.16)
	body_mat.metallic = 0.92
	body_mat.roughness = 0.22
	var sphere := SphereMesh.new()
	sphere.radius = 0.42
	sphere.height = 0.72
	sphere.material = body_mat
	var body_inst := MeshInstance3D.new()
	body_inst.mesh = sphere
	drone_root.add_child(body_inst)

	# Glowing cyan plasma thruster halo ring
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.0, 0.95, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.0, 0.95, 1.0)
	ring_mat.emission_energy_multiplier = 4.5
	var torus := TorusMesh.new()
	torus.inner_radius = 0.52
	torus.outer_radius = 0.68
	torus.material = ring_mat
	var ring_inst := MeshInstance3D.new()
	ring_inst.mesh = torus
	drone_root.add_child(ring_inst)

	# Crimson optical scanner eye
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.08, 0.18)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.08, 0.18)
	eye_mat.emission_energy_multiplier = 5.5
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.14
	eye_mesh.height = 0.28
	eye_mesh.material = eye_mat
	var eye_inst := MeshInstance3D.new()
	eye_inst.mesh = eye_mesh
	eye_inst.position = Vector3(0.0, -0.08, -0.38)
	drone_root.add_child(eye_inst)

	# Downward sweeping volumetric optical scanner beam (SpotLight3D)
	var scanner := SpotLight3D.new()
	scanner.light_color = Color(1.0, 0.12, 0.25)
	scanner.light_energy = 5.5
	scanner.spot_range = 18.0
	scanner.spot_angle = 28.0
	scanner.rotation_degrees.x = -65.0
	scanner.distance_fade_enabled = true
	scanner.distance_fade_begin = 90.0
	scanner.distance_fade_length = 25.0
	drone_root.add_child(scanner)

	# Drone rotor & telemetry chirp audio
	var drone_audio := AudioStreamPlayer3D.new()
	drone_audio.stream = _create_drone_hum_wav()
	drone_audio.unit_size = 14.0
	drone_audio.max_distance = 55.0
	drone_audio.volume_db = -12.0
	drone_audio.autoplay = true
	drone_root.add_child(drone_audio)

	track_root.add_child(drone_root)
	_security_drones.append({
		"node": drone_root,
		"scanner": scanner,
		"offset": offset,
		"lat": lat,
		"speed": patrol_speed,
		"dir": dir,
		"phase": seed_phase,
		"scan_timer": 0.0
	})


const CAR_CONCEPT_SCENE := preload("res://models/car_concept.glb")
const HD_TAXI_SCENE := preload("res://models/city_hd/2001_toyota_crown_comfort_s10_clean.glb")
const HD_CITY_BUS_SCENE := preload("res://models/city_hd/isuzu_erga_mio_bus_clean.glb")
const MODEL_DELIVERY_TRUCK_SCENE := preload("res://models/props/delivery_truck.glb")
const HD_KEI_TRUCK_SCENE := preload("res://models/city_hd/1984_suzuki_kei_truck_clean.glb")
const LOGO_NODES := ["License Plate", "InteriorSteeringEmblem"]
const LOGO_EMISSIVE_MATERIALS := ["Brake", "Hardware", "Mirror"]


static func _compute_local_aabb(node: Node, acc_xform: Transform3D, state: Dictionary) -> void:
	var cur_xform := acc_xform
	if node is Node3D:
		var n3d := node as Node3D
		if not n3d.visible:
			return
		cur_xform = acc_xform * n3d.transform
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			var maabb: AABB = mi.mesh.get_aabb()
			for ix in 2:
				for iy in 2:
					for iz in 2:
						var corner := maabb.position + Vector3(
							maabb.size.x * float(ix),
							maabb.size.y * float(iy),
							maabb.size.z * float(iz)
						)
						var pt: Vector3 = cur_xform * corner
						if not state["has"]:
							state["min"] = pt
							state["max"] = pt
							state["has"] = true
						else:
							state["min"] = (state["min"] as Vector3).min(pt)
							state["max"] = (state["max"] as Vector3).max(pt)
	for child in node.get_children():
		_compute_local_aabb(child, cur_xform, state)


static func normalize_and_ground_instance(inst: Node3D, target_length: float, forward_flip_deg: float = 0.0) -> Node3D:
	var wrapper := Node3D.new()
	var pivot := Node3D.new()
	wrapper.add_child(pivot)
	pivot.add_child(inst)

	var st1 := {"has": false, "min": Vector3.ZERO, "max": Vector3.ZERO}
	_compute_local_aabb(inst, Transform3D.IDENTITY, st1)
	if not st1["has"]:
		return wrapper

	var raw_size: Vector3 = (st1["max"] as Vector3) - (st1["min"] as Vector3)
	var base_yaw: float = 90.0 if raw_size.x > raw_size.z else 0.0
	var total_yaw: float = base_yaw + forward_flip_deg
	var rot_basis := Basis(Vector3.UP, deg_to_rad(total_yaw))

	var st2 := {"has": false, "min": Vector3.ZERO, "max": Vector3.ZERO}
	_compute_local_aabb(inst, Transform3D(rot_basis, Vector3.ZERO), st2)
	var rot_min: Vector3 = st2["min"]
	var rot_max: Vector3 = st2["max"]
	var rot_size: Vector3 = rot_max - rot_min
	var sc: float = target_length / maxf(0.05, rot_size.z)

	var scaled_min: Vector3 = rot_min * sc
	var scaled_max: Vector3 = rot_max * sc
	var center_x: float = (scaled_min.x + scaled_max.x) * 0.5
	var center_z: float = (scaled_min.z + scaled_max.z) * 0.5
	var bottom_y: float = scaled_min.y

	pivot.transform = Transform3D(rot_basis.scaled(Vector3(sc, sc, sc)), Vector3(-center_x, -bottom_y, -center_z))
	return wrapper


func spawn_white_box_truck(track_root: Node3D, offset: float, lat: float, speed: float, dir: float) -> void:
	if not HD_KEI_TRUCK_SCENE:
		return
	var raw_inst := HD_KEI_TRUCK_SCENE.instantiate() as Node3D
	if not raw_inst:
		return
	var idx: int = _traffic_vehicles.size()
	var is_box_van: bool = (idx % 3 != 2)
	var target_len: float = 5.65 if is_box_van else 4.35
	var truck_root := normalize_and_ground_instance(raw_inst, target_len, 180.0)
	truck_root.name = "CommercialDeliveryTruck_%d" % idx

	if is_box_van:
		# Mount a high-roof insulated white commercial logistics box container onto the rear truck bed
		var box_mat := StandardMaterial3D.new()
		box_mat.albedo_color = Color(0.94, 0.95, 0.97)
		box_mat.roughness = 0.28
		box_mat.metallic = 0.18
		box_mat.clearcoat_enabled = true
		box_mat.clearcoat = 0.65
		box_mat.clearcoat_roughness = 0.12

		var trim_mat := StandardMaterial3D.new()
		trim_mat.albedo_color = Color(0.22, 0.25, 0.29)
		trim_mat.metallic = 0.82
		trim_mat.roughness = 0.28

		var cargo_box := MeshInstance3D.new()
		var cmesh := BoxMesh.new()
		cmesh.size = Vector3(1.92, 1.68, 3.35)
		cmesh.material = box_mat
		cargo_box.mesh = cmesh
		cargo_box.position = Vector3(0.0, 1.72, -0.82)
		truck_root.add_child(cargo_box)

		var reefer_unit := MeshInstance3D.new()
		var rmesh := BoxMesh.new()
		rmesh.size = Vector3(1.25, 0.45, 0.38)
		rmesh.material = trim_mat
		reefer_unit.mesh = rmesh
		reefer_unit.position = Vector3(0.0, 2.22, 0.98)
		truck_root.add_child(reefer_unit)

	track_root.add_child(truck_root)
	register_traffic_vehicle(truck_root, offset, lat, speed, dir, 1.0, 0.22, 0.0, "truck")


func spawn_sleek_sedan(track_root: Node3D, offset: float, lat: float, speed: float, dir: float, paint_col: Color) -> void:
	var idx: int = _traffic_vehicles.size()
	if idx % 3 == 1 and HD_TAXI_SCENE:
		var taxi_raw := HD_TAXI_SCENE.instantiate() as Node3D
		if taxi_raw:
			var taxi_root := normalize_and_ground_instance(taxi_raw, 4.70, 0.0)
			taxi_root.name = "AutonomousCrownTaxi_%d" % idx
			track_root.add_child(taxi_root)
			register_traffic_vehicle(taxi_root, offset, lat, speed, dir, 1.0, 0.22, 0.0, "sedan")
			return

	var model := CAR_CONCEPT_SCENE.instantiate() as Node3D
	if not model:
		return

	for node_name: String in LOGO_NODES:
		var logo := model.find_child(node_name, true, false) as Node3D
		if logo:
			logo.visible = false

	# Drop the glTF posed spin/steer on the 4 wheels while preserving Body axes
	for wname in ["WheelFrontL", "WheelFrontR", "WheelRearL", "WheelRearR"]:
		var wnode := model.find_child(wname, true, false) as Node3D
		if wnode:
			wnode.transform.basis = Basis.IDENTITY

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.06, 0.10, 0.65)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic = 0.90
	glass_mat.roughness = 0.05

	for mi_node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		if not mi.mesh:
			continue
		for s_i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s_i) as StandardMaterial3D
			if not mat:
				continue
			mat.ao_on_uv2 = true
			if mat.resource_name.begins_with("Paint") or mat.resource_name in ["Brakelight", "Headlight", "Rim1", "Rim2"]:
				var dup := mat.duplicate() as StandardMaterial3D
				if dup.resource_name.begins_with("Paint"):
					dup.uv1_scale = Vector3(30.0, 30.0, 1.0)
					dup.ao_enabled = false
					dup.metallic = 0.58
					dup.clearcoat_enabled = true
					dup.clearcoat = 1.0
					dup.clearcoat_roughness = 0.03
					if dup.resource_name.begins_with("Paint 1"):
						dup.albedo_color = paint_col
						dup.roughness = 0.16
				mi.set_surface_override_material(s_i, dup)
			elif mat.resource_name == "Glass":
				mi.set_surface_override_material(s_i, glass_mat)
			elif mat.resource_name == "Tireside":
				var t_dup := mat.duplicate() as StandardMaterial3D
				t_dup.albedo_texture = null
				t_dup.albedo_color = Color(0.05, 0.05, 0.05)
				t_dup.roughness = 0.85
				t_dup.normal_enabled = false
				mi.set_surface_override_material(s_i, t_dup)
			elif mat.resource_name == "Tiretread":
				var tr_dup := mat.duplicate() as StandardMaterial3D
				tr_dup.albedo_color = Color(0.04, 0.04, 0.04)
				tr_dup.roughness = 0.90
				mi.set_surface_override_material(s_i, tr_dup)
			elif mat.resource_name in LOGO_EMISSIVE_MATERIALS:
				var e_dup := mat.duplicate() as StandardMaterial3D
				e_dup.emission_enabled = false
				mi.set_surface_override_material(s_i, e_dup)

	var car_root := normalize_and_ground_instance(model, 4.55, 0.0)
	car_root.name = "AutonomousCyberSedan_%d" % idx
	track_root.add_child(car_root)
	register_traffic_vehicle(car_root, offset, lat, speed, dir, 1.0, 0.22, 0.0, "sedan")


func spawn_futuristic_city_bus(track_root: Node3D, offset: float, lat: float, speed: float, dir: float, _accent_col: Color) -> void:
	if not HD_CITY_BUS_SCENE:
		return
	var bus_raw := HD_CITY_BUS_SCENE.instantiate() as Node3D
	if not bus_raw:
		return
	var bus_root := normalize_and_ground_instance(bus_raw, 10.4, 0.0)
	bus_root.name = "AutonomousTransitBus_%d" % _traffic_vehicles.size()
	track_root.add_child(bus_root)
	register_traffic_vehicle(bus_root, offset, lat, speed, dir, 1.0, 0.22, 0.0, "bus")


func register_traffic_vehicle(node: Node3D, offset: float, lat: float, speed: float, dir: float, base_scale: float, y_offset: float, rot_y_Fix: float, vtype: String) -> void:
	# Attach forward cyber-headlight & rear neon tailbar glow scaled to true metric coordinates
	var inv_sc: float = 1.0 / maxf(0.005, base_scale)
	var fwd_local := Vector3(0.0, 0.85, 2.4).rotated(Vector3.UP, deg_to_rad(-rot_y_Fix)) * inv_sc
	var rear_local := Vector3(0.0, 0.85, -2.4).rotated(Vector3.UP, deg_to_rad(-rot_y_Fix)) * inv_sc

	var headlight := OmniLight3D.new()
	headlight.light_color = Color(0.85, 0.96, 1.0)
	headlight.light_energy = 1.0
	headlight.light_specular = 0.08
	headlight.omni_range = 6.5
	headlight.distance_fade_enabled = true
	headlight.distance_fade_begin = 75.0
	headlight.distance_fade_length = 25.0
	headlight.position = fwd_local
	node.add_child(headlight)

	var taillight := OmniLight3D.new()
	taillight.light_color = Color(1.0, 0.08, 0.18)
	taillight.light_energy = 0.9
	taillight.light_specular = 0.08
	taillight.omni_range = 5.0
	taillight.distance_fade_enabled = true
	taillight.distance_fade_begin = 75.0
	taillight.distance_fade_length = 25.0
	taillight.position = rear_local
	node.add_child(taillight)

	var horn_player := AudioStreamPlayer3D.new()
	horn_player.stream = _horn_stream
	horn_player.unit_size = 20.0
	horn_player.max_distance = 75.0
	horn_player.volume_db = -6.0
	node.add_child(horn_player)

	# Give each vehicle an attitude; cargo and buses are laid back, scooters weave, sedans mix.
	var persona: int = TrafficPersona.POLITE
	match vtype:
		"bus":
			persona = TrafficPersona.POLITE
		"truck":
			persona = TrafficPersona.TOURIST
		"scooter":
			persona = TrafficPersona.COURIER
		_:
			persona = [TrafficPersona.POLITE, TrafficPersona.AGGRESSIVE, TrafficPersona.TOURIST][_traffic_vehicles.size() % 3]
	_traffic_vehicles.append({
		"node": node,
		"offset": offset,
		"base_lat": lat,
		"speed": speed,
		"cur_speed": speed,
		"dir": dir,
		"scale": base_scale,
		"y_offset": y_offset,
		"rot_fix": rot_y_Fix,
		"vtype": vtype,
		"persona": persona,
		"stop_timer": 0.0,
		"last_stop_offset": -999.0,
		"horn_cooldown": 0.0,
		"horn_player": horn_player
	})


func register_traffic_signal(offset: float, signal_light: OmniLight3D, phase_offset: float) -> void:
	_traffic_signals.append({
		"offset": offset,
		"light": signal_light,
		"phase": phase_offset,
		"state": 0 # 0 = GREEN, 1 = YELLOW, 2 = RED
	})


func register_strobe(light: OmniLight3D, base_energy: float, is_blue: bool) -> void:
	_strobe_lights.append({
		"light": light,
		"base_energy": base_energy,
		"is_blue": is_blue
	})


func register_neon_light(light: OmniLight3D, screen_mat: StandardMaterial3D, base_energy: float, seed_val: float) -> void:
	_neon_lights.append({
		"light": light,
		"mat": screen_mat,
		"base_energy": base_energy,
		"seed": seed_val
	})


func register_holo_arch(mat: StandardMaterial3D) -> void:
	_holo_materials.append(mat)


func add_siren_emitter(pos: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	player.name = "DistantEmergencySiren"
	player.stream = _create_siren_wav()
	player.unit_size = 28.0
	player.max_distance = 145.0
	player.volume_db = -11.0
	player.autoplay = true
	player.position = pos
	add_child(player)


func add_neon_hum_emitter(pos: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	player.name = "NeonTransformerHum"
	player.stream = _create_neon_hum_wav()
	player.unit_size = 16.0
	player.max_distance = 55.0
	player.volume_db = -14.0
	player.autoplay = true
	player.position = pos
	add_child(player)


## The player sounds their horn: nearby pedestrians react by personality and traffic honks back.
func honk_from(pos: Vector3) -> void:
	for cit in _citizens:
		var node: Node3D = cit.node
		if not is_instance_valid(node) or node.global_position.distance_squared_to(pos) > 625.0: # 25m
			continue
		match int(cit.get("persona", Persona.OBLIVIOUS)):
			Persona.TIMID:
				cit.dodge_timer = maxf(float(cit.dodge_timer), 1.6)
			Persona.CURIOUS:
				cit.watch_timer = maxf(float(cit.get("watch_timer", 0.0)), 2.0)
			Persona.FRIENDLY:
				cit.wave_timer = maxf(float(cit.get("wave_timer", 0.0)), 2.2)
			_:
				pass
	for veh in _traffic_vehicles:
		var vn: Node3D = veh.node
		if is_instance_valid(vn) and vn.global_position.distance_squared_to(pos) < 1600.0: # 40m
			var hp: AudioStreamPlayer3D = veh.horn_player
			if is_instance_valid(hp) and not hp.playing:
				hp.play()


func _process(delta: float) -> void:
	if not is_instance_valid(main_node):
		return
	_time += delta

	var player_car: Node3D = main_node.get("car")
	var player_pos: Vector3 = player_car.global_position if is_instance_valid(player_car) else Vector3.ZERO
	var cam: Camera3D = main_node.get("camera")

	# 1. District Synth Modulation
	if is_instance_valid(_synth_player) and is_instance_valid(player_car):
		var curve: Curve3D = main_node.get("curve")
		if curve:
			var p_off: float = curve.get_closest_offset(player_pos)
			var sector_ratio: float = p_off / maxf(1.0, track_len)
			_synth_player.pitch_scale = lerpf(0.92, 1.12, sin(sector_ratio * TAU) * 0.5 + 0.5)

	# 2. Update Intersection Traffic Signals (Green -> Amber -> Red cycle every 18s)
	for sig in _traffic_signals:
		var cyc: float = fmod(_time + float(sig.phase), 18.0)
		var lgt: OmniLight3D = sig.light
		if cyc < 10.0:
			sig.state = 0 # GREEN
			if is_instance_valid(lgt):
				lgt.light_color = Color(0.10, 1.0, 0.35)
		elif cyc < 12.5:
			sig.state = 1 # AMBER
			if is_instance_valid(lgt):
				lgt.light_color = Color(1.0, 0.72, 0.08)
		else:
			sig.state = 2 # RED
			if is_instance_valid(lgt):
				lgt.light_color = Color(1.0, 0.08, 0.14)

	# 3. Animate Moving Elevated Monorail Trains along the Continuous Elevated Guideway
	for tr in _el_trains:
		var node: Node3D = tr.node
		if not is_instance_valid(node):
			continue
		var cur_o: float = fposmod(float(tr.offset) + float(tr.speed) * float(tr.dir) * delta, track_len)
		tr.offset = cur_o

		var xform: Transform3D = main_node.call("_track_transform", cur_o, 0.0)
		var world_pos: Vector3 = xform * Vector3(_el_lateral, _el_height, 0.0)
		var rot_y := 0.0 if float(tr.dir) > 0.0 else 180.0
		var b := xform.basis.rotated(xform.basis.y.normalized(), deg_to_rad(rot_y))
		node.transform = Transform3D(b, world_pos)

	# 4. Animate Autonomous Traffic Fleet (Buses stopping at stations, Red-Light queuing, Weaving Couriers & Horns)
	for veh in _traffic_vehicles:
		var node: Node3D = veh.node
		if not is_instance_valid(node):
			continue
		var cur_o: float = float(veh.offset)
		var dir: float = float(veh.dir)
		var target_spd: float = float(veh.speed)
		var vtype: String = String(veh.vtype)

		if float(veh.horn_cooldown) > 0.0:
			veh.horn_cooldown = float(veh.horn_cooldown) - delta

		# Public Transit Bus Station Logic: decelerate and pause 4.0s at bus stops for commuters to board/exit
		if float(veh.stop_timer) > 0.0:
			veh.stop_timer = float(veh.stop_timer) - delta
			target_spd = 0.0
		elif vtype == "bus":
			for bstop in _bus_stop_offsets:
				var dist_stop: float = absf(cur_o - bstop)
				if dist_stop < 3.5 and absf(bstop - float(veh.last_stop_offset)) > 15.0:
					veh.stop_timer = 4.0
					veh.last_stop_offset = bstop
					target_spd = 0.0
					break

		# Intersection Traffic Signal Logic: check if approaching a RED light within 14m
		if target_spd > 0.0 and vtype != "scooter":
			for sig in _traffic_signals:
				if int(sig.state) == 2: # RED
					var d_sig: float = (float(sig.offset) - cur_o) * dir
					if d_sig > 2.0 and d_sig < 15.0:
						target_spd = 0.0
						break

		# Personality toward the player: polite drivers yield, aggressive ones hold their ground,
		# tourists dawdle, couriers are already weaving.
		var v_pos: Vector3 = node.global_position
		var player_dist: float = v_pos.distance_to(player_pos)
		var persona: int = int(veh.get("persona", TrafficPersona.POLITE))
		if player_dist < 34.0 and target_spd > 0.0:
			match persona:
				TrafficPersona.POLITE:
					target_spd = minf(target_spd, float(veh.speed) * 0.75)
				TrafficPersona.AGGRESSIVE:
					target_spd = float(veh.speed) * 1.18
				TrafficPersona.TOURIST:
					target_spd = float(veh.speed) * 0.7
				_:
					pass

		# Horn when the player is right on top of them; aggressive drivers lean on it.
		if player_dist < 14.0 and float(veh.horn_cooldown) <= 0.0:
			var hp: AudioStreamPlayer3D = veh.horn_player
			if is_instance_valid(hp) and not hp.playing and persona != TrafficPersona.TOURIST:
				hp.play()
			veh.horn_cooldown = 2.2 if persona == TrafficPersona.AGGRESSIVE else 5.0

		var cur_spd: float = move_toward(float(veh.cur_speed), target_spd, 9.5 * delta)
		veh.cur_speed = cur_spd
		cur_o = fposmod(cur_o + cur_spd * dir * delta, track_len)
		veh.offset = cur_o

		var xform: Transform3D = main_node.call("_track_transform", cur_o, 0.0)
		var lat_val: float = float(veh.base_lat)
		if persona == TrafficPersona.POLITE and player_dist < 24.0:
			lat_val += 1.3 if lat_val >= 0.0 else -1.3  # ease toward the kerb
		elif persona == TrafficPersona.TOURIST:
			lat_val += sin(_time * 0.7 + cur_o * 0.05) * 0.35  # gentle drift
		# Reckless Motorcycle/Scooter Couriers weave dynamically through traffic
		if vtype == "scooter":
			lat_val += sin(_time * 3.8 + cur_o * 0.08) * 0.55

		var world_pos: Vector3 = xform * Vector3(lat_val, float(veh.y_offset), 0.0)
		var sc: float = float(veh.scale)
		var heading_deg: float = float(veh.rot_fix) + (0.0 if dir > 0.0 else 180.0)
		var b: Basis = xform.basis.rotated(xform.basis.y.normalized(), deg_to_rad(heading_deg)).scaled(Vector3(sc, sc, sc))
		node.transform = Transform3D(b, world_pos)

	# 5. Animate Citizen AI & Character Ecosystem (Commuters, Skybridge Walkers, Vendors, Drifters)
	for cit in _citizens:
		var node: Node3D = cit.node
		if not is_instance_valid(node):
			continue
		var role: int = int(cit.role)
		var sc: float = float(cit.scale)
		var phase: float = float(cit.phase)

		if role == CitizenRole.SKYBRIDGE_COMMUTER:
			# Walk back and forth across the overhead glass pedestrian skybridge
			var span: float = float(cit.bridge_span)
			var cur_lat: float = float(cit.lat) + float(cit.speed) * float(cit.dir) * delta
			if cur_lat > span:
				cur_lat = span
				cit.dir = -1.0
			elif cur_lat < -span:
				cur_lat = -span
				cit.dir = 1.0
			cit.lat = cur_lat
			var bxform: Transform3D = main_node.call("_track_transform", float(cit.offset), 0.0)
			var bob: float = absf(sin(_time * 7.5 + phase)) * 0.04
			var wpos: Vector3 = bxform * Vector3(cur_lat, float(cit.elev_y) + bob, 0.0)
			var h_deg: float = 90.0 if float(cit.dir) > 0.0 else -90.0
			var b: Basis = bxform.basis.rotated(bxform.basis.y.normalized(), deg_to_rad(h_deg)).scaled(Vector3(sc, sc, sc))
			node.transform = Transform3D(b, wpos)
			continue

		if role == CitizenRole.TERRACE_COMMUTER:
			# Walk back and forth along a building's 2nd-story elevated balcony deck without stepping into alley gaps
			var z_span: float = float(cit.bridge_span)
			var cur_z: float = float(cit.z_local) + float(cit.speed) * float(cit.dir) * delta
			if cur_z > z_span:
				cur_z = z_span
				cit.dir = -1.0
			elif cur_z < -z_span:
				cur_z = -z_span
				cit.dir = 1.0
			cit.z_local = cur_z
			var txform: Transform3D = main_node.call("_track_transform", float(cit.offset), 0.0)
			var bob: float = absf(sin(_time * 7.2 + phase)) * 0.038
			var wpos: Vector3 = txform * Vector3(float(cit.lat), float(cit.elev_y) + bob, cur_z)
			var h_deg: float = 0.0 if float(cit.dir) > 0.0 else 180.0
			var b: Basis = txform.basis.rotated(txform.basis.y.normalized(), deg_to_rad(h_deg)).scaled(Vector3(sc, sc, sc))
			node.transform = Transform3D(b, wpos)
			continue

		if role == CitizenRole.VENDOR or role == CitizenRole.DRIFTER:
			# Street Vendors & Alley Drifters: animated conversational gestures, turning & head-nodding
			var vxform: Transform3D = main_node.call("_track_transform", float(cit.offset), 0.0)
			var gesture_bob: float = absf(sin(_time * 3.2 + phase)) * 0.025
			var turn_sway: float = sin(_time * 1.4 + phase) * 22.0
			var base_rot: float = 90.0 if float(cit.base_lat) < 0.0 else -90.0
			var wpos: Vector3 = vxform * Vector3(float(cit.lat), float(cit.elev_y) + gesture_bob, 0.0)
			var b: Basis = vxform.basis.rotated(vxform.basis.y.normalized(), deg_to_rad(base_rot + turn_sway)).scaled(Vector3(sc, sc, sc))
			node.transform = Transform3D(b, wpos)
			continue

		# COMMUTER AI: each pedestrian notices and reacts to the player's car differently.
		var cpos: Vector3 = node.global_position
		var dist_sq_player: float = cpos.distance_squared_to(player_pos)
		var base_lat: float = float(cit.base_lat)
		var side_sign: float = 1.0 if base_lat >= 0.0 else -1.0
		var persona: int = int(cit.get("persona", Persona.OBLIVIOUS))

		# How soon they notice the car depends on their personality.
		var notice_sq: float = 49.0
		match persona:
			Persona.TIMID:
				notice_sq = 400.0 # 20m: reacts early
			Persona.CURIOUS, Persona.FRIENDLY:
				notice_sq = 225.0 # 15m
			_:
				notice_sq = 49.0 # 7m: barely notices
		if dist_sq_player < notice_sq:
			match persona:
				Persona.TIMID:
					cit.dodge_timer = 1.8
				Persona.CURIOUS:
					cit.watch_timer = 2.2
				Persona.FRIENDLY:
					cit.wave_timer = 2.4
				_:
					pass

		var target_lat: float = base_lat
		var spd_mult: float = 1.0
		var facing_player: bool = false
		if float(cit.dodge_timer) > 0.0:
			cit.dodge_timer = float(cit.dodge_timer) - delta
			target_lat = base_lat + side_sign * (1.7 if persona == Persona.TIMID else 1.15)
			spd_mult = 0.0
			facing_player = true
		elif float(cit.watch_timer) > 0.0:
			cit.watch_timer = float(cit.watch_timer) - delta
			target_lat = base_lat - side_sign * 0.5 # lean toward the road for a better look
			spd_mult = 0.0
			facing_player = true
		elif float(cit.wave_timer) > 0.0:
			cit.wave_timer = float(cit.wave_timer) - delta
			spd_mult = 0.0
			facing_player = true
		elif weather_state == WeatherState.ACID_RAIN:
			# During acid rain, commuters rush faster and hug the awning line closer to buildings
			target_lat = base_lat + side_sign * 0.65
			spd_mult = 1.35

		# Check if near a Bus Stop shelter to pause and wait for transit
		var cur_o: float = float(cit.offset)
		if float(cit.wait_timer) > 0.0:
			cit.wait_timer = float(cit.wait_timer) - delta
			spd_mult = 0.0
		else:
			for bstop in _bus_stop_offsets:
				if absf(cur_o - bstop) < 1.8 and fmod(_time + phase, 19.0) < 0.15:
					cit.wait_timer = 3.5
					spd_mult = 0.0
					break

		cit.lat = move_toward(float(cit.lat), target_lat, 2.8 * delta)
		cur_o = fposmod(cur_o + float(cit.speed) * spd_mult * float(cit.dir) * delta, track_len)
		cit.offset = cur_o

		var xform: Transform3D = main_node.call("_track_transform", cur_o, 0.0)
		var stride_phase: float = _time * 7.4 * maxf(0.3, spd_mult) + phase
		var bob_y: float = absf(sin(stride_phase)) * 0.045 if spd_mult > 0.1 else 0.0
		if float(cit.dodge_timer) > 1.1:
			bob_y = 0.12 # Startle jump!
		var sway_angle: float = sin(stride_phase * 0.5) * 0.035 * spd_mult

		var world_pos: Vector3 = xform * Vector3(float(cit.lat), float(cit.elev_y) + bob_y, 0.0)
		var heading_deg: float = 0.0 if float(cit.dir) > 0.0 else 180.0
		if facing_player:
			heading_deg = 90.0 if side_sign < 0.0 else -90.0 # Turn to watch the road!
		var b: Basis = xform.basis.rotated(xform.basis.y.normalized(), deg_to_rad(heading_deg))
		b = b.rotated(b.z.normalized(), sway_angle)
		node.transform = Transform3D(b.scaled(Vector3(sc, sc, sc)), world_pos)

	# 6. Animate Autonomous Hovering Security Drones (Patrolling beats + scanning crowds/player)
	for dr in _security_drones:
		var node: Node3D = dr.node
		if not is_instance_valid(node):
			continue
		var cur_o: float = fposmod(float(dr.offset) + float(dr.speed) * float(dr.dir) * delta, track_len)
		dr.offset = cur_o
		var phase: float = float(dr.phase)

		var xform: Transform3D = main_node.call("_track_transform", cur_o, 0.0)
		var hover_y: float = 5.2 + sin(_time * 2.6 + phase) * 0.55
		var sway_lat: float = float(dr.lat) + cos(_time * 1.5 + phase) * 0.85
		var wpos: Vector3 = xform * Vector3(sway_lat, hover_y, 0.0)

		var scanner: SpotLight3D = dr.scanner
		# If player car is within 32m, security drone locks its crimson optical scanner beam onto the player!
		if wpos.distance_squared_to(player_pos) < 1024.0:
			node.global_position = wpos
			node.look_at(player_pos + Vector3(0.0, 0.8, 0.0), Vector3.UP)
			if is_instance_valid(scanner):
				scanner.light_color = Color(1.0, 0.05, 0.15)
				scanner.light_energy = 8.5
		else:
			var yaw_sweep: float = sin(_time * 1.8 + phase) * 35.0 + (0.0 if float(dr.dir) > 0.0 else 180.0)
			var b: Basis = xform.basis.rotated(xform.basis.y.normalized(), deg_to_rad(yaw_sweep))
			node.transform = Transform3D(b, wpos)
			if is_instance_valid(scanner):
				scanner.light_color = Color(0.0, 0.88, 1.0)
				scanner.light_energy = 4.5

	# 7. Animate Emergency Vehicle Quad-Strobe Lights & Flickering Holograms
	for st in _strobe_lights:
		var light: OmniLight3D = st.light
		if not is_instance_valid(light):
			continue
		var is_blue: bool = bool(st.is_blue)
		var cycle: float = fmod(_time * 2.4 + (0.5 if is_blue else 0.0), 1.0)
		var flash: float = 0.15
		if cycle < 0.45:
			var sub: float = fmod(cycle * 9.0, 1.0)
			flash = 1.45 if sub < 0.55 else 0.25
		light.light_energy = float(st.base_energy) * flash

	for nl in _neon_lights:
		var light: OmniLight3D = nl.light
		if not is_instance_valid(light):
			continue
		var s: float = float(nl.seed)
		var flicker_wave: float = sin(_time * 3.5 + s * 6.28) * 0.08 + 0.95
		var glitch_window: float = fmod(_time + s * 13.7, 7.5)
		if glitch_window < 0.18:
			flicker_wave = 0.25 if fmod(_time * 35.0, 1.0) < 0.5 else 1.15
		light.light_energy = float(nl.base_energy) * flicker_wave
		var mat: StandardMaterial3D = nl.mat
		if mat:
			mat.emission_energy_multiplier = 2.0 * flicker_wave

	for hmat in _holo_materials:
		if is_instance_valid(hmat):
			var pulse: float = 2.4 + sin(_time * 5.0) * 0.65
			hmat.emission_energy_multiplier = pulse


## Synthesizes a 4.0s looping Cyberpunk Synthwave Sub-Bass & Detuned Saw Pad
static func _create_cyberpunk_synth_wav() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 4.0
	var samples := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(mix_rate)
		# Root D1 (36.71 Hz) + Fifth A1 (55.0 Hz) + Minor 7th C2 (65.41 Hz) + Detuned F2 (87.31 Hz)
		var lfo := sin(t * TAU * 0.25) * 0.5 + 0.5
		var sub := sin(t * TAU * 36.71) * 0.45
		var fifth := sin(t * TAU * 55.0) * 0.28 + sin(t * TAU * 55.25) * 0.22
		var pad := sin(t * TAU * 65.41) * 0.18 * lfo + sin(t * TAU * 87.31) * 0.14 * (1.0 - lfo * 0.5)
		var shimmer := sin(t * TAU * 220.0) * 0.05 * sin(t * TAU * 0.5)
		var sig := clampf((sub + fifth + pad + shimmer) * 0.45, -1.0, 1.0)
		data.encode_s16(i * 2, int(sig * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples
	wav.data = data
	return wav


## Synthesizes a 1.2s looping Hovering Security Drone Propulsion Hum & Telemetry Chirp
static func _create_drone_hum_wav() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 1.2
	var samples := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(mix_rate)
		var rotor := sin(t * TAU * 92.0) * 0.40 + sin(t * TAU * 184.0) * 0.25 + sin(t * TAU * 276.0) * 0.12
		var chirp := 0.0
		if t > 0.95 and t < 1.06:
			chirp = sin(t * TAU * 1680.0) * 0.22
		var sig := clampf((rotor + chirp) * 0.38, -1.0, 1.0)
		data.encode_s16(i * 2, int(sig * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples
	wav.data = data
	return wav


## Synthesizes a 0.55s Non-Looping Dual-Tone Cyber-Vehicle Horn
static func _create_horn_wav() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.55
	var samples := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(mix_rate)
		var env := smoothstep(0.0, 0.03, t) * smoothstep(duration, duration - 0.08, t)
		# Dual-tone automotive chord (415 Hz + 523 Hz + harmonics)
		var tone := sin(t * TAU * 415.3) * 0.45 + sin(t * TAU * 523.25) * 0.45 + sin(t * TAU * 830.6) * 0.18
		var sig := clampf(tone * env * 0.55, -1.0, 1.0)
		data.encode_s16(i * 2, int(sig * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = data
	return wav


## Synthesizes a 2.0s looping 16-bit PCM WAV of an elevated Mag-Lev train hum & rail pulse
static func _create_train_rumble_wav() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 2.0
	var samples := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 901
	var lp := 0.0
	for i in samples:
		var t := float(i) / float(mix_rate)
		var rumble := sin(t * TAU * 55.0) * 0.35 + sin(t * TAU * 110.0) * 0.25 + sin(t * TAU * 220.0) * 0.12
		var noise := rng.randf_range(-1.0, 1.0)
		lp = lp * 0.88 + noise * 0.12
		var clack := 0.0
		for joint_t in [0.25, 0.40, 1.25, 1.40]:
			var dt: float = t - float(joint_t)
			if dt >= 0.0 and dt < 0.06:
				clack += exp(-dt * 55.0) * sin(dt * TAU * 420.0) * 0.65
		var sig := clampf((rumble + lp * 0.45 + clack) * 0.55, -1.0, 1.0)
		data.encode_s16(i * 2, int(sig * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples
	wav.data = data
	return wav


## Synthesizes a 3.0s looping 16-bit PCM WAV of a distant metropolitan emergency wail siren
static func _create_siren_wav() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 3.0
	var samples := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0
	for i in samples:
		var t := float(i) / float(mix_rate)
		var sweep := 0.5 - 0.5 * cos(t * TAU / duration)
		var freq := lerpf(580.0, 1120.0, sweep)
		phase += freq / float(mix_rate)
		var sig := (sin(phase * TAU) * 0.7 + sin(phase * TAU * 2.0) * 0.2) * 0.28
		data.encode_s16(i * 2, int(sig * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples
	wav.data = data
	return wav


## Synthesizes a 1.5s looping 16-bit PCM WAV of a 60Hz/120Hz neon sign transformer buzz & HVAC hum
static func _create_neon_hum_wav() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 1.5
	var samples := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(mix_rate)
		var hum := sin(t * TAU * 60.0) * 0.35 + sin(t * TAU * 120.0) * 0.45 + sin(t * TAU * 240.0) * 0.15 + sin(t * TAU * 360.0) * 0.08
		data.encode_s16(i * 2, int(clampf(hum * 0.32, -1.0, 1.0) * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples
	wav.data = data
	return wav
