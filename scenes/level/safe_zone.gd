extends Area2D

@export var checkpoint := false
@export var respawn_marker_path: NodePath
@export var location_name := "营地"


func _ready() -> void:
	add_to_group("SafeZones")
	if checkpoint:
		monitoring = true
		collision_mask = 2
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var marker := get_node_or_null(respawn_marker_path) as Node2D
		if marker != null:
			body.call("set_spawn_position", marker.global_position)
		SaveGame.save_game(location_name)


func contains_point(point: Vector2, margin: float = 0.0) -> bool:
	for child in get_children():
		var shape_node := child as CollisionShape2D
		if shape_node == null:
			continue
		var rect := shape_node.shape as RectangleShape2D
		if rect == null:
			continue
		var local_point := shape_node.to_local(point)
		if absf(local_point.x) <= rect.size.x * 0.5 + margin and absf(local_point.y) <= rect.size.y * 0.5 + margin:
			return true
	return false
