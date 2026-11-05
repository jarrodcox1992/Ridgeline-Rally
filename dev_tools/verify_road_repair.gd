extends SceneTree

func _init() -> void:
	_run_tests()


func _run_tests() -> void:
	print("--- ROAD REPAIR CONTROLLER TEST SUITE (GODOT 4.7 GDSCRIPT) ---")
	var RoadRepairScript := preload("res://road_repair_controller.gd")
	var CarScript := preload("res://car.gd")
	
	var test_root := Node3D.new()
	root.add_child(test_root)
	
	await process_frame
	
	var repair_ctrl = RoadRepairScript.new()
	repair_ctrl.name = "TestRoadRepairZone"
	repair_ctrl.repair_duration = 0.20
	repair_ctrl.setup_procedural_visuals(Vector3(12.0, 3.0, 10.0))
	test_root.add_child(repair_ctrl)
	
	# Verify initial state
	assert(repair_ctrl.current_state == RoadRepairScript.RoadState.DAMAGED, "Initial state must be DAMAGED")
	assert(repair_ctrl.damaged_visual.visible == true, "Damaged visual must be visible")
	assert(repair_ctrl.fixed_visual.visible == false, "Fixed visual must be hidden")
	assert(is_equal_approx(repair_ctrl.get_current_traction(), 0.60), "Damaged traction must be 0.60")
	print("  ✓ Step 1: Initial DAMAGED state & visuals verified (traction = 0.60)")
	
	# Create simulated VehicleBody3D with VehicleWheel3D
	var car := VehicleBody3D.new()
	car.set_script(CarScript)
	test_root.add_child(car)
	
	var front_wheel := VehicleWheel3D.new()
	front_wheel.name = "WheelFrontLeft"
	front_wheel.use_as_steering = true
	front_wheel.use_as_traction = false
	front_wheel.wheel_friction_slip = 1.45
	car.add_child(front_wheel)
	
	var rear_wheel := VehicleWheel3D.new()
	rear_wheel.name = "WheelRearLeft"
	rear_wheel.use_as_steering = false
	rear_wheel.use_as_traction = true
	rear_wheel.wheel_friction_slip = 1.60
	car.add_child(rear_wheel)
	
	# Test Entering Damaged Zone
	repair_ctrl._on_body_entered(car)
	assert(is_equal_approx(car.road_traction_multiplier, 0.60), "Car traction multiplier must be 0.60")
	assert(is_equal_approx(rear_wheel.wheel_friction_slip, 1.60 * 0.60), "Rear wheel slip must be modified to 0.96")
	assert(is_equal_approx(front_wheel.wheel_friction_slip, 1.45 * 0.60), "Front wheel slip must be modified to 0.87")
	print("  ✓ Step 2: Car entered damaged zone: VehicleWheel3D traction modifiers applied (0.60x)")
	
	# Test Async Coroutine Repair Trigger
	print("  Triggering async repair coroutine (duration: %.2fs)..." % repair_ctrl.repair_duration)
	repair_ctrl.trigger_repair()
	assert(repair_ctrl.current_state == RoadRepairScript.RoadState.REPAIRING, "State must be REPAIRING during coroutine")
	assert(repair_ctrl.repair_particles.emitting == true, "Repair particles must be emitting during repair")
	print("  ✓ Step 3: Repairing coroutine in progress (particles emitting)")
	
	# Wait for coroutine to complete by ticking frames
	var elapsed := 0.0
	while repair_ctrl.current_state == RoadRepairScript.RoadState.REPAIRING and elapsed < 1.0:
		await process_frame
		elapsed += 0.016
	
	assert(repair_ctrl.current_state == RoadRepairScript.RoadState.FIXED, "State must be FIXED after coroutine")
	assert(repair_ctrl.repair_particles.emitting == false, "Repair particles must be stopped after repair")
	assert(repair_ctrl.damaged_visual.visible == false, "Damaged visual must be hidden after repair")
	assert(repair_ctrl.fixed_visual.visible == true, "Fixed visual must be visible after repair")
	assert(is_equal_approx(repair_ctrl.get_current_traction(), 1.00), "Traction must be 1.00 after repair")
	assert(is_equal_approx(car.road_traction_multiplier, 1.00), "Car traction multiplier must be restored to 1.00")
	assert(is_equal_approx(rear_wheel.wheel_friction_slip, 1.60), "Rear wheel slip restored to 1.60")
	assert(is_equal_approx(front_wheel.wheel_friction_slip, 1.45), "Front wheel slip restored to 1.45")
	print("  ✓ Step 4: Repair coroutine finished: FIXED state, visuals updated, 1.00x traction restored")
	
	# Test Exiting Zone
	repair_ctrl._on_body_exited(car)
	assert(is_equal_approx(car.road_traction_multiplier, 1.00), "Exited zone keeps baseline traction")
	print("  ✓ Step 5: Car exited zone safely")
	
	print("\n=======================================================")
	print(" ROAD REPAIR CONTROLLER FULLY VERIFIED AND PASSING 100% ")
	print("=======================================================")
	quit(0)
