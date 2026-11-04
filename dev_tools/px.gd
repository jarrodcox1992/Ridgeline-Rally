extends SceneTree
func _initialize() -> void:
	var img := Image.load_from_file(OS.get_environment("IMG"))
	print("PX format=", img.get_format(), " centre=", img.get_pixel(img.get_width() / 2, img.get_height() / 2), " corner=", img.get_pixel(10, 10))
	quit()
