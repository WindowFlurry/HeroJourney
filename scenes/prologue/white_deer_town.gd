extends Node2D

const ENTRANCE := Vector2(62, 154)
const EXIT_POSITION := Vector2(495, 154)
const MAIN_GAME_SCENE := "res://scenes/level/game.tscn"

@onready var player = $Objects/Player
@onready var hud = $HUD


func _ready() -> void:
	Global.prologue_completed = true
	player.prologue_mode = true
	player.speed = 78.0
	if not Global.profession.is_empty():
		player.call("setup_profession", Global.profession, false)
	player.global_position = ENTRANCE
	player.set_spawn_position(ENTRANCE)
	hud.revive_requested.connect(_on_revive_requested)
	hud.call("show_banner", "白鹿镇", "序章 · 灰杉村的黎明 已完成", 2.8)
	hud.call("set_objective", "序章完成 · 白鹿镇已解锁")
	hud.call("show_tutorial", "存档点：白鹿镇")
	_build_blockers()
	SaveGame.save_game("白鹿镇")
	queue_redraw()


func _on_revive_requested() -> void:
	player.call("revive_at_camp")
	player.call("set_input_locked", false)
	SaveGame.save_game("白鹿镇")


func _process(_delta: float) -> void:
	if player == null or hud == null:
		return
	if bool(hud.get("character_open")) or bool(hud.get("death_open")):
		hud.call("clear_interaction")
		return
	if player.global_position.distance_to(EXIT_POSITION) <= 46.0:
		hud.call("show_interaction", "[%s] 离开白鹿镇" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			var data: Dictionary = player.call("get_save_data")
			# 主岛出生点（初始营地），避免沿用白鹿镇坐标
			data["position"] = [88.0, -80.0]
			SaveGame.pending_player_data = data
			Global.prologue_scene_spawn = ""
			get_tree().change_scene_to_file(MAIN_GAME_SCENE)
	else:
		hud.call("clear_interaction")


func _draw() -> void:
	draw_rect(Rect2(-100, 20, 700, 230), Color(0.27, 0.39, 0.2))
	draw_rect(Rect2(-20, 145, 560, 28), Color(0.48, 0.37, 0.24))
	draw_rect(Rect2(308, 75, 138, 58), Color(0.52, 0.4, 0.27))
	draw_colored_polygon(
		PackedVector2Array([Vector2(298, 76), Vector2(377, 47), Vector2(456, 76)]),
		Color(0.24, 0.15, 0.09)
	)
	draw_rect(Rect2(358, 101, 38, 32), Color(0.28, 0.18, 0.1))
	draw_circle(Vector2(377, 92), 10.0, Color(0.82, 0.68, 0.3, 0.9))
	for x in [110, 238, 470]:
		draw_circle(Vector2(x, 143), 5.0, Color(1.0, 0.72, 0.3, 0.35))
		draw_line(Vector2(x, 147), Vector2(x, 157), Color(0.23, 0.16, 0.1), 2.0)
	# 东门：前往主岛
	draw_rect(Rect2(498, 110, 6, 84), Color(0.34, 0.24, 0.14))
	draw_rect(Rect2(532, 110, 6, 84), Color(0.34, 0.24, 0.14))
	draw_rect(Rect2(496, 104, 44, 8), Color(0.28, 0.19, 0.11))


func _build_blockers() -> void:
	_add_blocker(Rect2(-80, 35, 620, 16))
	_add_blocker(Rect2(-80, 225, 620, 16))
	_add_blocker(Rect2(-80, 35, 14, 206))
	_add_blocker(Rect2(510, 35, 14, 206))
	_add_blocker(Rect2(308, 74, 138, 59))


func _add_blocker(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)
