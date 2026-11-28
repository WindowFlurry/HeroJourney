extends "res://scenes/prologue/prologue_scene_base.gd"

const DOOR: Texture2D = preload("res://graphics/camp/gate_closed.png")
const HILLS: Texture2D = preload("res://graphics/tilesets/hills_wood.png")
const HIGHLAND_TILESET: TileSet = preload("res://scenes/level/hills_tileset.tres")
const DUMMY_SCRIPT: Script = preload("res://scenes/prologue/training_dummy.gd")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")
const CONTRACT_COLORS := {
	"warrior": Color(1.0, 0.62, 0.3),
	"ranger": Color(0.56, 0.88, 0.44),
	"mage": Color(0.55, 0.72, 1.0),
}
const SKILL_GUIDE := {
	"warrior": {
		"skill": "向前冲锋，对沿途敌人造成伤害。",
		"weapon": "向前方大范围横扫，击退敌人。",
	},
	"ranger": {
		"skill": "向鼠标方向翻滚，没有伤害，可用来拉开距离。",
		"weapon": "一次射出三支箭，覆盖前方扇形区域。",
	},
	"mage": {
		"skill": "向鼠标方向瞬移，没有伤害，可用来躲避攻击。",
		"weapon": "短暂蓄力后，向鼠标方向发射火球。",
	},
}

const GARETH_HOUSE_SCENE := "res://scenes/prologue/gareth_house.tscn"
const BLACKSMITH_SCENE := "res://scenes/prologue/blacksmith.tscn"
const EAST_GATE_SCENE := "res://scenes/prologue/east_gate.tscn"

var entries := {}
var entry_prompts := {}
var notice_position := Vector2(245, 220)
var intro_lines: Array[Dictionary] = [
	{"speaker": "旁白", "text": "灰杉村，丰收祭的前夜。你在这里长大，如今到了选定职业的年纪。"},
	{"speaker": "旁白", "text": "按照村子的习俗，祭典前你必须前往山谷，触摸职业石碑，决定今后的道路。"},
	{"speaker": "旁白", "text": "加雷斯爵士让你先去见他。他说，有件事必须在你选定职业前告诉你。"},
]
var intro_index := 0
var intro_active := false
var stone_positions := {
	"warrior": Vector2(270, -185),
	"ranger": Vector2(350, -185),
	"mage": Vector2(430, -185),
}
var training_center := Vector2(350, -130)
var stone_sprites := {}
var attack_hits := 0
var contract_playing := false
var skill_guide_lines: Array[Dictionary] = []
var skill_guide_index := 0
var skill_guide_active := false
var test_menu_layer: CanvasLayer
var test_menu_overlay: Control
var test_menu_first_button: Button
var test_target_button: Button
var test_menu_open := false
var test_target_second := false


func on_scene_ready() -> void:
	build_village()
	resolve_spawn(Vector2(305, 255), {
		"gareth_house": Vector2(560, 240),
		"blacksmith": Vector2(165, 390),
		"east_gate": Vector2(660, 330),
		"town": Vector2(620, 330),
	})
	player.set_spawn_position(Vector2(305, 255))
	hud.profession_selected.connect(_on_profession_selected)
	hud.dialog_finished.connect(_on_dialog_finished)
	player.training_action.connect(_on_training_action)
	_build_test_menu()
	refresh_objective()
	if not loaded_from_save:
		_play_intro()


func _draw() -> void:
	draw_rect(Rect2(-100, -360, 960, 900), Color(0.1, 0.22, 0.19))


func build_village() -> void:
	add_tile_area(Rect2(0, -280, 760, 750), GRASS, [Vector2i(1, 1)], 2, 61)
	add_tile_area(Rect2(80, 220, 620, 70), SOIL, [Vector2i(1, 1)], 2, 62)
	for rect in [
		Rect2(545, 170, 40, 80),
		Rect2(318, -68, 64, 358),
		Rect2(120, 280, 40, 115),
		Rect2(625, 280, 40, 90),
	]:
		add_tile_area(rect, SOIL, [Vector2i(1, 1)], 2, 63)

	add_blocker(Rect2(0, -280, 760, 18))
	add_blocker(Rect2(0, 455, 760, 15))
	add_blocker(Rect2(0, -262, 18, 717))
	add_blocker(Rect2(742, -262, 18, 717))

	_add_building(Rect2(515, 137, 142, 82), "加雷斯的屋子", Vector2(586, 224), "gareth_house")
	_add_building(Rect2(65, 315, 126, 78), "铁匠铺", Vector2(128, 398), "blacksmith")

	# 村中告示：正面补一段简洁的背景说明
	_add_notice_board(notice_position)
	add_world_label("村中告示", notice_position + Vector2(-40, -48), 7, Color(0.9, 0.82, 0.64))
	entries["notice"] = notice_position + Vector2(0, 10)
	entry_prompts["notice"] = "查看村中告示"
	add_world_label("灰杉村", Vector2(250, 305), 11, Color(1.0, 0.84, 0.5))

	# 村庄北侧的小高地：草地平台，从主路沿石阶正常走上去
	_add_highland(Vector2(190, -260), 10, 6, 4, 2)
	add_world_label("山谷", Vector2(330, -244), 12, Color(1.0, 0.84, 0.5))

	for profession_id in stone_positions:
		var pos: Vector2 = stone_positions[profession_id]
		stone_sprites[profession_id] = add_sprite(HILLS, pos, 0.8)
	add_world_label("战士石碑", stone_positions["warrior"] + Vector2(-42, -35), 6, Color(0.96, 0.62, 0.3))
	add_world_label("游侠石碑", stone_positions["ranger"] + Vector2(-42, -35), 6, Color(0.55, 0.9, 0.45))
	add_world_label("法师石碑", stone_positions["mage"] + Vector2(-42, -35), 6, Color(0.55, 0.72, 1.0))

	for pos in [Vector2(315, -130), Vector2(385, -130)]:
		var dummy := Node2D.new()
		dummy.set_script(DUMMY_SCRIPT)
		dummy.position = pos
		objects.add_child(dummy)
	add_world_label("训练木桩", training_center + Vector2(-38, 26), 6, Color(0.9, 0.82, 0.64))

	add_sprite(DOOR, Vector2(665, 330), 1.6)
	add_world_label("东门", Vector2(637, 292), 9, Color(1.0, 0.78, 0.44))
	entries["east_gate"] = Vector2(665, 335)
	entry_prompts["east_gate"] = "前往东门"

	for pos in [
		Vector2(45, 75), Vector2(105, 50), Vector2(160, 50),
		Vector2(580, 52), Vector2(675, 72), Vector2(720, 140), Vector2(728, 220),
		Vector2(42, 220), Vector2(46, 300), Vector2(42, 410),
		Vector2(235, 445), Vector2(315, 455), Vector2(420, 450), Vector2(510, 440),
		Vector2(700, 430),
		# 山谷两侧
		Vector2(160, 120), Vector2(160, 190), Vector2(540, 80),
		# 上山路两侧
		Vector2(285, 60), Vector2(285, 165), Vector2(415, 20), Vector2(415, 145),
	]:
		add_tree(pos, 1.2, int(pos.x) % 2 == 0)


func _add_highland(origin: Vector2, width: int, height: int, stair_col: int, stair_width: int) -> void:
	var layer := TileMapLayer.new()
	layer.tile_set = HIGHLAND_TILESET
	layer.position = origin
	layer.scale = Vector2(2, 2)
	layer.z_index = 0
	for y in height:
		for x in width:
			var coords := Vector2i(1, 1)
			if y == 0:
				coords = Vector2i(0 if x == 0 else (2 if x == width - 1 else 1), 0)
			elif y == height - 1:
				coords = Vector2i(0 if x == 0 else (2 if x == width - 1 else 1), 2)
			elif x == 0:
				coords = Vector2i(0, 1)
			elif x == width - 1:
				coords = Vector2i(2, 1)
			layer.set_cell(Vector2i(x, y), 0, coords)
	# 石阶：替换底边的一小段，并向下延伸两级，形成上山台阶
	for i in stair_width:
		for row in 3:
			layer.set_cell(Vector2i(stair_col + i, height - 1 + row), 0, Vector2i(3, 2))
	objects.add_child(layer)


func _add_notice_board(pos: Vector2) -> void:
	var post := ColorRect.new()
	post.position = pos + Vector2(-3, 2)
	post.size = Vector2(6, 22)
	post.color = Color(0.33, 0.22, 0.12)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.z_index = 1
	objects.add_child(post)
	var frame := ColorRect.new()
	frame.position = pos + Vector2(-24, -28)
	frame.size = Vector2(48, 32)
	frame.color = Color(0.24, 0.15, 0.09)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = 1
	objects.add_child(frame)
	var board := ColorRect.new()
	board.position = pos + Vector2(-22, -26)
	board.size = Vector2(44, 28)
	board.color = Color(0.47, 0.32, 0.19)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.z_index = 2
	objects.add_child(board)
	var paper := ColorRect.new()
	paper.position = pos + Vector2(-16, -22)
	paper.size = Vector2(32, 20)
	paper.color = Color(0.83, 0.75, 0.58)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.z_index = 3
	objects.add_child(paper)
	for i in 3:
		var ink := ColorRect.new()
		ink.position = pos + Vector2(-11, -18 + i * 5)
		ink.size = Vector2(22 - i * 3, 1)
		ink.color = Color(0.35, 0.28, 0.18)
		ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ink.z_index = 4
		objects.add_child(ink)


func _add_building(rect: Rect2, title: String, interaction_pos: Vector2, entry_id: String) -> void:
	add_tile_area(rect, WOOD_FLOOR, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	], 2, int(rect.position.x + rect.position.y))
	add_blocker(rect)
	add_sprite(DOOR, interaction_pos + Vector2(0, -6), 1.4)
	add_world_label(title, rect.position + Vector2(0, -24), 8, Color(1.0, 0.84, 0.5))
	entries[entry_id] = interaction_pos
	entry_prompts[entry_id] = "进入" + title


func refresh_objective() -> void:
	if Global.guild_registered:
		set_objective("返回白鹿镇")
		set_tutorial("从村庄东侧的灰鹿古道返回白鹿镇")
		return
	if not Global.gareth_talked:
		set_objective("前往加雷斯的屋子")
		set_tutorial("沿村庄道路向东，进入加雷斯的屋子")
	elif Global.profession.is_empty():
		set_objective("前往山谷选择职业")
		set_tutorial("沿村庄主路中段的山路一直向北，登上石阶进入山谷")
	elif not Global.tutorial_attack_done:
		set_objective("攻击训练木桩（%d/2）" % mini(attack_hits, 2))
		set_tutorial("[%s] 攻击训练木桩　[%s] %s（职业技能）　[%s] %s（武器特技）" % [
			Settings.binding_text("action"),
			Settings.binding_text("dash"),
			str(player.call("get_skill_name")),
			Settings.binding_text("weapon_skill"),
			str(player.call("get_weapon_skill_name")),
		])
	elif not Global.tutorial_skill_done:
		set_objective("使用一次职业技能")
		set_tutorial("[%s] %s（职业技能）" % [
			Settings.binding_text("dash"),
			str(player.call("get_skill_name")),
		])
	elif not Global.tutorial_weapon_skill_done:
		set_objective("使用一次武器特技")
		set_tutorial("[%s] %s（武器特技）" % [
			Settings.binding_text("weapon_skill"),
			str(player.call("get_weapon_skill_name")),
		])
	elif not Global.prologue_chest_opened:
		set_objective("前往铁匠铺领取补给")
		set_tutorial("铁匠铺位于村庄西南侧")
	else:
		set_objective("前往东门")
		set_tutorial("沿村庄道路向东前往东门")


func on_scene_process(_delta: float) -> void:
	if contract_playing:
		hud.call("clear_interaction")
		return
	var nearest_stone := ""
	var nearest_distance := INF
	for profession_id in stone_positions:
		var distance: float = player.global_position.distance_to(stone_positions[profession_id])
		if distance <= 40.0 and distance < nearest_distance:
			nearest_stone = profession_id
			nearest_distance = distance
	if not nearest_stone.is_empty():
		hud.call("show_interaction", "[%s] 触摸%s石碑" % [
			Settings.binding_text("interact"),
			_profession_label(nearest_stone),
		])
		if Input.is_action_just_pressed("interact"):
			if not Global.gareth_talked:
				hud.call("show_notice", "先前往加雷斯的屋子了解情况")
			elif not Global.profession.is_empty() and Global.profession_reselects >= 1:
				hud.call("show_notice", "离开山谷前只能重新选择一次职业")
			else:
				hud.call("open_profession_select", nearest_stone, not Global.profession.is_empty())
		return

	var nearest := ""
	var nearest_distance_entry := INF
	for entry_id in entries:
		var distance: float = player.global_position.distance_to(entries[entry_id])
		if distance <= 40.0 and distance < nearest_distance_entry:
			nearest = entry_id
			nearest_distance_entry = distance
	if nearest.is_empty():
		hud.call("clear_interaction")
		return
	hud.call("show_interaction", "[%s] %s" % [
		Settings.binding_text("interact"),
		entry_prompts[nearest],
	])
	if not Input.is_action_just_pressed("interact"):
		return
	match nearest:
		"notice":
			hud.call(
				"show_dialog",
				"村中告示",
				"丰收祭前，年轻人须在山谷石碑前选定职业。山中近来不宁，入夜后不要离村。——加雷斯"
			)
		"gareth_house":
			travel_to(GARETH_HOUSE_SCENE)
		"blacksmith":
			travel_to(BLACKSMITH_SCENE)
		"east_gate":
			travel_to(EAST_GATE_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_jump"):
		if test_menu_open:
			_close_test_menu()
		else:
			_open_test_menu()
		get_viewport().set_input_as_handled()
		return
	if test_menu_open and event.is_action_pressed("pause"):
		_close_test_menu()
		get_viewport().set_input_as_handled()


func _build_test_menu() -> void:
	test_menu_layer = CanvasLayer.new()
	test_menu_layer.layer = 50
	add_child(test_menu_layer)
	test_menu_overlay = Control.new()
	test_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	test_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	test_menu_overlay.visible = false
	test_menu_layer.add_child(test_menu_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	test_menu_overlay.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(110, 38)
	panel.size = Vector2(260, 200)
	panel.add_theme_stylebox_override(
		"panel",
		hud.call("_style", Color(0.055, 0.043, 0.032, 0.98), Color(0.72, 0.55, 0.28), 3)
	)
	test_menu_overlay.add_child(panel)
	var title := hud.call("_label", "测试跳转", 11, Color(1.0, 0.84, 0.5)) as Label
	title.position = Vector2(0, 8)
	title.size = Vector2(260, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var sub := hud.call("_label", "选择职业后自动完成序章，进入测试关卡", 6, Color(0.78, 0.72, 0.62)) as Label
	sub.position = Vector2(10, 29)
	sub.size = Vector2(240, 12)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(sub)
	var profession_ids := ["warrior", "ranger", "mage"]
	var profession_names := ["战士", "游侠", "法师"]
	for i in profession_ids.size():
		var b := hud.call("_button", profession_names[i], 8) as Button
		b.position = Vector2(34, 48 + i * 28)
		b.size = Vector2(192, 22)
		b.custom_minimum_size = Vector2(192, 22)
		b.pressed.connect(_debug_jump.bind(profession_ids[i]))
		panel.add_child(b)
		if i == 0:
			test_menu_first_button = b
	test_target_button = hud.call("_button", "测试目标：第一关", 7) as Button
	test_target_button.position = Vector2(34, 132)
	test_target_button.size = Vector2(192, 20)
	test_target_button.custom_minimum_size = Vector2(192, 20)
	test_target_button.pressed.connect(_toggle_test_target)
	panel.add_child(test_target_button)
	var close := hud.call("_button", "关闭（Tab / Esc）", 7) as Button
	close.position = Vector2(80, 156)
	close.size = Vector2(100, 20)
	close.custom_minimum_size = Vector2(100, 20)
	close.pressed.connect(_close_test_menu)
	panel.add_child(close)
	var hint := hud.call("_label", "测试用：直接写入完整序章状态", 5, Color(0.6, 0.56, 0.48)) as Label
	hint.position = Vector2(0, 180)
	hint.size = Vector2(260, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)


func _open_test_menu() -> void:
	if test_menu_open:
		return
	test_menu_open = true
	hud.set("test_menu_open", true)
	test_menu_overlay.visible = true
	player.call("set_input_locked", true)
	if test_menu_first_button != null:
		test_menu_first_button.grab_focus()


func _close_test_menu() -> void:
	if not test_menu_open:
		return
	test_menu_open = false
	hud.set("test_menu_open", false)
	test_menu_overlay.visible = false
	if contract_playing:
		return
	if not bool(hud.get("dialog_active")) and not bool(hud.get("select_active")) and not bool(hud.get("character_open")) and not bool(hud.get("death_open")):
		player.call("set_input_locked", false)


func _toggle_test_target() -> void:
	test_target_second = not test_target_second
	if test_target_button != null:
		test_target_button.text = "测试目标：第二关" if test_target_second else "测试目标：第一关"


func _debug_jump(profession_id: String) -> void:
	if test_target_second:
		_debug_jump_to_first_level(profession_id, false)
		Global.first_stele_lit = true
		Global.boss_defeated = true
		Global.roland_defeated = false
		Global.second_stele_lit = false
		Global.monastery_chest_opened = false
		Global.monastery_right_seal = false
		Global.monastery_chapel_open = false
		Global.monastery_candles_lit = 0
		SaveGame.pending_player_data["position"] = [888.0, 1270.0]
		Global.prologue_scene_spawn = ""
		Global.prologue_travel = false
		get_tree().change_scene_to_file("res://scenes/monastery/monastery.tscn")
	else:
		_debug_jump_to_first_level(profession_id)


func _debug_jump_to_first_level(profession_id: String, change_scene: bool = true) -> void:
	_close_test_menu()
	Global.reset_state()
	Global.prologue_started = true
	Global.prologue_completed = true
	Global.gareth_talked = true
	Global.profession = profession_id
	Global.tutorial_attack_done = true
	Global.tutorial_skill_done = true
	Global.tutorial_weapon_skill_done = true
	Global.prologue_chest_opened = true
	Global.village_attack_started = true
	Global.wave1_cleared = true
	Global.wave2_cleared = true
	Global.east_gate_cleared = true
	Global.guild_registered = true
	player.set("attack_upgrades", 0)
	player.set("defense_upgrades", 0)
	player.set("armor_tier", 1)
	player.set("base_armor_equipped", false)
	player.set("has_camp_key", false)
	player.set("camp_key_granted", false)
	player.set("selected_quick_slot", 0)
	player.call("setup_profession", profession_id)
	var weapon_item := str(player.call("get_profession_weapon_item"))
	Global.add_item(weapon_item, 1)
	Global.move_item_to_hotbar(0, {"kind": "inventory_item", "item_id": weapon_item})
	# 铁匠铺宝箱会再补一把职业武器
	Global.add_item(weapon_item, 1)
	if int(Global.inventory.get("recruit_armor", 0)) <= 0 and str(Global.equipment["chest"].get("id", "")).is_empty():
		Global.add_item("recruit_armor", 1)
		Global.move_item_to_equipment("chest", {"kind": "inventory_item", "item_id": "recruit_armor"})
	Global.add_item("herb", 5)
	if int(Global.inventory.get("silver_oath_sigil", 0)) <= 0:
		Global.add_item("silver_oath_sigil", 1)
	player.call("equip_base_armor")
	Global.ensure_hotbar_defaults()
	player.set_spawn_position(Vector2(88, -80))
	SaveGame.pending_player_data = player.call("get_save_data")
	SaveGame.pending_player_data["position"] = [88.0, -80.0]
	Global.prologue_scene_spawn = ""
	Global.prologue_travel = false
	if change_scene:
		get_tree().change_scene_to_file("res://scenes/level/game.tscn")


func _play_intro() -> void:
	intro_active = true
	intro_index = 0
	_show_next_intro_line()


func _show_next_intro_line() -> void:
	var line: Dictionary = intro_lines[intro_index]
	intro_index += 1
	hud.call("show_dialog", str(line["speaker"]), str(line["text"]))


func _on_dialog_finished() -> void:
	if skill_guide_active:
		if skill_guide_index >= skill_guide_lines.size():
			skill_guide_active = false
			return
		_show_next_skill_line()
		return
	if not intro_active:
		return
	if intro_index >= intro_lines.size():
		intro_active = false
		return
	_show_next_intro_line()


func _start_skill_guide(profession_id: String) -> void:
	var guide: Dictionary = SKILL_GUIDE.get(profession_id, {})
	if guide.is_empty():
		return
	var skill_name := str(player.call("get_skill_name"))
	var weapon_name := str(player.call("get_weapon_skill_name"))
	skill_guide_lines = [
		{
			"title": "%s · 职业技能" % _profession_label(profession_id),
			"text": "[%s] %s：%s" % [Settings.binding_text("dash"), skill_name, str(guide["skill"])],
		},
		{
			"title": "%s · 武器特技" % _profession_label(profession_id),
			"text": "[%s] %s：%s" % [Settings.binding_text("weapon_skill"), weapon_name, str(guide["weapon"])],
		},
	]
	skill_guide_index = 0
	skill_guide_active = true
	_show_next_skill_line()


func _show_next_skill_line() -> void:
	var line: Dictionary = skill_guide_lines[skill_guide_index]
	skill_guide_index += 1
	hud.call("show_dialog", str(line["title"]), str(line["text"]))


func _on_profession_selected(profession_id: String) -> void:
	var previous := str(player.get("profession"))
	if not previous.is_empty() and previous != profession_id:
		Global.profession_reselects += 1
	player.call("setup_profession", profession_id)
	Global.profession = profession_id
	var weapon_item := str(player.call("get_profession_weapon_item"))
	if int(Global.inventory.get(weapon_item, 0)) <= 0:
		Global.add_item(weapon_item, 1)
	if Global.hotbar[0].is_empty() or Global.hotbar[0] in ["warrior_weapon", "ranger_weapon", "mage_weapon"]:
		Global.move_item_to_hotbar(0, {"kind": "inventory_item", "item_id": weapon_item})
	player.set_spawn_position(training_center)
	SaveGame.save_game("灰杉村山谷")
	refresh_objective()
	_play_contract(profession_id)


func _play_contract(profession_id: String) -> void:
	var stone_pos: Vector2 = stone_positions.get(profession_id, player.global_position)
	var stone: Sprite2D = stone_sprites.get(profession_id)
	var accent: Color = CONTRACT_COLORS.get(profession_id, Color(1.0, 0.84, 0.5))
	var base_scale: Vector2 = stone.scale if stone != null else Vector2.ONE
	contract_playing = true
	player.call("set_input_locked", true)

	var glow := _add_glow(stone_pos, accent, 0.3, 5)
	var ring := _add_glow(stone_pos, accent, 0.2, 4)
	var player_glow := _add_glow(player.global_position, accent, 0.25, 6)
	var beam := Line2D.new()
	beam.points = PackedVector2Array([player.global_position, stone_pos])
	beam.width = 3.0
	beam.default_color = Color(accent.r, accent.g, accent.b, 0.0)
	beam.z_index = 6
	objects.add_child(beam)

	Sfx.play("charge", 1.15)
	var tween := create_tween()
	tween.tween_property(glow, "modulate:a", 0.95, 0.3)
	tween.parallel().tween_property(glow, "scale", Vector2(2.4, 2.4), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(beam, "default_color:a", 1.0, 0.25)
	tween.parallel().tween_property(player_glow, "modulate:a", 0.7, 0.25)
	tween.parallel().tween_property(player_glow, "scale", Vector2(1.4, 1.4), 0.55)
	tween.parallel().tween_property(ring, "modulate:a", 0.7, 0.15)
	tween.parallel().tween_property(ring, "scale", Vector2(3.4, 3.4), 0.6)
	if stone != null:
		tween.parallel().tween_property(stone, "modulate", accent.lightened(0.35), 0.3)
		tween.parallel().tween_property(stone, "scale", base_scale * 1.22, 0.3)
	tween.tween_callback(func() -> void:
		Sfx.play("craft", 1.05, 2.0)
		if stone != null:
			var pulse := create_tween()
			pulse.tween_property(stone, "scale", base_scale * 1.35, 0.1)
			pulse.tween_property(stone, "scale", base_scale, 0.25)
	)
	tween.tween_interval(0.25)
	tween.tween_property(beam, "default_color:a", 0.0, 0.25)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(player_glow, "modulate:a", 0.0, 0.25)
	if stone != null:
		tween.parallel().tween_property(stone, "modulate", Color.WHITE, 0.25)
		tween.parallel().tween_property(stone, "scale", base_scale, 0.25)
	tween.tween_callback(func() -> void:
		glow.queue_free()
		ring.queue_free()
		player_glow.queue_free()
		beam.queue_free()
		if is_instance_valid(player):
			player.call("set_input_locked", false)
		contract_playing = false
		_start_skill_guide(profession_id)
	)


func _add_glow(pos: Vector2, color: Color, start_scale: float, glow_z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = GLOW
	sprite.position = pos
	sprite.scale = Vector2(start_scale, start_scale)
	sprite.modulate = Color(color.r, color.g, color.b, 0.0)
	sprite.z_index = glow_z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	objects.add_child(sprite)
	return sprite


func _on_training_action(action_name: String) -> void:
	if player.global_position.distance_to(training_center) > 85.0:
		return
	match action_name:
		"attack":
			if not Global.tutorial_attack_done:
				attack_hits += 1
				if attack_hits >= 2:
					Global.tutorial_attack_done = true
		"skill":
			if Global.tutorial_attack_done:
				Global.tutorial_skill_done = true
		"weapon_skill":
			if Global.tutorial_skill_done:
				Global.tutorial_weapon_skill_done = true
	refresh_objective()


func _profession_label(profession_id: String) -> String:
	return {"warrior": "战士", "ranger": "游侠", "mage": "法师"}.get(profession_id, "")


func on_after_revive() -> void:
	player.global_position = Vector2(305, 255)
