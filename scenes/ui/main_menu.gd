extends Control

const SETTINGS_PANEL := preload("res://scenes/ui/settings_panel.tscn")
const CONTROLS_PANEL := preload("res://scenes/ui/controls_panel.tscn")
const BG_TEXTURE: Texture2D = preload("res://graphics/ui/menu_bg.png")

var _font: SystemFont
var _menu_box: VBoxContainer
var _menu_buttons: Array[Button] = []
var _continue_button: Button
var _save_info: Label
var _settings_panel: Control
var _controls_panel: Control
var _confirm: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	_build()
	_refresh()


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
	b.add_theme_color_override("font_disabled_color", Color(0.42, 0.39, 0.35))
	b.add_theme_stylebox_override("normal", _style(Color(0.1, 0.08, 0.06, 0.9), Color(0.45, 0.36, 0.22)))
	b.add_theme_stylebox_override("hover", _style(Color(0.18, 0.13, 0.07, 0.95), Color(0.9, 0.7, 0.35)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.24, 0.17, 0.09, 1.0), Color(1.0, 0.8, 0.4)))
	b.add_theme_stylebox_override("disabled", _style(Color(0.07, 0.06, 0.05, 0.7), Color(0.22, 0.2, 0.17)))
	b.custom_minimum_size = Vector2(0, 26)
	var focus_style := _style(Color(0, 0, 0, 0), Color(1.0, 0.8, 0.4), 2)
	focus_style.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus_style)
	return b


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = BG_TEXTURE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var title := _label("勇者之旅", 22, Color(1.0, 0.86, 0.5))
	title.position = Vector2(20, 12)
	title.add_theme_constant_override("outline_size", 4)
	add_child(title)

	var panel := Panel.new()
	panel.position = Vector2(20, 58)
	panel.size = Vector2(206, 176)
	panel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.06, 0.05, 0.88), Color(0.72, 0.58, 0.32)))
	add_child(panel)

	_menu_box = VBoxContainer.new()
	_menu_box.position = Vector2(10, 10)
	_menu_box.size = Vector2(186, 156)
	_menu_box.add_theme_constant_override("separation", 4)
	panel.add_child(_menu_box)

	_continue_button = _button("继续游戏")
	_continue_button.pressed.connect(_on_continue)
	_menu_box.add_child(_continue_button)
	_menu_buttons.append(_continue_button)

	_save_info = _label("暂无存档", 5, Color(0.62, 0.58, 0.5))
	_save_info.custom_minimum_size = Vector2(0, 8)
	_menu_box.add_child(_save_info)

	var new_game := _button("新游戏")
	new_game.pressed.connect(_on_new_game)
	_menu_box.add_child(new_game)
	_menu_buttons.append(new_game)

	var controls := _button("操作说明")
	controls.pressed.connect(_open_controls)
	_menu_box.add_child(controls)
	_menu_buttons.append(controls)

	var settings := _button("设置")
	settings.pressed.connect(_open_settings)
	_menu_box.add_child(settings)
	_menu_buttons.append(settings)

	var quit := _button("退出游戏")
	quit.pressed.connect(_on_quit)
	_menu_box.add_child(quit)
	_menu_buttons.append(quit)

	# 新游戏确认
	_confirm = Control.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.visible = false
	add_child(_confirm)

	var cdim := ColorRect.new()
	cdim.color = Color(0, 0, 0, 0.66)
	cdim.mouse_filter = Control.MOUSE_FILTER_STOP
	cdim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(cdim)

	var cpanel := Panel.new()
	cpanel.anchor_left = 0.5
	cpanel.anchor_right = 0.5
	cpanel.anchor_top = 0.5
	cpanel.anchor_bottom = 0.5
	cpanel.offset_left = -130.0
	cpanel.offset_top = -58.0
	cpanel.offset_right = 130.0
	cpanel.offset_bottom = 58.0
	cpanel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.06, 0.05, 1.0), Color(0.72, 0.58, 0.32)))
	_confirm.add_child(cpanel)

	var ctitle := _label("开始新游戏？", 10, Color(1.0, 0.86, 0.5))
	ctitle.position = Vector2(14, 10)
	cpanel.add_child(ctitle)

	var cbody := _label("这会覆盖上一次的存档进度，无法恢复。", 6, Color(0.85, 0.8, 0.72))
	cbody.position = Vector2(14, 34)
	cpanel.add_child(cbody)

	var cyes := _button("确定", 7)
	cyes.position = Vector2(30, 78)
	cyes.size = Vector2(80, 24)
	cyes.custom_minimum_size = Vector2(80, 24)
	cyes.pressed.connect(_start_new_game)
	cpanel.add_child(cyes)

	var cno := _button("取消", 7)
	cno.position = Vector2(140, 78)
	cno.size = Vector2(80, 24)
	cno.custom_minimum_size = Vector2(80, 24)
	cno.pressed.connect(func() -> void: _confirm.visible = false)
	cpanel.add_child(cno)

	# 子面板
	_settings_panel = SETTINGS_PANEL.instantiate()
	add_child(_settings_panel)
	_settings_panel.visible = false
	_settings_panel.closed.connect(_on_overlay_closed)

	_controls_panel = CONTROLS_PANEL.instantiate()
	add_child(_controls_panel)
	_controls_panel.visible = false
	_controls_panel.closed.connect(_on_overlay_closed)


func _refresh() -> void:
	var has_save := SaveGame.has_save()
	var outdated := has_save and SaveGame.is_outdated()
	_continue_button.disabled = not has_save or outdated
	if has_save:
		var info := SaveGame.get_save_info()
		var location := str(info.get("location", "未知"))
		var stamp := str(info.get("timestamp", ""))
		var time_text := stamp.substr(11, 5) if stamp.length() >= 16 else stamp
		if outdated:
			_save_info.text = "该存档属于已废弃剧情"
			_save_info.add_theme_color_override("font_color", Color(0.88, 0.48, 0.34))
		else:
			_save_info.text = "存档：%s · %s" % [location, time_text]
			_save_info.add_theme_color_override("font_color", Color(0.72, 0.67, 0.55))
	else:
		_save_info.text = "暂无存档"
		_save_info.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))
	if has_save:
		_continue_button.grab_focus()
	else:
		_menu_buttons[1].grab_focus()


func _on_continue() -> void:
	if not SaveGame.has_save():
		return
	if SaveGame.load_into_global():
		var scene_path := SaveGame.pending_scene_path
		if scene_path.is_empty():
			scene_path = "res://scenes/prologue/player_house.tscn"
		get_tree().change_scene_to_file(scene_path)


func _on_new_game() -> void:
	if SaveGame.has_save():
		_confirm.visible = true
	else:
		_start_new_game()


func _start_new_game() -> void:
	SaveGame.delete_save()
	Global.reset_state()
	SaveGame.pending_player_data = {}
	Global.prologue_started = true
	get_tree().change_scene_to_file("res://scenes/prologue/player_house.tscn")


func _open_settings() -> void:
	_set_menu_enabled(false)
	_settings_panel.call("open")


func _open_controls() -> void:
	_set_menu_enabled(false)
	_controls_panel.call("open")


func _on_overlay_closed() -> void:
	_set_menu_enabled(true)


func _set_menu_enabled(enabled: bool) -> void:
	for b in _menu_buttons:
		b.disabled = not enabled
		b.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if enabled:
		_refresh()


func _on_quit() -> void:
	Global.quit_game()
