extends Control
## Top-down map of the track with a dot for the car.

var _points := PackedVector2Array()
var _car: Node3D
var others: Array = []
var _scale := 1.0
var _offset := Vector2.ZERO


func setup(track_points: PackedVector3Array, car: Node3D, map_size: Vector2) -> void:
	_car = car
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for p in track_points:
		min_p = Vector2(minf(min_p.x, p.x), minf(min_p.y, p.z))
		max_p = Vector2(maxf(max_p.x, p.x), maxf(max_p.y, p.z))
	var extent := max_p - min_p
	_scale = (minf(map_size.x, map_size.y) - 28.0) / maxf(extent.x, extent.y)
	_offset = (map_size - extent * _scale) * 0.5 - min_p * _scale
	_points.clear()
	for p in track_points:
		_points.append(_to_map(p))
	_points.append(_points[0])


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.35))
	if _points.size() < 2:
		return
	draw_polyline(_points, Color(0.0, 0.0, 0.0, 0.5), 7.0, true)
	draw_polyline(_points, Color(0.9, 0.9, 0.9), 3.0, true)
	draw_circle(_points[0], 4.0, Color.WHITE)
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
