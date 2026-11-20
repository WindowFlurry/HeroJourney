extends StaticBody2D

@onready var area: Area2D = $InteractArea

var player_near := false
var hud


func _ready() -> void:
	hud = get_tree().get_first_node_in_group("HUD")
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_near = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_near = false
		if hud != null:
			hud.call("hide_hint")


func _process(_delta: float) -> void:
	if not player_near or get_tree().paused:
		return
	if hud == null:
		hud = get_tree().get_first_node_in_group("HUD")
	if hud == null:
		return
	if not bool(hud.get("diary_open")):
		hud.call("show_hint", "按 F 查看手记")
		if Input.is_action_just_pressed("interact"):
			hud.call("open_diary")
