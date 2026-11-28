extends Node2D

# 关卡入口处的回程路牌：靠近后按交互键返回白鹿镇公会。
# interactive=false 时只作为视觉路牌，由所在关卡脚本处理交互。

@export var label_text := "返回白鹿镇"
@export var interactive := true

var player: Node2D
var hud: Node
var was_near := false


func _ready() -> void:
	z_index = 6
	_build_label()
	queue_redraw()
	set_process(interactive)


func _build_label() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	var label := Label.new()
	label.text = label_text
	label.position = Vector2(-60, -58)
	label.size = Vector2(120, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	add_child(label)


func _draw() -> void:
	var wood := Color(0.32, 0.22, 0.13)
	var wood_light := Color(0.5, 0.36, 0.2)
	draw_rect(Rect2(-20, -34, 5, 36), wood)
	draw_rect(Rect2(15, -34, 5, 36), wood)
	draw_rect(Rect2(-32, -44, 64, 14), wood_light)
	draw_rect(Rect2(-29, -41, 58, 8), Color(0.2, 0.14, 0.09))
	draw_rect(Rect2(-30, -2, 60, 4), Color(0.23, 0.16, 0.1))


func _process(_delta: float) -> void:
	if not interactive:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
	if hud == null or not is_instance_valid(hud):
		hud = get_tree().get_first_node_in_group("HUD")
	if player == null or hud == null:
		return
	if bool(player.get("dead")) or _modal_open():
		if was_near:
			hud.call("hide_hint")
			was_near = false
		return
	if player.global_position.distance_to(global_position) <= 44.0:
		was_near = true
		hud.call("show_hint", "[%s] 返回白鹿镇公会" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			Global.return_to_white_deer_town()
	elif was_near:
		was_near = false
		hud.call("hide_hint")


func _modal_open() -> bool:
	if hud == null:
		return false
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
