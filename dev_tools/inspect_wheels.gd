@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	
	var root_node = inst.get_node("Sketchfab_model/root/GLTF_SceneRootNode")
	for child in root_node.get_children():
		if "Wheel" in child.name or "wheel" in child.name.to_lower():
			print("\nNode: ", child.name, " pos=", child.position, " rot=", child.rotation_degrees, " scale=", child.scale)
			for sub in child.get_children():
				if sub is MeshInstance3D:
					print("  Mesh: ", sub.name, " aabb=", sub.mesh.get_aabb(), " surfs=", sub.mesh.get_surface_count())
					for s in range(sub.mesh.get_surface_count()):
						var m = sub.mesh.surface_get_material(s)
						print("    surf ", s, " mat: ", m.resource_name if m else "none")
	quit(0)
