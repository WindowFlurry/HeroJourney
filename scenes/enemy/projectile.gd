extends Area2D

var direction := Vector2.RIGHT
var speed := 170.0
var damage := 6
var lifetime := 2.5


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2, new_speed: float, new_damage: int) -> void:
	direction = new_direction.normalized()
	speed = new_speed
	damage = new_damage
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if _in_safe_zone(global_position):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not _in_safe_zone(body.global_position):
		body.call("take_damage", damage)
	queue_free()


func _in_safe_zone(point: Vector2) -> bool:
	for zone in get_tree().get_nodes_in_group("SafeZones"):
		if zone.has_method("contains_point") and bool(zone.call("contains_point", point)):
			return true
	return false
