extends Node3D
## Builds the whole game at startup: landscape, race track, scenery, car,
## camera, HUD and lap timing. Everything is procedural, so no asset files.

const CarScript := preload("res://car.gd")
const MinimapScript := preload("res://minimap.gd")
const PauseMenuScript := preload("res://pause_menu.gd")
const AIDriverScript := preload("res://ai_driver.gd")
const PhotoModeScript := preload("res://photo_mode.gd")

## Track centreline in metres (x, z). The loop closes back to the first point.
const TRACK_POINTS := [
	Vector2(0, -200), Vector2(120, -210), Vector2(220, -150), Vector2(250, -40),
	Vector2(200, 40), Vector2(110, 50), Vector2(60, 120), Vector2(90, 210),
	Vector2(20, 260), Vector2(-110, 240), Vector2(-200, 170), Vector2(-230, 60),
	Vector2(-160, -30), Vector2(-200, -120), Vector2(-120, -190),
]
const ROAD_HALF_WIDTH := 7.0
const ROAD_HEIGHT := 0.12
const TERRAIN_SIZE := 1500.0
const TERRAIN_RES := 150
const CHECKPOINT_COUNT := 10
const TREE_COUNT := 1100
const TREE_VARIANTS := 3
const TREE_PATCH_SIZE := 200.0
## Tree patches further than this from the camera don't cast shadows. Trees' shadows are
## costly to draw when the sun is low, and far-off ones can't be seen through the haze.
const TREE_SHADOW_RANGE := 260.0
const GRASS_PER_METRE := 16
const GRASS_BAND := Vector2(9.8, 40.0) # distance from the track centreline
const GRASS_CHUNK_LENGTH := 60.0
const ROCK_MODELS := ["res://models/rock_moss_set_01/rock_moss_set_01.gltf", "res://models/boulder_01/boulder_01.gltf"]
const DASH_LENGTH := 3.0
const DASH_GAP := 6.0
const CORNER_TURN := 0.14 # radians of heading change over 16 m that counts as a corner
const KERB_SEGMENT := 1.5
const GUARDRAIL_OFFSET := 12.0
const ROCK_COUNT := 140
const BOULDER_COUNT := 14
## Size in metres of one baked tree frame (matches the bake's camera).
const TREE_QUAD_SIZE := Vector2(9.6, 19.2)
const RACE_LAPS := 3
const PLAYER_PAINT := Color(0.012, 0.014, 0.02) # gloss black with a hint of blue
const COUNTDOWN := 3.0
const DIFFICULTY_PACE := [0.88, 1.0, 1.07] # Easy, Normal, Hard
const CAMERA_VIEWS := [
	{"name": "Chase camera", "mode": "chase", "distance": 6.5, "height": 2.3},
	{"name": "Far chase camera", "mode": "chase", "distance": 10.0, "height": 3.4},
	{"name": "Bumper camera", "mode": "bumper"},
	{"name": "Cockpit camera", "mode": "cockpit"},
]
## Opponents: paint colour and skill (scales their target speeds).
const OPPONENTS := [
	{"name": "Blue", "color": Color(0.04, 0.16, 0.55), "skill": 1.0},
	{"name": "Pearl", "color": Color(0.85, 0.85, 0.82), "skill": 0.96},
	{"name": "Red", "color": Color(0.62, 0.04, 0.03), "skill": 0.92},
]
## Start grid slots behind the line: distance back and offset to the driver's left.
## The player starts from the last slot.
const GRID := [Vector2(10.0, 3.0), Vector2(18.0, -3.0), Vector2(26.0, 3.0), Vector2(34.0, -3.0)]
## Times of day. Each sky is a Poly Haven HDRI; "sun" points towards the sun in it, found by
## aiming a camera at its brightest pixel. The sunset sun is raised a little above the
## horizon (about 14 degrees) so shadows don't stretch for hundreds of metres.
const TIMES_OF_DAY := [
	{"name": "Day", "sky": "res://textures/sky/kloofendal_puresky_4k.hdr", "sun": Vector3(-0.374, 0.745, 0.552),
		"sun_color": Color(1.0, 0.95, 0.88), "sun_energy": 1.6, "sky_energy": 1.0, "exposure": 1.0,
		"fog_color": Color(0.7, 0.76, 0.85), "fog_density": 0.0012, "contrast": 1.0, "saturation": 1.0,
		"shadow_scale": 1.0},
	{"name": "Sunset", "sky": "res://textures/sky/belfast_sunset_puresky_4k.hdr", "sun": Vector3(-0.54, 0.25, 0.84),
		"sun_color": Color(1.0, 0.55, 0.28), "sun_energy": 2.2, "sky_energy": 1.0, "exposure": 0.72,
		"fog_color": Color(0.5, 0.42, 0.4), "fog_density": 0.0005, "contrast": 1.18, "saturation": 1.2,
		"shadow_scale": 0.55}, # a low sun's long shadows are expensive, so draw them over a shorter range
	{"name": "Night", "sky": "res://textures/sky/qwantani_night_puresky_2k.hdr", "sun": Vector3(-0.3, 0.7, 0.4),
		"sun_color": Color(0.35, 0.45, 0.75), "sun_energy": 0.15, "sky_energy": 0.7, "exposure": 0.95,
		"fog_color": Color(0.04, 0.06, 0.12), "fog_density": 0.0018, "contrast": 1.15, "saturation": 1.1,
		"shadow_scale": 0.4},
]
const TERRAIN_TEXTURES := {
	"grass_albedo": "res://textures/aerial_grass_rock/aerial_grass_rock_diff_2k.jpg",
	"grass_normal": "res://textures/aerial_grass_rock/aerial_grass_rock_nor_gl_2k.jpg",
	"grass_roughness": "res://textures/aerial_grass_rock/aerial_grass_rock_rough_2k.jpg",
	"rock_albedo": "res://textures/rock_face_03/rock_face_03_diff_1k.jpg",
	"rock_normal": "res://textures/rock_face_03/rock_face_03_nor_gl_1k.jpg",
	"snow_albedo": "res://textures/snow_02/snow_02_diff_1k.jpg",
	"snow_normal": "res://textures/snow_02/snow_02_nor_gl_1k.jpg",
}

const TERRAIN_SHADER := """
shader_type spatial;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_roughness : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D snow_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D snow_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
// Real-world size in metres that each texture covers.
uniform float grass_tile = 15.0;
uniform float rock_tile = 5.0;
uniform float snow_tile = 4.0;
// The grass photo is of dry summer grass; this shifts it towards spring green.
uniform vec3 grass_tint = vec3(0.68, 0.95, 0.45);
varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Rock is projected from three sides so it does not stretch on cliffs.
vec3 triplanar_rock(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= w.x + w.y + w.z;
	return texture(rock_albedo, p.zy / rock_tile).rgb * w.x
		+ texture(rock_albedo, p.xz / rock_tile).rgb * w.y
		+ texture(rock_albedo, p.xy / rock_tile).rgb * w.z;
}

void fragment() {
	float n = texture(noise_tex, world_pos.xz * 0.01).r;
	float macro = texture(noise_tex, world_pos.xz * 0.003 + 0.37).r;

	// Blend the grass with a rotated, larger copy of itself to hide the repeating tile.
	vec2 grass_uv = world_pos.xz / grass_tile;
	vec2 grass_uv2 = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * world_pos.xz / (grass_tile * 2.7);
	float tile_mix = smoothstep(0.35, 0.65, n);
	vec3 grass = mix(texture(grass_albedo, grass_uv).rgb, texture(grass_albedo, grass_uv2).rgb, tile_mix);
	vec3 grass_n = mix(texture(grass_normal, grass_uv).rgb, texture(grass_normal, grass_uv2).rgb, tile_mix);
	float grass_r = mix(texture(grass_roughness, grass_uv).r, texture(grass_roughness, grass_uv2).r, tile_mix);
	grass *= grass_tint * mix(0.8, 1.15, macro);

	float slope = 1.0 - world_normal.y;
	float rockiness = smoothstep(0.22, 0.42, slope + (n - 0.5) * 0.2);
	vec3 rock = triplanar_rock(world_pos, world_normal);
	vec3 rock_n = texture(rock_normal, world_pos.xz / rock_tile).rgb;

	float snow = smoothstep(95.0, 125.0, world_pos.y + n * 20.0) * (1.0 - rockiness * 0.6);
	vec3 snow_c = texture(snow_albedo, world_pos.xz / snow_tile).rgb;
	vec3 snow_n = texture(snow_normal, world_pos.xz / snow_tile).rgb;

	ALBEDO = mix(mix(grass, rock, rockiness), snow_c, snow);
	NORMAL_MAP = mix(mix(grass_n, rock_n, rockiness), snow_n, snow);
	ROUGHNESS = mix(mix(grass_r, 0.85, rockiness), 0.6, snow);
}
"""

## Trees are "impostors": flat cards showing a photoreal fir (Poly Haven "Fir Tree 01")
## pre-rendered from 8 angles. Each card turns to face the camera and shows the matching view.
## Atlas rows are the 3 tree variants, columns the 8 view angles.
const TREE_SHADER := """
shader_type spatial;
render_mode world_vertex_coords, cull_disabled;
uniform sampler2D albedo_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_atlas : filter_linear_mipmap;
uniform float frames = 8.0;
uniform float rows = 3.0;
uniform vec2 quad_size = vec2(9.6, 19.2);
varying vec3 right_w;
varying vec3 facing_w;
varying float frame_pos;
varying flat float row;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float scale = length(MODEL_MATRIX[1].xyz);
	// In the shadow pass this is the light's camera, so shadows show the tree as the sun sees it.
	vec3 to_cam = INV_VIEW_MATRIX[3].xyz - origin;
	to_cam.y = 0.0;
	to_cam = length(to_cam) > 0.001 ? normalize(to_cam) : vec3(0.0, 0.0, 1.0);
	right_w = normalize(cross(vec3(0.0, 1.0, 0.0), to_cam));
	facing_w = to_cam;
	vec2 local = vec2(UV.x - 0.5, 1.0 - UV.y) * quad_size * scale;
	VERTEX = origin + right_w * local.x + vec3(0.0, local.y, 0.0);
	NORMAL = to_cam;
	mat3 rot = mat3(normalize(MODEL_MATRIX[0].xyz), normalize(MODEL_MATRIX[1].xyz), normalize(MODEL_MATRIX[2].xyz));
	vec3 local_dir = transpose(rot) * to_cam;
	frame_pos = fract(atan(local_dir.x, local_dir.z) / TAU) * frames;
	row = INSTANCE_CUSTOM.r;
}

void fragment() {
	// Cross-fade between the two nearest baked views.
	float f0 = floor(frame_pos);
	float t = frame_pos - f0;
	float f1 = mod(f0 + 1.0, frames);
	vec2 cell = vec2(1.0 / frames, 1.0 / rows);
	vec2 uv0 = (vec2(f0, row) + UV) * cell;
	vec2 uv1 = (vec2(f1, row) + UV) * cell;
	vec4 albedo = mix(texture(albedo_atlas, uv0), texture(albedo_atlas, uv1), t);
	vec3 baked_n = mix(texture(normal_atlas, uv0).rgb, texture(normal_atlas, uv1).rgb, t) * 2.0 - 1.0;
	vec3 world_n = normalize(right_w * baked_n.x + vec3(0.0, 1.0, 0.0) * baked_n.y + facing_w * baked_n.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(world_n, 0.0)).xyz);
	ALBEDO = albedo.rgb * COLOR.rgb;
	ALPHA = albedo.a;
	ALPHA_SCISSOR_THRESHOLD = 0.3;
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.12, 0.16, 0.06);
}
"""

## Grass tufts drawn as three crossed cards; the blades are cut out in the shader.
const GRASS_SHADER := """
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;
uniform vec3 root_color : source_color = vec3(0.15, 0.19, 0.06);
uniform vec3 tip_color : source_color = vec3(0.45, 0.48, 0.2);
uniform float fade_start = 45.0;
uniform float fade_end = 75.0;
varying float tuft_seed;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	tuft_seed = hash(origin.x * 0.37 + origin.z * 1.13);
	float height = 1.0 - UV.y;
	// Shrink tufts into the ground with distance instead of fading, so no blending is needed.
	float dist = distance(origin, INV_VIEW_MATRIX[3].xyz);
	float shrink = 1.0 - smoothstep(fade_start, fade_end, dist);
	VERTEX = origin + (VERTEX - origin) * vec3(1.0, shrink, 1.0);
	// Wind sway grows towards the blade tips.
	float gust = sin(TIME * 1.6 + origin.x * 0.21 + origin.z * 0.17) * 0.5 + 0.5;
	VERTEX.x += sin(TIME * 2.3 + tuft_seed * 6.28) * 0.06 * height * (0.4 + gust);
	VERTEX.z += cos(TIME * 1.9 + tuft_seed * 6.28) * 0.04 * height * (0.4 + gust);
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	float columns = 14.0;
	float x = UV.x * columns;
	float id = floor(x);
	float t = 1.0 - UV.y;
	float blade_h = 0.45 + 0.55 * hash(id + tuft_seed * 17.0);
	float lean = (hash(id * 3.1 + tuft_seed) - 0.5) * 0.6;
	float centre = 0.5 + lean * t;
	float width = 0.3 * (1.0 - t / blade_h);
	if (t > blade_h || abs(fract(x) - centre) > width) {
		discard;
	}
	vec3 tint = mix(vec3(0.85), vec3(1.15), tuft_seed);
	ALBEDO = mix(root_color, tip_color, smoothstep(0.0, blade_h, t)) * tint;
	ROUGHNESS = 0.85;
	BACKLIGHT = vec3(0.15, 0.2, 0.05);
}
"""

const CHECKER_SHADER := """
shader_type spatial;
void fragment() {
	vec2 cell = floor(UV * vec2(16.0, 2.0));
	float k = mod(cell.x + cell.y, 2.0);
	ALBEDO = vec3(0.04 + k * 0.86);
	ROUGHNESS = 0.7;
}
"""

var curve: Curve3D
var track_length := 0.0
var track_path: Path3D
var car: VehicleBody3D
var cars: Array[VehicleBody3D] = []
var ai_drivers: Array[Node] = []
var progress := {} # car -> metres driven since the start line, counting laps
var _last_offset := {}
var countdown := COUNTDOWN
var race_time := 0.0
var player_finish_time := 0.0
var finish_order: Array[VehicleBody3D] = []
var player_position := GRID.size() # the player starts from the back of the grid
var camera: Camera3D
var camera_view := 0
var noise := FastNoiseLite.new()
var env: Environment
var sky_material: PanoramaSkyMaterial
var sun_direction := Vector3.UP
var _shadow_distance := 200.0
var _shadow_scale := 1.0
var sun: DirectionalLight3D
var grass_instances: Array[MultiMeshInstance3D] = []
var tree_instances: Array[MultiMeshInstance3D] = []
var _tree_shadows := true
var _tree_shadow_timer := 0.0

var next_checkpoint := 0
var lap_running := false
var lap_time := 0.0
var last_lap := INF
var best_lap := INF
var laps_done := 0
var flipped_time := 0.0

var speed_label: Label
var gear_label: Label
var lap_label: Label
var position_label: Label
var fps_label: Label
var hud_layer: CanvasLayer
var time_label: Label
var last_label: Label
var best_label: Label
var message_label: Label
var message_timer := 0.0
var current_time_of_day_index := 1
var camera_shake := 0.0
var shift_light_bar: HBoxContainer
var shift_lights: Array[ColorRect] = []
var _corners: Array[Vector3] = []


func _ready() -> void:
	_setup_input()
	noise.seed = 7
	noise.frequency = 0.004
	noise.fractal_octaves = 5
	_build_track_curve()
	_build_environment()
	_build_terrain()
	_build_road()
	_build_start_line()
	_build_road_details()
	_build_checkpoints()
	_build_trees()
	_build_grass()
	_build_rocks()
	_spawn_car()
	_build_camera()
	_build_hud()
	var menu := PauseMenuScript.new()
	add_child(menu)
	menu.setup(self)
	var photo := PhotoModeScript.new()
	add_child(photo)
	photo.setup(self)
	_show_message("3", 1.4)


func _physics_process(delta: float) -> void:
	if lap_running:
		lap_time += delta
	_update_race(delta)

	if Input.is_action_just_pressed("reset_car"):
		_reset_car()
	if Input.is_action_just_pressed("show_fps"):
		fps_label.visible = not fps_label.visible
	if Input.is_action_just_pressed("camera"):
		camera_view = (camera_view + 1) % CAMERA_VIEWS.size()
		_show_message(CAMERA_VIEWS[camera_view].name, 1.2)

	# Recover automatically if the car ends up on its roof or falls off the world.
	if car.global_basis.y.y < 0.3 and car.linear_velocity.length() < 3.0:
		flipped_time += delta
	else:
		flipped_time = 0.0
	if flipped_time > 2.5 or car.global_position.y < -30.0:
		_reset_car()

	if car:
		var offset := curve.get_closest_offset(car.global_position)
		var t_xform := _track_transform(offset, 0.0)
		var lateral_dist := absf((t_xform.affine_inverse() * car.global_position).x)
		var on_kerb: bool = _is_in_corner(offset) and lateral_dist > (ROAD_HALF_WIDTH - 0.6) and lateral_dist < (ROAD_HALF_WIDTH + 1.4)
		(car as CarScript).on_curb = on_kerb
		if on_kerb:
			var speed := car.linear_velocity.length()
			camera_shake = maxf(camera_shake, clampf(speed / 30.0, 0.0, 1.0) * 0.045)

	_update_camera(delta)


func _process(delta: float) -> void:
	_tree_shadow_timer -= delta
	if _tree_shadow_timer <= 0.0:
		_tree_shadow_timer = 0.5
		_update_tree_shadows()
	var car_script := car as CarScript
	speed_label.text = "%d km/h" % roundi(car_script.speed_kmh)
	gear_label.text = "Gear %s   %d rpm" % [car_script.gear_text(), roundi(car_script.rpm / 10.0) * 10]
	_update_shift_lights()
	if car in finish_order:
		lap_label.text = "Finished P%d" % (finish_order.find(car) + 1)
	else:
		lap_label.text = "Lap %d / %d" % [mini(laps_done + 1, RACE_LAPS), RACE_LAPS]
	position_label.text = "Position %d / %d" % [player_position, cars.size()]
	if fps_label.visible:
		fps_label.text = "%d fps" % Engine.get_frames_per_second()
	if car in finish_order:
		time_label.text = "Race  " + _format_time(player_finish_time)
	else:
		time_label.text = "Time  " + (_format_time(lap_time) if lap_running else "--:--.--")
	last_label.text = "Last  " + _format_time(last_lap)
	best_label.text = "Best  " + _format_time(best_lap)
	if message_timer > 0.0:
		message_timer -= delta
		message_label.modulate.a = clampf(message_timer, 0.0, 1.0)


func _update_shift_lights() -> void:
	if not car or shift_lights.is_empty():
		return
	var rpm: float = (car as CarScript).rpm
	var redline: bool = rpm >= 6850.0
	var flash: bool = fmod(Time.get_ticks_msec() / 65.0, 2.0) < 1.0
	var thresholds := [3200.0, 3800.0, 4400.0, 5000.0, 5500.0, 6000.0, 6400.0, 6750.0, 7000.0]
	var active_colors := [
		Color(0.1, 0.9, 0.2), Color(0.1, 0.9, 0.2), Color(0.1, 0.9, 0.2),
		Color(1.0, 0.75, 0.1), Color(1.0, 0.75, 0.1), Color(1.0, 0.75, 0.1),
		Color(0.95, 0.15, 0.1), Color(0.95, 0.15, 0.1), Color(0.3, 0.6, 1.0)
	]
	var off_color := Color(0.12, 0.14, 0.16, 0.45)
	for i in 9:
		if redline and flash:
			shift_lights[i].color = Color(1.0, 0.1, 0.1)
		elif rpm >= thresholds[i]:
			shift_lights[i].color = active_colors[i]
		else:
			shift_lights[i].color = off_color


## Index into TIMES_OF_DAY. Sunlight comes from where the sun is in the sky, so shadows match it.
func set_time_of_day(index: int) -> void:
	current_time_of_day_index = index
	var time: Dictionary = TIMES_OF_DAY[index]
	sky_material.panorama = load(time.sky)
	sky_material.energy_multiplier = time.sky_energy
	env.tonemap_exposure = time.exposure
	env.fog_light_color = time.fog_color
	env.fog_density = time.fog_density
	env.adjustment_enabled = true
	env.adjustment_contrast = time.contrast
	env.adjustment_saturation = time.saturation
	sun_direction = (time.sun as Vector3).normalized()
	sun.light_color = time.sun_color
	sun.light_energy = time.sun_energy
	sun.look_at_from_position(Vector3.ZERO, -sun_direction, Vector3.UP)
	_shadow_scale = time.shadow_scale
	sun.directional_shadow_max_distance = _shadow_distance * _shadow_scale
	var is_night: bool = time.name == "Night"
	for c in cars:
		if c.has_method("set_headlights"):
			c.set_headlights(is_night)


func _update_tree_shadows() -> void:
	var eye := camera.global_position if camera else Vector3.ZERO
	for trees in tree_instances:
		var near := trees.custom_aabb.get_center().distance_to(eye) < TREE_SHADOW_RANGE
		var wanted := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if _tree_shadows and near else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Only touch patches that change; reassigning makes the renderer redo work.
		if trees.cast_shadow != wanted:
			trees.cast_shadow = wanted


## 0 = Easy, 1 = Normal, 2 = Hard.
func set_difficulty(level: int) -> void:
	for driver in ai_drivers:
		driver.difficulty = DIFFICULTY_PACE[level]


## 0 = Low, 1 = Medium, 2 = High. Trades shadows, ambient occlusion, grass and
## render resolution for frame rate.
func apply_quality(level: int) -> void:
	var viewport := get_viewport()
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	viewport.scaling_3d_scale = [0.7, 1.0, 1.0][level]
	env.ssao_enabled = level == 2
	# Lets glossy paint and glass reflect the road, other cars and trees, not just the sky.
	# It costs about a third of the frame rate on a 2019 MacBook Pro, so High only.
	env.ssr_enabled = level == 2
	env.ssr_max_steps = 48
	env.glow_enabled = level >= 1
	_shadow_distance = [120.0, 200.0, 300.0][level]
	sun.directional_shadow_max_distance = _shadow_distance * _shadow_scale
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if level == 0 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	for grass in grass_instances:
		grass.visible = level >= 1
		grass.visibility_range_end = 60.0 if level == 1 else 90.0
	_tree_shadows = level >= 1
	_update_tree_shadows()


# --- Input ---------------------------------------------------------------

func _setup_input() -> void:
	_add_action("accelerate", [KEY_W, KEY_UP], [], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_add_action("brake", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	_add_action("steer_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_action("steer_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_action("handbrake", [KEY_SPACE], [JOY_BUTTON_A], [])
	_add_action("reset_car", [KEY_R], [JOY_BUTTON_Y], [])
	_add_action("camera", [KEY_C], [JOY_BUTTON_BACK], [])
	_add_action("headlights", [KEY_H], [JOY_BUTTON_DPAD_UP], [])
	_add_action("look_back", [KEY_B], [JOY_BUTTON_LEFT_SHOULDER], [])
	_add_action("show_fps", [KEY_F], [], [])
	_add_action("photo_mode", [KEY_V], [JOY_BUTTON_RIGHT_SHOULDER], [])
	_add_action("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], [])


func _add_action(action: StringName, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.15)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	for button in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)
	for axis in axes:
		var event := InputEventJoypadMotion.new()
		event.axis = axis[0]
		event.axis_value = axis[1]
		InputMap.action_add_event(action, event)


# --- Track helpers -------------------------------------------------------

func _build_track_curve() -> void:
	curve = Curve3D.new()
	curve.bake_interval = 2.0
	var n := TRACK_POINTS.size()
	# Repeat the first point at the end so the loop closes smoothly.
	for i in n + 1:
		var p: Vector2 = TRACK_POINTS[i % n]
		var prev: Vector2 = TRACK_POINTS[(i - 1 + n) % n]
		var next: Vector2 = TRACK_POINTS[(i + 1) % n]
		var handle := (next - prev) * 0.22
		curve.add_point(Vector3(p.x, 0.0, p.y), Vector3(-handle.x, 0.0, -handle.y), Vector3(handle.x, 0.0, handle.y))
	track_length = curve.get_baked_length()
	track_path = Path3D.new()
	track_path.name = "TrackPath"
	track_path.curve = curve
	add_child(track_path)


func _track_point(offset: float) -> Vector3:
	return curve.sample_baked(fposmod(offset, track_length), true)


func _track_dir(offset: float) -> Vector3:
	return (_track_point(offset + 2.0) - _track_point(offset - 2.0)).normalized()


## The basis's +Z points along the track and +X to the driver's left.
func _track_transform(offset: float, height: float) -> Transform3D:
	var dir := _track_dir(offset)
	# looking_at points -Z at the target, so aim backwards to make +Z face along the track.
	return Transform3D(Basis.looking_at(-dir, Vector3.UP), _track_point(offset) + Vector3.UP * height)


func _distance_to_track(x: float, z: float) -> float:
	var closest := curve.get_closest_point(Vector3(x, 0.0, z))
	return Vector2(closest.x - x, closest.z - z).length()


## Ground is flat near the road, rolls into hills further out,
## and rises into a ring of mountains at the edge of the map.
func _terrain_height(x: float, z: float) -> float:
	var d := _distance_to_track(x, z)
	var hills := (noise.get_noise_2d(x, z) * 0.5 + 0.5) * 70.0 * smoothstep(25.0, 170.0, d)
	var edge := maxf(absf(x), absf(z))
	var ridge := noise.get_noise_2d(x * 2.0 + 500.0, z * 2.0) * 0.5 + 0.5
	var mountains := smoothstep(420.0, 720.0, edge) * 150.0 * (0.6 + 0.4 * ridge)
	return hills + mountains


# --- World building ------------------------------------------------------

func _build_environment() -> void:
	sky_material = PanoramaSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_material

	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_aerial_perspective = 0.8
	env.fog_sky_affect = 0.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 250.0
	add_child(sun)
	set_time_of_day(1)


func _build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := TERRAIN_SIZE / TERRAIN_RES
	var half := TERRAIN_SIZE * 0.5
	for zi in TERRAIN_RES + 1:
		for xi in TERRAIN_RES + 1:
			var x := -half + xi * step
			var z := -half + zi * step
			st.set_uv(Vector2(xi, zi) / TERRAIN_RES)
			st.add_vertex(Vector3(x, _terrain_height(x, z), z))
	var row := TERRAIN_RES + 1
	for zi in TERRAIN_RES:
		for xi in TERRAIN_RES:
			var i := zi * row + xi
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + row)
			st.add_index(i + 1)
			st.add_index(i + row + 1)
			st.add_index(i + row)
	st.generate_normals()
	st.generate_tangents()
	var mesh := st.commit()

	var noise_texture := NoiseTexture2D.new()
	noise_texture.seamless = true
	noise_texture.noise = FastNoiseLite.new()
	var shader := Shader.new()
	shader.code = TERRAIN_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("noise_tex", noise_texture)
	for param: String in TERRAIN_TEXTURES:
		material.set_shader_parameter(param, load(TERRAIN_TEXTURES[param]))

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)

	var body := StaticBody3D.new()
	body.name = "Terrain"
	var shape := CollisionShape3D.new()
	var trimesh := mesh.create_trimesh_shape() as ConcavePolygonShape3D
	trimesh.backface_collision = true
	shape.shape = trimesh
	body.add_child(shape)
	add_child(body)


func _build_road() -> void:
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_texture = load("res://textures/asphalt_track/asphalt_track_diff_2k.jpg")
	asphalt.normal_enabled = true
	asphalt.normal_texture = load("res://textures/asphalt_track/asphalt_track_nor_gl_2k.jpg")
	asphalt.roughness_texture = load("res://textures/asphalt_track/asphalt_track_rough_2k.jpg")
	asphalt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	asphalt.uv1_triplanar = true
	asphalt.uv1_world_triplanar = true
	asphalt.uv1_scale = Vector3.ONE * 0.5 # the texture covers 2 m

	# Cross-section with sloped shoulders so the car can drive on and off the road.
	var road := _add_track_strip(PackedVector2Array([
		Vector2(-ROAD_HALF_WIDTH - 2.5, -0.6), Vector2(-ROAD_HALF_WIDTH, ROAD_HEIGHT),
		Vector2(ROAD_HALF_WIDTH, ROAD_HEIGHT), Vector2(ROAD_HALF_WIDTH + 2.5, -0.6),
	]), asphalt)
	road.use_collision = true

	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.92, 0.92, 0.9)
	paint.roughness = 0.6
	for side in [-1.0, 1.0]:
		var inner: float = side * (ROAD_HALF_WIDTH - 0.6)
		var outer: float = side * (ROAD_HALF_WIDTH - 0.35)
		var a := minf(inner, outer)
		var b := maxf(inner, outer)
		_add_track_strip(PackedVector2Array([
			Vector2(a, ROAD_HEIGHT), Vector2(a, ROAD_HEIGHT + 0.012),
			Vector2(b, ROAD_HEIGHT + 0.012), Vector2(b, ROAD_HEIGHT),
		]), paint)


func _add_track_strip(polygon: PackedVector2Array, material: Material) -> CSGPolygon3D:
	var strip := CSGPolygon3D.new()
	strip.polygon = polygon
	strip.mode = CSGPolygon3D.MODE_PATH
	strip.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	strip.path_interval = 2.0
	strip.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	strip.smooth_faces = true
	strip.material = material
	add_child(strip)
	strip.path_node = strip.get_path_to(track_path)
	return strip


func _build_start_line() -> void:
	var line_xform := _track_transform(0.0, ROAD_HEIGHT + 0.015)
	var checker := ShaderMaterial.new()
	checker.shader = Shader.new()
	checker.shader.code = CHECKER_SHADER
	var plane := PlaneMesh.new()
	plane.size = Vector2(ROAD_HALF_WIDTH * 2.0, 1.6)
	plane.material = checker
	var line := MeshInstance3D.new()
	line.mesh = plane
	line.transform = line_xform
	add_child(line)

	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.25, 0.26, 0.28)
	metal.metallic = 0.8
	metal.roughness = 0.4
	var banner := StandardMaterial3D.new()
	banner.albedo_color = Color(0.85, 0.1, 0.08)
	banner.roughness = 0.5
	for side in [-1.0, 1.0]:
		_add_prop(Vector3(0.4, 7.0, 0.4), line_xform * Vector3(side * (ROAD_HALF_WIDTH + 2.0), 3.5, 0.0), line_xform.basis, metal)
	_add_prop(Vector3(ROAD_HALF_WIDTH * 2.0 + 4.4, 1.4, 0.3), line_xform * Vector3(0.0, 6.6, 0.0), line_xform.basis, banner)


func _build_road_details() -> void:
	var corners := _find_corners()
	_corners = corners
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.92, 0.92, 0.9)
	paint.roughness = 0.6

	var dashes := SurfaceTool.new()
	dashes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var offset := 0.0
	while offset + DASH_LENGTH < track_length:
		_add_strip(dashes, offset, offset + DASH_LENGTH, -0.08, 0.08, ROAD_HEIGHT + 0.012, ROAD_HEIGHT + 0.012, Color.WHITE)
		offset += DASH_LENGTH + DASH_GAP
	_add_mesh(dashes, paint)

	# Red and white kerbs on both edges through every corner. They drape from the
	# road edge over the shoulder, so the car just rolls across them.
	var kerb_material := StandardMaterial3D.new()
	kerb_material.vertex_color_use_as_albedo = true
	kerb_material.roughness = 0.55
	var kerbs := SurfaceTool.new()
	kerbs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for corner in corners:
		var stripe := 0
		var o := corner.x
		while o < corner.y:
			var color := Color(0.62, 0.02, 0.02) if stripe % 2 == 0 else Color(0.92, 0.92, 0.9)
			for side in [-1.0, 1.0]:
				_add_strip(kerbs, o, o + KERB_SEGMENT, side * (ROAD_HALF_WIDTH - 0.3), side * (ROAD_HALF_WIDTH + 1.2), ROAD_HEIGHT + 0.03, 0.03, color)
			o += KERB_SEGMENT
			stripe += 1
	_add_mesh(kerbs, kerb_material)

	_build_guardrails(corners)


## Returns corners as Vector3(start offset, end offset, turn direction: +1 left, -1 right).
func _find_corners() -> Array[Vector3]:
	var corners: Array[Vector3] = []
	var step := 2.0
	var current := Vector3(-1.0, -1.0, 0.0)
	for i in int(track_length / step):
		var o := i * step
		var turn := _track_dir(o - 8.0).signed_angle_to(_track_dir(o + 8.0), Vector3.UP)
		if absf(turn) < CORNER_TURN:
			continue
		var dir := signf(turn)
		if current.z == dir and o - current.y < 20.0:
			current.y = o
		else:
			if current.z != 0.0:
				corners.append(current)
			current = Vector3(o, o, dir)
	if current.z != 0.0:
		corners.append(current)
	# Pad each corner so kerbs and rails start before the turn-in and run past the exit.
	for i in corners.size():
		corners[i].x = maxf(corners[i].x - 12.0, 0.0)
		corners[i].y = minf(corners[i].y + 12.0, track_length)
	return corners


func _is_in_corner(offset: float) -> bool:
	for c in _corners:
		if offset >= c.x and offset <= c.y:
			return true
	return false


func _on_car_collision_impact(impact: float) -> void:
	camera_shake = clampf(impact / 12.0, 0.12, 0.5)


func _build_guardrails(corners: Array[Vector3]) -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.62, 0.64, 0.66)
	steel.metallic = 0.85
	steel.roughness = 0.35
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rails := SurfaceTool.new()
	rails.begin(Mesh.PRIMITIVE_TRIANGLES)
	var posts: Array[Transform3D] = []
	for corner in corners:
		# The rail goes on the outside of the turn, where a car that runs wide ends up.
		var lateral := -corner.z * GUARDRAIL_OFFSET
		var o := corner.x
		while o < corner.y:
			var next := minf(o + 2.0, corner.y)
			var p0 := _track_transform(o, 0.0)
			var a := p0.origin + p0.basis.x * lateral
			# Skip stretches that would cut across another part of the track.
			if _distance_to_track(a.x, a.z) > GUARDRAIL_OFFSET - 1.0:
				_add_strip(rails, o, next, lateral, lateral, 0.85, 0.85, Color.WHITE, 0.4)
				if fmod(o, 4.0) < 2.0:
					posts.append(Transform3D(p0.basis, a + p0.basis.x * signf(lateral) * 0.15 + Vector3.UP * 0.45))
			o = next
	var rail_mesh := _add_mesh(rails, steel)

	var body := StaticBody3D.new()
	body.name = "Guardrail"
	var shape := CollisionShape3D.new()
	var trimesh := rail_mesh.create_trimesh_shape() as ConcavePolygonShape3D
	trimesh.backface_collision = true
	shape.shape = trimesh
	body.add_child(shape)
	add_child(body)

	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.12, 0.9, 0.12)
	post_mesh.material = steel
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = post_mesh
	multimesh.instance_count = posts.size()
	for i in posts.size():
		multimesh.set_instance_transform(i, posts[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	add_child(instance)


## Adds a ribbon that follows the track between two offsets. With drop > 0 it is a
## vertical wall from height_a down by drop at lateral a (b is ignored); otherwise a
## surface from lateral a at height_a to lateral b at height_b.
func _add_strip(st: SurfaceTool, from: float, to: float, a: float, b: float, height_a: float, height_b: float, color: Color, drop := 0.0) -> void:
	var o := from
	while o < to - 0.01:
		var next := minf(o + 2.0, to)
		var t0 := _track_transform(o, 0.0)
		var t1 := _track_transform(next, 0.0)
		var quad: Array[Vector3]
		if drop > 0.0:
			quad = [t0.origin + t0.basis.x * a + Vector3.UP * (height_a - drop), t1.origin + t1.basis.x * a + Vector3.UP * (height_a - drop),
				t1.origin + t1.basis.x * a + Vector3.UP * height_a, t0.origin + t0.basis.x * a + Vector3.UP * height_a]
		else:
			quad = [t0.origin + t0.basis.x * a + Vector3.UP * height_a, t1.origin + t1.basis.x * a + Vector3.UP * height_a,
				t1.origin + t1.basis.x * b + Vector3.UP * height_b, t0.origin + t0.basis.x * b + Vector3.UP * height_b]
		var normal := (quad[1] - quad[0]).cross(quad[3] - quad[0]).normalized()
		var order := [0, 1, 2, 0, 2, 3]
		# Godot treats clockwise triangles as front faces, so make surfaces wind clockwise seen from above.
		if drop == 0.0:
			if normal.y > 0.0:
				order = [0, 2, 1, 0, 3, 2]
			else:
				normal = -normal
		for idx in order:
			st.set_color(color)
			st.set_normal(normal)
			st.add_vertex(quad[idx])
		o = next


func _add_mesh(st: SurfaceTool, material: Material) -> ArrayMesh:
	st.set_material(material)
	var mesh := st.commit()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	add_child(instance)
	return mesh


func _add_prop(size: Vector3, pos: Vector3, rot: Basis, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.transform = Transform3D(rot, pos)
	add_child(instance)
	var body := StaticBody3D.new()
	body.name = "Prop"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.transform = instance.transform
	add_child(body)


func _build_checkpoints() -> void:
	for i in CHECKPOINT_COUNT:
		var area := Area3D.new()
		area.monitorable = false
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(ROAD_HALF_WIDTH * 2.0 + 16.0, 10.0, 3.0)
		shape.shape = box
		area.add_child(shape)
		area.transform = _track_transform(track_length * i / CHECKPOINT_COUNT, 3.0)
		area.body_entered.connect(_on_checkpoint_entered.bind(i))
		add_child(area)


func _build_trees() -> void:
	var quad := QuadMesh.new()
	quad.size = TREE_QUAD_SIZE
	var shader := Shader.new()
	shader.code = TREE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("albedo_atlas", load("res://textures/trees/fir_impostor_albedo.png"))
	material.set_shader_parameter("normal_atlas", load("res://textures/trees/fir_impostor_normal.png"))
	material.set_shader_parameter("quad_size", TREE_QUAD_SIZE)
	quad.material = material

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var variants: Array[float] = []
	var attempts := 0
	while transforms.size() < TREE_COUNT and attempts < TREE_COUNT * 20:
		attempts += 1
		var x := rng.randf_range(-650.0, 650.0)
		var z := rng.randf_range(-650.0, 650.0)
		var d := _distance_to_track(x, z)
		if d < ROAD_HALF_WIDTH + 9.0:
			continue
		# Group trees into groves, denser close to the road for a sense of speed.
		var grove := smoothstep(-0.15, 0.25, noise.get_noise_2d(x * 3.0 + 1000.0, z * 3.0))
		if rng.randf() > clampf(1.4 - d / 300.0, 0.15, 1.0) * (0.08 + 0.92 * grove):
			continue
		var y := _terrain_height(x, z)
		if y > 90.0:
			continue
		var s := rng.randf_range(0.7, 1.15)
		var base := Vector3(x, y - 0.3, z)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), base))
		colors.append(Color(1.0, 1.0, 1.0).lerp(Color(0.8, 0.9, 0.75), rng.randf()))
		variants.append(float(rng.randi_range(0, TREE_VARIANTS - 1)))
		if d < 70.0:
			var body := StaticBody3D.new()
			body.name = "Tree"
			var shape := CollisionShape3D.new()
			var cylinder := CylinderShape3D.new()
			cylinder.radius = 0.35 * s
			cylinder.height = 6.0 * s
			shape.shape = cylinder
			body.add_child(shape)
			body.position = base + Vector3.UP * 3.0 * s
			add_child(body)

	# Split the forest into patches with their own bounds, so the camera and each shadow
	# cascade only draw the trees near them.
	var patches := {}
	for i in transforms.size():
		var origin := transforms[i].origin
		var key := Vector2i(floori(origin.x / TREE_PATCH_SIZE), floori(origin.z / TREE_PATCH_SIZE))
		if not patches.has(key):
			patches[key] = []
		patches[key].append(i)
	for key: Vector2i in patches:
		var members: Array = patches[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.use_custom_data = true
		multimesh.mesh = quad
		multimesh.instance_count = members.size()
		var low := Vector3(INF, INF, INF)
		var high := -low
		for n in members.size():
			var i: int = members[n]
			multimesh.set_instance_transform(n, transforms[i])
			multimesh.set_instance_color(n, colors[i])
			multimesh.set_instance_custom_data(n, Color(variants[i], 0.0, 0.0, 0.0))
			low = low.min(transforms[i].origin)
			high = high.max(transforms[i].origin)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		# The cards turn to face the camera in the shader, so pad the bounds by a tree's size.
		var pad := Vector3(TREE_QUAD_SIZE.x, 0.0, TREE_QUAD_SIZE.x)
		instance.custom_aabb = AABB(low - pad, high - low + pad * 2.0 + Vector3.UP * TREE_QUAD_SIZE.y * 1.2)
		add_child(instance)
		tree_instances.append(instance)


func _build_grass() -> void:
	var material := ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = GRASS_SHADER
	var tuft := _make_tuft_mesh(material)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var chunk_count := ceili(track_length / GRASS_CHUNK_LENGTH)
	for chunk in chunk_count:
		var transforms: Array[Transform3D] = []
		var start := chunk * GRASS_CHUNK_LENGTH
		for i in int(GRASS_CHUNK_LENGTH * GRASS_PER_METRE):
			var offset := start + rng.randf() * GRASS_CHUNK_LENGTH
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			# Thicker right at the verge, thinning out into the meadow.
			var lateral := lerpf(GRASS_BAND.x, GRASS_BAND.y, pow(rng.randf(), 1.6)) * side
			var xform := _track_transform(offset, 0.0)
			var pos := xform.origin + xform.basis.x * lateral
			# Skip spots that land on another part of the track where it loops back.
			if _distance_to_track(pos.x, pos.z) < GRASS_BAND.x:
				continue
			pos.y = _terrain_height(pos.x, pos.z)
			var s := rng.randf_range(0.7, 1.4)
			transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s)), pos))
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = tuft
		multimesh.instance_count = transforms.size()
		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end = 90.0
		add_child(instance)
		grass_instances.append(instance)


## Three vertical cards crossed at 60 degrees, 0.9 m wide and 0.45 m tall.
func _make_tuft_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var dir := Vector3(cos(k * PI / 3.0), 0.0, sin(k * PI / 3.0)) * 0.45
		var corners := [-dir, dir, dir + Vector3.UP * 0.45, -dir + Vector3.UP * 0.45]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_uv(uvs[idx])
			st.set_normal(Vector3.UP)
			st.add_vertex(corners[idx])
	st.set_material(material)
	return st.commit()


func _build_rocks() -> void:
	var meshes: Array[Mesh] = []
	for path: String in ROCK_MODELS:
		var scene := (load(path) as PackedScene).instantiate()
		for mi in scene.find_children("*", "MeshInstance3D", true, false):
			meshes.append((mi as MeshInstance3D).mesh)
		scene.free()
	var boulder: Mesh = meshes.pop_back()
	var collision_points := {}

	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var placed := 0
	var attempts := 0
	while placed < ROCK_COUNT + BOULDER_COUNT and attempts < 20000:
		attempts += 1
		var is_boulder := placed >= ROCK_COUNT
		var mesh: Mesh = boulder if is_boulder else meshes[rng.randi() % meshes.size()]
		var s := rng.randf_range(2.0, 4.0) if is_boulder else rng.randf_range(0.4, 1.6)
		var x := rng.randf_range(-600.0, 600.0)
		var z := rng.randf_range(-600.0, 600.0)
		var d := _distance_to_track(x, z)
		var clearance := ROAD_HALF_WIDTH + 4.0 + 1.5 * s
		if d < clearance or rng.randf() > clampf(1.3 - d / 150.0, 0.05, 1.0):
			continue
		var y := _terrain_height(x, z)
		if y > 110.0:
			continue
		var tilt := Basis(Vector3(rng.randf() - 0.5, 0.0, rng.randf() - 0.5).normalized(), rng.randf() * 0.25)
		var xform := Transform3D(tilt * Basis(Vector3.UP, rng.randf() * TAU), Vector3(x, y - 0.25 * s, z))
		var rock := MeshInstance3D.new()
		rock.mesh = mesh
		rock.transform = xform.scaled_local(Vector3.ONE * s)
		rock.visibility_range_end = 300.0
		add_child(rock)
		placed += 1
		if d < clearance + 25.0:
			if not collision_points.has(mesh):
				collision_points[mesh] = (mesh.create_convex_shape(true, true) as ConvexPolygonShape3D).points
			var shape := ConvexPolygonShape3D.new()
			var points: PackedVector3Array = collision_points[mesh]
			var scaled := PackedVector3Array()
			for point in points:
				scaled.append(point * s)
			shape.points = scaled
			var body := StaticBody3D.new()
			body.name = "Rock"
			var collider := CollisionShape3D.new()
			collider.shape = shape
			body.add_child(collider)
			body.transform = xform
			add_child(body)


func _spawn_car() -> void:
	for i in GRID.size():
		var slot: Vector2 = GRID[i]
		var is_player := i == GRID.size() - 1
		var racer := CarScript.new()
		racer.is_player = is_player
		racer.frozen = true
		var spot := _track_transform(-slot.x, 0.8)
		racer.transform = spot.translated(spot.basis.x * slot.y)
		if is_player:
			racer.name = "Car"
			racer.paint_color = PLAYER_PAINT
			racer.rim_color = Color(0.03, 0.03, 0.035)
			racer.rear_wing = true
			racer.body_style = "custom"
			car = racer
			racer.collision_impact.connect(_on_car_collision_impact)
		else:
			var opponent: Dictionary = OPPONENTS[i]
			racer.name = "AI " + opponent.name
			racer.paint_color = opponent.color
		add_child(racer)
		if TIMES_OF_DAY[current_time_of_day_index].name == "Night":
			racer.set_headlights(true)
		if not is_player:
			var driver := AIDriverScript.new()
			racer.add_child(driver)
			driver.setup(racer, self, OPPONENTS[i].skill, slot.y)
			ai_drivers.append(driver)
		cars.append(racer)
		progress[racer] = -slot.x
		_last_offset[racer] = fposmod(-slot.x, track_length)


# --- Camera --------------------------------------------------------------

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.far = 3000.0
	add_child(camera)
	camera.global_position = car.global_position - car.global_basis.z * 7.0 + Vector3.UP * 2.5
	camera.make_current()


func _update_camera(delta: float) -> void:
	var looking_back := Input.is_action_pressed("look_back")
	var behind := Basis.IDENTITY if looking_back else Basis(Vector3.UP, PI)
	match CAMERA_VIEWS[camera_view].mode:
		"bumper":
			var z := -2.75 if looking_back else 2.6
			camera.global_transform = car.global_transform * Transform3D(behind, Vector3(0.0, 0.75, z))
			camera.fov = 78.0
			_apply_camera_shake(delta)
			return
		"cockpit":
			camera.global_transform = car.global_transform * Transform3D(behind, car.cockpit_offset())
			camera.fov = 75.0
			_apply_camera_shake(delta)
			return

	var view: Dictionary = CAMERA_VIEWS[camera_view]
	var speed := car.linear_velocity.length()
	var forward := car.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.1 else Vector3.FORWARD
	# In a slide, swing partly towards where the car is actually going.
	var travel := car.linear_velocity
	travel.y = 0.0
	if speed > 5.0 and travel.normalized().dot(forward) > 0.0:
		forward = forward.slerp(travel.normalized(), 0.45)
	if looking_back:
		forward = -forward
	var pivot := car.global_position + Vector3.UP * 1.2
	var target: Vector3 = car.global_position - forward * (view.distance + speed * 0.03) + Vector3.UP * view.height
	# Keep the camera out of hills, rails and trees: stop short of anything between it and the car.
	var query := PhysicsRayQueryParameters3D.create(pivot, target)
	query.exclude = [car.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		target = hit.position + (pivot - target).normalized() * 0.4
	camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-delta * (20.0 if hit or looking_back else 7.0)))
	camera.look_at(car.global_position + forward * 4.0 + Vector3.UP * 0.9, Vector3.UP)
	camera.fov = lerpf(camera.fov, 70.0 + clampf(speed * 0.35, 0.0, 16.0), 1.0 - exp(-delta * 3.0))
	_apply_camera_shake(delta)


func _apply_camera_shake(delta: float) -> void:
	if camera_shake > 0.001:
		camera.global_position += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * camera_shake
		camera_shake = move_toward(camera_shake, 0.0, delta * 3.5)


## Runs the countdown, tracks how far each car has driven, and works out positions and finishers.
func _update_race(delta: float) -> void:
	if countdown > 0.0:
		var before := ceili(countdown)
		countdown -= delta
		if countdown <= 0.0:
			for racer in cars:
				racer.frozen = false
			_show_message("GO!", 1.5)
		elif ceili(countdown) != before:
			_show_message(str(ceili(countdown)), 1.4)
		return
	race_time += delta

	for racer in cars:
		var offset := curve.get_closest_offset(racer.global_position)
		var step: float = offset - _last_offset[racer]
		# Crossing the start line wraps the offset back to zero.
		if step > track_length * 0.5:
			step -= track_length
		elif step < -track_length * 0.5:
			step += track_length
		# A car that arrives somewhere else instantly (a reset, or cutting across the infield)
		# has not driven that distance, so don't credit it.
		var reach := racer.linear_velocity.length() * delta + 2.0
		if absf(step) > reach * 2.0 + 4.0:
			step = 0.0
		progress[racer] += step
		_last_offset[racer] = offset
		# Only laps confirmed by the checkpoints count for the player.
		var finished: bool = progress[racer] >= RACE_LAPS * track_length
		if racer == car:
			finished = laps_done >= RACE_LAPS
		if finished and racer not in finish_order:
			finish_order.append(racer)
			if racer == car:
				player_finish_time = race_time
				lap_running = false
				_show_message("Finished P%d!   Race time %s" % [finish_order.size(), _format_time(race_time)], 8.0)

	var order := cars.duplicate()
	order.sort_custom(func(a, b): return _race_rank(a) > _race_rank(b))
	player_position = order.find(car) + 1


## Finished cars rank by finishing order; everyone else by distance driven.
func _race_rank(racer: VehicleBody3D) -> float:
	var finished := finish_order.find(racer)
	if finished >= 0:
		return 1.0e9 - finished
	return progress[racer]


func _reset_car() -> void:
	flipped_time = 0.0
	var offset := curve.get_closest_offset(car.global_position)
	(car as CarScript).reset_to(_track_transform(offset, 0.8))


# --- Laps ----------------------------------------------------------------

func _on_checkpoint_entered(body: Node3D, index: int) -> void:
	if body != car or car in finish_order:
		return
	if index != next_checkpoint:
		# Passing a checkpoint without taking it would stall the lap, so say why.
		if index == (next_checkpoint + 1) % CHECKPOINT_COUNT:
			_show_message("Missed a checkpoint - turn back", 2.0)
		return
	next_checkpoint = (index + 1) % CHECKPOINT_COUNT
	if index != 0:
		return
	if lap_running:
		last_lap = lap_time
		laps_done += 1
		if lap_time < best_lap:
			best_lap = lap_time
			_show_message("New best lap!  " + _format_time(lap_time), 3.0)
		else:
			_show_message("Lap  " + _format_time(lap_time), 3.0)
	else:
		_show_message("Go!", 1.5)
	lap_running = true
	lap_time = 0.0


func _format_time(seconds: float) -> String:
	if seconds == INF:
		return "--:--.--"
	return "%d:%05.2f" % [int(seconds / 60.0), fmod(seconds, 60.0)]


# --- HUD -----------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_layer = layer

	# Gently darken the screen edges, like a camera lens.
	var falloff := GradientTexture2D.new()
	falloff.fill = GradientTexture2D.FILL_RADIAL
	falloff.fill_from = Vector2(0.5, 0.5)
	falloff.fill_to = Vector2(1.15, 0.5)
	falloff.gradient = Gradient.new()
	falloff.gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	falloff.gradient.add_point(0.45, Color(0.0, 0.0, 0.0, 0.0))
	falloff.gradient.set_color(falloff.gradient.get_point_count() - 1, Color(0.0, 0.0, 0.0, 0.5))
	var vignette := TextureRect.new()
	vignette.texture = falloff
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = -1
	vignette_layer.add_child(vignette)
	add_child(vignette_layer)

	var timing := VBoxContainer.new()
	timing.position = Vector2(28.0, 20.0)
	layer.add_child(timing)
	lap_label = _make_label(timing, 34)
	position_label = _make_label(timing, 26)
	fps_label = _make_label(timing, 18)
	fps_label.visible = false
	time_label = _make_label(timing, 26)
	last_label = _make_label(timing, 20)
	best_label = _make_label(timing, 20)

	var gauges := VBoxContainer.new()
	gauges.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	gauges.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	gauges.grow_vertical = Control.GROW_DIRECTION_BEGIN
	gauges.offset_right = -32.0
	gauges.offset_bottom = -24.0
	gauges.alignment = BoxContainer.ALIGNMENT_END
	layer.add_child(gauges)

	shift_light_bar = HBoxContainer.new()
	shift_light_bar.alignment = BoxContainer.ALIGNMENT_END
	shift_light_bar.add_theme_constant_override("separation", 4)
	gauges.add_child(shift_light_bar)
	shift_lights.clear()
	for i in 9:
		var led := ColorRect.new()
		led.custom_minimum_size = Vector2(16.0, 7.0)
		led.color = Color(0.12, 0.14, 0.16, 0.5)
		shift_light_bar.add_child(led)
		shift_lights.append(led)

	speed_label = _make_label(gauges, 64)
	gear_label = _make_label(gauges, 22)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	message_label = _make_label(layer, 40)
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	message_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_label.offset_top = 90.0
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var help := _make_label(layer, 15)
	help.text = "W/S or arrows: drive and brake    A/D: steer    Space: handbrake    R: reset    C: camera    B: look back    H: headlights    V: photo mode    F: fps    Esc: menu"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help.offset_left = 28.0
	help.offset_bottom = -20.0
	help.modulate.a = 0.8

	var minimap := MinimapScript.new() as Control
	layer.add_child(minimap)
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -254.0
	minimap.offset_right = -24.0
	minimap.offset_top = 20.0
	minimap.offset_bottom = 250.0
	minimap.setup(curve.get_baked_points(), car, Vector2(230.0, 230.0))
	minimap.others = cars.filter(func(c): return c != car)


func _make_label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", maxi(4, font_size / 6))
	parent.add_child(label)
	return label


func _show_message(text: String, duration: float) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	message_timer = duration
