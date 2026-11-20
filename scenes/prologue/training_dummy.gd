extends Node2D

var dead := false
var shake := 0.0
var base_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("Enemies")
	add_to_group("TrainingDummies")
	base_position = position


func _process(delta: float) -> void:
	if shake > 0.0:
		shake -= delta
		position.x = base_position.x + sin(shake * 85.0) * 2.8 * maxf(shake, 0.0)
	else:
		position = base_position
	queue_redraw()


func is_hit_by_attack(attacker_pos: Vector2, dir: Vector2, reach: float) -> bool:
	var center := global_position + Vector2(0, -16)
	var offset := center - attacker_pos
	if offset.length() > reach + 8.0:
		return false
	return offset.length() < 0.5 or offset.normalized().dot(dir) > -0.12


func take_damage(amount: int) -> void:
	take_damage_from(amount, Vector2.INF)


func take_damage_from(amount: int, _source_pos: Vector2) -> void:
	shake = 0.18
	Global.spawn_damage_number(global_position + Vector2(0, -28), amount, Color(1.0, 0.82, 0.42))


func _draw() -> void:
	draw_rect(Rect2(-4, -22, 8, 22), Color(0.38, 0.23, 0.1))
	draw_rect(Rect2(-11, -30, 22, 15), Color(0.55, 0.34, 0.15))
	draw_line(Vector2(-10, -8), Vector2(10, -8), Color(0.28, 0.16, 0.07), 4.0)
	draw_line(Vector2(-5, -29), Vector2(-9, -38), Color(0.28, 0.16, 0.07), 3.0)
	draw_line(Vector2(5, -29), Vector2(9, -38), Color(0.28, 0.16, 0.07), 3.0)
	draw_circle(Vector2(0, -20), 2.0, Color(0.95, 0.48, 0.2))

