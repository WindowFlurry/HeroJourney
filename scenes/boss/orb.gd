extends Node2D

const BURST := preload("res://graphics/boss/orb_burst.png")
const FOG_ZONE := preload("res://graphics/boss/fog_zone.png")

var direction := Vector2.RIGHT
var speed := 50.0
var damage := 22
var life := 5.0
var exploded := false

var player


func _ready() -> void:
	add_to_group("BossEffects")
	player = get_tree().get_first_node_in_group("Player")
	rotation = direction.angle()


func _process(delta: float) -> void:
	if exploded:
		return
	global_position += direction * speed * delta
	life -= delta
	if player != null:
		var center: Vector2 = player.global_position + Vector2(0, -12)
		if global_position.distance_to(center) <= 18.0:
			_explode()
			return
	if life <= 0.0:
		_explode()
		return
	rotation += delta * 2.0


func _explode() -> void:
	if exploded:
		return
	exploded = true
	if player != null:
		var center: Vector2 = player.global_position + Vector2(0, -12)
		if global_position.distance_to(center) <= 42.0:
			player.call("take_damage", damage, true)
	var parent := get_parent()
	if parent == null:
		queue_free()
		return

	var burst := Sprite2D.new()
	burst.texture = BURST
	parent.add_child(burst)
	burst.global_position = global_position
	burst.z_index = 3
	var tb := burst.create_tween()
	tb.set_parallel(true)
	tb.tween_property(burst, "scale", Vector2(1.7, 1.7), 0.3)
	tb.tween_property(burst, "modulate:a", 0.0, 0.3)
	tb.chain().tween_callback(burst.queue_free)

	var fog := Sprite2D.new()
	fog.texture = FOG_ZONE
	parent.add_child(fog)
	fog.global_position = global_position
	fog.z_index = 1
	var tf := fog.create_tween()
	tf.tween_interval(2.2)
	tf.tween_property(fog, "modulate:a", 0.0, 1.0)
	tf.tween_callback(fog.queue_free)

	queue_free()
