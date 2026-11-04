extends Node3D
## Photo mode: freezes the game, hides the HUD and lets you orbit a camera around your car
## with a depth-of-field blur, then save the shot to your Pictures folder.
##   V or Esc: leave   mouse drag / arrow keys: orbit   wheel / + -: zoom   Space: save

const ORBIT_SPEED := 1.6
const MIN_DISTANCE := 2.5
const MAX_DISTANCE := 25.0
const HINT := "PHOTO MODE    drag or arrows: orbit    wheel or + -: zoom    Space: save    V: back"

var _main: Node
var _camera: Camera3D
var _attributes: CameraAttributesPractical
var _hint: Label
var _active := false
var _yaw := 0.0
var _pitch := 0.12
var _distance := 6.0
var _saving := false


func setup(main: Node) -> void:
	_main = main
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = Camera3D.new()
	_camera.fov = 45.0
	_attributes = CameraAttributesPractical.new()
	_attributes.dof_blur_far_enabled = true
	_attributes.dof_blur_far_transition = 12.0
	_attributes.dof_blur_amount = 0.12
	_camera.attributes = _attributes
	add_child(_camera)

	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_hint = Label.new()
	_hint.text = HINT
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 5)
	_hint.position = Vector2(28.0, 20.0)
	_hint.visible = false
	layer.add_child(_hint)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("photo_mode") or (_active and event.is_action_pressed("pause")):
		if _active or not get_tree().paused:
			_set_active(not _active)
		get_viewport().set_input_as_handled()
		return
	if not _active:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_yaw -= event.relative.x * 0.006
		_pitch = clampf(_pitch + event.relative.y * 0.004, -0.05, 1.3)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(_distance * 0.92, MIN_DISTANCE)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(_distance * 1.08, MAX_DISTANCE)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and not _saving:
		_save_shot()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _active:
		return
	_yaw += (float(Input.is_key_pressed(KEY_LEFT)) - float(Input.is_key_pressed(KEY_RIGHT))) * ORBIT_SPEED * delta
	_pitch = clampf(_pitch + (float(Input.is_key_pressed(KEY_UP)) - float(Input.is_key_pressed(KEY_DOWN))) * delta, -0.05, 1.3)
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):
		_distance = maxf(_distance - 6.0 * delta, MIN_DISTANCE)
	if Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):
		_distance = minf(_distance + 6.0 * delta, MAX_DISTANCE)
	var car: Node3D = _main.car
	var focus := car.global_position + Vector3.UP * 0.7
	var offset := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch)) * _distance
	_camera.global_position = focus + offset
	_camera.look_at(focus, Vector3.UP)
	# Keep the car sharp and blur what lies well behind it.
	_attributes.dof_blur_far_distance = _distance + 4.0


func _set_active(on: bool) -> void:
	_active = on
	get_tree().paused = on
	# Audio players keep playing while the tree is paused, so silence the mix instead.
	AudioServer.set_bus_mute(0, on)
	_main.hud_layer.visible = not on
	_hint.visible = on
	if on:
		_hint.text = HINT
		# Start behind the car, looking at it over the rear quarter.
		var car: Node3D = _main.car
		_yaw = atan2(-car.global_basis.z.x, -car.global_basis.z.z) + 0.6
		_camera.make_current()
	else:
		_main.camera.make_current()


func _save_shot() -> void:
	_saving = true
	_hint.visible = false
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var folder := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES).path_join("Ridgeline Rally")
	DirAccess.make_dir_recursive_absolute(folder)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := folder.path_join("ridgeline_%s.png" % stamp)
	var error := image.save_png(path)
	if error == OK:
		_hint.text = "Saved to " + path + "    (V: back)"
	else:
		push_warning("Photo mode could not save %s (error %d)" % [path, error])
		_hint.text = "Could not save to " + folder + "    (V: back)"
	_hint.visible = true
	_saving = false
