extends SceneTree

func _init() -> void:
	print("--- CAPTURING UNIFIED METROPOLIS GRAND CIRCUIT SCREENSHOTS ---")
	var MainScript := preload("res://main.gd")
	var main: Node3D = MainScript.new()
	root.add_child(main)
	
	for frame in 10:
		await process_frame
		
	var screenshot_dir := "/Users/j/.gemini/antigravity/brain/0e473df5-5236-401a-9d8f-ea85b39c6bb0/screenshots"
	DirAccess.make_dir_recursive_absolute(screenshot_dir)
	
	var track_len: float = main.track_length
	var captures: Array[Dictionary] = [
		{
			"offset": 42.0,
			"tod": 0,
			"slug": "neo_veridia_aerial_overview",
			"title": "Neo-Veridia Grand Vista: Multi-Tier Terraces, Bullet Monorail, Skywalks & Harbor (Golden Day)",
			"cam_dist": 14.0,
			"cam_h": 13.8,
			"cam_lat": 3.2,
			"look_ahead": 75.0,
			"look_up": 7.5
		},
		{
			"offset": 0.0,
			"tod": 0,
			"slug": "sector1_financial_core",
			"title": "Sector 1: Downtown Financial Core & Start Grid (Day)",
			"cam_dist": 13.5,
			"cam_h": 4.2,
			"look_ahead": 18.0,
			"look_up": 2.8
		},
		{
			"offset": track_len * 0.34,
			"tod": 2,
			"slug": "sector2_neon_strip_night",
			"title": "Sector 2: Neon Entertainment Strip, Vending & Bus Shelter (Night)",
			"cam_dist": 14.0,
			"cam_h": 4.4,
			"look_ahead": 20.0,
			"look_up": 3.2
		},
		{
			"offset": 405.0,
			"tod": 1,
			"slug": "emergency_staging_sunset",
			"title": "Emergency Response Bay: Police Cruiser, Ambulance & Billboards (Sunset)",
			"cam_dist": 13.0,
			"cam_h": 3.8,
			"look_ahead": 18.0,
			"look_up": 2.4
		},
		{
			"offset": track_len * 0.62,
			"tod": 0,
			"slug": "sector3_brick_el_train",
			"title": "Sector 3: Historic 2K Brick Warehouses, Fire Escapes & El-Train (Day)",
			"cam_dist": 14.0,
			"cam_h": 4.4,
			"look_ahead": 20.0,
			"look_up": 3.0
		},
		{
			"offset": track_len * 0.84,
			"tod": 1,
			"slug": "sector4_industrial_logistics",
			"title": "Sector 4: Industrial Logistics Corridor & Skyline Towers (Sunset)",
			"cam_dist": 15.0,
			"cam_h": 4.8,
			"look_ahead": 22.0,
			"look_up": 3.2
		}
	]
	
	for cap in captures:
		var tod: int = cap.tod
		var slug: String = cap.slug
		var offset: float = float(cap.offset)
		print("Capturing %s (Offset %.1fm, TOD %d)..." % [cap.title, offset, tod])
		main.set_time_of_day(tod)
		
		if main.car and offset > 0.0:
			var spot: Transform3D = main._track_transform(offset, 0.8)
			main.car.reset_to(spot)
			
		for frame in 16:
			main._physics_process(0.016)
			await process_frame
			
		main.set_process(false)
		main.set_physics_process(false)
		if main.camera and main.car:
			var xform: Transform3D = main._track_transform(offset, 0.8)
			var car_pos: Vector3 = main.car.global_position
			var forward: Vector3 = xform.basis.z
			var right: Vector3 = xform.basis.x
			var lat_off: float = float(cap.get("cam_lat", 0.0))
			main.camera.global_position = car_pos - forward * float(cap.cam_dist) + right * lat_off + Vector3.UP * float(cap.cam_h)
			main.camera.look_at(car_pos + forward * float(cap.look_ahead) + Vector3.UP * float(cap.look_up), Vector3.UP)
			
		for frame in 4:
			await process_frame
		main.set_process(true)
		main.set_physics_process(true)
			
		var img := root.get_viewport().get_texture().get_image()
		var save_path: String = screenshot_dir + "/" + slug + ".png"
		img.save_png(save_path)
		print("Saved screenshot: ", save_path)
		
	print("ALL UNIFIED CITY SCREENSHOTS CAPTURED SUCCESSFULLY!")
	quit(0)
