extends Node2D

const GATE_TEXTURE: Texture2D = preload("res://graphics/monastery/monastery_gate.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")
const MONASTERY_SCENE := "res://scenes/monastery/monastery.tscn"
const MONASTERY_ENTRANCE := Vector2(560, 680)

var player: Node2D
var hud
var sprite: Sprite2D
var label: Label
var near := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	hud = get_tree().get_first_node_in_group("HUD")
	var scale_value := 1.8
	sprite = Sprite2D.new()
	sprite.texture = GATE_TEXTURE
	sprite.scale = Vector2(scale_value, scale_value)
	sprite.position = Vector2(0, 2.0 - GATE_TEXTURE.get_height() * scale_value * 0.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 1
	add_child(sprite)
	var glow := Sprite2D.new()
	glow.texture = GLOW
	glow.position = Vector2(0, -46)
	glow.scale = Vector2(1.7, 1.7)
	glow.modulate = Color(0.5, 0.7, 1.0, 0.28)
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.z_index = 0
	add_child(glow)
	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "modulate:a", 0.55, 1.0)
	pulse.tween_property(glow, "modulate:a", 0.22, 1.0)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	label = Label.new()
	label.text = "失誓修道院"
	label.position = Vector2(-55, -GATE_TEXTURE.get_height() * scale_value - 4.0)
	label.size = Vector2(110, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.5))
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
	var unlocked := Global.first_stele_lit
	visible = unlocked
	if not unlocked or player == null or hud == null:
		return
	var death_panel = hud.get("death_panel")
	if bool(hud.get("character_open")) or bool(hud.get("crafting_open")) or (death_panel != null and death_panel.visible):
		hud.call("hide_hint")
		return
	var victory = get_tree().get_first_node_in_group("VictoryScreen")
	if victory != null and victory.has_method("is_open") and bool(victory.call("is_open")):
		hud.call("hide_hint")
		return
	near = player.global_position.distance_to(global_position) <= 46.0
	if near:
		hud.call("show_hint", "[%s] 进入失誓修道院" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_enter()
	else:
		hud.call("hide_hint")


func _enter() -> void:
	if not Global.first_stele_lit:
		return
	var data: Dictionary = player.call("get_save_data")
	data["position"] = [MONASTERY_ENTRANCE.x, MONASTERY_ENTRANCE.y]
	SaveGame.pending_player_data = data
	Global.prologue_scene_spawn = ""
	Global.prologue_travel = false
	get_tree().change_scene_to_file(MONASTERY_SCENE)
