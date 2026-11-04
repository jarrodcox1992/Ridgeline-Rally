extends SceneTree
func _initialize() -> void:
	var model: Node = load("res://models/car_concept.glb").instantiate()
	var seen := {}
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i) as StandardMaterial3D
			if m == null or seen.has(m.resource_name) or not m.resource_name.begins_with("Paint 1"): continue
			seen[m.resource_name] = true
			print(m.resource_name, " albedo=", m.albedo_color, " rough=", m.roughness, " metal=", m.metallic, " normal=", m.normal_enabled, "/", m.normal_scale, " uv1=", m.uv1_scale, " ao=", m.ao_enabled, " ao_uv2=", m.ao_on_uv2, " emis=", m.emission_enabled, " cc=", m.clearcoat_enabled)
	quit()
