extends Node
## Drives an AI car: follows the track at a preferred lane, brakes in time for the
## corners it sees coming, and moves over to pass slower cars.

const STRAIGHT_SPEED := 70.0 # m/s; the car's power usually runs out first
const CORNER_GRIP := 8.8 # m/s^2 of sideways grip the AI plans to use, a margin under the car's limit
const BEND_ARC := 30.0 # length of track over which each bend is measured
const BRAKING := 7.0 # m/s^2 the AI assumes it can shed when planning for a corner
const SCAN_STEP := 18.0
const SCAN_STEPS := 7
const MAX_LANE := 7.8

var _car: VehicleBody3D
var _main: Node
var _skill := 1.0
## Set from the pause menu: scales every AI's pace.
var difficulty := 1.0
var _lane := 0.0
var _lane_now := 0.0
var _stuck_time := 0.0
var _rev_phase := randf() * TAU
var _route_pref: int = -1
var _active_alt_curve: Curve3D = null

# Personality
var _aggression := 0.5
var _braking := BRAKING
var _grip := CORNER_GRIP
var _wobble := 0.0
var _taunt := ""
var _time := 0.0
var _wander_phase := randf() * TAU
var _player_was_ahead := false
var _reaction_cd := 0.0
var _boost := 0.0


## skill scales every speed target; lane is the preferred offset from the centreline
## in metres (+ is the driver's left); route_pref (0=Overpass, 1=Bypass, 2=Tunnel).
func setup(car: VehicleBody3D, main: Node, skill: float, lane: float, route_pref: int = -1, persona: Dictionary = {}) -> void:
	_car = car
	_main = main
	_skill = skill
	_lane = lane
	_lane_now = lane
	_route_pref = route_pref
	if not persona.is_empty():
		_aggression = float(persona.get("aggression", 0.5))
		_braking = float(persona.get("braking", BRAKING))
		_grip = float(persona.get("grip", CORNER_GRIP))
		_wobble = float(persona.get("wobble", 0.0))
		_taunt = String(persona.get("taunt", ""))


func _physics_process(delta: float) -> void:
	_time += delta
	if _reaction_cd > 0.0:
		_reaction_cd = maxf(0.0, _reaction_cd - delta)
	_boost = maxf(0.0, _boost - delta * 0.8)
	var input: Dictionary = _car.ai_input
	if _car.frozen:
		# Blip the throttle on the grid like a real driver.
		_rev_phase += delta * 3.0
		input.accelerate = 0.3 + 0.3 * sin(_rev_phase)
		return

	var offset: float = _main.curve.get_closest_offset(_car.global_position)
	var speed := _car.linear_velocity.length()

	# If currently navigating an alternate overpass / bypass / tunnel branch
	if _active_alt_curve != null:
		var alt_len: float = _active_alt_curve.get_baked_length()
		var alt_offset: float = _active_alt_curve.get_closest_offset(_car.global_position)
		if alt_offset >= alt_len - 14.0:
			# Merged back onto the main circuit
			_active_alt_curve = null
		else:
			var aim_dist: float = minf(alt_len, alt_offset + 10.0 + speed * 0.45)
			var target_pt: Vector3 = _active_alt_curve.sample_baked(aim_dist, true)
			var aim: Vector3 = _car.global_transform.affine_inverse() * target_pt
			input.steer = clampf(atan2(aim.x, aim.z) * 2.2, -1.0, 1.0)
			var limit: float = STRAIGHT_SPEED * _skill * difficulty
			input.accelerate = 1.0 if speed < limit else 0.0
			input.brake = clampf((speed - limit) / 5.0, 0.0, 1.0) if speed > limit + 1.5 else 0.0
			input.handbrake = false
			_recover_if_stuck(offset, speed, delta)
			return

	# Check for alternate route branching opportunities
	if _active_alt_curve == null and _route_pref >= 0 and _main.get("alternate_curves") != null:
		var alt_curves: Array = _main.alternate_curves
		if _route_pref < alt_curves.size():
			var cand_curve: Curve3D = alt_curves[_route_pref]
			if cand_curve.point_count > 0:
				var entry_pt: Vector3 = cand_curve.get_point_position(0)
				if _car.global_position.distance_to(entry_pt) < 22.0:
					_active_alt_curve = cand_curve

	_react_to_player(offset, delta)

	_lane_now = move_toward(_lane_now, _choose_lane(offset), delta * 1.8)
	var target: Transform3D = _main._track_transform(offset + 10.0 + speed * 0.45, 0.0)
	var aim := _car.global_transform.affine_inverse() * (target.origin + target.basis.x * _lane_now)
	input.steer = clampf(atan2(aim.x, aim.z) * 2.2, -1.0, 1.0)

	var limit := _speed_limit(offset) * _skill * difficulty * (1.0 + _boost)
	if _wobble > 0.0:
		limit *= 1.0 + sin(_time * 0.8 + _wander_phase) * _wobble
	input.accelerate = 1.0 if speed < limit else 0.0
	input.brake = clampf((speed - limit) / 5.0, 0.0, 1.0) if speed > limit + 1.5 else 0.0
	input.handbrake = false

	_recover_if_stuck(offset, speed, delta)


## Reacts to the player: taunts when overtaken, and a high-aggression driver fights back.
func _react_to_player(offset: float, _delta: float) -> void:
	var player := _main.get("car") as VehicleBody3D
	if not is_instance_valid(player) or player == _car:
		return
	var here: Transform3D = _main._track_transform(offset, 0.0)
	var rel: Vector3 = here.affine_inverse() * player.global_position
	var player_ahead: bool = rel.z > 0.0 and rel.z < 28.0 and absf(rel.x) < 8.0
	if player_ahead and not _player_was_ahead and _reaction_cd <= 0.0 and _taunt != "":
		_reaction_cd = 8.0
		if _main.has_method("_show_message"):
			_main.call("_show_message", _taunt, 3.0)
		if _aggression > 0.55:
			_boost = 1.0  # Dig in and try to retake the place.
		else:
			_lane = clampf(_lane + (4.0 if rel.x > 0.0 else -4.0), -MAX_LANE, MAX_LANE)  # Give room
	_player_was_ahead = player_ahead


## The fastest speed from which the car can still brake down for every bend in the next stretch.
func _speed_limit(offset: float) -> float:
	var limit := STRAIGHT_SPEED
	for k in SCAN_STEPS:
		var distance := k * SCAN_STEP
		var a := offset + distance
		var bend := absf(_main._track_dir(a).signed_angle_to(_main._track_dir(a + BEND_ARC), Vector3.UP))
		# A bend turning this much over BEND_ARC metres has radius BEND_ARC / bend; v = sqrt(grip * radius).
		var corner_speed := minf(STRAIGHT_SPEED, sqrt(_grip * BEND_ARC / maxf(bend, 0.001)))
		limit = minf(limit, sqrt(corner_speed * corner_speed + 2.0 * _braking * distance))
	return limit


## Keeps to the preferred lane unless a slower car is just ahead in the way.
func _choose_lane(offset: float) -> float:
	var here: Transform3D = _main._track_transform(offset, 0.0)
	var my_speed := _car.linear_velocity.length()
	for other: VehicleBody3D in _main.cars:
		if other == _car:
			continue
		var rel := _car.global_transform.affine_inverse() * other.global_position
		if rel.z < 0.0 or rel.z > 16.0:
			continue
		var other_lane := (other.global_position - here.origin).dot(here.basis.x)
		if absf(other_lane - _lane_now) < 3.2 and other.linear_velocity.length() < my_speed + 1.0:
			var pass_lane := other_lane + 4.5 if _lane_now >= other_lane else other_lane - 4.5
			if absf(pass_lane) > MAX_LANE:
				pass_lane = other_lane - 4.5 * signf(pass_lane)
			return clampf(pass_lane, -MAX_LANE, MAX_LANE)
	# Personality: an aggressive driver blocks a player trying to pass; a calm one opens a lane.
	var player := _main.get("car") as VehicleBody3D
	if is_instance_valid(player) and player != _car:
		var prel: Vector3 = here.affine_inverse() * player.global_position
		var player_behind := prel.z < 0.0 and prel.z > -18.0
		if player_behind and absf(prel.x - _lane_now) < 3.6:
			if _aggression > 0.55:
				return clampf(prel.x, -MAX_LANE, MAX_LANE)
			elif _aggression < 0.3:
				return clampf(_lane + (4.2 if prel.x >= _lane_now else -4.2), -MAX_LANE, MAX_LANE)
	return _lane


func _recover_if_stuck(offset: float, speed: float, delta: float) -> void:
	var upside_down := _car.global_basis.y.y < 0.3
	if speed < 2.0 or upside_down:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
	if _stuck_time > 3.0 or _car.global_position.y < -30.0:
		_stuck_time = 0.0
		var spot: Transform3D = _main._track_transform(offset, 0.8)
		_car.reset_to(spot.translated(spot.basis.x * _lane))
