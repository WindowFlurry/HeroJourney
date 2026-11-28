extends Node2D

const ENTRANCE := Vector2(62, 154)
const GUILD_RETURN := Vector2(360, 190)
const MIRA_POSITION := Vector2(300, 150)
const REST_POS := Vector2(200, 190)

# 白鹿镇是白鹿地区的交通枢纽，四条道路对应地图上的四个方向。
const WEST_ROUTE := Vector2(34, 154)
const NORTH_ROUTE := Vector2(150, 62)
const EAST_ROUTE := Vector2(492, 154)
const SOUTH_ROUTE := Vector2(300, 210)

const GRAYFIR_SCENE := "res://scenes/prologue/grayfir_village.tscn"
const MAIN_GAME_SCENE := "res://scenes/level/game.tscn"
const MONASTERY_SCENE := "res://scenes/monastery/monastery.tscn"
const COAST_SCENE := "res://scenes/coast/coast.tscn"
const PLAYER_SHEET: Texture2D = preload("res://graphics/characters/player_animations.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")

@onready var player = $Objects/Player
@onready var hud = $HUD

var transitioning := false
var route_labels := {}
var route_sub_labels := {}


func _ready() -> void:
	Global.prologue_completed = true
	player.prologue_mode = true
	player.speed = 78.0
	if not Global.profession.is_empty():
		player.call("setup_profession", Global.profession, false)
	var returned_to_guild := Global.prologue_scene_spawn == "guild"
	var arrived_from_road := Global.prologue_travel
	var route_unlock := str(Global.pending_route_unlock)
	if returned_to_guild:
		player.global_position = GUILD_RETURN
	elif arrived_from_road:
		player.global_position = ENTRANCE
	# 读档时保留玩家存档中的位置，不再强制送回西侧入口。
	Global.prologue_scene_spawn = ""
	Global.prologue_travel = false
	Global.town_return_pending = false
	Global.pending_route_unlock = ""
	player.set_spawn_position(player.global_position)
	hud.revive_requested.connect(_on_revive_requested)
	_build_blockers()
	_build_guild()
	_build_routes()
	_refresh_objective()
	_show_arrival_banner(returned_to_guild, route_unlock)
	if route_unlock == "monastery":
		_flash_route("east")
	elif route_unlock == "coast":
		_flash_route("south")
	SaveGame.save_game("白鹿镇公会" if returned_to_guild else "白鹿镇")
	queue_redraw()


func _on_revive_requested() -> void:
	player.call("revive_at_camp")
	player.call("set_input_locked", false)
	SaveGame.save_game("白鹿镇")


func _process(_delta: float) -> void:
	if transitioning or player == null or hud == null:
		return
	if (
		bool(hud.get("character_open"))
		or bool(hud.get("death_open"))
		or bool(hud.get("dialog_active"))
		or bool(hud.get("select_active"))
		or bool(hud.get("test_menu_open"))
	):
		hud.call("clear_interaction")
		return
	if player.global_position.distance_to(MIRA_POSITION) <= 42.0:
		hud.call("show_interaction", "[%s] 与米拉交谈" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_talk_mira()
		return
	if player.global_position.distance_to(REST_POS) <= 40.0:
		hud.call("show_interaction", "[%s] 在公会休息，恢复生命" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_rest_at_guild()
		return
	if _near(WEST_ROUTE):
		hud.call("show_interaction", "[%s] 前往灰杉村 · 110 灰鹿古道" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_go_grayfir()
		return
	if _near(NORTH_ROUTE):
		if not Global.guild_registered:
			hud.call("show_interaction", "120 白桦径尚未开放：先找米拉完成公会报到")
			if Input.is_action_just_pressed("interact"):
				hud.call("show_notice", "先与公会接待米拉交谈")
		else:
			hud.call("show_interaction", "[%s] 前往白桦林地 · 120 白桦径" % Settings.binding_text("interact"))
			if Input.is_action_just_pressed("interact"):
				_go_white_birch()
		return
	if _near(EAST_ROUTE):
		if not Global.first_stele_lit:
			hud.call("show_interaction", "130 失誓朝圣路尚未开放：先净化白桦林地")
			if Input.is_action_just_pressed("interact"):
				hud.call("show_notice", "需先点燃白桦林地的誓火石碑")
		else:
			hud.call("show_interaction", "[%s] 前往失誓修道院 · 130 失誓朝圣路" % Settings.binding_text("interact"))
			if Input.is_action_just_pressed("interact"):
				_go_monastery()
		return
	if _near(SOUTH_ROUTE):
		if not Global.second_stele_lit:
			hud.call("show_interaction", "140 赤烬驿道尚未开放：先净化失誓修道院")
			if Input.is_action_just_pressed("interact"):
				hud.call("show_notice", "需先点燃失誓修道院的誓火石碑")
		else:
			hud.call("show_interaction", "[%s] 前往赤烬海岸 · 140 赤烬驿道" % Settings.binding_text("interact"))
			if Input.is_action_just_pressed("interact"):
				_go_coast()
		return
	hud.call("clear_interaction")


func _near(pos: Vector2) -> bool:
	return player.global_position.distance_to(pos) <= 44.0


func _rest_at_guild() -> void:
	if int(player.health) >= int(player.max_health):
		hud.call("show_notice", "生命已经满了")
		return
	player.call("heal_by", int(player.max_health))
	SaveGame.save_game("白鹿镇")
	hud.call("show_notice", "在公会休息后，生命已恢复")


func _show_arrival_banner(returned_to_guild: bool, route_unlock: String = "") -> void:
	if not route_unlock.is_empty():
		var subtitle := "你回到了冒险者公会"
		match route_unlock:
			"monastery":
				subtitle = "新路线开放：130 失誓朝圣路 · 镇东"
			"coast":
				subtitle = "新路线开放：140 赤烬驿道 · 镇南"
			"third":
				subtitle = "三座誓火石碑都已点亮"
		hud.call("show_banner", "白鹿镇 · 冒险者公会", subtitle, 3.2)
		return
	if returned_to_guild:
		var subtitle := "你回到了冒险者公会"
		if Global.third_stele_lit:
			subtitle = "三座誓火石碑都已点亮"
		elif Global.second_stele_lit:
			subtitle = "失誓修道院的捷报传回了公会"
		elif Global.first_stele_lit:
			subtitle = "白桦林地的捷报传回了公会"
		hud.call("show_banner", "白鹿镇 · 冒险者公会", subtitle, 2.8)
		return
	if Global.guild_registered:
		hud.call("show_banner", "白鹿镇", "白鹿地区的冒险者枢纽", 2.6)
	else:
		hud.call("show_banner", "白鹿镇", "序章 · 灰杉村的黎明 已完成", 2.8)


func _talk_mira() -> void:
	if Global.guild_registered:
		if Global.third_stele_lit:
			hud.call("show_dialog", "米拉", "三座誓火石碑都已经点燃，白鹿地区暂时恢复了平静。先好好休息吧，公会会把后续的航路整理出来。")
		elif Global.second_stele_lit:
			hud.call("show_dialog", "米拉", "赤烬驿道已经开放，从镇南出发。赤烬海岸的灯塔是最后一座石碑的关键。")
		elif Global.first_stele_lit:
			hud.call("show_dialog", "米拉", "失誓朝圣路已经开放，从镇东出发。修道院里还留着失誓骑士罗兰，小心他的冲锋。")
		else:
			hud.call("show_dialog", "米拉", "白桦径在镇北。穿过白桦林地，找到第一座誓火石碑。失誓修道院和赤烬海岸的路还封着。")
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
	var text := "推荐信我收下了。白桦径在镇北，沿路穿过白桦林地。失誓修道院和赤烬海岸的路还封着，先点亮第一座石碑。这点草药带上。"
	if not has_letter:
		text = "推荐信没有？银誓徽记也能证明你的身份。白桦径在镇北，沿路穿过白桦林地。失誓修道院和赤烬海岸的路还封着，先点亮第一座石碑。"
	hud.call("show_dialog", "米拉", text)
	_refresh_objective()
	_refresh_route_visuals()
	queue_redraw()


func _has_sigil() -> bool:
	if int(Global.inventory.get("silver_oath_sigil", 0)) > 0:
		return true
	for i in Global.HOTBAR_SIZE:
		if Global.hotbar[i] == "silver_oath_sigil" and int(Global.hotbar_counts[i]) > 0:
			return true
	return false


func _refresh_objective() -> void:
	if Global.third_stele_lit:
		hud.call("set_objective", "三座誓火石碑已点亮")
		hud.call("show_tutorial", "白鹿地区暂时恢复了平静")
	elif Global.second_stele_lit:
		hud.call("set_objective", "前往赤烬海岸")
		hud.call("show_tutorial", "从镇南的 140 赤烬驿道出发")
	elif Global.first_stele_lit:
		hud.call("set_objective", "前往失誓修道院")
		hud.call("show_tutorial", "从镇东的 130 失誓朝圣路出发")
	elif Global.guild_registered:
		hud.call("set_objective", "前往白桦林地")
		hud.call("show_tutorial", "从镇北的 120 白桦径出发")
	else:
		hud.call("set_objective", "前往白鹿镇公会报到")
		hud.call("show_tutorial", "与公会接待米拉交谈")


func _go_grayfir() -> void:
	_travel(GRAYFIR_SCENE, "town", Vector2(620, 330))


func _go_white_birch() -> void:
	_travel(MAIN_GAME_SCENE, "", Vector2(88, -80))


func _go_monastery() -> void:
	_travel(MONASTERY_SCENE, "", Vector2(888, 1270))


func _go_coast() -> void:
	_travel(COAST_SCENE, "", Vector2(240, 1500))


func _travel(scene_path: String, spawn_id: String, spawn_position: Vector2) -> void:
	if transitioning:
		return
	transitioning = true
	player.call("set_input_locked", true)
	SaveGame.save_game("白鹿镇")
	var data: Dictionary = player.call("get_save_data")
	data["position"] = [spawn_position.x, spawn_position.y]
	SaveGame.pending_player_data = data
	Global.prologue_scene_spawn = spawn_id
	Global.prologue_travel = true
	get_tree().change_scene_to_file(scene_path)


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


func _build_routes() -> void:
	route_labels["west"] = _add_label("← 灰杉村", Vector2(-16, 178), 100, 6, _route_main_color("west"))
	route_sub_labels["west"] = _add_label("110 灰鹿古道", Vector2(-16, 190), 100, 4, _route_sub_color("west"))
	route_labels["north"] = _add_label("↑ 白桦林地", Vector2(100, 26), 100, 6, _route_main_color("north"))
	route_sub_labels["north"] = _add_label("120 白桦径", Vector2(100, 39), 100, 4, _route_sub_color("north"))
	route_labels["east"] = _add_label("失誓修道院 →", Vector2(400, 178), 110, 6, _route_main_color("east"))
	route_sub_labels["east"] = _add_label("130 失誓朝圣路", Vector2(400, 190), 110, 4, _route_sub_color("east"))
	route_labels["south"] = _add_label("↓ 赤烬海岸", Vector2(250, 226), 100, 6, _route_main_color("south"))
	route_sub_labels["south"] = _add_label("140 赤烬驿道", Vector2(250, 238), 100, 4, _route_sub_color("south"))
	_add_label("公会休息处", Vector2(152, 202), 96, 5, Color(0.92, 0.82, 0.62))


func _route_unlocked(route_id: String) -> bool:
	match route_id:
		"west":
			return true
		"north":
			return Global.guild_registered
		"east":
			return Global.first_stele_lit
		"south":
			return Global.second_stele_lit
	return false


func _route_main_color(route_id: String) -> Color:
	if not _route_unlocked(route_id):
		return Color(0.46, 0.44, 0.4)
	match route_id:
		"west":
			return Color(0.86, 0.9, 0.72)
		"north":
			return Color(0.76, 0.9, 0.72)
		"east":
			return Color(0.82, 0.78, 0.94)
		"south":
			return Color(1.0, 0.72, 0.54)
	return Color.WHITE


func _route_sub_color(route_id: String) -> Color:
	if not _route_unlocked(route_id):
		return Color(0.36, 0.35, 0.33)
	match route_id:
		"west":
			return Color(0.66, 0.68, 0.56)
		"north":
			return Color(0.62, 0.7, 0.58)
		"east":
			return Color(0.65, 0.62, 0.74)
		"south":
			return Color(0.76, 0.56, 0.44)
	return Color.WHITE


func _refresh_route_visuals() -> void:
	for route_id in route_labels:
		var label: Label = route_labels[route_id]
		label.add_theme_color_override("font_color", _route_main_color(route_id))
	for route_id in route_sub_labels:
		var label: Label = route_sub_labels[route_id]
		label.add_theme_color_override("font_color", _route_sub_color(route_id))


func _flash_route(route_id: String) -> void:
	var route_pos := Vector2.ZERO
	match route_id:
		"north":
			route_pos = NORTH_ROUTE
		"east":
			route_pos = EAST_ROUTE
		"south":
			route_pos = SOUTH_ROUTE
		_:
			route_pos = WEST_ROUTE
	var glow := Sprite2D.new()
	glow.texture = GLOW
	glow.position = route_pos + Vector2(0, -22)
	glow.scale = Vector2(2.2, 2.2)
	glow.modulate = Color(1.0, 0.8, 0.35, 0.0)
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.z_index = 3
	add_child(glow)
	var pulse := create_tween()
	for i in 3:
		pulse.tween_property(glow, "modulate:a", 0.62, 0.3)
		pulse.tween_property(glow, "modulate:a", 0.12, 0.3)
	pulse.tween_callback(glow.queue_free)
	if route_labels.has(route_id):
		var label: Label = route_labels[route_id]
		label.modulate = Color(1.5, 1.25, 0.8)
		var label_tween := create_tween()
		label_tween.tween_property(label, "modulate", Color.WHITE, 1.8)


func _add_label(text: String, pos: Vector2, width: float, size: int, color: Color) -> Label:
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
	return label


func _draw() -> void:
	var north_open := Global.guild_registered
	var east_open := Global.first_stele_lit
	var south_open := Global.second_stele_lit
	var north_road := Color(0.48, 0.37, 0.24) if north_open else Color(0.27, 0.26, 0.24)
	var north_wood := Color(0.34, 0.24, 0.14) if north_open else Color(0.19, 0.19, 0.18)
	var south_road := Color(0.48, 0.37, 0.24) if south_open else Color(0.27, 0.26, 0.24)
	var south_wood := Color(0.34, 0.24, 0.14) if south_open else Color(0.19, 0.19, 0.18)
	var east_wood := Color(0.34, 0.24, 0.14) if east_open else Color(0.19, 0.19, 0.18)
	var east_beam := Color(0.28, 0.19, 0.11) if east_open else Color(0.16, 0.16, 0.15)
	draw_rect(Rect2(-100, 20, 700, 230), Color(0.27, 0.39, 0.2))
	draw_rect(Rect2(-20, 145, 560, 28), Color(0.48, 0.37, 0.24))
	# 北侧白桦径
	draw_rect(Rect2(142, 62, 16, 83), north_road)
	draw_rect(Rect2(124, 54, 52, 8), north_wood)
	draw_rect(Rect2(128, 46, 6, 16), north_wood)
	draw_rect(Rect2(166, 46, 6, 16), north_wood)
	# 南侧赤烬驿道
	draw_rect(Rect2(292, 173, 16, 52), south_road)
	draw_rect(Rect2(274, 214, 52, 8), south_wood)
	draw_rect(Rect2(278, 206, 6, 18), south_wood)
	draw_rect(Rect2(316, 206, 6, 18), south_wood)
	# 西侧灰鹿古道
	draw_rect(Rect2(16, 112, 6, 60), Color(0.34, 0.24, 0.14))
	draw_rect(Rect2(46, 112, 6, 60), Color(0.34, 0.24, 0.14))
	draw_rect(Rect2(12, 106, 44, 8), Color(0.28, 0.19, 0.11))
	# 公会建筑
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
	# 公会休息长椅
	draw_rect(Rect2(180, 178, 44, 5), Color(0.5, 0.36, 0.2))
	draw_rect(Rect2(182, 184, 40, 5), Color(0.34, 0.24, 0.14))
	draw_rect(Rect2(184, 189, 4, 10), Color(0.24, 0.17, 0.1))
	draw_rect(Rect2(216, 189, 4, 10), Color(0.24, 0.17, 0.1))
	# 东门：通往失誓修道院
	draw_rect(Rect2(498, 110, 6, 84), east_wood)
	draw_rect(Rect2(532, 110, 6, 84), east_wood)
	draw_rect(Rect2(496, 104, 44, 8), east_beam)


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
