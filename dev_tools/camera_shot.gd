extends SceneTree
# Drives with the autopilot and screenshots each camera view, plus look-back.
var main: Node3D
var t := 0.0
var shots := [[9.0, 0, false, "cam_chase"], [9.6, 1, false, "cam_far"], [10.2, 2, false, "cam_bumper"], [10.8, 3, false, "cam_cockpit"], [11.4, 0, true, "cam_lookback"]]
var pending: Array = []
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if OS.get_environment("TOD") != "":
		main.call_deferred("set_time_of_day", int(OS.get_environment("TOD")))
func _physics_process(delta: float) -> bool:
	t += delta
	var car: VehicleBody3D = main.car
	var offset: float = main.curve.get_closest_offset(car.global_position)
	var to_target: Vector3 = car.global_transform.affine_inverse() * main._track_point(offset + 18.0)
	var steer := clampf(atan2(to_target.x, to_target.z) * 2.0, -1.0, 1.0)
	Input.action_release("steer_left"); Input.action_release("steer_right")
	if steer > 0.0: Input.action_press("steer_left", steer)
	else: Input.action_press("steer_right", -steer)
	Input.action_press("accelerate")
	if not shots.is_empty() and t > shots[0][0] - 0.5 and pending.is_empty():
		pending = shots.pop_front()
		main.camera_view = pending[1]
		if pending[2]: Input.action_press("look_back")
		else: Input.action_release("look_back")
	if not pending.is_empty() and t > pending[0]:
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/%s.png" % pending[3])
		pending = []
		if shots.is_empty():
			print("CAMSHOTS done")
			quit()
	return false
