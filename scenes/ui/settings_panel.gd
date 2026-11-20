extends Control

signal closed

var _font: SystemFont
var _master_slider: HSlider
var _sfx_slider: HSlider
var _master_value: Label
var _sfx_value: Label
var _fullscreen_check: CheckButton
var _key_labels := {}
var _notice: Label
var _rebind_overlay: Control
var _rebind_action := ""
var _rebind_action_label: Label
var _rebind_conflict: Label
var _capturing := false


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
	_cancel_rebind()
	closed.emit()


func _panel_style(bg: Color, border: Color, radius: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	return s


func _make_label(text: String, size: int, color: Color = Color(0.9, 0.86, 0.78)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 2)
	return l


func _make_button(text: String, size: int = 7) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.6))
	b.add_theme_stylebox_override("normal", _panel_style(Color(0.1, 0.08, 0.06, 0.95), Color(0.45, 0.36, 0.22)))
	b.add_theme_stylebox_override("hover", _panel_style(Color(0.18, 0.13, 0.07, 0.98), Color(0.9, 0.7, 0.35)))
	b.add_theme_stylebox_override("pressed", _panel_style(Color(0.24, 0.17, 0.09, 1.0), Color(1.0, 0.8, 0.4)))
	var focus_style := _panel_style(Color(0, 0, 0, 0), Color(1.0, 0.8, 0.4), 3)
	focus_style.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus_style)
	return b


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
	panel.offset_left = 16.0
	panel.offset_top = 8.0
	panel.offset_right = -16.0
	panel.offset_bottom = -8.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.06, 0.05, 0.98), Color(0.72, 0.58, 0.32)))
	add_child(panel)

	var title := _make_label("设置", 12, Color(1.0, 0.88, 0.55))
	title.position = Vector2(14, 8)
	panel.add_child(title)

	# 音量
	var vol_title := _make_label("音量", 8, Color(1.0, 0.82, 0.5))
	vol_title.position = Vector2(14, 30)
	panel.add_child(vol_title)

	var master_label := _make_label("总音量", 7)
	master_label.position = Vector2(14, 46)
	panel.add_child(master_label)
	_master_slider = HSlider.new()
	_master_slider.min_value = 0
	_master_slider.max_value = 100
	_master_slider.step = 1
	_master_slider.position = Vector2(66, 46)
	_master_slider.custom_minimum_size = Vector2(110, 10)
	_master_slider.size = Vector2(110, 10)
	panel.add_child(_master_slider)
	_master_value = _make_label("100%", 7)
	_master_value.position = Vector2(180, 46)
	panel.add_child(_master_value)
	_master_slider.value_changed.connect(_on_master_changed)

	var sfx_label := _make_label("音效音量", 7)
	sfx_label.position = Vector2(14, 64)
	panel.add_child(sfx_label)
	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0
	_sfx_slider.max_value = 100
	_sfx_slider.step = 1
	_sfx_slider.position = Vector2(66, 64)
	_sfx_slider.custom_minimum_size = Vector2(110, 10)
	_sfx_slider.size = Vector2(110, 10)
	panel.add_child(_sfx_slider)
	_sfx_value = _make_label("100%", 7)
	_sfx_value.position = Vector2(180, 64)
	panel.add_child(_sfx_value)
	_sfx_slider.value_changed.connect(_on_sfx_changed)

	# 显示
	var display_title := _make_label("显示", 8, Color(1.0, 0.82, 0.5))
	display_title.position = Vector2(14, 92)
	panel.add_child(display_title)
	var fullscreen_label := _make_label("全屏", 7)
	fullscreen_label.position = Vector2(14, 110)
	panel.add_child(fullscreen_label)
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.position = Vector2(58, 104)
	_fullscreen_check.custom_minimum_size = Vector2(40, 18)
	panel.add_child(_fullscreen_check)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# 按键
	var key_title := _make_label("按键", 8, Color(1.0, 0.82, 0.5))
	key_title.position = Vector2(232, 30)
	panel.add_child(key_title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(228, 46)
	scroll.size = Vector2(210, 158)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.custom_minimum_size = Vector2(206, 0)
	scroll.add_child(list)

	for entry in Settings.ACTIONS:
		var action := str(entry["action"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.custom_minimum_size = Vector2(206, 12)

		var name_label := _make_label(str(entry["label"]), 6)
		name_label.custom_minimum_size = Vector2(74, 12)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var key_label := _make_label(Settings.binding_text(action), 6, Color(1.0, 0.9, 0.6))
		key_label.custom_minimum_size = Vector2(56, 12)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(key_label)
		_key_labels[action] = key_label

		var edit := _make_button("修改", 6)
		edit.custom_minimum_size = Vector2(28, 12)
		edit.pressed.connect(_start_rebind.bind(action))
		row.add_child(edit)

		list.add_child(row)

	# 底部
	var back := _make_button("返回", 7)
	back.position = Vector2(14, 214)
	back.custom_minimum_size = Vector2(44, 16)
	back.size = Vector2(44, 16)
	back.pressed.connect(close)
	panel.add_child(back)

	_notice = _make_label("", 5, Color(1.0, 0.78, 0.4))
	_notice.position = Vector2(64, 218)
	panel.add_child(_notice)

	# 改键弹窗
	_rebind_overlay = Control.new()
	_rebind_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebind_overlay.visible = false
	add_child(_rebind_overlay)

	var rdim := ColorRect.new()
	rdim.color = Color(0, 0, 0, 0.62)
	rdim.mouse_filter = Control.MOUSE_FILTER_STOP
	rdim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebind_overlay.add_child(rdim)

	var rpanel := Panel.new()
	rpanel.anchor_left = 0.5
	rpanel.anchor_right = 0.5
	rpanel.anchor_top = 0.5
	rpanel.anchor_bottom = 0.5
	rpanel.offset_left = -110.0
	rpanel.offset_top = -55.0
	rpanel.offset_right = 110.0
	rpanel.offset_bottom = 55.0
	rpanel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.06, 0.05, 1.0), Color(0.9, 0.7, 0.35)))
	_rebind_overlay.add_child(rpanel)

	var rtitle := _make_label("修改按键", 10, Color(1.0, 0.88, 0.55))
	rtitle.position = Vector2(12, 8)
	rpanel.add_child(rtitle)

	_rebind_action_label = _make_label("动作：", 7)
	_rebind_action_label.position = Vector2(12, 28)
	rpanel.add_child(_rebind_action_label)

	var prompt := _make_label("请按下新的按键…", 9, Color(1.0, 0.9, 0.6))
	prompt.position = Vector2(12, 48)
	rpanel.add_child(prompt)

	var hint := _make_label("Esc 取消 · 按键冲突会替换原按键", 5, Color(0.65, 0.6, 0.52))
	hint.position = Vector2(12, 76)
	rpanel.add_child(hint)

	_rebind_conflict = _make_label("", 5, Color(1.0, 0.7, 0.35))
	_rebind_conflict.position = Vector2(12, 88)
	rpanel.add_child(_rebind_conflict)


func _refresh() -> void:
	_master_slider.set_value_no_signal(Settings.master_volume * 100.0)
	_sfx_slider.set_value_no_signal(Settings.sfx_volume * 100.0)
	_master_value.text = "%d%%" % int(Settings.master_volume * 100.0)
	_sfx_value.text = "%d%%" % int(Settings.sfx_volume * 100.0)
	_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	for action in _key_labels:
		_key_labels[action].text = Settings.binding_text(action)
	_notice.text = ""


func _on_master_changed(value: float) -> void:
	Settings.set_master_volume(value / 100.0)
	_master_value.text = "%d%%" % int(value)


func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value / 100.0)
	_sfx_value.text = "%d%%" % int(value)


func _on_fullscreen_toggled(on: bool) -> void:
	Settings.set_fullscreen(on)


func _start_rebind(action: String) -> void:
	_rebind_action = action
	_capturing = true
	_rebind_action_label.text = "动作：" + Settings.label_for(action)
	_rebind_conflict.text = "当前按键：" + Settings.binding_text(action)
	_rebind_overlay.visible = true


func _cancel_rebind() -> void:
	_rebind_action = ""
	_capturing = false
	if _rebind_overlay != null:
		_rebind_overlay.visible = false


func _input(event: InputEvent) -> void:
	if not visible or not _capturing:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			get_viewport().set_input_as_handled()
			if key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_ESCAPE:
				_cancel_rebind()
			else:
				_apply_binding(key)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			get_viewport().set_input_as_handled()
			_apply_binding(mouse)


func _apply_binding(event: InputEvent) -> void:
	if _rebind_action.is_empty():
		return
	var conflict := Settings.find_conflict(_rebind_action, event)
	if conflict != "":
		Settings.remove_event(conflict, event)
		_rebind_conflict.text = "已从“%s”移除该按键" % Settings.label_for(conflict)
		if _key_labels.has(conflict):
			_key_labels[conflict].text = Settings.binding_text(conflict)
	Settings.rebind(_rebind_action, event)
	if _key_labels.has(_rebind_action):
		_key_labels[_rebind_action].text = Settings.binding_text(_rebind_action)
	_rebind_overlay.visible = false
	_capturing = false
	_rebind_action = ""
	_notice.text = "按键已保存"


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _capturing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
