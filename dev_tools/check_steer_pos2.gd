@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/lamborghini_centenario/centenario.tscn")
	var inst: Node3D = scene_res.instantiate()
	var steer: Node3D = inst.find_child("InteriorSteeringCylinder", true, false)
	var t := Transform3D.IDENTITY
	var cur: Node = steer
	while cur and cur != inst:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	print("Steering wheel relative origin: ", t.origin)
	quit(0)
