@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	
	var root_node = inst.get_node("Sketchfab_model/root/GLTF_SceneRootNode")
	var rear_wheels_node = root_node.get_node("<Wheel_0")
	var front_wheels_node = root_node.get_node("<Wheel_003_2")
	
	print("Rear wheels pos=", rear_wheels_node.position, " rot=", rear_wheels_node.rotation_degrees, " scale=", rear_wheels_node.scale)
	print("Front wheels pos=", front_wheels_node.position, " rot=", front_wheels_node.rotation_degrees, " scale=", front_wheels_node.scale)
	
	for child in [rear_wheels_node, front_wheels_node]:
		for m in child.get_children():
			if m is MeshInstance3D and m.mesh is ArrayMesh:
				var am = m.mesh as ArrayMesh
				for s in range(am.get_surface_count()):
					var arrays = am.surface_get_arrays(s)
					var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					var l_count = 0
					var r_count = 0
					for v in verts:
						if v.x > 0.05:
							l_count += 1
						elif v.x < -0.05:
							r_count += 1
					print(m.name, " surf ", s, " total verts: ", verts.size(), " left: ", l_count, " right: ", r_count)
					
	quit(0)
