extends Node2D

# 死亡后掉落的素材袋：回到死亡地点按 F 可以全部捡回

@onready var glow: Sprite2D = $Glow
@onready var icon: Sprite2D = $Icon
@onready var hint: Label = $Hint

var contents := {}
var player: Node2D


func _ready() -> void:
	add_to_group("Pickups")
	player = get_tree().get_first_node_in_group("Player") as Node2D


func setup(items: Dictionary) -> void:
	contents = items.duplicate()
	var total := 0
	for id in contents:
		total += int(contents[id])
	hint.text = "按F拾取遗失物（%d）" % total


func collect() -> void:
	if contents.is_empty():
		return
	for id in contents:
		Global.add_item(id, int(contents[id]), true)
	contents.clear()
	Sfx.play("pickup")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_property(self, "position:y", position.y - 8.0, 0.18)
	tween.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	glow.scale = Vector2.ONE * (0.7 + 0.08 * sin(t * 2.6))
	icon.position.y = -1.0 + sin(t * 2.2) * 1.2
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if player != null:
		hint.visible = global_position.distance_to(player.global_position) <= 40.0
