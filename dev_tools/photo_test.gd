extends SceneTree
# Does a burnout, enters photo mode, orbits a little and saves a shot through photo mode itself.
var main: Node3D
var t := 0.0
var stage := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(delta: float) -> bool:
	t += delta
	if stage == 0 and t > 3.2:
		if OS.get_environment("BURN") == "1": Input.action_press("handbrake"); Input.action_press("accelerate")
		stage = 1
	elif stage == 1 and t > 5.2:
		var ev := InputEventAction.new(); ev.action = "photo_mode"; ev.pressed = true
		Input.parse_input_event(ev)
		stage = 2
	elif stage == 2 and t > 5.6:
		var photo = main.get_children().filter(func(c): return c.has_method("_save_shot"))[0]
		photo._pitch = 0.08; photo._distance = 5.5; photo._yaw += 0.15
		if OS.get_environment("NOATTR") == "1": photo._camera.attributes = null
		print("CAMDBG pos=", photo._camera.global_position, " car=", main.car.global_position, " current=", photo._camera.current)
		stage = 3
	elif stage == 3 and t > 6.2:
		var photo = main.get_children().filter(func(c): return c.has_method("_save_shot"))[0]
		photo._save_shot()
		stage = 4
	elif stage == 4 and t > 7.0:
		var photo = main.get_children().filter(func(c): return c.has_method("_save_shot"))[0]
		print("PHOTO paused=%s hint=%s" % [paused, photo._hint.text])
		quit()
	return false
