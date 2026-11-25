extends Node2D

var radius := 34.0
var damage := 14
var warn_time := 1.0
var active_time := 4.0
var state := "warn"
var timer := 1.0
var tick_timer := 0.0
var player: Node2D
var pulse := 0.0


func setup(new_radius: float, new_damage: int, new_warn: float = 1.0, new_active: float = 4.0) -> void:
	radius = new_radius
	damage = new_damage
	warn_time = new_warn
	active_time = new_active
	timer = warn_time
	state = "warn"


func _ready() -> void:
	z_index = 2
	player = get_tree().get_first_node_in_group("Player") as Node2D
	queue_redraw()


func _process(delta: float) -> void:
	pulse += delta
	timer -= delta
	if state == "warn":
		if timer <= 0.0:
			state = "active"
			timer = active_time
			tick_timer = 0.0
			queue_redraw()
	elif state == "active":
		tick_timer -= delta
		if tick_timer <= 0.0:
			tick_timer = 0.55
			if player != null and is_instance_valid(player) and not bool(player.get("dead")):
				if player.global_position.distance_to(global_position) <= radius:
					player.call("take_damage", damage)
		if timer <= 0.0:
			queue_free()
	queue_redraw()


func _draw() -> void:
	if state == "warn":
		var blink := 0.35 + 0.3 * absf(sin(pulse * 9.0))
		draw_circle(Vector2.ZERO, radius, Color(0.75, 0.16, 0.06, blink * 0.22))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(1.0, 0.48, 0.16, blink), 2.0)
	else:
		draw_circle(Vector2.ZERO, radius, Color(0.55, 0.13, 0.04, 0.62))
		draw_circle(Vector2.ZERO, radius * 0.72, Color(1.0, 0.36, 0.08, 0.65))
		draw_circle(Vector2.ZERO, radius * 0.38, Color(1.0, 0.78, 0.28, 0.72))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(1.0, 0.66, 0.2, 0.85), 1.5)
