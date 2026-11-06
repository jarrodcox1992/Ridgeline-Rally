extends CanvasLayer
## Pause menu: resume, restart, AI difficulty, time of day, graphics quality, fullscreen and quit.
## Settings are saved to user://settings.cfg so they survive restarts.

const SETTINGS_PATH := "user://settings.cfg"
const QUALITY_NAMES := ["Low", "Medium", "High"]
const DIFFICULTY_NAMES := ["Easy", "Normal", "Hard"]

var _main: Node
var _panel: PanelContainer
var _resume: Button
var _quality: OptionButton
var _difficulty: OptionButton
var _time_of_day: OptionButton
var _fullscreen: CheckButton
var _abs_btn: CheckButton
var _tcs_btn: CheckButton
var _volume_slider: HSlider


func setup(main: Node) -> void:
	_main = main
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	var quality: int = settings.get_value("graphics", "quality", 1)
	var fullscreen: bool = settings.get_value("graphics", "fullscreen", false)
	var difficulty: int = settings.get_value("race", "difficulty", 1)
	_difficulty.select(difficulty)
	_main.set_difficulty(difficulty)
	var time_of_day: int = settings.get_value("race", "time_of_day", 1)
	_time_of_day.select(time_of_day)
	_main.set_time_of_day(time_of_day)
	_quality.select(quality)
	_fullscreen.button_pressed = fullscreen
	_main.apply_quality(quality)
	_set_fullscreen(fullscreen)
	var abs_val: bool = settings.get_value("assists", "abs", true)
	var tcs_val: bool = settings.get_value("assists", "tcs", true)
	var vol_val: float = float(settings.get_value("audio", "master_volume", 100.0))
	_abs_btn.button_pressed = abs_val
	_tcs_btn.button_pressed = tcs_val
	if _main.car:
		_main.car.abs_enabled = abs_val
		_main.car.tcs_enabled = tcs_val
	_volume_slider.value = vol_val
	_set_master_volume(vol_val)
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_panel.visible = paused
	# Players keep looping while paused, so silence the mix instead.
	AudioServer.set_bus_mute(0, paused)
	if paused:
		_resume.grab_focus()


func _save() -> void:
	var settings := ConfigFile.new()
	settings.set_value("graphics", "quality", _quality.selected)
	settings.set_value("graphics", "fullscreen", _fullscreen.button_pressed)
	settings.set_value("race", "difficulty", _difficulty.selected)
	settings.set_value("race", "time_of_day", _time_of_day.selected)
	if _abs_btn:
		settings.set_value("assists", "abs", _abs_btn.button_pressed)
	if _tcs_btn:
		settings.set_value("assists", "tcs", _tcs_btn.button_pressed)
	if _volume_slider:
		settings.set_value("audio", "master_volume", _volume_slider.value)
	settings.save(SETTINGS_PATH)


func _set_master_volume(val: float) -> void:
	if val <= 0.0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		var db := linear_to_db(val / 100.0)
		AudioServer.set_bus_volume_db(0, db)


func _set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxEmpty.new()
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_panel.add_child(dim)

	var center := CenterContainer.new()
	_panel.add_child(center)
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.09, 0.1, 0.92)
	card_style.set_corner_radius_all(10)
	card_style.set_content_margin_all(28)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.custom_minimum_size = Vector2(340.0, 0.0)
	card.add_child(column)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	column.add_child(title)

	_resume = _add_button(column, "Resume", func(): _set_paused(false))
	_add_button(column, "Restart race", func():
		_set_paused(false)
		get_tree().reload_current_scene())

	_difficulty = _add_choice(column, "AI difficulty", DIFFICULTY_NAMES, func(index: int):
		_main.set_difficulty(index)
		_save())
	_time_of_day = _add_choice(column, "Time of day", _main.TIMES_OF_DAY.map(func(t): return t.name), func(index: int):
		_main.set_time_of_day(index)
		_save())
	_quality = _add_choice(column, "Graphics quality", QUALITY_NAMES, func(index: int):
		_main.apply_quality(index)
		_save())

	_fullscreen = CheckButton.new()
	_fullscreen.text = "Fullscreen"
	_fullscreen.toggled.connect(func(on: bool):
		_set_fullscreen(on)
		_save())
	_fullscreen.add_theme_font_size_override("font_size", 20)
	column.add_child(_fullscreen)

	# Master Audio Volume
	var vol_row := HBoxContainer.new()
	var v_lbl := Label.new()
	v_lbl.text = "Master Volume"
	v_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_lbl.add_theme_font_size_override("font_size", 20)
	vol_row.add_child(v_lbl)
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 5.0
	_volume_slider.value = 100.0
	_volume_slider.custom_minimum_size = Vector2(120.0, 24.0)
	_volume_slider.value_changed.connect(func(val: float):
		_set_master_volume(val)
		_save())
	vol_row.add_child(_volume_slider)
	column.add_child(vol_row)

	# Driver Assists (ABS & TCS)
	var assist_row := HBoxContainer.new()
	assist_row.add_theme_constant_override("separation", 16)
	_abs_btn = CheckButton.new()
	_abs_btn.text = "ABS"
	_abs_btn.button_pressed = true
	_abs_btn.add_theme_font_size_override("font_size", 18)
	_abs_btn.toggled.connect(func(on: bool):
		if _main.car:
			_main.car.abs_enabled = on
		_save())
	assist_row.add_child(_abs_btn)

	_tcs_btn = CheckButton.new()
	_tcs_btn.text = "TCS"
	_tcs_btn.button_pressed = true
	_tcs_btn.add_theme_font_size_override("font_size", 18)
	_tcs_btn.toggled.connect(func(on: bool):
		if _main.car:
			_main.car.tcs_enabled = on
		_save())
	assist_row.add_child(_tcs_btn)
	column.add_child(assist_row)

	_add_button(column, "Quit", func(): get_tree().quit())


## A labelled dropdown row.
func _add_choice(parent: Node, text: String, choices: Array, on_select: Callable) -> OptionButton:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 20)
	row.add_child(label)
	var options := OptionButton.new()
	for choice: String in choices:
		options.add_item(choice)
	options.item_selected.connect(on_select)
	row.add_child(options)
	parent.add_child(row)
	return options


func _add_button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
