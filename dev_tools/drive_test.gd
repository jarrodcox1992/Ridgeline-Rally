extends SceneTree
# Autopilot test: drives the car around the track and reports what happens.

var main: Node3D
var t := 0.0
var next_report := 0.0
var max_speed := 0.0
var resets := 0
var shot_path := ""

func _initialize() -> void:
	shot_path = OS.get_environment("SHOT")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if OS.get_environment("TOD") != "":
		main.call_deferred("set_time_of_day", int(OS.get_environment("TOD")))
	if shot_path == "":
		Engine.time_scale = 4.0

func _physics_process(delta: float) -> bool:
	t += delta
	var car: VehicleBody3D = main.car
	var offset: float = main.curve.get_closest_offset(car.global_position)
	var target: Vector3 = main._track_point(offset + 18.0)
	var to_target := car.global_transform.affine_inverse() * target
	var steer := clampf(atan2(to_target.x, to_target.z) * 2.0, -1.0, 1.0)
	Input.action_release("steer_left"); Input.action_release("steer_right")
	if steer > 0.0: Input.action_press("steer_left", steer)
	else: Input.action_press("steer_right", -steer)
	var speed := car.linear_velocity.length()
	max_speed = maxf(max_speed, speed)
	# Look ahead along the track for the sharpest bend within braking range (scaled to speed),
	# so the car slows before a corner instead of carrying speed into it.
	var fwd: Vector3 = main._track_point(offset + 20.0) - main._track_point(offset - 20.0)
	var bend := 0.0
	var look := 30.0 + speed * 1.2
	var d := 20.0
	while d <= look:
		var seg: Vector3 = main._track_point(offset + d + 15.0) - main._track_point(offset + d - 15.0)
		bend = maxf(bend, fwd.normalized().angle_to(seg.normalized()))
		d += 10.0
	var limit := lerpf(42.0, 14.0, clampf(bend / 0.5, 0.0, 1.0))
	_check_stall(car, speed, offset, delta)
	if speed < limit:
		Input.action_press("accelerate"); Input.action_release("brake")
	else:
		Input.action_release("accelerate")
		if speed > limit + 4.0: Input.action_press("brake")
		else: Input.action_release("brake")
	if main.flipped_time > 2.4: resets += 1
	if shot_path != "":
		_shots(car)
	if t >= next_report:
		next_report += 10.0
		print("t=%5.1f speed=%5.1f km/h pos=(%6.1f,%5.2f,%6.1f) up=%.2f gear=%s rpm=%d lap=%d running=%s lap_time=%.1f next_cp=%d dist_from_line=%.1f" % [t, speed * 3.6, car.global_position.x, car.global_position.y, car.global_position.z, car.global_basis.y.y, car.gear_text(), car.rpm, main.laps_done, main.lap_running, main.lap_time, main.next_checkpoint, offset])
	if main.laps_done >= 1 or t > 200.0:
		print("DONE laps=%d last_lap=%.2f best=%.2f max_speed=%.1f km/h auto_resets=%d stalls=%d" % [main.laps_done, main.last_lap, main.best_lap, max_speed * 3.6, resets, stalls.size()])
		quit()
	return false

## Stall detection: if the car is effectively stopped for STALL_SECONDS (outside the start grid),
## record where it is and what its wheels are touching, then reset it onto the road and carry on.
const STALL_SECONDS := 4.0
var stall_timer := 0.0
var stalls: Array[String] = []

func _check_stall(car: VehicleBody3D, speed: float, offset: float, delta: float) -> void:
	if t < 5.0 or main.laps_done >= 1:
		return
	if speed > 0.5:
		stall_timer = 0.0
		return
	stall_timer += delta
	if stall_timer < STALL_SECONDS:
		return
	stall_timer = 0.0
	var ctr: Vector3 = main._track_point(offset)
	var lat_dir: Vector3 = main._track_dir(offset).cross(Vector3.UP).normalized()
	var lat := (car.global_position - ctr).dot(lat_dir)
	var contacts: Array[String] = []
	for w in car.get_children():
		if w is VehicleWheel3D and w.is_in_contact():
			var cb = w.get_contact_body()
			contacts.append(str(cb.get_path()) if cb else "none")
	var rec := "t=%.1f off=%.0f lat=%.2f pos=(%.1f,%.2f,%.1f) wheel_contacts=%s" % [t, offset, lat, car.global_position.x, car.global_position.y, car.global_position.z, str(contacts)]
	stalls.append(rec)
	print("STALL ", rec)
	main._reset_car()

var shot_stage := 0
var shot_cam: Camera3D
var shot_until := 0.0
# Each view: [name, camera position relative to car, look-at point relative to car, fov] or a special name.
var views := [
	["chase"],
	["side", Vector3(3.6, 1.1, 2.4), Vector3(0, 0.6, 0.2), 50.0],
	["rear", Vector3(-2.5, 1.2, -5.0), Vector3(0, 0.7, 0), 55.0],
	["sun"],
	["hood"],
]

func _save(suffix: String) -> void:
	var path := shot_path.replace(".png", "_" + suffix + ".png")
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SCREENSHOT ", path, " fps=", Engine.get_frames_per_second())

func _shots(car: VehicleBody3D) -> void:
	if t < 8.0 or t < shot_until:
		_place(car)
		return
	if shot_stage > 0:
		_save(views[shot_stage - 1][0])
	if shot_stage >= views.size():
		quit()
		return
	var view: Array = views[shot_stage]
	shot_stage += 1
	shot_until = t + 0.4
	if shot_cam == null:
		shot_cam = Camera3D.new()
		root.add_child(shot_cam)
	main.camera_view = 3 if view[0] == "hood" else 0
	if view[0] in ["chase", "hood"]:
		main.camera.make_current()
	else:
		shot_cam.make_current()
	_place(car)

func _place(car: VehicleBody3D) -> void:
	if shot_stage == 0:
		return
	var view: Array = views[shot_stage - 1]
	var xf := car.global_transform
	if view[0] == "sun":
		var sun_dir: Vector3 = main.sun_direction
		var flat := Vector3(sun_dir.x, 0, sun_dir.z).normalized()
		shot_cam.global_position = car.global_position - flat * 6.0 + Vector3.UP * 1.5
		shot_cam.look_at(shot_cam.global_position + flat + Vector3.UP * 0.6, Vector3.UP)
		shot_cam.fov = 95.0
	elif view.size() > 1:
		shot_cam.global_position = xf * (view[1] as Vector3)
		shot_cam.look_at(xf * (view[2] as Vector3), Vector3.UP)
		shot_cam.fov = view[3]
