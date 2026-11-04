@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	inst.global_position = Vector3.ZERO
	inst.global_rotation = Vector3.ZERO
	
	print("--- Major Nodes ---")
	for child in inst.find_children("*", "Node3D"):
		var n3d = child as Node3D
		if n3d.get_child_count() > 0 and not (n3d is MeshInstance3D):
			print("Parent Node: ", n3d.name, " path=", inst.get_path_to(n3d), " pos=", n3d.position, " rot=", n3d.rotation_degrees, " scale=", n3d.scale)
			
	print("\n--- Mesh Analysis ---")
	var total_min := Vector3(INF, INF, INF)
	var total_max := Vector3(-INF, -INF, -INF)
	
	for child in inst.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi.mesh:
			var gt: Transform3D = mi.global_transform
			var aabb: AABB = mi.mesh.get_aabb()
			# Transform all 8 corners of the AABB
			for c in [
				Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
				Vector3(aabb.end.x, aabb.position.y, aabb.position.z),
				Vector3(aabb.position.x, aabb.end.y, aabb.position.z),
				Vector3(aabb.end.x, aabb.end.y, aabb.position.z),
				Vector3(aabb.position.x, aabb.position.y, aabb.end.z),
				Vector3(aabb.end.x, aabb.position.y, aabb.end.z),
				Vector3(aabb.position.x, aabb.end.y, aabb.end.z),
				Vector3(aabb.end.x, aabb.end.y, aabb.end.z)
			]:
				var p = gt * c
				total_min = total_min.min(p)
				total_max = total_max.max(p)
				
	print("Global Min: ", total_min)
	print("Global Max: ", total_max)
	print("Global Size: ", total_max - total_min)
	print("Global Center: ", (total_min + total_max) * 0.5)
	
	quit(0)
