extends Node2D

const GATE_TEXTURE: Texture2D = preload("res://graphics/coast/coast_gate.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")
const COAST_SCENE := "res://scenes/coast/coast.tscn"
const COAST_ENTRANCE := Vector2(240, 1500)

var player: Node2D
var hud
var sprite: Sprite2D
var label: Label


func _ready() -> void:
	add_to_group("CoastGates")
	player = get_tree().get_first_node_in_group("Player")
	hud = get_tree().get_first_node_in_group("HUD")
	var scale_value := 1.9
	sprite = Sprite2D.new()
	sprite.texture = GATE_TEXTURE
	sprite.scale = Vector2(scale_value, scale_value)
	sprite.position = Vector2(0, 2.0 - GATE_TEXTURE.get_height() * scale_value * 0.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 1
	add_child(sprite)
	var glow := Sprite2D.new()
	glow.texture = GLOW
	glow.position = Vector2(0, -48)
	glow.scale = Vector2(1.8, 1.8)
	glow.modulate = Color(1.0, 0.48, 0.16, 0.3)
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.z_index = 0
	add_child(glow)
	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "modulate:a", 0.6, 1.0)
	pulse.tween_property(glow, "modulate:a", 0.24, 1.0)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	label = Label.new()
	label.text = "赤烬海岸"
	label.position = Vector2(-55, -GATE_TEXTURE.get_height() * scale_value - 4.0)
	label.size = Vector2(110, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	add_child(label)


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
	if hud == null or not is_instance_valid(hud):
		hud = get_tree().get_first_node_in_group("HUD")
	var unlocked := Global.second_stele_lit
	visible = unlocked
	if not unlocked or player == null or hud == null:
		return
	var death_panel = hud.get("death_panel")
	var character_open = hud.get("character_open")
	var dialog_active = hud.get("dialog_active")
	var select_active = hud.get("select_active")
	var test_menu_open = hud.get("test_menu_open")
	if (
		(character_open != null and bool(character_open))
		or (dialog_active != null and bool(dialog_active))
		or (select_active != null and bool(select_active))
		or (test_menu_open != null and bool(test_menu_open))
		or (death_panel != null and death_panel.visible)
	):
		hud.call("hide_hint")
		return
	var victory = get_tree().get_first_node_in_group("VictoryScreen")
	if victory != null and victory.has_method("is_open") and bool(victory.call("is_open")):
		hud.call("hide_hint")
		return
	if player.global_position.distance_to(global_position) <= 48.0:
		hud.call("show_hint", "[%s] 进入赤烬海岸" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_enter()
	else:
		hud.call("hide_hint")


func _enter() -> void:
	if not Global.second_stele_lit:
		return
	var data: Dictionary = player.call("get_save_data")
	data["position"] = [COAST_ENTRANCE.x, COAST_ENTRANCE.y]
	SaveGame.pending_player_data = data
	Global.prologue_scene_spawn = ""
	Global.prologue_travel = false
	get_tree().change_scene_to_file(COAST_SCENE)
