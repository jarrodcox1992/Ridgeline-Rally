extends SceneTree
# Places a camera at the start of each of the first few corners and saves a screenshot.
var main: Node3D
var cam: Camera3D
var corners: Array
var i := 0
var frames := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	if corners.is_empty():
		corners = main._find_corners()
		print("CORNERS ", corners.size(), " ", corners.map(func(c): return "%d-%d %s" % [c.x, c.y, "L" if c.z > 0 else "R"]))
		cam = Camera3D.new(); root.add_child(cam); cam.make_current(); cam.fov = 65.0
		return false
	frames += 1
	var c: Vector3 = corners[i]
	var xf: Transform3D = main._track_transform(c.x + 6.0, 0.0)
	cam.global_position = xf.origin + Vector3.UP * 2.2 - xf.basis.z * 6.0 + xf.basis.x * c.z * 2.0
	cam.look_at(main._track_point((c.x + c.y) * 0.5) + Vector3.UP * 0.5, Vector3.UP)
	if frames == 20:
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/corner_%d.png" % i)
		print("SHOT ", i)
		i += 1; frames = 0
		if i >= 3: quit()
	return false
