extends Node2D

@onready var glow: Sprite2D = $Glow
@onready var icon: Sprite2D = $Icon
@onready var hint: Label = $Hint

var item_id := ""
var item_name := ""
var player: Node2D


func _ready() -> void:
	add_to_group("Pickups")
	player = get_tree().get_first_node_in_group("Player") as Node2D
	if icon.texture == null:
		icon.visible = false


func setup(id: String, display_name: String, color: Color, icon_texture: Texture2D = null) -> void:
	item_id = id
	item_name = display_name
	glow.modulate = color
	if icon_texture != null:
		icon.texture = icon_texture
		icon.visible = true
	else:
		icon.visible = false


func collect() -> void:
	if item_id.is_empty():
		return
	if Global.is_item_full(item_id):
		return
	Global.add_item(item_id, 1)
	Sfx.play("pickup")
	queue_free()


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	glow.scale = Vector2.ONE * (0.65 + 0.07 * sin(t * 3.0))
	icon.position.y = -1.0 + sin(t * 2.5) * 1.5
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if player != null:
		var near := global_position.distance_to(player.global_position) <= 40.0
		hint.visible = near
		if near and not item_id.is_empty() and Global.is_item_full(item_id):
			hint.text = "%s已满" % item_name
		else:
			hint.text = "按F拾取"
