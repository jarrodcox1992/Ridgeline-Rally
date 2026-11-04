@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/scene.gltf")
	if not scene_res:
		print("Failed to load scene.gltf")
		quit(1)
		return
	var inst = scene_res.instantiate()
	root.add_child(inst)
	
	print("--- Scene Hierarchy ---")
	_print_tree(inst, 0)
	
	var total_aabb := AABB()
	var first_aabb := true
	var meshes: Array[MeshInstance3D] = []
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			meshes.append(n)
			var aabb: AABB = n.get_aabb()
			var global_aabb = n.global_transform * aabb
			if first_aabb:
				total_aabb = global_aabb
				first_aabb = false
			else:
				total_aabb = total_aabb.merge(global_aabb)
		for child in n.get_children():
			stack.append(child)
			
	print("\nTotal meshes found: ", meshes.size())
	print("Total Model AABB: ", total_aabb)
	print("Size (X, Y, Z): ", total_aabb.size)
	print("Center: ", total_aabb.get_center())
	
	quit(0)

func _print_tree(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	var extra = ""
	if node is Node3D:
		extra = " pos=" + str(node.position) + " rot=" + str(node.rotation_degrees) + " scale=" + str(node.scale)
	if node is MeshInstance3D and node.mesh:
		extra += " [Mesh: " + str(node.mesh.get_surface_count()) + " surfs, aabb=" + str(node.mesh.get_aabb()) + "]"
	print(indent + "- " + node.name + " (" + node.get_class() + ")" + extra)
	for child in node.get_children():
		_print_tree(child, depth + 1)
