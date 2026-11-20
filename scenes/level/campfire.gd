extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var t := 0.0


func _process(delta: float) -> void:
	t += delta
	sprite.frame = int(t * 7.0) % 3
