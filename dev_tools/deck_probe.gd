extends SceneTree
# Profiles the top of the car body near the rear: highest point in each 10 cm slice.
var model: Node3D
var frames := 0
func _initialize() -> void:
	model = load("res://models/car_concept.glb").instantiate()
	root.add_child(model)
func _process(_d: float) -> bool:
	frames += 1
	if frames < 2: return false
	var top := {}
	var zmin := 0.0
	for mi: MeshInstance3D in model.find_children("Body*", "MeshInstance3D", true, false):
		var xf := mi.global_transform
		for si in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
			for v in verts:
				var p := xf * v
				zmin = minf(zmin, p.z)
				if absf(p.x) < 0.75 and p.z < -0.8:
					var k := int(floor(p.z * 10.0))
					top[k] = maxf(top.get(k, -9.0), p.y)
	var keys := top.keys(); keys.sort()
	print("DECK rear_z=%.2f " % zmin, keys.map(func(k): return "z%.1f:y%.2f" % [k / 10.0, top[k]]))
	quit()
	return false
