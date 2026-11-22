extends CharacterBody2D

const COLS := 13
const ROW_FRONT := 0
const ROW_BACK := 1
const ROW_LEFT := 2
const ROW_RIGHT := 3
const F_IDLE_A := 0
const F_IDLE_B := 1
const F_WALK := 2
const F_CLAW_UP := 6
const F_CLAW_SLAM := 7
const F_TUMOR := 8
const F_ROOT := 9
const F_DEATH1 := 10
const F_DEATH2 := 11
const F_DEATH3 := 12

const ORB_SCENE := preload("res://scenes/boss/orb.tscn")
const SPIKE_SCENE := preload("res://scenes/boss/root_spike.tscn")
const WARNING_SQUARE := preload("res://graphics/boss/warning_square.png")
const WARNING_LINE := preload("res://graphics/boss/warning_line.png")
const CLAW_IMPACT := preload("res://graphics/boss/claw_impact.png")

const COOLDOWN := {"claw": 4.5, "orb": 6.0, "root": 7.0, "slam": 8.5}
const WINDUP := {"claw": 0.8, "orb": 1.0, "root": 0.7, "slam": 1.1}

@export var max_health := 420
@export var move_speed := 22.0
@export var claw_damage := 35
@export var orb_damage := 22
@export var root_damage := 12
@export var slam_damage := 18
@export var slam_radius := 125.0
@export var slam_knockback := 280.0
@export var claw_radius := 28.0
@export var body_center := Vector2(0, -85)
@export var body_extents := Vector2(62, 85)

@onready var sprite: Sprite2D = $Sprite
@onready var glow1: Sprite2D = $TumorGlow1
@onready var glow2: Sprite2D = $TumorGlow2
@onready var glow3: Sprite2D = $TumorGlow3
@onready var death_fog: GPUParticles2D = $DeathFog
@onready var body_shape: CollisionShape2D = $CollisionShape2D

var player
var arena_curtain
var health := 420
var active := false
var dead := false
var state := "idle"
var skill := ""
var cast_timer := 0.0
var recover_timer := 0.0
var decision_timer := 1.0
var cooldowns := {"claw": 0.0, "orb": 0.0, "root": 0.0, "slam": 0.0}
var direction_row := ROW_FRONT
var anim_timer := 0.0
var walk_frame := 0
var pose_col := -1
var pose_timer := 0.0
var moving := false
var claw_target := Vector2.ZERO
var warning
var root_warnings: Array = []
var root_targets: Array = []
var warning_clock := 0.0
var ui_layer: CanvasLayer
var ui_panel: Panel
var ui_bar: ProgressBar
var ui_font: SystemFont
var player_connected := false


func _ready() -> void:
	if Global.boss_defeated:
		queue_free()
		return
	add_to_group("Enemies")
	player = get_tree().get_first_node_in_group("Player")
	arena_curtain = get_parent().get_node_or_null("ArenaCurtain")
	health = max_health
	_build_ui()
	_hide_glows()
	_set_frame(F_IDLE_A)
	if player and not player_connected:
		player.died.connect(_on_player_died)
		player_connected = true


func _player_center() -> Vector2:
	return player.global_position + Vector2(0, -12)


func _player_on_island() -> bool:
	if player == null:
		return false
	var p: Vector2 = player.global_position
	return p.y > 1300.0 and p.x > 140.0 and p.x < 760.0


func _activate() -> void:
	if active or dead:
		return
	active = true
	state = "idle"
	decision_timer = 1.2
	_show_ui()
	if arena_curtain != null and arena_curtain.has_method("activate"):
		arena_curtain.call("activate")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		if player != null and not player_connected:
			player.died.connect(_on_player_died)
			player_connected = true
	if player == null:
		return

	if not active:
		moving = false
		_face_player()
		_update_anim(delta)
		if _player_on_island():
			_activate()
		return

	# 玩家离开岛屿（走回桥/主岛）：Boss 停手、退出战斗，血量回满等待再次进入
	if not _player_on_island():
		_reset_fight()
		return

	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, cooldowns[key] - delta)

	_face_player()
	match state:
		"idle":
			_do_idle(delta)
		"windup":
			_update_windup(delta)
		"recover":
			recover_timer -= delta
			if recover_timer <= 0.0:
				state = "idle"
				decision_timer = randf_range(0.7, 1.3)
	_update_anim(delta)
	_update_ui()


func _do_idle(delta: float) -> void:
	var to_player: Vector2 = player.global_position - global_position
	moving = to_player.length() > 58.0
	if moving:
		velocity = to_player.normalized() * move_speed
		move_and_slide()
		global_position.x = clampf(global_position.x, 300.0, 640.0)
		global_position.y = clampf(global_position.y, 1350.0, 1440.0)
	else:
		velocity = Vector2.ZERO
	decision_timer -= delta
	if decision_timer <= 0.0:
		_try_start_skill()


func _try_start_skill() -> void:
	var distance: float = player.global_position.distance_to(global_position)
	var available: Array = []
	if cooldowns["claw"] <= 0.0 and distance <= 130.0:
		available.append("claw")
	if cooldowns["orb"] <= 0.0:
		available.append("orb")
	if cooldowns["root"] <= 0.0:
		available.append("root")
	if cooldowns["slam"] <= 0.0 and distance <= 150.0:
		available.append("slam")
	if available.is_empty():
		decision_timer = 0.6
		return
	_start_skill(available[randi() % available.size()])


func _start_skill(s: String) -> void:
	state = "windup"
	skill = s
	moving = false
	velocity = Vector2.ZERO
	_face_player()
	cast_timer = float(WINDUP[s])
	warning_clock = 0.0
	Sfx.play("warn")
	match s:
		"claw":
			claw_target = player.global_position
			_show_square_warning(claw_target)
			_set_pose(F_CLAW_UP, cast_timer + 0.2)
		"orb":
			_show_tumor_glow(true)
			_set_pose(F_TUMOR, cast_timer + 0.2)
		"root":
			_prepare_roots()
			_set_pose(F_ROOT, cast_timer + 0.2)
		"slam":
			_show_slam_warning()
			_set_pose(F_CLAW_UP, cast_timer + 0.2)


func _update_windup(delta: float) -> void:
	cast_timer -= delta
	warning_clock += delta
	var blink := fmod(warning_clock, 0.24) < 0.12
	if warning != null and is_instance_valid(warning):
		warning.visible = blink
	for w in root_warnings:
		if is_instance_valid(w):
			w.visible = blink
	if cast_timer <= 0.0:
		_execute_skill()


func _execute_skill() -> void:
	var finished := skill
	_clear_warnings()
	match finished:
		"claw":
			_do_claw()
		"orb":
			_do_orb()
		"root":
			_do_roots()
		"slam":
			_do_slam()
	cooldowns[finished] = float(COOLDOWN[finished])
	if finished == "orb":
		_show_tumor_glow(false)
	state = "recover"
	recover_timer = 0.55
	if finished == "claw":
		_set_pose(F_CLAW_SLAM, 0.25)
	else:
		_set_pose(F_IDLE_A, 0.15)
	skill = ""


func _do_claw() -> void:
	_spawn_impact(claw_target)
	if player != null:
		var d: Vector2 = player.global_position - claw_target
		if absf(d.x) <= claw_radius and absf(d.y) <= claw_radius:
			player.call("take_damage", claw_damage, true)


func _do_orb() -> void:
	if player == null:
		return
	var spawn: Vector2 = global_position + Vector2(0, -105)
	var orb := ORB_SCENE.instantiate() as Node2D
	orb.set("direction", (_player_center() - spawn).normalized())
	orb.set("damage", orb_damage)
	orb.global_position = spawn
	get_parent().add_child(orb)
	orb.global_position = spawn


func _do_slam() -> void:
	_spawn_impact(global_position + Vector2(0, -10))
	if player != null:
		var offset: Vector2 = player.global_position - global_position
		if offset.length() <= slam_radius:
			var dir := offset.normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.DOWN
			player.call("take_damage", slam_damage, true)
			player.call("apply_knockback", dir, slam_knockback, 0.28)
	Sfx.play("enemy_strike", 0.7, 0.0)


func _do_roots() -> void:
	for p in root_targets:
		var spike := SPIKE_SCENE.instantiate() as Node2D
		spike.set("damage", root_damage)
		spike.global_position = p
		get_parent().add_child(spike)
		spike.global_position = p
	root_targets.clear()


func _prepare_roots() -> void:
	_clear_warnings()
	root_targets.clear()
	var to_player: Vector2 = (_player_center() - global_position).normalized()
	var base_angle: float = to_player.angle()
	for i in range(5):
		var a: float = base_angle + deg_to_rad(-80.0 + i * 40.0)
		var r: float = randf_range(55.0, 105.0)
		root_targets.append(global_position + Vector2(cos(a), sin(a)) * r)
	var player_radii := [0.0, 32.0, 56.0]
	for i in range(3):
		var a: float = randf() * TAU
		var r: float = player_radii[i]
		root_targets.append(_player_center() + Vector2(cos(a), sin(a)) * r)
	var ground := _ground_root()
	for i in range(root_targets.size()):
		var p: Vector2 = root_targets[i]
		p.x = clampf(p.x, 275.0, 648.0)
		p.y = clampf(p.y, 1300.0, 1448.0)
		root_targets[i] = p
		var w := Sprite2D.new()
		w.texture = WARNING_LINE
		w.rotation = base_angle + PI * 0.5
		w.z_index = 2
		ground.add_child(w)
		w.global_position = p
		root_warnings.append(w)


func _show_slam_warning() -> void:
	_clear_warnings()
	var ground := _ground_root()
	warning = Sprite2D.new()
	warning.texture = WARNING_SQUARE
	warning.scale = Vector2(4.4, 4.4)
	warning.z_index = 2
	ground.add_child(warning)
	warning.global_position = global_position + Vector2(0, -10)


func _show_square_warning(pos: Vector2) -> void:
	_clear_warnings()
	var ground := _ground_root()
	warning = Sprite2D.new()
	warning.texture = WARNING_SQUARE
	warning.z_index = 2
	ground.add_child(warning)
	warning.global_position = pos


func _spawn_impact(pos: Vector2) -> void:
	var ground := _ground_root()
	var fx := Sprite2D.new()
	fx.texture = CLAW_IMPACT
	fx.z_index = 2
	ground.add_child(fx)
	fx.global_position = pos
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(fx, "modulate:a", 0.0, 0.35)
	t.tween_property(fx, "scale", Vector2(1.4, 1.4), 0.35)
	t.chain().tween_callback(fx.queue_free)


func _ground_root() -> Node:
	var n := get_node_or_null("../../Layers")
	if n != null:
		return n
	return get_parent()


func _clear_warnings() -> void:
	if warning != null and is_instance_valid(warning):
		warning.queue_free()
	warning = null
	for w in root_warnings:
		if is_instance_valid(w):
			w.queue_free()
	root_warnings.clear()


func _clear_effects() -> void:
	for n in get_tree().get_nodes_in_group("BossEffects"):
		if is_instance_valid(n):
			n.queue_free()


func _show_tumor_glow(on: bool) -> void:
	glow2.visible = on
	if on:
		glow2.modulate.a = 1.0
		glow2.scale = Vector2(0.8, 0.8)
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(glow2, "scale", Vector2(1.9, 1.9), 0.7)
		t.tween_property(glow2, "modulate:a", 1.0, 0.2)


func _hide_glows() -> void:
	for g in [glow1, glow2, glow3]:
		g.visible = false


func _face_player() -> void:
	if player == null:
		return
	var d: Vector2 = player.global_position - global_position
	if absf(d.x) > absf(d.y):
		direction_row = ROW_RIGHT if d.x > 0.0 else ROW_LEFT
	else:
		direction_row = ROW_FRONT if d.y > 0.0 else ROW_BACK


func _set_frame(col: int) -> void:
	sprite.frame = direction_row * COLS + col


func _set_pose(col: int, time: float) -> void:
	pose_col = col
	pose_timer = time
	_set_frame(col)


func _update_anim(delta: float) -> void:
	if pose_timer > 0.0:
		pose_timer -= delta
		if pose_timer <= 0.0:
			pose_col = -1
	if pose_col >= 0:
		_set_frame(pose_col)
		return
	anim_timer += delta
	if moving:
		if anim_timer >= 0.18:
			anim_timer = 0.0
			walk_frame = (walk_frame + 1) % 4
		_set_frame(F_WALK + walk_frame)
	else:
		if anim_timer >= 0.7:
			anim_timer = 0.0
			walk_frame = 0
			if sprite.frame - direction_row * COLS == F_IDLE_A:
				_set_frame(F_IDLE_B)
			else:
				_set_frame(F_IDLE_A)


func get_hit_boxes() -> Array:
	var base := global_position
	return [
		{"rect": Rect2(base + Vector2(-30, -178), Vector2(60, 54)), "multiplier": 1.35, "region": "head"},
		{"rect": Rect2(base + Vector2(-44, -124), Vector2(88, 76)), "multiplier": 1.0, "region": "body"},
		{"rect": Rect2(base + Vector2(-40, -48), Vector2(80, 48)), "multiplier": 0.75, "region": "feet"},
	]


func get_hit_info(attacker_pos: Vector2, dir: Vector2, reach: float) -> Dictionary:
	return CombatHit.melee(get_hit_boxes(), attacker_pos, dir, reach)


func hit_test_projectile(point: Vector2, radius: float) -> Dictionary:
	return CombatHit.point(get_hit_boxes(), point, radius)


func is_hit_by_attack(attacker_pos: Vector2, dir: Vector2, reach: float) -> bool:
	return bool(get_hit_info(attacker_pos, dir, reach).get("hit", false))


func take_damage(amount: int) -> void:
	if dead:
		return
	if not active and _player_on_island():
		_activate()
	health = maxi(health - amount, 0)
	_update_ui()
	Global.spawn_damage_number(global_position + Vector2(randf_range(-10.0, 10.0), -108.0), amount)
	if health <= 0:
		_die()
		return
	sprite.modulate = Color(1.0, 0.55, 0.55)
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	dead = true
	active = false
	Global.boss_defeated = true
	Global.enemy_killed.emit()
	SaveGame.save_game("白桦林地")
	state = "dying"
	remove_from_group("Enemies")
	_clear_warnings()
	_clear_effects()
	_hide_ui()
	velocity = Vector2.ZERO
	health = 0
	for g in [glow1, glow2, glow3]:
		g.visible = true
		g.modulate.a = 1.0
	death_fog.emitting = true

	var tremble := create_tween()
	for i in range(12):
		tremble.tween_property(sprite, "position:x", 2.0 if i % 2 == 0 else -2.0, 0.05)
	tremble.tween_property(sprite, "position:x", 0.0, 0.08)

	for i in range(3):
		var g: Sprite2D = [glow1, glow2, glow3][i]
		var tg := create_tween()
		tg.tween_interval(0.6 + i * 0.7)
		tg.tween_property(g, "modulate:a", 0.0, 0.7)

	var ts := create_tween()
	ts.tween_interval(1.8)
	ts.tween_callback(func() -> void: _set_frame(F_DEATH1))
	ts.tween_interval(1.2)
	ts.tween_callback(func() -> void: _set_frame(F_DEATH2))
	ts.tween_interval(1.2)
	ts.tween_callback(func() -> void: _set_frame(F_DEATH3))
	ts.tween_interval(0.7)
	ts.tween_callback(_finish_death)


func _finish_death() -> void:
	death_fog.emitting = false
	_hide_glows()
	if arena_curtain != null and arena_curtain.has_method("lift"):
		arena_curtain.call("lift")
	# 胜利改由白桦林地的誓火石碑触发


func _on_player_died() -> void:
	_reset_fight()


func _reset_fight() -> void:
	if dead:
		return
	active = false
	state = "idle"
	health = max_health
	cooldowns = {"claw": 0.0, "orb": 0.0, "root": 0.0, "slam": 0.0}
	decision_timer = 1.0
	pose_col = -1
	pose_timer = 0.0
	_clear_warnings()
	_clear_effects()
	_hide_glows()
	_hide_ui()
	_update_ui()
	if arena_curtain != null and arena_curtain.has_method("lift_immediate"):
		arena_curtain.call("lift_immediate")


# ---------------- boss UI ----------------

func _build_ui() -> void:
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 1
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)
	ui_panel = Panel.new()
	ui_panel.anchor_left = 0.5
	ui_panel.anchor_right = 0.5
	ui_panel.anchor_top = 0.0
	ui_panel.anchor_bottom = 0.0
	ui_panel.offset_left = -120.0
	ui_panel.offset_right = 120.0
	ui_panel.offset_top = 6.0
	ui_panel.offset_bottom = 40.0
	ui_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.035, 0.06, 0.92)
	style.border_color = Color(0.55, 0.3, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	ui_panel.add_theme_stylebox_override("panel", style)
	root.add_child(ui_panel)
	var name_label := Label.new()
	name_label.text = "裂牙格鲁姆"
	name_label.position = Vector2(0, 1)
	name_label.size = Vector2(240, 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", ui_font)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(0.88, 0.7, 1.0))
	ui_panel.add_child(name_label)
	ui_bar = ProgressBar.new()
	ui_bar.position = Vector2(8, 18)
	ui_bar.size = Vector2(224, 9)
	ui_bar.max_value = max_health
	ui_bar.value = health
	ui_bar.show_percentage = false
	ui_bar.add_theme_font_size_override("font_size", 1)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.08, 0.14, 1.0)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.56, 0.22, 0.72, 1.0)
	fill.set_corner_radius_all(2)
	ui_bar.add_theme_stylebox_override("background", bg)
	ui_bar.add_theme_stylebox_override("fill", fill)
	ui_panel.add_child(ui_bar)
	ui_layer.visible = false


func _show_ui() -> void:
	if ui_layer != null:
		ui_layer.visible = true
		_update_ui()


func _hide_ui() -> void:
	if ui_layer != null:
		ui_layer.visible = false


func _update_ui() -> void:
	if ui_bar != null:
		ui_bar.max_value = max_health
		ui_bar.value = health
