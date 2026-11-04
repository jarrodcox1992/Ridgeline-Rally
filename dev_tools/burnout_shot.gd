extends SceneTree
# After the countdown, holds handbrake + full throttle for a burnout and screenshots it
# from a low rear three-quarter angle, like a car photo.
var main: Node3D
var t := 0.0
var cam: Camera3D
var start_pos: Vector3
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if OS.get_environment("TOD") != "":
		main.call_deferred("set_time_of_day", int(OS.get_environment("TOD")))
func _physics_process(delta: float) -> bool:
	t += delta
	var car = main.car
	if t > 3.2:
		Input.action_press("handbrake"); Input.action_press("accelerate")
		if start_pos == Vector3.ZERO: start_pos = car.global_position
		if cam == null:
			cam = Camera3D.new(); root.add_child(cam); cam.make_current(); cam.fov = 50.0
		var xf: Transform3D = car.global_transform
		cam.global_position = xf * Vector3(-3.4, 0.7, -5.2)
		cam.look_at(xf * Vector3(0.3, 0.7, -0.5), Vector3.UP)
	if t > 5.0:
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/burnout.png")
		print("BURNOUT burnout=%s rpm=%d moved=%.1fm" % [car.burnout, car.rpm, car.global_position.distance_to(start_pos)])
		quit()
	return false
