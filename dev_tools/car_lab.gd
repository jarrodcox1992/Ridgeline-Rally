extends SceneTree
# Car test lab: flat ground, one car driven through standard maneuvers. Prints measurements.
const CarScript := preload("res://car.gd")
var car: VehicleBody3D
var t := 0.0
var test := 0
var data := {}
var tests := ["accel", "brake", "skidpad", "handbrake", "lane_change"]

func _initialize() -> void:
	Engine.time_scale = 4.0
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(8000, 2, 8000)
	shape.shape = box; shape.position = Vector3(0, -1, 0)
	ground.add_child(shape); root.add_child(ground)
	car = CarScript.new(); car.is_player = false
	root.add_child(car)
	_start()

func _start() -> void:
	t = 0.0; data = {"phase": 0}
	car.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.6, 0)))
	_input(0, 0, 0, false)

func _input(a: float, b: float, s: float, hb: bool) -> void:
	car.ai_input.accelerate = a; car.ai_input.brake = b; car.ai_input.steer = s; car.ai_input.handbrake = hb

func _yaw_rate() -> float: return car.angular_velocity.y
func _kmh() -> float: return car.linear_velocity.length() * 3.6
func _slip_angle() -> float:
	var v := car.linear_velocity; v.y = 0
	if v.length() < 1.0: return 0.0
	var f := car.global_basis.z; f.y = 0
	return rad_to_deg(f.signed_angle_to(v, Vector3.UP))

func _physics_process(delta: float) -> bool:
	t += delta
	var name: String = tests[test]
	var done := false
	match name:
		"accel":
			_input(1, 0, 0, false)
			if not data.has("t100") and _kmh() >= 100.0: data.t100 = t
			if not data.has("t200") and _kmh() >= 200.0: data.t200 = t
			if t >= 10.0 and not data.has("v10"): data.v10 = _kmh()
			if t >= 40.0: data.top = _kmh(); done = true
		"brake":
			if data.phase == 0:
				_input(1, 0, 0, false)
				if _kmh() >= 100.0: data.phase = 1; data.start = car.global_position; data.bt = t
			else:
				_input(0, 1, 0, false)
				if _kmh() < 0.5: data.dist = car.global_position.distance_to(data.start); data.time = t - data.bt; done = true
		"skidpad":
			# Fixed moderate steering while speed slowly rises; record the most lateral grip
			# the car holds before it slides (slip angle over 8 degrees).
			var steer := 0.0 if t < 3.0 else 1.0
			_input(0.35 if t > 3.0 else 1.0, 0, steer, false)
			if t > 5.0:
				var lat := absf(_yaw_rate()) * car.linear_velocity.length() / 9.81
				if absf(_slip_angle()) < 8.0:
					data.max_lat_g = maxf(data.get("max_lat_g", 0.0), lat)
					data.at_kmh = _kmh()
				else:
					data.slid_at_kmh = data.get("slid_at_kmh", _kmh())
			if t >= 25.0 or data.has("slid_at_kmh") and t > data.get("slide_end", 0.0):
				done = true
			if data.has("slid_at_kmh") and not data.has("slide_end"):
				data.slide_end = t + 0.5
		"handbrake":
			if data.phase == 0:
				_input(1, 0, 0, false)
				if _kmh() >= 80.0: data.phase = 1; data.ht = t; data.v0 = _kmh(); data.yaw0 = car.global_rotation.y
			elif t - data.ht < 1.2:
				_input(0.3, 0, 1.0, true)
				data.max_slip = maxf(data.get("max_slip", 0.0), absf(_slip_angle()))
			elif t - data.ht < 3.2:
				_input(0.7, 0, -0.4, false)
				data.max_slip = maxf(data.get("max_slip", 0.0), absf(_slip_angle()))
			else:
				data.v_after = _kmh(); data.turned = rad_to_deg(absf(wrapf(car.global_rotation.y - data.yaw0, -PI, PI)))
				data.spun = car.global_basis.z.dot(car.linear_velocity.normalized()) < 0.0
				done = true
		"lane_change":
			if data.phase == 0:
				_input(1, 0, 0, false)
				if _kmh() >= 140.0: data.phase = 1; data.lt = t
			else:
				var k: float = t - data.lt
				var s := 1.0 if k < 0.6 else (-1.0 if k < 1.4 else 0.0)
				_input(0.6, 0, s, false)
				data.max_slip = maxf(data.get("max_slip", 0.0), absf(_slip_angle()))
				if k > 4.0:
					data.final_yaw_rate = absf(_yaw_rate()); data.kmh = _kmh(); done = true
	if t > 60.0: data.timeout = true; done = true
	if done:
		var shown := data.duplicate(); shown.erase("phase"); shown.erase("start"); shown.erase("lat"); shown.erase("n")
		for k in shown: if shown[k] is float: shown[k] = snappedf(shown[k], 0.01)
		print("LAB ", name, " ", shown)
		test += 1
		if test >= tests.size(): quit()
		else: _start()
	return false
