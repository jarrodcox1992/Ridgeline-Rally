@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	
	var root_node = inst.get_node("Sketchfab_model/root/GLTF_SceneRootNode")
	var rear = root_node.get_node("<Wheel_0")
	var front = root_node.get_node("<Wheel_003_2")
	
	for name_node in [["Front", front], ["Rear", rear]]:
		var name = name_node[0]
		var node = name_node[1]
		var l_min := Vector3(INF, INF, INF)
		var l_max := Vector3(-INF, -INF, -INF)
		var r_min := Vector3(INF, INF, INF)
		var r_max := Vector3(-INF, -INF, -INF)
		
		for m in node.get_children():
			if m is MeshInstance3D and m.mesh is ArrayMesh:
				var am = m.mesh as ArrayMesh
				for s in range(am.get_surface_count()):
					var arrays = am.surface_get_arrays(s)
					var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					for v in verts:
						var world_p = node.transform * v
						if world_p.x > 0.1:
							l_min = l_min.min(world_p)
							l_max = l_max.max(world_p)
						elif world_p.x < -0.1:
							r_min = r_min.min(world_p)
							r_max = r_max.max(world_p)
		print(name, " Left:  Center=", (l_min + l_max)*0.5, " Size=", l_max - l_min, " Radius=", (l_max.y - l_min.y)*0.5)
		print(name, " Right: Center=", (r_min + r_max)*0.5, " Size=", r_max - r_min, " Radius=", (r_max.y - r_min.y)*0.5)
		
	quit(0)
