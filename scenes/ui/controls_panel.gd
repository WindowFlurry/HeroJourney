extends Control

signal closed

var _font: SystemFont


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	_build()


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false
	closed.emit()


func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	return s


func _label(text: String, size: int, color: Color = Color(0.9, 0.86, 0.78)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 7)
	b.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.6))
	b.add_theme_stylebox_override("normal", _style(Color(0.1, 0.08, 0.06, 0.95), Color(0.45, 0.36, 0.22)))
	b.add_theme_stylebox_override("hover", _style(Color(0.18, 0.13, 0.07, 0.98), Color(0.9, 0.7, 0.35)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.24, 0.17, 0.09, 1.0), Color(1.0, 0.8, 0.4)))
	var focus_style := _style(Color(0, 0, 0, 0), Color(1.0, 0.8, 0.4))
	focus_style.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus_style)
	return b


var _lines_box: VBoxContainer


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := Panel.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 36.0
	panel.offset_top = 18.0
	panel.offset_right = -36.0
	panel.offset_bottom = -18.0
	panel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.06, 0.05, 0.98), Color(0.72, 0.58, 0.32)))
	add_child(panel)

	var title := _label("操作说明", 11, Color(1.0, 0.88, 0.55))
	title.position = Vector2(14, 10)
	panel.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 34)
	scroll.size = Vector2(365, 170)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	_lines_box = VBoxContainer.new()
	_lines_box.add_theme_constant_override("separation", 4)
	_lines_box.custom_minimum_size = Vector2(360, 0)
	scroll.add_child(_lines_box)

	var back := _button("返回")
	back.position = Vector2(14, 210)
	back.custom_minimum_size = Vector2(44, 16)
	back.size = Vector2(44, 16)
	back.pressed.connect(close)
	panel.add_child(back)


func _refresh() -> void:
	for child in _lines_box.get_children():
		child.queue_free()
	var entries := [
		["移动", ["left", "right", "up", "down"]],
		["攻击", ["action"]],
		["疾跑", ["run"]],
		["职业技能", ["dash"]],
		["武器特技", ["weapon_skill"]],
		["角色 / 背包", ["character_menu"]],
		["交互 / 拾取", ["interact"]],
		["使用草药", ["use_herb"]],
		["打开制作", ["craft"]],
		["物品栏", ["weapon_1", "weapon_2", "weapon_3", "weapon_4"]],
		["暂停", ["pause"]],
	]
	for entry in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := _label(str(entry[0]), 7)
		name_label.custom_minimum_size = Vector2(90, 14)
		row.add_child(name_label)
		var parts: Array[String] = []
		for action in entry[1]:
			parts.append(Settings.binding_text(str(action)))
		var key_label := _label(" / ".join(parts), 7, Color(1.0, 0.9, 0.6))
		row.add_child(key_label)
		_lines_box.add_child(row)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
