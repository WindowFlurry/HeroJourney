extends StaticBody2D

const TEXTURES: Array[Texture2D] = [
	preload("res://graphics/trees/white_birch/white_birch_a_single.png"),
	preload("res://graphics/trees/white_birch/white_birch_b_twin.png"),
	preload("res://graphics/trees/white_birch/white_birch_c_young.png"),
	preload("res://graphics/trees/white_birch/white_birch_d_broad.png"),
	preload("res://graphics/trees/white_birch/white_birch_e_gold.png"),
]

@export var style_index := -1
@export var scale_override := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if style_index < 0:
		style_index = randi() % TEXTURES.size()
	style_index = clampi(style_index, 0, TEXTURES.size() - 1)
	var tex := TEXTURES[style_index]
	sprite.texture = tex
	sprite.position = Vector2(0, 3.0 - tex.get_height() * 0.5)
	var hash_value := int(absf(global_position.x * 17.0 + global_position.y * 31.0))
	sprite.flip_h = hash_value % 2 == 0
	var s := scale_override if scale_override > 0.0 else 1.0
	scale = Vector2(s, s)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
