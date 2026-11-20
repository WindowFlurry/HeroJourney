extends CanvasLayer

var _root: Control
var _panel: Panel
var _buttons: Array[Button] = []
var _font: SystemFont


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("VictoryScreen")
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	_build()
	_root.visible = false


func is_open() -> bool:
	return _root != null and _root.visible


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
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, size: int = 7) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.6))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.9, 0.6))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.82, 0.45))
	b.add_theme_stylebox_override("normal", _style(Color(0.1, 0.08, 0.06, 0.9), Color(0.45, 0.36, 0.22)))
	b.add_theme_stylebox_override("hover", _style(Color(0.18, 0.13, 0.07, 0.95), Color(0.9, 0.7, 0.35)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.24, 0.17, 0.09, 1.0), Color(1.0, 0.8, 0.4)))
	var focus_style := _style(Color(0, 0, 0, 0), Color(1.0, 0.8, 0.4), 3)
	focus_style.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus_style)
	return b


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	_panel = Panel.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -100.0
	_panel.offset_top = -80.0
	_panel.offset_right = 100.0
	_panel.offset_bottom = 80.0
	_panel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.06, 0.05, 0.97), Color(0.72, 0.58, 0.32)))
	_root.add_child(_panel)

	var inner := Panel.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 2.0
	inner.offset_top = 2.0
	inner.offset_right = -2.0
	inner.offset_bottom = -2.0
	inner.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), Color(0.35, 0.29, 0.18, 0.4)))
	_panel.add_child(inner)

	var title := _label("第一关完成", 16, Color(1.0, 0.86, 0.5))
	title.position = Vector2(0, 28)
	title.size = Vector2(200, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 3)
	_panel.add_child(title)

	var line_color := Color(0.59, 0.47, 0.27, 0.85)
	var line_l := ColorRect.new()
	line_l.color = line_color
	line_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_l.position = Vector2(40, 57)
	line_l.size = Vector2(54, 1)
	_panel.add_child(line_l)
	var line_r := ColorRect.new()
	line_r.color = line_color
	line_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_r.position = Vector2(106, 57)
	line_r.size = Vector2(54, 1)
	_panel.add_child(line_r)
	var gem := _label("◆", 7, Color(0.82, 0.66, 0.36))
	gem.position = Vector2(94, 49)
	gem.size = Vector2(12, 14)
	gem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_panel.add_child(gem)

	var labels := ["继续探索", "返回主界面"]
	var calls: Array[Callable] = [Callable(self, "_continue_exploring"), Callable(self, "_back_to_menu")]
	var y := 62.0
	for i in labels.size():
		var b := _button(str(labels[i]), 7)
		b.position = Vector2(14, y)
		b.size = Vector2(172, 24)
		b.custom_minimum_size = Vector2(172, 24)
		b.pressed.connect(calls[i])
		_panel.add_child(b)
		_buttons.append(b)
		y += 29.0

	var hint := _label("↑↓ 选择 · Enter 确认 · 鼠标点击", 5, Color(0.59, 0.55, 0.48))
	hint.position = Vector2(0, 122)
	hint.size = Vector2(200, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_constant_override("outline_size", 1)
	_panel.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_continue_exploring()


func show_victory() -> void:
	if _root == null or _root.visible:
		return
	_root.visible = true
	_root.modulate.a = 0.0
	get_tree().paused = true
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 1.0, 0.3)
	await get_tree().process_frame
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func _continue_exploring() -> void:
	if not is_open():
		return
	_root.visible = false
	get_tree().paused = false


func _back_to_menu() -> void:
	SaveGame.save_game("白桦林地")
	_root.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
