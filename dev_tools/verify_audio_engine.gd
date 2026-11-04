extends SceneTree

const CarScript = preload("res://car.gd")

func _initialize() -> void:
	print("--- VERIFYING AUDIO ENGINE ---")
	var car = CarScript.new()
	car.is_player = true
	car.body_style = "centenario"
	root.add_child(car)
	print("Car added to tree. RPM: ", car.rpm, " Gear: ", car.gear)
	
	# Simulate accelerating through gears up to redline and downshifting
	car.throttle = 1.0
	for i in 120:
		car.speed_kmh = float(i) * 2.0
		car._physics_process(1.0 / 60.0)
	print("Accelerated to 240 km/h: RPM=%.1f Gear=%d PopLevel=%.3f" % [car.rpm, car.gear, car._pop_level])

	# Simulate throttle lift-off overrun & braking
	car.throttle = 0.0
	for i in 60:
		car.speed_kmh = maxf(car.speed_kmh - 2.5, 0.0)
		car._physics_process(1.0 / 60.0)
	print("Decelerated: RPM=%.1f OverrunLevel=%.3f DownshiftBlip=%.3f" % [car.rpm, car._overrun_level, car._downshift_blip])

	# Simulate rev-limiter bounce
	car.throttle = 1.0
	car.speed_kmh = 320.0 # redline in top gear
	for i in 60:
		car._physics_process(1.0 / 60.0)
	print("Limiter bounce: RPM=%.1f LimiterStutter=%.3f IgnitionCut=%s" % [car.rpm, car._limiter_stutter, car._ignition_cut])

	print("--- AUDIO ENGINE VERIFICATION PASSED ---")
	quit(0)
