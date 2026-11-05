extends Control
## Top-down map of the track with a dot for the car and color-coded alternate routes / overpasses.

var _points := PackedVector2Array()
var _alt_polylines: Array[PackedVector2Array] = []
var _car: Node3D
var others: Array = []
var _scale := 1.0
var _offset := Vector2.ZERO


func setup(track_points: PackedVector3Array, car: Node3D, map_size: Vector2, alt_curves: Array = []) -> void:
	_car = car
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for p in track_points:
		min_p = Vector2(minf(min_p.x, p.x), minf(min_p.y, p.z))
		max_p = Vector2(maxf(max_p.x, p.x), maxf(max_p.y, p.z))
	for ac: Curve3D in alt_curves:
		for ap in ac.get_baked_points():
			min_p = Vector2(minf(min_p.x, ap.x), minf(min_p.y, ap.z))
			max_p = Vector2(maxf(max_p.x, ap.x), maxf(max_p.y, ap.z))
	var extent := max_p - min_p
	_scale = (minf(map_size.x, map_size.y) - 28.0) / maxf(extent.x, extent.y)
	_offset = (map_size - extent * _scale) * 0.5 - min_p * _scale
	_points.clear()
	for p in track_points:
		_points.append(_to_map(p))
	_points.append(_points[0])
	_alt_polylines.clear()
	for ac: Curve3D in alt_curves:
		var poly := PackedVector2Array()
		for ap in ac.get_baked_points():
			poly.append(_to_map(ap))
		if poly.size() >= 2:
			_alt_polylines.append(poly)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Semi-transparent dark backdrop with neon HUD border
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.10, 0.55))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.85, 1.0, 0.45), false, 1.5)
	if _points.size() < 2:
		return
	var alt_colors: Array[Color] = [
		Color(0.0, 0.95, 1.0, 0.95),  # Overpass: Electric Cyan (y=16.2m)
		Color(1.0, 0.78, 0.12, 0.95), # Hyper-Straight Bypass: Amber Gold
		Color(1.0, 0.22, 0.85, 0.95), # Neon Tunnel Split-Route: Cyber Magenta
	]
	for i in _alt_polylines.size():
		var poly := _alt_polylines[i]
		draw_polyline(poly, Color(0.0, 0.0, 0.0, 0.75), 6.5, true)
		draw_polyline(poly, alt_colors[i % alt_colors.size()], 2.8, true)
	draw_polyline(_points, Color(0.0, 0.0, 0.0, 0.65), 7.5, true)
	draw_polyline(_points, Color(0.92, 0.94, 0.98), 3.2, true)
	draw_circle(_points[0], 4.5, Color.WHITE)

	# Route Legend Chips
	if not _alt_polylines.is_empty():
		var lx := 14.0
		var ly := size.y - 10.0
		for i in mini(_alt_polylines.size(), alt_colors.size()):
			draw_circle(Vector2(lx, ly), 4.0, Color.BLACK)
			draw_circle(Vector2(lx, ly), 3.0, alt_colors[i])
			lx += 18.0

	for other: Node3D in others:
		var other_pos := _to_map(other.global_position)
		draw_circle(other_pos, 5.0, Color.BLACK)
		draw_circle(other_pos, 3.5, Color(0.85, 0.9, 1.0))
	if _car:
		var pos := _to_map(_car.global_position)
		draw_circle(pos, 7.0, Color.BLACK)
		draw_circle(pos, 5.0, Color(1.0, 0.25, 0.15))


func _to_map(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z) * _scale + _offset
