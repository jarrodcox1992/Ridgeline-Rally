extends SceneTree
# Screenshots the grid during the countdown and the field a few seconds into the race.
var main: Node3D
var t := 0.0
var shots := [[1.6, "grid"], [9.0, "race"], [15.0, "race2"]]
var fps_samples := []
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
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
	if t > 5.0: fps_samples.append(Engine.get_frames_per_second())
	if not shots.is_empty() and t > shots[0][0]:
		var name: String = shots.pop_front()[1]
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/%s.png" % name)
		if shots.is_empty():
			var avg := 0.0
			for f in fps_samples: avg += f
			print("RACESHOT fps avg %.1f min %.1f" % [avg / fps_samples.size(), fps_samples.min()])
			quit()
	return false
