extends SceneTree
# Measures the generated car: height profile, footprint above the ground slab, and the
# outermost points low down on each side (where the tyres bulge out).
func _initialize() -> void:
	var scene: Node = (load("res://models/your_car/your_car_shape.glb") as PackedScene).instantiate()
	var mi: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var ymin := INF; var ymax := -INF
	for v in verts: ymin = minf(ymin, v.y); ymax = maxf(ymax, v.y)
	var h := ymax - ymin
	# Height histogram in 2.5% bands.
	var bands := {}
	for v in verts:
		var b := int((v.y - ymin) / h * 40.0)
		bands[b] = bands.get(b, 0) + 1
	var keys := bands.keys(); keys.sort()
	print("ANALYZE ymin=%.3f ymax=%.3f" % [ymin, ymax])
	print("HIST ", keys.map(func(k): return "%d:%d" % [k, bands[k]]))
	# Footprint of each height band.
	for frac in [0.02, 0.05, 0.08, 0.12, 0.2, 0.3, 0.5, 0.7]:
		var lo := Vector2(INF, INF); var hi := Vector2(-INF, -INF)
		for v in verts:
			if absf((v.y - ymin) / h - frac) < 0.015:
				lo = Vector2(minf(lo.x, v.x), minf(lo.y, v.z)); hi = Vector2(maxf(hi.x, v.x), maxf(hi.y, v.z))
		print("BAND %.2f x[%.3f,%.3f] z[%.3f,%.3f]" % [frac, lo.x, hi.x, lo.y, hi.y])
	quit()
