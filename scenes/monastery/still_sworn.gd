extends CharacterBody2D

signal died

const SHEET: Texture2D = preload("res://graphics/enemies/monastery/still_sworn_sheet.png")
const WARNING_SQUARE: Texture2D = preload("res://graphics/boss/warning_square.png")
const WARNING_LINE: Texture2D = preload("res://graphics/boss/warning_line.png")
const CLAW_IMPACT: Texture2D = preload("res://graphics/boss/claw_impact.png")

@export var max_health := 380
@export var move_speed := 38.0
@export var slash_damage := 16
@export var charge_damage := 18
@export var counter_damage := 12
@export var slash_radius := 58.0
@export var slam_cooldown := 4.4
@export var charge_cooldown := 5.8
@export var shield_cooldown_time := 7.5

var health := 380
var active := false
var dead := false
var player: Node2D
var sprite: Sprite2D
var body_shape: CollisionShape2D
var frame_size := Vector2(64, 64)
var facing_right := true
var state := "idle"
var skill := ""
var cast_timer := 0.0
var recover_timer := 0.0
var attack_cd := 1.2
var shield_cd := 3.0
var shielded := false
var shield_timer := 0.0
var shield_weakened := false
var start_position := Vector2.ZERO
var warning: Node2D
var charge_line: Line2D
var warning_on := false
var warning_clock := 0.0
var ui_layer: CanvasLayer
var ui_panel: Panel
var ui_bar: ProgressBar
var ui_font: SystemFont
var charge_target := Vector2.ZERO


func _ready() -> void:
	add_to_group("Enemies")
	collision_layer = 4
	collision_mask = 3
	start_position = global_position
	player = get_tree().get_first_node_in_group("Player")
	_build_visual()
	_build_ui()
	health = max_health
	_update_ui()


func _build_visual() -> void:
	frame_size = SHEET.get_size() / Vector2(3, 2)
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = 3
	sprite.vframes = 2
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, 3.0 - frame_size.y * 0.5)
	sprite.z_index = 4
	add_child(sprite)
	body_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 20)
	body_shape.shape = rect
	body_shape.position = Vector2(0, -10)
	add_child(body_shape)
	_update_frame(0)


func _build_ui() -> void:
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 3
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)
	ui_panel = Panel.new()
	ui_panel.anchor_left = 0.5
	ui_panel.anchor_right = 0.5
	ui_panel.anchor_top = 1.0
	ui_panel.anchor_bottom = 1.0
	ui_panel.offset_left = -120
	ui_panel.offset_right = 120
	ui_panel.offset_top = -90
	ui_panel.offset_bottom = -60
	ui_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.04, 0.94)
	style.border_color = Color(0.62, 0.48, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	ui_panel.add_theme_stylebox_override("panel", style)
	root.add_child(ui_panel)
	var name_label := Label.new()
	name_label.text = "失誓骑士罗兰"
	name_label.position = Vector2(0, 2)
	name_label.size = Vector2(240, 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", ui_font)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.48))
	ui_panel.add_child(name_label)
	ui_bar = ProgressBar.new()
	ui_bar.position = Vector2(8, 17)
	ui_bar.size = Vector2(224, 8)
	ui_bar.max_value = max_health
	ui_bar.value = max_health
	ui_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.08, 0.06, 1.0)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.62, 0.18, 0.12, 1.0)
	fill.border_color = Color(0.95, 0.55, 0.22)
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(2)
	ui_bar.add_theme_stylebox_override("background", bg)
	ui_bar.add_theme_stylebox_override("fill", fill)
	ui_panel.add_child(ui_bar)
	ui_panel.visible = false


func activate() -> void:
	if active or dead:
		return
	active = true
	state = "idle"
	attack_cd = 1.0
	shield_cd = 3.0
	ui_panel.visible = true
	Sfx.play("danger", 0.6, 0.0)


func apply_shield_weakness() -> void:
	if shield_weakened:
		return
	shield_weakened = true
	shield_cooldown_time = 13.0


func reset_fight() -> void:
	if dead:
		return
	active = false
	state = "idle"
	health = max_health
	shielded = false
	shield_timer = 0.0
	cast_timer = 0.0
	recover_timer = 0.0
	attack_cd = 1.0
	shield_cd = 3.0
	global_position = start_position
	_clear_warnings()
	ui_panel.visible = false
	_update_frame(0)
	_update_ui()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
	if player == null or bool(player.get("dead")):
		velocity = Vector2.ZERO
		if active and not dead:
			pass
		move_and_slide()
		return
	if not active:
		velocity = Vector2.ZERO
		_update_frame(0)
		move_and_slide()
		return

	attack_cd = maxf(0.0, attack_cd - delta)
	shield_cd = maxf(0.0, shield_cd - delta)
	var to_player: Vector2 = player.global_position - global_position
	facing_right = to_player.x >= 0.0
	match state:
		"idle":
			if shielded:
				velocity = Vector2.ZERO
				_update_frame(2)
			elif to_player.length() > 76.0:
				velocity = to_player.normalized() * move_speed
				_update_frame(1)
			else:
				velocity = Vector2.ZERO
				_update_frame(0)
			if attack_cd <= 0.0:
				_choose_attack(to_player.length())
		"windup":
			velocity = Vector2.ZERO
			cast_timer -= delta
			warning_clock += delta
			var blink := fmod(warning_clock, 0.22) < 0.11
			if warning != null and is_instance_valid(warning):
				warning.visible = blink
			if charge_line != null and is_instance_valid(charge_line):
				charge_line.visible = blink
			if cast_timer <= 0.0:
				_execute_skill()
		"recover":
			velocity = Vector2.ZERO
			recover_timer -= delta
			if recover_timer <= 0.0:
				state = "idle"
				shielded = false
				sprite.modulate = Color.WHITE
				_update_frame(0)
		"shield":
			velocity = Vector2.ZERO
			shield_timer -= delta
			_update_frame(2)
			if shield_timer <= 0.0:
				shielded = false
				sprite.modulate = Color.WHITE
				if not shield_weakened and to_player.length() <= 88.0:
					_do_counter()
				state = "recover"
				recover_timer = 0.25 if shield_weakened else 0.45
				_update_frame(0)
	move_and_slide()


func _choose_attack(distance: float) -> void:
	if shield_cd <= 0.0 and distance <= 120.0:
		_start_shield()
		return
	if distance <= 82.0:
		_start_slash()
	elif distance <= 270.0:
		_start_charge()
	else:
		attack_cd = 0.4


func _start_shield() -> void:
	state = "shield"
	shielded = true
	shield_timer = 0.45 if shield_weakened else 1.1
	shield_cd = shield_cooldown_time
	attack_cd = 0.8
	sprite.modulate = Color(0.65, 0.8, 1.0)
	Sfx.play("warn", 0.8, -3.0)
	_update_frame(2)


func _start_slash() -> void:
	state = "windup"
	skill = "slash"
	cast_timer = 0.58
	warning_clock = 0.0
	_clear_warnings()
	_spawn_warning_square(player.global_position)
	_update_frame(2)
	Sfx.play("warn", 1.05, -4.0)


func _start_charge() -> void:
	state = "windup"
	skill = "charge"
	cast_timer = 0.72
	warning_clock = 0.0
	_clear_warnings()
	charge_target = player.global_position
	_spawn_charge_line(global_position, charge_target)
	_update_frame(2)
	Sfx.play("warn", 0.9, -3.0)


func _execute_skill() -> void:
	var finished := skill
	_clear_warnings()
	if finished == "slash":
		_do_slash()
	elif finished == "charge":
		_do_charge()
	state = "recover"
	recover_timer = 0.65
	attack_cd = slam_cooldown if finished == "slash" else charge_cooldown
	_update_frame(0)


func _do_slash() -> void:
	if player == null:
		return
	var target := player.global_position
	if global_position.distance_to(target) <= slash_radius + 24.0:
		player.call("take_damage", slash_damage)
		var dir := (target - global_position).normalized()
		player.call("apply_knockback", dir, 260.0, 0.25)
	_spawn_impact(target)
	Sfx.play("sword", 0.9, -3.0)


func _do_charge() -> void:
	if player == null:
		return
	var start := global_position
	var dir := (charge_target - start).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var end := start + dir * minf(start.distance_to(charge_target) + 70.0, 190.0)
	# 冲锋必须留在礼拜堂内部，不能穿出地图或卡在墙外
	var arena := Rect2(440.0, 120.0, 920.0, 210.0)
	end.x = clampf(end.x, arena.position.x, arena.end.x)
	end.y = clampf(end.y, arena.position.y, arena.end.y)
	var closest := Geometry2D.get_closest_point_to_segment(player.global_position, start, end)
	if closest.distance_to(player.global_position) <= 30.0:
		player.call("take_damage", charge_damage)
		player.call("apply_knockback", dir, 320.0, 0.28)
	Sfx.play("enemy_strike", 0.8, -2.0)
	var tween := create_tween()
	tween.tween_property(self, "global_position", end, 0.28)
	await tween.finished


func _do_counter() -> void:
	if player == null:
		return
	player.call("take_damage", counter_damage)
	var dir := (player.global_position - global_position).normalized()
	player.call("apply_knockback", dir, 280.0, 0.25)
	_spawn_impact(player.global_position)
	Sfx.play("sword", 1.0, -2.0)


func _spawn_warning_square(pos: Vector2) -> void:
	var w := Sprite2D.new()
	w.texture = WARNING_SQUARE
	w.scale = Vector2(2.2, 2.2)
	w.z_index = 2
	get_parent().add_child(w)
	w.global_position = pos
	warning = w


func _spawn_charge_line(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from + Vector2(0, -8), to + Vector2(0, -8)])
	line.width = 10.0
	line.default_color = Color(1.0, 0.28, 0.1, 0.5)
	line.z_index = 2
	get_parent().add_child(line)
	charge_line = line


func _spawn_impact(pos: Vector2) -> void:
	var fx := Sprite2D.new()
	fx.texture = CLAW_IMPACT
	fx.z_index = 3
	get_parent().add_child(fx)
	fx.global_position = pos
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(fx, "modulate:a", 0.0, 0.35)
	t.tween_property(fx, "scale", Vector2(1.5, 1.5), 0.35)
	t.chain().tween_callback(fx.queue_free)


func _clear_warnings() -> void:
	if warning != null and is_instance_valid(warning):
		warning.queue_free()
	warning = null
	if charge_line != null and is_instance_valid(charge_line):
		charge_line.queue_free()
	charge_line = null


func _update_frame(column: int) -> void:
	if sprite == null:
		return
	var row := 1 if facing_right else 0
	sprite.frame = row * 3 + clampi(column, 0, 2)


func get_hit_boxes() -> Array:
	var base := global_position
	return [
		{"rect": Rect2(base + Vector2(-24, -72), Vector2(48, 22)), "multiplier": 1.35, "region": "head"},
		{"rect": Rect2(base + Vector2(-28, -50), Vector2(56, 34)), "multiplier": 1.0, "region": "body"},
		{"rect": Rect2(base + Vector2(-22, -16), Vector2(44, 16)), "multiplier": 0.75, "region": "feet"},
	]


func get_hit_info(attacker_pos: Vector2, dir: Vector2, reach: float) -> Dictionary:
	return CombatHit.melee(get_hit_boxes(), attacker_pos, dir, reach)


func hit_test_projectile(point: Vector2, radius: float) -> Dictionary:
	return CombatHit.point(get_hit_boxes(), point, radius)


func is_hit_by_attack(attacker_pos: Vector2, dir: Vector2, reach: float) -> bool:
	return bool(get_hit_info(attacker_pos, dir, reach).get("hit", false))


func take_damage(amount: int) -> void:
	take_damage_from(amount, Vector2.INF)


func take_damage_from(amount: int, _source_pos: Vector2) -> void:
	if dead:
		return
	if not active:
		activate()
	var applied := 1 if shielded else amount
	health = maxi(health - applied, 0)
	_update_ui()
	Global.spawn_damage_number(global_position + Vector2(0, -64), applied)
	var tint := Color(0.65, 0.8, 1.0) if shielded else Color.WHITE
	sprite.modulate = tint
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", tint, 0.12)
	if health <= 0:
		_die()


func _update_ui() -> void:
	if ui_bar != null:
		ui_bar.max_value = max_health
		ui_bar.value = health


func _die() -> void:
	if dead:
		return
	dead = true
	active = false
	shielded = false
	_clear_warnings()
	remove_from_group("Enemies")
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if ui_panel != null:
		ui_panel.visible = false
	died.emit()
	Sfx.play("enemy_death", 0.62, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.9)
	tween.tween_property(sprite, "rotation", 0.15, 0.9)
	tween.chain().tween_callback(queue_free)
