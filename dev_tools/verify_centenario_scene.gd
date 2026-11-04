@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/centenario.tscn")
	var inst: Node3D = scene_res.instantiate()
	root.add_child(inst)
	print("Root name: ", inst.name)
	for child in inst.get_children():
		print("- Child: ", child.name, " (", child.get_class(), ") pos=", child.position, " subchildren=", child.get_child_count())
		
	var steer = inst.find_child("InteriorSteeringCylinder", true, false)
	print("Steering wheel found: ", steer != null)
	if steer:
		print("Steering wheel position: ", steer.global_position)
		
	for w_name in ["WheelFrontL", "WheelFrontR", "WheelRearL", "WheelRearR"]:
		var w = inst.find_child(w_name, true, false)
		print(w_name, " found: ", w != null, " children: ", w.get_child_count() if w else 0)
		if w and w.get_child_count() > 0:
			var w_mesh = w.get_child(0) as MeshInstance3D
			print("   first child aabb: ", w_mesh.mesh.get_aabb())
			
	quit(0)
