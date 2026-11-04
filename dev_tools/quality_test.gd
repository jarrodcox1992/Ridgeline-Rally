extends SceneTree
# Drives with the autopilot, measures frame rate at each quality level, then opens the pause menu.
var main: Node3D
var t := 0.0
var frames := 0
var window_start := 0.0
var level := -1
var results := []
var menu_opened := false
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(delta: float) -> bool:
	if menu_opened:
		t += delta
		if t > 0.6:
			root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/pause_menu.png")
			print("QUALITY fps low/med/high = ", results, " paused=", paused)
			quit()
		return false
	t += delta
	frames += 1
	var car: VehicleBody3D = main.car
	var offset: float = main.curve.get_closest_offset(car.global_position)
	var to_target: Vector3 = car.global_transform.affine_inverse() * main._track_point(offset + 18.0)
	var steer := clampf(atan2(to_target.x, to_target.z) * 2.0, -1.0, 1.0)
	Input.action_release("steer_left"); Input.action_release("steer_right")
	if steer > 0.0: Input.action_press("steer_left", steer)
	else: Input.action_press("steer_right", -steer)
	if car.linear_velocity.length() < 22.0: Input.action_press("accelerate")
	else: Input.action_release("accelerate")
	var next_level := int(t / 4.0)
	if next_level != level:
		if level >= 0:
			results.append(snappedf((frames - 1) / (t - window_start), 0.1))
		if next_level > 2:
			Input.action_release("accelerate")
			var ev := InputEventAction.new(); ev.action = "pause"; ev.pressed = true
			Input.parse_input_event(ev)
			menu_opened = true
			t = 0.0
			return false
		level = next_level
		main.apply_quality(level)
		frames = 0
		window_start = t + 1.0
	if t < window_start:
		frames = 0
	return false
