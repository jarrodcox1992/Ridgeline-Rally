extends SceneTree
# Drives for 30 s with the autopilot (with a handbrake slide at 12 s) and reports slow frames.
var main: Node3D
var t := 0.0
var slow := []
var frames := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if OS.get_environment("NOSHADOW") == "1":
		(func(): main.sun.shadow_enabled = false).call_deferred()
	if OS.get_environment("EXPO") != "":
		(func(): main.env.adjustment_enabled = false; main.env.glow_enabled = false).call_deferred()
	if OS.get_environment("NOTREESHADOW") == "1":
		(func(): for tr in main.tree_instances: tr.cast_shadow = 0).call_deferred()
	if OS.get_environment("NOCARSHADOW") == "1":
		(func():
			for c in main.cars:
				for m in c.find_children("*", "GeometryInstance3D", true, false): m.cast_shadow = 0).call_deferred()
	if OS.get_environment("NOSSR") == "1":
		(func(): main.env.ssr_enabled = false).call_deferred()
	if OS.get_environment("TOD") != "":
		main.call_deferred("set_time_of_day", int(OS.get_environment("TOD")))
func _process(delta: float) -> bool:
	t += delta
	frames += 1
	if t > 0.5 and delta > 1.0 / 40.0:
		slow.append("%.1fs:%dms" % [t, roundi(delta * 1000.0)])
	var car: VehicleBody3D = main.car
	var offset: float = main.curve.get_closest_offset(car.global_position)
	var to_target: Vector3 = car.global_transform.affine_inverse() * main._track_point(offset + 18.0)
	var steer := clampf(atan2(to_target.x, to_target.z) * 2.0, -1.0, 1.0)
	Input.action_release("steer_left"); Input.action_release("steer_right")
	if steer > 0.0: Input.action_press("steer_left", steer)
	else: Input.action_press("steer_right", -steer)
	Input.action_press("accelerate")
	if t > 12.0 and t < 12.8: Input.action_press("handbrake")
	else: Input.action_release("handbrake")
	if t > 30.0:
		print("HITCH avg_fps=%.1f slow_frames=%d %s" % [frames / t, slow.size(), slow.slice(0, 25)])
		quit()
	return false
