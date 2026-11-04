@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/centenario.tscn")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	var steer = inst.find_child("InteriorSteeringCylinder", true, false) as Node3D
	print("Steering wheel node: ", steer)
	if steer:
		# Calculate transform relative to car root
		var rel_xform = inst.transform.affine_inverse() * steer.global_transform
		print("Steering wheel origin relative to car: ", rel_xform.origin)
	quit(0)
