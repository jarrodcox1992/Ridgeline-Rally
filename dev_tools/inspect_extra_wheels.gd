@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	var root_node = inst.get_node("Sketchfab_model/root/GLTF_SceneRootNode")
	for name in ["<Wheel_001_1", "<Wheel_002_3", "<Wheel_004_4"]:
		var node = root_node.get_node(name)
		for c in node.get_children():
			if c is MeshInstance3D:
				var m: MeshInstance3D = c
				print(name, " / ", m.name, " aabb=", m.mesh.get_aabb())
				for s in range(m.mesh.get_surface_count()):
					var mat = m.mesh.surface_get_material(s)
					print("   surf ", s, " mat=", mat.resource_name if mat else "none")
	quit(0)
