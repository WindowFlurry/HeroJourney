extends CharacterBody2D

signal died
signal phase_changed(phase: int)

const SHEET: Texture2D = preload("res://graphics/enemies/coast/ska_sheet.png")
const WARNING_SQUARE: Texture2D = preload("res://graphics/boss/warning_square.png")
const WARNING_LINE: Texture2D = preload("res://graphics/boss/warning_line.png")
const LAVA_POOL_SCENE: PackedScene = preload("res://scenes/coast/lava_pool.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/prologue/prologue_projectile.tscn")

@export var max_health := 540
@export var move_speed := 44.0
@export var claw_damage := 18
@export var charge_damage := 22
@export var fire_damage := 10
@export var pool_damage := 11

var health := 540
var base_move_speed := 44.0
var phase := 1
var active := false
var dead := false
var player: Node2D
var sprite: Sprite2D
var body_shape: CollisionShape2D
var frame_size := Vector2(128, 128)
var facing_right := true
var state := "idle"
var skill := ""
var cast_timer := 0.0
var recover_timer := 0.0
var attack_cd := 1.4
var warning: Node2D
var charge_line: Line2D
var warning_on := false
var warning_clock := 0.0
var charge_timer := 0.0
var charge_dir := Vector2.ZERO
var charge_hit := false
var retreat_timer := 0.0
var retreat_dir := Vector2.ZERO
var start_position := Vector2.ZERO
var phase_two_done := false
var ui_layer: CanvasLayer
var ui_panel: Panel
var ui_bar: ProgressBar
var ui_font: SystemFont

const ARENA_SAFE := Rect2(1850, 500, 350, 400)


func _ready() -> void:
	add_to_group("Enemies")
	collision_layer = 4
	collision_mask = 3
	start_position = global_position
	base_move_speed = move_speed
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
	sprite.z_index = 5
	add_child(sprite)
	body_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(58, 34)
	body_shape.shape = rect
	body_shape.position = Vector2(0, -16)
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
	ui_panel.offset_left = -130
	ui_panel.offset_right = 130
	ui_panel.offset_top = -90
	ui_panel.offset_bottom = -60
	ui_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.04, 0.035, 0.94)
	style.border_color = Color(0.7, 0.38, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	ui_panel.add_theme_stylebox_override("panel", style)
	root.add_child(ui_panel)
	var name_label := Label.new()
	name_label.text = "赤烬龙裔 · 斯卡"
	name_label.position = Vector2(0, 2)
	name_label.size = Vector2(260, 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", ui_font)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	ui_panel.add_child(name_label)
	ui_bar = ProgressBar.new()
	ui_bar.position = Vector2(8, 17)
	ui_bar.size = Vector2(244, 8)
	ui_bar.max_value = max_health
	ui_bar.value = max_health
	ui_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.06, 0.04, 1.0)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.78, 0.22, 0.08, 1.0)
	fill.border_color = Color(1.0, 0.6, 0.2)
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
	attack_cd = 1.4
	ui_panel.visible = true
	Sfx.play("danger", 0.55, 0.0)


func reset_fight() -> void:
	if dead:
		return
	active = false
	state = "idle"
	health = max_health
	phase = 1
	phase_two_done = false
	move_speed = base_move_speed
	cast_timer = 0.0
	recover_timer = 0.0
	attack_cd = 1.4
	charge_timer = 0.0
	retreat_timer = 0.0
	global_position = start_position
	_clear_warnings()
	ui_panel.visible = false
	sprite.modulate = Color.WHITE
	_update_frame(0)
	_update_ui()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
	if player == null or bool(player.get("dead")):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if not active:
		velocity = Vector2.ZERO
		_update_frame(0)
		move_and_slide()
		return

	attack_cd = maxf(0.0, attack_cd - delta)
	var to_player: Vector2 = player.global_position - global_position
	facing_right = to_player.x >= 0.0
	match state:
		"idle":
			var d := to_player.length()
			if d > 175.0:
				velocity = to_player.normalized() * move_speed
				_update_frame(1)
			elif d < 115.0:
				velocity = -to_player.normalized() * move_speed * 0.85
				_update_frame(1)
			else:
				velocity = Vector2.ZERO
				_update_frame(0)
			if attack_cd <= 0.0:
				_choose_attack(d)
		"windup":
			velocity = Vector2.ZERO
			cast_timer -= delta
			warning_clock += delta
			var blink := fmod(warning_clock, 0.2) < 0.1
			if warning != null and is_instance_valid(warning):
				warning.visible = blink
			if charge_line != null and is_instance_valid(charge_line):
				charge_line.visible = blink
			if cast_timer <= 0.0:
				_execute_skill()
		"charge":
			velocity = charge_dir * (480.0 if phase == 2 else 410.0)
			charge_timer -= delta
			if not charge_hit and global_position.distance_to(player.global_position) <= 46.0:
				charge_hit = true
				player.call("take_damage", charge_damage)
				player.call("apply_knockback", charge_dir, 280.0, 0.3)
			if charge_timer <= 0.0:
				state = "recover"
				recover_timer = 0.65
				retreat_dir = (global_position - player.global_position).normalized()
				retreat_timer = 0.45
				velocity = Vector2.ZERO
				attack_cd = 1.7 if phase == 2 else 2.2
				_update_frame(0)
		"recover":
			recover_timer -= delta
			if retreat_timer > 0.0:
				retreat_timer -= delta
				velocity = retreat_dir * move_speed * 0.75
				_update_frame(1)
			else:
				velocity = Vector2.ZERO
				_update_frame(0)
			if recover_timer <= 0.0:
				state = "idle"
				velocity = Vector2.ZERO
				_update_frame(0)
	move_and_slide()


func _choose_attack(distance: float) -> void:
	var roll := randf()
	if distance <= 105.0:
		if phase == 2 and roll < 0.45:
			_start_pools()
		else:
			_start_claw()
	elif distance <= 270.0:
		if phase == 2 and roll < 0.3:
			_start_pools()
		elif roll < 0.65:
			_start_fire()
		else:
			_start_charge()
	else:
		if phase == 2 and roll < 0.25:
			_start_fire()
		else:
			_start_charge()


func _start_claw() -> void:
	state = "windup"
	skill = "claw"
	cast_timer = 0.95
	warning_clock = 0.0
	_clear_warnings()
	_spawn_warning_square(player.global_position, 2.55)
	_update_frame(2)
	Sfx.play("warn", 1.0, -4.0)


func _start_fire() -> void:
	state = "windup"
	skill = "fire"
	cast_timer = 0.8
	warning_clock = 0.0
	_clear_warnings()
	_update_frame(2)
	Sfx.play("warn", 1.15, -5.0)


func _start_charge() -> void:
	state = "windup"
	skill = "charge"
	cast_timer = 0.85
	warning_clock = 0.0
	_clear_warnings()
	_spawn_charge_line(global_position, player.global_position)
	_update_frame(2)
	Sfx.play("warn", 0.9, -3.0)


func _start_pools() -> void:
	state = "windup"
	skill = "pools"
	cast_timer = 0.85
	warning_clock = 0.0
	_clear_warnings()
	_update_frame(2)
	Sfx.play("warn", 1.2, -6.0)


func _execute_skill() -> void:
	var finished := skill
	_clear_warnings()
	if finished == "charge":
		_do_charge()
		return
	match finished:
		"claw":
			_do_claw()
		"fire":
			_do_fire()
		"pools":
			_do_pools()
	retreat_dir = (global_position - player.global_position).normalized()
	retreat_timer = 0.35
	state = "recover"
	recover_timer = 0.65
	attack_cd = 1.65 if phase == 2 else 2.1
	_update_frame(0)


func _do_claw() -> void:
	if player == null:
		return
	var target := player.global_position
	if global_position.distance_to(target) <= 110.0:
		player.call("take_damage", claw_damage)
		var dir := (target - global_position).normalized()
		player.call("apply_knockback", dir, 240.0, 0.26)
	_spawn_impact(target)
	Sfx.play("sword", 0.8, -2.0)


func _do_fire() -> void:
	if player == null:
		return
	var target := player.global_position + Vector2(0, -12)
	var origin := global_position + Vector2(0, -58)
	var dir := (target - origin).normalized()
	var angles := [0.0]
	if phase == 2:
		angles = [-0.21, -0.07, 0.07, 0.21]
	else:
		angles = [-0.17, 0.0, 0.17]
	for angle in angles:
		var shot_dir := dir.rotated(angle)
		var projectile := PROJECTILE_SCENE.instantiate() as Node2D
		if projectile == null:
			continue
		get_parent().add_child(projectile)
		projectile.global_position = origin
		var aim := origin + shot_dir * maxf(origin.distance_to(target) + 50.0, 260.0)
		projectile.call("setup_enemy_target", shot_dir, 170.0, fire_damage, aim)
		projectile.set("projectile_color", Color(1.0, 0.38, 0.08))
	Sfx.play("enemy_strike", 0.7, -2.0)


func _do_charge() -> void:
	if player == null:
		return
	charge_dir = (player.global_position - global_position).normalized()
	if charge_dir == Vector2.ZERO:
		charge_dir = Vector2.RIGHT
	charge_timer = 0.34 if phase == 2 else 0.3
	charge_hit = false
	state = "charge"
	_update_frame(1)
	Sfx.play("enemy_strike", 0.62, -3.0)


func _do_pools() -> void:
	if player == null:
		return
	var base := player.global_position
	for offset in [Vector2.ZERO, Vector2(64, 0), Vector2(-64, 0)]:
		var pos: Vector2 = base + offset
		pos.x = clampf(pos.x, ARENA_SAFE.position.x + 20.0, ARENA_SAFE.end.x - 20.0)
		pos.y = clampf(pos.y, ARENA_SAFE.position.y + 20.0, ARENA_SAFE.end.y - 20.0)
		var pool := LAVA_POOL_SCENE.instantiate() as Node2D
		if pool == null:
			continue
		get_parent().add_child(pool)
		pool.global_position = pos
		pool.call("setup", 34.0, pool_damage, 1.5, 3.8)
	Sfx.play("danger", 0.8, -8.0)


func _spawn_warning_square(pos: Vector2, warning_scale: float) -> void:
	var w := Sprite2D.new()
	w.texture = WARNING_SQUARE
	w.scale = Vector2(warning_scale, warning_scale)
	w.z_index = 2
	get_parent().add_child(w)
	w.global_position = pos
	warning = w


func _spawn_charge_line(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from + Vector2(0, -8), to + Vector2(0, -8)])
	line.width = 12.0
	line.default_color = Color(1.0, 0.24, 0.06, 0.55)
	line.z_index = 2
	get_parent().add_child(line)
	charge_line = line


func _spawn_impact(pos: Vector2) -> void:
	var fx := Sprite2D.new()
	fx.texture = WARNING_SQUARE
	fx.modulate = Color(1.0, 0.5, 0.16, 0.8)
	fx.z_index = 3
	fx.scale = Vector2(2.0, 2.0)
	get_parent().add_child(fx)
	fx.global_position = pos
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fx, "modulate:a", 0.0, 0.35)
	tween.tween_property(fx, "scale", Vector2(3.2, 3.2), 0.35)
	tween.chain().tween_callback(fx.queue_free)


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
		{"rect": Rect2(base + Vector2(-46, -124), Vector2(92, 42)), "multiplier": 1.35, "region": "head"},
		{"rect": Rect2(base + Vector2(-62, -84), Vector2(124, 62)), "multiplier": 1.0, "region": "body"},
		{"rect": Rect2(base + Vector2(-54, -24), Vector2(108, 28)), "multiplier": 0.75, "region": "feet"},
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
	health = maxi(health - amount, 0)
	_update_ui()
	Global.spawn_damage_number(global_position + Vector2(0, -92), amount)
	sprite.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.78, 0.62) if phase == 2 else Color.WHITE, 0.12)
	if health <= max_health * 0.5 and phase == 1 and not phase_two_done:
		_enter_phase_two()
	if health <= 0:
		_die()


func _enter_phase_two() -> void:
	phase_two_done = true
	phase = 2
	move_speed += 6.0
	attack_cd = 0.9
	sprite.modulate = Color(1.0, 0.78, 0.62)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.24, 0.06, 1.0)
	fill.border_color = Color(1.0, 0.8, 0.34)
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(2)
	ui_bar.add_theme_stylebox_override("fill", fill)
	phase_changed.emit(2)
	Sfx.play("danger", 0.45, 2.0)


func _update_ui() -> void:
	if ui_bar != null:
		ui_bar.max_value = max_health
		ui_bar.value = health


func _die() -> void:
	if dead:
		return
	dead = true
	active = false
	_clear_warnings()
	remove_from_group("Enemies")
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if ui_panel != null:
		ui_panel.visible = false
	died.emit()
	Sfx.play("enemy_death", 0.55, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_property(sprite, "rotation", 0.12, 1.0)
	tween.chain().tween_callback(queue_free)
