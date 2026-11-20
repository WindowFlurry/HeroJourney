extends Control

# 临时测试面板：Tab 打开，可增减所有道具、调整血量。后续删除。

const ITEM_ORDER := ["gland", "shell", "slime", "herb", "vine", "material", "mask"]

var player
var hud
var ui_font: SystemFont
var count_labels := {}
var hp_label: Label
var panel_open := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	player = get_tree().get_first_node_in_group("Player")
	hud = get_tree().get_first_node_in_group("HUD")
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	_build_ui()
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.health, player.max_health)
	Global.inventory_changed.connect(_refresh_items)
	_refresh_items()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -116.0
	panel.offset_top = -104.0
	panel.offset_right = 116.0
	panel.offset_bottom = 104.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	style.border_color = Color(0.72, 0.58, 0.32)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var title := _make_label("测试模式    Tab / Esc 关闭", 9, Color(1, 0.85, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(HSeparator.new())

	for id in ITEM_ORDER:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		var name_label := _make_label(Global.ITEM_NAMES[id], 8)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var count_label := _make_label("0", 8, Color(1, 0.9, 0.6))
		count_label.custom_minimum_size = Vector2(20, 0)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(count_label)
		count_labels[id] = count_label
		var minus := _make_button("-1", 18)
		minus.pressed.connect(_change_item.bind(id, -1))
		row.add_child(minus)
		var plus := _make_button("+1", 18)
		plus.pressed.connect(_change_item.bind(id, 1))
		row.add_child(plus)
		var plus_ten := _make_button("+10", 22)
		plus_ten.pressed.connect(_change_item.bind(id, 10))
		row.add_child(plus_ten)
		box.add_child(row)

	box.add_child(HSeparator.new())
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 3)
	hp_label = _make_label("生命 0 / 0", 8)
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_label)
	var full_button := _make_button("满血", 24)
	full_button.pressed.connect(_full_heal)
	hp_row.add_child(full_button)
	var hp_minus := _make_button("-10", 20)
	hp_minus.pressed.connect(_change_hp.bind(-10))
	hp_row.add_child(hp_minus)
	var hp_plus := _make_button("+10", 20)
	hp_plus.pressed.connect(_change_hp.bind(10))
	hp_row.add_child(hp_plus)
	box.add_child(hp_row)


func _make_label(text: String, size: int, color: Color = Color(0.9, 0.86, 0.78)) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String, min_width: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 14)
	button.add_theme_font_override("font", ui_font)
	button.add_theme_font_size_override("font_size", 8)
	return button


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("heal"):
		get_viewport().set_input_as_handled()
		if panel_open:
			close()
		else:
			try_open()
		return
	if panel_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func try_open() -> void:
	if hud != null:
		if bool(hud.get("crafting_open")):
			return
		var death_panel: Control = hud.get("death_panel")
		if death_panel != null and death_panel.visible:
			return
	panel_open = true
	visible = true
	get_tree().paused = true
	_refresh_items()
	_refresh_hp()


func close() -> void:
	if not panel_open:
		return
	panel_open = false
	visible = false
	get_tree().paused = false


func _change_item(id: String, delta: int) -> void:
	var current := int(Global.inventory.get(id, 0))
	var target := current + delta
	if target < 0:
		return
	if id == "mask" or id == "material":
		target = mini(target, 1)
	target = mini(target, Global.item_cap(id))
	if target == current:
		return
	Global.add_item(id, target - current)


func _change_hp(delta: int) -> void:
	if player == null or player.dead:
		return
	player.call("debug_set_health", player.health + delta)


func _full_heal() -> void:
	if player == null or player.dead:
		return
	player.call("debug_set_health", player.max_health)


func _refresh_items() -> void:
	for id in count_labels:
		var label: Label = count_labels[id]
		var count := int(Global.inventory.get(id, 0))
		if Global.ITEM_CAPS.has(id):
			label.text = "%d/%d" % [count, Global.item_cap(id)]
		else:
			label.text = str(count)


func _on_health_changed(_current: int, _maximum: int) -> void:
	_refresh_hp()


func _refresh_hp() -> void:
	if player == null or hp_label == null:
		return
	hp_label.text = "生命 %d / %d" % [player.health, player.max_health]
