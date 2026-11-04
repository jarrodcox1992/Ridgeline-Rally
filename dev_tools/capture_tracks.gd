extends SceneTree

func _init() -> void:
	print("--- CAPTURING TRACK SCREENSHOTS ---")
	var MainScript := preload("res://main.gd")
	var main: Node3D = MainScript.new()
	root.add_child(main)
	
	for frame in 5:
		await process_frame
		
	var screenshot_dir := "/Users/j/.gemini/antigravity/brain/e4909efe-cd92-49e4-ba0c-0cb857cb4344/screenshots"
	DirAccess.make_dir_recursive_absolute(screenshot_dir)
	
	var track_names: Array[String] = [
		"track_alpine_pass",
		"track_akina_touge",
		"track_coastal_speedway",
		"track_forest_gp"
	]
	
	for i in main.TRACK_DATA.size():
		print("Capturing track %d: %s..." % [i, main.TRACK_DATA[i].name])
		main.load_track(i)
		
		# Let terrain, physics, and textures settle
		for frame in 20:
			main._physics_process(0.016)
			await process_frame
			
		# Elevate camera slightly for a dramatic overview of the new road
		if main.camera and main.car:
			main.camera_view = 1 # Far chase view
			main.camera.global_position = main.car.global_position - main.car.global_basis.z * 14.0 + Vector3.UP * 5.0
			main.camera.look_at(main.car.global_position + main.car.global_basis.z * 10.0 + Vector3.UP * 1.5, Vector3.UP)
			
		for frame in 5:
			await process_frame
			
		var img := root.get_viewport().get_texture().get_image()
		var save_path: String = screenshot_dir + "/" + track_names[i] + ".png"
		img.save_png(save_path)
		print("Saved screenshot: ", save_path)
		
	print("ALL SCREENSHOTS CAPTURED!")
	quit(0)
