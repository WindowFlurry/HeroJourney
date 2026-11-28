extends Node2D

var bell_index := 0
var highlighted := false
var active := false


func set_state(is_highlighted: bool, is_active: bool) -> void:
	highlighted = is_highlighted
	active = is_active
	queue_redraw()


func _draw() -> void:
	var color := Color(0.92, 0.72, 0.28) if highlighted or active else Color(0.48, 0.4, 0.27)
	draw_circle(Vector2(0, -18), 12.0, color)
	draw_rect(Rect2(-14, -14, 28, 14), color)
	draw_rect(Rect2(-3, -32, 6, 12), color.darkened(0.25))
	draw_line(Vector2(-10, 2), Vector2(10, 2), color.darkened(0.35), 2.0)
	if highlighted:
		draw_arc(Vector2(0, -18), 17.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.5, 0.6), 1.5)
