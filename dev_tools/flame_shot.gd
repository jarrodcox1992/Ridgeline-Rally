extends SceneTree
# Accelerates hard, lifts off at high revs to trigger backfires, and screenshots the rear.
var main: Node3D
var t := 0.0
var cam: Camera3D
var lifted := -1.0
var pops := 0
var shot := false
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(delta: float) -> bool:
	t += delta
	var car = main.car
	if cam == null and t > 3.5:
		var ex = car.get_children().filter(func(c): return c.has_method("_pop"))[0]
		ex.on_pop = func(): pops += 1; car._pop_level = 1.0
		cam = Camera3D.new(); root.add_child(cam); cam.make_current(); cam.fov = 45.0
	if cam:
		var xf: Transform3D = car.global_transform
		cam.global_position = xf * Vector3(-2.2, 0.9, -5.5)
		cam.look_at(xf * Vector3(0.0, 0.55, -1.6), Vector3.UP)
	if lifted < 0.0:
		Input.action_press("accelerate")
		if car.rpm > 6000.0 and t > 4.0:
			Input.action_release("accelerate"); lifted = t
	elif not shot and pops > 0 and t - lifted > 0.09:
		shot = true
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/flames.png")
	if t > 9.0:
		print("FLAMES pops=%d shot=%s" % [pops, shot]); quit()
	return false
