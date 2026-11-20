extends Control

signal closed

const PLAYER_TEXTURE: Texture2D = preload("res://graphics/characters/player_animations.png")
const INVENTORY_SLOT_SCRIPT: Script = preload("res://scenes/prologue/inventory_slot.gd")
const HOTBAR_SLOT_SCRIPT: Script = preload("res://scenes/prologue/hotbar_slot.gd")
const EQUIPMENT_SLOT_SCRIPT: Script = preload("res://scenes/prologue/equipment_slot.gd")
const TAB_INVENTORY := "inventory"
const TAB_SKILLS := "skills"

var player
var font: SystemFont
var current_tab := TAB_INVENTORY
var selected_skill := 0
var inventory_page: Control
var skills_page: Control
var inventory_tab: Button
var skills_tab: Button
var character_name: Label
var character_stats: Label
var equipment_values := {}
var equipment_slots := {}
var item_bar_slots: Array[Panel] = []
var item_bar_text: Array[Label] = []
var bag_slots: Array[Panel] = []
var bag_labels: Array[Label] = []
var skill_buttons: Array[Button] = []
var skill_detail_title: Label
var skill_detail_type: Label
var skill_detail_body: Label
var skill_detail_key: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	_build()
	Global.inventory_changed.connect(_on_inventory_changed)


func open(player_node) -> void:
	player = player_node
	visible = true
	current_tab = TAB_INVENTORY
	selected_skill = 0
	_refresh()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _style(bg: Color, border: Color, radius: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _label(text: String, size: int, color: Color = Color(0.92, 0.88, 0.78)) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, size: int = 7) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color(0.94, 0.88, 0.75))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.82, 0.42))
	button.add_theme_stylebox_override("normal", _style(Color(0.08, 0.06, 0.04, 0.98), Color(0.36, 0.28, 0.17)))
	button.add_theme_stylebox_override("hover", _style(Color(0.17, 0.115, 0.055, 1.0), Color(0.9, 0.66, 0.28)))
	button.add_theme_stylebox_override("pressed", _style(Color(0.24, 0.15, 0.055, 1.0), Color(1.0, 0.75, 0.32)))
	return button


func _panel(parent: Node, pos: Vector2, size: Vector2, accent: Color = Color(0.48, 0.37, 0.2)) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color(0.045, 0.035, 0.025, 0.98), accent))
	parent.add_child(panel)
	return panel


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.01, 0.008, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var frame := _panel(self, Vector2(26, 23), Vector2(416, 224), Color(0.76, 0.56, 0.26))
	frame.add_theme_stylebox_override("panel", _style(Color(0.055, 0.043, 0.03, 0.995), Color(0.76, 0.56, 0.26), 4))

	inventory_page = Control.new()
	inventory_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(inventory_page)
	_build_inventory_page(inventory_page)

	skills_page = Control.new()
	skills_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skills_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(skills_page)
	_build_skills_page(skills_page)

	inventory_tab = _button("背包", 6)
	inventory_tab.position = Vector2(439, 51)
	inventory_tab.size = Vector2(32, 24)
	inventory_tab.pressed.connect(_set_tab.bind(TAB_INVENTORY))
	add_child(inventory_tab)

	skills_tab = _button("技能", 6)
	skills_tab.position = Vector2(439, 79)
	skills_tab.size = Vector2(32, 24)
	skills_tab.pressed.connect(_set_tab.bind(TAB_SKILLS))
	add_child(skills_tab)

	var close_button := _button("×", 10)
	close_button.position = Vector2(417, 224)
	close_button.size = Vector2(20, 19)
	close_button.pressed.connect(close)
	add_child(close_button)


func _build_inventory_page(parent: Control) -> void:
	var equipment_names := ["头盔", "胸甲", "裤子", "鞋子"]
	var equipment_ids := ["helmet", "chest", "pants", "shoes"]
	for i in equipment_names.size():
		var slot := Panel.new()
		slot.position = Vector2(12, 12 + i * 48)
		slot.size = Vector2(48, 39)
		slot.set_script(EQUIPMENT_SLOT_SCRIPT)
		slot.call("setup", equipment_ids[i])
		slot.connect("item_dropped", _on_equipment_drop)
		slot.add_theme_stylebox_override("panel", _style(Color(0.035, 0.028, 0.022, 0.95), Color(0.38, 0.3, 0.18), 2))
		parent.add_child(slot)
		var name_label := _label(equipment_names[i], 6, Color(0.76, 0.67, 0.53))
		name_label.position = Vector2(4, 2)
		slot.add_child(name_label)
		var value_label := _label("空", 5, Color(0.48, 0.45, 0.4))
		value_label.position = Vector2(3, 18)
		value_label.size = Vector2(42, 17)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(value_label)
		equipment_values[equipment_ids[i]] = value_label
		equipment_slots[equipment_ids[i]] = slot

	var preview_panel := _panel(parent, Vector2(68, 12), Vector2(150, 158), Color(0.56, 0.42, 0.2))
	var atlas := AtlasTexture.new()
	atlas.atlas = PLAYER_TEXTURE
	atlas.region = Rect2(0, 0, 48, 48)
	var preview := TextureRect.new()
	preview.texture = atlas
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.position = Vector2(18, 10)
	preview.size = Vector2(114, 104)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(preview)
	character_name = _label("见习冒险者", 8, Color(1.0, 0.82, 0.46))
	character_name.position = Vector2(5, 114)
	character_name.size = Vector2(140, 12)
	character_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_panel.add_child(character_name)
	character_stats = _label("", 6, Color(0.82, 0.77, 0.67))
	character_stats.position = Vector2(5, 128)
	character_stats.size = Vector2(140, 24)
	character_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	character_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_panel.add_child(character_stats)

	var item_label := _label("物品栏", 5, Color(0.7, 0.62, 0.5))
	item_label.position = Vector2(118, 172)
	item_label.size = Vector2(50, 9)
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(item_label)
	for i in 4:
		var slot := Panel.new()
		slot.position = Vector2(72 + i * 36, 182)
		slot.size = Vector2(30, 23)
		slot.set_script(HOTBAR_SLOT_SCRIPT)
		slot.call("setup", i)
		slot.add_theme_stylebox_override("panel", _style(Color(0.035, 0.028, 0.022, 0.95), Color(0.35, 0.28, 0.17), 2))
		slot.connect("item_dropped", _on_hotbar_drop)
		parent.add_child(slot)
		var label := _label("", 5, Color(0.9, 0.85, 0.75))
		label.position = Vector2(2, 1)
		label.size = Vector2(26, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(label)
		item_bar_slots.append(slot)
		item_bar_text.append(label)

	var bag_panel := _panel(parent, Vector2(226, 11), Vector2(180, 202), Color(0.48, 0.36, 0.2))
	var bag_title := _label("背包  ·  16 格", 6, Color(0.82, 0.72, 0.54))
	bag_title.position = Vector2(8, 2)
	bag_title.size = Vector2(164, 10)
	bag_panel.add_child(bag_title)
	var grid := GridContainer.new()
	grid.position = Vector2(10, 17)
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag_panel.add_child(grid)
	for i in 16:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(35, 36)
		slot.set_script(INVENTORY_SLOT_SCRIPT)
		slot.call("setup", "")
		slot.connect("item_returned", _on_item_returned)
		slot.add_theme_stylebox_override("panel", _style(Color(0.035, 0.028, 0.022, 0.95), Color(0.26, 0.22, 0.16), 2))
		grid.add_child(slot)
		var label := _label("", 5, Color(0.88, 0.82, 0.7))
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.offset_left = 2
		label.offset_top = 2
		label.offset_right = -2
		label.offset_bottom = -2
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(label)
		bag_slots.append(slot)
		bag_labels.append(label)


func _build_skills_page(parent: Control) -> void:
	var title := _label("职业", 8, Color(0.92, 0.8, 0.55))
	title.position = Vector2(12, 5)
	title.size = Vector2(60, 12)
	parent.add_child(title)
	for i in 4:
		var button := _button("", 6)
		button.position = Vector2(12, 24 + i * 45)
		button.size = Vector2(58, 37)
		button.pressed.connect(_select_skill.bind(i))
		parent.add_child(button)
		skill_buttons.append(button)

	var detail := _panel(parent, Vector2(80, 20), Vector2(292, 180), Color(0.56, 0.42, 0.21))
	var heading := _label("技能库", 6, Color(0.72, 0.64, 0.52))
	heading.position = Vector2(9, 4)
	detail.add_child(heading)
	skill_detail_title = _label("", 13, Color(1.0, 0.8, 0.43))
	skill_detail_title.position = Vector2(12, 21)
	skill_detail_title.size = Vector2(268, 18)
	detail.add_child(skill_detail_title)
	skill_detail_type = _label("", 6, Color(0.67, 0.86, 0.64))
	skill_detail_type.position = Vector2(12, 43)
	skill_detail_type.size = Vector2(268, 11)
	detail.add_child(skill_detail_type)
	var divider := ColorRect.new()
	divider.position = Vector2(12, 58)
	divider.size = Vector2(268, 1)
	divider.color = Color(0.48, 0.36, 0.2, 0.75)
	detail.add_child(divider)
	skill_detail_body = _label("", 7, Color(0.89, 0.84, 0.74))
	skill_detail_body.position = Vector2(12, 68)
	skill_detail_body.size = Vector2(268, 76)
	skill_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(skill_detail_body)
	skill_detail_key = _label("", 7, Color(1.0, 0.78, 0.38))
	skill_detail_key.position = Vector2(12, 150)
	skill_detail_key.size = Vector2(268, 18)
	skill_detail_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.add_child(skill_detail_key)


func _set_tab(tab: String) -> void:
	current_tab = tab
	_refresh()


func _select_skill(index: int) -> void:
	selected_skill = index
	_refresh_skills()


func _refresh() -> void:
	if player == null:
		return
	inventory_page.visible = current_tab == TAB_INVENTORY
	skills_page.visible = current_tab == TAB_SKILLS
	inventory_tab.add_theme_stylebox_override("normal", _tab_style(current_tab == TAB_INVENTORY))
	skills_tab.add_theme_stylebox_override("normal", _tab_style(current_tab == TAB_SKILLS))
	if current_tab == TAB_INVENTORY:
		_refresh_inventory()
	else:
		_refresh_skills()


func _tab_style(active: bool) -> StyleBoxFlat:
	if active:
		return _style(Color(0.26, 0.16, 0.05, 1.0), Color(1.0, 0.72, 0.28), 3)
	return _style(Color(0.07, 0.055, 0.038, 0.98), Color(0.35, 0.28, 0.17), 3)


func _refresh_inventory() -> void:
	for slot_id in Global.EQUIPMENT_SLOTS:
		var item_id := str(Global.equipment[slot_id].get("id", ""))
		equipment_slots[slot_id].call("set_item", item_id)
		var label: Label = equipment_values[slot_id]
		label.text = _display_name(item_id) if not item_id.is_empty() else "空"
		label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.69) if not item_id.is_empty() else Color(0.42, 0.4, 0.36))

	character_name.text = "%s  ·  %s" % [str(player.call("get_profession_name")), "见习冒险者"]
	character_stats.text = "生命 %d / %d\n防御 %d" % [
		int(player.get("health")),
		int(player.get("max_health")),
		int(player.get("defense")),
	]

	var quick_items := [
		Global.hotbar[0],
		Global.hotbar[1],
		Global.hotbar[2],
		Global.hotbar[3],
	]
	for i in 4:
		var item_id := str(quick_items[i])
		var count := int(Global.hotbar_counts[i])
		item_bar_slots[i].call("set_item", item_id if count > 0 else "")
		item_bar_text[i].text = _short_name(_item_name(item_id)) if count > 0 else "—"
		if count > 1:
			item_bar_text[i].text += "\n%d" % count
		item_bar_text[i].add_theme_color_override("font_color", Color(0.92, 0.84, 0.65) if count > 0 else Color(0.38, 0.36, 0.32))

	var entries := []
	for item_id in Global.ITEM_NAMES:
		var count := int(Global.inventory.get(item_id, 0))
		if count > 0:
			entries.append({"id": item_id, "count": count})
	for i in 16:
		if i < entries.size():
			var entry: Dictionary = entries[i]
			var name := str(Global.ITEM_NAMES.get(entry["id"], entry["id"]))
			bag_slots[i].call("setup", str(entry["id"]))
			bag_labels[i].text = "%s\n×%d" % [_short_name(name), int(entry["count"])]
			bag_labels[i].add_theme_color_override("font_color", Color(0.92, 0.84, 0.68))
			bag_slots[i].add_theme_stylebox_override("panel", _style(Color(0.11, 0.075, 0.04, 0.98), Color(0.62, 0.45, 0.22), 2))
		else:
			bag_slots[i].call("setup", "")
			bag_labels[i].text = ""
			bag_slots[i].add_theme_stylebox_override("panel", _style(Color(0.035, 0.028, 0.022, 0.95), Color(0.26, 0.22, 0.16), 2))


func _refresh_skills() -> void:
	var skills := _skill_data()
	for i in skill_buttons.size():
		var data: Dictionary = skills[i]
		skill_buttons[i].text = "%s\n%s" % [str(data["slot"]), str(data["name"])]
		skill_buttons[i].add_theme_stylebox_override("normal", _tab_style(i == selected_skill))
	var data: Dictionary = skills[selected_skill]
	skill_detail_title.text = str(data["name"])
	skill_detail_type.text = "%s  ·  %s" % [str(data["slot"]), str(data["type"])]
	skill_detail_body.text = str(data["description"])
	skill_detail_key.text = str(data["footer"])


func _skill_data() -> Array:
	var profession := str(player.get("profession"))
	var key_skill := Settings.binding_text("dash")
	var key_weapon := Settings.binding_text("weapon_skill")
	var data_by_profession := {
		"warrior": [
			{"slot": "主动1", "name": "破阵冲锋", "type": "职业技能", "description": "向当前方向冲锋，击退沿途敌人并使其短暂失衡。", "footer": "[%s] 释放  ·  冷却 5 秒" % key_skill},
			{"slot": "主动2", "name": "横斩", "type": "武器特技", "description": "挥出大范围横斩，造成高额伤害并击退近身敌人。", "footer": "[%s] 使用  ·  冷却 4.2 秒" % key_weapon},
			{"slot": "主动3", "name": "尚未解锁", "type": "职业进阶", "description": "完成后续主线后解锁新的战士主动技能。", "footer": "继续冒险以解锁"},
			{"slot": "被动", "name": "银誓见习者", "type": "职业被动", "description": "穿戴见习者皮甲后额外获得 1 点防御。", "footer": "装备生效时持续存在"},
		],
		"ranger": [
			{"slot": "主动1", "name": "翻滚", "type": "职业技能", "description": "向当前方向翻滚，翻滚期间免疫伤害。", "footer": "[%s] 释放  ·  冷却 4.5 秒" % key_skill},
			{"slot": "主动2", "name": "三连射", "type": "武器特技", "description": "同时射出三支箭矢，适合中距离压制。", "footer": "[%s] 使用  ·  冷却 3.5 秒" % key_weapon},
			{"slot": "主动3", "name": "尚未解锁", "type": "职业进阶", "description": "完成后续主线后解锁新的游侠主动技能。", "footer": "继续冒险以解锁"},
			{"slot": "被动", "name": "轻盈步伐", "type": "职业被动", "description": "游侠拥有更高的机动性，依靠翻滚穿过危险攻击。", "footer": "职业特性"},
		],
		"mage": [
			{"slot": "主动1", "name": "闪现", "type": "职业技能", "description": "短距离瞬移，瞬移期间免疫伤害。", "footer": "[%s] 释放  ·  冷却 5 秒" % key_skill},
			{"slot": "主动2", "name": "蓄力火球", "type": "武器特技", "description": "短暂蓄力后发射火球，命中时造成范围爆炸。", "footer": "[%s] 使用  ·  冷却 5 秒" % key_weapon},
			{"slot": "主动3", "name": "尚未解锁", "type": "职业进阶", "description": "完成后续主线后解锁新的法师主动技能。", "footer": "继续冒险以解锁"},
			{"slot": "被动", "name": "法力亲和", "type": "职业被动", "description": "熟练操控龙焰魔法，爆发能力高于其他职业。", "footer": "职业特性"},
		],
	}
	return data_by_profession.get(profession, data_by_profession["warrior"])


func _item_name(item_id: String) -> String:
	if item_id.is_empty():
		return ""
	return str(Global.ITEM_NAMES.get(item_id, item_id))


func _short_name(value: String) -> String:
	return value if value.length() <= 5 else value.substr(0, 5)


func _on_inventory_changed() -> void:
	if visible:
		_refresh()


func _display_name(item_id: String) -> String:
	return _short_name(str(Global.ITEM_NAMES.get(item_id, item_id)))


func _on_hotbar_drop(target_index: int, drag_data: Dictionary) -> void:
	Global.move_item_to_hotbar(target_index, drag_data)


func _on_equipment_drop(target_slot: String, drag_data: Dictionary) -> void:
	Global.move_item_to_equipment(target_slot, drag_data)


func _on_item_returned(drag_data: Dictionary) -> void:
	match str(drag_data.get("kind", "")):
		"hotbar_item":
			Global.clear_hotbar_slot(int(drag_data.get("slot_index", -1)))
		"equipment_item":
			Global.clear_equipment_slot(str(drag_data.get("slot", "")))

