extends CanvasLayer

signal dialog_finished
signal profession_selected(profession: String)
signal revive_requested

const PROFESSION_CARDS := [
	{
		"id": "warrior",
		"name": "战士",
		"tag": "推荐新手",
		"color": Color(0.96, 0.62, 0.3),
		"body": "近战 / 承伤 / 击退\n生命 120  防御 3\n旧铁长剑\nZ：破阵冲锋\n右键：横斩",
	},
	{
		"id": "ranger",
		"name": "游侠",
		"tag": "机动",
		"color": Color(0.56, 0.88, 0.44),
		"body": "中距 / 机动 / 持续输出\n生命 95  防御 2\n猎弓\nZ：翻滚\n右键：三连射",
	},
	{
		"id": "mage",
		"name": "法师",
		"tag": "爆发",
		"color": Color(0.55, 0.72, 1.0),
		"body": "远程 / 爆发 / 位移\n生命 85  防御 1\n见习法杖\nZ：闪现\n右键：蓄力火球",
	},
]
const CHARACTER_UI_SCENE: PackedScene = preload("res://scenes/prologue/character_ui.tscn")
const HOTBAR_SLOT_SCRIPT: Script = preload("res://scenes/prologue/hotbar_slot.gd")

var player
var ui_font: SystemFont
var root: Control
var health_bar: ProgressBar
var health_text: Label
var profession_label: Label
var objective_panel: Panel
var objective_label: Label
var interaction_label: Label
var tutorial_panel: Panel
var tutorial_label: Label
var notice_panel: Panel
var notice_label: Label
var quick_panel: Panel
var quick_slots: Array[Panel] = []
var quick_labels: Array[Label] = []
var quick_keys: Array[Label] = []
var skill_panel: Panel
var skill_name_label: Label
var skill_key_label: Label
var skill_fill: ColorRect
var boss_panel: Panel
var boss_bar: ProgressBar
var boss_name_label: Label
var dialog_panel: Panel
var dialog_title: Label
var dialog_body: Label
var dialog_button: Button
var select_overlay: Control
var select_cards: HBoxContainer
var select_confirm: Button
var selected_profession := ""
var allow_profession_cancel := false
var character_ui: Control
var death_overlay: Control
var banner_label: Label
var banner_subtitle: Label
var dialog_active := false
var select_active := false
var character_open := false
var death_open := false
var _notice_generation := 0
var _refresh_clock := 0.0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("HUD")
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	_build()
	player = get_tree().get_first_node_in_group("Player")
	if player != null:
		player.health_changed.connect(_on_health_changed)
		player.died.connect(_on_player_died)
		_on_health_changed(player.health, player.max_health)


func _process(delta: float) -> void:
	_refresh_clock -= delta
	if _refresh_clock > 0.0:
		return
	_refresh_clock = 0.12
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	_refresh_skill()
	refresh_quick_slots()
	if profession_label != null:
		profession_label.text = str(player.call("get_profession_name"))


func _style(bg: Color, border: Color, radius: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _label(text: String, size: int, color: Color = Color(0.94, 0.9, 0.82)) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.035, 0.02, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, size: int = 7) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", ui_font)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color(0.96, 0.9, 0.76))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.82, 0.38))
	button.add_theme_stylebox_override("normal", _style(Color(0.09, 0.07, 0.045, 0.98), Color(0.55, 0.42, 0.23)))
	button.add_theme_stylebox_override("hover", _style(Color(0.18, 0.12, 0.055, 1.0), Color(1.0, 0.72, 0.28)))
	button.add_theme_stylebox_override("pressed", _style(Color(0.26, 0.16, 0.06, 1.0), Color(1.0, 0.8, 0.34)))
	return button


func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_health()
	_build_objective()
	_build_prompts()
	_build_quickbar()
	_build_skill()
	_build_boss()
	_build_banner()
	_build_dialog()
	_build_profession_select()
	_build_character()
	_build_death()


func _build_health() -> void:
	var panel := Panel.new()
	panel.position = Vector2(10, 232)
	panel.size = Vector2(118, 27)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color(0.045, 0.035, 0.025, 0.9), Color(0.62, 0.46, 0.22)))
	root.add_child(panel)

	profession_label = _label("见习冒险者", 6, Color(1.0, 0.82, 0.45))
	profession_label.position = Vector2(5, 1)
	profession_label.size = Vector2(108, 9)
	panel.add_child(profession_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(5, 12)
	health_bar.size = Vector2(108, 8)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", _style(Color(0.16, 0.045, 0.03, 1.0), Color(0.38, 0.12, 0.07), 2))
	health_bar.add_theme_stylebox_override("fill", _style(Color(0.72, 0.12, 0.06, 1.0), Color(0.95, 0.36, 0.2), 2))
	panel.add_child(health_bar)

	health_text = _label("", 6, Color(1.0, 0.93, 0.82))
	health_text.position = Vector2(5, 11)
	health_text.size = Vector2(108, 9)
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(health_text)


func _build_objective() -> void:
	objective_panel = Panel.new()
	objective_panel.position = Vector2(92, 6)
	objective_panel.size = Vector2(296, 23)
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.035, 0.03, 0.78), Color(0.73, 0.55, 0.24, 0.68)))
	root.add_child(objective_panel)
	objective_label = _label("序章 · 灰杉村的黎明", 7, Color(1.0, 0.9, 0.64))
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_panel.add_child(objective_label)


func _build_prompts() -> void:
	interaction_label = _label("", 7, Color(1.0, 0.9, 0.62))
	interaction_label.position = Vector2(80, 211)
	interaction_label.size = Vector2(320, 12)
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.visible = false
	root.add_child(interaction_label)

	tutorial_panel = Panel.new()
	tutorial_panel.position = Vector2(74, 218)
	tutorial_panel.size = Vector2(332, 16)
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.03, 0.025, 0.92), Color(0.72, 0.56, 0.3, 0.72)))
	tutorial_panel.visible = false
	root.add_child(tutorial_panel)
	tutorial_label = _label("", 6, Color(0.96, 0.9, 0.74))
	tutorial_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_panel.add_child(tutorial_label)

	notice_panel = Panel.new()
	notice_panel.position = Vector2(110, 51)
	notice_panel.size = Vector2(260, 20)
	notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_panel.add_theme_stylebox_override("panel", _style(Color(0.035, 0.025, 0.02, 0.94), Color(0.82, 0.58, 0.24, 0.8)))
	notice_panel.visible = false
	root.add_child(notice_panel)
	notice_label = _label("", 7, Color(1.0, 0.87, 0.55))
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_panel.add_child(notice_label)


func _build_quickbar() -> void:
	quick_panel = Panel.new()
	quick_panel.position = Vector2(185, 232)
	quick_panel.size = Vector2(110, 27)
	quick_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quick_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.03, 0.025, 0.88), Color(0.55, 0.43, 0.26)))
	root.add_child(quick_panel)

	var row := HBoxContainer.new()
	row.position = Vector2(4, 3)
	row.size = Vector2(102, 21)
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quick_panel.add_child(row)
	for i in Global.HOTBAR_SIZE:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(23, 21)
		slot.set_script(HOTBAR_SLOT_SCRIPT)
		slot.call("setup", i)
		slot.connect("item_dropped", _on_hotbar_drop)
		slot.add_theme_stylebox_override("panel", _style(Color(0.08, 0.06, 0.04, 0.9), Color(0.32, 0.25, 0.16), 2))
		row.add_child(slot)
		var text := _label("", 5, Color(0.94, 0.88, 0.75))
		text.position = Vector2(1, 3)
		text.size = Vector2(21, 14)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(text)
		var key := _label("", 4, Color(1.0, 0.82, 0.46))
		key.position = Vector2(1, 0)
		key.size = Vector2(20, 7)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		slot.add_child(key)
		quick_slots.append(slot)
		quick_labels.append(text)
		quick_keys.append(key)


func _build_skill() -> void:
	skill_panel = Panel.new()
	skill_panel.position = Vector2(385, 229)
	skill_panel.size = Vector2(84, 31)
	skill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.03, 0.025, 0.9), Color(0.58, 0.45, 0.25)))
	root.add_child(skill_panel)
	skill_name_label = _label("职业技能", 6, Color(1.0, 0.88, 0.6))
	skill_name_label.position = Vector2(4, 2)
	skill_name_label.size = Vector2(76, 10)
	skill_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_panel.add_child(skill_name_label)
	skill_key_label = _label("", 5, Color(0.88, 0.8, 0.65))
	skill_key_label.position = Vector2(4, 12)
	skill_key_label.size = Vector2(76, 8)
	skill_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_panel.add_child(skill_key_label)
	skill_fill = ColorRect.new()
	skill_fill.color = Color(0.78, 0.46, 0.16, 0.92)
	skill_fill.position = Vector2(3, 29)
	skill_fill.size = Vector2(78, 1.5)
	skill_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_panel.add_child(skill_fill)


func _build_boss() -> void:
	boss_panel = Panel.new()
	boss_panel.position = Vector2(90, 33)
	boss_panel.size = Vector2(300, 26)
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_theme_stylebox_override("panel", _style(Color(0.045, 0.025, 0.02, 0.94), Color(0.8, 0.3, 0.14)))
	boss_panel.visible = false
	root.add_child(boss_panel)
	boss_name_label = _label("裂翼兽", 7, Color(1.0, 0.68, 0.4))
	boss_name_label.position = Vector2(4, 1)
	boss_name_label.size = Vector2(292, 10)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_panel.add_child(boss_name_label)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(6, 14)
	boss_bar.size = Vector2(288, 8)
	boss_bar.show_percentage = false
	boss_bar.add_theme_stylebox_override("background", _style(Color(0.15, 0.035, 0.02, 1.0), Color(0.35, 0.09, 0.04), 2))
	boss_bar.add_theme_stylebox_override("fill", _style(Color(0.76, 0.12, 0.045, 1.0), Color(1.0, 0.36, 0.12), 2))
	boss_panel.add_child(boss_bar)


func _build_banner() -> void:
	banner_label = _label("", 20, Color(1.0, 0.76, 0.4))
	banner_label.position = Vector2(40, 92)
	banner_label.size = Vector2(400, 35)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.visible = false
	root.add_child(banner_label)
	banner_subtitle = _label("", 8, Color(0.96, 0.88, 0.72))
	banner_subtitle.position = Vector2(60, 128)
	banner_subtitle.size = Vector2(360, 18)
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_subtitle.visible = false
	root.add_child(banner_subtitle)


func _build_dialog() -> void:
	dialog_panel = Panel.new()
	dialog_panel.position = Vector2(80, 176)
	dialog_panel.size = Vector2(320, 43)
	dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_panel.add_theme_stylebox_override("panel", _style(Color(0.035, 0.028, 0.022, 0.98), Color(0.72, 0.53, 0.25), 3))
	dialog_panel.visible = false
	root.add_child(dialog_panel)
	dialog_title = _label("", 7, Color(1.0, 0.76, 0.36))
	dialog_title.position = Vector2(8, 4)
	dialog_title.size = Vector2(304, 10)
	dialog_panel.add_child(dialog_title)
	dialog_body = _label("", 6, Color(0.94, 0.9, 0.82))
	dialog_body.position = Vector2(8, 15)
	dialog_body.size = Vector2(304, 18)
	dialog_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_panel.add_child(dialog_body)
	dialog_button = _button("继续", 6)
	dialog_button.position = Vector2(273, 31)
	dialog_button.size = Vector2(42, 12)
	dialog_button.custom_minimum_size = Vector2(42, 12)
	dialog_button.pressed.connect(close_dialog)
	dialog_panel.add_child(dialog_button)


func _build_profession_select() -> void:
	select_overlay = Control.new()
	select_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	select_overlay.visible = false
	root.add_child(select_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.012, 0.01, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_overlay.add_child(dim)
	var title := _label("选择你的职业", 15, Color(1.0, 0.82, 0.46))
	title.position = Vector2(35, 24)
	title.size = Vector2(410, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_overlay.add_child(title)
	var subtitle := _label("职业决定初始生命、防御、武器与战斗方式", 7, Color(0.78, 0.72, 0.62))
	subtitle.position = Vector2(35, 48)
	subtitle.size = Vector2(410, 12)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_overlay.add_child(subtitle)
	select_cards = HBoxContainer.new()
	select_cards.position = Vector2(31, 70)
	select_cards.size = Vector2(418, 132)
	select_cards.add_theme_constant_override("separation", 9)
	select_overlay.add_child(select_cards)
	for card_data in PROFESSION_CARDS:
		var card := Panel.new()
		card.custom_minimum_size = Vector2(133, 128)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_gui_input.bind(str(card_data["id"])))
		select_cards.add_child(card)
		var name_label := _label(str(card_data["name"]), 10, card_data["color"])
		name_label.position = Vector2(6, 5)
		name_label.size = Vector2(120, 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(name_label)
		var tag := _label(str(card_data["tag"]), 5, Color(0.2, 0.12, 0.04))
		tag.position = Vector2(43, 20)
		tag.size = Vector2(48, 9)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(tag)
		var body := _label(str(card_data["body"]), 6, Color(0.9, 0.86, 0.77))
		body.position = Vector2(8, 34)
		body.size = Vector2(117, 86)
		body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(body)
		card.set_meta("base_color", card_data["color"])
		_refresh_card_style(card, false)
	select_confirm = _button("确认职业", 8)
	select_confirm.position = Vector2(183, 215)
	select_confirm.size = Vector2(114, 23)
	select_confirm.custom_minimum_size = Vector2(114, 23)
	select_confirm.pressed.connect(_confirm_profession)
	select_overlay.add_child(select_confirm)
	var cancel := _button("暂不选择", 7)
	cancel.name = "Cancel"
	cancel.position = Vector2(183, 244)
	cancel.size = Vector2(114, 18)
	cancel.custom_minimum_size = Vector2(114, 18)
	cancel.pressed.connect(_cancel_profession)
	select_overlay.add_child(cancel)


func _build_character() -> void:
	character_ui = CHARACTER_UI_SCENE.instantiate()
	root.add_child(character_ui)
	character_ui.closed.connect(_on_character_closed)


func _build_death() -> void:
	death_overlay = Control.new()
	death_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	death_overlay.visible = false
	root.add_child(death_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.008, 0.006, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_overlay.add_child(dim)
	var title := _label("你倒下了", 20, Color(0.9, 0.28, 0.18))
	title.position = Vector2(90, 93)
	title.size = Vector2(300, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_overlay.add_child(title)
	var hint := _label("在广场检查点复活，职业与物品不会丢失", 7, Color(0.9, 0.82, 0.7))
	hint.position = Vector2(90, 128)
	hint.size = Vector2(300, 15)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_overlay.add_child(hint)
	var revive := _button("在检查点复活", 8)
	revive.position = Vector2(185, 154)
	revive.size = Vector2(110, 23)
	revive.pressed.connect(_on_revive_pressed)
	death_overlay.add_child(revive)


func set_objective(text: String) -> void:
	objective_label.text = "◆ " + text
	objective_label.modulate = Color(1.45, 1.15, 0.72)
	var tween := create_tween()
	tween.tween_property(objective_label, "modulate", Color.WHITE, 0.35)


func show_tutorial(text: String) -> void:
	tutorial_label.text = text
	tutorial_panel.visible = not text.is_empty()


func show_interaction(text: String) -> void:
	interaction_label.text = text
	interaction_label.visible = not text.is_empty()


func clear_interaction() -> void:
	show_interaction("")


# 兼容旧交互组件的 HUD 接口。
func show_hint(text: String) -> void:
	show_interaction(text)


func hide_hint() -> void:
	clear_interaction()


func show_notice(text: String, duration: float = 2.4) -> void:
	_notice_generation += 1
	var generation := _notice_generation
	notice_label.text = text
	notice_panel.visible = true
	notice_panel.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(notice_panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		if generation == _notice_generation:
			notice_panel.visible = false
	)


func show_banner(title: String, subtitle: String = "", duration: float = 2.4) -> void:
	banner_label.text = title
	banner_subtitle.text = subtitle
	banner_label.visible = true
	banner_subtitle.visible = not subtitle.is_empty()
	banner_label.modulate.a = 0.0
	banner_subtitle.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner_label, "modulate:a", 1.0, 0.35)
	tween.tween_property(banner_subtitle, "modulate:a", 1.0, 0.35)
	tween.chain().tween_interval(duration)
	tween.chain().tween_property(banner_label, "modulate:a", 0.0, 0.45)
	tween.parallel().tween_property(banner_subtitle, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(func() -> void:
		banner_label.visible = false
		banner_subtitle.visible = false
	)


func show_dialog(speaker: String, text: String) -> void:
	if death_open:
		return
	dialog_title.text = speaker
	dialog_body.text = text
	dialog_panel.visible = true
	dialog_active = true
	dialog_button.focus_mode = Control.FOCUS_ALL
	dialog_button.grab_focus()
	if player != null:
		player.call("set_input_locked", true)


func close_dialog() -> void:
	if not dialog_active:
		return
	dialog_active = false
	dialog_panel.visible = false
	if player != null and not select_active and not character_open and not death_open:
		player.call("set_input_locked", false)
	dialog_finished.emit()


func open_profession_select(current_id: String = "", allow_cancel: bool = false) -> void:
	if death_open or dialog_active:
		return
	selected_profession = current_id
	allow_profession_cancel = allow_cancel
	select_active = true
	select_overlay.visible = true
	var cancel_button := select_overlay.get_node_or_null("Cancel") as Button
	if cancel_button != null:
		cancel_button.visible = allow_cancel
	select_confirm.disabled = selected_profession.is_empty()
	_refresh_profession_cards()
	if player != null:
		player.call("set_input_locked", true)


func _on_card_gui_input(event: InputEvent, profession_id: String) -> void:
	if not select_active:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		selected_profession = profession_id
		select_confirm.disabled = false
		_refresh_profession_cards()
		get_viewport().set_input_as_handled()


func _refresh_profession_cards() -> void:
	for i in mini(select_cards.get_child_count(), PROFESSION_CARDS.size()):
		var card := select_cards.get_child(i) as Panel
		var profession_id := str(PROFESSION_CARDS[i]["id"])
		_refresh_card_style(card, profession_id == selected_profession)


func _refresh_card_style(card: Panel, selected: bool) -> void:
	var accent: Color = card.get_meta("base_color", Color(0.72, 0.55, 0.28))
	var bg := Color(0.1, 0.075, 0.045, 0.98)
	var border := Color(0.34, 0.27, 0.18)
	if selected:
		bg = Color(0.22, 0.14, 0.055, 1.0)
		border = accent
	var style := _style(bg, border, 3)
	if selected:
		style.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", style)


func _confirm_profession() -> void:
	if selected_profession.is_empty():
		return
	select_active = false
	select_overlay.visible = false
	if player != null and not dialog_active and not character_open:
		player.call("set_input_locked", false)
	profession_selected.emit(selected_profession)


func _cancel_profession() -> void:
	if not allow_profession_cancel:
		return
	select_active = false
	select_overlay.visible = false
	if player != null and not dialog_active and not character_open:
		player.call("set_input_locked", false)


func open_character() -> void:
	if death_open or dialog_active or select_active or character_open:
		return
	character_open = true
	if player != null:
		player.call("set_input_locked", true)
	character_ui.call("open", player)


func close_character() -> void:
	if not character_open:
		return
	character_ui.call("close")


func _on_character_closed() -> void:
	character_open = false
	if player != null and not dialog_active and not select_active:
		player.call("set_input_locked", false)


func refresh_quick_slots() -> void:
	if player == null or quick_slots.is_empty():
		return
	var key_actions := ["weapon_1", "weapon_2", "weapon_3", "weapon_4"]
	var selected := int(player.get("selected_quick_slot"))
	for i in quick_slots.size():
		var item_id := Global.hotbar[i]
		var count := int(Global.hotbar_counts[i])
		var item_name := str(Global.ITEM_NAMES.get(item_id, item_id))
		quick_slots[i].call("set_item", item_id if count > 0 else "")
		quick_labels[i].text = _short_item_name(item_name) if count > 0 else "—"
		if count > 1:
			quick_labels[i].text += "\n%d" % count
		quick_keys[i].text = Settings.binding_text(str(key_actions[i]))
		var active := i == selected
		var accent := Color(1.0, 0.72, 0.3) if active else Color(0.32, 0.25, 0.16)
		var bg := Color(0.18, 0.11, 0.04, 0.98) if active else Color(0.08, 0.06, 0.04, 0.9)
		quick_slots[i].add_theme_stylebox_override("panel", _style(bg, accent, 2))


func _short_item_name(value: String) -> String:
	match value:
		"初级生命药水": return "药水"
		"旧铁长剑": return "长剑"
		"见习法杖": return "法杖"
		"见习者皮甲": return "皮甲"
		"银誓徽记": return "徽记"
	return value if value.length() <= 3 else value.substr(0, 3)


func _on_hotbar_drop(target_index: int, drag_data: Dictionary) -> void:
	Global.move_item_to_hotbar(target_index, drag_data)


func _refresh_skill() -> void:
	if player == null:
		return
	skill_name_label.text = str(player.call("get_skill_name"))
	skill_key_label.text = "[%s] 职业技能" % Settings.binding_text("dash")
	var cooldown := float(player.get("dash_cd_timer"))
	var total := maxf(float(player.call("get_skill_cooldown")), 0.01)
	skill_fill.size.x = 78.0 * clampf(1.0 - cooldown / total, 0.0, 1.0)


func show_boss(name: String, maximum: int) -> void:
	boss_name_label.text = name
	boss_bar.max_value = maximum
	boss_bar.value = maximum
	boss_panel.visible = true


func update_boss(current: int, maximum: int) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current


func hide_boss() -> void:
	boss_panel.visible = false


func set_attack_tint(enabled: bool) -> void:
	if enabled:
		var tint := ColorRect.new()
		tint.name = "RaidTint"
		tint.color = Color(0.45, 0.035, 0.015, 0.16)
		tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(tint)
		move_child(tint, 0)
		tint.create_tween().tween_property(tint, "color:a", 0.28, 1.0)
	else:
		var tint := get_node_or_null("RaidTint") as ColorRect
		if tint != null:
			var tween := tint.create_tween()
			tween.tween_property(tint, "color:a", 0.0, 0.8)
			tween.tween_callback(tint.queue_free)


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_text.text = "%d / %d" % [current, maximum]


func _on_player_died() -> void:
	if death_open:
		return
	death_open = true
	death_overlay.visible = true
	if player != null:
		player.call("set_input_locked", true)
	get_tree().paused = true


func _on_revive_pressed() -> void:
	get_tree().paused = false
	death_open = false
	death_overlay.visible = false
	revive_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and dialog_active:
		close_dialog()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("character_menu") and not death_open and not dialog_active and not select_active:
		if character_open:
			close_character()
		else:
			open_character()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and character_open:
		close_character()
		get_viewport().set_input_as_handled()

