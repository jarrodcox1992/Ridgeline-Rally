extends SceneTree
# Renders a model in neutral grey from several angles into a contact sheet, and prints its bounds.
var model: Node3D
var cam: Camera3D
var views := [["front", Vector3(0, 0.15, 1)], ["side", Vector3(1, 0.1, 0)], ["rear", Vector3(0, 0.15, -1)], ["other_side", Vector3(-1, 0.1, 0)], ["three_quarter", Vector3(0.8, 0.45, 0.8)]]
var i := 0
var frames := 0
var center := Vector3.ZERO
var radius := 1.0
func _initialize() -> void:
	var res = load(OS.get_environment("MODEL"))
	if res is Mesh:
		model = Node3D.new()
		var holder := MeshInstance3D.new(); holder.mesh = res; model.add_child(holder)
	else:
		model = (res as PackedScene).instantiate()
	root.add_child(model)
	var grey := StandardMaterial3D.new(); grey.albedo_color = Color(0.6, 0.6, 0.62); grey.roughness = 0.5
	var aabb := AABB()
	var first := true
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = grey
		var b := mi.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	print("MODEL meshes=", model.find_children("*", "MeshInstance3D", true, false).size(), " aabb=", aabb)
	center = aabb.get_center(); radius = aabb.size.length() * 0.75
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.15, 0.16, 0.18)
	env.ambient_light_color = Color(0.5, 0.5, 0.55); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); root.add_child(sun); sun.rotation_degrees = Vector3(-40, 30, 0)
	cam = Camera3D.new(); root.add_child(cam); cam.fov = 40.0
func _process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		var dir: Vector3 = views[i][1]
		cam.look_at_from_position(center + dir.normalized() * radius * 1.6, center, Vector3.UP)
	if frames == 6:
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT") + "/view_%s.png" % views[i][0])
		i += 1; frames = 0
		if i >= views.size(): quit()
	return false
