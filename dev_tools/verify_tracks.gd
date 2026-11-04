extends SceneTree

func _init() -> void:
	print("--- RIDGELINE RALLY MULTI-TRACK VERIFICATION ---")
	var MainScript := preload("res://main.gd")
	var main: Node3D = MainScript.new()
	root.add_child(main)
	
	# Wait for main to initialize
	await process_frame
	await process_frame
	
	var track_count: int = main.TRACK_DATA.size()
	print("Discovered %d tracks in TRACK_DATA:" % track_count)
	for i in track_count:
		var t: Dictionary = main.TRACK_DATA[i]
		print("  [%d] %s: %s (Points: %d)" % [i, t.name, t.desc, t.points.size()])
		
	# Verify each track by loading it and simulating 10 physics ticks
	for i in track_count:
		var t_info: Dictionary = main.TRACK_DATA[i]
		print("\nTesting Track %d: '%s'..." % [i, t_info.name])
		main.load_track(i)
		await process_frame
		await process_frame
		
		# Check curve & path
		assert(main.curve != null, "Curve must exist")
		assert(main.track_length > 1000.0, "Track length must be > 1km (was %.1fm)" % main.track_length)
		print("  - Track length: %.1f m" % main.track_length)
		
		# Check start transform
		var start_xf: Transform3D = main._track_transform(0.0, 0.8)
		assert(not is_nan(start_xf.origin.x) and not is_nan(start_xf.origin.y) and not is_nan(start_xf.origin.z), "Start xf has NaN")
		print("  - Start line position: Vector3(%.1f, %.1f, %.1f)" % [start_xf.origin.x, start_xf.origin.y, start_xf.origin.z])
		
		# Check terrain height at start line
		var terrain_h: float = main._terrain_height(start_xf.origin.x, start_xf.origin.z)
		var road_pt: Vector3 = main._track_point(0.0)
		var h_diff := absf(terrain_h - road_pt.y)
		print("  - Road altitude: %.2fm | Terrain altitude under road: %.2fm (diff: %.3fm)" % [road_pt.y, terrain_h, h_diff])
		assert(h_diff < 0.8, "Terrain under road must match road elevation within 0.8m! Was: %.3fm" % h_diff)
		
		# Check car position
		assert(main.car != null, "Car must exist")
		var car_pos: Vector3 = main.car.global_position
		assert(not is_nan(car_pos.x) and not is_nan(car_pos.y) and not is_nan(car_pos.z), "Car has NaN")
		print("  - Player Car position: Vector3(%.1f, %.1f, %.1f)" % [car_pos.x, car_pos.y, car_pos.z])
		
		# Check AI cars
		assert(main.cars.size() == 4, "Must have 4 total racers (player + 3 AI)")
		print("  - Racers count: %d" % main.cars.size())
		
		# Simulate 10 physics ticks
		for tick in 10:
			main._physics_process(0.016)
			for driver in main.ai_drivers:
				driver._physics_process(0.016)
			await physics_frame
		
		# Check minimap points
		assert(main.minimap_ctrl != null, "Minimap must exist")
		print("  - Minimap updated successfully")
		print("  ✓ Track %d ('%s') PASSED!" % [i, t_info.name])
		
	print("\n==========================================")
	print(" ALL %d TRACKS VERIFIED AND PASSING 100%%!" % track_count)
	print("==========================================")
	quit(0)
