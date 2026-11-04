extends SceneTree
# Turns the raw image-to-3D car into a game body: scales it to real size, faces it down +Z,
# drops the ground/smoke slab, cuts out the fused wheels, and recomputes smooth normals.
const SCALE := 2.5
const GROUND_Y := -0.19 # model units: bottom of the tyres
const SLAB_LIMIT := -0.195 # triangles centred below this (13% up the model) are ground or smoke
const WHEEL_Z := [-0.52, 0.54] # model units, front then rear
const WHEEL_Y := -0.045
const WHEEL_CUT_R := 0.158
const WHEEL_CUT_X := 0.24 # only cut the outer part where the tyres are

func _initialize() -> void:
	var scene: Node = (load("res://models/your_car/your_car_shape.glb") as PackedScene).instantiate()
	var mi: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	print("BAKE in: verts=%d tris=%d" % [verts.size(), idx.size() / 3])
	var keep := PackedInt32Array()
	var dropped_slab := 0
	var dropped_wheel := 0
	for t in range(0, idx.size(), 3):
		var c := (verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0
		# The slab is wide and low; the body itself never gets this low.
		if c.y < SLAB_LIMIT:
			dropped_slab += 1
			continue
		var in_wheel := false
		for wz: float in WHEEL_Z:
			if absf(c.x) > WHEEL_CUT_X and Vector2(c.z - wz, c.y - WHEEL_Y).length() < WHEEL_CUT_R:
				in_wheel = true
		if in_wheel:
			dropped_wheel += 1
			continue
		keep.append_array([idx[t], idx[t + 1], idx[t + 2]])
	# Re-index only the vertices still in use, moved into the car's frame:
	# metres, ground at y = 0, nose towards +Z (the model's nose points to -Z).
	var remap := {}
	var out_verts := PackedVector3Array()
	var out_idx := PackedInt32Array()
	for i in keep:
		if not remap.has(i):
			remap[i] = out_verts.size()
			var v := verts[i]
			out_verts.append(Vector3(-v.x, v.y - GROUND_Y, -v.z) * SCALE)
		out_idx.append(remap[i])
	# Flipping two axes keeps the winding, so triangles still face outwards.
	var st := SurfaceTool.new()
	var new_arrays := []
	new_arrays.resize(Mesh.ARRAY_MAX)
	new_arrays[Mesh.ARRAY_VERTEX] = out_verts
	new_arrays[Mesh.ARRAY_INDEX] = out_idx
	st.create_from_arrays(new_arrays)
	st.generate_normals()
	var mesh := st.commit()
	var aabb := mesh.get_aabb()
	ResourceSaver.save(mesh, "res://models/your_car/your_car_body.res")
	print("BAKE out: verts=%d tris=%d dropped slab=%d wheels=%d aabb=%s" % [out_verts.size(), out_idx.size() / 3, dropped_slab, dropped_wheel, aabb])
	quit()
