extends SceneTree
# Side profile of the generated car, low down: for each 4 cm slice along its length, how far the
# lower body sticks out and its top height in the band. Tyres show up as bulges at both ends.
func _initialize() -> void:
	var scene: Node = (load("res://models/your_car/your_car_shape.glb") as PackedScene).instantiate()
	var mi: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var ymin := -0.260; var h := 0.501
	var out := {}
	var low := {}
	for v in verts:
		var f := (v.y - ymin) / h
		if f < 0.14 or f > 0.6: continue
		var k := int(floor(v.z / 0.04))
		out[k] = maxf(out.get(k, 0.0), absf(v.x))
		# lowest body point in this slice (arch opening shows as a high "lowest point")
		low[k] = minf(low.get(k, 1.0), f)
	var keys := out.keys(); keys.sort()
	print("PROFILE ", keys.map(func(k): return "z%.2f:x%.3f:low%.2f" % [k * 0.04, out[k], low[k]]))
	quit()
