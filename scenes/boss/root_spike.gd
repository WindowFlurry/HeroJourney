extends Node2D

var damage := 12
var player


func _ready() -> void:
	add_to_group("BossEffects")
	player = get_tree().get_first_node_in_group("Player")
	modulate.a = 0.0
	position.y += 12.0
	var up := create_tween()
	up.set_parallel(true)
	up.tween_property(self, "position:y", position.y - 12.0, 0.14)
	up.tween_property(self, "modulate:a", 1.0, 0.1)
	var seq := create_tween()
	seq.tween_interval(0.18)
	seq.tween_callback(_hit_player)
	seq.tween_interval(0.38)
	seq.tween_callback(_retract)


func _hit_player() -> void:
	if player != null and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= 22.0:
			player.call("take_damage", damage, true)


func _retract() -> void:
	var down := create_tween()
	down.set_parallel(true)
	down.tween_property(self, "position:y", position.y + 14.0, 0.25)
	down.tween_property(self, "modulate:a", 0.0, 0.25)
	down.chain().tween_callback(queue_free)
