extends SceneTree
# Runs a whole 3-lap race with the player's car on a simple autopilot and logs the field.
var main: Node3D
var t := 0.0
var next_report := 0.0
var resets := {}
var last_progress := {}
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	Engine.time_scale = 4.0
	var level := int(OS.get_environment("DIFF")) if OS.get_environment("DIFF") != "" else 1
	main.call_deferred("set_difficulty", level)
func _physics_process(delta: float) -> bool:
	t += delta
	var car: VehicleBody3D = main.car
	var offset: float = main.curve.get_closest_offset(car.global_position)
	var to_target: Vector3 = car.global_transform.affine_inverse() * main._track_point(offset + 18.0)
	var steer := clampf(atan2(to_target.x, to_target.z) * 2.0, -1.0, 1.0)
	Input.action_release("steer_left"); Input.action_release("steer_right")
	if steer > 0.0: Input.action_press("steer_left", steer)
	else: Input.action_press("steer_right", -steer)
	var ahead: Vector3 = main._track_point(offset + 60.0) - main._track_point(offset + 20.0)
	var fwd: Vector3 = main._track_point(offset + 20.0) - main._track_point(offset - 20.0)
	var limit := lerpf(42.0, 16.0, clampf(fwd.normalized().angle_to(ahead.normalized()), 0.0, 1.0))
	if car.linear_velocity.length() < limit: Input.action_press("accelerate"); Input.action_release("brake")
	else: Input.action_release("accelerate"); Input.action_press("brake", 0.6)
	# Count teleports (resets) as big one-frame jumps in position.
	for c in main.cars:
		var p: Vector3 = c.global_position
		if last_progress.has(c) and p.distance_to(last_progress[c]) > 5.0:
			resets[c.name] = resets.get(c.name, 0) + 1
		last_progress[c] = p
	if t >= next_report:
		next_report += 15.0
		var parts := []
		for c in main.cars:
			parts.append("%s %.0fm %.0fkm/h" % [c.name, main.progress[c], c.speed_kmh])
		print("t=%5.1f P%d | %s" % [t, main.player_position, " | ".join(parts)])
	if main.finish_order.size() == main.cars.size() or t > 360.0:
		print("FINISH order=", main.finish_order.map(func(c): return c.name), " race_time=%.1f best_lap=%.2f resets=%s" % [main.race_time, main.best_lap, resets])
		quit()
	return false
