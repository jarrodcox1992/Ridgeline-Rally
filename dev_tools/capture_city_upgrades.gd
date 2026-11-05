extends SceneTree

func _init() -> void:
	print("--- COMMENCING CITY UPGRADES & ROAD REPAIR SCREENSHOT CAPTURE ---")
	var MainScript := preload("res://main.gd")
	var main: Node3D = MainScript.new()
	root.add_child(main)
	
	# Wait for city, materials and shaders to initialize
	for frame in 20:
		await process_frame
		
	var brain_dir := "/Users/j/.gemini/antigravity/brain/156bd9d6-1a53-48ee-bcb7-b969f9e18c4c/screenshots"
	var project_dir := "/Users/j/Documents/Ridgeline Rally/screenshots"
	DirAccess.make_dir_recursive_absolute(brain_dir)
	DirAccess.make_dir_recursive_absolute(project_dir)
	
	var track_len: float = main.track_length
	print("Track initialized: %s (Length: %.1fm)" % [main.TRACK_DATA[main.current_track_index].name, track_len])
	
	# --- 1. ▲ Sky-Expressway Overpass (y=16.2m elevated viaduct with Jersey barriers and cyan LED strips) ---
	print("Capturing 1: Sky-Expressway Overpass...")
	main.set_time_of_day(2) # Night for glowing cyan LEDs
	var overpass_curve: Curve3D = main.alternate_curves[0]
	var overpass_mid := overpass_curve.sample_baked(overpass_curve.get_baked_length() * 0.45, true)
	if main.camera and main.car:
		main.car.reset_to(Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), overpass_mid + Vector3.UP * 0.5))
		main.camera.global_position = overpass_mid + Vector3(-18.0, 8.5, -22.0)
		main.camera.look_at(overpass_mid + Vector3(15.0, 2.0, 15.0), Vector3.UP)
	for f in 15:
		main._physics_process(0.016)
		await process_frame
	_save_screen(brain_dir, project_dir, "01_sky_expressway_overpass")
	
	# --- 2. ► Hyper-Straight Bypass (chord-straightened top-speed outer straight) ---
	print("Capturing 2: Hyper-Straight Bypass...")
	main.set_time_of_day(1) # Sunset
	var bypass_curve: Curve3D = main.alternate_curves[1]
	var bypass_pt := bypass_curve.sample_baked(bypass_curve.get_baked_length() * 0.35, true)
	var bypass_ahead := bypass_curve.sample_baked(bypass_curve.get_baked_length() * 0.55, true)
	if main.camera and main.car:
		main.car.reset_to(Transform3D(Basis.looking_at((bypass_ahead - bypass_pt).normalized(), Vector3.UP), bypass_pt + Vector3.UP * 0.4))
		main.camera.global_position = bypass_pt - (bypass_ahead - bypass_pt).normalized() * 16.0 + Vector3.UP * 4.5 + Vector3(4.0, 0.0, 4.0)
		main.camera.look_at(bypass_pt + (bypass_ahead - bypass_pt).normalized() * 25.0 + Vector3.UP * 1.5, Vector3.UP)
	for f in 15:
		main._physics_process(0.016)
		await process_frame
	_save_screen(brain_dir, project_dir, "02_hyper_straight_bypass")
	
	# --- 3. ◄ Neon Tunnel Split-Route (covered brutalist tunnel gallery with magenta neon ribs) ---
	print("Capturing 3: Neon Tunnel Split-Route...")
	main.set_time_of_day(2) # Night for glowing magenta ribs
	var tunnel_curve: Curve3D = main.alternate_curves[2]
	var tunnel_pt := tunnel_curve.sample_baked(tunnel_curve.get_baked_length() * 0.42, true)
	var tunnel_ahead := tunnel_curve.sample_baked(tunnel_curve.get_baked_length() * 0.60, true)
	if main.camera and main.car:
		main.car.reset_to(Transform3D(Basis.looking_at((tunnel_ahead - tunnel_pt).normalized(), Vector3.UP), tunnel_pt + Vector3.UP * 0.4))
		main.camera.global_position = tunnel_pt - (tunnel_ahead - tunnel_pt).normalized() * 12.0 + Vector3.UP * 2.8
		main.camera.look_at(tunnel_pt + (tunnel_ahead - tunnel_pt).normalized() * 28.0 + Vector3.UP * 1.8, Vector3.UP)
	for f in 15:
		main._physics_process(0.016)
		await process_frame
	_save_screen(brain_dir, project_dir, "03_neon_tunnel_split_route")
	
	# --- 4. Color-coded multi-route Minimap and expanded lap checkpoint bounding boxes ---
	print("Capturing 4: Color-Coded Multi-Route Minimap & Lap Checkpoints...")
	main.set_time_of_day(0) # Daylight
	var cp_spot: Transform3D = main._track_transform(track_len * 0.10, 0.8)
	if main.camera and main.car:
		main.car.reset_to(cp_spot)
		main.camera.global_position = cp_spot.origin - cp_spot.basis.z * 14.0 + Vector3.UP * 5.0
		main.camera.look_at(cp_spot.origin + cp_spot.basis.z * 30.0 + Vector3.UP * 2.0, Vector3.UP)
	for f in 15:
		main._physics_process(0.016)
		await process_frame
	_save_screen(brain_dir, project_dir, "04_color_coded_minimap_and_checkpoints")
	
	# --- 5. RoadRepairController DAMAGED state (potholed cracked surface + traction reduction) ---
	print("Capturing 5: RoadRepairController Damaged State...")
	if not main.road_repair_zones.is_empty():
		var repair_zone = main.road_repair_zones[0]
		var r_pos: Vector3 = repair_zone.global_position
		if main.camera and main.car:
			main.car.reset_to(Transform3D(Basis.looking_at(repair_zone.global_transform.basis.z, Vector3.UP), r_pos - repair_zone.global_transform.basis.z * 8.0 + Vector3.UP * 0.5))
			main.camera.global_position = r_pos - repair_zone.global_transform.basis.z * 16.0 + repair_zone.global_transform.basis.x * 5.0 + Vector3.UP * 4.8
			main.camera.look_at(r_pos + Vector3.UP * 0.8, Vector3.UP)
		for f in 15:
			main._physics_process(0.016)
			await process_frame
		_save_screen(brain_dir, project_dir, "05_road_repair_damaged_state")
		
		# --- 6. RoadRepairController Trigger Repair -> FIXED state (particles & pristine asphalt) ---
		print("Capturing 6: RoadRepairController Repair In-Progress & Fixed State...")
		repair_zone.repair_duration = 0.5
		repair_zone.trigger_repair()
		for f in 8:
			main._physics_process(0.016)
			await process_frame
		_save_screen(brain_dir, project_dir, "06_road_repair_active_routine")
		
		# Wait for coroutine to complete
		var wait_elapsed := 0.0
		while repair_zone.current_state != 2 and wait_elapsed < 2.0:
			main._physics_process(0.016)
			await process_frame
			wait_elapsed += 0.016
		for f in 10:
			main._physics_process(0.016)
			await process_frame
		_save_screen(brain_dir, project_dir, "07_road_repair_fixed_state")
	
	# --- 7. CityGroundMesh scaled to 3,800m with 2K PBR materials (High Aerial Vista) ---
	print("Capturing 7: CityGroundMesh 3,800m 2K PBR Aerial Overview...")
	main.set_time_of_day(0) # Golden Day
	if main.camera and main.car:
		main.camera.global_position = Vector3(0.0, 180.0, -320.0)
		main.camera.look_at(Vector3(0.0, 0.0, 120.0), Vector3.UP)
	for f in 15:
		main._physics_process(0.016)
		await process_frame
	_save_screen(brain_dir, project_dir, "08_city_ground_mesh_3800m_pbr")
	
	# --- 8. Track Tour: Veridia Sky-Expressway & Sector-9 Autobahn A-95 ---
	print("Capturing 8: Veridia Sky-Expressway...")
	main.load_track(1) # Veridia Sky-Expressway
	for f in 25:
		main._physics_process(0.016)
		await process_frame
	if main.camera and main.car:
		main.camera.global_position = main.car.global_position - main.car.global_basis.z * 18.0 + Vector3.UP * 7.5
		main.camera.look_at(main.car.global_position + main.car.global_basis.z * 40.0 + Vector3.UP * 4.0, Vector3.UP)
	for f in 10:
		main._physics_process(0.016)
		await process_frame
	_save_screen(brain_dir, project_dir, "09_track_veridia_sky_expressway")
	
	print("Capturing 9: Sector-9 Autobahn A-95...")
	main.load_track(4) # Sector-9 Autobahn A-95
	for f in 25:
		main._physics_process(0.016)
		await process_frame
	if main.camera and main.car:
		main.camera.global_position = main.car.global_position - main.car.global_basis.z * 22.0 + Vector3.UP * 9.0
		main.camera.look_at(main.car.global_position + main.car.global_basis.z * 50.0 + Vector3.UP * 4.5, Vector3.UP)
	for f in 10:
		main._physics_process(0.016)
		await process_frame
	_save_screen(brain_dir, project_dir, "10_track_sector9_autobahn_a95")
	
	print("\n============================================================")
	print(" ALL 10 CITY UPGRADE SCREENSHOTS CAPTURED SUCCESSFULLY! ")
	print("============================================================")
	quit(0)


func _save_screen(brain_dir: String, project_dir: String, slug: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	var p1: String = brain_dir + "/" + slug + ".png"
	var p2: String = project_dir + "/" + slug + ".png"
	img.save_png(p1)
	img.save_png(p2)
	print("  Saved: %s" % slug)
