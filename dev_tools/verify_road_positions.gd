extends SceneTree

func _init() -> void:
	print("\n--- ROAD & ENVIRONMENT OBJECT POSITION VERIFICATION ---")
	
	var main_scene := load("res://main.tscn")
	if not main_scene:
		printerr("FAIL: Could not load main.tscn")
		quit(1)
		return
	print("✓ main.tscn loaded")
	
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	
	await create_timer(0.25).timeout
	
	var road_h: float = float(main.get("ROAD_HEIGHT"))
	var road_half: float = float(main.get("ROAD_HALF_WIDTH"))
	var track_len: float = float(main.get("track_length"))
	var sw_h: float = road_h + 0.18 # 0.40m
	
	print("✓ Road Dimensions: Half-Width = %.2fm, Road Height = %.2fm, Sidewalk Elevation = %.2fm" % [road_half, road_h, sw_h])
	assert(absf(road_h - 0.22) < 0.01, "ROAD_HEIGHT must be 0.22m")
	assert(absf(road_half - 11.5) < 0.01, "ROAD_HALF_WIDTH must be 11.5m")
	assert(absf(sw_h - 0.40) < 0.01, "Sidewalk elevation must be 0.40m")
	
	# 1. Verify Road Repair Zones Placement & Lane Confinement
	var repair_zones: Array = main.get("road_repair_zones")
	assert(repair_zones.size() >= 2, "Must have at least 2 dynamic road repair zones")
	for i in repair_zones.size():
		var z: Node3D = repair_zones[i]
		var local_x: float = z.transform.origin.x
		# Must be in outer lane (|x| >= 5.0m), leaving passing lane open
		assert(absf(local_x) >= 5.0, "Repair zone %d must be in outer lane (|x| >= 5.0m), got %.2fm" % [i, local_x])
		print("✓ Road Repair Zone %d: Placed in outer lane at lateral = %.2fm (passing lane 100%% clear)" % [i, local_x])
	
	# 2. Verify Living City Traffic Vehicles: Direction vs Lane Sign
	var living_ctrl: Node = main.find_child("LivingCityController", true, false)
	assert(living_ctrl != null, "LivingCityController must exist")
	
	var traffic_vehs: Array = living_ctrl.get("_traffic_vehicles")
	assert(traffic_vehs.size() >= 20, "Should have active autonomous cyber-traffic fleet (got %d)" % traffic_vehs.size())
	
	var forward_count := 0
	var oncoming_count := 0
	for veh in traffic_vehs:
		var lat: float = float(veh.base_lat)
		var dir: float = float(veh.dir)
		var y_off: float = float(veh.y_offset)
		
		# Grounding check: vehicle should ride flush with road surface (0.22m)
		assert(absf(y_off - road_h) < 0.02, "Vehicle y_offset must match ROAD_HEIGHT (0.22m), got %.3fm" % y_off)
		
		# Direction vs Lane convention check:
		# Right side (lat < 0) -> dir == 1.0 (forward travel)
		# Left side (lat > 0) -> dir == -1.0 (oncoming travel)
		if dir > 0.0:
			assert(lat < -1.0, "Forward vehicle must be in right lane (lat < -1.0m), got %.2fm" % lat)
			forward_count += 1
		else:
			assert(lat > 1.0, "Oncoming vehicle must be in left lane (lat > 1.0m), got %.2fm" % lat)
			oncoming_count += 1
			
	print("✓ Traffic Fleet Orientation Verified: %d Forward vehicles (right lanes) & %d Oncoming vehicles (left lanes)" % [forward_count, oncoming_count])
	print("✓ Traffic Fleet Vertical Grounding Verified: All vehicles ride flush at road surface y = %.2fm" % road_h)
	
	# 3. Verify Pedestrians Grounding
	var citizens: Array = living_ctrl.get("_citizens")
	assert(citizens.size() >= 10, "Should have active citizen AI")
	for cit in citizens:
		var role: int = int(cit.role)
		var elev_y: float = float(cit.elev_y)
		# Commuters and sidewalk vendors must be grounded at sidewalk elevation (sw_h = 0.40m)
		if role in [0, 2, 3]: # COMMUTER, VENDOR, DRIFTER
			assert(absf(elev_y - sw_h) < 0.02, "Sidewalk citizen elevation must be sw_h (0.40m), got %.3fm" % elev_y)
	print("✓ Sidewalk Pedestrian Grounding Verified: Walking at true sidewalk elevation y = %.2fm (0%% sinking)" % sw_h)

	print("\n=======================================================")
	print(" ALL ROAD OBJECT POSITIONS AND ELEVATIONS VERIFIED 100% ")
	print("=======================================================\n")
	
	main.queue_free()
	quit(0)
