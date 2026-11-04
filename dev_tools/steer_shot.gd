extends SceneTree
# Holds full left lock while parked and screenshots the cockpit, then the front with headlights on.
var main: Node3D
var t := 0.0
var stage := 0
var cam: Camera3D
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(delta: float) -> bool:
	t += delta
	var car = main.car
	Input.action_press("steer_left")
	if stage == 0 and t > 1.5:
		main.hood_camera = true
		stage = 1
	elif stage == 1 and t > 2.0:
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/steer_left.png")
		car.set_headlights(true)
		cam = Camera3D.new(); root.add_child(cam); cam.make_current()
		stage = 2
	elif stage == 2:
		var xf: Transform3D = car.global_transform
		cam.global_position = xf * Vector3(2.5, 1.0, 6.0)
		cam.look_at(xf * Vector3(0, 0.6, 1.5), Vector3.UP)
		if t > 2.5:
			root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/headlights.png")
			print("STEER shots saved, steering=", car.steering)
			quit()
	return false
