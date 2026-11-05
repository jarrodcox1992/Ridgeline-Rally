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
	
	var captures: Array[Dictionary] = [
		{"index": 0, "tod": 1, "slug": "highway_autobahn", "title": "Trans-Alpine Autobahn"},
		{"index": 1, "tod": 0, "slug": "highway_spa", "title": "Spa Ardennes Expressway"},
		{"index": 3, "tod": 1, "slug": "highway_monza", "title": "Monza Super-Autostrada"},
		{"index": 0, "tod": 2, "slug": "highway_night", "title": "Highway Night Lighting & Luminaires"}
	]
	
	for cap in captures:
		var idx: int = cap.index
		var tod: int = cap.tod
		var slug: String = cap.slug
		print("Capturing %s (Track %d, TOD %d)..." % [cap.title, idx, tod])
		main.set_time_of_day(tod)
		main.load_track(idx)
		
		# Let terrain, physics, and textures settle
		for frame in 20:
			main._physics_process(0.016)
			await process_frame
			
		# Elevate camera slightly for a dramatic overview of the wide 4-lane highway
		if main.camera and main.car:
			main.camera_view = 1 # Far chase view
			main.camera.global_position = main.car.global_position - main.car.global_basis.z * 18.0 + Vector3.UP * 7.2
			main.camera.look_at(main.car.global_position + main.car.global_basis.z * 14.0 + Vector3.UP * 1.5, Vector3.UP)
			
		for frame in 6:
			await process_frame
			
		var img := root.get_viewport().get_texture().get_image()
		var save_path: String = screenshot_dir + "/" + slug + ".png"
		img.save_png(save_path)
		print("Saved screenshot: ", save_path)
		
	print("ALL SCREENSHOTS CAPTURED!")
	quit(0)
