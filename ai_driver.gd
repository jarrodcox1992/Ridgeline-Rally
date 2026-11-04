extends Node
## Drives an AI car: follows the track at a preferred lane, brakes in time for the
## corners it sees coming, and moves over to pass slower cars.

const STRAIGHT_SPEED := 70.0 # m/s; the car's power usually runs out first
const CORNER_GRIP := 8.8 # m/s^2 of sideways grip the AI plans to use, a margin under the car's limit
const BEND_ARC := 30.0 # length of track over which each bend is measured
const BRAKING := 7.0 # m/s^2 the AI assumes it can shed when planning for a corner
const SCAN_STEP := 18.0
const SCAN_STEPS := 7
const MAX_LANE := 4.5

var _car: VehicleBody3D
var _main: Node
var _skill := 1.0
## Set from the pause menu: scales every AI's pace.
var difficulty := 1.0
var _lane := 0.0
var _lane_now := 0.0
var _stuck_time := 0.0
var _rev_phase := randf() * TAU


## skill scales every speed target; lane is the preferred offset from the centreline
## in metres (+ is the driver's left).
func setup(car: VehicleBody3D, main: Node, skill: float, lane: float) -> void:
	_car = car
	_main = main
	_skill = skill
	_lane = lane
	_lane_now = lane


func _physics_process(delta: float) -> void:
	var input: Dictionary = _car.ai_input
	if _car.frozen:
		# Blip the throttle on the grid like a real driver.
		_rev_phase += delta * 3.0
		input.accelerate = 0.3 + 0.3 * sin(_rev_phase)
		return

	var offset: float = _main.curve.get_closest_offset(_car.global_position)
	var speed := _car.linear_velocity.length()

	_lane_now = move_toward(_lane_now, _choose_lane(offset), delta * 1.8)
	var target: Transform3D = _main._track_transform(offset + 10.0 + speed * 0.45, 0.0)
	var aim := _car.global_transform.affine_inverse() * (target.origin + target.basis.x * _lane_now)
	input.steer = clampf(atan2(aim.x, aim.z) * 2.2, -1.0, 1.0)

	var limit := _speed_limit(offset) * _skill * difficulty
	input.accelerate = 1.0 if speed < limit else 0.0
	input.brake = clampf((speed - limit) / 5.0, 0.0, 1.0) if speed > limit + 1.5 else 0.0
	input.handbrake = false

	_recover_if_stuck(offset, speed, delta)


## The fastest speed from which the car can still brake down for every bend in the next stretch.
func _speed_limit(offset: float) -> float:
	var limit := STRAIGHT_SPEED
	for k in SCAN_STEPS:
		var distance := k * SCAN_STEP
		var a := offset + distance
		var bend := absf(_main._track_dir(a).signed_angle_to(_main._track_dir(a + BEND_ARC), Vector3.UP))
		# A bend turning this much over BEND_ARC metres has radius BEND_ARC / bend; v = sqrt(grip * radius).
		var corner_speed := minf(STRAIGHT_SPEED, sqrt(CORNER_GRIP * BEND_ARC / maxf(bend, 0.001)))
		limit = minf(limit, sqrt(corner_speed * corner_speed + 2.0 * BRAKING * distance))
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
		if absf(other_lane - _lane_now) < 2.6 and other.linear_velocity.length() < my_speed + 1.0:
			var pass_lane := other_lane + 3.2 if _lane_now >= other_lane else other_lane - 3.2
			if absf(pass_lane) > MAX_LANE:
				pass_lane = other_lane - 3.2 * signf(pass_lane)
			return clampf(pass_lane, -MAX_LANE, MAX_LANE)
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
