extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthUI/HealthBar
@onready var health_text: Label = $HealthUI/HealthText
@onready var death_panel: Control = $DeathPanel
@onready var revive_button: Button = $DeathPanel/Panel/VBox/ReviveButton
@onready var hint_label: Label = $HintLabel
@onready var notice_label: Label = $NoticeLabel
@onready var notice_timer: Timer = $NoticeTimer
@onready var crafting_ui = $CraftingUI

const CHARACTER_UI_SCENE: PackedScene = preload("res://scenes/prologue/character_ui.tscn")
const HOTBAR_SLOT_SCRIPT: Script = preload("res://scenes/prologue/hotbar_slot.gd")

const INV_ORDER := ["gland", "shell", "slime", "herb", "vine", "material", "mask"]
const INV_SHORT := {
	"gland": "鳞片",
	"shell": "岩甲",
	"slime": "灰烬",
	"herb": "草药",
	"vine": "焦藤",
	"material": "建材",
	"mask": "护符",
}
const INV_ICONS := {
	"gland": preload("res://graphics/items/gland.png"),
	"shell": preload("res://graphics/items/shell.png"),
	"slime": preload("res://graphics/items/slime.png"),
	"herb": preload("res://graphics/items/herb.png"),
	"vine": preload("res://graphics/items/vine.png"),
	"material": preload("res://graphics/items/material.png"),
	"mask": preload("res://graphics/items/mask.png"),
}

var player
var crafting_open := false
var character_open := false
var character_ui: Control
var ui_font: SystemFont
var quick_panel: Panel
var quick_slots: Array[Panel] = []
var quick_labels: Array[Label] = []
var quick_keys: Array[Label] = []
var _quick_selected := -1

var objective_panel: Panel
var objective_label: Label
var area_label: Label
var banner_label: Label
var banner_subtitle: Label
var _banner_tween: Tween
var channel_root: Control
var channel_panel: Panel
var channel_fill: ColorRect
var channel_label: Label
var _area_name := ""
var _area_tween: Tween
var inv_compact: Panel
var inv_grid: GridContainer
var inv_cells := {}
var inv_labels := {}
var dash_panel: Panel
var dash_fill: ColorRect
var dash_key_label: Label
var skill_name_label: Label
var heal_root: Control
var heal_panel: Panel
var heal_fill: ColorRect
var heal_key_label: Label
var heal_text_label: Label
var _heal_flash := 0.0
var _heal_used_prev := false
var stats_panel: Panel
var atk_label: Label
var def_label: Label
var weapon_panel: Panel
var weapon_slots: Array[Panel] = []
var weapon_icons: Array[TextureRect] = []
var weapon_key_labels: Array[Label] = []
var weapon_slot_states: Array[int] = []

const ICON_FIST := preload("res://graphics/ui/weapon_fist.png")
const ICON_AXE := preload("res://graphics/ui/weapon_axe.png")
const ICON_SWORD := preload("res://graphics/ui/weapon_sword.png")
const WEAPON_SLOTS := [
	{"key": "fist", "icon": ICON_FIST, "num": "1"},
	{"key": "axe", "icon": ICON_AXE, "num": "2"},
	{"key": "sword", "icon": ICON_SWORD, "num": "3"},
]

var _objective_timer := 0.0
var _current_objective := ""
var test_menu_open := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.died.connect(_on_player_died)
		_on_player_health_changed(player.health, player.max_health)
	death_panel.visible = false
	revive_button.pressed.connect(_on_revive_pressed)
	hint_label.visible = false
	notice_label.visible = false
	notice_timer.timeout.connect(_on_notice_timer_timeout)
	crafting_ui.closed.connect(_on_crafting_closed)
	Global.inventory_changed.connect(_update_inventory)

	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	_build_banner()
	_build_objective()
	_build_area_label()
	_build_inventory()
	_build_stats()
	_build_skill_bar()
	_build_weapon_bar()
	_build_quickbar()
	_build_character_ui()
	_build_heal_hint()
	_build_channel_bar()
	_update_inventory()
	_refresh_objective()
	_refresh_stats()
	_refresh_weapon_bar()
	_refresh_quickbar()


func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
	_objective_timer -= delta
	if _objective_timer <= 0.0:
		_objective_timer = 0.35
		_refresh_objective()
		_refresh_stats()
		_refresh_weapon_bar()
		_refresh_quickbar()
	_refresh_skill()
	_refresh_heal_hint()
	_update_area_label()


func _panel_style(bg: Color, border: Color, radius: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	return s


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_banner() -> void:
	banner_label = _make_label("", 20, Color(1.0, 0.76, 0.4))
	banner_label.anchor_left = 0.0
	banner_label.anchor_right = 1.0
	banner_label.anchor_top = 0.32
	banner_label.anchor_bottom = 0.32
	banner_label.offset_top = -18.0
	banner_label.offset_bottom = 18.0
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_constant_override("outline_size", 4)
	banner_label.visible = false
	add_child(banner_label)
	banner_subtitle = _make_label("", 8, Color(0.96, 0.88, 0.72))
	banner_subtitle.anchor_left = 0.0
	banner_subtitle.anchor_right = 1.0
	banner_subtitle.anchor_top = 0.43
	banner_subtitle.anchor_bottom = 0.43
	banner_subtitle.offset_top = -9.0
	banner_subtitle.offset_bottom = 9.0
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_subtitle.visible = false
	add_child(banner_subtitle)


func _build_objective() -> void:
	objective_panel = Panel.new()
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_panel.anchor_left = 0.5
	objective_panel.anchor_right = 0.5
	objective_panel.offset_left = -110.0
	objective_panel.offset_right = 110.0
	objective_panel.offset_top = 4.0
	objective_panel.offset_bottom = 22.0
	objective_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.05, 0.04, 0.72), Color(0.72, 0.58, 0.32, 0.55)))
	add_child(objective_panel)

	objective_label = _make_label("◆ 离开营地，探索岛屿", 7, Color(1.0, 0.9, 0.62))
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_panel.add_child(objective_label)


func _build_area_label() -> void:
	area_label = _make_label("", 16, Color(1.0, 0.94, 0.82))
	area_label.anchor_left = 0.0
	area_label.anchor_right = 1.0
	area_label.anchor_top = 0.35
	area_label.anchor_bottom = 0.35
	area_label.offset_left = 0.0
	area_label.offset_right = 0.0
	area_label.offset_top = -14.0
	area_label.offset_bottom = 14.0
	area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	area_label.add_theme_constant_override("outline_size", 4)
	area_label.visible = false
	add_child(area_label)


func _spaced_name(name: String) -> String:
	var out := ""
	for i in name.length():
		if i > 0:
			out += "  "
		out += name[i]
	return out


func _area_display_name() -> String:
	if player == null:
		return ""
	for zone in get_tree().get_nodes_in_group("SafeZones"):
		if zone.has_method("contains_point") and bool(zone.call("contains_point", player.global_position)):
			return str(zone.get("location_name"))
	var p: Vector2 = player.global_position
	if p.y > 1300.0 and p.x > 140.0 and p.x < 760.0:
		return "白桦林地深处"
	if p.y >= 800.0:
		return "白桦林地外围"
	if p.y >= 200.0:
		return "白桦林地"
	return "白鹿边境"


func _update_area_label() -> void:
	if player == null or area_label == null:
		return
	var name := _area_display_name()
	if name == "" or name == _area_name:
		return
	_area_name = name
	area_label.text = _spaced_name(name)
	area_label.visible = true
	area_label.modulate.a = 0.0
	if _area_tween != null and _area_tween.is_valid():
		_area_tween.kill()
	_area_tween = create_tween()
	_area_tween.tween_property(area_label, "modulate:a", 1.0, 0.25)
	_area_tween.tween_interval(1.1)
	_area_tween.tween_property(area_label, "modulate:a", 0.0, 0.55)
	_area_tween.tween_callback(func() -> void: area_label.visible = false)


func _build_inventory() -> void:
	inv_compact = Panel.new()
	inv_compact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inv_compact.offset_left = 8.0
	inv_compact.offset_top = 8.0
	inv_compact.offset_right = 94.0
	inv_compact.offset_bottom = 52.0
	inv_compact.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.05, 0.04, 0.68), Color(0.72, 0.58, 0.32, 0.5)))
	add_child(inv_compact)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 3)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	inv_compact.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	var title := _make_label("背包", 6, Color(0.9, 0.78, 0.52))
	box.add_child(title)

	inv_grid = GridContainer.new()
	inv_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inv_grid.columns = 2
	inv_grid.add_theme_constant_override("h_separation", 4)
	inv_grid.add_theme_constant_override("v_separation", 1)
	box.add_child(inv_grid)

	for id in INV_ORDER:
		var cell := HBoxContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.custom_minimum_size = Vector2(38.0, 9.0)
		cell.add_theme_constant_override("separation", 1)

		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = INV_ICONS.get(id, null)
		icon.custom_minimum_size = Vector2(8.0, 8.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(icon)

		var label := _make_label(INV_SHORT[id], 6, Color(0.95, 0.92, 0.85))
		cell.add_child(label)

		inv_grid.add_child(cell)
		inv_cells[id] = cell
		inv_labels[id] = label


func _build_stats() -> void:
	stats_panel = Panel.new()
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_panel.anchor_top = 1.0
	stats_panel.anchor_bottom = 1.0
	stats_panel.offset_left = 12.0
	stats_panel.offset_right = 70.0
	stats_panel.offset_top = -66.0
	stats_panel.offset_bottom = -46.0
	stats_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.05, 0.04, 0.68), Color(0.72, 0.58, 0.32, 0.5)))
	add_child(stats_panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	stats_panel.add_child(box)

	atk_label = _make_label("攻 5", 6, Color(1.0, 0.72, 0.38))
	def_label = _make_label("防 1", 6, Color(0.55, 0.8, 1.0))
	atk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(atk_label)
	box.add_child(def_label)


func _build_skill_bar() -> void:
	dash_panel = Panel.new()
	dash_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash_panel.anchor_left = 0.5
	dash_panel.anchor_right = 0.5
	dash_panel.anchor_top = 1.0
	dash_panel.anchor_bottom = 1.0
	dash_panel.offset_left = 80.0
	dash_panel.offset_right = 112.0
	dash_panel.offset_top = -50.0
	dash_panel.offset_bottom = -18.0
	dash_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.05, 0.04, 0.88), Color(0.72, 0.58, 0.32, 0.65), 2))
	add_child(dash_panel)

	dash_fill = ColorRect.new()
	dash_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash_fill.color = Color(0.78, 0.58, 0.24, 0.95)
	dash_fill.anchor_left = 0.0
	dash_fill.anchor_right = 1.0
	dash_fill.anchor_top = 1.0
	dash_fill.anchor_bottom = 1.0
	dash_fill.offset_left = 2.0
	dash_fill.offset_right = -2.0
	dash_fill.offset_top = -2.0
	dash_fill.offset_bottom = -2.0
	dash_panel.add_child(dash_fill)

	skill_name_label = _make_label("冲刺", 8, Color(1.0, 0.95, 0.75))
	skill_name_label.anchor_left = 0.0
	skill_name_label.anchor_right = 1.0
	skill_name_label.offset_left = 0.0
	skill_name_label.offset_right = 0.0
	skill_name_label.offset_top = 3.0
	skill_name_label.offset_bottom = 17.0
	skill_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dash_panel.add_child(skill_name_label)

	dash_key_label = _make_label("V", 5, Color(0.95, 0.82, 0.55))
	dash_key_label.anchor_left = 0.0
	dash_key_label.anchor_right = 1.0
	dash_key_label.offset_left = 0.0
	dash_key_label.offset_right = 0.0
	dash_key_label.offset_top = 17.0
	dash_key_label.offset_bottom = 27.0
	dash_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dash_key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dash_panel.add_child(dash_key_label)


func _build_weapon_bar() -> void:
	weapon_panel = Panel.new()
	weapon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_panel.anchor_left = 0.5
	weapon_panel.anchor_right = 0.5
	weapon_panel.anchor_top = 1.0
	weapon_panel.anchor_bottom = 1.0
	weapon_panel.offset_left = -54.0
	weapon_panel.offset_right = 54.0
	weapon_panel.offset_top = -50.0
	weapon_panel.offset_bottom = -16.0
	weapon_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.05, 0.04, 0.72), Color(0.72, 0.58, 0.32, 0.5)))
	add_child(weapon_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 3)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	weapon_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	margin.add_child(row)

	for slot in WEAPON_SLOTS:
		var p := Panel.new()
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.custom_minimum_size = Vector2(30.0, 28.0)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", _weapon_style(0))
		row.add_child(p)

		var icon := TextureRect.new()
		icon.texture = slot["icon"]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_preset(Control.PRESET_CENTER)
		icon.offset_left = -11.0
		icon.offset_top = -13.0
		icon.offset_right = 11.0
		icon.offset_bottom = 9.0
		p.add_child(icon)

		var num := _make_label(str(slot["num"]), 6, Color(0.75, 0.7, 0.6))
		num.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		num.offset_left = -10.0
		num.offset_top = -10.0
		num.offset_right = -2.0
		num.offset_bottom = -1.0
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		p.add_child(num)

		weapon_slots.append(p)
		weapon_icons.append(icon)
		weapon_key_labels.append(num)
		weapon_slot_states.append(-1)


func _weapon_style(state: int) -> StyleBoxFlat:
	var bg := Color(0.05, 0.05, 0.05, 0.7)
	var border := Color(0.25, 0.22, 0.18, 0.6)
	if state == 2:
		bg = Color(0.22, 0.16, 0.08, 0.95)
		border = Color(1.0, 0.8, 0.35, 0.95)
	elif state == 1:
		bg = Color(0.1, 0.08, 0.06, 0.85)
		border = Color(0.55, 0.46, 0.3, 0.8)
	var s := _panel_style(bg, border, 2)
	if state == 2:
		s.set_border_width_all(2)
	return s


func _refresh_weapon_bar() -> void:
	if player == null or weapon_slots.is_empty():
		return
	for i in WEAPON_SLOTS.size():
		var key := str(WEAPON_SLOTS[i]["key"])
		var owned := bool(player.call("has_weapon", key))
		var state := 2 if str(player.get("current_weapon")) == key else (1 if owned else 0)
		if weapon_slot_states[i] == state:
			continue
		weapon_slot_states[i] = state
		weapon_slots[i].add_theme_stylebox_override("panel", _weapon_style(state))
		weapon_icons[i].visible = owned
		var col := Color(1.0, 0.9, 0.55)
		if state == 1:
			col = Color(0.9, 0.88, 0.8)
		elif state == 0:
			col = Color(0.35, 0.33, 0.3)
		weapon_key_labels[i].add_theme_color_override("font_color", col)
		weapon_icons[i].modulate = Color.WHITE if state == 2 else Color(0.82, 0.8, 0.74)


func _has_profession() -> bool:
	if player == null:
		return false
	var value = player.get("profession")
	return value is String and not (value as String).is_empty()


func _build_quickbar() -> void:
	quick_panel = Panel.new()
	quick_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quick_panel.anchor_left = 0.5
	quick_panel.anchor_right = 0.5
	quick_panel.anchor_top = 1.0
	quick_panel.anchor_bottom = 1.0
	quick_panel.offset_left = -55.0
	quick_panel.offset_right = 55.0
	quick_panel.offset_top = -50.0
	quick_panel.offset_bottom = -16.0
	quick_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.05, 0.04, 0.8), Color(0.72, 0.58, 0.32, 0.55)))
	quick_panel.visible = false
	add_child(quick_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	quick_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 3)
	margin.add_child(row)

	var key_actions := ["weapon_1", "weapon_2", "weapon_3", "weapon_4"]
	for i in Global.HOTBAR_SIZE:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(23.0, 28.0)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.set_script(HOTBAR_SLOT_SCRIPT)
		slot.call("setup", i)
		slot.connect("item_dropped", _on_hotbar_drop)
		slot.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.06, 0.04, 0.9), Color(0.32, 0.25, 0.16), 2))
		row.add_child(slot)

		var text := _make_label("", 5, Color(0.94, 0.88, 0.75))
		text.position = Vector2(1.0, 3.0)
		text.size = Vector2(21.0, 14.0)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(text)

		var key := _make_label(Settings.binding_text(str(key_actions[i])), 4, Color(1.0, 0.82, 0.46))
		key.position = Vector2(1.0, 0.0)
		key.size = Vector2(20.0, 7.0)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		slot.add_child(key)

		quick_slots.append(slot)
		quick_labels.append(text)
		quick_keys.append(key)


func _refresh_quickbar() -> void:
	if quick_panel == null:
		return
	var active := _has_profession()
	if weapon_panel != null:
		weapon_panel.visible = not active
	quick_panel.visible = active
	if not active:
		return
	var key_actions := ["weapon_1", "weapon_2", "weapon_3", "weapon_4"]
	var selected := int(player.get("selected_quick_slot"))
	for i in quick_slots.size():
		var item_id := str(Global.hotbar[i]) if i < Global.hotbar.size() else ""
		var count := int(Global.hotbar_counts[i]) if i < Global.hotbar_counts.size() else 0
		var item_name := str(Global.ITEM_NAMES.get(item_id, item_id))
		quick_slots[i].call("set_item", item_id if count > 0 else "")
		quick_labels[i].text = _short_item_name(item_name) if count > 0 else "—"
		if count > 1:
			quick_labels[i].text += "\n%d" % count
		quick_keys[i].text = Settings.binding_text(str(key_actions[i]))
		var is_active := i == selected
		var accent := Color(1.0, 0.72, 0.3) if is_active else Color(0.32, 0.25, 0.16)
		var bg := Color(0.18, 0.11, 0.04, 0.98) if is_active else Color(0.08, 0.06, 0.04, 0.9)
		quick_slots[i].add_theme_stylebox_override("panel", _panel_style(bg, accent, 2))


func _short_item_name(value: String) -> String:
	match value:
		"旧铁长剑": return "长剑"
		"见习法杖": return "法杖"
		"见习者皮甲": return "皮甲"
		"银誓徽记": return "徽记"
	return value if value.length() <= 3 else value.substr(0, 3)


func _on_hotbar_drop(target_index: int, drag_data: Dictionary) -> void:
	Global.move_item_to_hotbar(target_index, drag_data)


func _build_character_ui() -> void:
	character_ui = CHARACTER_UI_SCENE.instantiate()
	character_ui.visible = false
	add_child(character_ui)
	character_ui.connect("closed", _on_character_closed)


func _unhandled_input(event: InputEvent) -> void:
	if test_menu_open:
		return
	if event.is_action_pressed("character_menu"):
		if character_open:
			_close_character()
			get_viewport().set_input_as_handled()
		elif _can_open_character():
			_open_character()
			get_viewport().set_input_as_handled()
		return
	if character_open and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_close_character()
		get_viewport().set_input_as_handled()


func _can_open_character() -> bool:
	if player == null or crafting_open or character_open:
		return false
	if death_panel != null and death_panel.visible:
		return false
	var victory = get_tree().get_first_node_in_group("VictoryScreen")
	if victory != null and victory.has_method("is_open") and bool(victory.call("is_open")):
		return false
	return true


func _open_character() -> void:
	if not _can_open_character():
		return
	character_open = true
	if player != null:
		player.call("set_input_locked", true)
	character_ui.call("open", player)
	get_tree().paused = true


func _close_character() -> void:
	if not character_open:
		return
	character_ui.call("close")


func _on_character_closed() -> void:
	character_open = false
	get_tree().paused = false
	if player != null:
		player.call("set_input_locked", false)


func _refresh_objective() -> void:
	var text := _compute_objective()
	if text == _current_objective:
		return
	_current_objective = text
	objective_label.text = "◆ " + text
	objective_label.modulate = Color(1.5, 1.25, 0.8)
	var t := create_tween()
	t.tween_property(objective_label, "modulate", Color.WHITE, 0.45)


func _compute_objective() -> String:
	if Global.first_stele_lit:
		return "白桦林地已净化"
	if Global.boss_defeated:
		return "点燃誓火石碑"
	if Global.mask_equipped:
		return "击败裂牙格鲁姆"
	if Global.bridge_repaired:
		if Global.mask_crafted or int(Global.inventory.get("mask", 0)) > 0:
			return "戴上灰烬护符，穿过龙焰烟尘"
		return "制作灰烬护符"
	var stage := int(Global.bridge_repair_stage)
	var materials := int(Global.inventory.get("material", 0))
	if materials >= 3:
		return "建材已集齐：尽快赶往断桥抢修"
	if stage > 0:
		if materials <= 0:
			return "寻找建材，继续抢修前哨木桥（已完成 %d/3）" % stage
		return "继续抢修前哨木桥（已完成 %d/3，可再修 %d 段）" % [stage, mini(materials, 3 - stage)]
	if materials > 0:
		return "已有建材 %d 份：到前哨木桥抢修第 1 段" % materials
	if Global.bridge_tracking_done:
		return "收集剩余建材（0/3）"
	return "收集建材，追踪伐木队留下的血迹"


func _refresh_stats() -> void:
	if player == null or atk_label == null:
		return
	atk_label.text = "攻 %d" % int(player.get_weapon_damage())
	def_label.text = "防 %d" % int(player.defense)


func _refresh_skill() -> void:
	if player == null or dash_fill == null:
		return
	var cd := float(player.dash_cd_timer)
	var total := maxf(float(player.get_skill_cooldown()), 0.01)
	var progress := clampf(1.0 - cd / total, 0.0, 1.0)
	dash_fill.offset_top = -2.0 - 28.0 * progress
	var skill_name := str(player.get_skill_name())
	if skill_name_label.text != skill_name:
		skill_name_label.text = skill_name
	var key_text := Settings.binding_text("dash")
	if key_text.begins_with("鼠标"):
		key_text = key_text.substr(2)
	if dash_key_label.text != key_text:
		dash_key_label.text = key_text


func _build_heal_hint() -> void:
	heal_root = Control.new()
	heal_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heal_root.visible = false
	add_child(heal_root)

	heal_panel = Panel.new()
	heal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heal_panel.position = Vector2.ZERO
	heal_panel.size = Vector2(11, 13)
	heal_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.05, 0.04, 0.9), Color(0.72, 0.58, 0.32, 0.7), 1))
	heal_root.add_child(heal_panel)

	heal_fill = ColorRect.new()
	heal_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heal_fill.color = Color(0.78, 0.58, 0.24, 0.95)
	heal_fill.anchor_left = 0.0
	heal_fill.anchor_right = 1.0
	heal_fill.anchor_top = 1.0
	heal_fill.anchor_bottom = 1.0
	heal_fill.offset_left = 1.5
	heal_fill.offset_right = -1.5
	heal_fill.offset_top = -1.5
	heal_fill.offset_bottom = -1.5
	heal_panel.add_child(heal_fill)

	heal_key_label = _make_label("Q", 6, Color(1.0, 0.95, 0.78))
	heal_key_label.anchor_left = 0.0
	heal_key_label.anchor_right = 1.0
	heal_key_label.anchor_top = 0.0
	heal_key_label.anchor_bottom = 1.0
	heal_key_label.offset_left = 0.0
	heal_key_label.offset_right = 0.0
	heal_key_label.offset_top = 0.0
	heal_key_label.offset_bottom = 0.0
	heal_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heal_key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heal_panel.add_child(heal_key_label)

	heal_text_label = _make_label("回血", 5, Color(1.0, 0.32, 0.28))
	heal_text_label.position = Vector2(13.0, 2.0)
	heal_root.add_child(heal_text_label)


func _build_channel_bar() -> void:
	channel_root = Control.new()
	channel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	channel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	channel_root.visible = false
	add_child(channel_root)

	channel_label = _make_label("", 9, Color(1.0, 0.9, 0.66))
	channel_label.anchor_left = 0.5
	channel_label.anchor_right = 0.5
	channel_label.anchor_top = 1.0
	channel_label.anchor_bottom = 1.0
	channel_label.offset_left = -130.0
	channel_label.offset_right = 130.0
	channel_label.offset_top = -140.0
	channel_label.offset_bottom = -122.0
	channel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	channel_root.add_child(channel_label)

	channel_panel = Panel.new()
	channel_panel.anchor_left = 0.5
	channel_panel.anchor_right = 0.5
	channel_panel.anchor_top = 1.0
	channel_panel.anchor_bottom = 1.0
	channel_panel.offset_left = -88.0
	channel_panel.offset_right = 88.0
	channel_panel.offset_top = -118.0
	channel_panel.offset_bottom = -105.0
	channel_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	channel_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.04, 0.03, 0.92), Color(0.72, 0.55, 0.28, 0.9), 2))
	channel_root.add_child(channel_panel)

	channel_fill = ColorRect.new()
	channel_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	channel_fill.position = Vector2(2.0, 2.0)
	channel_fill.size = Vector2(172.0, 9.0)
	channel_fill.color = Color(0.9, 0.68, 0.28, 1.0)
	channel_panel.add_child(channel_fill)


func show_channel(progress: float, text: String) -> void:
	if channel_root == null:
		return
	channel_root.visible = true
	channel_label.text = text
	var p := clampf(progress, 0.0, 1.0)
	channel_fill.size = Vector2(172.0 * p, 9.0)
	channel_fill.visible = p > 0.001


func hide_channel() -> void:
	if channel_root != null:
		channel_root.visible = false


func _refresh_heal_hint() -> void:
	if player == null or heal_root == null:
		return
	var herbs := int(Global.inventory.get("herb", 0))
	var can_heal := herbs > 0 and int(player.health) < int(player.max_health) and not bool(player.dead)
	var show := can_heal and not crafting_open and not character_open
	heal_root.visible = show
	if heal_text_label != null:
		heal_text_label.text = "草药"

	var holding := Input.is_action_pressed("use_herb")
	var used := bool(player.herb_hold_used)
	if used and not _heal_used_prev:
		_heal_flash = 0.28
	_heal_used_prev = used
	if _heal_flash > 0.0:
		_heal_flash = maxf(_heal_flash - get_process_delta_time(), 0.0)

	if not show:
		return

	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * player.global_position
	heal_root.position = screen_pos + Vector2(-5.0, -30.0)

	var progress := 0.0
	if _heal_flash > 0.0:
		progress = 1.0
	elif holding and not used:
		progress = clampf(float(player.herb_hold) / maxf(float(player.herb_hold_time), 0.01), 0.0, 1.0)
	heal_fill.offset_top = -1.5 - 10.0 * progress

	var key_text := Settings.binding_text("use_herb")
	if key_text.begins_with("鼠标"):
		key_text = key_text.substr(2)
	if heal_key_label.text != key_text:
		heal_key_label.text = key_text
		var key_size := 6 if key_text.length() <= 2 else 4
		heal_key_label.add_theme_font_size_override("font_size", key_size)


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_text.text = "%d / %d" % [current, maximum]


func _on_player_died() -> void:
	death_panel.visible = true
	revive_button.grab_focus()
	get_tree().paused = true


func _on_revive_pressed() -> void:
	get_tree().paused = false
	death_panel.visible = false
	if player:
		player.call("revive_at_camp")
		player.call("set_input_locked", false)


func show_hint(text: String) -> void:
	hint_label.text = text
	hint_label.visible = true


func hide_hint() -> void:
	hint_label.visible = false


func show_notice(text: String) -> void:
	notice_label.text = text
	notice_label.visible = true
	notice_timer.start()


func show_banner(title: String, subtitle: String = "", duration: float = 2.4) -> void:
	banner_label.text = title
	banner_subtitle.text = subtitle
	banner_label.visible = true
	banner_subtitle.visible = not subtitle.is_empty()
	banner_label.modulate.a = 0.0
	banner_subtitle.modulate.a = 0.0
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(banner_label, "modulate:a", 1.0, 0.35)
	_banner_tween.tween_property(banner_subtitle, "modulate:a", 1.0, 0.35)
	_banner_tween.chain().tween_interval(duration)
	_banner_tween.chain().tween_property(banner_label, "modulate:a", 0.0, 0.45)
	_banner_tween.parallel().tween_property(banner_subtitle, "modulate:a", 0.0, 0.45)
	_banner_tween.chain().tween_callback(func() -> void:
		banner_label.visible = false
		banner_subtitle.visible = false
	)


func _on_notice_timer_timeout() -> void:
	notice_label.visible = false


func _update_inventory() -> void:
	if inv_compact == null:
		return
	var showing := 0
	for id in INV_ORDER:
		var count := int(Global.inventory.get(id, 0))
		var cell: Control = inv_cells[id]
		cell.visible = count > 0
		if count > 0:
			showing += 1
			var label: Label = inv_labels[id]
			if Global.ITEM_CAPS.has(id):
				label.text = "%s %d/%d" % [INV_SHORT[id], count, Global.item_cap(id)]
			else:
				label.text = "%s %d" % [INV_SHORT[id], count]
	inv_compact.visible = showing > 0
	if showing > 0:
		var rows := int(ceil(showing / 2.0))
		inv_compact.offset_bottom = inv_compact.offset_top + 15.0 + rows * 10.0


func open_crafting() -> void:
	if crafting_open or character_open:
		return
	crafting_open = true
	hide_hint()
	crafting_ui.call("open")


func _on_crafting_closed() -> void:
	crafting_open = false
