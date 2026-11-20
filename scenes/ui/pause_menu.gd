extends CanvasLayer

const SETTINGS_PANEL := preload("res://scenes/ui/settings_panel.tscn")
const CONTROLS_PANEL := preload("res://scenes/ui/controls_panel.tscn")

var _root: Control
var _font: SystemFont
var _buttons: Array[Button] = []
var _info_label: Label
var _settings_panel: Control
var _controls_panel: Control


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	_build()
	_root.visible = false


func _style(bg: Color, border: Color, radius: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	return s


func _label(text: String, size: int, color: Color = Color(0.9, 0.86, 0.78)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, size: int = 8) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.6))
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
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -100.0
	panel.offset_top = -95.0
	panel.offset_right = 100.0
	panel.offset_bottom = 95.0
	panel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.06, 0.05, 0.98), Color(0.72, 0.58, 0.32)))
	_root.add_child(panel)

	var title := _label("游戏暂停", 11, Color(1.0, 0.86, 0.5))
	title.position = Vector2(14, 10)
	panel.add_child(title)

	var labels := ["继续游戏", "保存并返回主菜单", "操作说明", "设置", "退出游戏"]
	var calls: Array[Callable] = [
		Callable(self, "close"),
		Callable(self, "_save_and_menu"),
		Callable(self, "_open_controls"),
		Callable(self, "_open_settings"),
		Callable(self, "_on_quit"),
	]
	var y := 36
	for i in labels.size():
		var b := _button(str(labels[i]), 7)
		b.position = Vector2(14, y)
		b.size = Vector2(172, 24)
		b.custom_minimum_size = Vector2(172, 24)
		b.pressed.connect(calls[i])
		panel.add_child(b)
		_buttons.append(b)
		y += 28

	_info_label = _label("当前存档：营地", 5, Color(0.6, 0.56, 0.48))
	_info_label.position = Vector2(14, 174)
	panel.add_child(_info_label)

	_settings_panel = SETTINGS_PANEL.instantiate()
	add_child(_settings_panel)
	_settings_panel.visible = false
	_settings_panel.closed.connect(_restore_focus)

	_controls_panel = CONTROLS_PANEL.instantiate()
	add_child(_controls_panel)
	_controls_panel.visible = false
	_controls_panel.closed.connect(_restore_focus)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _settings_panel != null and _settings_panel.visible:
		return
	if _controls_panel != null and _controls_panel.visible:
		return
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud != null and _hud_blocks_pause(hud):
		return
	var victory = get_tree().get_first_node_in_group("VictoryScreen")
	if victory != null and victory.has_method("is_open") and bool(victory.call("is_open")):
		return
	get_viewport().set_input_as_handled()
	if _root.visible:
		close()
	else:
		open()


func _hud_blocks_pause(hud: Node) -> bool:
	for property_name in [
		"crafting_open",
		"character_open",
		"dialog_active",
		"select_active",
		"test_menu_open",
		"death_open",
	]:
		if hud.get(property_name) == true:
			return true
	var death_panel := hud.get("death_panel") as Control
	return death_panel != null and death_panel.visible


func open() -> void:
	if _root.visible:
		return
	_root.visible = true
	get_tree().paused = true
	var info := SaveGame.get_save_info()
	if not info.is_empty():
		_info_label.text = "当前存档：%s" % str(info.get("location", "未知"))
	for b in _buttons:
		b.focus_mode = Control.FOCUS_ALL
	_buttons[0].grab_focus()


func close() -> void:
	_root.visible = false
	get_tree().paused = false


func _save_and_menu() -> void:
	SaveGame.save_game("手动保存")
	close()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _restore_focus() -> void:
	for b in _buttons:
		b.focus_mode = Control.FOCUS_ALL
	if _buttons.size() > 0:
		_buttons[0].grab_focus()


func _open_settings() -> void:
	for b in _buttons:
		b.focus_mode = Control.FOCUS_NONE
	_settings_panel.call("open")


func _open_controls() -> void:
	for b in _buttons:
		b.focus_mode = Control.FOCUS_NONE
	_controls_panel.call("open")


func _on_quit() -> void:
	Global.quit_game()
