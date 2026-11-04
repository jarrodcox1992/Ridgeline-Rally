extends SceneTree
# Points a camera at each candidate sun direction and records how bright the screen centre is.
var cam: Camera3D
var candidates := [Vector3(-0.374, 0.745, -0.552), Vector3(0.374, 0.745, -0.552), Vector3(-0.374, 0.745, 0.552), Vector3(0.374, 0.745, 0.552)]
var i := 0
var frames := 0
func _initialize() -> void:
	var mat := PanoramaSkyMaterial.new()
	mat.panorama = load("res://textures/sky/kloofendal_puresky_4k.hdr")
	var sky := Sky.new(); sky.sky_material = mat
	var env := Environment.new(); env.background_mode = Environment.BG_SKY; env.sky = sky
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	cam = Camera3D.new(); cam.fov = 20.0; root.add_child(cam)
func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:
		cam.look_at_from_position(Vector3.ZERO, candidates[i], Vector3.UP)
	if frames == 6:
		var img := root.get_viewport().get_texture().get_image()
		var c := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
		print("CAND ", i, " ", candidates[i], " centre=", c)
		img.save_png(OS.get_environment("OUT") + "/sun_%d.png" % i)
		i += 1; frames = 0
		if i >= candidates.size(): quit()
	return false
