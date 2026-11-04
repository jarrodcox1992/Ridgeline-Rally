@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/car_concept.glb")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	var w = inst.find_child("WheelFrontL", true, false) as Node3D
	print("Concept WheelFrontL parent: ", w.get_parent().name)
	print("Concept WheelFrontL global transform basis: ", w.global_transform.basis)
	print("Concept WheelFrontL local transform basis: ", w.transform.basis)
	print("Concept WheelFrontL child meshes:")
	for c in w.get_children():
		if c is MeshInstance3D:
			print("  ", c.name, " aabb=", c.mesh.get_aabb(), " pos=", c.position, " rot=", c.rotation_degrees)
	quit(0)
