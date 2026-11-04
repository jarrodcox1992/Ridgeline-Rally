extends Node3D
## Twin exhaust tips that spit flame when the engine backfires: a crackle of pops when
## lifting off at high revs, and a single burst on a full-throttle upshift.

const LIFT_OFF_RPM := 4500.0

## Called with each pop so the car can play the crack in its audio.
var on_pop: Callable

var _car: VehicleBody3D
var _flames: Array[GPUParticles3D] = []
var _flash: OmniLight3D
var _flash_time := 0.0
var _pops_left := 0
var _next_pop := 0.0
var _last_throttle := 0.0
var _last_gear := 1


## tips: exhaust outlet positions in the car's frame.
func setup(car: VehicleBody3D, tips: Array) -> void:
	_car = car
	var pipe_material := StandardMaterial3D.new()
	pipe_material.albedo_color = Color(0.08, 0.08, 0.09)
	pipe_material.metallic = 0.9
	pipe_material.roughness = 0.3
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.055
	pipe.bottom_radius = 0.055
	pipe.height = 0.16
	pipe.material = pipe_material
	for tip: Vector3 in tips:
		var mesh := MeshInstance3D.new()
		mesh.mesh = pipe
		mesh.position = tip + Vector3(0.0, 0.0, 0.06)
		mesh.rotation_degrees.x = 90.0
		add_child(mesh)
		var flame := _build_flame()
		flame.position = tip
		add_child(flame)
		_flames.append(flame)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1.0, 0.5, 0.15)
	_flash.omni_range = 3.5
	_flash.light_energy = 0.0
	_flash.light_specular = 0.3
	_flash.position = Vector3(0.0, 0.4, -2.3)
	add_child(_flash)


func _physics_process(delta: float) -> void:
	var throttle: float = _car.throttle
	var gear: int = _car.gear
	if _last_throttle > 0.6 and throttle < 0.1 and _car.rpm > LIFT_OFF_RPM and not _car.frozen:
		_pops_left = randi_range(2, 5)
		_next_pop = 0.0
	elif gear > _last_gear and throttle > 0.5:
		_pop()
	_last_throttle = throttle
	_last_gear = gear

	if _pops_left > 0:
		_next_pop -= delta
		if _next_pop <= 0.0:
			_pop()
			_pops_left -= 1
			_next_pop = randf_range(0.06, 0.22)

	_flash_time = maxf(_flash_time - delta, 0.0)
	_flash.light_energy = 3.0 * _flash_time / 0.12 * randf_range(0.6, 1.0)


func _pop() -> void:
	for flame in _flames:
		flame.restart()
	_flash_time = 0.12
	if on_pop.is_valid():
		on_pop.call()


func _build_flame() -> GPUParticles3D:
	var blob := GradientTexture2D.new()
	blob.fill = GradientTexture2D.FILL_RADIAL
	blob.fill_from = Vector2(0.5, 0.5)
	blob.fill_to = Vector2(1.0, 0.5)
	blob.gradient = Gradient.new()
	blob.gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	blob.gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))

	var draw_material := StandardMaterial3D.new()
	draw_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	draw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	draw_material.vertex_color_use_as_albedo = true
	draw_material.albedo_texture = blob
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.16)
	quad.material = draw_material

	# Yellow-orange at the tip, cooling to deep orange, then out. Kept below white so the
	# additive blend doesn't blow out into a blob.
	var heat := Gradient.new()
	heat.set_color(0, Color(1.0, 0.7, 0.3, 0.55))
	heat.add_point(0.3, Color(1.0, 0.45, 0.1, 0.5))
	heat.add_point(0.65, Color(0.9, 0.22, 0.03, 0.35))
	heat.set_color(heat.get_point_count() - 1, Color(0.5, 0.08, 0.0, 0.0))
	var heat_texture := GradientTexture1D.new()
	heat_texture.gradient = heat
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.6))
	grow.add_point(Vector2(1.0, 2.2))
	var grow_texture := CurveTexture.new()
	grow_texture.curve = grow

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.05, -1.0)
	process.spread = 9.0
	process.initial_velocity_min = 6.0
	process.initial_velocity_max = 13.0
	process.gravity = Vector3.ZERO
	process.damping_min = 6.0
	process.damping_max = 10.0
	process.color_ramp = heat_texture
	process.scale_curve = grow_texture

	var flame := GPUParticles3D.new()
	flame.amount = 40
	flame.lifetime = 0.12
	flame.one_shot = true
	flame.explosiveness = 0.35
	flame.emitting = false
	flame.local_coords = true
	flame.process_material = process
	flame.draw_pass_1 = quad
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return flame
