extends Node2D

const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")

var facing := 0
var aligned := false
var beam: Line2D
var glow: Sprite2D


func _ready() -> void:
	beam = Line2D.new()
	beam.width = 3.0
	beam.z_index = 1
	add_child(beam)
	glow = Sprite2D.new()
	glow.texture = GLOW
	glow.position = Vector2(0, -28)
	glow.scale = Vector2(1.5, 1.5)
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.z_index = 2
	add_child(glow)
	_refresh()


func set_facing(value: int) -> void:
	facing = posmod(value, 4)
	_refresh()
	queue_redraw()


func set_aligned(value: bool) -> void:
	aligned = value
	_refresh()
	queue_redraw()


func _direction() -> Vector2:
	match facing:
		0:
			return Vector2.RIGHT
		1:
			return Vector2.DOWN
		2:
			return Vector2.LEFT
		_:
			return Vector2.UP


func _refresh() -> void:
	if beam != null:
		var origin := Vector2(0, -28)
		beam.points = PackedVector2Array([origin, origin + _direction() * 180.0])
		beam.width = 5.0 if aligned else 3.0
		beam.default_color = Color(1.0, 0.82, 0.38, 0.7) if aligned else Color(0.55, 0.8, 0.9, 0.28)
	if glow != null:
		glow.modulate = Color(1.0, 0.82, 0.38, 0.55) if aligned else Color(0.45, 0.75, 0.85, 0.2)


func _draw() -> void:
	var bronze := Color(0.95, 0.74, 0.3) if aligned else Color(0.56, 0.46, 0.28)
	draw_rect(Rect2(-6, -12, 12, 12), bronze.darkened(0.35))
	draw_circle(Vector2(0, -28), 12.0, bronze)
	draw_circle(Vector2(0, -28), 7.0, bronze.darkened(0.18))
	var dir := _direction()
	draw_line(Vector2(0, -28), Vector2(0, -28) + dir * 15.0, Color(0.95, 0.9, 0.7, 0.85), 2.0)
	if aligned:
		draw_arc(Vector2(0, -28), 17.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.5, 0.55), 1.5)
