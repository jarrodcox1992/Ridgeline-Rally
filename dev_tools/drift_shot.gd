extends SceneTree
# Accelerates down the start straight, then yanks the handbrake and steers to provoke a slide,
# and screenshots the result from a chase camera above and behind.
var main: Node3D
var t := 0.0
var cam: Camera3D
var max_slip := 0.0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(delta: float) -> bool:
	t += delta
	var car: VehicleBody3D = main.car
	for a in ["accelerate", "handbrake", "steer_left", "steer_right", "brake"]: Input.action_release(a)
	if t < 5.0:
		Input.action_press("accelerate")
	elif t < 6.6:
		Input.action_press("handbrake"); Input.action_press("steer_left"); Input.action_press("accelerate", 0.6)
	elif t < 8.0:
		Input.action_press("accelerate"); Input.action_press("steer_right", 0.5)
	for w in car._all_wheels:
		max_slip = maxf(max_slip, 1.0 - w.get_skidinfo())
	if t > 7.2 and cam == null:
		cam = Camera3D.new(); root.add_child(cam); cam.make_current()
		var f := car.global_basis.z; f.y = 0; f = f.normalized()
		cam.global_position = car.global_position - f * 9.0 + Vector3.UP * 4.5 + f.cross(Vector3.UP) * 3.0
		cam.look_at(car.global_position - f * 2.0, Vector3.UP)
	if t > 7.5:
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/drift.png")
		var fx = car.get_children().filter(func(c): return c.has_method("_add_mark"))[0]
		print("DRIFT max_slip=%.2f marks=%d speed=%.0f" % [max_slip, fx._marks.visible_instance_count, car.speed_kmh])
		quit()
	return false
