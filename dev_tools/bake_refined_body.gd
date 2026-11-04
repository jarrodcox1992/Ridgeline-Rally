extends SceneTree
# Refined mesh baker: protects the front fender from over-cutting while cleanly
# clearing the wheel wells and smoke/ground slab.
const SCALE := 2.5
const GROUND_Y := -0.19 # model units: bottom of the tyres
const SLAB_LIMIT := -0.195 # triangles centred below this are ground or smoke
const WHEEL_CUT_X := 0.24 # only cut the outer part where the tyres are

# Front wheel: z = -0.52, wheel radius in model units is 0.36/2.5 = 0.144
# Rear wheel: z = 0.54, wheel radius in model units is 0.36/2.5 = 0.144
const WHEELS_DATA := [
	{"z": -0.52, "y": -0.045, "rx": 0.150, "ry": 0.142}, # Front: slightly flattened vertically to protect fender
	{"z": 0.54, "y": -0.045, "rx": 0.156, "ry": 0.154},  # Rear: slightly taller arch
]

func _initialize() -> void:
	var scene: Node = (load("res://models/your_car/your_car_shape.glb") as PackedScene).instantiate()
	var mi: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	print("REFINED BAKE in: verts=%d tris=%d" % [verts.size(), idx.size() / 3])
	var keep := PackedInt32Array()
	var dropped_slab := 0
	var dropped_wheel := 0

	for t in range(0, idx.size(), 3):
		var c := (verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0
		if c.y < SLAB_LIMIT:
			dropped_slab += 1
			continue
		var in_wheel := false
		if absf(c.x) > WHEEL_CUT_X:
			for w in WHEELS_DATA:
				var dz: float = (c.z - w.z) / w.rx
				var dy: float = (c.y - w.y) / w.ry
				if dz * dz + dy * dy < 1.0:
					in_wheel = true
					break
		if in_wheel:
			dropped_wheel += 1
			continue
		keep.append_array([idx[t], idx[t + 1], idx[t + 2]])

	var remap := {}
	var out_verts := PackedVector3Array()
	var out_idx := PackedInt32Array()
	for i in keep:
		if not remap.has(i):
			remap[i] = out_verts.size()
			var v := verts[i]
			out_verts.append(Vector3(-v.x, v.y - GROUND_Y, -v.z) * SCALE)
		out_idx.append(remap[i])

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
	print("REFINED BAKE out: verts=%d tris=%d dropped slab=%d wheels=%d aabb=%s" % [out_verts.size(), out_idx.size() / 3, dropped_slab, dropped_wheel, aabb])
	quit()
