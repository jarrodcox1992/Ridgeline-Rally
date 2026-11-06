class_name CityBuilder
extends RefCounted

## Unified Flagship Metropolitan City Engine for Ridgeline Rally.
## Combines 4 distinct urban sectors (Financial Core, Neon Entertainment Strip,
## Historic Brick & El-Train District, and Industrial Logistics) along a single
## cohesive loop using photo-scanned Poly Haven 3D models and 2K PBR textures.

const SKYSCRAPER_SHADER := preload("res://shaders/skyscraper.gdshader")
const BRICK_WAREHOUSE_SHADER := preload("res://shaders/brick_warehouse.gdshader")
const STEAM_VENT_SHADER := preload("res://shaders/steam_vent.gdshader")
const RESIDENTIAL_MEGABLOCK_SHADER := preload("res://shaders/residential_megablock.gdshader")
const INDUSTRIAL_LOGISTICS_SHADER := preload("res://shaders/industrial_logistics.gdshader")
const OIL_PUDDLE_SHADER := preload("res://shaders/oil_puddle.gdshader")
const CYBER_BILLBOARD_SHADER := preload("res://shaders/cyber_billboard.gdshader")

# 2K Photo-Scanned PBR Textures
const TEX_PAVING_DIFF := preload("res://textures/city_pbr/rectangular_paving_diff.jpg")
const TEX_PAVING_NOR := preload("res://textures/city_pbr/rectangular_paving_nor_gl.jpg")
const TEX_PAVING_ROUGH := preload("res://textures/city_pbr/rectangular_paving_rough.jpg")
const TEX_GRAVEL_DIFF := preload("res://textures/city_pbr/tarred_gravel_diff.jpg")
const TEX_GRAVEL_NOR := preload("res://textures/city_pbr/tarred_gravel_nor_gl.jpg")
const TEX_GRAVEL_ROUGH := preload("res://textures/city_pbr/tarred_gravel_rough.jpg")
const TEX_BRICK_DIFF := preload("res://textures/city_pbr/red_brick_03_diff.jpg")
const TEX_BRICK_NOR := preload("res://textures/city_pbr/red_brick_03_nor_gl.jpg")
const TEX_CONCRETE_DIFF := preload("res://textures/city_pbr/concrete_wall_006_diff.jpg")
const TEX_CONCRETE_NOR := preload("res://textures/city_pbr/concrete_wall_006_nor_gl.jpg")
const TEX_IRON_DIFF := preload("res://textures/city_pbr/corrugated_iron_diff.jpg")
const TEX_IRON_NOR := preload("res://textures/city_pbr/corrugated_iron_nor_gl.jpg")
const TEX_STOREFRONT_RAMEN := preload("res://textures/city_pbr/storefront_ramen_interior.jpg")
const TEX_BILLBOARD_SUPERCAR := preload("res://textures/city_pbr/neon_billboard_supercar.jpg")
const TEX_BILLBOARD_ARCADE := preload("res://textures/city_pbr/neon_billboard_arcade.jpg")

# Poly Haven Photo-Scanned 3D Urban Models (1:1 Metric GLTF)
const PH_FIRE_HYDRANT := preload("res://models/polyhaven/fire_hydrant/fire_hydrant.gltf")
const PH_MANHOLE_COVER := preload("res://models/polyhaven/water_manhole_cover/water_manhole_cover.gltf")
const PH_STREET_LAMP := preload("res://models/polyhaven/street_lamp_01/street_lamp_01.gltf")
const PH_SECURITY_CAM := preload("res://models/polyhaven/security_camera_01/security_camera_01.gltf")
const PH_ROLLERSHUTTER := preload("res://models/polyhaven/rollershutter_door/rollershutter_door.gltf")
const PH_FIRE_ESCAPE := preload("res://models/polyhaven/modular_fire_escape/modular_fire_escape.gltf")
const PH_PLASTIC_CRATE := preload("res://models/polyhaven/plastic_crate_01/plastic_crate_01.gltf")
const PH_OLD_TYRE := preload("res://models/polyhaven/old_tyre/old_tyre.gltf")
const PH_ROAD_BARRIER := preload("res://models/polyhaven/concrete_road_barrier/concrete_road_barrier.gltf")
const PH_STREET_SEATING := preload("res://models/polyhaven/modular_street_seating/modular_street_seating.gltf")
const PH_UTILITY_BOX_1 := preload("res://models/polyhaven/utility_box_01/utility_box_01.gltf")
const PH_UTILITY_BOX_2 := preload("res://models/polyhaven/utility_box_02/utility_box_02.gltf")
const PH_SECURITY_LIGHT := preload("res://models/polyhaven/security_light/security_light.gltf")
const PH_PLANTER_BOX := preload("res://models/polyhaven/planter_box_01/planter_box_01.gltf")
const PH_SHRUB := preload("res://models/polyhaven/shrub_02/shrub_02.gltf")
const PH_METAL_TRASHCAN := preload("res://models/polyhaven/metal_trash_can/metal_trash_can.gltf")
const PH_TRASHBAG := preload("res://models/polyhaven/trashbag/trashbag.gltf")
const PH_AIRCON_UNIT := preload("res://models/polyhaven/exterior_aircon_unit/exterior_aircon_unit.gltf")
const PH_CARDBOARD_BOX := preload("res://models/polyhaven/cardboard_box_01/cardboard_box_01.gltf")

# High-Detail City 3D Models (GLB)
const HD_BUS_STOP := preload("res://models/city_hd/kyoto_cityscene_bus_stop.glb")
const HD_VENDING_MACHINE := preload("res://models/city_hd/red_japanese_vending_machine_clean.glb")
const HD_TRAFFIC_LIGHT := preload("res://models/city_hd/traffic_light.glb")
const HD_BOLLARD := preload("res://models/city_hd/bollard.glb")
const HD_BICYCLE := preload("res://models/city_hd/bicycle.glb")
const HD_POSTBOX := preload("res://models/city_hd/postbox_red.glb")
const HD_NEON_STREET := preload("res://models/city_hd/neon_street.glb")
const HD_COP_CRUISER := preload("res://models/city_hd/cop_cruiser.glb")
const HD_AMBULANCE := preload("res://models/city_hd/ambulance.glb")
const HD_KEI_TRUCK := preload("res://models/city_hd/1984_suzuki_kei_truck_clean.glb")
const HD_PED_CLAUDIA := preload("res://models/city_hd/claudia.glb")
const HD_PED_ERIC := preload("res://models/city_hd/eric.glb")
const HD_PED_NATHAN := preload("res://models/city_hd/nathan.glb")
const HD_PED_CARLA := preload("res://models/city_hd/carla.glb")
const CHAR_PEOPLE: Array[PackedScene] = [
	preload("res://models/people_src/claudia_low.glb"),
	preload("res://models/people_src/eric_low.glb"),
	preload("res://models/people_src/nathan_low.glb"),
	preload("res://models/people_src/carla_low.glb"),
]
const HD_CITY_BUS := preload("res://models/city_hd/isuzu_erga_mio_bus_clean.glb")
const HD_FIRE_TRUCK := preload("res://models/city_hd/fire_truck.glb")
const HD_TAXI := preload("res://models/city_hd/2001_toyota_crown_comfort_s10_clean.glb")
const HD_SCOOTER := preload("res://models/city_hd/old_scooter_clean.glb")
const HD_METRO_TRAIN := preload("res://models/city_hd/ginza_line_clean.glb")
const HD_NEON_VERTICAL := preload("res://models/city_hd/neon_vertical.glb")
const HD_LAMP_MODERN := preload("res://models/city_hd/lamp_baturinets.glb")

# Additional Modular Urban Props (GLB)
const MODEL_DUMPSTER := preload("res://models/props/dumpster.glb")
const MODEL_DUMPSTER_OPEN := preload("res://models/props/dumpster_open.glb")
const MODEL_BENCH := preload("res://models/props/bench.glb")
const MODEL_PALLET := preload("res://models/props/pallet.glb")
const MODEL_CONE := preload("res://models/props/cone.glb")
const MODEL_DELIVERY_TRUCK := preload("res://models/props/delivery_truck.glb")
const MODEL_TREE_LARGE := preload("res://models/props/tree_large.glb")
const MODEL_AWNING := preload("res://models/props/awning.glb")
const MODEL_BALCONY := preload("res://models/props/balcony.glb")
const MODEL_VENDING_KIOSK := preload("res://models/props/vending_kiosk.glb")
const MODEL_TRASHCAN := preload("res://models/props/trashcan.glb")
const MODEL_STOP_SIGN := preload("res://models/props/stop_sign.glb")
const MODEL_SIGN_NOPARKING := preload("res://models/props/sign_noparking.glb")
const MODEL_CRATE := preload("res://models/props/crate.glb")
const MODEL_WATER_TANK := preload("res://models/props/water_tank.glb")
const MODEL_ANTENNA_DISH := preload("res://models/props/antenna_dish.glb")
const LIVING_CITY_SCRIPT := preload("res://living_city_controller.gd")

enum Archetype {
	CORPORATE_HIGHRISE,
	RESIDENTIAL_MEGABLOCK,
	INDUSTRIAL_LOGISTICS,
	HISTORIC_BRICK
}

const FACADE_PALETTES: Array[Dictionary] = [
	{
		"facade": Color(0.36, 0.35, 0.33),
		"glass": Color(0.10, 0.16, 0.22),
		"window_lit": Color(1.0, 0.92, 0.75),
		"metallic": 0.65,
		"roughness": 0.32
	},
	{
		"facade": Color(0.28, 0.30, 0.32),
		"glass": Color(0.14, 0.20, 0.26),
		"window_lit": Color(0.75, 0.90, 1.0),
		"metallic": 0.78,
		"roughness": 0.24
	},
	{
		"facade": Color(0.42, 0.40, 0.37),
		"glass": Color(0.12, 0.16, 0.18),
		"window_lit": Color(1.0, 0.85, 0.62),
		"metallic": 0.55,
		"roughness": 0.38
	},
	{
		"facade": Color(0.32, 0.31, 0.29),
		"glass": Color(0.08, 0.14, 0.20),
		"window_lit": Color(0.95, 0.95, 1.0),
		"metallic": 0.72,
		"roughness": 0.28
	}
]

const BRICK_PALETTES: Array[Dictionary] = [
	{
		"primary": Color(0.48, 0.20, 0.14),
		"secondary": Color(0.36, 0.14, 0.10),
		"mortar": Color(0.65, 0.62, 0.58),
		"window_lit": Color(1.0, 0.86, 0.60)
	},
	{
		"primary": Color(0.32, 0.22, 0.18),
		"secondary": Color(0.24, 0.16, 0.12),
		"mortar": Color(0.55, 0.52, 0.48),
		"window_lit": Color(1.0, 0.78, 0.45)
	},
	{
		"primary": Color(0.22, 0.20, 0.22),
		"secondary": Color(0.16, 0.14, 0.16),
		"mortar": Color(0.45, 0.45, 0.48),
		"window_lit": Color(0.85, 0.92, 1.0)
	}
]

const RESIDENTIAL_PALETTES: Array[Dictionary] = [
	{
		"concrete": Color(0.52, 0.54, 0.56),
		"spandrel": Color(0.22, 0.25, 0.30),
		"warm_light": Color(1.0, 0.88, 0.65),
		"cool_light": Color(0.70, 0.85, 1.0)
	},
	{
		"concrete": Color(0.42, 0.44, 0.46),
		"spandrel": Color(0.18, 0.19, 0.22),
		"warm_light": Color(1.0, 0.82, 0.52),
		"cool_light": Color(0.80, 0.90, 1.0)
	}
]

const INDUSTRIAL_PALETTES: Array[Dictionary] = [
	{
		"metal": Color(0.32, 0.35, 0.38),
		"rust": Color(0.45, 0.22, 0.12),
		"caution": Color(0.95, 0.78, 0.12)
	},
	{
		"metal": Color(0.22, 0.26, 0.30),
		"rust": Color(0.38, 0.18, 0.10),
		"caution": Color(0.92, 0.65, 0.10)
	}
]

const NEON_COLORS: Array[Color] = [
	Color(0.15, 0.75, 1.0),
	Color(1.0, 0.12, 0.65),
	Color(0.20, 1.0, 0.45),
	Color(1.0, 0.65, 0.10),
	Color(0.85, 0.25, 1.0),
	Color(1.0, 0.95, 0.20)
]

const NEON_SIGN_TEXTS: Array[String] = [
	"CYBERDYNE", "HOTEL METROPOLIS", "BAR NOIR", "RAMEN 24/7",
	"QUANTUM BANK", "CLUB ECLIPSE", "KINETIC MOTORS", "TERMINAL 9",
	"APEX ARCHITECTURE", "SYNAPSE TECH", "TITAN LOGISTICS", "NEON DREAMS",
	"MIDNIGHT DINER", "VORTEX AUDIO", "CHRONOS WATCHES", "PHANTOM CASINO"
]

const STREET_NAMES: Array[String] = [
	"5th AVE", "BROADWAY", "GOTHAM BLVD", "METROPOLITAN WAY",
	"INDUSTRIAL PKWY", "HARBOR DR", "FOUNDRY ST", "UNION ROW",
	"LEXINGTON AVE", "PARK BLVD", "SKYLINE DR", "CENTRAL PLAZA"
]

## Spawns an imported 3D GLTF/GLB model at a given transform with uniform scaling and road-clearance guard
static func _spawn_model(track_root: Node3D, scene: PackedScene, xform: Transform3D, offset: Vector3, scale_factor: float, rot_deg_y: float = 0.0) -> Node3D:
	if not scene:
		return null
	var world_pos: Vector3 = xform * offset
	var main_node: Node = track_root.get_parent()
	if main_node and main_node.has_method("_distance_to_track"):
		var dist: float = float(main_node.call("_distance_to_track", world_pos.x, world_pos.z))
		var road_half: float = float(main_node.get("ROAD_HALF_WIDTH"))
		if dist < road_half + 0.35:
			return null # Guarantee 100% clean road carriage with zero obstructions
	var inst := scene.instantiate() as Node3D
	if inst:
		var basis_scaled := xform.basis.scaled(Vector3(scale_factor, scale_factor, scale_factor))
		if rot_deg_y != 0.0:
			basis_scaled = basis_scaled.rotated(xform.basis.y.normalized(), deg_to_rad(rot_deg_y))
		inst.transform = Transform3D(basis_scaled, world_pos)
		if scene == MODEL_TREE_LARGE:
			_tint_tree_lush_green(inst)
		track_root.add_child(inst)
		return inst
	return null


static func _make_pbr_concrete(tint: Color, rough: float = 0.65, metal: float = 0.16, uv_scale: float = 0.24) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.albedo_texture = TEX_CONCRETE_DIFF
	mat.normal_enabled = true
	mat.normal_texture = TEX_CONCRETE_NOR
	mat.normal_scale = 1.15
	mat.roughness = rough
	mat.metallic = metal
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	return mat


static func _make_pbr_metal(tint: Color, rough: float = 0.38, metal: float = 0.78, uv_scale: float = 0.28) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.albedo_texture = TEX_IRON_DIFF
	mat.normal_enabled = true
	mat.normal_texture = TEX_IRON_NOR
	mat.normal_scale = 0.85
	mat.roughness = rough
	mat.metallic = metal
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	return mat


static func _make_cyber_billboard_mat(channel: int, col1: Color, col2: Color, bg_tex: Texture2D = null, strength: float = 2.4) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CYBER_BILLBOARD_SHADER
	mat.set_shader_parameter("channel_id", channel)
	mat.set_shader_parameter("primary_color", col1)
	mat.set_shader_parameter("secondary_color", col2)
	mat.set_shader_parameter("emission_strength", strength)
	if bg_tex:
		mat.set_shader_parameter("bg_tex", bg_tex)
		mat.set_shader_parameter("use_bg_tex", true)
	return mat


static func _tint_tree_lush_green(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for s_idx in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s_idx) as StandardMaterial3D
				if mat and mat.albedo_color.r > 0.45 and mat.albedo_color.g > 0.25:
					var green_mat := mat.duplicate() as StandardMaterial3D
					green_mat.albedo_color = Color(0.14, 0.44, 0.16)
					green_mat.roughness = 0.72
					mi.set_surface_override_material(s_idx, green_mat)
	for child in node.get_children():
		_tint_tree_lush_green(child)


static func build_city(main: Node, track_root: Node3D) -> void:
	print("CityBuilder: Constructing Unified Flagship 3D Metropolis...")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	
	var living_ctrl := LIVING_CITY_SCRIPT.new()
	living_ctrl.name = "LivingCityController"
	track_root.add_child(living_ctrl)
	living_ctrl.setup(main)
	
	_build_city_ground(main, track_root)
	_build_sidewalks_and_curbs(main, track_root)
	_build_boulevard_frontage(main, track_root, rng, living_ctrl)
	_build_secondary_skyline_grid(main, track_root, rng)
	_build_sidewalk_hardware_and_furniture(main, track_root, rng, living_ctrl)
	_build_urban_pocket_parks(main, track_root, rng, living_ctrl)
	_build_elevated_railway_sector(main, track_root, living_ctrl)
	_build_cyberpunk_skybridges_and_holoarches(main, track_root, rng, living_ctrl)
	_build_waterfront_harbor_and_smokestacks(main, track_root, rng)
	_build_neon_billboards(main, track_root, rng, living_ctrl)
	_build_urban_soundscapes(main, track_root)
	_build_city_street_grid(main, track_root, rng)
	_build_dense_crowd(main, track_root, rng)
	_build_animated_characters(main, track_root, living_ctrl, rng)
	_purge_carriageway_intrusions(main, track_root)
	print("CityBuilder: Neo-Veridia // Sector-9 Cyberpunk Metropolis fully operational!")


## Clearance pass: removes any static box prop that stands inside the carriageway at car height
## (its footprint comes within the road half-width of the centreline, and it is not purely overhead).
## The collider and its matching mesh are removed together so no invisible walls or floating props are left.
static func _purge_carriageway_intrusions(main: Node, track_root: Node3D) -> void:
	if not main.has_method("_sample_circuit_points"):
		return
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var limit: float = road_half - 1.0
	var limit_sq: float = limit * limit
	var pts: PackedVector3Array = main.call("_sample_circuit_points", 4.0)
	var removed := 0
	var doomed: Array[Node] = []
	for body in track_root.get_children():
		if not (body is StaticBody3D):
			continue
		var shape_node: CollisionShape3D = null
		for c in body.get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
				shape_node = c
				break
		if shape_node == null:
			continue
		var he: Vector3 = ((shape_node.shape) as BoxShape3D).size * 0.5
		var gt: Transform3D = (body as Node3D).global_transform * shape_node.transform
		var box_top: float = gt.origin.y + he.y
		if gt.origin.y - he.y > 1.5 and box_top > 3.5:
			continue # overhead only (overpass deck, skybridge, canopy): the car passes underneath
		var intrudes := false
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var corner: Vector3 = gt * Vector3(sx * he.x, 0.0, sz * he.z)
				for cp in pts:
					var dx: float = cp.x - corner.x
					var dz: float = cp.z - corner.z
					if dx * dx + dz * dz < limit_sq:
						intrudes = true
						break
				if intrudes:
					break
			if intrudes:
				break
		if not intrudes:
			continue
		doomed.append(body)
		for m in track_root.get_children():
			if m is MeshInstance3D and (m as Node3D).global_position.distance_to((body as Node3D).global_position) < 0.02:
				doomed.append(m)
		removed += 1
	for n in doomed:
		n.queue_free()
	print("CityBuilder: cleared %d prop(s) from the carriageway" % removed)


## Layer 1A: 2K Photo-Scanned Tarred Gravel City Ground Plaza
static func _build_city_ground(_main: Node, track_root: Node3D) -> void:
	var ground_size: float = 3800.0
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(ground_size, ground_size)
	
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.45, 0.46, 0.48)
	ground_mat.albedo_texture = TEX_GRAVEL_DIFF
	ground_mat.normal_enabled = true
	ground_mat.normal_texture = TEX_GRAVEL_NOR
	ground_mat.roughness_texture = TEX_GRAVEL_ROUGH
	ground_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	ground_mat.uv1_triplanar = true
	ground_mat.uv1_world_triplanar = true
	ground_mat.uv1_scale = Vector3(0.22, 0.22, 0.22)
	ground_mesh.material = ground_mat
	
	var ground_inst := MeshInstance3D.new()
	ground_inst.name = "CityGroundMesh"
	ground_inst.mesh = ground_mesh
	ground_inst.position = Vector3(0.0, 0.0, 0.0)
	track_root.add_child(ground_inst)
	
	var body := StaticBody3D.new()
	body.name = "CityGround"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ground_size, 0.4, ground_size)
	col.shape = box
	col.position = Vector3(0.0, -0.2, 0.0)
	body.add_child(col)
	track_root.add_child(body)


## Layer 1B: 2K Photo-Scanned Rectangular Concrete Paver Sidewalks, Granite Curbs & Outer Urban Plaza Apron
static func _build_sidewalks_and_curbs(main: Node, track_root: Node3D) -> void:
	var sidewalk_width: float = 4.5
	var plaza_width: float = 26.0
	var curb_height: float = 0.18
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var road_h: float = float(main.get("ROAD_HEIGHT"))
	var track_path: Node = main.get("track_path")
	
	var sidewalk_mat := StandardMaterial3D.new()
	sidewalk_mat.albedo_color = Color(0.76, 0.78, 0.82)
	sidewalk_mat.albedo_texture = TEX_PAVING_DIFF
	sidewalk_mat.normal_enabled = true
	sidewalk_mat.normal_texture = TEX_PAVING_NOR
	sidewalk_mat.roughness_texture = TEX_PAVING_ROUGH
	sidewalk_mat.roughness = 0.58
	sidewalk_mat.clearcoat_enabled = true
	sidewalk_mat.clearcoat = 0.26
	sidewalk_mat.clearcoat_roughness = 0.22
	sidewalk_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	sidewalk_mat.uv1_triplanar = true
	sidewalk_mat.uv1_world_triplanar = true
	sidewalk_mat.uv1_scale = Vector3(0.35, 0.35, 0.35)
	
	var plaza_mat := _make_pbr_concrete(Color(0.54, 0.56, 0.60), 0.65, 0.14, 0.28)
	
	for side in [-1.0, 1.0]:
		var in_x: float = side * road_half
		var out_x: float = side * (road_half + sidewalk_width)
		var far_x: float = side * (road_half + sidewalk_width + plaza_width)
		
		var sw_poly := PackedVector2Array([
			Vector2(in_x, road_h),
			Vector2(in_x, road_h + curb_height),
			Vector2(out_x, road_h + curb_height),
			Vector2(out_x, 0.0)
		])
		if side < 0:
			sw_poly.reverse()
			
		var sw_strip := CSGPolygon3D.new()
		sw_strip.name = "SidewalkStrip_%s" % ("L" if side > 0 else "R")
		sw_strip.polygon = sw_poly
		sw_strip.mode = CSGPolygon3D.MODE_PATH
		sw_strip.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
		sw_strip.path_interval = 2.0
		sw_strip.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
		sw_strip.smooth_faces = true
		sw_strip.material = sidewalk_mat
		sw_strip.use_collision = false # cars can cross the kerb onto the city street grid
		track_root.add_child(sw_strip)
		if track_path:
			sw_strip.path_node = sw_strip.get_path_to(track_path)
			
		# Outer Urban Slate Plaza Apron flush with sidewalk top (road_h + curb_height) so building setbacks, alleys & promenades have seamless paving
		var sw_h: float = road_h + curb_height
		var pz_poly := PackedVector2Array([
			Vector2(out_x, 0.0),
			Vector2(out_x, sw_h),
			Vector2(far_x, sw_h),
			Vector2(far_x, 0.0)
		])
		if side < 0:
			pz_poly.reverse()
		var pz_strip := CSGPolygon3D.new()
		pz_strip.name = "UrbanPlazaApron_%s" % ("L" if side > 0 else "R")
		pz_strip.polygon = pz_poly
		pz_strip.mode = CSGPolygon3D.MODE_PATH
		pz_strip.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
		pz_strip.path_interval = 4.0
		pz_strip.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
		pz_strip.smooth_faces = true
		pz_strip.material = plaza_mat
		track_root.add_child(pz_strip)
		if track_path:
			pz_strip.path_node = pz_strip.get_path_to(track_path)


## Layer 4 & 6: Unified 4-Sector Boulevard Frontage & Service Alleys
static func _build_boulevard_frontage(main: Node, track_root: Node3D, rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var glass_materials := _init_glass_materials()
	var brick_materials := _init_brick_materials()
	var residential_materials := _init_residential_materials()
	var industrial_materials := _init_industrial_materials()
	
	var podium_mat := _make_pbr_concrete(Color(0.46, 0.48, 0.52), 0.62, 0.18)
	var iron_mat := _make_pbr_metal(Color(0.24, 0.26, 0.28), 0.35, 0.88)
	
	var beacon_mat := StandardMaterial3D.new()
	beacon_mat.albedo_color = Color(1.0, 0.08, 0.08)
	beacon_mat.emission_enabled = true
	beacon_mat.emission = Color(1.0, 0.08, 0.08)
	beacon_mat.emission_energy_multiplier = 4.0
	
	var canopy_mat := StandardMaterial3D.new()
	canopy_mat.albedo_color = Color(0.2, 0.3, 0.45, 0.6)
	canopy_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	canopy_mat.roughness = 0.1
	canopy_mat.metallic = 0.95

	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var sidewalk_w: float = 4.5
	var track_len: float = float(main.get("track_length"))
	
	var block_spacing: float = 38.0
	var b_width: float = 28.0 # along road tangent
	var b_depth: float = 22.0 # perpendicular to road
	var half_w: float = b_width * 0.5
	var half_d: float = b_depth * 0.5
	var min_frontage_clearance: float = road_half + sidewalk_w - 0.25 # 15.75m
	var placed_frontage_aabbs: Array[AABB] = []
	
	var o: float = 19.0
	var building_idx: int = 0
	var last_high_bridge_o: float = -999.0
	
	var sky_deck_mat := _make_pbr_concrete(Color(0.42, 0.44, 0.48), 0.62, 0.22)
	var sky_truss_mat := _make_pbr_metal(Color(0.22, 0.25, 0.30), 0.30, 0.85)
	
	while o < track_len - 25.0:
		var xform: Transform3D = main.call("_track_transform", o, 0.0)
		var sector_prog: float = o / track_len
		var left_tower_h: float = 0.0
		var right_tower_h: float = 0.0
		
		for side in [-1.0, 1.0]:
			var center_lat: float = side * (road_half + sidewalk_w + half_d)
			var b_center: Vector3 = xform * Vector3(center_lat, 0.0, 0.0)
			
			# Verify all 9 footprint points clear the road + sidewalk across curves
			var clears_corridor: bool = true
			for dx in [-half_d, 0.0, half_d]:
				for dz in [-half_w, 0.0, half_w]:
					var test_pt: Vector3 = xform * Vector3(center_lat + dx, 0.0, dz)
					if float(main.call("_distance_to_track", test_pt.x, test_pt.z)) < min_frontage_clearance:
						clears_corridor = false
						break
				if not clears_corridor:
					break
			if not clears_corridor:
				continue
				
			# Prevent frontage building overlaps on tight inside corners
			var foot_r: float = maxf(half_w, half_d) * 0.82
			var f_aabb := AABB(Vector3(b_center.x - foot_r, 0.0, b_center.z - foot_r), Vector3(foot_r * 2.0, 160.0, foot_r * 2.0))
			var overlaps_frontage: bool = false
			for ex in placed_frontage_aabbs:
				if ex.intersects(f_aabb):
					overlaps_frontage = true
					break
			if overlaps_frontage:
				continue
			placed_frontage_aabbs.append(f_aabb)
			
			# Right-Side (-X) Waterfront Quayside Commercial Pavilion at o = 19m before opening into the Harbor Basin (o = 48..310m)
			if side < 0.0 and absf(o - 19.0) < 5.0:
				var q_mat: ShaderMaterial = glass_materials[0]
				_build_waterfront_quayside_pavilion(track_root, xform, o, center_lat, b_width, b_depth, q_mat, side, building_idx, rng, living_ctrl)
				building_idx += 1
				continue
			if side < 0.0 and (o >= 48.0 and o <= 310.0):
				continue

			# Landmark Sculptural Exoskeleton Spire at center-left of Sector 1 vista (o = 133m) & Sector 2 (o = 1145m)
			if side > 0.0 and (absf(o - 133.0) < 5.0 or absf(o - 1145.0) < 5.0):
				var spire_mat: ShaderMaterial = glass_materials[0]
				_build_landmark_exoskeleton_spire(track_root, xform, o, center_lat, b_width, b_depth, 210.0, spire_mat, iron_mat, beacon_mat, side, building_idx, rng, living_ctrl)
				left_tower_h = 210.0
				building_idx += 1
				continue

			# 4 Unified Urban Sectors along the single Metropolis Grand Circuit
			var archetype: int = Archetype.CORPORATE_HIGHRISE
			var roll: float = rng.randf()
			if sector_prog < 0.34: # Sector 1: 100% Futuristic Corporate Core (zero brick warehouses at start vista)
				archetype = Archetype.CORPORATE_HIGHRISE
			elif sector_prog < 0.56: # Sector 2: Neon Entertainment Strip
				archetype = Archetype.RESIDENTIAL_MEGABLOCK if roll < 0.52 else Archetype.CORPORATE_HIGHRISE
			elif sector_prog < 0.78: # Sector 3: Historic Brick & El-Train District
				archetype = Archetype.HISTORIC_BRICK if roll < 0.65 else Archetype.RESIDENTIAL_MEGABLOCK
			else: # Sector 4: Industrial Logistics & Harbor Approach
				archetype = Archetype.INDUSTRIAL_LOGISTICS if roll < 0.55 else Archetype.CORPORATE_HIGHRISE
				
			var b_height: float = 0.0
			match archetype:
				Archetype.CORPORATE_HIGHRISE:
					b_height = rng.randf_range(105.0, 175.0) if sector_prog < 0.34 else rng.randf_range(78.0, 135.0)
					var chosen_mat: ShaderMaterial = glass_materials[rng.randi() % glass_materials.size()]
					_build_frontage_highrise(track_root, xform, o, center_lat, b_width, b_depth, b_height, chosen_mat, podium_mat, iron_mat, beacon_mat, canopy_mat, side, building_idx, rng, living_ctrl)
				Archetype.RESIDENTIAL_MEGABLOCK:
					b_height = rng.randf_range(38.0, 68.0)
					var chosen_mat: ShaderMaterial = residential_materials[rng.randi() % residential_materials.size()]
					_build_frontage_residential(track_root, xform, o, center_lat, b_width, b_depth, b_height, chosen_mat, iron_mat, podium_mat, side, building_idx, rng, living_ctrl)
				Archetype.HISTORIC_BRICK:
					b_height = rng.randf_range(26.0, 48.0)
					var chosen_mat: ShaderMaterial = brick_materials[rng.randi() % brick_materials.size()]
					_build_frontage_brick(track_root, xform, o, center_lat, b_width, b_depth, b_height, chosen_mat, iron_mat, side, building_idx, rng, living_ctrl)
				Archetype.INDUSTRIAL_LOGISTICS:
					b_height = rng.randf_range(16.0, 24.0)
					var chosen_mat: ShaderMaterial = industrial_materials[rng.randi() % industrial_materials.size()]
					_build_frontage_industrial(track_root, xform, o, center_lat, b_width, b_depth, b_height, chosen_mat, iron_mat, side, building_idx, rng, living_ctrl)

			if side > 0.0:
				left_tower_h = b_height
			else:
				right_tower_h = b_height
			building_idx += 1
			
		# Spawn High-Altitude Brutalist Megatower Skybridge ONLY when BOTH left and right towers were placed at this exact offset with height >= 68m!
		if left_tower_h >= 68.0 and right_tower_h >= 68.0 and (o - last_high_bridge_o) >= 180.0:
			var hy: float = 46.0 if int(o) % 2 == 0 else 52.0
			var high_span: float = (road_half + sidewalk_w + half_d) * 2.0
			var portal_lat: float = road_half + sidewalk_w + 1.2
			main.call("_add_prop", Vector3(high_span, 2.6, 4.8), xform * Vector3(0.0, hy, 0.0), xform.basis, sky_deck_mat)
			main.call("_add_prop", Vector3(high_span, 0.50, 5.2), xform * Vector3(0.0, hy - 1.4, 0.0), xform.basis, sky_truss_mat)
			main.call("_add_prop", Vector3(high_span, 0.50, 5.2), xform * Vector3(0.0, hy + 1.4, 0.0), xform.basis, sky_truss_mat)
			for p_side in [-1.0, 1.0]:
				main.call("_add_prop", Vector3(3.6, 4.4, 6.4), xform * Vector3(p_side * portal_lat, hy, 0.0), xform.basis, sky_truss_mat)
			last_high_bridge_o = o
			
		# Structured Service Alley between adjacent frontage buildings (equipped with Poly Haven 3D clutter)
		var alley_o: float = o + block_spacing * 0.5
		if alley_o < track_len - 25.0:
			var axform: Transform3D = main.call("_track_transform", alley_o, 0.0)
			for aside in [-1.0, 1.0]:
				var alley_lat: float = aside * (road_half + sidewalk_w + 3.8)
				var alley_pt: Vector3 = axform * Vector3(alley_lat, 0.0, 0.0)
				if float(main.call("_distance_to_track", alley_pt.x, alley_pt.z)) < min_frontage_clearance + 1.5:
					continue
				
				# Commercial Dumpster (closed / open) + Photo-Scanned Metal Trash Can & Trash Bags grounded on plaza apron
				var alley_sw_h: float = float(main.get("ROAD_HEIGHT")) + 0.18
				var is_open: bool = (int(alley_o) % 76 < 38)
				_spawn_model(track_root, MODEL_DUMPSTER_OPEN if is_open else MODEL_DUMPSTER, axform, Vector3(alley_lat, alley_sw_h, 0.0), 2.5, 90.0 if aside < 0 else -90.0)
				_spawn_model(track_root, PH_METAL_TRASHCAN, axform, Vector3(alley_lat, alley_sw_h, -1.8), 1.0, 90.0 if aside < 0 else -90.0)
				_spawn_model(track_root, PH_TRASHBAG, axform, Vector3(alley_lat - aside * 0.7, alley_sw_h, -1.2), 1.0, rng.randf_range(0.0, 360.0))
				
				# 3-High Stack of GMA Wooden Transport Pallets
				for pi in 3:
					_spawn_model(track_root, MODEL_PALLET, axform, Vector3(aside * (road_half + sidewalk_w + 5.5), alley_sw_h + float(pi) * 0.16, 2.0), 1.2)
					
				# Photo-Scanned Plastic Crate, Cardboard Box, Wooden Crate & Old Tire
				_spawn_model(track_root, MODEL_CRATE, axform, Vector3(aside * (road_half + sidewalk_w + 5.5), alley_sw_h + 0.425, -2.0), 0.85)
				_spawn_model(track_root, PH_PLASTIC_CRATE, axform, Vector3(aside * (road_half + sidewalk_w + 5.5), alley_sw_h + 0.85, -2.0), 1.2, 15.0)
				_spawn_model(track_root, PH_CARDBOARD_BOX, axform, Vector3(aside * (road_half + sidewalk_w + 7.0), alley_sw_h, 0.2), 1.2, 25.0)
				_spawn_model(track_root, PH_OLD_TYRE, axform, Vector3(aside * (road_half + sidewalk_w + 6.5), alley_sw_h + 0.33, 1.4), 1.1)
				
		o += block_spacing
	print("CityBuilder: Constructed %d structured boulevard frontage buildings across 4 sectors." % building_idx)


## Helper to build open-air cafe parasol umbrella & bistro table set (matching bottom-left of reference image)
static func _add_cafe_parasol_set(track_root: Node3D, xform: Transform3D, local_pos: Vector3, canopy_col: Color) -> void:
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.20, 0.22, 0.24)
	pole_mat.metallic = 0.8
	pole_mat.roughness = 0.35
	
	var cloth_mat := StandardMaterial3D.new()
	cloth_mat.albedo_color = canopy_col
	cloth_mat.roughness = 0.85
	
	var tbl := CylinderMesh.new()
	tbl.top_radius = 0.68
	tbl.bottom_radius = 0.68
	tbl.height = 0.08
	tbl.material = cloth_mat
	var t_inst := MeshInstance3D.new()
	t_inst.mesh = tbl
	t_inst.transform = Transform3D(xform.basis, xform * (local_pos + Vector3(0.0, 0.78, 0.0)))
	track_root.add_child(t_inst)
	
	var pole := CylinderMesh.new()
	pole.top_radius = 0.04
	pole.bottom_radius = 0.04
	pole.height = 2.35
	pole.material = pole_mat
	var p_inst := MeshInstance3D.new()
	p_inst.mesh = pole
	p_inst.transform = Transform3D(xform.basis, xform * (local_pos + Vector3(0.0, 1.18, 0.0)))
	track_root.add_child(p_inst)
	
	var parasol := CylinderMesh.new()
	parasol.top_radius = 0.12
	parasol.bottom_radius = 1.45
	parasol.height = 0.55
	parasol.radial_segments = 8
	parasol.material = cloth_mat
	var u_inst := MeshInstance3D.new()
	u_inst.mesh = parasol
	u_inst.transform = Transform3D(xform.basis, xform * (local_pos + Vector3(0.0, 2.28, 0.0)))
	track_root.add_child(u_inst)


## Helper to build continuous 2nd-story elevated pedestrian balcony deck (y = 5.2m) with cafe parasols, glass balustrade & walking citizens
static func _add_second_story_balcony_deck(track_root: Node3D, xform: Transform3D, o: float, front_lat: float, w: float, side: float, _mat: Material, living_ctrl: Node3D) -> void:
	var deck_concrete := _make_pbr_concrete(Color(0.56, 0.54, 0.50), 0.58, 0.16)
	var steel_trim := _make_pbr_metal(Color(0.22, 0.25, 0.28), 0.28, 0.85)
	
	var glass_rail := StandardMaterial3D.new()
	glass_rail.albedo_color = Color(0.12, 0.28, 0.38, 0.42)
	glass_rail.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_rail.metallic = 0.85
	glass_rail.roughness = 0.12

	var deck_lat: float = front_lat - side * 1.25
	var span_z: float = w + 0.6 # Flush with building podium width so it never overhangs past sector transitions or curves
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(2.6, 0.45, span_z)
	deck_mesh.material = deck_concrete
	var deck_inst := MeshInstance3D.new()
	deck_inst.mesh = deck_mesh
	deck_inst.transform = Transform3D(xform.basis, xform * Vector3(deck_lat, 5.2, 0.0))
	track_root.add_child(deck_inst)
	
	# Smoked-Glass Balustrade & Dark-Steel Top Handrail
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(0.10, 0.95, span_z)
	rail_mesh.material = glass_rail
	var rail_inst := MeshInstance3D.new()
	rail_inst.mesh = rail_mesh
	rail_inst.transform = Transform3D(xform.basis, xform * Vector3(front_lat - side * 2.45, 5.90, 0.0))
	track_root.add_child(rail_inst)
	
	var top_bar := BoxMesh.new()
	top_bar.size = Vector3(0.18, 0.10, span_z)
	top_bar.material = steel_trim
	var tb_inst := MeshInstance3D.new()
	tb_inst.mesh = top_bar
	tb_inst.transform = Transform3D(xform.basis, xform * Vector3(front_lat - side * 2.45, 6.42, 0.0))
	track_root.add_child(tb_inst)
	
	# Open-Air Cafe Parasol Umbrellas on both the 2nd-story terrace (y = 5.425m) and ground promenade (y = 0.40m)
	var umbrella_colors: Array[Color] = [
		Color(0.88, 0.84, 0.74), # Warm Cream
		Color(0.22, 0.36, 0.30), # Forest Sage
		Color(0.24, 0.34, 0.44)  # Slate Blue
	]
	var ucol: Color = umbrella_colors[int(o) % umbrella_colors.size()]
	_add_cafe_parasol_set(track_root, xform, Vector3(deck_lat + side * 0.25, 5.425, -8.5), ucol)
	_add_cafe_parasol_set(track_root, xform, Vector3(deck_lat + side * 0.25, 5.425, 8.5), ucol)
	_add_cafe_parasol_set(track_root, xform, Vector3(front_lat - side * 1.1, 0.40, -7.0), umbrella_colors[(int(o) + 1) % umbrella_colors.size()])
	_add_cafe_parasol_set(track_root, xform, Vector3(front_lat - side * 1.1, 0.40, 7.0), umbrella_colors[(int(o) + 2) % umbrella_colors.size()])
	
	# Spawn 3 Animated 2nd-Story Terrace Citizens walking back and forth along the continuous balcony promenade
	var ped_models: Array[PackedScene] = [HD_PED_CLAUDIA, HD_PED_ERIC, HD_PED_NATHAN, HD_PED_CARLA]
	for tz_idx in 3:
		var start_z: float = -10.5 + float(tz_idx) * 10.5
		var p_scn: PackedScene = ped_models[(int(o) + tz_idx) % ped_models.size()]
		var t_dir: float = 1.0 if (tz_idx % 2 == 0) else -1.0
		var p_node := _spawn_model(track_root, p_scn, xform, Vector3(deck_lat, 5.425, start_z), 0.0095, 0.0 if t_dir > 0 else 180.0)
		if p_node and living_ctrl:
			living_ctrl.call("register_pedestrian", p_node, o, deck_lat, 1.35 + float(tz_idx) * 0.18, t_dir, 0.0095, float(tz_idx) * 1.7, 4, 5.425, span_z * 0.46, start_z)


## Low 2-Story Waterfront Quayside Commercial Pavilion on Right Side (-X, o = 19m) opening onto the Harbor Basin
static func _build_waterfront_quayside_pavilion(track_root: Node3D, xform: Transform3D, o: float, lat: float, w: float, d: float, glass_mat: ShaderMaterial, side: float, _count: int, rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var pav_h: float = 7.4
	var front_lat: float = lat - side * (d * 0.5)
	var exo_concrete := StandardMaterial3D.new()
	exo_concrete.albedo_color = Color(0.46, 0.44, 0.40)
	exo_concrete.roughness = 0.55
	
	var pod_mesh := BoxMesh.new()
	pod_mesh.size = Vector3(d, pav_h, w)
	pod_mesh.material = glass_mat
	var pod_inst := MeshInstance3D.new()
	pod_inst.mesh = pod_mesh
	pod_inst.transform = Transform3D(xform.basis, xform * Vector3(lat, pav_h * 0.5, 0.0))
	track_root.add_child(pod_inst)
	
	_add_second_story_balcony_deck(track_root, xform, o, front_lat, w, side, exo_concrete, living_ctrl)
	
	# Lush Emerald-Green Rooftop Garden & Flush Street-Facing Cyan LED Billboard on the Quayside Pavilion
	for z_g in [-w * 0.30, 0.0, w * 0.30]:
		_spawn_model(track_root, MODEL_TREE_LARGE, xform, Vector3(front_lat - side * 0.2, pav_h, z_g), 2.1, rng.randf_range(0.0, 360.0))
		_spawn_model(track_root, PH_SHRUB, xform, Vector3(front_lat - side * 0.8, pav_h + 0.1, z_g * 0.7), 0.35, 45.0)
	
	var cyan_led := _make_cyber_billboard_mat(0, Color(0.0, 0.95, 0.88), Color(0.15, 0.55, 1.0), TEX_BILLBOARD_SUPERCAR, 2.2)
	var scr := QuadMesh.new()
	scr.size = Vector2(7.2, 2.1)
	scr.material = cyan_led
	var s_inst := MeshInstance3D.new()
	s_inst.mesh = scr
	var s_basis := xform.basis.rotated(xform.basis.y.normalized(), deg_to_rad(90.0 if side < 0 else -90.0))
	s_inst.transform = Transform3D(s_basis, xform * Vector3(front_lat - side * 0.16, 6.2, 4.5))
	track_root.add_child(s_inst)


## Monumental 210m Sculptural Brutalist Exoskeleton Spire (matching the centerpiece curved-arch megatower in the reference image!)
static func _build_landmark_exoskeleton_spire(track_root: Node3D, xform: Transform3D, o: float, lat: float, w: float, d: float, total_h: float, glass_mat: ShaderMaterial, iron_mat: StandardMaterial3D, beacon_mat: StandardMaterial3D, side: float, count: int, rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	# Build base highrise + stepped podium terraces first
	_build_frontage_highrise(track_root, xform, o, lat, w + 4.0, d + 4.0, total_h, glass_mat, null, iron_mat, beacon_mat, null, side, count, rng, living_ctrl)
	
	var exo_concrete := _make_pbr_concrete(Color(0.62, 0.59, 0.54), 0.50, 0.22)
	
	var front_lat: float = lat - side * (d * 0.42)
	# Sweeping Multi-Segment Parabolic Exoskeleton Arch Ribs on the -Z and Street-Facing Facades
	for arch_side in [-1.0, 1.0]:
		for seg in 6:
			var t0: float = float(seg) / 6.0
			var seg_y: float = 16.5 + t0 * 78.0
			var z_spread: float = lerpf(w * 0.44, w * 0.10, pow(t0, 0.75)) * arch_side
			var x_bow: float = front_lat - side * (sin(t0 * PI) * 2.8)
			var tilt_deg: float = lerpf(arch_side * 18.0, arch_side * 3.0, t0)
			
			var rib := BoxMesh.new()
			rib.size = Vector3(2.4, 15.0, 2.4)
			rib.material = exo_concrete
			var r_inst := MeshInstance3D.new()
			r_inst.mesh = rib
			var r_basis := xform.basis.rotated(xform.basis.x.normalized(), deg_to_rad(tilt_deg))
			r_inst.transform = Transform3D(r_basis, xform * Vector3(x_bow, seg_y, z_spread))
			track_root.add_child(r_inst)
			
	# Horizontal Brutalist Concrete Louver Rings every 5.0m up the Exoskeleton Core
	for ly in range(20, int(total_h - 10.0), 5):
		var ring := BoxMesh.new()
		ring.size = Vector3(d * 0.78, 0.65, w * 0.78)
		ring.material = exo_concrete
		var l_inst := MeshInstance3D.new()
		l_inst.mesh = ring
		l_inst.transform = Transform3D(xform.basis, xform * Vector3(lat, float(ly), 0.0))
		track_root.add_child(l_inst)


## Sculptural Brutalist Exoskeleton High-Rise with Stepped Botanical Terraces, 2nd-Level Pedestrian Deck & Flush LED Screens
static func _build_frontage_highrise(track_root: Node3D, xform: Transform3D, o: float, lat: float, w: float, d: float, total_h: float, glass_mat: ShaderMaterial, _podium_mat: StandardMaterial3D, iron_mat: StandardMaterial3D, beacon_mat: StandardMaterial3D, _canopy_mat: StandardMaterial3D, side: float, count: int, rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var podium_h: float = 16.5
	var tower_h: float = total_h - podium_h
	var tow_w: float = w * 0.72
	var tow_d: float = d * 0.72
	var front_lat: float = lat - side * (d * 0.5)
	var exo_concrete := _make_pbr_concrete(Color(0.58, 0.55, 0.50), 0.54, 0.18)
	
	# 1A. Stepped Brutalist Podium & 2nd-Level Elevated Pedestrian Balcony Deck (y = 5.4m)
	var pod_mesh := BoxMesh.new()
	pod_mesh.size = Vector3(d, podium_h, w)
	pod_mesh.material = glass_mat
	var pod_inst := MeshInstance3D.new()
	pod_inst.mesh = pod_mesh
	pod_inst.transform = Transform3D(xform.basis, xform * Vector3(lat, podium_h * 0.5, 0.0))
	track_root.add_child(pod_inst)
	
	var pod_body := StaticBody3D.new()
	pod_body.name = "Frontage_Podium_%d" % count
	var pod_col := CollisionShape3D.new()
	var pod_box := BoxShape3D.new()
	pod_box.size = Vector3(d, podium_h, w)
	pod_col.shape = pod_box
	pod_body.add_child(pod_col)
	pod_body.transform = pod_inst.transform
	track_root.add_child(pod_body)
	
	# Projecting 2nd-Story Elevated Pedestrian Terrace Slab & Parapet Railing (y = 5.2m)
	_add_second_story_balcony_deck(track_root, xform, o, front_lat, w, side, exo_concrete, living_ctrl)
	
	# 1B. Stepped 3rd-Tier Botanical Terrace Ledge (y = 11.2m) & Rooftop Garden at y = 16.5m (with Lush Trees & Organic Bioluminescent Blossoms!)
	var ledge_mesh := BoxMesh.new()
	ledge_mesh.size = Vector3(3.6, 0.85, w * 0.94)
	ledge_mesh.material = exo_concrete
	var ledge_inst := MeshInstance3D.new()
	ledge_inst.mesh = ledge_mesh
	ledge_inst.transform = Transform3D(xform.basis, xform * Vector3(front_lat - side * 0.9, 11.2, 0.0))
	track_root.add_child(ledge_inst)
	
	for z_garden in [-w * 0.32, 0.0, w * 0.32]:
		_spawn_model(track_root, MODEL_TREE_LARGE, xform, Vector3(front_lat - side * 0.2, podium_h, z_garden), 2.5, rng.randf_range(0.0, 360.0))
		_spawn_model(track_root, PH_PLANTER_BOX, xform, Vector3(front_lat - side * 1.35, 11.6, z_garden * 0.85), 1.35, 90.0)
		_spawn_model(track_root, PH_SHRUB, xform, Vector3(front_lat - side * 1.35, 12.05, z_garden * 0.85), 0.42, rng.randf_range(0.0, 360.0))
		_spawn_model(track_root, PH_SHRUB, xform, Vector3(front_lat - side * 0.45, podium_h + 0.1, z_garden * 0.72), 0.45, rng.randf_range(0.0, 360.0))
		
		# Delicate Bioluminescent Blossom Clusters (0.24m radius) nestled inside the rooftop shrubs
		var bio_mat := StandardMaterial3D.new()
		var bcol: Color = [Color(0.0, 0.92, 1.0), Color(0.95, 0.22, 0.78), Color(0.58, 0.25, 1.0)][(count + int(z_garden >= 0)) % 3]
		bio_mat.albedo_color = bcol
		bio_mat.emission_enabled = true
		bio_mat.emission = bcol
		bio_mat.emission_energy_multiplier = 2.2
		var bio_blossom := SphereMesh.new()
		bio_blossom.radius = 0.24
		bio_blossom.height = 0.36
		bio_blossom.material = bio_mat
		for bl_off in [-0.35, 0.35]:
			var b_flora := MeshInstance3D.new()
			b_flora.mesh = bio_blossom
			b_flora.transform = Transform3D(xform.basis, xform * Vector3(front_lat - side * 1.48, 12.28, z_garden * 0.85 + bl_off))
			track_root.add_child(b_flora)

	# 1C. Animated Cyberpunk Digital Jumbotrons & Vertical Media Screens (using CYBER_BILLBOARD_SHADER!)
	var led_colors: Array[Color] = [Color(0.0, 0.90, 1.0), Color(0.98, 0.18, 0.78), Color(0.58, 0.25, 1.0), Color(0.15, 0.96, 0.68)]
	var led_col: Color = led_colors[count % led_colors.size()]
	var sec_col: Color = led_colors[(count + 1) % led_colors.size()]
	var bg_tex: Texture2D = TEX_BILLBOARD_SUPERCAR if (count % 2 == 0) else TEX_BILLBOARD_ARCADE
	var h_billboard_mat := _make_cyber_billboard_mat(count % 4, led_col, sec_col, bg_tex, 2.2)
	var v_billboard_mat := _make_cyber_billboard_mat((count + 1) % 4, sec_col, led_col, null, 2.4)
	var face_rot_deg: float = 90.0 if side < 0 else -90.0
	var face_basis := xform.basis.rotated(xform.basis.y.normalized(), deg_to_rad(face_rot_deg))
	
	# Street-Facing Horizontal Jumbotron on Podium Facade (7.6m wide x 3.8m tall)
	var z_screen := QuadMesh.new()
	z_screen.size = Vector2(7.6, 3.8)
	z_screen.material = h_billboard_mat
	var zs_inst := MeshInstance3D.new()
	zs_inst.mesh = z_screen
	zs_inst.transform = Transform3D(face_basis, xform * Vector3(front_lat - side * 0.16, 8.6, -5.5))
	track_root.add_child(zs_inst)
	
	# Vertical Cyberpunk Portrait & Telemetry Screen on Podium Facade (2.8m wide x 5.6m tall)
	var v_screen := QuadMesh.new()
	v_screen.size = Vector2(2.8, 5.6)
	v_screen.material = v_billboard_mat
	var vs_inst := MeshInstance3D.new()
	vs_inst.mesh = v_screen
	vs_inst.transform = Transform3D(face_basis, xform * Vector3(front_lat - side * 0.16, 13.8, 6.2))
	track_root.add_child(vs_inst)

	# Wrap-Around Angled Corner Digital Billboard on the leading (-Z) corner of the podium (matching reference image!)
	var corner_screen := QuadMesh.new()
	corner_screen.size = Vector2(4.2, 3.4)
	corner_screen.material = _make_cyber_billboard_mat((count + 2) % 4, led_col, sec_col, bg_tex, 2.3)
	var cs_inst := MeshInstance3D.new()
	cs_inst.mesh = corner_screen
	var corner_basis := xform.basis.rotated(xform.basis.y.normalized(), deg_to_rad(135.0 if side < 0 else -135.0))
	cs_inst.transform = Transform3D(corner_basis, xform * Vector3(front_lat - side * 0.25, 8.6, -w * 0.44))
	track_root.add_child(cs_inst)

	# Ground-Floor Entrance Canopies, CCTV Security Camera & Warm Terrace Light
	var awning_rot: float = 90.0 if side < 0 else -90.0
	_spawn_model(track_root, MODEL_AWNING, xform, Vector3(front_lat, 3.6, -4.5), 3.0, awning_rot)
	_spawn_model(track_root, MODEL_AWNING, xform, Vector3(front_lat, 3.6, 4.5), 3.0, awning_rot)
	_spawn_model(track_root, PH_SECURITY_CAM, xform, Vector3(front_lat - side * 0.15, 4.4, 0.0), 1.2, awning_rot)
	
	# 2. Stepped Tower Shaft with Sculptural Brutalist Exoskeleton A-Frame Buttress Ribs
	var tow_mesh := BoxMesh.new()
	tow_mesh.size = Vector3(tow_d, tower_h, tow_w)
	tow_mesh.material = glass_mat
	var tow_inst := MeshInstance3D.new()
	tow_inst.mesh = tow_mesh
	tow_inst.transform = Transform3D(xform.basis, xform * Vector3(lat, podium_h + tower_h * 0.5, 0.0))
	track_root.add_child(tow_inst)
	
	var tow_body := StaticBody3D.new()
	tow_body.name = "Frontage_Tower_%d" % count
	var tow_col := CollisionShape3D.new()
	var tow_box := BoxShape3D.new()
	tow_box.size = Vector3(tow_d, tower_h, tow_w)
	tow_col.shape = tow_box
	tow_body.add_child(tow_col)
	tow_body.transform = tow_inst.transform
	track_root.add_child(tow_body)
	
	# Sculptural Brutalist Exoskeleton Vertical & Tapered A-Frame Megacolumns (matching the central tower in reference image!)
	var tow_front_lat: float = lat - side * (tow_d * 0.5)
	for rib_z in [-tow_w * 0.46, 0.0, tow_w * 0.46]:
		var rib_mesh := BoxMesh.new()
		rib_mesh.size = Vector3(1.5, tower_h, 1.6)
		rib_mesh.material = exo_concrete
		var rib_inst := MeshInstance3D.new()
		rib_inst.mesh = rib_mesh
		rib_inst.transform = Transform3D(xform.basis, xform * Vector3(tow_front_lat, podium_h + tower_h * 0.5, rib_z))
		track_root.add_child(rib_inst)
		
	# Angled A-Frame Exoskeleton Arch Struts & Sweeping Parabolic Ribs on the street-facing base of the tower shaft
	for arch_sign in [-1.0, 1.0]:
		var strut_mesh := BoxMesh.new()
		strut_mesh.size = Vector3(1.8, 36.0, 1.8)
		strut_mesh.material = exo_concrete
		var s_inst := MeshInstance3D.new()
		s_inst.mesh = strut_mesh
		var s_basis := xform.basis.rotated(xform.basis.x.normalized(), deg_to_rad(arch_sign * 14.0))
		s_inst.transform = Transform3D(s_basis, xform * Vector3(tow_front_lat, podium_h + 15.0, arch_sign * (tow_w * 0.28)))
		track_root.add_child(s_inst)
		
		# Sweeping Upper Parabolic Exoskeleton Ribs on every second tower (matching the reference skyline!)
		if count % 2 == 0 and total_h > 90.0:
			for seg in 4:
				var t0: float = float(seg) / 4.0
				var seg_y: float = 32.0 + t0 * (total_h - 46.0)
				var z_sp: float = lerpf(tow_w * 0.42, tow_w * 0.14, t0) * arch_sign
				var tilt_d: float = lerpf(arch_sign * 12.0, arch_sign * 2.5, t0)
				var u_rib := BoxMesh.new()
				u_rib.size = Vector3(1.9, (total_h - 46.0) * 0.28, 1.9)
				u_rib.material = exo_concrete
				var ur_inst := MeshInstance3D.new()
				ur_inst.mesh = u_rib
				var ur_basis := xform.basis.rotated(xform.basis.x.normalized(), deg_to_rad(tilt_d))
				ur_inst.transform = Transform3D(ur_basis, xform * Vector3(tow_front_lat - side * 0.4, seg_y, z_sp))
				track_root.add_child(ur_inst)
		
	# Upper Sky-Garden Setback Ledge at y = 44m with Lush Green Rooftop Trees
	if total_h > 65.0:
		var sky_ledge := BoxMesh.new()
		sky_ledge.size = Vector3(tow_d + 2.8, 1.2, tow_w + 2.4)
		sky_ledge.material = exo_concrete
		var sl_inst := MeshInstance3D.new()
		sl_inst.mesh = sky_ledge
		sl_inst.transform = Transform3D(xform.basis, xform * Vector3(lat, 44.0, 0.0))
		track_root.add_child(sl_inst)
		_spawn_model(track_root, MODEL_TREE_LARGE, xform, Vector3(tow_front_lat, 44.6, -4.0), 2.2, 45.0)
		_spawn_model(track_root, MODEL_TREE_LARGE, xform, Vector3(tow_front_lat, 44.6, 4.0), 2.2, 165.0)
	
	# 3. Rooftop Crown & Antenna Dish
	var pent_w: float = tow_w * 0.5
	var pent_d: float = tow_d * 0.5
	var pent_h: float = 8.0
	var pent_mesh := BoxMesh.new()
	pent_mesh.size = Vector3(pent_d, pent_h, pent_w)
	pent_mesh.material = exo_concrete
	var pent_inst := MeshInstance3D.new()
	pent_inst.mesh = pent_mesh
	pent_inst.transform = Transform3D(xform.basis, xform * Vector3(lat, total_h + pent_h * 0.5, 0.0))
	track_root.add_child(pent_inst)
	_spawn_model(track_root, MODEL_TREE_LARGE, xform, Vector3(lat, total_h, -4.5), 2.5, 0.0)
	_spawn_model(track_root, MODEL_ANTENNA_DISH, xform, Vector3(lat - side * (pent_d * 0.3), total_h + pent_h + 1.15, 0.0), 3.2, 120.0)
	
	# Aviation Warning Beacon Spire
	if total_h > 80.0:
		var spire_mesh := CylinderMesh.new()
		spire_mesh.top_radius = 0.15
		spire_mesh.bottom_radius = 0.65
		spire_mesh.height = 22.0
		spire_mesh.material = iron_mat
		var spire_inst := MeshInstance3D.new()
		spire_inst.mesh = spire_mesh
		spire_inst.transform = Transform3D(xform.basis, xform * Vector3(lat, total_h + pent_h + 11.0, 0.0))
		track_root.add_child(spire_inst)
		
		var beacon := MeshInstance3D.new()
		var b_sphere := SphereMesh.new()
		b_sphere.radius = 0.5
		b_sphere.height = 1.0
		b_sphere.material = beacon_mat
		beacon.mesh = b_sphere
		beacon.transform = Transform3D(xform.basis, xform * Vector3(lat, total_h + pent_h + 22.0, 0.0))
		track_root.add_child(beacon)


## Residential & Commercial Megablock with 3D Neon Blade Signs, Balconies & Photo-Scanned Aircon Units
static func _build_frontage_residential(track_root: Node3D, xform: Transform3D, o: float, lat: float, w: float, d: float, height: float, res_mat: ShaderMaterial, _iron_mat: StandardMaterial3D, podium_mat: StandardMaterial3D, side: float, count: int, _rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(d, height, w)
	mesh.material = res_mat
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.transform = Transform3D(xform.basis, xform * Vector3(lat, height * 0.5, 0.0))
	track_root.add_child(inst)
	
	var body := StaticBody3D.new()
	body.name = "Frontage_Residential_%d" % count
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(d, height, w)
	col.shape = box
	body.add_child(col)
	body.transform = inst.transform
	track_root.add_child(body)
	
	# Street-Facing 2nd-Story Pedestrian Balcony Deck + 3D Balconies & Projecting 3D Neon Street Signs
	var front_lat: float = lat - side * (d * 0.5)
	_add_second_story_balcony_deck(track_root, xform, o, front_lat, w, side, podium_mat, living_ctrl)
	var rot_y: float = 90.0 if side < 0 else -90.0
	var stories: int = int(height / 4.5)
	for s in range(2, min(stories, 8), 2):
		var by: float = float(s) * 4.5
		for z_off in [-w * 0.25, w * 0.25]:
			_spawn_model(track_root, MODEL_BALCONY, xform, Vector3(front_lat, by, z_off), 3.0, rot_y)
			_spawn_model(track_root, PH_AIRCON_UNIT, xform, Vector3(front_lat - side * 0.2, by + 1.1, z_off + 2.4), 0.85, rot_y)
			
	# Projecting 3D Neon Signs on facade at y = 6.5m and y = 12.0m
	_spawn_model(track_root, HD_NEON_STREET, xform, Vector3(front_lat - side * 0.45, 6.5, -4.0), 3.2, 0.0 if side > 0 else 180.0)
	_spawn_model(track_root, HD_NEON_VERTICAL, xform, Vector3(front_lat - side * 0.85, 11.5, 4.5), 0.065, 90.0 if side < 0 else -90.0)
	
	# Rooftop Elevator Machine Penthouse
	var pent_mesh := BoxMesh.new()
	pent_mesh.size = Vector3(6.5, 4.2, 5.5)
	pent_mesh.material = podium_mat
	var pent_inst := MeshInstance3D.new()
	pent_inst.mesh = pent_mesh
	pent_inst.transform = Transform3D(xform.basis, xform * Vector3(lat, height + 2.1, 0.0))
	track_root.add_child(pent_inst)


## Historic 2K PBR Brick Warehouse with 3D Iron Fire Escape, Rollershutter Door & Rooftop Water Tower
static func _build_frontage_brick(track_root: Node3D, xform: Transform3D, o: float, lat: float, w: float, d: float, height: float, brick_mat: ShaderMaterial, iron_mat: StandardMaterial3D, side: float, count: int, _rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(d, height, w)
	mesh.material = brick_mat
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.transform = Transform3D(xform.basis, xform * Vector3(lat, height * 0.5, 0.0))
	track_root.add_child(inst)
	
	var body := StaticBody3D.new()
	body.name = "Frontage_Brick_%d" % count
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(d, height, w)
	col.shape = box
	body.add_child(col)
	body.transform = inst.transform
	track_root.add_child(body)
	
	# Rooftop 3D Water Tower on Stilts
	_spawn_model(track_root, MODEL_WATER_TANK, xform, Vector3(lat, height + 2.28, 0.0), 5.5)
	
	# Front Facade Hardware: 2nd-Story Pedestrian Balcony Deck, Rollershutter Door, Iron Fire Escape & Wall Security Light
	var front_lat: float = lat - side * (d * 0.5)
	_add_second_story_balcony_deck(track_root, xform, o, front_lat, w, side, iron_mat, living_ctrl)
	var rot_y: float = 90.0 if side < 0 else -90.0
	_spawn_model(track_root, MODEL_AWNING, xform, Vector3(front_lat, 3.6, -5.0), 3.0, rot_y)
	_spawn_model(track_root, PH_ROLLERSHUTTER, xform, Vector3(front_lat - side * 0.08, 0.40, 4.5), 1.1, rot_y)
	_spawn_model(track_root, PH_SECURITY_LIGHT, xform, Vector3(front_lat - side * 0.15, 3.4, 4.5), 1.0, rot_y)
	if height >= 24.0:
		_spawn_model(track_root, PH_FIRE_ESCAPE, xform, Vector3(front_lat - side * 0.95, 7.8, -1.5), 0.95, rot_y)
		# Living Tenement Details: Potted plants, blooming jasmine shrubs & bicycles on the fire-escape landings
		_spawn_model(track_root, PH_PLANTER_BOX, xform, Vector3(front_lat - side * 1.05, 5.2, -0.8), 0.75, rot_y)
		_spawn_model(track_root, PH_SHRUB, xform, Vector3(front_lat - side * 1.05, 5.5, -0.8), 0.18, rot_y)
		_spawn_model(track_root, HD_BICYCLE, xform, Vector3(front_lat - side * 0.95, 8.2, -2.1), 0.20, rot_y)


## Industrial 2K PBR Corrugated Steel Logistics Depot with Utility Boxes & Jersey Barriers
static func _build_frontage_industrial(track_root: Node3D, xform: Transform3D, o: float, lat: float, w: float, d: float, height: float, ind_mat: ShaderMaterial, iron_mat: StandardMaterial3D, side: float, count: int, _rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(d, height, w)
	mesh.material = ind_mat
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.transform = Transform3D(xform.basis, xform * Vector3(lat, height * 0.5, 0.0))
	track_root.add_child(inst)
	
	var body := StaticBody3D.new()
	body.name = "Frontage_Industrial_%d" % count
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(d, height, w)
	col.shape = box
	body.add_child(col)
	body.transform = inst.transform
	track_root.add_child(body)
	
	var front_lat: float = lat - side * (d * 0.5)
	_add_second_story_balcony_deck(track_root, xform, o, front_lat, w, side, iron_mat, living_ctrl)
	var rot_y: float = 90.0 if side < 0 else -90.0
	_spawn_model(track_root, PH_UTILITY_BOX_2, xform, Vector3(front_lat - side * 0.25, 0.40, -6.0), 1.1, rot_y)
	_spawn_model(track_root, PH_AIRCON_UNIT, xform, Vector3(front_lat - side * 0.25, 3.8, 6.0), 1.0, rot_y)


## Layer 5: Non-Overlapping Background Skyline Grid
static func _build_secondary_skyline_grid(main: Node, track_root: Node3D, rng: RandomNumberGenerator) -> void:
	var glass_materials := _init_glass_materials()
	var grid_step: float = 52.0
	var bmin: Vector2 = main.get("_track_bounds_min")
	var bmax: Vector2 = main.get("_track_bounds_max")
	var max_ext: float = maxf(maxf(absf(bmin.x), absf(bmax.x)), maxf(absf(bmin.y), absf(bmax.y)))
	var city_radius: float = clampf(max_ext + 140.0, 520.0, 820.0)
	var min_track_dist: float = 58.0
	
	var placed_aabbs: Array[AABB] = []
	var bg_count: int = 0
	var h_pos_1: Vector3 = (main.call("_track_transform", 185.0, 0.0) as Transform3D) * Vector3(-50.0, 0.0, 0.0)
	var h_pos_2: Vector3 = (main.call("_track_transform", 2300.0, 0.0) as Transform3D) * Vector3(-50.0, 0.0, 0.0)
	
	for gx in range(-int(city_radius), int(city_radius), int(grid_step)):
		for gz in range(-int(city_radius), int(city_radius), int(grid_step)):
			var bx: float = float(gx) + rng.randf_range(-2.0, 2.0)
			var bz: float = float(gz) + rng.randf_range(-2.0, 2.0)
			
			var dist_to_road: float = float(main.call("_distance_to_track", bx, bz))
			if dist_to_road < min_track_dist:
				continue
			if Vector2(bx - h_pos_1.x, bz - h_pos_1.z).length() < 95.0 or Vector2(bx - h_pos_2.x, bz - h_pos_2.z).length() < 95.0:
				continue
				
			var dist_to_center: float = Vector2(bx, bz).length()
			var bw: float = rng.randf_range(28.0, 38.0)
			var bd: float = rng.randf_range(28.0, 38.0)
			var bh: float = 0.0
			
			if dist_to_center < 160.0:
				bh = rng.randf_range(95.0, 185.0)
			elif dist_to_center < 300.0:
				bh = rng.randf_range(65.0, 130.0)
			else:
				bh = rng.randf_range(40.0, 85.0)
				
			var candidate_aabb := AABB(Vector3(bx - bw * 0.5 - 4.0, 0.0, bz - bd * 0.5 - 4.0), Vector3(bw + 8.0, bh, bd + 8.0))
			var overlaps: bool = false
			for existing in placed_aabbs:
				if existing.intersects(candidate_aabb):
					overlaps = true
					break
			if overlaps:
				continue
				
			placed_aabbs.append(candidate_aabb)
			
			var chosen_mat: ShaderMaterial = glass_materials[rng.randi() % glass_materials.size()]
			var bg_exo := _make_pbr_concrete(Color(0.56, 0.54, 0.50), 0.56, 0.18)
			var base_h: float = bh * 0.72 if bh > 75.0 else bh
			var mesh := BoxMesh.new()
			mesh.size = Vector3(bw, base_h, bd)
			mesh.material = chosen_mat
			var inst := MeshInstance3D.new()
			inst.mesh = mesh
			inst.position = Vector3(bx, base_h * 0.5, bz)
			track_root.add_child(inst)
			
			# Vertical Exoskeleton Corner Columns on background towers
			for cx_s in [-0.48, 0.48]:
				var fin := BoxMesh.new()
				fin.size = Vector3(1.8, base_h, bd + 0.8)
				fin.material = bg_exo
				var f_inst := MeshInstance3D.new()
				f_inst.mesh = fin
				f_inst.position = Vector3(bx + cx_s * bw, base_h * 0.5, bz)
				track_root.add_child(f_inst)
			
			if bh > 75.0:
				# Stepped Upper Setback Tier + Brutalist Crown Collar + Twin Spires
				var top_h: float = bh - base_h
				var top_w: float = bw * 0.68
				var top_d: float = bd * 0.68
				var top_mesh := BoxMesh.new()
				top_mesh.size = Vector3(top_w, top_h, top_d)
				top_mesh.material = chosen_mat
				var t_inst := MeshInstance3D.new()
				t_inst.mesh = top_mesh
				t_inst.position = Vector3(bx, base_h + top_h * 0.5, bz)
				track_root.add_child(t_inst)
				
				var collar := BoxMesh.new()
				collar.size = Vector3(bw + 1.6, 1.8, bd + 1.6)
				collar.material = bg_exo
				var c_inst := MeshInstance3D.new()
				c_inst.mesh = collar
				c_inst.position = Vector3(bx, base_h, bz)
				track_root.add_child(c_inst)
				
				var crown := BoxMesh.new()
				crown.size = Vector3(top_w + 1.2, 2.2, top_d + 1.2)
				crown.material = bg_exo
				var cr_inst := MeshInstance3D.new()
				cr_inst.mesh = crown
				cr_inst.position = Vector3(bx, bh, bz)
				track_root.add_child(cr_inst)
				
				var spire_cyl := CylinderMesh.new()
				spire_cyl.top_radius = 0.12
				spire_cyl.bottom_radius = 0.45
				spire_cyl.height = 18.0
				spire_cyl.material = bg_exo
				var sp_inst := MeshInstance3D.new()
				sp_inst.mesh = spire_cyl
				sp_inst.position = Vector3(bx, bh + 9.0, bz)
				track_root.add_child(sp_inst)
			
			var body := StaticBody3D.new()
			body.name = "BG_Building_%d" % bg_count
			var col := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(bw, bh, bd)
			col.shape = box
			body.add_child(col)
			body.position = Vector3(bx, bh * 0.5, bz)
			track_root.add_child(body)
			
			if rng.randf() < 0.40:
				_spawn_model(track_root, MODEL_WATER_TANK, Transform3D(Basis.IDENTITY, Vector3(bx, bh + 2.28, bz)), Vector3.ZERO, 5.5)
			elif rng.randf() < 0.35:
				_spawn_model(track_root, MODEL_ANTENNA_DISH, Transform3D(Basis.IDENTITY, Vector3(bx, bh + 1.15, bz)), Vector3.ZERO, 3.2, 45.0)
				
			bg_count += 1
	print("CityBuilder: Constructed %d non-overlapping background skyline towers." % bg_count)


## Layer 2 & 3: Street Furniture, Photo-Scanned Hardware, Transit, Walking Pedestrians & Emergency Vehicles
static func _build_sidewalk_hardware_and_furniture(main: Node, track_root: Node3D, rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var grate_mat := StandardMaterial3D.new()
	grate_mat.albedo_color = Color(0.14, 0.15, 0.16)
	grate_mat.metallic = 0.85
	grate_mat.roughness = 0.5
	
	var tactile_mat := StandardMaterial3D.new()
	tactile_mat.albedo_color = Color(0.92, 0.75, 0.10)
	tactile_mat.roughness = 0.45
	
	var sign_green := StandardMaterial3D.new()
	sign_green.albedo_color = Color(0.08, 0.42, 0.18)
	sign_green.roughness = 0.3
	
	var hazard_mat := StandardMaterial3D.new()
	hazard_mat.albedo_color = Color(1.0, 0.65, 0.05)
	hazard_mat.emission_enabled = true
	hazard_mat.emission = Color(1.0, 0.65, 0.05)
	hazard_mat.emission_energy_multiplier = 4.0

	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var track_len: float = float(main.get("track_length"))
	var road_h: float = float(main.get("ROAD_HEIGHT"))
	var curb_h: float = 0.18
	var sw_h: float = road_h + curb_h # 0.40m: true top elevation of sidewalks & pedestrian promenades
	var sides: Array = [-1.0, 1.0]
	var ped_models: Array[PackedScene] = [HD_PED_CLAUDIA, HD_PED_ERIC, HD_PED_NATHAN, HD_PED_CARLA]
	
	# 1. Photo-Scanned Cast-Iron Street Lamps (PH_STREET_LAMP, 7.35m tall) every 24m
	var o_light: float = 12.0
	while o_light < track_len - 20.0:
		var xform: Transform3D = main.call("_track_transform", o_light, 0.0)
		for side in sides:
			var lat: float = side * (road_half + 1.2) # 12.7m
			var base_pos: Vector3 = xform.origin + xform.basis.x * lat
			var lamp_rot: float = -90.0 if side > 0 else 90.0
			_spawn_model(track_root, PH_STREET_LAMP, xform, Vector3(lat, sw_h, 0.0), 1.9, lamp_rot)
			
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.95, 0.88)
			light.light_energy = 2.6
			light.omni_range = 28.0
			light.omni_attenuation = 1.3
			light.distance_fade_enabled = true
			light.distance_fade_begin = 85.0
			light.distance_fade_length = 30.0
			light.position = base_pos - xform.basis.x * (side * 0.4) + Vector3.UP * (sw_h + 7.02)
			track_root.add_child(light)
		o_light += 24.0

	# 2. Large Leafy Trees in Cast-Iron Grates + Photo-Scanned Planter Boxes & Shrubs every 24m
	var o_tree: float = 24.0
	var tree_step: int = 0
	while o_tree < track_len - 20.0:
		var xform: Transform3D = main.call("_track_transform", o_tree, 0.0)
		for side in sides:
			var tlat: float = side * (road_half + 2.4) # 13.9m
			var tpos: Vector3 = xform * Vector3(tlat, 0.0, 0.0)
			
			var grate := PlaneMesh.new()
			grate.size = Vector2(1.5, 1.5)
			grate.material = grate_mat
			var g_inst := MeshInstance3D.new()
			g_inst.mesh = grate
			g_inst.transform = Transform3D(xform.basis, tpos + Vector3.UP * (sw_h + 0.005))
			track_root.add_child(g_inst)
			
			_spawn_model(track_root, MODEL_TREE_LARGE, xform, Vector3(tlat, sw_h, 0.0), 3.2, rng.randf_range(0.0, 360.0))
			
			# Alternating Planter Box with Shrub along the promenade
			if tree_step % 2 == 0:
				var plat: float = side * (road_half + 3.6)
				_spawn_model(track_root, PH_PLANTER_BOX, xform, Vector3(plat, sw_h, 5.5), 1.35, 90.0)
				_spawn_model(track_root, PH_SHRUB, xform, Vector3(plat, sw_h + 0.47, 5.5), 0.30, rng.randf_range(0.0, 360.0))
		tree_step += 1
		o_tree += 24.0

	# 3. Photo-Scanned Modular Street Seating, Park Benches, Fire Hydrants, Postboxes, Bicycles & Walking Pedestrians every 48m
	var o_bench: float = 36.0
	var bench_step: int = 0
	while o_bench < track_len - 25.0:
		var xform: Transform3D = main.call("_track_transform", o_bench, 0.0)
		for side in sides:
			var rot_y: float = 90.0 if side < 0 else -90.0
			if bench_step % 2 == 0:
				_spawn_model(track_root, PH_STREET_SEATING, xform, Vector3(side * (road_half + 3.5), sw_h, 0.0), 0.55, rot_y)
			else:
				_spawn_model(track_root, MODEL_BENCH, xform, Vector3(side * (road_half + 3.4), sw_h, 0.0), 2.5, rot_y)
			
			# Curbside Trash Can & Photo-Scanned Fire Hydrant
			_spawn_model(track_root, MODEL_TRASHCAN, xform, Vector3(side * (road_half + 1.5), sw_h, 2.8), 0.15)
			if side > 0:
				_spawn_model(track_root, PH_FIRE_HYDRANT, xform, Vector3(side * (road_half + 1.35), sw_h, -3.5), 1.0, rot_y)
			else:
				_spawn_model(track_root, HD_POSTBOX, xform, Vector3(side * (road_half + 1.55), sw_h, -3.5), 0.28, rot_y)
				
			# Parked 3D Street Bicycle, Commuter Scooter & Walking Sidewalk Pedestrians ("The Capillaries")
			if bench_step % 3 == 0 and side > 0:
				_spawn_model(track_root, HD_BICYCLE, xform, Vector3(side * (road_half + 1.8), sw_h + 0.15, 6.0), 0.24, 0.0)
			elif bench_step % 3 == 1 and side < 0:
				_spawn_model(track_root, HD_SCOOTER, xform, Vector3(side * (road_half + 1.9), sw_h, 5.5), 0.0068, 25.0)
				
			var ped_scn: PackedScene = ped_models[(bench_step + int(side > 0)) % ped_models.size()]
			var ped_lat: float = side * (road_half + 2.85)
			var ped_node := _spawn_model(track_root, ped_scn, xform, Vector3(ped_lat, sw_h, -1.8), 0.0095, 0.0 if side > 0 else 180.0)
			if ped_node and living_ctrl:
				var walk_dir: float = 1.0 if (bench_step % 2 == 0) else -1.0
				var walk_speed: float = rng.randf_range(1.25, 1.65)
				living_ctrl.call("register_pedestrian", ped_node, o_bench, ped_lat, walk_speed, walk_dir, 0.0095, rng.randf_range(0.0, 6.28), 0, sw_h)
		bench_step += 1
		o_bench += 36.0

	# 4. 3D Illuminated Beverage Vending Machines, High-Detail Bus Stop Shelters & Utility Cabinets
	var o_amenity: float = 60.0
	var amenity_flip: bool = false
	while o_amenity < track_len - 30.0:
		var xform: Transform3D = main.call("_track_transform", o_amenity, 0.0)
		var aside: float = 1.0 if amenity_flip else -1.0
		var rot_y: float = -90.0 if aside < 0 else 90.0
		
		if amenity_flip:
			# 3D Illuminated Red Beverage Vending Machine + Bottle Kiosk + Utility Box + Modern Promenade Lamp + Street Vendor AI
			_spawn_model(track_root, HD_VENDING_MACHINE, xform, Vector3(aside * (road_half + 3.8), sw_h, -1.2), 0.95, rot_y)
			_spawn_model(track_root, MODEL_VENDING_KIOSK, xform, Vector3(aside * (road_half + 3.8), sw_h, 1.2), 1.8, rot_y)
			_spawn_model(track_root, PH_UTILITY_BOX_1, xform, Vector3(aside * (road_half + 3.9), sw_h, 3.2), 1.1, rot_y)
			_spawn_model(track_root, HD_LAMP_MODERN, xform, Vector3(aside * (road_half + 3.6), sw_h, -3.5), 4.5, rot_y)
			var vendor_node := _spawn_model(track_root, HD_PED_NATHAN, xform, Vector3(aside * (road_half + 3.0), sw_h, 0.2), 0.0095, rot_y)
			if vendor_node and living_ctrl:
				living_ctrl.call("register_pedestrian", vendor_node, o_amenity, aside * (road_half + 3.0), 0.0, 1.0, 0.0095, o_amenity * 0.1, 2, sw_h) # CitizenRole.VENDOR
		else:
			# High-Detail 3D City Bus Stop Shelter + Waiting Commuters
			_spawn_model(track_root, HD_BUS_STOP, xform, Vector3(aside * (road_half + 3.2), sw_h, 0.0), 0.0042, rot_y)
			var wait_ped := _spawn_model(track_root, HD_PED_CLAUDIA, xform, Vector3(aside * (road_half + 2.6), sw_h, 1.5), 0.0095, rot_y)
			if living_ctrl:
				living_ctrl.call("register_bus_stop", o_amenity)
				if wait_ped:
					living_ctrl.call("register_pedestrian", wait_ped, o_amenity, aside * (road_half + 2.6), 0.0, 1.0, 0.0095, o_amenity * 0.2, 3, sw_h) # CitizenRole.DRIFTER
			
		amenity_flip = !amenity_flip
		o_amenity += 72.0

	# 5. Traffic Hardware, High-Detail Signals, Bollards, Crosswalks & Intersections every 120m
	var crosswalk_mat := StandardMaterial3D.new()
	crosswalk_mat.albedo_color = Color(0.94, 0.94, 0.92)
	crosswalk_mat.roughness = 0.55
	
	var oil_mat := ShaderMaterial.new()
	oil_mat.shader = OIL_PUDDLE_SHADER

	var o_traffic: float = 48.0
	var sign_idx: int = 0
	while o_traffic < track_len - 35.0:
		var xform: Transform3D = main.call("_track_transform", o_traffic, 0.0)
		
		# Continental Zebra Crosswalk Stripes & Yellow Box-Junction Crisscross Grid across the roadway
		for cx in range(-9, 10, 2):
			var stripe := PlaneMesh.new()
			stripe.size = Vector2(0.65, 2.8)
			stripe.material = crosswalk_mat
			var s_inst := MeshInstance3D.new()
			s_inst.name = "CrosswalkStripe"
			s_inst.mesh = stripe
			s_inst.transform = Transform3D(xform.basis, xform * Vector3(float(cx), road_h + 0.014, 0.0))
			track_root.add_child(s_inst)
			
		# Second Parallel Zebra Crosswalk at z = +9.5m forming a complete urban intersection box (matching reference image!)
		for cx2 in range(-9, 10, 2):
			var stripe2 := PlaneMesh.new()
			stripe2.size = Vector2(0.65, 2.6)
			stripe2.material = crosswalk_mat
			var s2_inst := MeshInstance3D.new()
			s2_inst.mesh = stripe2
			s2_inst.transform = Transform3D(xform.basis, xform * Vector3(float(cx2), road_h + 0.014, 9.5))
			track_root.add_child(s2_inst)
			
		for side in sides:
			var pole_lat: float = side * (road_half + 1.2)
			
			# High-Detail 3D City Traffic Light (5.94m tall) + Active Signal Light + Corner Steel Bollards
			_spawn_model(track_root, HD_TRAFFIC_LIGHT, xform, Vector3(pole_lat, sw_h, 0.0), 0.85, 90.0 if side > 0 else -90.0)
			var sig_light := OmniLight3D.new()
			sig_light.light_color = Color(0.10, 1.0, 0.35)
			sig_light.light_energy = 3.2
			sig_light.omni_range = 14.0
			sig_light.distance_fade_enabled = true
			sig_light.distance_fade_begin = 90.0
			sig_light.distance_fade_length = 25.0
			sig_light.position = xform * Vector3(pole_lat - side * 1.4, sw_h + 5.1, 0.0)
			track_root.add_child(sig_light)
			if living_ctrl and side > 0:
				living_ctrl.call("register_traffic_signal", o_traffic, sig_light, float(sign_idx) * 2.5)
				
			_spawn_model(track_root, HD_BOLLARD, xform, Vector3(side * (road_half + 0.85), sw_h, -2.2), 0.08)
			_spawn_model(track_root, HD_BOLLARD, xform, Vector3(side * (road_half + 0.85), sw_h, 2.2), 0.08)
			
			# Street Name Blade Sign on pole at y = 3.6m facing oncoming traffic (-Z)
			var sign_name: String = STREET_NAMES[sign_idx % STREET_NAMES.size()]
			var sblade_pos: Vector3 = xform * Vector3(pole_lat - side * 0.65, sw_h + 3.42, 0.0)
			main.call("_add_prop", Vector3(1.35, 0.28, 0.06), sblade_pos, xform.basis, sign_green)
			var slbl := Label3D.new()
			slbl.text = sign_name
			slbl.font_size = 24
			slbl.outline_size = 3
			slbl.double_sided = true
			slbl.modulate = Color.WHITE
			slbl.outline_modulate = Color(0.0, 0.2, 0.0)
			slbl.transform = Transform3D(xform.basis, sblade_pos - xform.basis.z * 0.04)
			track_root.add_child(slbl)
			sign_idx += 1
			
			# 3D STOP Sign & No Parking Sign facing oncoming traffic at offset + 24m
			var stop_xform: Transform3D = main.call("_track_transform", o_traffic + 24.0, 0.0)
			_spawn_model(track_root, MODEL_STOP_SIGN, stop_xform, Vector3(pole_lat, sw_h, 0.0), 4.2, 90.0)
			_spawn_model(track_root, MODEL_SIGN_NOPARKING, stop_xform, Vector3(-pole_lat, sw_h, 0.0), 4.2, 90.0)
			
			# Tactile Warning Pavers at crosswalk curb cuts
			var tile := PlaneMesh.new()
			tile.size = Vector2(1.2, 0.7)
			tile.material = tactile_mat
			var t_inst := MeshInstance3D.new()
			t_inst.mesh = tile
			t_inst.transform = Transform3D(xform.basis, xform * Vector3(side * (road_half + 0.8), sw_h + 0.003, 0.0))
			track_root.add_child(t_inst)
			
			# Iridescent Hydrocarbon Oil Sheen Puddle in sidewalk service apron
			var oil_mesh := PlaneMesh.new()
			oil_mesh.size = Vector2(1.6, 2.2)
			oil_mesh.material = oil_mat
			var oil_inst := MeshInstance3D.new()
			oil_inst.mesh = oil_mesh
			oil_inst.transform = Transform3D(xform.basis, stop_xform * Vector3(side * (road_half + 3.2), sw_h + 0.004, 0.0))
			track_root.add_child(oil_inst)

		o_traffic += 120.0

	# 6. Photo-Scanned Cast-Iron Water Manhole Covers & Billowing Steam Vents every 40m
	var o_vent: float = 20.0
	while o_vent < track_len - 30.0:
		var xform: Transform3D = main.call("_track_transform", o_vent, 0.0)
		for side in sides:
			var mlat: float = side * (road_half + 2.2)
			var mpos: Vector3 = xform * Vector3(mlat, sw_h + 0.005, 0.0)
			_spawn_model(track_root, PH_MANHOLE_COVER, xform, Vector3(mlat, sw_h, 0.0), 1.15, rng.randf_range(0.0, 360.0))
			
			if rng.randf() < 0.65:
				_add_steam_plume(track_root, mpos)
		o_vent += 40.0

	# 7. Curbside Emergency & Commercial Staging Bays (Fire Truck, Ambulance & Police Cruiser normalized to true metric scale & grounded at sidewalk elevation sw_h)
	if track_len > 600.0 and living_ctrl:
		# Bay 1 (180m): Curbside Fire Response Rig + Road Barriers & Traffic Cones
		var vxform1: Transform3D = main.call("_track_transform", 180.0, 0.0)
		var vlat1: float = road_half + 3.85
		if HD_FIRE_TRUCK:
			var ft_raw := HD_FIRE_TRUCK.instantiate() as Node3D
			if ft_raw:
				var ft_norm: Node3D = living_ctrl.call("normalize_and_ground_instance", ft_raw, 7.2, 0.0)
				ft_norm.transform = Transform3D(vxform1.basis, vxform1 * Vector3(vlat1, sw_h, 0.0))
				track_root.add_child(ft_norm)
		_spawn_model(track_root, PH_ROAD_BARRIER, vxform1, Vector3(vlat1, sw_h, -4.8), 1.2, 0.0)
		_spawn_model(track_root, MODEL_CONE, vxform1, Vector3(vlat1 - 1.2, sw_h, -3.5), 8.0, 0.0)
		
		# Bay 2 (420m): Emergency Ambulance & Police Cruiser Staging Zone with Strobe Lights (oriented parallel to road)
		var vxform2: Transform3D = main.call("_track_transform", 420.0, 0.0)
		if HD_AMBULANCE:
			var amb_raw := HD_AMBULANCE.instantiate() as Node3D
			if amb_raw:
				var amb_norm: Node3D = living_ctrl.call("normalize_and_ground_instance", amb_raw, 5.6, 0.0)
				amb_norm.transform = Transform3D(vxform2.basis, vxform2 * Vector3(vlat1, sw_h, 0.0))
				track_root.add_child(amb_norm)
		if HD_COP_CRUISER:
			var cop_raw := HD_COP_CRUISER.instantiate() as Node3D
			if cop_raw:
				var cop_norm: Node3D = living_ctrl.call("normalize_and_ground_instance", cop_raw, 4.8, 0.0)
				cop_norm.transform = Transform3D(vxform2.basis, vxform2 * Vector3(-vlat1, sw_h, 0.0))
				track_root.add_child(cop_norm)
		_spawn_model(track_root, PH_ROAD_BARRIER, vxform2, Vector3(-vlat1, sw_h, -5.0), 1.2, 0.0)
		
		var strobe_red := OmniLight3D.new()
		strobe_red.light_color = Color(1.0, 0.08, 0.12)
		strobe_red.light_energy = 4.5
		strobe_red.omni_range = 24.0
		strobe_red.position = vxform2 * Vector3(vlat1, sw_h + 2.02, 0.0)
		track_root.add_child(strobe_red)
		
		var strobe_blue := OmniLight3D.new()
		strobe_blue.light_color = Color(0.12, 0.45, 1.0)
		strobe_blue.light_energy = 4.5
		strobe_blue.omni_range = 24.0
		strobe_blue.position = vxform2 * Vector3(-vlat1, sw_h + 1.82, 0.0)
		track_root.add_child(strobe_blue)
		
		if living_ctrl:
			living_ctrl.call("register_strobe", strobe_red, 4.5, false)
			living_ctrl.call("register_strobe", strobe_blue, 4.5, true)
			living_ctrl.call("add_siren_emitter", vxform2 * Vector3(vlat1, sw_h + 2.02, 0.0))
			
			# 8. Autonomous Hovering Security Drones patrolling overhead beats along both promenades
			for d_idx in 14:
				var d_off: float = float(d_idx) * (track_len / 14.0) + 25.0
				var d_side: float = 1.0 if (d_idx % 2 == 0) else -1.0
				var d_lat: float = d_side * (road_half + 2.5)
				var d_spd: float = rng.randf_range(5.5, 8.5)
				living_ctrl.call("spawn_security_drone", track_root, d_off, d_lat, d_spd, d_side, float(d_idx) * 0.85)
				
			# 9. Bustling Multi-Lane Autonomous Cyber-Traffic Fleet:
			# Right Lanes (lat < 0): Forward travel (dir = 1.0)
			# Left Lanes (lat > 0): Oncoming travel (dir = -1.0)
			var box_truck_specs: Array[Dictionary] = [
				{"off": 62.0, "lat": -7.85, "spd": 11.8, "dir": 1.0},
				{"off": 118.0, "lat": 7.85, "spd": 12.2, "dir": -1.0},
				{"off": 154.0, "lat": -7.85, "spd": 12.0, "dir": 1.0},
				{"off": 215.0, "lat": 7.85, "spd": 11.8, "dir": -1.0},
				{"off": 520.0, "lat": -7.85, "spd": 12.5, "dir": 1.0},
				{"off": 860.0, "lat": 7.85, "spd": 12.1, "dir": -1.0},
				{"off": 1190.0, "lat": 7.85, "spd": 12.4, "dir": -1.0},
				{"off": 1540.0, "lat": -7.85, "spd": 12.0, "dir": 1.0},
				{"off": 1840.0, "lat": -7.85, "spd": 12.2, "dir": 1.0},
				{"off": 2380.0, "lat": 7.85, "spd": 12.0, "dir": -1.0}
			]
			for bts in box_truck_specs:
				living_ctrl.call("spawn_white_box_truck", track_root, float(bts.off), float(bts.lat), float(bts.spd), float(bts.dir))
				
			# Spawn Sleek Autonomous Sedans & Crown Taxis across passing (±3.6m) and cruising (±6.9m) lanes
			var sedan_palette: Array[Color] = [
				Color(0.92, 0.94, 0.96), # Pearl White
				Color(0.14, 0.18, 0.26), # Midnight Navy
				Color(0.74, 0.78, 0.82), # Liquid Silver
				Color(0.16, 0.17, 0.19), # Graphite Charcoal
				Color(0.68, 0.14, 0.18), # Cyber Crimson
				Color(0.12, 0.44, 0.56)  # Electric Teal
			]
			var sedan_offsets: Array[float] = [
				52.0, 68.0, 82.0, 96.0, 112.0, 134.0, 148.0, 166.0, 188.0, 210.0,
				340.0, 465.0, 690.0, 810.0, 920.0, 1060.0, 1240.0, 1390.0, 1680.0, 1820.0, 1980.0, 2250.0, 2410.0, 2580.0
			]
			for s_i in sedan_offsets.size():
				var s_off: float = sedan_offsets[s_i]
				var s_dir: float = 1.0 if (s_i % 2 == 0) else -1.0
				var lane_mag: float = 3.6 if (s_i % 4 < 2) else 6.9
				var s_lat: float = -lane_mag if s_dir > 0.0 else lane_mag
				var s_col: Color = sedan_palette[s_i % sedan_palette.size()]
				living_ctrl.call("spawn_sleek_sedan", track_root, s_off, s_lat, 14.2 + float(s_i % 3) * 0.65, s_dir, s_col)

			# Spawn Futuristic Articulated Transit Buses in dedicated outer transit lanes (±7.8m)
			var bus_specs: Array[Dictionary] = [
				{"off": 88.0, "lat": -7.8, "spd": 11.5, "dir": 1.0, "col": Color(0.88, 0.36, 0.14)},
				{"off": 168.0, "lat": 7.8, "spd": 11.5, "dir": -1.0, "col": Color(0.14, 0.56, 0.62)},
				{"off": 242.0, "lat": -7.8, "spd": 11.6, "dir": 1.0, "col": Color(0.14, 0.56, 0.62)},
				{"off": 780.0, "lat": 7.8, "spd": 11.5, "dir": -1.0, "col": Color(0.88, 0.36, 0.14)},
				{"off": 1520.0, "lat": -7.8, "spd": 11.8, "dir": 1.0, "col": Color(0.14, 0.56, 0.62)},
				{"off": 2180.0, "lat": 7.8, "spd": 11.2, "dir": -1.0, "col": Color(0.88, 0.36, 0.14)}
			]
			for bsp in bus_specs:
				living_ctrl.call("spawn_futuristic_city_bus", track_root, float(bsp.off), float(bsp.lat), float(bsp.spd), float(bsp.dir), bsp.col)

			var fleet_specs: Array[Dictionary] = [
				{"scn": HD_COP_CRUISER, "off": 440.0, "lat": -6.8, "spd": 16.5, "dir": 1.0, "sc": 1.0, "y": 0.22, "rot": 0.0, "type": "police", "norm_len": 4.85},
				{"scn": HD_COP_CRUISER, "off": 1580.0, "lat": 6.8, "spd": 16.5, "dir": -1.0, "sc": 1.0, "y": 0.22, "rot": 0.0, "type": "police", "norm_len": 4.85},
				{"scn": HD_SCOOTER, "off": 110.0, "lat": -7.2, "spd": 18.0, "dir": 1.0, "sc": 0.0068, "y": 0.22, "rot": 0.0, "type": "scooter", "norm_len": 0.0},
				{"scn": HD_SCOOTER, "off": 840.0, "lat": 7.2, "spd": 18.5, "dir": -1.0, "sc": 0.0068, "y": 0.22, "rot": 0.0, "type": "scooter", "norm_len": 0.0},
				{"scn": HD_SCOOTER, "off": 1740.0, "lat": -7.2, "spd": 17.8, "dir": 1.0, "sc": 0.0068, "y": 0.22, "rot": 0.0, "type": "scooter", "norm_len": 0.0},
				{"scn": HD_SCOOTER, "off": 2480.0, "lat": 7.2, "spd": 17.5, "dir": -1.0, "sc": 0.0068, "y": 0.22, "rot": 0.0, "type": "scooter", "norm_len": 0.0}
			]
			for fs in fleet_specs:
				var f_scn: PackedScene = fs.scn
				if f_scn:
					var f_inst := f_scn.instantiate() as Node3D
					if f_inst:
						var nlen: float = float(fs.get("norm_len", 0.0))
						if nlen > 0.0:
							f_inst = living_ctrl.call("normalize_and_ground_instance", f_inst, nlen, 0.0)
						track_root.add_child(f_inst)
						living_ctrl.call("register_traffic_vehicle", f_inst, float(fs.off), float(fs.lat), float(fs.spd), float(fs.dir), float(fs.sc), float(fs.y), float(fs.rot), String(fs.type))


## Layer 3B: Bioluminescent Cyber-Botanical Pocket Parks ("The City's Lungs" — Glowing Flora, Ancient Oaks & Plazas)
static func _build_urban_pocket_parks(main: Node, track_root: Node3D, rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var turf_mat := StandardMaterial3D.new()
	turf_mat.albedo_color = Color(0.08, 0.45, 0.28)
	turf_mat.emission_enabled = true
	turf_mat.emission = Color(0.04, 0.35, 0.22)
	turf_mat.emission_energy_multiplier = 0.65
	turf_mat.roughness = 0.75
	
	var bio_colors: Array[Color] = [
		Color(0.0, 0.95, 1.0),  # Bioluminescent Cyan
		Color(0.15, 1.0, 0.55), # Bioluminescent Emerald
		Color(1.0, 0.15, 0.75)  # Bioluminescent Magenta
	]
	
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var track_len: float = float(main.get("track_length"))
	var sw_h: float = float(main.get("ROAD_HEIGHT")) + 0.18 # 0.40m
	var park_offsets: Array[float] = [300.0, 820.0, 1480.0, 2120.0]
	
	for i in park_offsets.size():
		var po: float = park_offsets[i]
		if po >= track_len - 40.0:
			continue
		var xform: Transform3D = main.call("_track_transform", po, 0.0)
		for side in [-1.0, 1.0]:
			var park_lat: float = side * (road_half + 3.1)
			var park_pos: Vector3 = xform * Vector3(park_lat, sw_h + 0.005, 0.0)
			
			# Bioluminescent pocket-park lawn strip along the wide promenade
			var lawn := PlaneMesh.new()
			lawn.size = Vector2(2.4, 14.0)
			lawn.material = turf_mat
			var l_inst := MeshInstance3D.new()
			l_inst.name = "PocketParkLawn_%d" % i
			l_inst.mesh = lawn
			l_inst.transform = Transform3D(xform.basis, park_pos)
			track_root.add_child(l_inst)
			
			# Ancient Oak Canopy Trees + Bioluminescent Shrubs + Modular Park Seating + Socializing Citizens grounded on promenade
			_spawn_model(track_root, MODEL_TREE_LARGE, xform, Vector3(park_lat, sw_h, -5.0), 3.6, rng.randf_range(0.0, 360.0))
			_spawn_model(track_root, MODEL_TREE_LARGE, xform, Vector3(park_lat, sw_h, 5.0), 3.6, rng.randf_range(0.0, 360.0))
			_spawn_model(track_root, PH_SHRUB, xform, Vector3(park_lat, sw_h, -3.2), 0.32, 45.0)
			_spawn_model(track_root, PH_SHRUB, xform, Vector3(park_lat, sw_h, 3.2), 0.32, 135.0)
			_spawn_model(track_root, PH_STREET_SEATING, xform, Vector3(park_lat, sw_h, 0.0), 0.65, 90.0 if side < 0 else -90.0)
			var p1 := _spawn_model(track_root, HD_PED_NATHAN, xform, Vector3(park_lat - side * 0.9, sw_h, -1.2), 0.0095, 90.0 if side < 0 else -90.0)
			var p2 := _spawn_model(track_root, HD_PED_CARLA, xform, Vector3(park_lat - side * 0.9, sw_h, 1.2), 0.0095, 90.0 if side < 0 else -90.0)
			if living_ctrl:
				if p1:
					living_ctrl.call("register_pedestrian", p1, po, park_lat - side * 0.9, 0.0, 1.0, 0.0095, float(i), 3, sw_h)
				if p2:
					living_ctrl.call("register_pedestrian", p2, po, park_lat - side * 0.9, 0.0, -1.0, 0.0095, float(i) + 1.5, 3, sw_h)
			
			# Bioluminescent Flora Under-Glow Lights
			var bio_light := OmniLight3D.new()
			bio_light.light_color = bio_colors[(i + int(side > 0)) % bio_colors.size()]
			bio_light.light_energy = 3.2
			bio_light.omni_range = 14.0
			bio_light.distance_fade_enabled = true
			bio_light.distance_fade_begin = 85.0
			bio_light.distance_fade_length = 25.0
			bio_light.position = xform * Vector3(park_lat, 1.2, 0.0)
			track_root.add_child(bio_light)
			
			# Corner Noodle-Bar / Espresso Steam Plume rising beside the bioluminescent terrace
			_add_steam_plume(track_root, xform * Vector3(park_lat + side * 0.8, 0.25, -2.5))


static func _add_steam_plume(track_root: Node3D, pos: Vector3) -> void:
	var steam_mesh := QuadMesh.new()
	steam_mesh.size = Vector2(2.4, 4.2)
	
	var mat := ShaderMaterial.new()
	mat.shader = STEAM_VENT_SHADER
	mat.set_shader_parameter("steam_color", Color(0.92, 0.94, 0.98, 0.32))
	mat.set_shader_parameter("speed", 0.75)
	steam_mesh.material = mat
	
	var inst1 := MeshInstance3D.new()
	inst1.mesh = steam_mesh
	inst1.position = pos + Vector3(0.0, 2.1, 0.0)
	track_root.add_child(inst1)
	
	var inst2 := MeshInstance3D.new()
	inst2.mesh = steam_mesh
	inst2.position = pos + Vector3(0.0, 2.1, 0.0)
	inst2.rotation_degrees.y = 90.0
	track_root.add_child(inst2)
	
	var player := AudioStreamPlayer3D.new()
	var snd := load("res://sounds/subway_vent_hum.wav")
	if snd:
		player.stream = snd
		player.unit_size = 18.0
		player.max_distance = 60.0
		player.volume_db = -12.0
		player.autoplay = true
		player.position = pos
		track_root.add_child(player)


## Layer 6B: Continuous Elevated Monorail Viaduct on Tall Brutalist T-Pillars & White 3-Car Bullet Monorail Trains
static func _build_elevated_railway_sector(main: Node, track_root: Node3D, living_ctrl: Node3D) -> void:
	var brutalist_viaduct := _make_pbr_concrete(Color(0.68, 0.70, 0.72), 0.72, 0.14)
	var steel_beam := _make_pbr_metal(Color(0.42, 0.46, 0.52), 0.30, 0.88)
	
	var maglev_cyan := StandardMaterial3D.new()
	maglev_cyan.albedo_color = Color(0.0, 0.92, 1.0)
	maglev_cyan.emission_enabled = true
	maglev_cyan.emission = Color(0.0, 0.92, 1.0)
	maglev_cyan.emission_energy_multiplier = 2.4

	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var el_lateral: float = road_half + 2.0 # +13.5m setback on LEFT promenade (+X) in front of stepped podium terraces
	var el_height: float = 10.5
	var track_len: float = float(main.get("track_length"))
	var road_h_lim: float = road_half + 0.2
	
	var num_bents: int = maxi(24, int(round(track_len / 12.0)))
	var step_dist: float = track_len / float(num_bents)
	
	for bi in num_bents:
		var o0: float = float(bi) * step_dist
		var o1: float = float((bi + 1) % num_bents) * step_dist
		var xform0: Transform3D = main.call("_track_transform", o0, 0.0)
		var xform1: Transform3D = main.call("_track_transform", o1, 0.0)
		
		# Tall Brutalist Concrete T-Pillar Column & Hammerhead Cap at o0
		var col_pos: Vector3 = xform0 * Vector3(el_lateral, el_height * 0.5, 0.0)
		if float(main.call("_distance_to_track", col_pos.x, col_pos.z)) >= road_h_lim:
			main.call("_add_prop", Vector3(0.85, el_height, 0.85), col_pos, xform0.basis, brutalist_viaduct)
			var cap_pos: Vector3 = xform0 * Vector3(el_lateral, el_height, 0.0)
			main.call("_add_prop", Vector3(3.2, 0.75, 1.35), cap_pos, xform0.basis, brutalist_viaduct)
		
		# Exact Point-to-Point Monorail Guideway Span from Cap p0 to Cap p1 (overhead at y = 10.95m, 100% seamless around all curves!)
		var p0: Vector3 = xform0 * Vector3(el_lateral, el_height + 0.45, 0.0)
		var p1: Vector3 = xform1 * Vector3(el_lateral, el_height + 0.45, 0.0)
		var mid_p: Vector3 = (p0 + p1) * 0.5
		var chord: Vector3 = p1 - p0
		var span_len: float = chord.length() + 0.55
		if chord.length() > 0.1:
			var span_basis := Basis.looking_at(-chord.normalized(), Vector3.UP)
			main.call("_add_prop", Vector3(2.3, 0.55, span_len), mid_p, span_basis, brutalist_viaduct)
			main.call("_add_prop", Vector3(2.45, 0.16, span_len), mid_p + Vector3(0.0, 0.30, 0.0), span_basis, steel_beam)
			main.call("_add_prop", Vector3(0.32, 0.08, span_len), mid_p + Vector3(0.0, 0.41, 0.0), span_basis, maglev_cyan)
		
	# Spawn 4 Sleek White-and-Silver 3-Car Articulated Bullet Monorail Trains gliding along the left elevated guideway
	if living_ctrl:
		var train_offsets: Array[float] = [72.0, 740.0, 1480.0, 2190.0]
		for ti in train_offsets.size():
			living_ctrl.call("spawn_bullet_monorail_train", track_root, train_offsets[ti], 20.0, 1.0)
			
	# 2. Elevated Monorail Transit Stations with Cantilevered Canopies & Waiting Platform Commuters (y = 11.2m)
	var station_glass := StandardMaterial3D.new()
	station_glass.albedo_color = Color(0.10, 0.30, 0.44, 0.45)
	station_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	station_glass.metallic = 0.85
	station_glass.roughness = 0.12
	
	var white_train_mat := StandardMaterial3D.new()
	white_train_mat.albedo_color = Color(0.92, 0.94, 0.97)
	white_train_mat.metallic = 0.35
	white_train_mat.roughness = 0.22
	
	var dark_win_mat := StandardMaterial3D.new()
	dark_win_mat.albedo_color = Color(0.06, 0.10, 0.16)
	dark_win_mat.metallic = 0.88
	dark_win_mat.roughness = 0.10
	
	var ped_models: Array[PackedScene] = [HD_PED_CLAUDIA, HD_PED_ERIC, HD_PED_NATHAN, HD_PED_CARLA]
	var station_offsets: Array[float] = [148.0, 880.0, 1640.0, 2340.0]
	for si in station_offsets.size():
		var so: float = station_offsets[si]
		if so >= track_len - 40.0:
			continue
		var sxform: Transform3D = main.call("_track_transform", so, 0.0)
		var plat_lat: float = el_lateral + 2.85 # Platform immediately adjacent to monorail guideway
		var plat_y: float = el_height + 0.35
		# Brutalist Station Platform Deck, Support Columns & Glass Safety Barrier
		main.call("_add_prop", Vector3(3.2, 0.55, 26.0), sxform * Vector3(plat_lat, plat_y, 0.0), sxform.basis, brutalist_viaduct)
		main.call("_add_prop", Vector3(0.75, plat_y, 0.75), sxform * Vector3(plat_lat, plat_y * 0.5, -9.5), sxform.basis, brutalist_viaduct)
		main.call("_add_prop", Vector3(0.75, plat_y, 0.75), sxform * Vector3(plat_lat, plat_y * 0.5, 9.5), sxform.basis, brutalist_viaduct)
		main.call("_add_prop", Vector3(0.12, 1.15, 25.6), sxform * Vector3(plat_lat - 1.48, plat_y + 0.85, 0.0), sxform.basis, station_glass)
		# Cantilevered Glass & Steel Station Canopy Roof
		main.call("_add_prop", Vector3(4.2, 0.28, 24.0), sxform * Vector3(plat_lat - 0.2, plat_y + 3.6, 0.0), sxform.basis, steel_beam)
		main.call("_add_prop", Vector3(3.8, 0.12, 23.2), sxform * Vector3(plat_lat - 0.2, plat_y + 3.8, 0.0), sxform.basis, station_glass)
		main.call("_add_prop", Vector3(0.22, 0.10, 23.0), sxform * Vector3(plat_lat - 1.9, plat_y + 3.48, 0.0), sxform.basis, maglev_cyan)
		# Waiting Platform Commuters
		for pi in 3:
			var p_inst := ped_models[(si + pi) % ped_models.size()].instantiate() as Node3D
			if p_inst and living_ctrl:
				track_root.add_child(p_inst)
				var z_st: float = -7.5 + float(pi) * 7.5
				living_ctrl.call("register_pedestrian", p_inst, so, plat_lat, 1.25, 1.0 if (pi % 2 == 0) else -1.0, 0.0095, float(si + pi) * 1.4, 4, plat_y + 0.30, 10.5, z_st)

	# 3. High-Altitude Cross-Avenue Monorail Bridge (y = 26.5m) supported by Tall Brutalist Pylons on both sides of the avenue
	var cross_monorail_offsets: Array[float] = [335.0, 1280.0]
	for cmi in cross_monorail_offsets.size():
		var cmo: float = cross_monorail_offsets[cmi]
		if cmo >= track_len - 40.0:
			continue
		var cmxform: Transform3D = main.call("_track_transform", cmo, 0.0)
		var cmy: float = 26.5
		var pylon_lat: float = road_half + 4.2
		var cm_span: float = pylon_lat * 2.0 + 4.0
		# Support Pylons on both sides so the cross-avenue monorail bridge is 100% structurally anchored
		for p_side in [-1.0, 1.0]:
			main.call("_add_prop", Vector3(1.6, cmy, 2.2), cmxform * Vector3(p_side * pylon_lat, cmy * 0.5, 0.0), cmxform.basis, brutalist_viaduct)
		main.call("_add_prop", Vector3(cm_span, 1.25, 2.6), cmxform * Vector3(0.0, cmy, 0.0), cmxform.basis, brutalist_viaduct)
		main.call("_add_prop", Vector3(cm_span, 0.25, 2.8), cmxform * Vector3(0.0, cmy + 0.72, 0.0), cmxform.basis, steel_beam)
		main.call("_add_prop", Vector3(cm_span, 0.10, 0.35), cmxform * Vector3(0.0, cmy + 0.88, -1.25), cmxform.basis, maglev_cyan)
		# 3-Car White Bullet Monorail perched along the cross-avenue bridge
		for car_i in 3:
			var cx: float = -10.5 + float(car_i) * 10.5
			main.call("_add_prop", Vector3(9.6, 2.3, 2.3), cmxform * Vector3(cx, cmy + 2.0, 0.0), cmxform.basis, white_train_mat)
			main.call("_add_prop", Vector3(8.8, 0.78, 2.38), cmxform * Vector3(cx, cmy + 2.25, 0.0), cmxform.basis, dark_win_mat)


## Layer 6C: Lower Pedestrian Overpass Skywalks (y = 6.2m) & High-Altitude Megatower Skybridges (y = 52m)
static func _build_cyberpunk_skybridges_and_holoarches(main: Node, track_root: Node3D, rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var track_len: float = float(main.get("track_length"))
	var pier_lat: float = road_half + 3.85
	var bridge_span: float = pier_lat * 2.0 + 1.6
	
	var brutalist_deck := _make_pbr_concrete(Color(0.62, 0.64, 0.68), 0.68, 0.16)
	var truss_mat := _make_pbr_metal(Color(0.38, 0.42, 0.48), 0.28, 0.88)
	
	var glass_tube_mat := StandardMaterial3D.new()
	glass_tube_mat.albedo_color = Color(0.12, 0.32, 0.45, 0.38)
	glass_tube_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_tube_mat.metallic = 0.88
	glass_tube_mat.roughness = 0.08
	glass_tube_mat.clearcoat_enabled = true
	glass_tube_mat.clearcoat = 0.75
	glass_tube_mat.clearcoat_roughness = 0.08
	
	var ped_models: Array[PackedScene] = [HD_PED_CLAUDIA, HD_PED_ERIC, HD_PED_NATHAN, HD_PED_CARLA]
	
	# 1. 8 Lower Pedestrian Overpass Skywalks at y = 6.2m with Sturdy Brutalist Support Piers & Stair Towers on Both Sidewalks
	var low_skywalk_offsets: Array[float] = [115.0, 380.0, 720.0, 1080.0, 1440.0, 1780.0, 2140.0, 2520.0]
	var banner_titles: Array[String] = [
		"NEO-VERIDIA TRANSIT // LINE-01",
		"SECTOR-9 BIOTECH // TERRACE",
		"SYNAPSE PLAZA // SKY-PROMENADE",
		"HARBOR DOCKLANDS // EAST LINK"
	]
	for bi in low_skywalk_offsets.size():
		var bo: float = low_skywalk_offsets[bi]
		if bo >= track_len - 40.0:
			continue
		var xform: Transform3D = main.call("_track_transform", bo, 0.0)
		var by: float = 6.2
		var neon_col: Color = Color(0.0, 0.88, 0.96) if (bi % 2 == 0) else Color(0.95, 0.22, 0.78)
		
		var trim_mat := StandardMaterial3D.new()
		trim_mat.albedo_color = neon_col * 0.25
		trim_mat.emission_enabled = true
		trim_mat.emission = neon_col
		trim_mat.emission_energy_multiplier = 2.0
		
		# Brutalist Support Piers & Glass Elevator/Stair Towers on BOTH Left and Right Sidewalks so Skywalk is 100% Grounded
		for p_side in [-1.0, 1.0]:
			main.call("_add_prop", Vector3(1.4, by, 3.6), xform * Vector3(p_side * pier_lat, by * 0.5, 0.0), xform.basis, brutalist_deck)
			main.call("_add_prop", Vector3(2.2, by + 1.2, 2.4), xform * Vector3(p_side * (pier_lat + 1.2), (by + 1.2) * 0.5, 2.2), xform.basis, glass_tube_mat)
		
		# Brutalist concrete skywalk deck & glass parapet railings spanning the avenue
		main.call("_add_prop", Vector3(bridge_span, 0.65, 3.6), xform * Vector3(0.0, by, 0.0), xform.basis, brutalist_deck)
		main.call("_add_prop", Vector3(bridge_span, 1.15, 0.14), xform * Vector3(0.0, by + 0.85, -1.72), xform.basis, glass_tube_mat)
		main.call("_add_prop", Vector3(bridge_span, 1.15, 0.14), xform * Vector3(0.0, by + 0.85, 1.72), xform.basis, glass_tube_mat)
		
		# Flush Digital Ticker Fascia mounted on the front of the pedestrian overpass
		main.call("_add_prop", Vector3(11.5, 0.72, 0.12), xform * Vector3(0.0, by + 0.05, -1.86), xform.basis, trim_mat)
		var sw_lbl := Label3D.new()
		sw_lbl.text = banner_titles[bi % banner_titles.size()]
		sw_lbl.font_size = 26
		sw_lbl.outline_size = 4
		sw_lbl.double_sided = true
		sw_lbl.modulate = Color.WHITE
		sw_lbl.outline_modulate = Color(0.02, 0.08, 0.12)
		sw_lbl.transform = Transform3D(xform.basis, xform * Vector3(0.0, by + 0.05, -1.94))
		track_root.add_child(sw_lbl)
		
		# Spawn 3 Skybridge Commuters walking overhead across the open-top pedestrian overpass
		for w_i in 3:
			var p_scn: PackedScene = ped_models[(bi + w_i) % ped_models.size()]
			var p_inst := p_scn.instantiate() as Node3D
			if p_inst and living_ctrl:
				track_root.add_child(p_inst)
				var start_lat: float = -9.0 + float(w_i) * 9.0
				var w_dir: float = 1.0 if (w_i % 2 == 0) else -1.0
				living_ctrl.call("register_pedestrian", p_inst, bo, start_lat, rng.randf_range(1.35, 1.85), w_dir, 0.0095, float(bi + w_i), 1, by + 0.35, road_half + 2.5)


## Layer 6D: Waterfront Harbor Docklands, Cargo Ships, Articulated Yellow Port Cranes & Industrial Smokestacks
static func _build_waterfront_harbor_and_smokestacks(main: Node, track_root: Node3D, rng: RandomNumberGenerator) -> void:
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var track_len: float = float(main.get("track_length"))
	
	# Animated Wind-Rippled Harbor Water Shader with SSR & Sun Glint
	var water_shader := Shader.new()
	water_shader.code = """
shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 v_wpos;
void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 uv1 = v_wpos.xz * 0.35 + vec2(TIME * 0.08, TIME * 0.05);
	vec2 uv2 = v_wpos.xz * 0.85 - vec2(TIME * 0.06, TIME * 0.11);
	float w1 = sin(uv1.x * 6.2831 + cos(uv1.y * 4.5)) * 0.5;
	float w2 = cos(uv2.y * 6.2831 - sin(uv2.x * 5.2)) * 0.5;
	vec3 n = normalize(vec3((w1 + w2) * 0.16, (w1 - w2) * 0.16, 1.0));
	NORMAL_MAP = n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.85;
	ALBEDO = mix(vec3(0.04, 0.11, 0.16), vec3(0.09, 0.20, 0.27), clamp(w1 + 0.5, 0.0, 1.0));
	METALLIC = 0.82;
	ROUGHNESS = 0.09;
	SPECULAR = 0.92;
}
"""
	var water_mat := ShaderMaterial.new()
	water_mat.shader = water_shader
	
	var quay_concrete := _make_pbr_concrete(Color(0.68, 0.66, 0.62), 0.78, 0.08)
	var crane_yellow := _make_pbr_metal(Color(0.95, 0.72, 0.16), 0.38, 0.55)
	var cable_steel := _make_pbr_metal(Color(0.32, 0.36, 0.40), 0.28, 0.88)
	var hull_rust := _make_pbr_metal(Color(0.56, 0.28, 0.24), 0.62, 0.42)
	var hull_upper := _make_pbr_metal(Color(0.36, 0.40, 0.44), 0.52, 0.48)
	var hull_deck := _make_pbr_metal(Color(0.58, 0.60, 0.64), 0.62, 0.35)
	
	var bridge_white := _make_pbr_concrete(Color(0.92, 0.90, 0.86), 0.42, 0.12)
	
	var bridge_glass := StandardMaterial3D.new()
	bridge_glass.albedo_color = Color(0.05, 0.10, 0.15)
	bridge_glass.metallic = 0.90
	bridge_glass.roughness = 0.08
	bridge_glass.clearcoat_enabled = true
	bridge_glass.clearcoat = 0.80
	bridge_glass.clearcoat_roughness = 0.06
	
	var stack_mat := _make_pbr_concrete(Color(0.58, 0.56, 0.54), 0.76, 0.10)
	
	var container_colors: Array[Color] = [
		Color(0.58, 0.22, 0.16),
		Color(0.18, 0.34, 0.46),
		Color(0.62, 0.48, 0.18),
		Color(0.24, 0.38, 0.28)
	]
	
	# 1. Harbor Quayside Dock & Shimmering Canal Basin along the RIGHT side (-X) in Sector 1 (o = 55..305m)
	var harbor_offsets: Array[float] = [68.0, 128.0, 188.0, 248.0, 302.0]
	for hi in harbor_offsets.size():
		var ho: float = harbor_offsets[hi]
		if ho >= track_len - 50.0:
			continue
		var xform: Transform3D = main.call("_track_transform", ho, 0.0)
		var quay_lat: float = -(road_half + 8.5)   # -20.0m (from -16.0m sidewalk edge to -24.0m canal seawall)
		var water_lat: float = -(road_half + 48.5) # -60.0m (spanning from -24.0m seawall out to -96.0m)
		
		# Quayside stone pier apron (top at y = 0.40m) & shimmering harbor water basin (top at y = 0.22m, above ground plane!)
		main.call("_add_prop", Vector3(8.0, 0.40, 62.0), xform * Vector3(quay_lat, 0.20, 0.0), xform.basis, quay_concrete)
		main.call("_add_prop", Vector3(0.45, 0.55, 62.0), xform * Vector3(quay_lat - 3.85, 0.38, 0.0), xform.basis, crane_yellow)
		main.call("_add_prop", Vector3(72.0, 0.16, 64.0), xform * Vector3(water_lat, 0.14, 0.0), xform.basis, water_mat)
		
		# Detailed Moored Cargo Freighter Ship floating in the harbor basin on the right (-X)
		var ship_lat: float = -(road_half + 23.5)
		var ship_pos: Vector3 = xform * Vector3(ship_lat, 0.22, 0.0)
		# Red Anti-Fouling Waterline Hull + Dark Charcoal Freeboard Hull + Raked Bow + Main Deck
		main.call("_add_prop", Vector3(10.6, 1.8, 44.0), ship_pos + Vector3(0.0, 0.9, 0.0), xform.basis, hull_rust)
		main.call("_add_prop", Vector3(11.0, 2.2, 46.5), ship_pos + Vector3(0.0, 2.6, 0.0), xform.basis, hull_upper)
		main.call("_add_prop", Vector3(8.2, 2.1, 6.5), ship_pos + xform.basis.z * 24.5 + Vector3(0.0, 2.7, 0.0), xform.basis, hull_upper)
		main.call("_add_prop", Vector3(10.4, 0.45, 45.0), ship_pos + Vector3(0.0, 3.85, 0.0), xform.basis, hull_deck)
		
		# Multi-Tiered Ship Aft Superstructure / Navigation Bridge with Windows, Bridge Wings, Radar Mast & Funnel
		var aft_pos: Vector3 = ship_pos - xform.basis.z * 15.5
		main.call("_add_prop", Vector3(8.2, 4.4, 8.8), aft_pos + Vector3(0.0, 6.0, 0.0), xform.basis, bridge_white)
		main.call("_add_prop", Vector3(9.6, 2.0, 5.8), aft_pos + Vector3(0.0, 9.0, 1.2), xform.basis, bridge_white)
		main.call("_add_prop", Vector3(9.75, 0.78, 5.95), aft_pos + Vector3(0.0, 9.25, 1.2), xform.basis, bridge_glass)
		main.call("_add_prop", Vector3(2.0, 3.6, 2.8), aft_pos + Vector3(0.0, 11.4, -1.5), xform.basis, hull_rust)
		main.call("_add_prop", Vector3(0.28, 5.8, 0.28), aft_pos + Vector3(0.0, 12.8, 1.5), xform.basis, cable_steel)
		main.call("_add_prop", Vector3(3.2, 0.22, 0.22), aft_pos + Vector3(0.0, 14.8, 1.5), xform.basis, bridge_white)
		
		# 2-Tier Stacked Intermodal Shipping Containers on Cargo Deck
		for ci in 3:
			for tier in 2:
				var c_mat := _make_pbr_metal(container_colors[(hi + ci + tier) % container_colors.size()], 0.52, 0.35, 0.65)
				var c_pos: Vector3 = ship_pos + xform.basis.z * (float(ci - 1) * 10.6 + 4.5) + Vector3(0.0, 5.15 + float(tier) * 2.55, 0.0)
				main.call("_add_prop", Vector3(7.2, 2.45, 9.6), c_pos, xform.basis, c_mat)
			
		# Open-Lattice Articulated Yellow Harbor Port Crane on the Quayside reaching over the moored cargo ship (-X)
		var crane_base: Vector3 = xform * Vector3(quay_lat - 1.2, 0.40, -8.0)
		# 4 Slender Gantry Portal Legs + Cross-Tie Beams + Upper Slewing Turntable House + Glass Operator Cab
		for lx in [-1.8, 1.8]:
			for lz in [-2.2, 2.2]:
				main.call("_add_prop", Vector3(0.38, 5.2, 0.38), crane_base + Vector3(lx, 2.6, lz), xform.basis, crane_yellow)
			main.call("_add_prop", Vector3(0.32, 0.35, 4.6), crane_base + Vector3(lx, 2.8, 0.0), xform.basis, crane_yellow)
		main.call("_add_prop", Vector3(4.2, 2.2, 4.8), crane_base + Vector3(0.0, 6.0, 0.0), xform.basis, crane_yellow)
		main.call("_add_prop", Vector3(1.8, 1.7, 2.4), crane_base + Vector3(-2.1, 6.1, 1.6), xform.basis, bridge_glass)
		# A-Frame Mast Tower (2 slender chords instead of a solid block)
		for mz in [-0.85, 0.85]:
			main.call("_add_prop", Vector3(0.36, 12.0, 0.36), crane_base + Vector3(-0.8, 12.5, mz), xform.basis, crane_yellow)
		# Open-Lattice Twin-Chord Luffing Boom + 6 Cross-Rungs reaching out toward -X over the moored cargo ship
		var boom_basis: Basis = xform.basis.rotated(xform.basis.z.normalized(), deg_to_rad(38.0))
		var boom_center: Vector3 = crane_base + Vector3(-7.4, 16.2, 0.0)
		for bz in [-0.72, 0.72]:
			main.call("_add_prop", Vector3(0.32, 22.5, 0.32), boom_center + xform.basis.z * bz, boom_basis, crane_yellow)
		for rung_i in 6:
			var r_off: float = -9.0 + float(rung_i) * 3.6
			var r_pos: Vector3 = boom_center + boom_basis.y * r_off
			main.call("_add_prop", Vector3(0.24, 0.24, 1.55), r_pos, boom_basis, crane_yellow)
		# Dual Hoist Cables + Spreader Bar
		for cz in [-0.45, 0.45]:
			main.call("_add_prop", Vector3(0.08, 14.0, 0.08), crane_base + Vector3(-13.2, 15.2, cz), xform.basis, cable_steel)
		main.call("_add_prop", Vector3(2.2, 0.35, 3.2), crane_base + Vector3(-13.2, 8.2, 0.0), xform.basis, crane_yellow)
		
		# Quayside Heavy Forklift / Container Handler Vehicle & Dockside Stacked Containers
		var loader_base: Vector3 = xform * Vector3(quay_lat + 0.8, 0.40, 11.0)
		main.call("_add_prop", Vector3(2.4, 1.6, 3.8), loader_base + Vector3(0.0, 0.8, 0.0), xform.basis, crane_yellow)
		main.call("_add_prop", Vector3(1.6, 1.3, 1.7), loader_base + Vector3(0.0, 2.0, -0.4), xform.basis, bridge_glass)

	# 2. Distant Industrial Power-Plant Reactor Domes, Hyperbolic Cooling Towers & Tall Slender Smokestacks on the right horizon (-X)
	var stack_offsets: Array[float] = [155.0, 235.0, 315.0, 1680.0, 2280.0]
	for si in stack_offsets.size():
		var so: float = stack_offsets[si]
		if so >= track_len - 40.0:
			continue
		var sxform: Transform3D = main.call("_track_transform", so, 0.0)
		var slat: float = -(road_half + 88.0 + float(si % 2) * 16.0)
		var sh: float = rng.randf_range(76.0, 102.0)
		
		# Sculpted Domed Reactor Containment Shell & Hyperbolic Cooling Tower on the distant industrial horizon
		var dome_base := CylinderMesh.new()
		dome_base.top_radius = 13.5
		dome_base.bottom_radius = 15.0
		dome_base.height = 24.0
		dome_base.material = stack_mat
		var db_inst := MeshInstance3D.new()
		db_inst.mesh = dome_base
		db_inst.position = sxform * Vector3(slat - 10.0, 12.0, -12.0)
		track_root.add_child(db_inst)
		
		var dome_top := SphereMesh.new()
		dome_top.radius = 13.5
		dome_top.height = 16.0
		dome_top.material = quay_concrete
		var dt_inst := MeshInstance3D.new()
		dt_inst.mesh = dome_top
		dt_inst.position = sxform * Vector3(slat - 10.0, 24.0, -12.0)
		track_root.add_child(dt_inst)
		
		# Hyperbolic Cooling Tower
		var cool_tower := CylinderMesh.new()
		cool_tower.top_radius = 8.5
		cool_tower.bottom_radius = 13.5
		cool_tower.height = 38.0
		cool_tower.material = stack_mat
		var ct_inst := MeshInstance3D.new()
		ct_inst.mesh = cool_tower
		ct_inst.position = sxform * Vector3(slat - 8.0, 19.0, 16.0)
		track_root.add_child(ct_inst)
		
		for pair_i in 2:
			var spos: Vector3 = sxform * Vector3(slat - float(pair_i) * 10.5, sh * 0.5, float(pair_i) * 9.0)
			var cyl := CylinderMesh.new()
			cyl.top_radius = 1.65
			cyl.bottom_radius = 2.85
			cyl.height = sh
			cyl.material = stack_mat
			var c_inst := MeshInstance3D.new()
			c_inst.mesh = cyl
			c_inst.position = spos
			track_root.add_child(c_inst)
			
			# Large Industrial Steam / Smoke Plume rising from each smokestack top
			var plume_mesh := QuadMesh.new()
			plume_mesh.size = Vector2(18.0, 28.0)
			var pmat := ShaderMaterial.new()
			pmat.shader = STEAM_VENT_SHADER
			pmat.set_shader_parameter("steam_color", Color(0.82, 0.78, 0.72, 0.42))
			pmat.set_shader_parameter("speed", 0.45)
			plume_mesh.material = pmat
			var p_inst := MeshInstance3D.new()
			p_inst.mesh = plume_mesh
			p_inst.position = spos + Vector3(0.0, sh * 0.5 + 11.0, 0.0)
			track_root.add_child(p_inst)
			var p_inst2 := MeshInstance3D.new()
			p_inst2.mesh = plume_mesh
			p_inst2.position = spos + Vector3(0.0, sh * 0.5 + 11.0, 0.0)
			p_inst2.rotation_degrees.y = 90.0
			track_root.add_child(p_inst2)


## Layer 5B: Wet Pavement Reflection Pools & Ambient Neon Street Glow
static func _build_neon_billboards(main: Node, track_root: Node3D, _rng: RandomNumberGenerator, living_ctrl: Node3D) -> void:
	var board_count: int = 20
	var track_len: float = float(main.get("track_length"))
	var spacing: float = track_len / float(board_count)
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var sw_h: float = float(main.get("ROAD_HEIGHT")) + 0.18
	
	var wet_pool_mat := ShaderMaterial.new()
	wet_pool_mat.shader = OIL_PUDDLE_SHADER
	
	for i in board_count:
		var o: float = (float(i) + 0.35) * spacing
		var xform: Transform3D = main.call("_track_transform", o, 0.0)
		var side: float = 1.0 if (i % 2 == 0) else -1.0
		var sign_color: Color = NEON_COLORS[i % NEON_COLORS.size()]
		
		var screen_mat := StandardMaterial3D.new()
		screen_mat.albedo_color = sign_color * 0.25
		screen_mat.emission_enabled = true
		screen_mat.emission = sign_color
		screen_mat.emission_energy_multiplier = 2.0
		
		var neon_light := OmniLight3D.new()
		neon_light.light_color = sign_color
		neon_light.light_energy = 1.8
		neon_light.omni_range = 22.0
		neon_light.omni_attenuation = 1.4
		neon_light.distance_fade_enabled = true
		neon_light.distance_fade_begin = 85.0
		neon_light.distance_fade_length = 25.0
		neon_light.position = xform * Vector3(side * (road_half + 3.2), 7.5, 0.0)
		track_root.add_child(neon_light)
		
		# Wet Pavement Reflection Pool beneath neon signage ("casting pools of pink, green, and electric blue onto wet pavement")
		var pool_mesh := PlaneMesh.new()
		pool_mesh.size = Vector2(2.6, 5.5)
		pool_mesh.material = wet_pool_mat
		var pool_inst := MeshInstance3D.new()
		pool_inst.mesh = pool_mesh
		pool_inst.transform = Transform3D(xform.basis, xform * Vector3(side * (road_half + 2.4), sw_h + 0.006, 0.0))
		track_root.add_child(pool_inst)
		
		if living_ctrl:
			living_ctrl.call("register_neon_light", neon_light, screen_mat, 1.8, float(i) * 0.37)
			if i % 4 == 0:
				living_ctrl.call("add_neon_hum_emitter", xform * Vector3(side * (road_half + 3.8), 3.2, 0.0))


static func _build_urban_soundscapes(_main: Node, track_root: Node3D) -> void:
	var snd_path := "res://sounds/subway_vent_hum.wav"
	if ResourceLoader.exists(snd_path):
		var ambient_player := AudioStreamPlayer.new()
		ambient_player.name = "UrbanAmbientCanyon"
		ambient_player.stream = load(snd_path)
		ambient_player.volume_db = -18.0
		ambient_player.autoplay = true
		track_root.add_child(ambient_player)


static func _init_glass_materials() -> Array[ShaderMaterial]:
	var mats: Array[ShaderMaterial] = []
	for p in FACADE_PALETTES:
		var m := ShaderMaterial.new()
		m.shader = SKYSCRAPER_SHADER
		m.set_shader_parameter("facade_color", p.facade)
		m.set_shader_parameter("glass_color", p.glass)
		m.set_shader_parameter("lit_color_1", p.window_lit)
		m.set_shader_parameter("concrete_albedo_tex", TEX_CONCRETE_DIFF)
		m.set_shader_parameter("concrete_normal_tex", TEX_CONCRETE_NOR)
		m.set_shader_parameter("storefront_tex", TEX_STOREFRONT_RAMEN)
		m.set_shader_parameter("use_pbr_tex", true)
		mats.append(m)
	return mats


static func _init_brick_materials() -> Array[ShaderMaterial]:
	var mats: Array[ShaderMaterial] = []
	for p in BRICK_PALETTES:
		var m := ShaderMaterial.new()
		m.shader = BRICK_WAREHOUSE_SHADER
		m.set_shader_parameter("brick_color_primary", p.primary)
		m.set_shader_parameter("brick_color_secondary", p.secondary)
		m.set_shader_parameter("mortar_color", p.mortar)
		m.set_shader_parameter("window_lit_color", p.window_lit)
		m.set_shader_parameter("brick_albedo_tex", TEX_BRICK_DIFF)
		m.set_shader_parameter("brick_normal_tex", TEX_BRICK_NOR)
		m.set_shader_parameter("concrete_albedo_tex", TEX_CONCRETE_DIFF)
		m.set_shader_parameter("use_pbr_tex", true)
		mats.append(m)
	return mats


static func _init_residential_materials() -> Array[ShaderMaterial]:
	var mats: Array[ShaderMaterial] = []
	for p in RESIDENTIAL_PALETTES:
		var m := ShaderMaterial.new()
		m.shader = RESIDENTIAL_MEGABLOCK_SHADER
		m.set_shader_parameter("concrete_color", p.concrete)
		m.set_shader_parameter("spandrel_color", p.spandrel)
		m.set_shader_parameter("warm_light", p.warm_light)
		m.set_shader_parameter("cool_light", p.cool_light)
		m.set_shader_parameter("concrete_albedo_tex", TEX_CONCRETE_DIFF)
		m.set_shader_parameter("concrete_normal_tex", TEX_CONCRETE_NOR)
		m.set_shader_parameter("storefront_tex", TEX_STOREFRONT_RAMEN)
		m.set_shader_parameter("use_pbr_tex", true)
		mats.append(m)
	return mats


static func _init_industrial_materials() -> Array[ShaderMaterial]:
	var mats: Array[ShaderMaterial] = []
	for p in INDUSTRIAL_PALETTES:
		var m := ShaderMaterial.new()
		m.shader = INDUSTRIAL_LOGISTICS_SHADER
		m.set_shader_parameter("metal_color", p.metal)
		m.set_shader_parameter("rust_color", p.rust)
		m.set_shader_parameter("hazard_yellow", p.caution)
		m.set_shader_parameter("iron_albedo_tex", TEX_IRON_DIFF)
		m.set_shader_parameter("iron_normal_tex", TEX_IRON_NOR)
		m.set_shader_parameter("use_pbr_tex", true)
		mats.append(m)
	return mats


## A network of flat city streets laid across the single map: a grid of asphalt roads with
## collision, so the one map has many roads to drive. Buildings that sit on a street are removed.
static func _build_city_street_grid(main: Node, track_root: Node3D, rng: RandomNumberGenerator) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://textures/asphalt_track/asphalt_track_diff_2k.jpg")
	mat.albedo_color = Color(0.40, 0.42, 0.46)
	mat.normal_enabled = true
	mat.normal_texture = load("res://textures/asphalt_track/asphalt_track_nor_gl_2k.jpg")
	mat.normal_scale = 1.2
	mat.roughness = 0.72
	mat.metallic = 0.2
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * 0.5
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.88, 0.72, 0.16)
	line_mat.roughness = 0.55
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.25, 0.2, 0.05)
	line_mat.emission_energy_multiplier = 0.4

	var width := 14.0
	var thick := 0.20
	var extent := 900.0
	var step := 260.0
	var rects: Array[AABB] = []

	# East-west streets.
	var z: float = -extent
	while z <= extent:
		var length_x: float = extent * 2.0
		var pos := Vector3(0.0, thick * 0.5, z)
		main.call("_add_prop", Vector3(length_x, thick, width), pos, Basis(), mat)
		_add_street_line(track_root, Vector3(0.0, thick + 0.005, z), Vector3(length_x, 0.02, 0.5), line_mat)
		rects.append(AABB(Vector3(-extent, 0.0, z - width * 0.5 - 11.0), Vector3(length_x, 6.0, width + 22.0)))
		z += step

	# North-south streets.
	var x: float = -extent
	while x <= extent:
		var length_z: float = extent * 2.0
		var pos2 := Vector3(x, thick * 0.5, 0.0)
		main.call("_add_prop", Vector3(width, thick, length_z), pos2, Basis(), mat)
		_add_street_line(track_root, Vector3(x, thick + 0.005, 0.0), Vector3(0.5, 0.02, length_z), line_mat)
		rects.append(AABB(Vector3(x - width * 0.5 - 11.0, 0.0, -extent), Vector3(width + 22.0, 6.0, length_z)))
		x += step

	_purge_buildings_on_streets(track_root, rects)
	print("CityBuilder: built a city street grid (%d streets)" % rects.size())


static func _add_street_line(track_root: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	track_root.add_child(mi)


static func _purge_buildings_on_streets(track_root: Node3D, rects: Array[AABB]) -> void:
	var doomed: Array[Node] = []
	for body in track_root.get_children():
		if not (body is StaticBody3D):
			continue
		var shape_node: CollisionShape3D = null
		for c in body.get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
				shape_node = c
				break
		if shape_node == null:
			continue
		var box: BoxShape3D = shape_node.shape
		if box.size.y < 8.0:
			continue # not a building
		var gt: Transform3D = (body as Node3D).global_transform * shape_node.transform
		var centre := Vector3(gt.origin.x, 3.0, gt.origin.z)
		var half := Vector3(box.size.x * 0.5, 3.0, box.size.z * 0.5)
		var bb := AABB(centre - half, half * 2.0)
		var hit := false
		for r in rects:
			if r.intersects(bb):
				hit = true
				break
		if not hit:
			continue
		doomed.append(body)
		for m in track_root.get_children():
			if m is MeshInstance3D and (m as Node3D).global_position.distance_to((body as Node3D).global_position) < 0.02:
				doomed.append(m)
	for n in doomed:
		n.queue_free()


## Skeletal-animated characters (CC0 service droids + CC BY walkers) that stride along the
## sidewalks, idle, and wave at the player. These give the city real articulated motion.
static func _build_animated_characters(main: Node, track_root: Node3D, living_ctrl: Node, rng: RandomNumberGenerator) -> void:
	if living_ctrl == null or not living_ctrl.has_method("spawn_rpm_character"):
		return
	var track_len: float = float(main.get("track_length"))
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var walker_scale := 1.0
	if OS.get_environment("WALKER_SCALE") != "":
		walker_scale = maxf(0.0, float(OS.get_environment("WALKER_SCALE")))
	var count := int(160.0 * walker_scale)
	var spawned := 0
	for i in count:
		var o: float = rng.randf() * track_len
		var xf: Transform3D = main.call("_track_transform", o, 0.0)
		if xf.origin.y > 2.5:
			continue
		var side: float = 1.0 if rng.randf() < 0.5 else -1.0
		var lat: float = side * (road_half + rng.randf_range(1.9, 3.2))
		var dir: float = 1.0 if rng.randf() < 0.5 else -1.0
		var speed: float = rng.randf_range(0.9, 1.6)
		var person: PackedScene = CHAR_PEOPLE[i % CHAR_PEOPLE.size()]
		living_ctrl.call("spawn_rpm_character", track_root, person, o, lat, speed, dir, 1.78, 0.0)
		spawned += 1
	print("CityBuilder: %d realistic people walking the sidewalks" % spawned)


## ---------------------------------------------------------------------------
## Dense ambient crowd: thousands of lightweight instanced people (MultiMesh) so
## the streets feel packed. Each person is dealt a personality that decides where
## they stand and how they behave (timid people keep back near the buildings,
## curious ones crowd the kerb, friendly ones gather in the plazas), and a subtle
## sway shader keeps the crowd alive for almost no CPU cost.
## ---------------------------------------------------------------------------
const CROWD_SHADER := """
shader_type spatial;
render_mode cull_back, diffuse_burley;

void vertex() {
	float phase = INSTANCE_CUSTOM.r * 6.2831853;
	float activity = INSTANCE_CUSTOM.g;
	float h = max(VERTEX.y, 0.0);
	float s = sin(TIME * 1.6 + phase);
	VERTEX.x += s * 0.035 * activity * h;
	VERTEX.z += cos(TIME * 1.25 + phase) * 0.020 * activity * h;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
"""

static func _build_crowd_mesh(radius: float, height: float, head_r: float) -> ArrayMesh:
	# A simple stylised humanoid: two legs, a torso, two arms and a head, ~1.7 m tall.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leg_h: float = height * 0.5
	var leg_w: float = radius * 0.58
	for sx in [-1.0, 1.0]:
		var leg := BoxMesh.new()
		leg.size = Vector3(leg_w, leg_h, leg_w * 1.1)
		st.append_from(leg, 0, Transform3D(Basis(), Vector3(sx * radius * 0.40, leg_h * 0.5, 0.0)))
	var torso := CapsuleMesh.new()
	torso.radius = radius
	torso.height = maxf(height * 0.66, radius * 2.05)
	torso.radial_segments = 6
	torso.rings = 3
	st.append_from(torso, 0, Transform3D(Basis(), Vector3(0.0, leg_h + torso.height * 0.5, 0.0)))
	for sx in [-1.0, 1.0]:
		var arm := BoxMesh.new()
		arm.size = Vector3(leg_w * 0.8, height * 0.38, leg_w * 0.9)
		st.append_from(arm, 0, Transform3D(Basis(), Vector3(sx * (radius + leg_w * 0.45), leg_h + height * 0.34, 0.0)))
	var head := SphereMesh.new()
	head.radius = head_r
	head.height = head_r * 2.0
	head.radial_segments = 6
	head.rings = 3
	st.append_from(head, 0, Transform3D(Basis(), Vector3(0.0, leg_h + torso.height + head_r * 1.1, 0.0)))
	return st.commit()


static func _build_dense_crowd(main: Node, track_root: Node3D, rng: RandomNumberGenerator) -> void:
	if not main.has_method("_track_transform"):
		return
	var track_len: float = float(main.get("track_length"))
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	if track_len < 200.0:
		return

	# Realistic baked people (Ready Player Me) in a natural walking pose. We use the baked
	# static meshes so thousands of textured people stay cheap; fall back to the procedural
	# humanoid if the baked resources are missing.
	var people_paths := [
		"res://models/people/claudia_pose.res",
		"res://models/people/eric_pose.res",
		"res://models/people/nathan_pose.res",
		"res://models/people/carla_pose.res",
	]
	var variants: Array = []
	var realistic := true
	for pp in people_paths:
		if ResourceLoader.exists(pp):
			variants.append([load(pp), 300, 0.0095])
		else:
			realistic = false
	var shader := Shader.new()
	shader.code = CROWD_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	if not realistic:
		variants = [
			[_build_crowd_mesh(0.20, 0.95, 0.105), 1250, 1.0],
			[_build_crowd_mesh(0.26, 1.02, 0.120), 1250, 1.0],
			[_build_crowd_mesh(0.22, 0.78, 0.100), 1250, 1.0],
			[_build_crowd_mesh(0.16, 0.62, 0.090), 1250, 1.0],
		]

	# CROWD_SCALE env var scales the population (handy for profiling; 1.0 is the full city).
	var crowd_scale := 1.0
	if OS.get_environment("CROWD_SCALE") != "":
		crowd_scale = maxf(0.0, float(OS.get_environment("CROWD_SCALE")))

	var total := 0
	for vi in variants.size():
		var mesh: Mesh = variants[vi][0]
		var count: int = int(int(variants[vi][1]) * crowd_scale)
		var mesh_scale: float = float(variants[vi][2])
		if count <= 0 or mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = count
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Crowd_%d" % vi
		mmi.multimesh = mm
		if not realistic:
			mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		track_root.add_child(mmi)

		# Gather people in small clusters (a queue at a bus stop, friends in a plaza,
		# curious onlookers at the kerb) so the streets read as busy rather than evenly sprinkled.
		var idx := 0
		while idx < count:
			var cluster_o: float = rng.randf() * track_len
			var cluster_side: float = 1.0 if rng.randf() < 0.5 else -1.0
			var persona: int = rng.randi() % 4
			var members: int = rng.randi_range(3, 7)
			for m in members:
				if idx >= count:
					break
				var o: float = fposmod(cluster_o + rng.randf_range(-3.5, 3.5), track_len)
				var xf: Transform3D = main.call("_track_transform", o, 0.0)
				if xf.origin.y > 2.5:
					idx += 1
					continue
				var lat: float = 0.0
				var facing: float = 0.0
				match persona:
					0: # TIMID: keeps back, away from the road
						lat = road_half + 5.0 + rng.randf_range(0.0, 2.0)
						facing = 180.0
					1: # CURIOUS: right at the kerb, watching the traffic
						lat = road_half + 1.7 + rng.randf_range(0.0, 0.7)
						facing = -90.0 * cluster_side
					2: # OBLIVIOUS: mid-sidewalk, going about their day
						lat = road_half + 3.1 + rng.randf_range(0.0, 1.2)
						facing = rng.randf_range(0.0, 360.0)
					_: # FRIENDLY: gathered out in the plaza
						lat = road_half + 6.5 + rng.randf_range(0.0, 6.0)
						facing = rng.randf_range(-55.0, 55.0)

				var pos: Vector3 = xf * Vector3(cluster_side * lat, 0.40, 0.0)
				var yaw: float = deg_to_rad(facing) + xf.basis.get_euler().y
				var sc: float = rng.randf_range(0.92, 1.08) * mesh_scale
				var basis := Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc, sc))
				mm.set_instance_transform(idx, Transform3D(basis, pos))
				total += 1
				idx += 1
		# Hide any unused instances.
		for k in range(idx, count):
			mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0.0, -1000.0, 0.0)))

	print("CityBuilder: populated the streets with %d realistic crowdspeople" % total)
