extends SceneTree

func _init() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)

	var c := Curve3D.new()
	c.add_point(Vector3(0, 0, 0))
	c.add_point(Vector3(0, 0, 100))
	var p3d := Path3D.new()
	p3d.curve = c
	root_node.add_child(p3d)

	var poly := CSGPolygon3D.new()
	poly.polygon = PackedVector2Array([
		Vector2(11.5, 0.22),
		Vector2(11.5, 0.40),
		Vector2(16.0, 0.40),
		Vector2(16.0, 0.0)
	])
	poly.mode = CSGPolygon3D.MODE_PATH
	poly.path_interval = 2.0
	poly.use_collision = true
	root_node.add_child(poly)
	poly.path_node = poly.get_path_to(p3d)

	var sub := CSGBox3D.new()
	sub.operation = CSGShape3D.OPERATION_SUBTRACTION
	sub.size = Vector3(12.0, 4.0, 30.0)
	sub.position = Vector3(14.0, 0.3, 50.0)
	poly.add_child(sub)

	await create_timer(0.2).timeout
	print("SUCCESS: CSG MODE_PATH subtraction executed cleanly!")
	root_node.queue_free()
	quit(0)
