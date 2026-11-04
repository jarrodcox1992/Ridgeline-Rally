extends SceneTree

var main: Node3D
var t := 0.0
var cam: Camera3D
var step := 0
var out_dir := "/Users/j/.gemini/antigravity/brain/e4909efe-cd92-49e4-ba0c-0cb857cb4344/screenshots"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	cam = Camera3D.new()
	root.add_child(cam)
	cam.make_current()
	cam.fov = 48.0

func _process(delta: float) -> bool:
	t += delta
	var car: VehicleBody3D = main.car
	if car == null:
		return false
		
	# Let the car drive forward a bit to settle on suspension
	if t < 2.0:
		Input.action_press("accelerate")
		return false

	var xf := car.global_transform
	
	if step == 0 and t > 2.5:
		# Rear 3/4 chase shot
		cam.global_position = xf * Vector3(-2.8, 1.4, -4.8)
		cam.look_at(xf * Vector3(0.0, 0.6, -0.5), Vector3.UP)
		root.get_viewport().get_texture().get_image().save_png(out_dir + "/centenario_rear_chase.png")
		print("Saved centenario_rear_chase.png")
		step += 1
		
	elif step == 1 and t > 3.0:
		# Front 3/4 beauty shot
		cam.global_position = xf * Vector3(3.2, 1.2, 4.6)
		cam.look_at(xf * Vector3(0.0, 0.5, 0.5), Vector3.UP)
		root.get_viewport().get_texture().get_image().save_png(out_dir + "/centenario_front.png")
		print("Saved centenario_front.png")
		step += 1
		
	elif step == 2 and t > 3.5:
		# Cockpit / Interior shot
		cam.global_position = xf * Vector3(-0.41, 0.88, -0.32)
		cam.look_at(xf * Vector3(-0.41, 0.80, 2.0), Vector3.UP)
		root.get_viewport().get_texture().get_image().save_png(out_dir + "/centenario_cockpit.png")
		print("Saved centenario_cockpit.png")
		step += 1
		
	elif step == 3 and t > 4.0:
		# Side profile shot showing stance & wheels
		cam.global_position = xf * Vector3(4.8, 0.8, 0.0)
		cam.look_at(xf * Vector3(0.0, 0.45, 0.0), Vector3.UP)
		root.get_viewport().get_texture().get_image().save_png(out_dir + "/centenario_side.png")
		print("Saved centenario_side.png")
		step += 1
		print("ALL PHOTOS COMPLETE")
		quit()

	return false
