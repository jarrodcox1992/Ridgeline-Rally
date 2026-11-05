class_name RoadRepairController
extends Area3D
## Dynamic Road Repair Controller ported to Godot 4.7 GDScript.
## Manages dynamic road surface states (Damaged, Repairing, Fixed), visual switching,
## asynchronous repair coroutines with particles, and VehicleWheel3D traction modifiers.

signal repair_started(controller: RoadRepairController)
signal repair_completed(controller: RoadRepairController)
signal state_changed(new_state: RoadState)

enum RoadState {
	DAMAGED,
	REPAIRING,
	FIXED
}

@export_group("Road State")
@export var current_state: RoadState = RoadState.DAMAGED

@export_group("Visual References")
## Visual mesh, scene, or node representing the broken/potholed road surface.
@export var damaged_visual: Node3D
## Visual mesh, scene, or node representing the smooth, repaired road.
@export var fixed_visual: Node3D
## GPUParticles3D or CPUParticles3D played during active repairs (e.g. asphalt steam/welding sparks).
@export var repair_particles: GPUParticles3D

@export_group("Repair Settings")
@export var repair_cost: int = 150
@export var repair_duration: float = 3.0

@export_group("Driving Physics Modifiers")
@export_range(0.1, 1.0, 0.05) var damaged_traction: float = 0.60
@export_range(0.1, 1.0, 0.05) var fixed_traction: float = 1.00

var _is_repairing: bool = false
var _active_cars: Array[Node3D] = []
var _col_shape: CollisionShape3D
var _beacon_node: Node3D
var _beacon_mat: StandardMaterial3D
var _audio_player: AudioStreamPlayer3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_audio()
	update_visuals()


func _setup_audio() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.unit_size = 25.0
	_audio_player.max_distance = 180.0
	_audio_player.bus = "Master"
	add_child(_audio_player)


func _play_tone(frequency: float, duration: float, type: String = "sine") -> void:
	if not _audio_player:
		return
	var sample_hz := 44100.0
	var total_frames := int(sample_hz * duration)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_hz)
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(total_frames * 2)
	for i in total_frames:
		var t := float(i) / sample_hz
		var env := 1.0 - (float(i) / float(total_frames))
		var sample := 0.0
		if type == "chirp":
			var cur_freq := frequency + (t / duration) * 600.0
			sample = sin(t * cur_freq * TAU) * env
		else:
			sample = sin(t * frequency * TAU) * env
		var val := clampi(int(sample * 16000.0), -32768, 32767)
		data.encode_s16(i * 2, val)
	stream.data = data
	_audio_player.stream = stream
	_audio_player.play()


func _process(delta: float) -> void:
	if _beacon_node:
		_beacon_node.rotate_y(delta * 2.4)
		_beacon_node.position.y = 3.6 + sin(Time.get_ticks_msec() * 0.0035) * 0.28
		if _beacon_mat:
			match current_state:
				RoadState.DAMAGED:
					var pulse: float = 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.006)
					_beacon_mat.albedo_color = Color(1.0, 0.65, 0.1, 0.95)
					_beacon_mat.emission = Color(1.0, 0.6, 0.05)
					_beacon_mat.emission_energy_multiplier = 2.4 * pulse
				RoadState.REPAIRING:
					var flash: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.015)
					_beacon_mat.albedo_color = Color(0.1, 0.85, 1.0, 0.95)
					_beacon_mat.emission = Color(0.2, 0.9, 1.0)
					_beacon_mat.emission_energy_multiplier = 3.5 * flash
				RoadState.FIXED:
					_beacon_mat.albedo_color = Color(0.2, 1.0, 0.45, 0.4)
					_beacon_mat.emission = Color(0.2, 1.0, 0.45)
					_beacon_mat.emission_energy_multiplier = 0.6

	# Continuously feed road rumble status to active cars
	if not _active_cars.is_empty():
		for c in _active_cars:
			if is_instance_valid(c) and "on_curb" in c:
				c.set("on_curb", current_state == RoadState.DAMAGED)


## Call this method from UI button, player interaction key, or city event manager.
func trigger_repair() -> void:
	if current_state == RoadState.FIXED:
		print("[RoadRepairController %s] Section is already in top condition!" % name)
		return

	if current_state == RoadState.DAMAGED and not _is_repairing:
		_start_repair_routine()


## Asynchronous coroutine port of Unity's IEnumerator RepairRoutine
func _start_repair_routine() -> void:
	_is_repairing = true
	current_state = RoadState.REPAIRING
	state_changed.emit(current_state)
	repair_started.emit(self)
	_play_tone(440.0, 0.45, "chirp")
	print("[RoadRepairController %s] Road repair crew dispatched. Duration: %.1fs" % [name, repair_duration])

	if repair_particles:
		repair_particles.emitting = true

	# Asynchronous coroutine in Godot 4.7
	await get_tree().create_timer(repair_duration).timeout

	current_state = RoadState.FIXED
	_is_repairing = false

	if repair_particles:
		repair_particles.emitting = false

	update_visuals()
	_update_all_active_car_tractions()
	state_changed.emit(current_state)
	repair_completed.emit(self)
	_play_tone(880.0, 0.55, "sine")
	print("[RoadRepairController %s] Road repair completed successfully! Full traction restored." % name)


func update_visuals() -> void:
	var is_fixed: bool = (current_state == RoadState.FIXED)
	if damaged_visual:
		damaged_visual.visible = not is_fixed
	if fixed_visual:
		fixed_visual.visible = is_fixed


## Returns the active traction multiplier (0.60 damaged, 1.00 fixed)
func get_current_traction() -> float:
	return fixed_traction if (current_state == RoadState.FIXED) else damaged_traction


# --- Vehicle Physics Interaction & VehicleWheel3D Traction Modifiers ---

func _on_body_entered(body: Node3D) -> void:
	if _is_car(body):
		if not _active_cars.has(body):
			_active_cars.append(body)
		_apply_traction_to_car(body)


func _on_body_exited(body: Node3D) -> void:
	if body in _active_cars:
		_active_cars.erase(body)
		_reset_car_traction(body)


func _is_car(body: Node3D) -> bool:
	return body is VehicleBody3D or "road_traction_multiplier" in body or body.is_in_group("cars")


func _apply_traction_to_car(car_body: Node3D) -> void:
	var mult: float = get_current_traction()

	# 1. Update car script dynamic traction property
	if "road_traction_multiplier" in car_body:
		car_body.set("road_traction_multiplier", mult)

	# 2. Directly scale VehicleWheel3D friction slip on physical vehicle wheels
	var wheels := _find_vehicle_wheels(car_body)
	for wheel in wheels:
		var base_grip: float = 1.6 if wheel.use_as_traction else 1.45
		wheel.wheel_friction_slip = base_grip * mult


func _reset_car_traction(car_body: Node3D) -> void:
	if "road_traction_multiplier" in car_body:
		car_body.set("road_traction_multiplier", 1.0)

	var wheels := _find_vehicle_wheels(car_body)
	for wheel in wheels:
		var base_grip: float = 1.6 if wheel.use_as_traction else 1.45
		wheel.wheel_friction_slip = base_grip


func _update_all_active_car_tractions() -> void:
	for car in _active_cars:
		if is_instance_valid(car):
			_apply_traction_to_car(car)


func _find_vehicle_wheels(root: Node3D) -> Array[VehicleWheel3D]:
	var result: Array[VehicleWheel3D] = []
	for child in root.get_children():
		if child is VehicleWheel3D:
			result.append(child)
	return result


## Procedurally generates 3D visual geometry, collision box, warning markers, and particles
## if standalone instantiation without a pre-baked scene is needed.
func setup_procedural_visuals(zone_size: Vector3 = Vector3(18.0, 3.5, 14.0)) -> void:
	# 1. Collision Shape
	if not _col_shape:
		_col_shape = CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = zone_size
		_col_shape.shape = box
		_col_shape.position = Vector3(0.0, zone_size.y * 0.5, 0.0)
		add_child(_col_shape)

	# 2. Damaged Visual: cracked asphalt patch + caution cones and amber flashing beacon
	var damaged_root := Node3D.new()
	damaged_root.name = "DamagedVisualRoot"

	var patch_mesh := BoxMesh.new()
	patch_mesh.size = Vector3(zone_size.x * 0.98, 0.015, zone_size.z * 0.98)
	var patch_mat := StandardMaterial3D.new()
	patch_mat.albedo_color = Color(0.22, 0.20, 0.18)
	patch_mat.roughness = 0.94
	patch_mat.metallic = 0.02
	var patch_inst := MeshInstance3D.new()
	patch_inst.mesh = patch_mesh
	patch_inst.position = Vector3(0.0, 0.008, 0.0)
	damaged_root.add_child(patch_inst)

	# Safety cones along perimeter and approach taper
	var cone_mat := StandardMaterial3D.new()
	cone_mat.albedo_color = Color(1.0, 0.42, 0.04)
	cone_mat.roughness = 0.38
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.06
	cone_mesh.bottom_radius = 0.24
	cone_mesh.height = 0.68
	cone_mesh.radial_segments = 12
	cone_mesh.material = cone_mat

	var cone_z_steps := [-zone_size.z * 0.48, -zone_size.z * 0.16, zone_size.z * 0.16, zone_size.z * 0.48]
	for cz in cone_z_steps:
		var c_left := MeshInstance3D.new()
		c_left.mesh = cone_mesh
		c_left.position = Vector3(-zone_size.x * 0.48, 0.34, cz)
		damaged_root.add_child(c_left)

		var c_right := MeshInstance3D.new()
		c_right.mesh = cone_mesh
		c_right.position = Vector3(zone_size.x * 0.48, 0.34, cz)
		damaged_root.add_child(c_right)

	# Two amber warning strobe lights on the entry cones
	var entry_strobe := OmniLight3D.new()
	entry_strobe.light_color = Color(1.0, 0.65, 0.08)
	entry_strobe.light_energy = 2.8
	entry_strobe.omni_range = 10.0
	entry_strobe.position = Vector3(0.0, 0.85, -zone_size.z * 0.48)
	damaged_root.add_child(entry_strobe)

	add_child(damaged_root)
	damaged_visual = damaged_root

	# 3. Fixed Visual: pristine dark asphalt patch + fresh white road line
	var fixed_root := Node3D.new()
	fixed_root.name = "FixedVisualRoot"

	var fixed_mesh := BoxMesh.new()
	fixed_mesh.size = Vector3(zone_size.x * 0.98, 0.015, zone_size.z * 0.98)
	var fixed_mat := StandardMaterial3D.new()
	fixed_mat.albedo_color = Color(0.18, 0.19, 0.22)
	fixed_mat.roughness = 0.28
	fixed_mat.clearcoat_enabled = true
	fixed_mat.clearcoat = 0.45
	var fixed_inst := MeshInstance3D.new()
	fixed_inst.mesh = fixed_mesh
	fixed_inst.position = Vector3(0.0, 0.008, 0.0)
	fixed_root.add_child(fixed_inst)

	var line_mesh := BoxMesh.new()
	line_mesh.size = Vector3(0.20, 0.02, zone_size.z * 0.98)
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.96, 0.96, 0.96)
	var line_inst := MeshInstance3D.new()
	line_inst.mesh = line_mesh
	line_inst.position = Vector3(0.0, 0.012, 0.0)
	fixed_root.add_child(line_inst)

	add_child(fixed_root)
	fixed_visual = fixed_root

	# 4. Repair Particles: asphalt steam & sparks
	var parts := GPUParticles3D.new()
	parts.name = "RepairParticles"
	parts.emitting = false
	parts.amount = 48
	parts.lifetime = 1.2
	parts.position = Vector3(0.0, 0.4, 0.0)

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(zone_size.x * 0.4, 0.2, zone_size.z * 0.4)
	pmat.direction = Vector3.UP
	pmat.spread = 45.0
	pmat.initial_velocity_min = 2.0
	pmat.initial_velocity_max = 4.5
	pmat.gravity = Vector3(0.0, 1.5, 0.0)
	pmat.color = Color(1.0, 0.85, 0.4, 0.8)

	var qm := QuadMesh.new()
	qm.size = Vector2(0.35, 0.35)
	var qmat := StandardMaterial3D.new()
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.albedo_color = Color(1.0, 0.9, 0.6)
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = qmat

	parts.process_material = pmat
	parts.draw_pass_1 = qm
	add_child(parts)
	repair_particles = parts

	# 5. Floating Holographic Repair Beacon
	_beacon_node = Node3D.new()
	_beacon_node.name = "HolographicBeacon"
	_beacon_node.position = Vector3(0.0, 3.8, 0.0)

	var beacon_mesh := CylinderMesh.new()
	beacon_mesh.top_radius = 0.65
	beacon_mesh.bottom_radius = 0.0
	beacon_mesh.height = 1.1
	beacon_mesh.radial_segments = 6

	_beacon_mat = StandardMaterial3D.new()
	_beacon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beacon_mat.albedo_color = Color(1.0, 0.65, 0.1, 0.95)
	_beacon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beacon_mat.emission_enabled = true
	_beacon_mat.emission = Color(1.0, 0.6, 0.05)
	_beacon_mat.emission_energy_multiplier = 2.4

	var beacon_inst := MeshInstance3D.new()
	beacon_inst.mesh = beacon_mesh
	beacon_inst.material_override = _beacon_mat
	_beacon_node.add_child(beacon_inst)

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.85
	ring_mesh.outer_radius = 1.05
	var ring_inst := MeshInstance3D.new()
	ring_inst.mesh = ring_mesh
	ring_inst.material_override = _beacon_mat
	ring_inst.position = Vector3(0.0, -0.2, 0.0)
	_beacon_node.add_child(ring_inst)

	add_child(_beacon_node)

	update_visuals()
