extends Node3D
## Skid marks left on the ground, and smoke from the rear tires, whenever a tire slides.
## Works in world space, so it is not dragged along by the car.

const MAX_SEGMENTS := 3000
const MARK_WIDTH := 0.26
const SLIP_THRESHOLD := 0.35 # how far below full grip (1 - skidinfo) a tire must slip to leave marks
const MIN_SPEED := 3.0
const MIN_SEGMENT := 0.25
const SMOKE_THRESHOLD := 0.45

var _car: VehicleBody3D
var _wheels: Array[VehicleWheel3D] = []
var _last_points: Array[Vector3] = []
var _marking: Array[bool] = []
var _marks: MultiMesh
var _next_mark := 0
var _smoke: Dictionary = {} # VehicleWheel3D -> GPUParticles3D


func setup(car: VehicleBody3D, wheels: Array[VehicleWheel3D], smoking_wheels: Array[VehicleWheel3D]) -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_car = car
	_wheels = wheels
	for wheel in wheels:
		_last_points.append(Vector3.ZERO)
		_marking.append(false)
	_build_marks()
	for wheel in smoking_wheels:
		_smoke[wheel] = _build_smoke()
	_warm_up()


func _physics_process(_delta: float) -> void:
	var speed := _car.linear_velocity.length()
	for i in _wheels.size():
		var wheel := _wheels[i]
		var slip := 1.0 - wheel.get_skidinfo()
		var sliding := wheel.is_in_contact() and slip > SLIP_THRESHOLD and speed > MIN_SPEED
		var point := wheel.get_contact_point() + wheel.get_contact_normal() * 0.02 if sliding else Vector3.ZERO
		if sliding and _marking[i]:
			var gap := point.distance_to(_last_points[i])
			if gap > 3.0:
				_last_points[i] = point # the car was reset; don't draw a line across the map
			elif gap > MIN_SEGMENT:
				_add_mark(_last_points[i], point, wheel.get_contact_normal(), clampf((slip - SLIP_THRESHOLD) * 2.5, 0.45, 0.9))
				_last_points[i] = point
		elif sliding:
			_last_points[i] = point
		_marking[i] = sliding

		var smoke: GPUParticles3D = _smoke.get(wheel)
		if smoke:
			var amount := clampf((slip - SMOKE_THRESHOLD) * 2.0, 0.0, 1.0) if wheel.is_in_contact() and speed > 1.0 else 0.0
			if _car.burnout:
				amount = 1.0
			smoke.emitting = amount > 0.05
			smoke.amount_ratio = amount
			smoke.global_position = wheel.global_position - Vector3.UP * wheel.wheel_radius * 0.6


## Graphics drivers compile an effect's shaders the first time it is drawn, which stalls a
## frame or two. Draw an invisible mark and a wisp of smoke now, while the cars wait on the grid.
func _warm_up() -> void:
	var under := _car.global_position + Vector3.UP * 0.05
	_add_mark(under, under + _car.global_basis.z * 0.3, Vector3.UP, 0.0)
	for smoke: GPUParticles3D in _smoke.values():
		smoke.global_position = under
		smoke.amount_ratio = 0.05
		smoke.emitting = true
	await get_tree().create_timer(0.3).timeout
	for smoke: GPUParticles3D in _smoke.values():
		smoke.emitting = false


func _add_mark(from: Vector3, to: Vector3, normal: Vector3, alpha: float) -> void:
	var along := to - from
	# normal x along keeps the basis right-handed, so the plane still faces up.
	var across := normal.cross(along).normalized() * MARK_WIDTH
	var xform := Transform3D(Basis(across, normal, along), (from + to) * 0.5)
	_marks.set_instance_transform(_next_mark, xform)
	_marks.set_instance_color(_next_mark, Color(1.0, 1.0, 1.0, alpha))
	_next_mark = (_next_mark + 1) % MAX_SEGMENTS
	_marks.visible_instance_count = maxi(_marks.visible_instance_count, _next_mark if _next_mark > 0 else MAX_SEGMENTS)


func _build_marks() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.02, 0.02, 0.02)
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.6
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	plane.material = material
	_marks = MultiMesh.new()
	_marks.transform_format = MultiMesh.TRANSFORM_3D
	_marks.use_colors = true
	_marks.mesh = plane
	_marks.instance_count = MAX_SEGMENTS
	_marks.visible_instance_count = 0
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _marks
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Marks can be anywhere on the map.
	instance.custom_aabb = AABB(Vector3(-800.0, -50.0, -800.0), Vector3(1600.0, 300.0, 1600.0))
	add_child(instance)


## A soft puff with ragged, cloudy edges: a radial falloff broken up by noise.
func _puff_texture() -> ImageTexture:
	var size := 96
	var noise := FastNoiseLite.new()
	noise.frequency = 0.06
	noise.fractal_octaves = 4
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(Vector2(size, size) * 0.5) / (size * 0.5)
			var cloud := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var alpha := clampf((1.0 - d) * 1.6 * (0.35 + cloud), 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * alpha))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _build_smoke() -> GPUParticles3D:
	var draw_material := StandardMaterial3D.new()
	draw_material.albedo_texture = _puff_texture()
	draw_material.albedo_color = Color(0.72, 0.72, 0.74)
	draw_material.vertex_color_use_as_albedo = true
	draw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	draw_material.proximity_fade_enabled = true
	draw_material.proximity_fade_distance = 0.6
	var quad := QuadMesh.new()
	quad.size = Vector2(2.2, 2.2)
	quad.material = draw_material

	# Fade in quickly, then thin out as the puff spreads.
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.08, Color(1.0, 1.0, 1.0, 0.3))
	fade.set_color(fade.get_point_count() - 1, Color(1.0, 1.0, 1.0, 0.0))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(1.0, 3.2))
	var grow_texture := CurveTexture.new()
	grow_texture.curve = grow

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 70.0
	process.initial_velocity_min = 0.8
	process.initial_velocity_max = 2.6
	process.gravity = Vector3(0.0, 0.35, 0.0)
	process.damping_min = 0.8
	process.damping_max = 1.5
	process.scale_curve = grow_texture
	process.color_ramp = fade_texture
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.3
	# Random rotation and turbulence so the smoke curls instead of stacking up.
	process.angle_min = 0.0
	process.angle_max = 360.0
	process.angular_velocity_min = -25.0
	process.angular_velocity_max = 25.0
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.4
	process.turbulence_noise_scale = 4.0
	process.turbulence_influence_min = 0.05
	process.turbulence_influence_max = 0.15

	var particles := GPUParticles3D.new()
	particles.top_level = true
	particles.amount = 180
	particles.lifetime = 3.2
	particles.emitting = false
	particles.process_material = process
	particles.draw_pass_1 = quad
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-25.0, -3.0, -25.0), Vector3(50.0, 20.0, 50.0))
	add_child(particles)
	return particles
