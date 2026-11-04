@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	
	var root_node = inst.get_node("Sketchfab_model/root/GLTF_SceneRootNode")
	var front = root_node.get_node("<Wheel_003_2")
	var m = front.get_node("Object_15") as MeshInstance3D # CRBN_JANTE rim
	var am = m.mesh as ArrayMesh
	var arrays = am.surface_get_arrays(0)
	
	var left_arrays = split_surface(arrays, true, Vector3(0.85, 0.38, 1.20))
	var right_arrays = split_surface(arrays, false, Vector3(-0.85, 0.38, 1.20))
	
	print("Original verts: ", arrays[Mesh.ARRAY_VERTEX].size())
	print("Left verts: ", left_arrays[Mesh.ARRAY_VERTEX].size() if not left_arrays.is_empty() else 0)
	print("Right verts: ", right_arrays[Mesh.ARRAY_VERTEX].size() if not right_arrays.is_empty() else 0)
	
	quit(0)

func split_surface(arrays: Array, is_left: bool, offset: Vector3) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] else PackedInt32Array()
	var new_verts := PackedVector3Array()
	var old_to_new := {}
	
	if indices.size() > 0:
		for i in range(0, indices.size(), 3):
			var i0 = indices[i]
			var i1 = indices[i+1]
			var i2 = indices[i+2]
			var tri_center_x = (verts[i0].x + verts[i1].x + verts[i2].x) / 3.0
			var belongs = (tri_center_x > 0.0) if is_left else (tri_center_x < 0.0)
			if belongs:
				for idx in [i0, i1, i2]:
					if not old_to_new.has(idx):
						old_to_new[idx] = new_verts.size()
						new_verts.append(verts[idx] - offset)
	var res := []
	res.resize(Mesh.ARRAY_MAX)
	res[Mesh.ARRAY_VERTEX] = new_verts
	return res
