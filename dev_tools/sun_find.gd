extends SceneTree
# Finds the sun in an equirectangular HDRI and prints its direction in Godot's sky convention.
func _initialize() -> void:
	var img := Image.load_from_file(OS.get_environment("HDR"))
	img.resize(512, 256, Image.INTERPOLATE_BILINEAR)
	var best := 0.0
	var best_p := Vector2i.ZERO
	for y in img.get_height() / 2:
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var l := c.r + c.g + c.b
			if l > best:
				best = l
				best_p = Vector2i(x, y)
	var u := (best_p.x + 0.5) / img.get_width()
	var v := (best_p.y + 0.5) / img.get_height()
	var phi := u * TAU
	var theta := v * PI
	var dir := Vector3(sin(theta) * sin(phi), cos(theta), -sin(theta) * cos(phi))
	print("SUN pixel=", best_p, " lum=", best, " dir=", dir, " elevation_deg=", rad_to_deg(asin(dir.y)))
	quit()
