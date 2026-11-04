extends VehicleBody3D
## A race car, driven either by the player or by an AI (see ai_driver.gd). Uses the
## Car Concept model (see CREDITS.md) for its looks and a recorded engine loop for sound.
## The car's forward direction is local +Z.

const CarModel := preload("res://models/car_concept.glb")
const TireEffects := preload("res://tire_effects.gd")
const EngineLoop := preload("res://sounds/engine_loop.wav")
const ExhaustScript := preload("res://exhaust.gd")

const ENGINE_POWER := 180000.0 # watts, about 240 hp
const MAX_DRIVE_FORCE := 3200.0 # per rear wheel; caps wheelspin off the line
const MAX_REVERSE_FORCE := 1400.0
# Braking is applied as a direct force rather than through Godot's wheel brakes, which
# fade as the car slows and drag out every stop.
const BRAKE_DECEL := 10.5 # m/s^2 at full pedal, a little over 1 g
const ENGINE_BRAKE_DECEL := 0.8 # m/s^2 when coasting off the throttle
const HOLD_BRAKE := 2.0 # wheel brake that keeps a stopped car from creeping
const HANDBRAKE := 8.0
const DRAG := 0.44 # 0.5 * air density * drag coefficient * frontal area
const ROLLING_RESISTANCE := 0.015
const DOWNFORCE := 1.2
const GEAR_TOP_SPEEDS := [14.0, 24.0, 35.0, 47.0, 60.0, 78.0]
const IDLE_RPM := 900.0
const REDLINE_RPM := 7200.0
const FRONT_GRIP := 1.45
const REAR_GRIP := 1.6
const WHEELBASE := 2.8
const MAX_STEER := 0.6
# Steering lock is limited at speed to what the tires can actually use, with this much in reserve.
const STEER_GRIP := 1.15 * 9.8
const STEER_HEADROOM := 1.7
const REAR_GRIP_HANDBRAKE := 1.25
const WHEEL_RADIUS := 0.384
# Wheel centres in the model, keyed by the model's wheel node names.
const WHEELS := {
	"WheelFrontL": Vector3(0.976, WHEEL_RADIUS, 1.485),
	"WheelFrontR": Vector3(-0.976, WHEEL_RADIUS, 1.485),
	"WheelRearL": Vector3(0.982, WHEEL_RADIUS, -1.314),
	"WheelRearR": Vector3(-0.982, WHEEL_RADIUS, -1.314),
}
# Suspension mounts sit this far above the wheel centres, so the body settles to its modelled ride height.
const SUSPENSION_SAG := 0.165
# Parts that carry Khronos logos, which the model's license does not cover.
const LOGO_NODES := ["License Plate", "InteriorSteeringEmblem"]
const LOGO_EMISSIVE_MATERIALS := ["Brake", "Hardware", "Mirror"]
# The steering wheel turns this many times further than the front wheels.
const STEERING_WHEEL_RATIO := 5.0
# Engine loop pitch at idle and at the redline. The recording idles around 1300 rpm; the range
# is compressed from the true ratio so the top end does not sound like a chipmunk.
const ENGINE_PITCH_IDLE := 0.75
const ENGINE_PITCH_REDLINE := 3.0
const AI_INTERIOR_RANGE := 25.0
# Real windows are see-through face on and turn to mirrors at grazing angles (Fresnel).
const GLASS_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 tint : source_color = vec3(0.04, 0.05, 0.06);
uniform float base_alpha = 0.3;
void fragment() {
	float facing = abs(dot(NORMAL, VIEW));
	float fresnel = pow(1.0 - facing, 4.0);
	ALBEDO = tint;
	METALLIC = 0.0;
	ROUGHNESS = 0.02;
	SPECULAR = 1.0;
	ALPHA = clamp(base_alpha + fresnel * 0.65, 0.0, 0.96);
}
"""
# Rim spokes blur into a disc at speed, as they do on camera.
const WHEEL_BLUR_SPEED := Vector2(35.0, 110.0) # km/h where blur starts and is strongest
# Cars draw on their own render layer so the contact shadow under them only darkens the ground.
const CAR_RENDER_LAYER := 2
## Layout of each body, in the car's frame (metres, +Z forward, +X to the driver's left).
## "concept" is the Khronos Car Concept. "custom" is the body made from your own car image
## (models/your_car), riding on the Car Concept's wheels.
const BODIES := {
	"concept": {
		"wheels": WHEELS, "wheel_radius": WHEEL_RADIUS,
		"collision": [[Vector3(2.1, 0.55, 4.2), Vector3(0.0, 0.5, 0.25)], [Vector3(1.7, 0.35, 2.0), Vector3(0.0, 0.98, 0.0)]],
		"headlights": [Vector3(0.62, 0.67, 2.25), Vector3(-0.62, 0.67, 2.25)],
		"tail_glow": Vector3(0.0, 0.85, -2.25),
		"exhausts": [Vector3(0.32, 0.36, -1.97), Vector3(-0.32, 0.36, -1.97)],
		"cockpit": Vector3(0.0, 0.95, 0.55),
	},
	"custom": {
		"wheels": {
			"WheelFrontL": Vector3(0.85, 0.36, 1.30), "WheelFrontR": Vector3(-0.85, 0.36, 1.30),
			"WheelRearL": Vector3(0.85, 0.36, -1.35), "WheelRearR": Vector3(-0.85, 0.36, -1.35),
		},
		"wheel_radius": 0.36,
		"collision": [[Vector3(2.0, 0.5, 4.6), Vector3(0.0, 0.47, 0.03)], [Vector3(1.5, 0.34, 1.9), Vector3(0.0, 0.92, -0.15)]],
		"headlights": [Vector3(0.7, 0.64, 2.3), Vector3(-0.7, 0.64, 2.3)],
		"tail_glow": Vector3(0.0, 0.65, -2.55),
		"exhausts": [Vector3(0.32, 0.45, -2.42), Vector3(-0.32, 0.45, -2.42)],
		"cockpit": Vector3(0.0, 1.0, 1.25), # over the bonnet; the generated body has no interior
	},
}
const CUSTOM_BODY_MESH := "res://models/your_car/your_car_body.res"
## The generated body is one mesh with no separate glass or lights, so they are painted on by
## position and surface direction: steep surfaces up high are glass, a band across the tail is
## the taillights, the top corners of the nose are the headlights.
const CUSTOM_BODY_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 paint : source_color = vec3(0.012, 0.014, 0.02);
uniform float brake = 0.0;
uniform float headlights = 0.0;
varying vec3 local_pos;
varying vec3 local_normal;
void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
}
void fragment() {
	if (!FRONT_FACING) {
		// Inside of the shell, seen through the wheel openings: a dark wheel well.
		ALBEDO = vec3(0.0);
		ROUGHNESS = 1.0;
	} else {
		vec3 p = local_pos;
		vec3 n = normalize(local_normal);
		bool glass = p.y > 0.78 && abs(n.y) < 0.72 && p.z > -1.0;
		// A thin strip across each side of the tail, like the photo's arrow-shaped lights.
		bool tail = p.z < -2.25 && p.y > 0.66 && p.y < 0.73 && abs(p.x) > 0.35 && abs(p.x) < 0.9 && n.z < -0.5;
		bool head = p.z > 2.05 && p.y > 0.55 && p.y < 0.72 && abs(p.x) > 0.42 && abs(p.x) < 0.92 && n.z > 0.3;
		ALBEDO = paint;
		METALLIC = 0.55;
		ROUGHNESS = 0.2;
		CLEARCOAT = 1.0;
		CLEARCOAT_ROUGHNESS = 0.05;
		if (glass) {
			ALBEDO = vec3(0.01, 0.012, 0.016);
			METALLIC = 0.0;
			ROUGHNESS = 0.03;
			SPECULAR = 1.0;
			CLEARCOAT = 0.0;
		} else if (tail) {
			ALBEDO = vec3(0.25, 0.0, 0.0);
			EMISSION = vec3(1.0, 0.06, 0.02) * (2.5 + brake * 9.0);
		} else if (head) {
			ALBEDO = vec3(0.8);
			EMISSION = vec3(1.0, 0.96, 0.9) * (1.5 + headlights * 8.0);
		}
	}
}
"""
## Set these before adding the car to the tree.
var is_player := true
var paint_color := Color(0.0, 0.0, 0.0, 0.0) # alpha 0 keeps the model's own red
var rim_color := Color(0.0, 0.0, 0.0, 0.0) # alpha 0 keeps the model's own silver
## Adds a carbon-fibre rear wing (the custom body already has its own).
var rear_wing := false
## Which entry of BODIES to build.
var body_style := "concept"
## Held on the start grid during the countdown. The engine can still be revved.
var frozen := false
## What an AI driver wants this frame; ignored for the player's car.
var ai_input := {"accelerate": 0.0, "brake": 0.0, "steer": 0.0, "handbrake": false}

var throttle := 0.0
var rpm := IDLE_RPM
var gear := 1
var reversing := false
var speed_kmh := 0.0

var _rear_wheels: Array[VehicleWheel3D] = []
var _all_wheels: Array[VehicleWheel3D] = []
var headlights_on := false
## Handbrake plus throttle at a standstill: front wheels locked, rears spinning in smoke.
var burnout := false

var _brake_light_material: StandardMaterial3D
var _tail_glow: OmniLight3D
var _wheel_blur: Array[StandardMaterial3D] = []
var _body_material: ShaderMaterial
var _layout: Dictionary
var _headlight_material: StandardMaterial3D
var _headlights: Array[SpotLight3D] = []
var _steering_wheel: Node3D
var _steering_wheel_basis: Basis
var _skid := 0.0

var _engine # AudioStreamPlayer for the player, AudioStreamPlayer3D for AI cars
var _engine_rasp
var _playback: AudioStreamGeneratorPlayback
var _mix_rate := 22050.0
var _squeal_phase := 0.0
var _wind := 0.0
var _pop_level := 0.0


func _ready() -> void:
	mass = 1250.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, 0.35, 0.0)
	# Godot's default damping acts like heavy air drag; real drag is modelled below instead.
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	_layout = BODIES[body_style]
	for box: Array in _layout.collision:
		_add_collision(box[0], box[1])
	var model := CarModel.instantiate() as Node3D
	add_child(model)
	_fix_materials(model)
	if not is_player:
		# AI cockpits are only drawn when you're close enough to see into them.
		for node in model.find_children("Interior*", "GeometryInstance3D", true, false):
			(node as GeometryInstance3D).visibility_range_end = AI_INTERIOR_RANGE
	var wheels: Dictionary = _layout.wheels
	for wheel_name: String in wheels:
		_add_wheel(model, wheel_name, wheels[wheel_name], _layout.wheel_radius)
	if body_style == "custom":
		# Keep only the Car Concept's wheels (already moved onto the physics wheels).
		model.visible = false
		_build_custom_body()
	_steering_wheel = model.find_child("InteriorSteeringCylinder", true, false) as Node3D
	if _steering_wheel:
		_steering_wheel_basis = _steering_wheel.transform.basis
	_build_headlights()
	if rear_wing and body_style == "concept":
		_build_rear_wing()
	if is_player:
		# Red light from the taillights spilling onto the road and any smoke behind.
		_tail_glow = OmniLight3D.new()
		_tail_glow.light_color = Color(1.0, 0.08, 0.04)
		_tail_glow.omni_range = 4.5
		_tail_glow.position = _layout.tail_glow
		_tail_glow.light_specular = 0.0 # no hot spot reflected in the glossy bumper
		add_child(_tail_glow)
		var exhaust := ExhaustScript.new()
		add_child(exhaust)
		exhaust.setup(self, _layout.exhausts)
		exhaust.on_pop = func(): _pop_level = 1.0
	var effects := TireEffects.new()
	add_child(effects)
	effects.setup(self, _all_wheels, _rear_wheels)
	_build_contact_shadow()
	_build_engine_sound()
	for geometry in find_children("*", "GeometryInstance3D", true, false):
		(geometry as GeometryInstance3D).layers = CAR_RENDER_LAYER


func _physics_process(delta: float) -> void:
	var forward_speed := linear_velocity.dot(global_basis.z)
	var speed := linear_velocity.length()
	speed_kmh = speed * 3.6

	var accel_input: float = ai_input.accelerate
	var brake_input: float = ai_input.brake
	var steer_input: float = ai_input.steer
	var handbrake_on: bool = ai_input.handbrake
	if is_player:
		accel_input = Input.get_action_strength("accelerate")
		brake_input = Input.get_action_strength("brake")
		steer_input = Input.get_axis("steer_right", "steer_left")
		handbrake_on = Input.is_action_pressed("handbrake")

	# Like speed-sensitive power steering: at speed, full lock only asks for about as much
	# cornering as the tires can give, so the car doesn't snap into a spin.
	var grip_steer := atan(WHEELBASE * STEER_GRIP / maxf(speed * speed, 1.0)) * STEER_HEADROOM
	var max_steer := clampf(grip_steer, 0.05, MAX_STEER)
	var target_steer := steer_input * max_steer
	# Turn in more gently at speed, but always let the wheel come back to centre quickly.
	var returning := absf(target_steer) < absf(steering) or signf(target_steer) != signf(steering)
	var rate := 3.5 if returning else lerpf(2.5, 0.8, clampf(speed / 50.0, 0.0, 1.0))
	steering = move_toward(steering, target_steer, delta * rate)

	var force := 0.0
	var decel := ENGINE_BRAKE_DECEL
	var braking := false
	throttle = 0.0
	reversing = false
	if accel_input > 0.0:
		if forward_speed < -1.0:
			decel = BRAKE_DECEL * accel_input
			braking = true
		else:
			# Full traction off the line, then limited by engine power as speed rises.
			force = minf(MAX_DRIVE_FORCE, ENGINE_POWER / maxf(forward_speed, 1.0) * 0.5) * accel_input
			decel = 0.0
			throttle = accel_input
	if brake_input > 0.0:
		if forward_speed > 1.0:
			decel = BRAKE_DECEL * brake_input
			braking = true
		else:
			force = -MAX_REVERSE_FORCE * brake_input
			decel = 0.0
			throttle = brake_input
			reversing = true
	var hold := force == 0.0 and speed < 1.0
	if frozen:
		force = 0.0
		decel = 0.0
		hold = true
		throttle = accel_input
		handbrake_on = false
	engine_force = force
	brake = HOLD_BRAKE * 4.0 if hold else 0.0

	burnout = handbrake_on and accel_input > 0.5 and speed < 6.0
	for wheel in _rear_wheels:
		wheel.wheel_friction_slip = REAR_GRIP_HANDBRAKE if handbrake_on else REAR_GRIP
		if burnout:
			# Rears get full power on almost no grip, so they spin instead of driving the car.
			wheel.wheel_friction_slip = 0.35
			wheel.brake = 0.0
			wheel.engine_force = MAX_DRIVE_FORCE
		elif handbrake_on:
			wheel.brake = HANDBRAKE
			wheel.engine_force = 0.0
	if burnout:
		for wheel in _all_wheels:
			if wheel.use_as_steering:
				wheel.brake = 60.0
		decel = 0.0
		throttle = accel_input

	var grounded := 0
	for wheel in _all_wheels:
		if wheel.is_in_contact():
			grounded += 1
	if grounded > 0:
		var share := grounded / float(_all_wheels.size())
		# Brake along the car's own axis, applied above the centre of mass so the nose dips.
		if decel > 0.0 and absf(forward_speed) > 0.05:
			var stop := clampf(absf(forward_speed) / 1.5, 0.0, 1.0)
			var brake_push := -global_basis.z * signf(forward_speed) * mass * decel * share * stop
			apply_force(brake_push, global_basis * Vector3(0.0, 0.6, 0.0))
		if speed > 0.5:
			apply_central_force(-linear_velocity.normalized() * ROLLING_RESISTANCE * mass * 9.8 * share)
	apply_central_force(-linear_velocity * speed * DRAG)
	apply_central_force(-global_basis.y * speed * speed * DOWNFORCE)

	_skid = 0.0
	for wheel in _all_wheels:
		if wheel.is_in_contact():
			_skid = maxf(_skid, 1.0 - wheel.get_skidinfo())

	if is_player and Input.is_action_just_pressed("headlights"):
		set_headlights(not headlights_on)

	_update_rpm(absf(forward_speed), delta)
	var brake_lit := braking or handbrake_on
	if _brake_light_material:
		_brake_light_material.emission_energy_multiplier = 12.0 if brake_lit else 3.0
	if _body_material:
		_body_material.set_shader_parameter("brake", 1.0 if brake_lit else 0.0)
	if _tail_glow:
		_tail_glow.light_energy = 2.5 if brake_lit else 0.7


func _process(_delta: float) -> void:
	# The column's local Y axis points back at the driver, so a positive turn is anticlockwise
	# from the driver's seat, matching a left turn of the front wheels.
	if _steering_wheel:
		_steering_wheel.transform.basis = _steering_wheel_basis * Basis(Vector3.UP, steering * STEERING_WHEEL_RATIO)
	var blur := smoothstep(WHEEL_BLUR_SPEED.x, WHEEL_BLUR_SPEED.y, speed_kmh) * 0.6
	for material in _wheel_blur:
		material.albedo_color.a = blur
	_update_engine_sound()
	if _playback:
		_fill_effects_sound()


func _update_engine_sound() -> void:
	var rev := clampf((rpm - IDLE_RPM) / (REDLINE_RPM - IDLE_RPM), 0.0, 1.0)
	var pitch := lerpf(ENGINE_PITCH_IDLE, ENGINE_PITCH_REDLINE, rev)
	_engine.pitch_scale = pitch
	_engine.volume_db = lerpf(-12.0, -3.0, maxf(throttle, rev * 0.5))
	# An octave-up copy fades in under load for a harder, raspier note.
	_engine_rasp.pitch_scale = pitch * 2.0
	_engine_rasp.volume_db = linear_to_db(maxf(throttle * rev, 0.001) * 0.35)


## Tire squeal and wind noise are generated, since they are mostly filtered noise.
func _fill_effects_sound() -> void:
	var squeal := clampf((_skid - 0.35) * 2.0, 0.0, 1.0) * clampf(speed_kmh / 20.0, 0.0, 1.0)
	var wind_level := clampf(speed_kmh / 200.0, 0.0, 1.0)
	wind_level *= wind_level * 0.12
	for i in _playback.get_frames_available():
		_wind += (randf_range(-1.0, 1.0) - _wind) * 0.08
		var out: float = _wind * wind_level
		if _pop_level > 0.001:
			# A backfire: a sharp crack of noise that dies away in about 60 ms.
			out += randf_range(-1.0, 1.0) * _pop_level * 0.55
			_pop_level *= 0.9985
		if squeal > 0.0:
			_squeal_phase = fmod(_squeal_phase + randf_range(820.0, 900.0) / _mix_rate, 1.0)
			out += sin(_squeal_phase * TAU) * squeal * 0.08
		_playback.push_frame(Vector2(out, out))


func set_headlights(on: bool) -> void:
	headlights_on = on
	for light in _headlights:
		light.visible = on
	if _headlight_material:
		_headlight_material.emission_energy_multiplier = 10.0 if on else 1.5
	if _body_material:
		_body_material.set_shader_parameter("headlights", 1.0 if on else 0.0)


## Puts the car back on the road, stopped, at the given transform.
func reset_to(xform: Transform3D) -> void:
	global_transform = xform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	steering = 0.0


func gear_text() -> String:
	if reversing:
		return "R"
	if speed_kmh < 2.0 and throttle == 0.0:
		return "N"
	return str(gear)


func _update_rpm(abs_speed: float, delta: float) -> void:
	gear = GEAR_TOP_SPEEDS.size()
	for i in GEAR_TOP_SPEEDS.size():
		var top: float = GEAR_TOP_SPEEDS[i]
		if abs_speed < top:
			gear = i + 1
			break
	var low: float = 0.0 if gear == 1 else GEAR_TOP_SPEEDS[gear - 2] * 0.6
	var high: float = GEAR_TOP_SPEEDS[gear - 1]
	var target := lerpf(IDLE_RPM + 400.0, REDLINE_RPM, clampf((abs_speed - low) / (high - low), 0.0, 1.0))
	if burnout:
		target = 5800.0 + randf_range(-250.0, 250.0)
	elif abs_speed < 1.0:
		target = IDLE_RPM + throttle * 2500.0
	rpm = lerpf(rpm, target, 1.0 - exp(-delta * 10.0))


func _add_collision(size: Vector3, pos: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	add_child(shape)


## Moves one of the model's wheels onto a physics wheel, so it spins, steers
## and follows the suspension.
func _add_wheel(model: Node3D, wheel_name: String, centre: Vector3, radius: float) -> void:
	var front := wheel_name.begins_with("WheelFront")
	var wheel := VehicleWheel3D.new()
	wheel.position = centre + Vector3.UP * SUSPENSION_SAG
	wheel.use_as_steering = front
	wheel.use_as_traction = not front
	wheel.wheel_radius = radius
	wheel.wheel_rest_length = 0.25
	wheel.suspension_travel = 0.2
	wheel.suspension_stiffness = 55.0
	wheel.suspension_max_force = 15000.0
	wheel.damping_compression = 1.8
	wheel.damping_relaxation = 2.4
	wheel.wheel_friction_slip = FRONT_GRIP if front else REAR_GRIP
	wheel.wheel_roll_influence = 0.3
	add_child(wheel)
	_all_wheels.append(wheel)
	if not front:
		_rear_wheels.append(wheel)

	var visual := model.find_child(wheel_name, true, false) as Node3D
	if visual == null:
		push_warning("Car model has no wheel named %s" % wheel_name)
		return
	# The wheel meshes are modelled in the body's axes around their own centre,
	# so keep only the body's orientation and drop the model's posed spin and steer.
	var body_axes := (global_transform.affine_inverse() * visual.get_parent_node_3d().global_transform).basis
	visual.reparent(wheel, false)
	# The Car Concept's wheels are scaled to fit other bodies' wheel arches.
	var fit := radius / WHEEL_RADIUS
	visual.transform = Transform3D(body_axes.scaled(Vector3.ONE * fit), Vector3.ZERO)
	_add_wheel_blur(wheel, signf(centre.x) * fit)


## A thin disc over the outside of the rim that fades in with speed to stand in for motion blur.
func _add_wheel_blur(wheel: VehicleWheel3D, side: float) -> void:
	# A spinning rim smears into rings: a dark hub, a lighter band where the spokes blur, a dark lip.
	var tone := rim_color if rim_color.a > 0.0 else Color(0.5, 0.51, 0.53)
	var rings := GradientTexture2D.new()
	rings.fill = GradientTexture2D.FILL_RADIAL
	rings.fill_from = Vector2(0.5, 0.5)
	rings.fill_to = Vector2(1.0, 0.5)
	rings.gradient = Gradient.new()
	rings.gradient.set_color(0, Color(0.25, 0.25, 0.25, 0.9))
	rings.gradient.add_point(0.25, Color(0.6, 0.6, 0.6, 0.35))
	rings.gradient.add_point(0.8, Color(1.0, 1.0, 1.0, 0.55))
	rings.gradient.add_point(0.93, Color(0.15, 0.15, 0.15, 0.8))
	rings.gradient.set_color(rings.gradient.get_point_count() - 1, Color(0.15, 0.15, 0.15, 0.0))
	var material := StandardMaterial3D.new()
	material.albedo_texture = rings
	material.albedo_color = Color(tone.r, tone.g, tone.b, 0.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.8
	material.roughness = 0.45
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var disc := QuadMesh.new()
	disc.size = Vector2(0.6, 0.6)
	disc.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = disc
	instance.rotation_degrees.y = 90.0 # face out of the side of the car
	instance.position = Vector3(side * 0.15, 0.0, 0.0)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wheel.add_child(instance)
	_wheel_blur.append(material)


func _fix_materials(model: Node) -> void:
	for node_name: String in LOGO_NODES:
		var logo := model.find_child(node_name, true, false) as Node3D
		if logo:
			logo.visible = false

	var glass := ShaderMaterial.new()
	glass.shader = Shader.new()
	glass.shader.code = GLASS_SHADER
	# Opponents get darker tint, like most road cars' rear and side glass.
	glass.set_shader_parameter("base_alpha", 0.28 if is_player else 0.55)

	for mesh_instance in model.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh_instance as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var material := mi.mesh.surface_get_material(i) as StandardMaterial3D
			if material == null:
				continue
			# The model bakes ambient occlusion into its second UV set, which the importer misses.
			material.ao_on_uv2 = true
			# Imported materials are shared by every car, so give each car its own copy of
			# anything that differs between cars: paint colour and lights.
			if material.resource_name.begins_with("Paint") or material.resource_name in ["Brakelight", "Headlight", "Rim1", "Rim2"]:
				_fix_paint(material)
				material = material.duplicate() as StandardMaterial3D
				mi.set_surface_override_material(i, material)
				if paint_color.a > 0.0 and material.resource_name.begins_with("Paint 1"):
					material.albedo_color = paint_color
					material.roughness = 0.18
				if rim_color.a > 0.0 and material.resource_name.begins_with("Rim"):
					material.albedo_color = rim_color
					material.roughness = 0.35
			match material.resource_name:
				# Godot does not import glTF transmission, so glass would render opaque.
				"Glass":
					mi.set_surface_override_material(i, glass)
				"Tireside":
					# Real tyres are dark grey, matte rubber, not pure black.
					material.albedo_texture = null
					material.albedo_color = Color(0.05, 0.05, 0.05)
					material.roughness = 0.85
					material.normal_enabled = false
				"Tiretread":
					material.albedo_color = Color(0.04, 0.04, 0.04)
					material.roughness = 0.9
					material.uv1_scale = Vector3(1.0, 4.0, 1.0)
					material.uv1_offset = Vector3(0.0, 1.5, 0.0)
				"Brakelight":
					_brake_light_material = material
				"Headlight":
					_headlight_material = material
				_:
					if material.resource_name in LOGO_EMISSIVE_MATERIALS:
						material.emission_enabled = false


## Restores what the importer drops from the paint: clearcoat, and the 30x tiling of the metal-flake normals.
func _fix_paint(material: StandardMaterial3D) -> void:
	if not material.resource_name.begins_with("Paint"):
		return
	material.uv1_scale = Vector3(30.0, 30.0, 1.0)
	material.ao_enabled = false
	material.metallic = 0.55
	material.clearcoat_enabled = true
	material.clearcoat = 1.0
	material.clearcoat_roughness = 0.03


## A big wing on swan-neck uprights, sized to the rear deck (about 1.0 m high near the tail).
func _build_rear_wing() -> void:
	var carbon := _carbon_material()
	var wing := Node3D.new()
	wing.position = Vector3(0.0, 1.36, -1.78)
	# Trailing edge up, like a real downforce wing.
	wing.rotation_degrees.x = -10.0
	add_child(wing)
	_add_part(wing, Vector3(1.95, 0.035, 0.34), Vector3.ZERO, carbon) # main plane
	_add_part(wing, Vector3(1.95, 0.05, 0.012), Vector3(0.0, 0.03, -0.17), carbon) # lip along the trailing edge
	for side in [-1.0, 1.0]:
		_add_part(wing, Vector3(0.02, 0.24, 0.44), Vector3(side * 0.985, -0.04, 0.0), carbon) # endplates
		_add_part(self, Vector3(0.04, 0.36, 0.12), Vector3(side * 0.45, 1.17, -1.72), carbon) # uprights


func _add_part(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	parent.add_child(part)


## Glossy twill-weave carbon fibre, generated as a small tiling texture.
func _carbon_material() -> StandardMaterial3D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGB8)
	for y in 16:
		for x in 16:
			# 2x2 twill: diagonal bands of alternating weave direction.
			var band := ((x / 4) + (y / 4)) % 4 < 2
			var along := float((x if band else y) % 4) / 3.0
			var v := 0.035 + 0.03 * sin(along * PI)
			image.set_pixel(x, y, Color(v, v, v * 1.1))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 25.0
	material.metallic = 0.3
	material.roughness = 0.35
	material.clearcoat_enabled = true
	material.clearcoat = 1.0
	material.clearcoat_roughness = 0.05
	return material


func _build_custom_body() -> void:
	_body_material = ShaderMaterial.new()
	_body_material.shader = Shader.new()
	_body_material.shader.code = CUSTOM_BODY_SHADER
	if paint_color.a > 0.0:
		_body_material.set_shader_parameter("paint", paint_color)
	var body := MeshInstance3D.new()
	body.name = "CustomBody"
	body.mesh = load(CUSTOM_BODY_MESH)
	body.material_override = _body_material
	add_child(body)


func cockpit_offset() -> Vector3:
	return _layout.cockpit


## Real cars sit in a pool of soft shadow where the body blocks the sky's light. Without it
## they look like they float above the road.
func _build_contact_shadow() -> void:
	var falloff := GradientTexture2D.new()
	falloff.fill = GradientTexture2D.FILL_RADIAL
	falloff.fill_from = Vector2(0.5, 0.5)
	falloff.fill_to = Vector2(1.0, 0.5)
	falloff.gradient = Gradient.new()
	falloff.gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.85))
	falloff.gradient.add_point(0.55, Color(0.0, 0.0, 0.0, 0.55))
	falloff.gradient.set_color(falloff.gradient.get_point_count() - 1, Color(0.0, 0.0, 0.0, 0.0))
	var decal := Decal.new()
	decal.texture_albedo = falloff
	decal.size = Vector3(2.5, 1.4, 5.0)
	decal.position = Vector3(0.0, 0.3, 0.22)
	decal.upper_fade = 0.2
	decal.lower_fade = 0.5
	decal.cull_mask = 1 # the ground and road only, not cars
	add_child(decal)


func _build_headlights() -> void:
	for pos: Vector3 in _layout.headlights:
		var light := SpotLight3D.new()
		light.position = pos
		# Spotlights shine down their -Z, so turn them to face forward and dip them slightly.
		light.basis = Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, -0.07)
		light.light_color = Color(1.0, 0.96, 0.88)
		light.light_energy = 8.5
		light.spot_range = 80.0
		light.spot_angle = 26.0
		light.spot_attenuation = 0.75
		light.shadow_enabled = is_player
		add_child(light)
		_headlights.append(light)
	set_headlights(false)


func _build_engine_sound() -> void:
	var loop := EngineLoop.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(loop.get_length() * loop.mix_rate)
	_engine = _add_audio_player(loop)
	_engine_rasp = _add_audio_player(loop)
	if not is_player:
		return

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = _mix_rate
	generator.buffer_length = 0.1
	var effects := _add_audio_player(generator)
	_playback = effects.get_stream_playback() as AudioStreamGeneratorPlayback


## The player hears their own car flat; AI cars are positioned in 3D so you hear them pass.
func _add_audio_player(stream: AudioStream) -> Node:
	var player: Node
	if is_player:
		player = AudioStreamPlayer.new()
	else:
		var positional := AudioStreamPlayer3D.new()
		positional.unit_size = 8.0
		positional.max_distance = 180.0
		player = positional
	player.stream = stream
	add_child(player)
	player.play()
	return player
