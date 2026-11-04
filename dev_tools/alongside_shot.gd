extends SceneTree
# Close-up of an AI car at speed from beside it: checks wheel blur, glass, cockpit and contact shadow.
var main: Node3D
var t := 0.0
var cam: Camera3D
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(delta: float) -> bool:
	t += delta
	if t > 9.0:
		var ai: VehicleBody3D = main.cars[0]
		if cam == null:
			cam = Camera3D.new(); root.add_child(cam); cam.make_current(); cam.fov = 40.0
		var xf := ai.global_transform
		cam.global_position = xf * Vector3(4.2, 0.9, 1.2)
		cam.look_at(xf * Vector3(0.0, 0.55, 0.0), Vector3.UP)
		if t > 9.4:
			root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/alongside.png")
			print("ALONGSIDE speed=%d" % ai.speed_kmh); quit()
	return false
