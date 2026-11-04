extends VehicleBody3D
## A race car, driven either by the player or by an AI (see ai_driver.gd). Uses the
## Car Concept model (see CREDITS.md) for its looks and a recorded engine loop for sound.
## The car's forward direction is local +Z.

const CarModel := preload("res://models/car_concept.glb")
const CentenarioModel := preload("res://models/lamborghini_centenario/centenario.tscn")
const TireEffects := preload("res://tire_effects.gd")
const ExhaustScript := preload("res://exhaust.gd")

# Real Open-Source Audio Pack (Multi-RPM Engine Loops, Decel, Limiter, Tires, Transmission, Turbo, Impacts)
const EngineLoops: Array[AudioStreamWAV] = [
	preload("res://sounds/engine_loop_0.wav"),
	preload("res://sounds/engine_loop_1.wav"),
	preload("res://sounds/engine_loop_2.wav"),
	preload("res://sounds/engine_loop_3.wav"),
	preload("res://sounds/engine_loop_4.wav"),
	preload("res://sounds/engine_loop_5.wav"),
]
const LOOP_RPMS := [1000.0, 2000.0, 3200.0, 4600.0, 5900.0, 7200.0]
const EngineDecel := preload("res://sounds/engine_decel.wav")
const EngineLimiter := preload("res://sounds/engine_limiter.wav")
const TireScreech := preload("res://sounds/tire_screech.wav")
const TireScrub := preload("res://sounds/tire_scrub.wav")
const GearWhine := preload("res://sounds/gear_whine.wav")
const GearShiftUp := preload("res://sounds/gear_shift_up.wav")
const GearShiftDown := preload("res://sounds/gear_shift_down.wav")
const TurboBOV := preload("res://sounds/turbo_bov.wav")
const TurboWhistle := preload("res://sounds/turbo_whistle.wav")
const ImpactHeavy := preload("res://sounds/impact_heavy.wav")
const ImpactThud := preload("res://sounds/impact_thud.wav")
const ImpactClink := preload("res://sounds/impact_clink.wav")

const BackfireSounds: Array[AudioStreamWAV] = [
	preload("res://sounds/backfire_1.wav"),
	preload("res://sounds/backfire_2.wav"),
	preload("res://sounds/backfire_3.wav"),
	preload("res://sounds/backfire_4.wav"),
	preload("res://sounds/backfire_5.wav"),
	preload("res://sounds/backfire_6.wav"),
	preload("res://sounds/backfire_7.wav"),
	preload("res://sounds/backfire_8.wav"),
	preload("res://sounds/backfire_9.wav"),
]

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
	"centenario": {
		"wheels": {
			"WheelFrontL": Vector3(0.853, 0.381, 1.211), "WheelFrontR": Vector3(-0.861, 0.381, 1.184),
			"WheelRearL": Vector3(0.849, 0.396, -1.494), "WheelRearR": Vector3(-0.849, 0.396, -1.494),
		},
		"wheel_radius": 0.37,
		"collision": [[Vector3(2.06, 0.52, 4.95), Vector3(0.0, 0.45, 0.0)], [Vector3(1.6, 0.36, 2.1), Vector3(0.0, 0.95, -0.1)]],
		"headlights": [Vector3(0.68, 0.58, 2.15), Vector3(-0.68, 0.58, 2.15)],
		"tail_glow": Vector3(0.0, 0.65, -2.52),
		"exhausts": [Vector3(0.08, 0.38, -2.45), Vector3(-0.08, 0.38, -2.45)],
		"cockpit": Vector3(0.42, 0.88, -0.15),
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
signal collision_impact(strength: float)

var on_curb := false
var _turbo_boost := 0.0
var _turbo_phase := 0.0
var _bov_level := 0.0
var _bov_flutter := 0.0
var _prev_throttle := 0.0
var _rumble_phase := 0.0
var _scrape_level := 0.0
var _spark_emitter: GPUParticles3D

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

# Real Sample-Based Audio Players
var _engine_players: Array[Node] = []
var _engine_decel_player: Node
var _engine_limiter_player: Node
var _tire_screech_player: Node
var _tire_scrub_player: Node
var _gear_whine_player: Node
var _turbo_whistle_player: Node
var _shift_player: Node
var _bov_player: Node
var _backfire_player: Node
var _impact_player: Node

var _playback: AudioStreamGeneratorPlayback
var _mix_rate := 44100.0

# Aerodynamic Wind Buffeting & Stereo Air Rush
var _wind_l := 0.0
var _wind_r := 0.0
var _buffet_phase := 0.0
var _pop_level := 0.0

# Rev Limiter Staccato Ignition Cut & Downshift Blip
var _limiter_stutter := 0.0
var _ignition_cut := false
var _downshift_blip := 0.0


func _ready() -> void:
	mass = 1250.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, 0.35, 0.0)
	# Godot's default damping acts like heavy air drag; real drag is modelled below instead.
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	_layout = BODIES[body_style]
	for box: Array in _layout.collision:
		_add_collision(box[0], box[1])
	var model: Node3D
	if body_style == "centenario":
		model = CentenarioModel.instantiate() as Node3D
	else:
		model = CarModel.instantiate() as Node3D
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
		exhaust.on_pop = func():
			_pop_level = 1.0
			_trigger_backfire(randf_range(0.85, 1.0))
		_build_sparks()
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

	# Continuous scrape sparks and audio when rubbing against guardrails or opponents
	var scraping := false
	if contact_monitor and speed_kmh > 12.0:
		for b in get_colliding_bodies():
			if _is_obstacle(b):
				scraping = true
				break
	if scraping:
		_scrape_level = maxf(_scrape_level, 0.45)
		if _spark_emitter and not _spark_emitter.emitting:
			_spark_emitter.emitting = true
	elif _spark_emitter and _scrape_level < 0.1:
		_spark_emitter.emitting = false


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
	if _engine_players.is_empty():
		return

	# 1. Multi-RPM Crossfade Engine Loops (Real Recorded Audio)
	var n := LOOP_RPMS.size()
	for i in n:
		var center: float = LOOP_RPMS[i]
		var w := 0.0
		if i == 0 and rpm <= center:
			w = 1.0
		elif i == n - 1 and rpm >= center:
			w = 1.0
		elif i > 0 and rpm >= LOOP_RPMS[i - 1] and rpm <= center:
			w = (rpm - LOOP_RPMS[i - 1]) / (center - LOOP_RPMS[i - 1])
		elif i < n - 1 and rpm >= center and rpm <= LOOP_RPMS[i + 1]:
			w = 1.0 - (rpm - center) / (LOOP_RPMS[i + 1] - center)

		var player = _engine_players[i]
		if w > 0.01:
			var pitch: float = clampf(rpm / center, 0.68, 1.48)
			player.pitch_scale = pitch
			# Dynamic load scaling: full throttle roars louder and throatier
			var base_vol: float = linear_to_db(w)
			var throttle_boost: float = lerpf(-9.0, -1.0, throttle)
			if _ignition_cut:
				throttle_boost -= 12.0 # instantaneous torque cut
			player.volume_db = base_vol + throttle_boost
		else:
			player.volume_db = -80.0

	# 2. Real Off-Throttle Engine Deceleration Overrun
	if _engine_decel_player:
		if throttle < 0.22 and rpm > 2200.0 and speed_kmh > 15.0:
			var decel_w := (1.0 - throttle * 4.5) * clampf((rpm - 2200.0) / 2800.0, 0.0, 1.0)
			_engine_decel_player.pitch_scale = clampf(rpm / 4200.0, 0.65, 1.7)
			_engine_decel_player.volume_db = linear_to_db(decel_w) - 3.5
		else:
			_engine_decel_player.volume_db = -80.0

	# 3. Real Rev Limiter Bounce Cut
	if _engine_limiter_player:
		if _ignition_cut:
			_engine_limiter_player.pitch_scale = randf_range(0.96, 1.04)
			_engine_limiter_player.volume_db = -1.0
		else:
			_engine_limiter_player.volume_db = -80.0

	if not is_player:
		return

	# 4. Real Recorded Tire Screech (96 kHz Asphalt Slide)
	if _tire_screech_player:
		var squeal_norm := clampf((_skid - 0.26) * 2.8, 0.0, 1.0) * clampf(speed_kmh / 12.0, 0.0, 1.0)
		if burnout:
			squeal_norm = 1.0
		if squeal_norm > 0.01:
			_tire_screech_player.pitch_scale = clampf(0.90 + speed_kmh / 160.0 * 0.28 + _skid * 0.12, 0.85, 1.38)
			_tire_screech_player.volume_db = linear_to_db(squeal_norm) - 1.5
		else:
			_tire_screech_player.volume_db = -80.0

	# 5. Real Recorded Asphalt Scrub (Edge-of-Grip Friction)
	if _tire_scrub_player:
		var scrub_norm := 0.0
		if _skid > 0.08 and _skid < 0.42 and speed_kmh > 12.0:
			scrub_norm = clampf((_skid - 0.08) * 4.5, 0.0, 1.0) * clampf((0.42 - _skid) * 4.0, 0.0, 1.0)
		if scrub_norm > 0.01:
			_tire_scrub_player.pitch_scale = clampf(0.85 + speed_kmh / 120.0 * 0.35, 0.75, 1.45)
			_tire_scrub_player.volume_db = linear_to_db(scrub_norm) - 4.5
		else:
			_tire_scrub_player.volume_db = -80.0

	# 6. Real Recorded Straight-Cut Dog Gear Transmission Whine
	if _gear_whine_player:
		if speed_kmh > 4.0:
			var whine_norm := clampf(speed_kmh / 170.0, 0.0, 1.0) * lerpf(0.18, 0.95, throttle)
			_gear_whine_player.pitch_scale = clampf(speed_kmh / 80.0, 0.32, 2.7)
			_gear_whine_player.volume_db = linear_to_db(whine_norm) - 7.5
		else:
			_gear_whine_player.volume_db = -80.0

	# 7. Real Turbo Compressor Spool Whistle
	var target_boost := clampf((rpm - 2400.0) / 4200.0, 0.0, 1.0) * throttle
	_turbo_boost = move_toward(_turbo_boost, target_boost, 0.04)
	if throttle < 0.18 and _prev_throttle > 0.55 and _turbo_boost > 0.32:
		if _bov_player:
			_bov_player.stream = TurboBOV
			_bov_player.pitch_scale = randf_range(0.96, 1.05)
			_bov_player.volume_db = lerpf(-4.0, 2.0, _turbo_boost)
			_bov_player.play()
	_prev_throttle = throttle

	if _turbo_whistle_player:
		if _turbo_boost > 0.04:
			_turbo_whistle_player.pitch_scale = 0.72 + _turbo_boost * 0.85
			_turbo_whistle_player.volume_db = linear_to_db(_turbo_boost * _turbo_boost) - 6.5
		else:
			_turbo_whistle_player.volume_db = -80.0


## Procedural synthesis for high-speed wind buffeting, curb rumble clatter, and metal scrape.
func _fill_effects_sound() -> void:
	if _playback == null:
		return
	var frames: int = _playback.get_frames_available()
	if frames <= 0:
		return

	# Aerodynamic Wind & Cabin Pressure Buffeting
	var wind_speed_norm := clampf(speed_kmh / 260.0, 0.0, 1.0)
	var wind_level := wind_speed_norm * wind_speed_norm * 0.18
	var buffet_level := clampf((speed_kmh - 130.0) / 130.0, 0.0, 1.0) * 0.065

	# Curb Rumble Level
	var rumble_level := 0.28 if on_curb and speed_kmh > 10.0 else 0.0
	var rumble_hz := clampf(speed_kmh * 1.2, 38.0, 92.0)

	var inv_sr := 1.0 / _mix_rate

	for i in frames:
		# Wind Stereo Noise
		_wind_l += (randf_range(-1.0, 1.0) - _wind_l) * 0.06
		_wind_r += (randf_range(-1.0, 1.0) - _wind_r) * 0.06
		var out_l := _wind_l * wind_level
		var out_r := _wind_r * wind_level

		# High-speed aerodynamic buffeting (low-frequency cabin flutter)
		if buffet_level > 0.001:
			_buffet_phase = fmod(_buffet_phase + 52.0 * inv_sr, 1.0)
			var buff := sin(_buffet_phase * TAU) * buffet_level
			out_l += buff
			out_r += buff * 0.85

		# Curb Rumble / Kerb Clatter
		if rumble_level > 0.0:
			_rumble_phase = fmod(_rumble_phase + rumble_hz * inv_sr, 1.0)
			var curb_thump := (1.0 if _rumble_phase < 0.32 else -0.28) * rumble_level * 0.09
			out_l += curb_thump
			out_r += curb_thump

		# Collision Scrape / Metal Grinding
		if _scrape_level > 0.01:
			var scrape := randf_range(-1.0, 1.0) * _scrape_level * 0.18
			out_l += scrape
			out_r += scrape
			_scrape_level *= 0.9992

		# Final Soft Saturation / Master Limiter
		out_l = clampf(out_l, -0.95, 0.95)
		out_r = clampf(out_r, -0.95, 0.95)
		_playback.push_frame(Vector2(out_l, out_r))


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
	var prev_gear := gear
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

	# Rev-limiter bounce (staccato ignition cut at redline under heavy throttle)
	if target >= REDLINE_RPM - 40.0 and throttle > 0.8:
		_limiter_stutter += delta * 24.0
		if fmod(_limiter_stutter, 1.0) < 0.45:
			_ignition_cut = true
			target -= 280.0
			if randf() < 0.35:
				_trigger_backfire(randf_range(0.75, 1.0))
		else:
			_ignition_cut = false
	else:
		_ignition_cut = false
		_limiter_stutter = 0.0

	# Downshift rev-matching throttle blip & upshift pop
	if gear < prev_gear and not frozen:
		_downshift_blip = 1.0
		if is_player:
			if _shift_player:
				_shift_player.stream = GearShiftDown
				_shift_player.pitch_scale = randf_range(0.96, 1.04)
				_shift_player.volume_db = -1.0
				_shift_player.play()
			if randf() < 0.7:
				_trigger_backfire(randf_range(0.7, 0.95))
	elif gear > prev_gear and throttle > 0.4 and not frozen:
		if is_player:
			if _shift_player:
				_shift_player.stream = GearShiftUp
				_shift_player.pitch_scale = randf_range(0.96, 1.04)
				_shift_player.volume_db = -1.0
				_shift_player.play()
			_trigger_backfire(randf_range(0.85, 1.0))

	if _downshift_blip > 0.0:
		target += _downshift_blip * 950.0
		_downshift_blip = maxf(_downshift_blip - delta * 5.0, 0.0)

	rpm = lerpf(rpm, target, 1.0 - exp(-delta * 12.0))


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
	var fit := 1.0 if body_style == "centenario" else (radius / WHEEL_RADIUS)
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
	if body_style == "centenario":
		for mesh_instance in model.find_children("*", "MeshInstance3D", true, false):
			var mi := mesh_instance as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var material := mi.mesh.surface_get_material(i) as StandardMaterial3D
				if material == null:
					continue
				if material.resource_name == "LIGT_RED":
					_brake_light_material = material
				elif material.resource_name == "LIGT_BLC":
					_headlight_material = material
		return

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
	# 1. Multi-RPM Crossfade Engine Loops (Real Recorded Audio)
	for i in EngineLoops.size():
		var loop := _make_loop(EngineLoops[i])
		var player := _add_audio_player(loop)
		player.volume_db = -80.0
		_engine_players.append(player)

	# 2. Deceleration Overrun Rumble & Limiter Cut
	_engine_decel_player = _add_audio_player(_make_loop(EngineDecel))
	_engine_decel_player.volume_db = -80.0
	_engine_limiter_player = _add_audio_player(_make_loop(EngineLimiter))
	_engine_limiter_player.volume_db = -80.0

	if not is_player:
		return

	# 3. Real Tire Screech & Asphalt Scrub
	_tire_screech_player = _add_audio_player(_make_loop(TireScreech))
	_tire_screech_player.volume_db = -80.0
	_tire_scrub_player = _add_audio_player(_make_loop(TireScrub))
	_tire_scrub_player.volume_db = -80.0

	# 4. Straight-Cut Transmission Gear Whine & Turbo Whistle
	_gear_whine_player = _add_audio_player(_make_loop(GearWhine))
	_gear_whine_player.volume_db = -80.0
	_turbo_whistle_player = _add_audio_player(_make_loop(TurboWhistle))
	_turbo_whistle_player.volume_db = -80.0

	# 5. One-Shot Effect Players (Shifts, BOV flutter, Backfires, Impacts)
	_shift_player = _add_one_shot_player()
	_bov_player = _add_one_shot_player()
	_backfire_player = _add_one_shot_player()
	_impact_player = _add_one_shot_player()

	# 6. Procedural Generator for High-Speed Stereo Wind & Curb Clatter
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = _mix_rate
	generator.buffer_length = 0.1
	var effects := _add_audio_player(generator)
	_playback = effects.get_stream_playback() as AudioStreamGeneratorPlayback


func _make_loop(stream: AudioStreamWAV) -> AudioStreamWAV:
	var loop := stream.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(loop.get_length() * loop.mix_rate)
	return loop


func _add_one_shot_player() -> Node:
	var player: Node
	if is_player:
		player = AudioStreamPlayer.new()
	else:
		var positional := AudioStreamPlayer3D.new()
		positional.unit_size = 8.0
		positional.max_distance = 180.0
		player = positional
	add_child(player)
	return player


func _trigger_backfire(volume_scale: float = 1.0) -> void:
	if not is_player or _backfire_player == null or BackfireSounds.is_empty():
		return
	var sample: AudioStreamWAV = BackfireSounds[randi() % BackfireSounds.size()]
	_backfire_player.stream = sample
	_backfire_player.pitch_scale = randf_range(0.90, 1.12)
	_backfire_player.volume_db = lerpf(-9.0, 2.0, clampf(volume_scale, 0.0, 1.0))
	_backfire_player.play()
	_pop_level = volume_scale


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


func _build_sparks() -> void:
	_spark_emitter = GPUParticles3D.new()
	_spark_emitter.amount = 24
	_spark_emitter.lifetime = 0.28
	_spark_emitter.explosiveness = 0.8
	_spark_emitter.emitting = false
	_spark_emitter.local_coords = false
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.1)
	mat.emission_energy_multiplier = 10.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	quad.material = mat
	_spark_emitter.draw_pass_1 = quad
	var p_mat := ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0.0, 0.8, -1.0)
	p_mat.spread = 55.0
	p_mat.initial_velocity_min = 6.0
	p_mat.initial_velocity_max = 14.0
	p_mat.gravity = Vector3(0.0, -12.0, 0.0)
	p_mat.scale_min = 0.6
	p_mat.scale_max = 1.2
	_spark_emitter.process_material = p_mat
	add_child(_spark_emitter)


func _is_obstacle(node: Node) -> bool:
	if not node:
		return false
	if node is VehicleBody3D:
		return true
	var n := node.name
	return n.begins_with("Guardrail") or n.begins_with("Rock") or n.begins_with("Tree") or n.begins_with("Prop")


func _on_body_entered(body: Node) -> void:
	if not _is_obstacle(body):
		return
	var impact := linear_velocity.length()
	if impact > 2.0:
		_scrape_level = clampf(impact / 18.0, 0.35, 1.0)
		if is_player:
			collision_impact.emit(impact)
			if _impact_player:
				if impact > 10.5:
					_impact_player.stream = ImpactHeavy
					_impact_player.volume_db = 1.0
				elif impact > 5.0:
					_impact_player.stream = ImpactThud
					_impact_player.volume_db = lerpf(-4.0, 0.0, (impact - 5.0) / 5.5)
				else:
					_impact_player.stream = ImpactClink
					_impact_player.volume_db = -5.0
				_impact_player.pitch_scale = randf_range(0.92, 1.08)
				_impact_player.play()
			if _spark_emitter:
				_spark_emitter.position = Vector3(randf_range(-0.8, 0.8), 0.4, randf_range(-1.2, 1.2))
				_spark_emitter.restart()
				_spark_emitter.emitting = true
