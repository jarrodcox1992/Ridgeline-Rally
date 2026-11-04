extends SceneTree
func _initialize() -> void:
	var model: Node3D = load("res://models/car_concept.glb").instantiate()
	root.add_child(model)
	var col := model.find_child("InteriorSteeringCylinder", true, false) as Node3D
	var n: Node = col
	while n != null and n != root:
		var n3 := n as Node3D
		print("CHAIN ", n.name, " ", n.get_class(), " basis=", n3.transform.basis if n3 else "-", " pos=", n3.position if n3 else "-")
		n = n.get_parent()
	print("GLOBAL y-axis=", col.global_transform.basis.y, " origin=", col.global_transform.origin)
	quit()
