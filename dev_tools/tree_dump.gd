extends SceneTree
func _initialize() -> void:
	var doc := GLTFDocument.new(); var state := GLTFState.new()
	var err := doc.append_from_file(OS.get_environment("MODEL"), state)
	var scene := doc.generate_scene(state)
	print("ERR=", err, " root=", scene)
	_dump(scene, 0)
	quit()
func _dump(n: Node, d: int) -> void:
	print("TREE ", "  ".repeat(d), n.name, " : ", n.get_class())
	for c in n.get_children(): _dump(c, d + 1)
