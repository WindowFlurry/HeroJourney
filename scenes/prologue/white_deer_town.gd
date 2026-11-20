extends Node2D

const ENTRANCE := Vector2(62, 154)
const EXIT_POSITION := Vector2(495, 154)
const MIRA_POSITION := Vector2(300, 150)
const MAIN_GAME_SCENE := "res://scenes/level/game.tscn"
const PLAYER_SHEET: Texture2D = preload("res://graphics/characters/player_animations.png")

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
	_build_blockers()
	_build_guild()
	_refresh_objective()
	SaveGame.save_game("白鹿镇")
	queue_redraw()


func _on_revive_requested() -> void:
	player.call("revive_at_camp")
	player.call("set_input_locked", false)
	SaveGame.save_game("白鹿镇")


func _process(_delta: float) -> void:
	if player == null or hud == null:
		return
	if bool(hud.get("character_open")) or bool(hud.get("death_open")) or bool(hud.get("dialog_active")):
		hud.call("clear_interaction")
		return
	if player.global_position.distance_to(MIRA_POSITION) <= 42.0:
		hud.call("show_interaction", "[%s] 与米拉交谈" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_talk_mira()
		return
	if player.global_position.distance_to(EXIT_POSITION) <= 46.0:
		if not Global.guild_registered:
			hud.call("show_interaction", "[%s] 离开白鹿镇（先在公会报到）" % Settings.binding_text("interact"))
			if Input.is_action_just_pressed("interact"):
				hud.call("show_notice", "先去公会找米拉报到")
			return
		hud.call("show_interaction", "[%s] 离开白鹿镇" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			var data: Dictionary = player.call("get_save_data")
			# 主岛出生点（初始营地），避免沿用白鹿镇坐标
			data["position"] = [88.0, -80.0]
			SaveGame.pending_player_data = data
			Global.prologue_scene_spawn = ""
			get_tree().change_scene_to_file(MAIN_GAME_SCENE)
		return
	hud.call("clear_interaction")


func _talk_mira() -> void:
	if Global.guild_registered:
		hud.call("show_dialog", "米拉", "白桦林地已经开放。失誓修道院和赤烬海岸仍在封锁中，先从东侧出口前往白鹿边境吧。")
		return
	var has_letter := int(Global.inventory.get("white_deer_letter", 0)) > 0
	if not has_letter and not _has_sigil():
		hud.call("show_dialog", "米拉", "没有白鹿镇的推荐信或银誓徽记，我不能为你登记。先去东门取得推荐信。")
		return
	if has_letter:
		Global.remove_items({"white_deer_letter": 1})
	Global.guild_registered = true
	Global.add_item("herb", 2)
	SaveGame.save_game("白鹿镇")
	var text := "推荐信我收下了。白桦林地已经开放，失誓修道院和赤烬海岸还在封锁中。这点草药带上，路上小心。"
	if not has_letter:
		text = "推荐信没有？银誓徽记也能证明你的身份。白桦林地已经开放，失誓修道院和赤烬海岸还在封锁中。这点草药带上。"
	hud.call("show_dialog", "米拉", text)
	_refresh_objective()


func _has_sigil() -> bool:
	if int(Global.inventory.get("silver_oath_sigil", 0)) > 0:
		return true
	for i in Global.HOTBAR_SIZE:
		if Global.hotbar[i] == "silver_oath_sigil" and int(Global.hotbar_counts[i]) > 0:
			return true
	return false


func _refresh_objective() -> void:
	if Global.guild_registered:
		hud.call("set_objective", "前往白桦林地")
		hud.call("show_tutorial", "从东侧出口前往白鹿边境")
	else:
		hud.call("set_objective", "前往白鹿镇公会报到")
		hud.call("show_tutorial", "与公会接待米拉交谈")


func _build_guild() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = PLAYER_SHEET
	atlas.region = Rect2(0, 0, 48, 48)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position = MIRA_POSITION
	sprite.scale = Vector2(1.4, 1.4)
	sprite.modulate = Color(0.72, 0.8, 1.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 4
	add_child(sprite)
	_add_label("公会接待 · 米拉", MIRA_POSITION + Vector2(-60, -62), 120, 6, Color(0.75, 0.84, 1.0))
	_add_label("白鹿镇公会", Vector2(238, 88), 124, 7, Color(1.0, 0.84, 0.5))


func _add_label(text: String, pos: Vector2, width: float, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(width, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", hud.ui_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	add_child(label)


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
	# 公会柜台与告示板
	draw_rect(Rect2(258, 158, 84, 9), Color(0.4, 0.28, 0.16))
	draw_rect(Rect2(262, 164, 76, 3), Color(0.27, 0.19, 0.11))
	draw_rect(Rect2(238, 104, 124, 18), Color(0.31, 0.22, 0.13))
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
