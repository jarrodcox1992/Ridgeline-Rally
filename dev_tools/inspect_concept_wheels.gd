@tool
extends SceneTree

func _init():
	var scene_res = load("res://models/car_concept.glb")
	var inst: Node3D = scene_res.instantiate()
	for child in inst.find_children("*", "Node3D"):
		if "Wheel" in child.name:
			print("Concept Wheel: ", child.name, " class=", child.get_class(), " pos=", child.position, " rot=", child.rotation_degrees)
			for sub in child.get_children():
				print("   Sub: ", sub.name, " class=", sub.get_class())
	quit(0)
