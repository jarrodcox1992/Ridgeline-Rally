@tool
extends SceneTree

const WHEEL_CENTERS = {
	"WheelFrontL": Vector3(0.853, 0.381, 1.211),
	"WheelFrontR": Vector3(-0.861, 0.381, 1.184),
	"WheelRearL": Vector3(0.849, 0.396, -1.494),
	"WheelRearR": Vector3(-0.849, 0.396, -1.494),
}

func _init():
	print("Building clean Centenario scene...")
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	if not scene_res:
		printerr("Could not load scene.gltf")
		quit(1)
		return

	var raw_scene = scene_res.instantiate()
	root.add_child(raw_scene)

	var gltf_root = raw_scene.get_node("Sketchfab_model/root/GLTF_SceneRootNode")
	if not gltf_root:
		printerr("Could not find GLTF_SceneRootNode")
		quit(1)
		return

	var car_root := Node3D.new()
	car_root.name = "CentenarioCar"
	root.add_child(car_root)

	var body := Node3D.new()
	body.name = "Body"
	car_root.add_child(body)
	body.owner = car_root

	# Create wheel nodes
	var wheel_nodes: Dictionary = {}
	for w_name in WHEEL_CENTERS:
		var wn := Node3D.new()
		wn.name = w_name
		wn.position = WHEEL_CENTERS[w_name]
		car_root.add_child(wn)
		wn.owner = car_root
		wheel_nodes[w_name] = wn

	# Process front and rear wheels
	var front_nodes = [gltf_root.get_node_or_null("<Wheel_003_2"), gltf_root.get_node_or_null("<Wheel_004_4")]
	var rear_nodes = [gltf_root.get_node_or_null("<Wheel_0"), gltf_root.get_node_or_null("<Wheel_001_1"), gltf_root.get_node_or_null("<Wheel_002_3")]

	_process_wheel_group(front_nodes, gltf_root, wheel_nodes["WheelFrontL"], wheel_nodes["WheelFrontR"], WHEEL_CENTERS["WheelFrontL"], WHEEL_CENTERS["WheelFrontR"], car_root)
	_process_wheel_group(rear_nodes, gltf_root, wheel_nodes["WheelRearL"], wheel_nodes["WheelRearR"], WHEEL_CENTERS["WheelRearL"], WHEEL_CENTERS["WheelRearR"], car_root)

	# Now move non-wheel body nodes to body
	var body_node_names = ["Empty_10", "Empty_001_16", "Empty_002_20", "KLM_26", "CR_27", "moteur_11", "SDC_28", "DF_29", "012_30"]
	for b_name in body_node_names:
		var n = gltf_root.get_node_or_null(b_name)
		if n:
			var t = n.transform
			_clear_owner_recursive(n)
			n.get_parent().remove_child(n)
			body.add_child(n)
			n.transform = t
			_set_owner_recursive(n, car_root)

	# Rename steering wheel node so car.gd picks it up
	var steer = body.find_child("movsteer_1_0_7", true, false)
	if steer:
		steer.name = "InteriorSteeringCylinder"
		print("Steering wheel mapped to InteriorSteeringCylinder")

	# Tune materials for high visual fidelity
	_enhance_materials(car_root)

	# Pack and save scene
	var packed := PackedScene.new()
	var err = packed.pack(car_root)
	if err != OK:
		printerr("Failed to pack scene: ", err)
		quit(1)
		return

	var out_path = "res://models/lamborghini_centenario/centenario.tscn"
	err = ResourceSaver.save(packed, out_path)
	if err != OK:
		printerr("Failed to save scene: ", err)
		quit(1)
		return

	print("Successfully updated and verified ", out_path)
	quit(0)

func _clear_owner_recursive(node: Node):
	node.owner = null
	for child in node.get_children():
		_clear_owner_recursive(child)

func _set_owner_recursive(node: Node, new_owner: Node):
	node.owner = new_owner
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)

func _process_wheel_group(source_nodes: Array, gltf_root: Node, left_parent: Node3D, right_parent: Node3D, left_center: Vector3, right_center: Vector3, main_owner: Node):
	for src in source_nodes:
		if not src: continue
		var src_t: Transform3D = src.transform
		for child in src.get_children():
			if child is MeshInstance3D and child.mesh is ArrayMesh:
				var mi = child as MeshInstance3D
				var am = mi.mesh as ArrayMesh
				
				var left_mesh := ArrayMesh.new()
				var right_mesh := ArrayMesh.new()
				var has_left := false
				var has_right := false
				
				for s in range(am.get_surface_count()):
					var arrays = am.surface_get_arrays(s)
					var mat = am.surface_get_material(s)
					
					var l_arr = _split_surface(arrays, src_t, true, left_center)
					if not l_arr.is_empty():
						left_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, l_arr)
						if mat: left_mesh.surface_set_material(left_mesh.get_surface_count() - 1, mat)
						has_left = true
						
					var r_arr = _split_surface(arrays, src_t, false, right_center)
					if not r_arr.is_empty():
						right_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, r_arr)
						if mat: right_mesh.surface_set_material(right_mesh.get_surface_count() - 1, mat)
						has_right = true
						
				if has_left:
					var l_inst := MeshInstance3D.new()
					l_inst.name = mi.name + "_L"
					l_inst.mesh = left_mesh
					left_parent.add_child(l_inst)
					l_inst.owner = main_owner
					
				if has_right:
					var r_inst := MeshInstance3D.new()
					r_inst.name = mi.name + "_R"
					r_inst.mesh = right_mesh
					right_parent.add_child(r_inst)
					r_inst.owner = main_owner

func _split_surface(arrays: Array, node_transform: Transform3D, is_left: bool, center_offset: Vector3) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays.size() > Mesh.ARRAY_NORMAL and arrays[Mesh.ARRAY_NORMAL] else PackedVector3Array()
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT] if arrays.size() > Mesh.ARRAY_TANGENT and arrays[Mesh.ARRAY_TANGENT] else PackedFloat32Array()
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays.size() > Mesh.ARRAY_TEX_UV and arrays[Mesh.ARRAY_TEX_UV] else PackedVector2Array()
	var uvs2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays.size() > Mesh.ARRAY_TEX_UV2 and arrays[Mesh.ARRAY_TEX_UV2] else PackedVector2Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] else PackedInt32Array()
	
	var new_verts := PackedVector3Array()
	var new_normals := PackedVector3Array()
	var new_tangents := PackedFloat32Array()
	var new_uvs := PackedVector2Array()
	var new_uvs2 := PackedVector2Array()
	var new_indices := PackedInt32Array()
	var old_to_new := {}
	
	if indices.size() > 0:
		for i in range(0, indices.size(), 3):
			var i0 = indices[i]
			var i1 = indices[i+1]
			var i2 = indices[i+2]
			var v0 = node_transform * verts[i0]
			var v1 = node_transform * verts[i1]
			var v2 = node_transform * verts[i2]
			var tri_center_x = (v0.x + v1.x + v2.x) / 3.0
			var belongs = (tri_center_x > 0.0) if is_left else (tri_center_x < 0.0)
			if belongs:
				for idx in [i0, i1, i2]:
					if not old_to_new.has(idx):
						var new_idx = new_verts.size()
						old_to_new[idx] = new_idx
						var p = node_transform * verts[idx]
						new_verts.append(p - center_offset)
						if normals.size() > idx:
							new_normals.append((node_transform.basis * normals[idx]).normalized())
						if uvs.size() > idx: new_uvs.append(uvs[idx])
						if uvs2.size() > idx: new_uvs2.append(uvs2[idx])
						if tangents.size() >= (idx + 1) * 4:
							for t in range(4): new_tangents.append(tangents[idx * 4 + t])
					new_indices.append(old_to_new[idx])
	else:
		for i in range(0, verts.size(), 3):
			var v0 = node_transform * verts[i]
			var v1 = node_transform * verts[i+1]
			var v2 = node_transform * verts[i+2]
			var tri_center_x = (v0.x + v1.x + v2.x) / 3.0
			var belongs = (tri_center_x > 0.0) if is_left else (tri_center_x < 0.0)
			if belongs:
				for idx in [i, i+1, i+2]:
					var p = node_transform * verts[idx]
					new_verts.append(p - center_offset)
					if normals.size() > idx:
						new_normals.append((node_transform.basis * normals[idx]).normalized())
					if uvs.size() > idx: new_uvs.append(uvs[idx])
					if uvs2.size() > idx: new_uvs2.append(uvs2[idx])
					if tangents.size() >= (idx + 1) * 4:
						for t in range(4): new_tangents.append(tangents[idx * 4 + t])
					new_indices.append(new_indices.size())

	if new_verts.is_empty():
		return []

	var res := []
	res.resize(Mesh.ARRAY_MAX)
	res[Mesh.ARRAY_VERTEX] = new_verts
	if not new_normals.is_empty(): res[Mesh.ARRAY_NORMAL] = new_normals
	if not new_tangents.is_empty(): res[Mesh.ARRAY_TANGENT] = new_tangents
	if not new_uvs.is_empty(): res[Mesh.ARRAY_TEX_UV] = new_uvs
	if not new_uvs2.is_empty(): res[Mesh.ARRAY_TEX_UV2] = new_uvs2
	if not new_indices.is_empty(): res[Mesh.ARRAY_INDEX] = new_indices
	return res

func _enhance_materials(root_node: Node):
	var seen_mats := {}
	for child in root_node.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi.mesh is ArrayMesh:
			var am = mi.mesh as ArrayMesh
			for s in range(am.get_surface_count()):
				var mat = am.surface_get_material(s)
				if mat and mat is StandardMaterial3D and not seen_mats.has(mat):
					seen_mats[mat] = true
					var m = mat as StandardMaterial3D
					var m_name = m.resource_name.to_lower()
					
					# Body paint
					if "centenario" in m_name or "carrosserie" in m_name or "paint" in m_name:
						m.clearcoat_enabled = true
						m.clearcoat = 0.8
						m.clearcoat_roughness = 0.15
						m.roughness = 0.22
						m.metallic = 0.75
					# Glass & windshield
					elif "klm" in m_name or "glass" in m_name or "vitre" in m_name:
						m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
						m.albedo_color = Color(0.08, 0.10, 0.12, 0.35)
						m.roughness = 0.05
						m.metallic = 0.2
						m.refraction_enabled = true
						m.refraction_scale = 0.02
						m.cull_mode = BaseMaterial3D.CULL_DISABLED
					# Carbon fiber rims
					elif "crbn" in m_name or "carbon" in m_name:
						m.roughness = 0.35
						m.metallic = 0.4
						m.clearcoat_enabled = true
						m.clearcoat = 0.5
					# Tires
					elif "pneu" in m_name or "tire" in m_name:
						m.roughness = 0.85
						m.metallic = 0.05
					# Interior leather
					elif "cuir" in m_name or "leather" in m_name:
						m.roughness = 0.7
						m.metallic = 0.0
					# Taillights
					elif "ligt_red" in m_name:
						m.emission_enabled = true
						m.emission = Color(1.0, 0.05, 0.02)
						m.emission_energy_multiplier = 3.0
						m.albedo_color = Color(0.9, 0.05, 0.05)
					# Headlights
					elif "ligt_blc" in m_name:
						m.emission_enabled = true
						m.emission = Color(1.0, 1.0, 0.95)
						m.emission_energy_multiplier = 2.0
						m.albedo_color = Color(0.95, 0.95, 0.95)
