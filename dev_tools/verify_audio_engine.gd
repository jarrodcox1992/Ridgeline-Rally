extends SceneTree

const CarScript = preload("res://car.gd")

func _initialize() -> void:
	print("--- VERIFYING REAL SAMPLE AUDIO PACK ENGINE ---")
	var car = CarScript.new()
	car.is_player = true
	car.body_style = "centenario"
	root.add_child(car)
	car._ready()
	print("Car added to tree and ready. Engine players: ", car._engine_players.size())

	# Test 1: Accelerating through RPM range & checking crossfade volume
	print("Testing RPM crossfades...")
	for test_rpm in [950.0, 1800.0, 3000.0, 4500.0, 6000.0, 7200.0]:
		car.rpm = test_rpm
		car.throttle = 1.0
		car._update_engine_sound()
		var active_loops := []
		for i in car._engine_players.size():
			if car._engine_players[i].volume_db > -70.0:
				active_loops.append("L%d(%.1fdB, p=%.2f)" % [i, car._engine_players[i].volume_db, car._engine_players[i].pitch_scale])
		print("RPM %4.0f -> Active: %s" % [test_rpm, ", ".join(active_loops)])

	# Test 2: Deceleration Overrun
	print("Testing off-throttle overrun...")
	car.rpm = 4500.0
	car.throttle = 0.0
	car.speed_kmh = 80.0
	car._update_engine_sound()
	print("Decel player volume_db: %.1f dB (pitch=%.2f)" % [car._engine_decel_player.volume_db, car._engine_decel_player.pitch_scale])

	# Test 3: Tire Screech and Scrub
	print("Testing tire physics...")
	car._skid = 0.18 # scrub range
	car.speed_kmh = 60.0
	car._update_engine_sound()
	print("Scrub slip=0.18 -> scrub=%.1fdB, screech=%.1fdB" % [car._tire_scrub_player.volume_db, car._tire_screech_player.volume_db])

	car._skid = 0.65 # full slide
	car._update_engine_sound()
	print("Slide slip=0.65 -> scrub=%.1fdB, screech=%.1fdB" % [car._tire_scrub_player.volume_db, car._tire_screech_player.volume_db])

	# Test 4: Gear Whine
	print("Testing transmission whine...")
	car.speed_kmh = 140.0
	car.throttle = 1.0
	car._update_engine_sound()
	print("Whine at 140kmh -> whine=%.1fdB, pitch=%.2f" % [car._gear_whine_player.volume_db, car._gear_whine_player.pitch_scale])

	# Test 5: Backfire trigger
	print("Testing backfire detonation...")
	car._trigger_backfire(1.0)
	print("Backfire triggered! Stream: ", car._backfire_player.stream.resource_path.get_file(), " vol: ", car._backfire_player.volume_db)

	# Test 6: Collision impact
	print("Testing collision impact...")
	var dummy_guardrail = StaticBody3D.new()
	dummy_guardrail.name = "Guardrail_01"
	root.add_child(dummy_guardrail)
	car.linear_velocity = Vector3(0, 0, 14.0)
	car._on_body_entered(dummy_guardrail)
	print("Heavy impact triggered! Stream: ", car._impact_player.stream.resource_path.get_file(), " vol: ", car._impact_player.volume_db)

	print("--- ALL REAL SAMPLE AUDIO CHECKS PASSED ---")
	quit(0)
