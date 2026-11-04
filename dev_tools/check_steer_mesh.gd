@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/centenario.tscn")
	var inst: Node3D = scene_res.instantiate()
	var steer: Node3D = inst.find_child("InteriorSteeringCylinder", true, false)
	for c in steer.get_children():
		if c is MeshInstance3D:
			print("Steer mesh: ", c.name, " aabb=", c.mesh.get_aabb())
	quit(0)
