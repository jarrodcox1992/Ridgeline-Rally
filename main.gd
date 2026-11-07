extends Node3D
## Builds the whole game at startup: landscape, race track, scenery, car,
## camera, HUD and lap timing. Everything is procedural, so no asset files.

const CarScript := preload("res://car.gd")
const MinimapScript := preload("res://minimap.gd")
const PauseMenuScript := preload("res://pause_menu.gd")
const AIDriverScript := preload("res://ai_driver.gd")
const PhotoModeScript := preload("res://photo_mode.gd")
const CityBuilderScript := preload("res://city_builder.gd")
const RoadRepairControllerScript := preload("res://road_repair_controller.gd")

## Multi-Track Cyberpunk Metropolis & High-Speed Expressway Circuits
## The single city map. All roads are built into this one world; there is no track switching.
const CITY_TRACKS: Array[Dictionary] = [
	{
		"name": "Neo-Veridia",
		"desc": "One unified cyberpunk metropolis with a main ring circuit and a network of city streets",
		"file": "res://tracks/AutobahnA95.csv",
		"span": 1760.0,
		"step": 3,
		"procedural": true,
		"smooth": 0,
		"branches": false,
		"elev_amp": 0.0,
		"elev_type": "flat",
		"district": "NEO-VERIDIA // CITY",
		"road_title": "VERIDIA RING ROAD",
		"speed_limit": "UNLIMITED",
	},
]

## Active runtime track dataset populated from open-source datasets + classic circuits
var TRACK_DATA: Array[Dictionary] = []
const ROAD_HALF_WIDTH := 11.5 # 23m wide 4-lane highway with emergency breakdown shoulders
const ROAD_HEIGHT := 0.22
const TERRAIN_SIZE := 3800.0
const TERRAIN_RES := 150
const CHECKPOINT_COUNT := 10
const TREE_COUNT := 1100
const TREE_VARIANTS := 3
const TREE_PATCH_SIZE := 200.0
## Tree patches further than this from the camera don't cast shadows. Trees' shadows are
## costly to draw when the sun is low, and far-off ones can't be seen through the haze.
const TREE_SHADOW_RANGE := 260.0
const GRASS_PER_METRE := 16
const GRASS_BAND := Vector2(18.5, 52.0) # distance from the highway centreline (well clear of road)
const GRASS_CHUNK_LENGTH := 60.0
const ROCK_MODELS := ["res://models/rock_moss_set_01/rock_moss_set_01.gltf", "res://models/boulder_01/boulder_01.gltf"]
const DASH_LENGTH := 4.5
const DASH_GAP := 7.5
const CORNER_TURN := 0.08 # radians of heading change over 16 m that counts as a corner
const GUARDRAIL_OFFSET := 12.8
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
## Each opponent has a distinct personality. `persona` drives the AI's behaviour:
## aggression (0 = lets you pass, 1 = defends hard), braking (m/s^2 it dares to use),
## grip (cornering margin), wobble (how much its pace drifts), and a taunt shown to the
## player when they overtake it.
const OPPONENTS := [
	{
		"name": "Blaze", "color": Color(0.04, 0.16, 0.55), "skill": 1.0,
		"persona": {
			"title": "The Enforcer",
			"aggression": 0.95, "braking": 8.4, "grip": 9.2, "wobble": 0.015,
			"taunt": "Blaze: Not today. That line's mine.",
		},
	},
	{
		"name": "Pearl", "color": Color(0.85, 0.85, 0.82), "skill": 0.96,
		"persona": {
			"title": "The Technician",
			"aggression": 0.15, "braking": 7.4, "grip": 9.5, "wobble": 0.0,
			"taunt": "Pearl: Clean move. Nice line through the apex.",
		},
	},
	{
		"name": "Red", "color": Color(0.62, 0.04, 0.03), "skill": 0.92,
		"persona": {
			"title": "The Wildcard",
			"aggression": 0.7, "braking": 9.0, "grip": 8.5, "wobble": 0.05,
			"taunt": "Red: Brakes are for people who slow down!",
		},
	},
]
## Start grid slots across highway lanes: distance back and offset to driver's left.
## Staggered across lanes: Lane 1 (-4.6m), Lane 4 (+4.6m), Lane 2 (-1.5m), Lane 1 (-4.6m)
const GRID := [Vector2(14.0, -4.6), Vector2(26.0, 4.6), Vector2(38.0, 1.5), Vector2(50.0, -4.6)]
## Times of day. Each sky is a Poly Haven HDRI; "sun" points towards the sun in it, found by
## aiming a camera at its brightest pixel. The sunset sun is raised a little above the
## horizon (about 14 degrees) so shadows don't stretch for hundreds of metres.
const TIMES_OF_DAY := [
	{"name": "Day", "sky": "res://textures/sky/kloofendal_puresky_4k.hdr", "sun": Vector3(-0.46, 0.36, 0.80),
		"sun_color": Color(1.0, 0.86, 0.68), "sun_energy": 2.45, "sky_energy": 1.02, "exposure": 0.96,
		"fog_color": Color(0.94, 0.84, 0.70), "fog_density": 0.00075, "contrast": 1.14, "saturation": 1.16,
		"shadow_scale": 0.95},
	{"name": "Sunset", "sky": "res://textures/sky/belfast_sunset_puresky_4k.hdr", "sun": Vector3(-0.54, 0.25, 0.84),
		"sun_color": Color(1.0, 0.58, 0.30), "sun_energy": 2.35, "sky_energy": 1.04, "exposure": 0.78,
		"fog_color": Color(0.82, 0.58, 0.44), "fog_density": 0.00085, "contrast": 1.18, "saturation": 1.20,
		"shadow_scale": 0.75},
	{"name": "Night", "sky": "res://textures/sky/qwantani_night_puresky_2k.hdr", "sun": Vector3(-0.3, 0.7, 0.4),
		"sun_color": Color(0.32, 0.46, 0.78), "sun_energy": 0.18, "sky_energy": 0.22, "exposure": 0.96,
		"fog_color": Color(0.03, 0.06, 0.12), "fog_density": 0.00065, "contrast": 1.18, "saturation": 1.18,
		"shadow_scale": 0.6},
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
var alternate_curves: Array[Curve3D] = []
var branch_junctions: Array[Dictionary] = []
var road_repair_zones: Array[RoadRepairController] = []
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
var current_track_index := 0
var _track_root: Node3D
var minimap_ctrl: Control
var _track_bounds_min := Vector2(-400.0, -400.0)
var _track_bounds_max := Vector2(400.0, 400.0)
var current_quality_level := 1

# Dynamic Cockpit & Camera G-Force Inertia Rig
var _head_inertia_pos := Vector3.ZERO
var _head_inertia_rot := Vector3.ZERO

# Sector Split Delta-Time Tracking
var current_split_times: Array[float] = [0.0, 0.0, 0.0, 0.0]
var best_split_times: Array[float] = [0.0, 0.0, 0.0, 0.0]
var sector_delta_label: Label
var sector_delta_timer: float = 0.0
var sector_delta_text: String = ""
var sector_delta_color: Color = Color.WHITE

# Cockpit & HUD G-Force Telemetry & Driver Assists
var g_meter_ctrl: Control
var abs_indicator: Label
var tcs_indicator: Label
var g_force_val_label: Label


class GMeterWidget extends Control:
	var car: Node3D

	func _init() -> void:
		custom_minimum_size = Vector2(84.0, 84.0)

	func _draw() -> void:
		var center := Vector2(42.0, 42.0)
		draw_circle(center, 40.0, Color(0.04, 0.06, 0.09, 0.75))
		draw_arc(center, 24.0, 0, TAU, 32, Color(0.35, 0.55, 0.75, 0.35), 1.2)
		draw_arc(center, 36.0, 0, TAU, 32, Color(0.25, 0.4, 0.55, 0.22), 1.0)
		draw_line(Vector2(6.0, 42.0), Vector2(78.0, 42.0), Color(0.4, 0.55, 0.7, 0.25), 1.0)
		draw_line(Vector2(42.0, 6.0), Vector2(42.0, 78.0), Color(0.4, 0.55, 0.7, 0.25), 1.0)
		var g_lat: float = car.get("g_force_lateral") if (car and "g_force_lateral" in car) else 0.0
		var g_lon: float = car.get("g_force_longitudinal") if (car and "g_force_longitudinal" in car) else 0.0
		var total_g := sqrt(g_lat * g_lat + g_lon * g_lon)
		var puck_pos := center + Vector2(clampf(g_lat * 24.0, -36.0, 36.0), clampf(-g_lon * 24.0, -36.0, 36.0))
		var dot_col := Color(0.2, 0.95, 0.4)
		if total_g > 1.25:
			dot_col = Color(1.0, 0.2, 0.15)
		elif total_g > 0.85:
			dot_col = Color(1.0, 0.75, 0.1)
		draw_line(center, puck_pos, Color(dot_col.r, dot_col.g, dot_col.b, 0.45), 1.5)
		draw_circle(puck_pos, 4.0, dot_col)


func _init() -> void:
	_init_tracks()


func _init_tracks() -> void:
	TRACK_DATA.clear()
	for circuit in CITY_TRACKS:
		# Hidden circuits are kept in the data but not offered in the track list (see ROADMAP known issues).
		if circuit.get("hidden", false):
			continue
		var pts := _load_osm_track(circuit.file, circuit)
		TRACK_DATA.append({
			"name": circuit.name,
			"desc": circuit.desc,
			"points": pts,
			"district": circuit.get("district", "METROPOLIS"),
			"road_title": circuit.get("road_title", circuit.name),
			"speed_limit": circuit.get("speed_limit", "45 MPH"),
			"branches": circuit.get("branches", true),
		})


func _load_osm_track(path: String, cfg: Dictionary) -> Array[Vector3]:
	var pts: Array[Vector2] = []
	if cfg.get("procedural", false):
		# Smooth generated loop: gentle, continuous curvature with no sharp corners.
		for k in 360:
			var t := TAU * float(k) / 360.0
			var r := 1.0 + 0.18 * sin(2.0 * t) + 0.08 * cos(3.0 * t)
			pts.append(Vector2(cos(t) * r * 1.6, sin(t) * r))
	else:
		var file := FileAccess.open(path, FileAccess.READ)
		if not file:
			push_error("Failed to open open-source track file: " + path)
			return []
		while not file.eof_reached():
			var line := file.get_line().strip_edges()
			if line.is_empty() or line.begins_with("#"):
				continue
			var parts := line.split(",")
			if parts.size() >= 2:
				pts.append(Vector2(parts[0].to_float(), parts[1].to_float()))

	if pts.is_empty():
		return []

	# Chaikin corner cutting: each pass replaces every corner with two points at 1/4 and 3/4 along its edges,
	# giving smooth, drivable turns while keeping the overall shape of the surveyed road.
	for _it in int(cfg.get("smooth", 0)):
		var smoothed: Array[Vector2] = []
		var m := pts.size()
		for i in m:
			var a := pts[i]
			var b := pts[(i + 1) % m]
			smoothed.append(a.lerp(b, 0.25))
			smoothed.append(a.lerp(b, 0.75))
		pts = smoothed

	var step: int = int(cfg.get("step", 3))
	var min_p := Vector2(1e9, 1e9)
	var max_p := Vector2(-1e9, -1e9)
	for p in pts:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
	var center := (min_p + max_p) * 0.5
	var span := maxf(max_p.x - min_p.x, max_p.y - min_p.y)
	var target_span: float = float(cfg.get("span", 780.0))
	var scale: float = target_span / span

	var n_sub := int(pts.size() / step)
	var pts3d: Array[Vector3] = []
	var elev_amp: float = float(cfg.get("elev_amp", 0.0))
	var elev_type: String = str(cfg.get("elev_type", "flat"))
	for i in n_sub:
		var p2d := (pts[i * step] - center) * scale
		var progress := float(i) / float(n_sub)
		var y := 0.0
		match elev_type:
			"flyover":
				y = elev_amp * pow(sin(progress * PI), 2.0)
			"multi_overpass":
				# Keep start/finish straight flat (progress 0..0.08 and 0.92..1.0), with sweeping multi-level overpasses across the circuit
				var ramp_env := smoothstep(0.06, 0.14, progress) * (1.0 - smoothstep(0.86, 0.94, progress))
				y = elev_amp * pow(sin(progress * PI * 2.0), 2.0) * ramp_env
			"flat":
				y = 0.0
			_:
				y = 0.0
		pts3d.append(Vector3(p2d.x, y, p2d.y))
	return pts3d


func _ready() -> void:
	_setup_input()
	noise.seed = 7
	noise.frequency = 0.004
	noise.fractal_octaves = 5

	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	current_track_index = clampi(settings.get_value("race", "track", 0), 0, TRACK_DATA.size() - 1)

	_build_environment()
	_track_root = Node3D.new()
	_track_root.name = "TrackRoot"
	add_child(_track_root)

	_build_track_curve()
	_build_road()
	_build_alternate_routes_and_overpasses()
	_build_start_line()
	_build_road_details()
	_build_dynamic_road_repairs()
	_build_checkpoints()
	CityBuilderScript.build_city(self, _track_root)
	_spawn_car()
	_build_camera()
	_build_hud()
	var menu := PauseMenuScript.new()
	add_child(menu)
	menu.setup(self)
	var photo := PhotoModeScript.new()
	add_child(photo)
	photo.setup(self)
	_show_message(TRACK_DATA[current_track_index].name, 2.0)


func _physics_process(delta: float) -> void:
	if lap_running:
		lap_time += delta
	_update_race(delta)

	# Dynamic slipstream drafting calculation across all vehicles
	for c in cars:
		if is_instance_valid(c):
			c.update_slipstream(cars)

	if Input.is_action_just_pressed("repair_road"):
		_trigger_nearest_road_repair()
	if Input.is_action_just_pressed("reset_car"):
		_reset_car()
	if Input.is_action_just_pressed("horn"):
		_honk()
	if Input.is_action_just_pressed("show_fps"):
		fps_label.visible = not fps_label.visible
	if Input.is_action_just_pressed("quality"):
		current_quality_level = (current_quality_level + 1) % 3
		apply_quality(current_quality_level)
		_show_message("Graphics: " + ["Performance", "Balanced", "Quality"][current_quality_level], 1.2)
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
		# Remember the last place the car was genuinely on the road surface, so a reset returns it there
		# (not onto an elevated deck or box that happens to be nearest in 3D).
		if absf(car.global_position.y - t_xform.origin.y) < 0.8:
			_last_grounded_offset = offset
		var lateral_dist := absf((t_xform.affine_inverse() * car.global_position).x)
		var on_rumble: bool = lateral_dist > 9.0 and lateral_dist < 9.6
		(car as CarScript).on_curb = on_rumble
		# Hint when the car is wedged off the road (e.g. against a sidewalk prop): R resets it to the road.
		if car.linear_velocity.length() < 0.5 and lateral_dist > ROAD_HALF_WIDTH:
			_stuck_time += delta
			if _stuck_time > 3.0 and not _stuck_hinted:
				_stuck_hinted = true
				_show_message("Stuck? Press R to reset to the road", 4.0)
		else:
			_stuck_time = 0.0
			_stuck_hinted = false
		if on_rumble:
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
	if sector_delta_label:
		if sector_delta_timer > 0.0:
			sector_delta_timer -= delta
			sector_delta_label.text = "Split  " + sector_delta_text
			sector_delta_label.add_theme_color_override("font_color", sector_delta_color)
			sector_delta_label.modulate.a = clampf(sector_delta_timer, 0.0, 1.0)
			sector_delta_label.visible = true
		else:
			sector_delta_label.visible = false

	# Update Live G-Meter & Assist indicators
	if g_meter_ctrl:
		g_meter_ctrl.queue_redraw()
	if car:
		var is_abs: bool = bool(car.get("abs_active"))
		var is_tcs: bool = bool(car.get("tcs_active"))
		if abs_indicator:
			abs_indicator.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1) if is_abs else Color(0.35, 0.4, 0.45, 0.5))
		if tcs_indicator:
			tcs_indicator.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1) if is_tcs else Color(0.35, 0.4, 0.45, 0.5))
		if g_force_val_label:
			var lat_g: float = car.get("g_force_lateral") if "g_force_lateral" in car else 0.0
			var lon_g: float = car.get("g_force_longitudinal") if "g_force_longitudinal" in car else 0.0
			var tot_g := sqrt(lat_g * lat_g + lon_g * lon_g)
			g_force_val_label.text = "%.2f G" % tot_g

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
	env.fog_aerial_perspective = 0.22 if is_night else 0.32
	env.fog_sky_affect = 0.08 if is_night else 0.06
	env.fog_sun_scatter = 0.08 if is_night else 0.65
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
	current_quality_level = level
	var viewport := get_viewport()
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	viewport.scaling_3d_scale = [0.66, 0.75, 1.0][level]
	env.ssao_enabled = level >= 2
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.0
	env.ssao_light_affect = 0.20
	env.ssr_enabled = level == 2
	env.ssr_max_steps = 32
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssil_enabled = false
	env.glow_enabled = level >= 1
	_shadow_distance = [120.0, 160.0, 260.0][level]
	sun.directional_shadow_max_distance = _shadow_distance * _shadow_scale
	sun.directional_shadow_blend_splits = level >= 2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if level <= 1 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	for grass in grass_instances:
		grass.visible = level >= 1
		grass.visibility_range_end = 60.0 if level == 1 else 90.0
	_tree_shadows = level >= 1
	_update_tree_shadows()
	if is_instance_valid(_track_root):
		for n in _track_root.find_children("GridFacade*", "MultiMeshInstance3D", true, false):
			n.visible = level >= 1


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
	_add_action("horn", [KEY_G], [JOY_BUTTON_B], [])
	_add_action("look_back", [KEY_B], [JOY_BUTTON_LEFT_SHOULDER], [])
	_add_action("show_fps", [KEY_F], [], [])
	_add_action("quality", [KEY_G], [], [])
	_add_action("repair_road", [KEY_K], [JOY_BUTTON_X], [])
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
	var points: Array = TRACK_DATA[current_track_index].points
	var n := points.size()
	var min_x := 1.0e9
	var max_x := -1.0e9
	var min_z := 1.0e9
	var max_z := -1.0e9
	# Repeat the first point at the end so the loop closes smoothly in 3D.
	for i in n + 1:
		var p: Vector3 = points[i % n]
		var prev: Vector3 = points[(i - 1 + n) % n]
		var next: Vector3 = points[(i + 1) % n]
		var handle := (next - prev) * 0.22
		curve.add_point(p, -handle, handle)
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_z = minf(min_z, p.z)
		max_z = maxf(max_z, p.z)
	_track_bounds_min = Vector2(min_x, min_z)
	_track_bounds_max = Vector2(max_x, max_z)
	track_length = curve.get_baked_length()
	track_path = Path3D.new()
	track_path.name = "TrackPath"
	track_path.curve = curve
	_track_root.add_child(track_path)


func _track_point(offset: float) -> Vector3:
	return curve.sample_baked(fposmod(offset, track_length), true)


func _track_dir(offset: float) -> Vector3:
	return (_track_point(offset + 2.0) - _track_point(offset - 2.0)).normalized()


## The basis's +Z points along the track, +X to the driver's left, and +Y along the road normal.
func _track_transform(offset: float, height: float) -> Transform3D:
	var dir := _track_dir(offset)
	var b := Basis.looking_at(-dir, Vector3.UP)
	return Transform3D(b, _track_point(offset) + b.y * height)


func _track_closest_point(x: float, z: float) -> Vector3:
	var pt := curve.get_closest_point(Vector3(x, 0.0, z))
	return curve.get_closest_point(Vector3(x, pt.y, z))


func _distance_to_track(x: float, z: float) -> float:
	var closest := _track_closest_point(x, z)
	var min_d := Vector2(closest.x - x, closest.z - z).length()
	for alt_c in alternate_curves:
		var apt := alt_c.get_closest_point(Vector3(x, 0.0, z))
		var ad := Vector2(apt.x - x, apt.z - z).length()
		if ad < min_d:
			min_d = ad
	return min_d


## Returns whether the given track offset and side falls within an on-ramp, off-ramp, or merge junction zone
func is_branch_junction(track_offset: float, side: float) -> bool:
	for j in branch_junctions:
		if (j.side < 0.0 and side < 0.0) or (j.side > 0.0 and side > 0.0):
			var s: float = float(j.start)
			var e: float = float(j.end)
			if s <= e:
				if track_offset >= s and track_offset <= e:
					return true
			else:
				if track_offset >= s or track_offset <= e:
					return true
	return false


## Returns whether the 3D point is within min_dist of any alternate bypass, overpass, or tunnel route
func is_point_near_branch(pt: Vector3, min_dist: float) -> bool:
	for alt_c in alternate_curves:
		var closest: Vector3 = alt_c.get_closest_point(pt)
		if Vector2(closest.x - pt.x, closest.z - pt.z).length() < min_dist:
			return true
	return false


func _terrain_height(_x: float, _z: float) -> float:
	return 0.0


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
	env.glow_bloom = 0.12
	env.glow_intensity = 0.85
	env.glow_strength = 1.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.62, 0.75)
	env.fog_density = 0.0006
	env.fog_aerial_perspective = 0.75
	env.fog_sky_affect = 0.05
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 250.0
	add_child(sun)
	set_time_of_day(1)


func _build_terrain() -> void:
	pass


func _build_road() -> void:
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_texture = load("res://textures/asphalt_track/asphalt_track_diff_2k.jpg")
	asphalt.albedo_color = Color(0.72, 0.74, 0.78)
	asphalt.normal_enabled = true
	asphalt.normal_texture = load("res://textures/asphalt_track/asphalt_track_nor_gl_2k.jpg")
	asphalt.normal_scale = 1.35
	asphalt.roughness_texture = load("res://textures/asphalt_track/asphalt_track_rough_2k.jpg")
	asphalt.roughness = 0.28
	asphalt.metallic = 0.25
	asphalt.clearcoat_enabled = true
	asphalt.clearcoat = 0.42
	asphalt.clearcoat_roughness = 0.14
	asphalt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	asphalt.uv1_triplanar = true
	asphalt.uv1_world_triplanar = true
	asphalt.uv1_scale = Vector3.ONE * 0.5

	# 23m wide multi-lane city avenue meeting sidewalks and granite curbs flush
	var road := _add_track_strip(PackedVector2Array([
		Vector2(-ROAD_HALF_WIDTH, 0.0), Vector2(-ROAD_HALF_WIDTH, ROAD_HEIGHT),
		Vector2(ROAD_HALF_WIDTH, ROAD_HEIGHT), Vector2(ROAD_HALF_WIDTH, 0.0),
	]), asphalt)
	road.use_collision = true

	# Outer solid white shoulder lines (fog lines) at ±9.2m separating 4 travel lanes from emergency breakdown shoulders
	var white_paint := StandardMaterial3D.new()
	white_paint.albedo_color = Color(0.95, 0.95, 0.93)
	white_paint.roughness = 0.5
	for side in [-1.0, 1.0]:
		var x: float = side * 9.2
		_add_track_strip(PackedVector2Array([
			Vector2(x - 0.1, ROAD_HEIGHT), Vector2(x - 0.1, ROAD_HEIGHT + 0.012),
			Vector2(x + 0.1, ROAD_HEIGHT + 0.012), Vector2(x + 0.1, ROAD_HEIGHT),
		]), white_paint)

	# Center double solid yellow median dividing lines
	var yellow_paint := StandardMaterial3D.new()
	yellow_paint.albedo_color = Color(0.98, 0.82, 0.12) # Highway Yellow
	yellow_paint.roughness = 0.5
	for side in [-1.0, 1.0]:
		var x: float = side * 0.18
		_add_track_strip(PackedVector2Array([
			Vector2(x - 0.07, ROAD_HEIGHT), Vector2(x - 0.07, ROAD_HEIGHT + 0.012),
			Vector2(x + 0.07, ROAD_HEIGHT + 0.012), Vector2(x + 0.07, ROAD_HEIGHT),
		]), yellow_paint)

	# When the primary track has elevated overpass sections (y > 1.8m), add concrete viaduct piers & Jersey barriers
	var pier_mat := StandardMaterial3D.new()
	pier_mat.albedo_color = Color(0.58, 0.60, 0.64)
	pier_mat.roughness = 0.72
	var po := 24.0
	while po < track_length - 24.0:
		var pxform := _track_transform(po, 0.0)
		if pxform.origin.y > 1.8:
			var ph: float = pxform.origin.y
			_add_prop(Vector3(ROAD_HALF_WIDTH * 2.0 + 1.2, 0.85, 2.2), Vector3(pxform.origin.x, ph - 0.42, pxform.origin.z), pxform.basis, pier_mat)
			for pside: float in [-1.0, 1.0]:
				var col_pos: Vector3 = pxform.origin + pxform.basis.x * (pside * 7.8)
				_add_prop(Vector3(1.6, ph, 1.8), Vector3(col_pos.x, ph * 0.5, col_pos.z), pxform.basis, pier_mat)
		po += 28.0


## Builds 3 physically drivable Multi-Level Overpasses and Alternate Routing Paths on every track:
## 1. Sky-Expressway Multi-Level Overpass (inclined ramp climbing to y = 15.6m, crossing over the avenue with Jersey barriers & viaduct piers)
## 2. High-Speed Hyper-Straight Bypass (chord-straightened outer high-velocity straightaway corridor)
## 3. Inner Split-Route & Illuminated Cyber-Tunnel Gallery (covered neon tunnel chicane with overhead light ribs)
func _build_alternate_routes_and_overpasses() -> void:
	alternate_curves.clear()
	if track_length < 600.0:
		return
	if current_track_index < TRACK_DATA.size() and not TRACK_DATA[current_track_index].get("branches", true):
		return

	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_texture = load("res://textures/asphalt_track/asphalt_track_diff_2k.jpg")
	asphalt.albedo_color = Color(0.68, 0.71, 0.76)
	asphalt.normal_enabled = true
	asphalt.normal_texture = load("res://textures/asphalt_track/asphalt_track_nor_gl_2k.jpg")
	asphalt.normal_scale = 1.35
	asphalt.roughness_texture = load("res://textures/asphalt_track/asphalt_track_rough_2k.jpg")
	asphalt.roughness = 0.26
	asphalt.metallic = 0.28
	asphalt.clearcoat_enabled = true
	asphalt.clearcoat = 0.48
	asphalt.clearcoat_roughness = 0.12
	asphalt.uv1_triplanar = true
	asphalt.uv1_world_triplanar = true
	asphalt.uv1_scale = Vector3.ONE * 0.5

	var barrier_mat := StandardMaterial3D.new()
	barrier_mat.albedo_texture = load("res://textures/city_pbr/concrete_wall_006_diff.jpg")
	barrier_mat.albedo_color = Color(0.56, 0.58, 0.62)
	barrier_mat.normal_enabled = true
	barrier_mat.normal_texture = load("res://textures/city_pbr/concrete_wall_006_nor_gl.jpg")
	barrier_mat.normal_scale = 1.25
	barrier_mat.roughness = 0.68
	barrier_mat.metallic = 0.15
	barrier_mat.uv1_triplanar = true
	barrier_mat.uv1_world_triplanar = true
	barrier_mat.uv1_scale = Vector3.ONE * 0.25

	var cyan_neon := StandardMaterial3D.new()
	cyan_neon.albedo_color = Color(0.0, 0.92, 1.0)
	cyan_neon.emission_enabled = true
	cyan_neon.emission = Color(0.0, 0.92, 1.0)
	cyan_neon.emission_energy_multiplier = 2.8

	var amber_neon := StandardMaterial3D.new()
	amber_neon.albedo_color = Color(1.0, 0.72, 0.08)
	amber_neon.emission_enabled = true
	amber_neon.emission = Color(1.0, 0.72, 0.08)
	amber_neon.emission_energy_multiplier = 2.6

	var magenta_neon := StandardMaterial3D.new()
	magenta_neon.albedo_color = Color(1.0, 0.16, 0.72)
	magenta_neon.emission_enabled = true
	magenta_neon.emission = Color(1.0, 0.16, 0.72)
	magenta_neon.emission_energy_multiplier = 2.8

	# --- ROUTE 1: Multi-Level Sky-Expressway Overpass (Double-Decker Highway Viaduct climbing to y = 16.2m & sweeping across the boulevard) ---
	var over_start: float = 132.0
	var over_end: float = minf(740.0, track_length * 0.28)
	var over_curve := Curve3D.new()
	over_curve.bake_interval = 2.0
	var circuit_pts := _sample_circuit_points(4.0)
	var over_steps: int = 32
	for i in over_steps + 1:
		var t: float = float(i) / float(over_steps)
		var o: float = lerpf(over_start, over_end, t)
		var xf := _track_transform(o, 0.0)
		var elev_env: float = smoothstep(0.0, 0.20, t) * (1.0 - smoothstep(0.80, 1.0, t))
		var lat: float = 0.0
		if t < 0.22:
			# Inclined concrete viaduct on-ramp rising along the right side of the boulevard
			lat = lerpf(-5.2, -8.8, smoothstep(0.0, 0.22, t))
		elif t < 0.50:
			# Upper-deck expressway sweeping diagonally across the boulevard canyon at y = 16.2m
			lat = lerpf(-8.8, 7.2, smoothstep(0.22, 0.50, t))
		elif t < 0.78:
			# Sweeping out to the right-side elevated viaduct corridor past the harbor
			lat = lerpf(7.2, -32.0, smoothstep(0.50, 0.78, t))
		else:
			lat = lerpf(-32.0, -5.2, smoothstep(0.78, 1.0, t))
		var h: float = 16.2 * elev_env
		var pt: Vector3 = xf.origin + xf.basis.x * lat + Vector3.UP * h
		over_curve.add_point(_enforce_road_clearance(pt, circuit_pts))
	_smooth_open_curve(over_curve)
	alternate_curves.append(over_curve)
	_build_branch_highway("SkyExpresswayOverpass", over_curve, 5.4, asphalt, barrier_mat, cyan_neon, true, false)
	_build_route_portal_gantry(_track_transform(over_start + 6.0, 0.0), -5.8, "▲ SKY-EXPRESSWAY OVERPASS", cyan_neon, barrier_mat)

	# --- ROUTE 2: High-Speed Outer Straightaway Bypass (Chord-straightened top-speed corridor) ---
	var bypass_start: float = track_length * 0.35
	var bypass_end: float = track_length * 0.58
	var bypass_curve := Curve3D.new()
	bypass_curve.bake_interval = 2.0
	var p_entry := _track_transform(bypass_start, 0.0).origin
	var p_exit := _track_transform(bypass_end, 0.0).origin
	var bypass_steps: int = 24
	for i in bypass_steps + 1:
		var t: float = float(i) / float(bypass_steps)
		var o: float = lerpf(bypass_start, bypass_end, t)
		var xf := _track_transform(o, 0.0)
		var branch_env: float = smoothstep(0.0, 0.16, t) * (1.0 - smoothstep(0.84, 1.0, t))
		var curved_pt: Vector3 = xf.origin + xf.basis.x * (-36.0 * branch_env)
		var chord_pt: Vector3 = p_entry.lerp(p_exit, t) + xf.basis.x * (-36.0 * branch_env)
		var straight_blend: float = 0.68 * branch_env
		var pt: Vector3 = curved_pt.lerp(chord_pt, straight_blend)
		pt.y = maxf(0.0, pt.y)
		bypass_curve.add_point(pt)
	_smooth_open_curve(bypass_curve)
	alternate_curves.append(bypass_curve)
	_build_branch_highway("HyperStraightBypass", bypass_curve, 7.2, asphalt, barrier_mat, amber_neon, false, false)
	_build_route_portal_gantry(_track_transform(bypass_start + 10.0, 0.0), -7.5, "► HYPER-STRAIGHT BYPASS", amber_neon, barrier_mat)

	# --- ROUTE 3: Inner Split-Route & Illuminated Cyber-Tunnel Gallery ---
	var split_start: float = track_length * 0.66
	var split_end: float = track_length * 0.86
	var split_curve := Curve3D.new()
	split_curve.bake_interval = 2.0
	var split_steps: int = 24
	for i in split_steps + 1:
		var t: float = float(i) / float(split_steps)
		var o: float = lerpf(split_start, split_end, t)
		var xf := _track_transform(o, 0.0)
		var branch_env: float = smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.82, 1.0, t))
		var chicane_wave: float = sin(t * PI * 2.0) * 6.5 * branch_env
		var lat: float = (32.0 + chicane_wave) * branch_env
		var pt: Vector3 = xf.origin + xf.basis.x * lat
		pt.y = maxf(0.0, pt.y)
		split_curve.add_point(pt)
	_smooth_open_curve(split_curve)
	alternate_curves.append(split_curve)
	_build_branch_highway("CyberTunnelSplitRoute", split_curve, 6.4, asphalt, barrier_mat, magenta_neon, false, true)
	_build_route_portal_gantry(_track_transform(split_start + 10.0, 0.0), 7.5, "◄ NEON TUNNEL SPLIT-ROUTE", magenta_neon, barrier_mat)


## Samples the main circuit's centreline every `step` metres (used for clearance checks).
func _sample_circuit_points(step: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var o := 0.0
	while o < track_length:
		pts.append(_track_point(o))
		o += step
	return pts


## Raises an elevated-route sample to a safe clearance height if it passes over the
## main circuit at traffic height. Keeps any viaduct from sitting in the car's path.
const ROUTE_CLEARANCE_RADIUS := 14.0
const ROUTE_CLEARANCE_HEIGHT := 8.5
func _enforce_road_clearance(pt: Vector3, circuit_pts: PackedVector3Array) -> Vector3:
	if pt.y >= ROUTE_CLEARANCE_HEIGHT:
		return pt
	for cp in circuit_pts:
		if Vector2(cp.x - pt.x, cp.z - pt.z).length_squared() < ROUTE_CLEARANCE_RADIUS * ROUTE_CLEARANCE_RADIUS:
			return Vector3(pt.x, ROUTE_CLEARANCE_HEIGHT, pt.z)
	return pt


func _smooth_open_curve(c: Curve3D) -> void:
	var n := c.point_count
	for i in n:
		var p := c.get_point_position(i)
		var prev := c.get_point_position(maxi(0, i - 1))
		var next := c.get_point_position(mini(n - 1, i + 1))
		var h := (next - prev) * 0.22
		c.set_point_in(i, -h)
		c.set_point_out(i, h)
		_track_bounds_min = Vector2(minf(_track_bounds_min.x, p.x), minf(_track_bounds_min.y, p.z))
		_track_bounds_max = Vector2(maxf(_track_bounds_max.x, p.x), maxf(_track_bounds_max.y, p.z))


func _build_branch_highway(branch_name: String, branch_curve: Curve3D, half_w: float, asphalt: Material, barrier_mat: Material, neon_mat: Material, build_piers: bool, build_tunnel: bool) -> void:
	var path_node := Path3D.new()
	path_node.name = branch_name + "_Path"
	path_node.curve = branch_curve
	_track_root.add_child(path_node)

	# Structural concrete viaduct box-girder deck + drivable asphalt surface
	var deck := CSGPolygon3D.new()
	deck.name = branch_name + "_Deck"
	deck.polygon = PackedVector2Array([
		Vector2(-half_w, -0.45), Vector2(-half_w, ROAD_HEIGHT + 0.02),
		Vector2(half_w, ROAD_HEIGHT + 0.02), Vector2(half_w, -0.45),
	])
	deck.mode = CSGPolygon3D.MODE_PATH
	deck.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	deck.path_interval = 2.5
	deck.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	deck.path_joined = false
	deck.smooth_faces = true
	deck.use_collision = true
	deck.material = asphalt
	_track_root.add_child(deck)
	deck.path_node = deck.get_path_to(path_node)

	# Jersey barriers and LED strips only run where they can't block the main circuit: stretches that
	# stay clear of the carriageway, or are elevated above traffic. The asphalt deck keeps full length.
	var edge_curve := _trim_curve_clear_of_circuit(branch_curve, ROAD_HALF_WIDTH + 1.0, 3.0)
	var edge_path := Path3D.new()
	edge_path.name = branch_name + "_EdgePath"
	edge_path.curve = edge_curve
	_track_root.add_child(edge_path)

	# Left & Right Concrete Jersey Crash Barriers + Glowing LED Guidance Strips
	for side in [-1.0, 1.0]:
		var bx: float = side * (half_w + 0.32)
		var wall := CSGPolygon3D.new()
		wall.name = "%s_Barrier_%s" % [branch_name, "L" if side > 0 else "R"]
		var w_poly := PackedVector2Array([
			Vector2(bx - 0.32, -0.45), Vector2(bx - 0.24, ROAD_HEIGHT + 1.05),
			Vector2(bx + 0.24, ROAD_HEIGHT + 1.05), Vector2(bx + 0.32, -0.45),
		])
		wall.polygon = w_poly
		wall.mode = CSGPolygon3D.MODE_PATH
		wall.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
		wall.path_interval = 3.0
		wall.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
		wall.path_joined = false
		wall.smooth_faces = true
		wall.use_collision = true
		wall.material = barrier_mat
		_track_root.add_child(wall)
		wall.path_node = wall.get_path_to(edge_path)

		var led := CSGPolygon3D.new()
		var lx: float = side * (half_w - 0.02)
		led.polygon = PackedVector2Array([
			Vector2(lx - 0.08, ROAD_HEIGHT + 0.82), Vector2(lx - 0.08, ROAD_HEIGHT + 0.96),
			Vector2(lx + 0.08, ROAD_HEIGHT + 0.96), Vector2(lx + 0.08, ROAD_HEIGHT + 0.82),
		])
		led.mode = CSGPolygon3D.MODE_PATH
		led.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
		led.path_interval = 3.0
		led.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
		led.path_joined = false
		led.material = neon_mat
		_track_root.add_child(led)
		led.path_node = led.get_path_to(edge_path)

	# Center highway dividing line along the branch
	var yellow_paint := StandardMaterial3D.new()
	yellow_paint.albedo_color = Color(0.98, 0.82, 0.12)
	yellow_paint.roughness = 0.45
	var center_line := CSGPolygon3D.new()
	center_line.polygon = PackedVector2Array([
		Vector2(-0.12, ROAD_HEIGHT + 0.02), Vector2(-0.12, ROAD_HEIGHT + 0.035),
		Vector2(0.12, ROAD_HEIGHT + 0.035), Vector2(0.12, ROAD_HEIGHT + 0.02),
	])
	center_line.mode = CSGPolygon3D.MODE_PATH
	center_line.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	center_line.path_interval = 2.5
	center_line.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	center_line.path_joined = false
	center_line.material = yellow_paint
	_track_root.add_child(center_line)
	center_line.path_node = center_line.get_path_to(path_node)

	var blen: float = branch_curve.get_baked_length()
	if build_piers:
		var d: float = 28.0
		while d < blen - 24.0:
			var pt := branch_curve.sample_baked(d, true)
			var dir := (branch_curve.sample_baked(minf(blen, d + 2.0), true) - branch_curve.sample_baked(maxf(0.0, d - 2.0), true)).normalized()
			var b := Basis.looking_at(-dir, Vector3.UP)
			if pt.y > 2.2:
				# Check if pier column clears the primary ground road; if over the main road, use wide portal frame piers outside the road
				var main_closest := _track_closest_point(pt.x, pt.z)
				var dist_main := Vector2(main_closest.x - pt.x, main_closest.z - pt.z).length()
				_add_prop(Vector3(half_w * 2.0 + 1.4, 0.85, 1.8), Vector3(pt.x, pt.y - 0.65, pt.z), b, barrier_mat)
				if dist_main > ROAD_HALF_WIDTH + 2.5:
					_add_prop(Vector3(1.5, pt.y, 1.8), Vector3(pt.x, pt.y * 0.5, pt.z), b, barrier_mat)
			d += 30.0

	if build_tunnel:
		# Architectural Brutalist Concrete Cyber-Tunnel Gallery over the middle 60% of the split route
		var td: float = blen * 0.20
		while td < blen * 0.80:
			var pt := branch_curve.sample_baked(td, true)
			var dir := (branch_curve.sample_baked(minf(blen, td + 2.0), true) - branch_curve.sample_baked(maxf(0.0, td - 2.0), true)).normalized()
			var b := Basis.looking_at(-dir, Vector3.UP)
			var arch_h: float = 6.8
			for side in [-1.0, 1.0]:
				var wx: Vector3 = pt + b.x * (side * (half_w + 0.55)) + Vector3.UP * (arch_h * 0.5)
				_add_prop(Vector3(0.75, arch_h, 4.2), wx, b, barrier_mat)
			_add_prop(Vector3(half_w * 2.0 + 1.8, 0.75, 4.2), pt + Vector3.UP * arch_h, b, barrier_mat)
			_add_prop(Vector3(half_w * 1.8, 0.16, 0.45), pt + Vector3.UP * (arch_h - 0.42), b, neon_mat)
			td += 8.5


## Returns the part of `c` that stays at least `clear` metres from the main circuit centreline, or is
## at least `min_elev_y` metres high (elevated over traffic). Only the longest continuous run is kept, so
## junction stubs that sit on the main road are dropped. Falls back to the full curve if nothing is left.
func _trim_curve_clear_of_circuit(c: Curve3D, clear: float, min_elev_y: float) -> Curve3D:
	var circuit := _sample_circuit_points(2.0)
	var total := c.get_baked_length()
	var samples: Array[Vector3] = []
	var ok: Array[bool] = []
	var s := 0.0
	while s <= total:
		var p := c.sample_baked(s)
		var md := INF
		if p.y < min_elev_y:
			for cp in circuit:
				var d := Vector2(cp.x - p.x, cp.z - p.z).length_squared()
				if d < md:
					md = d
		samples.append(p)
		ok.append(p.y >= min_elev_y or md >= clear * clear)
		s += 2.0
	var best_start := 0
	var best_len := 0
	var run_start := -1
	for i in range(samples.size() + 1):
		var good := i < samples.size() and ok[i]
		if good and run_start < 0:
			run_start = i
		elif not good and run_start >= 0:
			if i - run_start > best_len:
				best_len = i - run_start
				best_start = run_start
			run_start = -1
	var out := Curve3D.new()
	out.bake_interval = 2.0
	if best_len < 2:
		return c
	for i in range(best_start, best_start + best_len):
		out.add_point(samples[i])
	_smooth_open_curve(out)
	return out


func _build_route_portal_gantry(xform: Transform3D, lat_offset: float, title: String, neon_mat: Material, post_mat: Material) -> void:
	var gh: float = 7.4
	var post_dist: float = ROAD_HALF_WIDTH + 1.35 # 12.85m: safely planted on the sidewalk curb, 100% off the drivable road carriage
	var span_width: float = post_dist * 2.0

	# Two heavy structural viaduct/overhead gantry pillars grounded safely on the sidewalks
	for side in [-1.0, 1.0]:
		var post_pos: Vector3 = xform.origin + xform.basis.x * (side * post_dist) + Vector3.UP * (gh * 0.5)
		_add_prop(Vector3(0.65, gh, 0.65), post_pos, xform.basis, post_mat)

	# Continuous overhead truss spanning across the entire boulevard
	var truss_pos: Vector3 = xform.origin + Vector3.UP * gh
	_add_prop(Vector3(span_width + 0.8, 0.95, 0.55), truss_pos, xform.basis, post_mat)

	# Illuminated route signage board positioned precisely over the target diverge lane with 6+ meters vertical clearance
	var sign_w: float = 9.4
	var sign_pos: Vector3 = xform.origin + xform.basis.x * lat_offset + Vector3.UP * (gh - 0.45)
	_add_prop(Vector3(sign_w, 1.25, 0.38), sign_pos, xform.basis, post_mat)
	_add_prop(Vector3(sign_w - 0.2, 0.14, 0.48), sign_pos + Vector3.UP * 0.68, xform.basis, neon_mat)

	var lbl := Label3D.new()
	lbl.text = title
	lbl.font_size = 32
	lbl.outline_size = 6
	lbl.double_sided = true
	lbl.modulate = Color(0.96, 0.98, 1.0)
	lbl.outline_modulate = Color(0.02, 0.06, 0.12)
	lbl.transform = Transform3D(xform.basis, sign_pos - xform.basis.z * 0.24)
	_track_root.add_child(lbl)


func _add_track_strip(polygon: PackedVector2Array, material: Material) -> CSGPolygon3D:
	var strip := CSGPolygon3D.new()
	strip.polygon = polygon
	strip.mode = CSGPolygon3D.MODE_PATH
	strip.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	strip.path_interval = 2.0
	strip.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	strip.smooth_faces = true
	strip.material = material
	_track_root.add_child(strip)
	strip.path_node = strip.get_path_to(track_path)
	return strip


func _build_start_line() -> void:
	var line_xform := _track_transform(0.0, ROAD_HEIGHT + 0.005)

	# High-detail checkered start/finish grid line across the roadway
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.96, 0.96, 0.96)
	white_mat.roughness = 0.45
	var plane := PlaneMesh.new()
	plane.size = Vector2(ROAD_HALF_WIDTH * 2.0 - 0.4, 1.2)
	plane.material = white_mat
	var line := MeshInstance3D.new()
	line.mesh = plane
	line.transform = line_xform
	_track_root.add_child(line)

	# Start/Finish Overhead Arch Gantry (posts located safely on the sidewalks at ±12.85m)
	var gantry_mat := StandardMaterial3D.new()
	gantry_mat.albedo_color = Color(0.14, 0.16, 0.20)
	gantry_mat.metallic = 0.82
	gantry_mat.roughness = 0.28

	var neon_cyan := StandardMaterial3D.new()
	neon_cyan.albedo_color = Color(0.1, 0.95, 1.0)
	neon_cyan.emission_enabled = true
	neon_cyan.emission = Color(0.1, 0.95, 1.0)
	neon_cyan.emission_energy_multiplier = 3.5

	var post_dist: float = ROAD_HALF_WIDTH + 1.35
	var gh: float = 7.5
	for side in [-1.0, 1.0]:
		var post_pos: Vector3 = line_xform.origin + line_xform.basis.x * (side * post_dist) + Vector3.UP * (gh * 0.5)
		_add_prop(Vector3(0.65, gh, 0.65), post_pos, line_xform.basis, gantry_mat)

	var truss_pos: Vector3 = line_xform.origin + Vector3.UP * gh
	_add_prop(Vector3(post_dist * 2.0 + 0.8, 1.0, 0.55), truss_pos, line_xform.basis, gantry_mat)
	_add_prop(Vector3(post_dist * 2.0 + 0.4, 0.12, 0.6), truss_pos + Vector3.UP * 0.55, line_xform.basis, neon_cyan)

	var start_lbl := Label3D.new()
	start_lbl.text = "START  /  FINISH"
	start_lbl.font_size = 36
	start_lbl.outline_size = 6
	start_lbl.double_sided = true
	start_lbl.modulate = Color(0.96, 0.98, 1.0)
	start_lbl.outline_modulate = Color(0.02, 0.06, 0.12)
	start_lbl.transform = Transform3D(line_xform.basis, truss_pos - line_xform.basis.z * 0.3)
	_track_root.add_child(start_lbl)


func _build_road_details() -> void:
	var corners := _find_corners()
	_corners = corners
	var white_paint := StandardMaterial3D.new()
	white_paint.albedo_color = Color(0.95, 0.95, 0.93)
	white_paint.roughness = 0.5

	# Dashed white lane dividers between Lane 1-2 (-4.6m) and Lane 3-4 (+4.6m)
	var dashes := SurfaceTool.new()
	dashes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var offset := 0.0
	while offset + DASH_LENGTH < track_length:
		for lx: float in [-4.6, 4.6]:
			_add_strip(dashes, offset, offset + DASH_LENGTH, lx - 0.09, lx + 0.09, ROAD_HEIGHT + 0.008, ROAD_HEIGHT + 0.008, Color.WHITE)
		offset += DASH_LENGTH + DASH_GAP
	_add_mesh(dashes, white_paint)

	# Red and White Alternating Rumble Kerbs on Corner Apexes
	var kerbs := SurfaceTool.new()
	kerbs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var kerb_mat := StandardMaterial3D.new()
	kerb_mat.vertex_color_use_as_albedo = true
	kerb_mat.roughness = 0.55
	for corner in corners:
		var side: float = corner.z
		var in_edge: float = side * (ROAD_HALF_WIDTH - 1.25)
		var out_edge: float = side * ROAD_HALF_WIDTH
		var o: float = corner.x
		var k_idx: int = 0
		while o < corner.y:
			var next: float = minf(o + 1.2, corner.y)
			var col: Color = Color(0.92, 0.15, 0.15) if (k_idx % 2 == 0) else Color(0.96, 0.96, 0.96)
			_add_strip(kerbs, o, next, in_edge, out_edge, ROAD_HEIGHT + 0.012, ROAD_HEIGHT + 0.024, col)
			k_idx += 1
			o = next
	_add_mesh(kerbs, kerb_mat)

	# Guardrails on the outside of corners
	_build_guardrails(corners)


## Dynamic Road Mechanics: Spawns RoadRepairController instances with Area3D triggers,
## coroutines, and VehicleWheel3D traction modifiers.
func _build_dynamic_road_repairs() -> void:
	road_repair_zones.clear()
	if track_length < 500.0:
		return

	# Place dynamic road repair zones at key points along the circuit
	var repair_offsets := [
		track_length * 0.18,
		track_length * 0.72
	]

	for idx in repair_offsets.size():
		var off: float = repair_offsets[idx]
		var xform: Transform3D = _track_transform(off, ROAD_HEIGHT)
		# Position repair zone neatly in the outer travel lane (-6.8m right / +6.8m left), leaving passing lanes open
		var lane_lat: float = -6.8 if (idx % 2 == 0) else 6.8
		var lane_xform := xform.translated_local(Vector3(lane_lat, 0.0, 0.0))
		var zone: RoadRepairController = RoadRepairControllerScript.new()
		zone.name = "RoadRepairZone_%d" % idx
		zone.repair_duration = 3.2
		zone.damaged_traction = 0.60
		zone.fixed_traction = 1.00
		zone.setup_procedural_visuals(Vector3(4.8, 3.5, 16.0))
		zone.transform = lane_xform
		_track_root.add_child(zone)
		road_repair_zones.append(zone)

		# Notification when road repair coroutine completes
		zone.repair_completed.connect(func(_ctrl):
			_show_message("Road Repair Complete: Full Traction Restored!", 3.0)
		)


func _trigger_nearest_road_repair() -> void:
	if not car or road_repair_zones.is_empty():
		return
	var nearest_zone: RoadRepairController = null
	var min_dist: float = 1e9
	for zone in road_repair_zones:
		if is_instance_valid(zone):
			var d := car.global_position.distance_to(zone.global_position)
			if d < min_dist:
				min_dist = d
				nearest_zone = zone
	if nearest_zone:
		if nearest_zone.current_state == RoadRepairController.RoadState.FIXED:
			_show_message("Nearest road section is already in pristine condition!", 2.0)
		elif nearest_zone.current_state == RoadRepairController.RoadState.REPAIRING:
			_show_message("Road repair crew already dispatched on site!", 2.0)
		else:
			_show_message("Dispatching Road Repair Crew (Distance: %.0fm)..." % min_dist, 2.5)
			nearest_zone.trigger_repair()


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
					posts.append(Transform3D(p0.basis, a + p0.basis.x * signf(lateral) * 0.15 + p0.basis.y * 0.45))
			o = next
	var rail_mesh := _add_mesh(rails, steel)

	if rail_mesh.get_surface_count() > 0:
		var body := StaticBody3D.new()
		body.name = "Guardrail"
		var shape := CollisionShape3D.new()
		var trimesh := rail_mesh.create_trimesh_shape() as ConcavePolygonShape3D
		if trimesh:
			trimesh.backface_collision = true
			shape.shape = trimesh
			body.add_child(shape)
			_track_root.add_child(body)

	if not posts.is_empty():
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
		_track_root.add_child(instance)


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
			quad = [t0.origin + t0.basis.x * a + t0.basis.y * (height_a - drop), t1.origin + t1.basis.x * a + t1.basis.y * (height_a - drop),
				t1.origin + t1.basis.x * a + t1.basis.y * height_a, t0.origin + t0.basis.x * a + t0.basis.y * height_a]
		else:
			quad = [t0.origin + t0.basis.x * a + t0.basis.y * height_a, t1.origin + t1.basis.x * a + t1.basis.y * height_a,
				t1.origin + t1.basis.x * b + t1.basis.y * height_b, t0.origin + t0.basis.x * b + t0.basis.y * height_b]
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
	_track_root.add_child(instance)
	return mesh


func _add_prop(size: Vector3, pos: Vector3, rot: Basis, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.transform = Transform3D(rot, pos)
	_track_root.add_child(instance)
	var body := StaticBody3D.new()
	body.name = "Prop"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.transform = instance.transform
	_track_root.add_child(body)


func _build_checkpoints() -> void:
	for i in CHECKPOINT_COUNT:
		var area := Area3D.new()
		area.name = "LapCheckpoint_%d" % i
		area.monitorable = false
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		# Generously expanded checkpoint bounding box: 163m width and 52m vertical span so laps register
		# flawlessly across main boulevard, elevated viaduct overpass (y=16.2m), and wide outer bypass corridors (±55m)
		box.size = Vector3(ROAD_HALF_WIDTH * 2.0 + 140.0, 52.0, 6.0)
		shape.shape = box
		area.add_child(shape)
		area.transform = _track_transform(track_length * i / CHECKPOINT_COUNT, 10.0)
		area.body_entered.connect(_on_checkpoint_entered.bind(i))
		_track_root.add_child(area)


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
			_track_root.add_child(body)

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
		_track_root.add_child(instance)
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
			# Strictly ensure NO grass can ever spawn on or near the highway or its shoulders
			if _distance_to_track(pos.x, pos.z) < ROAD_HALF_WIDTH + 6.0:
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
		_track_root.add_child(instance)
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
		_track_root.add_child(rock)
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
			_track_root.add_child(body)


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
			racer.body_style = "centenario"
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
			var route_choice := (i - 1) % 3
			driver.setup(racer, self, OPPONENTS[i].skill, slot.y, route_choice, OPPONENTS[i].persona)
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

	# Dynamic G-Force Inertia Rig
	var lat_g: float = car.get("g_force_lateral") if (car and "g_force_lateral" in car) else 0.0
	var lon_g: float = car.get("g_force_longitudinal") if (car and "g_force_longitudinal" in car) else 0.0
	var target_head_pos := Vector3(
		clampf(-lat_g * 0.045, -0.06, 0.06),
		clampf(-absf(lat_g) * 0.015 - lon_g * 0.02, -0.04, 0.03),
		clampf(lon_g * 0.05, -0.07, 0.07)
	)
	var target_head_rot := Vector3(
		clampf(-lon_g * 0.04, -0.055, 0.055),
		0.0,
		clampf(lat_g * 0.042, -0.065, 0.065)
	)
	_head_inertia_pos = _head_inertia_pos.lerp(target_head_pos, delta * 12.0)
	_head_inertia_rot = _head_inertia_rot.lerp(target_head_rot, delta * 12.0)

	match CAMERA_VIEWS[camera_view].mode:
		"bumper":
			var z := -2.75 if looking_back else 2.6
			var bumper_pos := Vector3(0.0, 0.75, z) + Vector3(_head_inertia_pos.x * 0.3, _head_inertia_pos.y * 0.3, 0.0)
			camera.global_transform = car.global_transform * Transform3D(behind, bumper_pos)
			camera.fov = 78.0
			_apply_camera_shake(delta)
			return
		"cockpit":
			var inertia_basis := Basis.from_euler(_head_inertia_rot)
			var head_xform := Transform3D(behind * inertia_basis, car.cockpit_offset() + _head_inertia_pos)
			camera.global_transform = car.global_transform * head_xform
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
	camera.rotation.z = lerpf(camera.rotation.z, _head_inertia_rot.z * 0.45, delta * 10.0)
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


var _last_grounded_offset: float = -1.0
var _stuck_time: float = 0.0
var _player_horn: AudioStreamPlayer3D = null
var _stuck_hinted: bool = false

func _reset_car() -> void:
	flipped_time = 0.0
	var offset := _last_grounded_offset if _last_grounded_offset >= 0.0 else curve.get_closest_offset(car.global_position)
	(car as CarScript).reset_to(_track_transform(offset, 0.8))


## Player horn: sounds the car's horn and lets the city react (pedestrians by personality, traffic honks back).
func _honk() -> void:
	if not is_instance_valid(car):
		return
	if _player_horn == null:
		_player_horn = AudioStreamPlayer3D.new()
		_player_horn.unit_size = 18.0
		_player_horn.max_distance = 95.0
		_player_horn.volume_db = -4.0
		car.add_child(_player_horn)
	var city := _living_city()
	if city:
		if _player_horn.stream == null:
			var hs = city.get("_horn_stream")
			if hs is AudioStream:
				_player_horn.stream = hs
		if city.has_method("honk_from"):
			city.call("honk_from", car.global_position)
	if _player_horn.stream and not _player_horn.playing:
		_player_horn.play()


func _living_city() -> Node:
	return _track_root.get_node_or_null("LivingCityController") if is_instance_valid(_track_root) else null


func load_track(index: int) -> void:
	current_track_index = posmod(index, TRACK_DATA.size())
	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	settings.set_value("race", "track", current_track_index)
	settings.save("user://settings.cfg")

	tree_instances.clear()
	grass_instances.clear()

	if _track_root and is_instance_valid(_track_root):
		_track_root.name = "TrackRoot_Disposed"
		_track_root.queue_free()

	_track_root = Node3D.new()
	_track_root.name = "TrackRoot"
	add_child(_track_root)

	_build_track_curve()
	_build_road()
	_build_alternate_routes_and_overpasses()
	_build_start_line()
	_build_road_details()
	_build_dynamic_road_repairs()
	_build_checkpoints()
	CityBuilderScript.build_city(self, _track_root)

	apply_quality(current_quality_level)

	if minimap_ctrl:
		minimap_ctrl.setup(curve.get_baked_points(), car, Vector2(230.0, 230.0), alternate_curves)

	_reset_race()
	_show_message(TRACK_DATA[current_track_index].name, 3.5)


func _reset_race() -> void:
	countdown = COUNTDOWN
	race_time = 0.0
	player_finish_time = 0.0
	finish_order.clear()
	laps_done = 0
	lap_running = false
	lap_time = 0.0
	last_lap = INF
	best_lap = INF
	next_checkpoint = 0
	flipped_time = 0.0
	current_split_times = [0.0, 0.0, 0.0, 0.0]
	best_split_times = [0.0, 0.0, 0.0, 0.0]
	sector_delta_timer = 0.0
	sector_delta_text = ""
	for i in cars.size():
		var racer := cars[i]
		var slot: Vector2 = GRID[i]
		var spot := _track_transform(-slot.x, 0.8)
		(racer as CarScript).reset_to(spot.translated(spot.basis.x * slot.y))
		progress[racer] = -slot.x
		_last_offset[racer] = fposmod(-slot.x, track_length)
		racer.frozen = true


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
		if lap_running and index < current_split_times.size():
			current_split_times[index] = lap_time
			if best_split_times[index] > 0.0:
				var diff := lap_time - best_split_times[index]
				if diff <= 0.0:
					sector_delta_text = "-%.2fs" % absf(diff)
					sector_delta_color = Color(0.2, 1.0, 0.3)
				else:
					sector_delta_text = "+%.2fs" % diff
					sector_delta_color = Color(1.0, 0.3, 0.2)
				sector_delta_timer = 3.0
		return
	if lap_running:
		last_lap = lap_time
		laps_done += 1
		if lap_time < best_lap:
			best_lap = lap_time
			best_split_times = current_split_times.duplicate()
			_show_message("New best lap!  " + _format_time(lap_time), 3.0)
		else:
			_show_message("Lap  " + _format_time(lap_time), 3.0)
	else:
		_show_message("Go!", 1.5)
	lap_running = true
	lap_time = 0.0
	current_split_times = [0.0, 0.0, 0.0, 0.0]


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
	sector_delta_label = _make_label(timing, 24)
	sector_delta_label.visible = false
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

	# Live G-Force Friction Circle & Driver Assist Status Badges
	var telem_row := HBoxContainer.new()
	telem_row.alignment = BoxContainer.ALIGNMENT_END
	telem_row.add_theme_constant_override("separation", 10)
	gauges.add_child(telem_row)

	var assist_box := VBoxContainer.new()
	assist_box.alignment = BoxContainer.ALIGNMENT_CENTER
	assist_box.add_theme_constant_override("separation", 2)
	telem_row.add_child(assist_box)

	abs_indicator = Label.new()
	abs_indicator.text = "ABS"
	abs_indicator.add_theme_font_size_override("font_size", 14)
	abs_indicator.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	abs_indicator.add_theme_constant_override("outline_size", 3)
	abs_indicator.add_theme_color_override("font_color", Color(0.35, 0.4, 0.45, 0.5))
	assist_box.add_child(abs_indicator)

	tcs_indicator = Label.new()
	tcs_indicator.text = "TCS"
	tcs_indicator.add_theme_font_size_override("font_size", 14)
	tcs_indicator.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	tcs_indicator.add_theme_constant_override("outline_size", 3)
	tcs_indicator.add_theme_color_override("font_color", Color(0.35, 0.4, 0.45, 0.5))
	assist_box.add_child(tcs_indicator)

	g_force_val_label = Label.new()
	g_force_val_label.text = "0.00 G"
	g_force_val_label.add_theme_font_size_override("font_size", 13)
	g_force_val_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	g_force_val_label.add_theme_constant_override("outline_size", 3)
	g_force_val_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.85))
	assist_box.add_child(g_force_val_label)

	var g_widget := GMeterWidget.new()
	g_widget.car = car
	telem_row.add_child(g_widget)
	g_meter_ctrl = g_widget

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
	help.text = "W/S: drive    A/D: steer    Space: handbrake / drift    Space+W: burnout    K: repair road    R: reset    C: camera    B: look back    H: headlights    V: photo mode    F: fps    G: graphics    Esc: menu"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help.offset_left = 28.0
	help.offset_bottom = -20.0
	help.modulate.a = 0.8

	var minimap := MinimapScript.new() as Control
	layer.add_child(minimap)
	minimap_ctrl = minimap
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -254.0
	minimap.offset_right = -24.0
	minimap.offset_top = 20.0
	minimap.offset_bottom = 250.0
	minimap.setup(curve.get_baked_points(), car, Vector2(230.0, 230.0), alternate_curves)
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
