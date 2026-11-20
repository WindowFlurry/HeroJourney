extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $InteractArea

var player
var hud
var near := false
var t := 0.0


func _ready() -> void:
	hud = get_tree().get_first_node_in_group("HUD")
	player = get_tree().get_first_node_in_group("Player")
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near = false
		if hud != null:
			hud.call("hide_hint")
		if player != null and player.has_method("campfire_heal_stop"):
			player.call("campfire_heal_stop")


func _process(delta: float) -> void:
	t += delta
	sprite.frame = int(t * 7.0) % 3
	if not near or get_tree().paused:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
	if player != null and player.has_method("campfire_heal"):
		player.call("campfire_heal", delta)
	if hud == null:
		hud = get_tree().get_first_node_in_group("HUD")
	if hud == null:
		return
	hud.call("show_hint", "按 B 熔炼合成")
	if Input.is_action_just_pressed("craft"):
		hud.call("open_crafting")
