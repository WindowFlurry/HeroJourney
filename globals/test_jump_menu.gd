extends Node

# 测试用：三个地图内按 Tab 打开，保留/选择职业并写入满配状态后跳转。

const MAPS := {
	"village": {
		"label": "新手村",
		"scene": "res://scenes/prologue/grayfir_village.tscn",
		"spawn": Vector2(305, 255),
	},
	"first": {
		"label": "第一关 · 白桦林地",
		"scene": "res://scenes/level/game.tscn",
		"spawn": Vector2(88, -80),
	},
	"second": {
		"label": "第二关 · 失誓修道院",
		"scene": "res://scenes/monastery/monastery.tscn",
		"spawn": Vector2(888, 1270),
	},
	"third": {
		"label": "第三关 · 赤烬海岸",
		"scene": "res://scenes/coast/coast.tscn",
		"spawn": Vector2(240, 1500),
	},
}
const TEST_SCENES := [
	"res://scenes/prologue/grayfir_village.tscn",
	"res://scenes/level/game.tscn",
	"res://scenes/monastery/monastery.tscn",
	"res://scenes/coast/coast.tscn",
]
const PROFESSIONS := ["warrior", "ranger", "mage"]
const PROFESSION_NAMES := {"warrior": "战士", "ranger": "游侠", "mage": "法师"}
const PROFESSION_STATS := {
	"warrior": {"hp": 120, "weapon": "warrior_weapon", "current": "sword", "has_axe": false, "has_sword": true},
	"ranger": {"hp": 95, "weapon": "ranger_weapon", "current": "axe", "has_axe": true, "has_sword": false},
	"mage": {"hp": 85, "weapon": "mage_weapon", "current": "axe", "has_axe": true, "has_sword": false},
}

var layer: CanvasLayer
var overlay: Control
var panel: Panel
var font: SystemFont
var profession_buttons := {}
var map_buttons := {}
var selected_profession := "warrior"
var is_open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	overlay.visible = false


func _build_ui() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	panel = Panel.new()
	panel.position = Vector2(80, 18)
	panel.size = Vector2(320, 244)
	panel.add_theme_stylebox_override("panel", _style(Color(0.055, 0.043, 0.032, 0.98), Color(0.72, 0.55, 0.28), 3))
	overlay.add_child(panel)

	var title := _label("测试跳转", 13, Color(1.0, 0.84, 0.5))
	title.position = Vector2(0, 8)
	title.size = Vector2(320, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var sub := _label("保留当前职业；角色满配；前置剧情视为已通过", 5, Color(0.76, 0.7, 0.6))
	sub.position = Vector2(0, 28)
	sub.size = Vector2(320, 12)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(sub)
	var note := _label("目标地图本身会重置为可玩状态", 5, Color(0.6, 0.56, 0.48))
	note.position = Vector2(0, 40)
	note.size = Vector2(320, 10)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(note)

	var prof_label := _label("职业", 6, Color(0.82, 0.76, 0.64))
	prof_label.position = Vector2(14, 56)
	prof_label.size = Vector2(50, 12)
	panel.add_child(prof_label)
	for i in PROFESSIONS.size():
		var id: String = PROFESSIONS[i]
		var b := _button(PROFESSION_NAMES[id], 7)
		b.position = Vector2(14 + i * 98, 70)
		b.size = Vector2(92, 22)
		b.custom_minimum_size = Vector2(92, 22)
		b.pressed.connect(_select_profession.bind(id))
		panel.add_child(b)
		profession_buttons[id] = b

	var map_label := _label("跳转到", 6, Color(0.82, 0.76, 0.64))
	map_label.position = Vector2(14, 100)
	map_label.size = Vector2(60, 12)
	panel.add_child(map_label)
	var y := 112
	for id in ["village", "first", "second", "third"]:
		var b := _button(str(MAPS[id]["label"]), 7)
		b.position = Vector2(14, y)
		b.size = Vector2(292, 20)
		b.custom_minimum_size = Vector2(292, 20)
		b.pressed.connect(_jump_to.bind(id))
		panel.add_child(b)
		map_buttons[id] = b
		y += 22

	var close := _button("关闭", 7)
	close.position = Vector2(110, 204)
	close.size = Vector2(100, 20)
	close.custom_minimum_size = Vector2(100, 20)
	close.pressed.connect(close_menu)
	panel.add_child(close)
	var hint := _label("Tab / Esc 关闭", 5, Color(0.6, 0.56, 0.48))
	hint.position = Vector2(0, 226)
	hint.size = Vector2(320, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)


func _style(bg: Color, border: Color, radius: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	return s


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.5))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.86, 0.5))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.8, 0.4))
	b.add_theme_stylebox_override("normal", _style(Color(0.09, 0.07, 0.045, 0.98), Color(0.55, 0.42, 0.23)))
	b.add_theme_stylebox_override("hover", _style(Color(0.18, 0.12, 0.055, 1.0), Color(1.0, 0.72, 0.28)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.26, 0.16, 0.06, 1.0), Color(1.0, 0.8, 0.34)))
	var focus_style := _style(Color(0, 0, 0, 0), Color(1.0, 0.8, 0.4), 3)
	focus_style.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus_style)
	return b


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_jump"):
		if is_open:
			close_menu()
			get_viewport().set_input_as_handled()
			return
		if _is_test_map() and not get_tree().paused:
			_open()
			get_viewport().set_input_as_handled()
		return
	if is_open and event.is_action_pressed("pause"):
		close_menu()
		get_viewport().set_input_as_handled()


func _is_test_map() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return scene.scene_file_path in TEST_SCENES


func _current_profession() -> String:
	var value := str(Global.profession)
	if value.is_empty():
		var player := get_tree().get_first_node_in_group("Player")
		if player != null:
			value = str(player.get("profession"))
	if value in PROFESSIONS:
		return value
	return "warrior"


func _open() -> void:
	is_open = true
	selected_profession = _current_profession()
	_refresh_profession_buttons()
	overlay.visible = true
	get_tree().paused = true
	_set_hud_modal(true)
	if map_buttons.has("first"):
		map_buttons["first"].grab_focus()


func close_menu() -> void:
	if not is_open:
		return
	is_open = false
	overlay.visible = false
	get_tree().paused = false
	_set_hud_modal(false)


func _set_hud_modal(modal: bool) -> void:
	var hud := get_tree().get_first_node_in_group("HUD")
	if hud != null:
		hud.set("test_menu_open", modal)


func _select_profession(id: String) -> void:
	if not id in PROFESSIONS:
		return
	selected_profession = id
	_refresh_profession_buttons()


func _refresh_profession_buttons() -> void:
	for id in profession_buttons:
		var b: Button = profession_buttons[id]
		b.text = ("● " if id == selected_profession else "") + str(PROFESSION_NAMES[id])


func _jump_to(map_id: String) -> void:
	if not MAPS.has(map_id):
		return
	var map: Dictionary = MAPS[map_id]
	var profession := selected_profession
	close_menu()
	_prepare_state(profession, map_id, map["spawn"])
	get_tree().change_scene_to_file(str(map["scene"]))


func _prepare_state(profession: String, destination: String, spawn: Vector2) -> void:
	if not profession in PROFESSIONS:
		profession = "warrior"
	Global.reset_state()
	Global.prologue_started = true
	Global.prologue_completed = true
	Global.gareth_talked = true
	Global.profession = profession
	Global.profession_reselects = 0
	Global.tutorial_attack_done = true
	Global.tutorial_skill_done = true
	Global.tutorial_weapon_skill_done = true
	Global.prologue_chest_opened = true
	Global.village_attack_started = true
	Global.wave1_cleared = true
	Global.wave2_cleared = true
	Global.east_gate_cleared = true
	Global.guild_registered = true
	Global.roland_defeated = false
	Global.second_stele_lit = false
	Global.monastery_chest_opened = false
	Global.monastery_right_seal = false
	Global.monastery_chapel_open = false
	Global.monastery_candles_lit = 0
	Global.coast_lens_found = false
	Global.coast_falcon_defeated = false
	Global.coast_tide_guardian_defeated = false
	Global.coast_tide_key = false
	Global.coast_lighthouse_guards_defeated = false
	Global.coast_lighthouse_lit = false
	Global.coast_mirror_cliff_guard = false
	Global.coast_mirror_cave_guard = false
	Global.coast_mirror_wreck_guard = false
	Global.coast_mirror_cliff = false
	Global.coast_mirror_cave = false
	Global.coast_mirror_wreck = false
	Global.coast_beam_aligned = false
	Global.coast_chest_opened = false
	Global.coast_vault_opened = false
	Global.ska_defeated = false
	Global.third_stele_lit = false

	if destination == "third":
		# 第三关的前置：前两关都已完成
		Global.bridge_repaired = true
		Global.material_crafted = true
		Global.mask_crafted = true
		Global.mask_equipped = true
		Global.boss_defeated = true
		Global.first_stele_lit = true
		Global.roland_defeated = true
		Global.second_stele_lit = true
		Global.monastery_chapel_open = true
	elif destination == "second":
		# 第二关的前置：第一关已完成
		Global.bridge_repaired = true
		Global.material_crafted = true
		Global.mask_crafted = true
		Global.mask_equipped = true
		Global.boss_defeated = true
		Global.first_stele_lit = true
	else:
		# 新手村/第一关：第一关重置为可玩状态
		Global.bridge_repaired = false
		Global.material_crafted = false
		Global.mask_crafted = false
		Global.mask_equipped = false
		Global.boss_defeated = false
		Global.first_stele_lit = false

	var stats: Dictionary = PROFESSION_STATS[profession]
	var weapon := str(stats["weapon"])
	Global.add_item(weapon, 1)
	Global.move_item_to_hotbar(0, {"kind": "inventory_item", "item_id": weapon})
	Global.add_item("recruit_armor", 1)
	Global.move_item_to_equipment("chest", {"kind": "inventory_item", "item_id": "recruit_armor"})
	Global.add_item("herb", 5)
	Global.add_item("silver_oath_sigil", 1)
	Global.add_item("gland", 20)
	Global.add_item("shell", 20)
	Global.add_item("slime", 20)
	Global.add_item("vine", 20)
	Global.ensure_hotbar_defaults()

	var data := {
		"position": [spawn.x, spawn.y],
		"health": int(stats["hp"]),
		"max_health": int(stats["hp"]),
		"has_axe": bool(stats["has_axe"]),
		"has_sword": bool(stats["has_sword"]),
		"current_weapon": str(stats["current"]),
		"attack_upgrades": 8,
		"defense": 9,
		"defense_upgrades": 0,
		"armor_tier": 2,
		"has_camp_key": true,
		"camp_key_granted": true,
		"profession": profession,
		"base_armor_equipped": true,
		"selected_quick_slot": 0,
	}
	SaveGame.pending_player_data = data
	Global.prologue_scene_spawn = ""
	Global.prologue_travel = false
