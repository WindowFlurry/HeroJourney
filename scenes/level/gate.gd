extends Node2D

@onready var closed_sprite: Sprite2D = $Closed
@onready var open_sprite: Sprite2D = $Open
@onready var blocker: CollisionShape2D = $Blocker/CollisionShape2D
@onready var lever: Sprite2D = $Lever


func _ready() -> void:
	# 营地大门默认敞开，不需要钥匙
	closed_sprite.visible = false
	open_sprite.visible = true
	blocker.disabled = true
	lever.scale.x = -1.0
