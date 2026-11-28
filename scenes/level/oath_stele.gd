extends Node2D

const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")

@export var reveal_flag := "boss_defeated"
@export var lit_flag := "first_stele_lit"
@export var reveal_notice := "裂牙格鲁姆倒下了，誓火石碑显现"
@export var lit_notice := "誓火石碑已点燃，白桦林地得到净化"
@export var victory_title := "第一关完成"
@export var victory_location := "白桦林地"
@export var reveal_delay := 5.0

var player: Node2D
var hud
var label: Label
var glow: Sprite2D
var announced := false
var lit_visual := false
var allow_interact := false


func _ready() -> void:
	add_to_group("OathSteles")
	player = get_tree().get_first_node_in_group("Player")
	hud = get_tree().get_first_node_in_group("HUD")
	_build_visual()
	visible = false
	allow_interact = bool(Global.get(reveal_flag))


func _build_visual() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	label = Label.new()
	label.text = "誓火石碑"
	label.position = Vector2(-45, -66)
	label.size = Vector2(90, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.4))
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	add_child(label)

	glow = Sprite2D.new()
	glow.texture = GLOW
	glow.position = Vector2(0, -22)
	glow.scale = Vector2(1.4, 1.4)
	glow.modulate = Color(1.0, 0.55, 0.18, 0.0)
	glow.z_index = 1
	add_child(glow)


func _process(_delta: float) -> void:
	if not bool(Global.get(reveal_flag)):
		visible = false
		return
	if not visible:
		visible = true
		if not announced:
			announced = true
			if hud != null:
				hud.call("show_notice", reveal_notice)
			if not allow_interact:
				var delay := get_tree().create_timer(reveal_delay)
				delay.timeout.connect(func() -> void:
					if is_inside_tree():
						allow_interact = true
				)
	if bool(Global.get(lit_flag)):
		_set_lit_visual()
		return
	if not allow_interact:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
	if hud == null or not is_instance_valid(hud):
		hud = get_tree().get_first_node_in_group("HUD")
	if player == null or hud == null:
		return
	if player.global_position.distance_to(global_position) <= 44.0:
		hud.call("show_hint", "[%s] 点燃誓火石碑" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_light()
	else:
		hud.call("hide_hint")


func _light() -> void:
	if bool(Global.get(lit_flag)):
		return
	Global.set(lit_flag, true)
	match lit_flag:
		"first_stele_lit":
			Global.pending_route_unlock = "monastery"
		"second_stele_lit":
			Global.pending_route_unlock = "coast"
		"third_stele_lit":
			Global.pending_route_unlock = "third"
	SaveGame.save_game(victory_location)
	_set_lit_visual()
	if hud != null:
		hud.call("hide_hint")
		hud.call("show_notice", lit_notice)
	Sfx.play("craft", 1.0, 2.0)
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	# 不再显示“通关成功”弹窗；点碑后直接回到白鹿镇公会。
	Global.return_to_white_deer_town()


func _set_lit_visual() -> void:
	if lit_visual:
		return
	lit_visual = true
	label.text = "誓火石碑 · 已点燃"
	glow.modulate.a = 0.8
	var tween := create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.85, 0.8)
	tween.tween_property(glow, "modulate:a", 0.35, 0.8)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-18, -46, 36, 44), Color(0.42, 0.36, 0.3))
	draw_rect(Rect2(-22, -8, 44, 8), Color(0.27, 0.23, 0.2))
	draw_rect(Rect2(-10, -38, 20, 4), Color(0.26, 0.22, 0.18))
	var lit := bool(Global.get(lit_flag))
	var rune := Color(1.0, 0.55, 0.2) if lit else Color(0.2, 0.17, 0.15)
	draw_circle(Vector2(0, -28), 7.0, rune)
	draw_line(Vector2(-9, -28), Vector2(9, -28), rune, 2.0)
	draw_line(Vector2(0, -37), Vector2(0, -19), rune, 2.0)
