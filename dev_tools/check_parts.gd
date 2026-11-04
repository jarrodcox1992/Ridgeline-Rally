@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	
	var root_node = inst.get_node("Sketchfab_model/root/GLTF_SceneRootNode")
	print("Direct children of GLTF_SceneRootNode:")
	for child in root_node.get_children():
		var child_min := Vector3(INF, INF, INF)
		var child_max := Vector3(-INF, -INF, -INF)
		var count := 0
		var meshes = child.find_children("*", "MeshInstance3D")
		if child is MeshInstance3D:
			meshes.append(child)
		for m in meshes:
			var mi = m as MeshInstance3D
			if mi.mesh:
				count += 1
				var aabb = mi.mesh.get_aabb()
				for c in [aabb.position, aabb.end]:
					var p = child.transform * c
					child_min = child_min.min(p)
					child_max = child_max.max(p)
		print(child.name, " (", count, " meshes) pos=", child.position, " aabb_min=", child_min, " aabb_max=", child_max)
		
	quit(0)
