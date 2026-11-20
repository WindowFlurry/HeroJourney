extends Node2D

# 乌鸦：不可攻击。玩家靠近就飞走；玩家走远且看不见它之后，过几秒飞回原处。

@export var flee_radius := 76.0
@export var return_distance := 270.0
@export var return_delay := 3.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D
var home: Vector2
var state := "perched"
var away_timer := 0.0


func _ready() -> void:
	home = global_position
	player = get_tree().get_first_node_in_group("Player")
	sprite.flip_h = randf() < 0.5
	sprite.play("perch")


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		if player == null:
			return
	var distance := player.global_position.distance_to(home)

	match state:
		"perched":
			if distance < flee_radius:
				_take_off()
		"away":
			if distance > return_distance:
				away_timer += delta
				if away_timer >= return_delay:
					_come_back()


func _take_off() -> void:
	state = "away"
	away_timer = 0.0
	sprite.play("fly")
	Sfx.play("crow", randf_range(0.95, 1.12), -3.0)
	var dir := 1.0 if randf() < 0.5 else -1.0
	var target := home + Vector2(dir * randf_range(40.0, 90.0), -randf_range(150.0, 200.0))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target, randf_range(0.9, 1.2)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.45).set_delay(0.55)


func _come_back() -> void:
	state = "flying_in"
	global_position = home
	sprite.modulate.a = 0.0
	sprite.play("fly")
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.3)
	tween.tween_callback(_land)


func _land() -> void:
	sprite.stop()
	sprite.animation = "perch"
	sprite.frame = 0
	sprite.flip_h = randf() < 0.5
	state = "perched"
