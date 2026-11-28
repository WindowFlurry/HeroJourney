extends CharacterBody2D

signal died

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/prologue/prologue_projectile.tscn")
const ENEMY_DROPS: Script = preload("res://scenes/level/enemy_drops.gd")
const IMPACT_TEXTURE: Texture2D = preload("res://graphics/boss/claw_impact.png")
const SHEETS := {
	"ash_feather": preload("res://graphics/enemies/coast/ash_feather_sheet.png"),
	"dragonfire_digger": preload("res://graphics/enemies/coast/dragonfire_digger_sheet.png"),
	"slag_skink": preload("res://graphics/enemies/coast/slag_skink_sheet.png"),
	"ferry_strangler": preload("res://graphics/enemies/coast/ferry_strangler_sheet.png"),
	"gamehound": preload("res://graphics/enemies/coast/gamehound_sheet.png"),
	"menhir_golem": preload("res://graphics/enemies/coast/menhir_golem_sheet.png"),
	"lava_span_basilisk": preload("res://graphics/enemies/coast/lava_span_basilisk_sheet.png"),
	"cinder_falcon": preload("res://graphics/enemies/coast/cinder_falcon_sheet.png"),
}
const STATS := {
	"ash_feather": {
		"health": 32, "damage": 7, "speed": 52.0, "range": 190.0, "cooldown": 2.0,
		"ranged": true, "color": Color(0.62, 0.68, 0.74), "aggro": 210.0, "deaggro": 390.0,
		"scale": 1.0, "elite": false, "special": "",
	},
	"dragonfire_digger": {
		"health": 66, "damage": 11, "speed": 74.0, "range": 34.0, "cooldown": 1.35,
		"ranged": false, "color": Color(1.0, 0.58, 0.24), "aggro": 175.0, "deaggro": 345.0,
		"scale": 1.0, "elite": false, "special": "",
	},
	"slag_skink": {
		"health": 38, "damage": 8, "speed": 102.0, "range": 30.0, "cooldown": 1.1,
		"ranged": false, "color": Color(1.0, 0.38, 0.16), "aggro": 180.0, "deaggro": 370.0,
		"scale": 1.0, "elite": false, "special": "",
	},
	"ferry_strangler": {
		"health": 96, "damage": 13, "speed": 52.0, "range": 38.0, "cooldown": 1.7,
		"ranged": false, "color": Color(0.38, 0.64, 0.48), "aggro": 165.0, "deaggro": 330.0,
		"scale": 1.05, "elite": false, "special": "",
	},
	"gamehound": {
		"health": 34, "damage": 7, "speed": 108.0, "range": 30.0, "cooldown": 1.0,
		"ranged": false, "color": Color(0.82, 0.68, 0.48), "aggro": 195.0, "deaggro": 390.0,
		"scale": 1.0, "elite": false, "special": "",
	},
	"menhir_golem": {
		"health": 230, "damage": 18, "speed": 38.0, "range": 46.0, "cooldown": 1.9,
		"ranged": false, "color": Color(0.66, 0.64, 0.58), "aggro": 190.0, "deaggro": 380.0,
		"scale": 1.2, "elite": true, "special": "slam",
	},
	"lava_span_basilisk": {
		"health": 170, "damage": 13, "speed": 44.0, "range": 185.0, "cooldown": 1.8,
		"ranged": true, "color": Color(1.0, 0.42, 0.12), "aggro": 235.0, "deaggro": 430.0,
		"scale": 1.15, "elite": true, "special": "fan",
	},
	"cinder_falcon": {
		"health": 145, "damage": 11, "speed": 74.0, "range": 210.0, "cooldown": 1.6,
		"ranged": true, "color": Color(1.0, 0.6, 0.18), "aggro": 240.0, "deaggro": 440.0,
		"scale": 1.15, "elite": true, "special": "fan",
	},
}

@export var enemy_kind := "gamehound"

var max_health := 40
var health := 40
var damage := 8
var move_speed := 60.0
var attack_range := 32.0
var attack_cooldown := 1.2
var is_ranged := false
var projectile_color := Color(1.0, 0.5, 0.2)
var frame_size := Vector2(48, 48)
var visual_scale := 1.0
var is_elite := false
var special := ""
var base_tint := Color.WHITE
var player: Node2D
var nav: Node
var nav_path: Array[Vector2] = []
var nav_timer := 0.0
var nav_goal := Vector2.INF
var sprite: Sprite2D
var body_shape: CollisionShape2D
var dead := false
var facing_right := true
var attack_windup := 0.0
var cooldown_timer := 0.0
var walk_clock := 0.0
var attack_flash := 0.0
var aggro_range := 190.0
var deaggro_range := 380.0
var awake := false
var home := Vector2.ZERO
var idle_target := Vector2.ZERO
var idle_timer := 0.0
var retreat_timer := 0.0
var retreat_dir := Vector2.ZERO
var leash_rect := Rect2()
var pounce_cd := 0.0
var pounce_windup := 0.0
var pounce_timer := 0.0
var pounce_dir := Vector2.ZERO
var pounce_hit := false


func configure(kind: String) -> void:
	enemy_kind = kind


func _ready() -> void:
	add_to_group("Enemies")
	player = get_tree().get_first_node_in_group("Player") as Node2D
	nav = get_tree().get_first_node_in_group("CoastNav")
	collision_layer = 4
	collision_mask = 3
	home = global_position
	idle_target = home
	_build_visual()
	_configure_stats()
	health = max_health


func _build_visual() -> void:
	var sheet: Texture2D = SHEETS.get(enemy_kind, SHEETS["gamehound"])
	frame_size = sheet.get_size() / Vector2(3, 2)
	sprite = Sprite2D.new()
	sprite.texture = sheet
	sprite.hframes = 3
	sprite.vframes = 2
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(visual_scale, visual_scale)
	sprite.position = Vector2(0, 3.0 - frame_size.y * visual_scale * 0.5)
	sprite.z_index = 4
	add_child(sprite)

	body_shape = CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 8.0
	capsule.height = 16.0
	body_shape.shape = capsule
	body_shape.position = Vector2(0, -9)
	add_child(body_shape)


func _configure_stats() -> void:
	var stats: Dictionary = STATS.get(enemy_kind, STATS["gamehound"])
	max_health = int(stats["health"])
	damage = int(stats["damage"])
	move_speed = float(stats["speed"])
	attack_range = float(stats["range"])
	attack_cooldown = float(stats["cooldown"])
	is_ranged = bool(stats["ranged"])
	projectile_color = stats["color"]
	aggro_range = float(stats["aggro"])
	deaggro_range = float(stats["deaggro"])
	visual_scale = float(stats["scale"])
	is_elite = bool(stats["elite"])
	special = str(stats["special"])
	base_tint = Color.WHITE
	# 第二/第三关近战怪：少数个体速度会超过玩家疾跑
	if not is_ranged and not is_elite and randf() < 0.16:
		move_speed = maxf(move_speed * 1.55, 162.0)
		base_tint = Color(1.0, 0.78, 0.5)
	if enemy_kind == "gamehound":
		pounce_cd = 1.2
	sprite.modulate = base_tint
	sprite.scale = Vector2(visual_scale, visual_scale)
	sprite.position = Vector2(0, 3.0 - frame_size.y * visual_scale * 0.5)
	if body_shape != null:
		var capsule := body_shape.shape as CapsuleShape2D
		if capsule != null:
			capsule.radius = 8.0 * visual_scale
			capsule.height = 16.0 * visual_scale
		body_shape.position = Vector2(0, -9.0 * visual_scale)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null or bool(player.get("dead")):
		velocity = Vector2.ZERO
		_slide()
		return
	cooldown_timer = maxf(0.0, cooldown_timer - delta)
	pounce_cd = maxf(0.0, pounce_cd - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	if attack_flash > 0.0:
		sprite.modulate = Color(1.25, 1.0, 0.9)
	elif cooldown_timer <= 0.1:
		sprite.modulate = base_tint
	if attack_windup > 0.0:
		attack_windup -= delta
		velocity = Vector2.ZERO
		if attack_windup <= 0.0:
			_execute_attack()
		_update_frame(2)
		_slide()
		return

	if enemy_kind == "gamehound" and pounce_windup > 0.0:
		pounce_windup -= delta
		velocity = Vector2.ZERO
		_update_frame(2)
		if pounce_windup <= 0.0:
			pounce_dir = (player.global_position - global_position).normalized()
			pounce_timer = 0.32
			pounce_hit = false
			Sfx.play("enemy_strike", 0.9, -6.0)
		_slide()
		return

	if enemy_kind == "gamehound" and pounce_timer > 0.0:
		pounce_timer -= delta
		velocity = pounce_dir * 280.0
		if not pounce_hit and global_position.distance_to(player.global_position) <= 38.0:
			pounce_hit = true
			player.call("take_damage", damage + 3)
			player.call("apply_knockback", pounce_dir, 280.0, 0.25)
		if pounce_timer <= 0.0:
			cooldown_timer = attack_cooldown * 0.8
			retreat_timer = 0.25
			retreat_dir = -pounce_dir
		_update_frame(1)
		_slide()
		return

	if retreat_timer > 0.0:
		retreat_timer -= delta
		velocity = retreat_dir * move_speed * 0.85
		facing_right = velocity.x >= 0.0
		_update_frame(1)
		_slide()
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	facing_right = to_player.x >= 0.0
	var has_los := _has_line_of_sight()
	if not awake:
		if distance <= aggro_range and has_los:
			awake = true
			Sfx.play("warn", 1.35, -18.0)
		else:
			_idle_wander(delta)
			_slide()
			return
	if distance > deaggro_range:
		awake = false
		nav_path.clear()
		nav_timer = 0.0
		_idle_wander(delta)
		_slide()
		return
	if enemy_kind == "gamehound" and pounce_cd <= 0.0 and has_los and distance > attack_range + 10.0 and distance < 150.0 and cooldown_timer <= 0.0:
		pounce_cd = 3.2
		pounce_windup = 0.45
		velocity = Vector2.ZERO
		_update_frame(2)
		Sfx.play("warn", 1.3, -12.0)
		_slide()
		return

	if is_ranged:
		if has_los and distance < 80.0:
			velocity = -to_player.normalized() * move_speed * 0.9
			facing_right = velocity.x >= 0.0
			_update_frame(1)
			_slide()
			if get_slide_collision_count() > 0 and cooldown_timer <= 0.0:
				velocity = Vector2.ZERO
				_start_attack()
				_update_frame(2)
			return
		if has_los and distance <= attack_range:
			velocity = Vector2.ZERO
			if cooldown_timer <= 0.0:
				_start_attack()
				_update_frame(2)
			else:
				_update_frame(0)
			_slide()
			return
	else:
		if has_los and distance < attack_range - 4.0:
			velocity = -to_player.normalized() * move_speed * 0.9
			facing_right = velocity.x >= 0.0
			_update_frame(1)
			_slide()
			if get_slide_collision_count() > 0 and cooldown_timer <= 0.0:
				velocity = Vector2.ZERO
				_start_attack()
				_update_frame(2)
			return
		if has_los and distance <= attack_range + 6.0:
			velocity = Vector2.ZERO
			if cooldown_timer <= 0.0:
				_start_attack()
				_update_frame(2)
			else:
				velocity = -to_player.normalized() * move_speed * 0.22
				_update_frame(1)
			_slide()
			return
	_move_with_nav(delta, to_player)
	_slide()


func _has_line_of_sight() -> bool:
	if nav != null and is_instance_valid(nav):
		return bool(nav.call("has_line_of_sight", global_position, player.global_position))
	return true


func _idle_wander(delta: float) -> void:
	idle_timer -= delta
	if idle_timer <= 0.0:
		idle_timer = randf_range(2.4, 4.8)
		idle_target = home + Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, 30.0))
	var to_target := idle_target - global_position
	if to_target.length() > 6.0:
		velocity = to_target.normalized() * move_speed * 0.35
		facing_right = velocity.x >= 0.0
		walk_clock += delta
		_update_frame(1)
	else:
		velocity = Vector2.ZERO
		_update_frame(0)


func _move_with_nav(delta: float, to_player: Vector2) -> void:
	var desired := to_player.normalized()
	if nav != null and is_instance_valid(nav):
		var clear_path := bool(nav.call("has_line_of_sight", global_position, player.global_position))
		if clear_path:
			nav_path.clear()
			nav_timer = 0.0
		else:
			nav_timer -= delta
			if nav_timer <= 0.0 or nav_path.is_empty() or nav_goal.distance_to(player.global_position) > 40.0:
				var found: Array = nav.call("find_path", global_position, player.global_position)
				nav_path.clear()
				for point in found:
					nav_path.append(point)
				nav_goal = player.global_position
				nav_timer = 0.45
			while not nav_path.is_empty() and global_position.distance_to(nav_path[0]) < 10.0:
				nav_path.pop_front()
			if not nav_path.is_empty():
				desired = (nav_path[0] - global_position).normalized()
	velocity = desired * move_speed
	walk_clock += delta
	_update_frame(1 if velocity.length() > 1.0 else 0)


func _start_attack() -> void:
	attack_windup = 0.42
	if is_ranged:
		attack_windup = 0.52
	if special == "slam":
		attack_windup = 0.72
	cooldown_timer = attack_cooldown
	attack_flash = attack_windup
	Sfx.play("warn", 1.25, -12.0)


func set_leash_rect(rect: Rect2) -> void:
	leash_rect = rect


func _slide() -> void:
	move_and_slide()
	if leash_rect.size.x > 0.0 and leash_rect.size.y > 0.0:
		global_position.x = clampf(global_position.x, leash_rect.position.x, leash_rect.end.x)
		global_position.y = clampf(global_position.y, leash_rect.position.y, leash_rect.end.y)


func _execute_attack() -> void:
	if player == null or bool(player.get("dead")):
		return
	retreat_dir = (global_position - player.global_position).normalized()
	retreat_timer = 0.2 if is_ranged else 0.35
	var target: Vector2 = player.global_position + Vector2(0, -12)
	var origin := global_position + Vector2(0, -22.0 * visual_scale)
	var dir := (target - origin).normalized()
	if is_ranged:
		if special == "fan":
			for angle in [-0.16, 0.0, 0.16]:
				var shot_dir := dir.rotated(angle)
				_fire_projectile(shot_dir, 0.0, target, origin)
		else:
			_fire_projectile(dir, 0.0, target, origin)
		Sfx.play("enemy_strike", 0.95, -10.0)
	else:
		if special == "slam":
			if global_position.distance_to(player.global_position) <= attack_range + 34.0:
				player.call("take_damage", damage)
				var knock := (player.global_position - global_position).normalized()
				player.call("apply_knockback", knock, 300.0, 0.3)
			_spawn_impact(player.global_position)
			Sfx.play("enemy_strike", 0.75, -6.0)
		else:
			if global_position.distance_to(player.global_position) <= attack_range + 14.0:
				player.call("take_damage", damage)
				if is_elite:
					var knock := (player.global_position - global_position).normalized()
					player.call("apply_knockback", knock, 210.0, 0.22)
			Sfx.play("enemy_strike", 1.05, -8.0)


func _fire_projectile(dir: Vector2, _unused: float, target: Vector2, origin: Vector2) -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as Node2D
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.global_position = origin
	var aim_target := target
	if special == "fan":
		aim_target = origin + dir * maxf(origin.distance_to(target) + 40.0, 220.0)
	projectile.call("setup_enemy_target", dir, 140.0 if enemy_kind != "cinder_falcon" else 165.0, damage, aim_target)
	projectile.set("projectile_color", projectile_color)


func _spawn_impact(pos: Vector2) -> void:
	var fx := Sprite2D.new()
	fx.texture = IMPACT_TEXTURE
	fx.z_index = 3
	get_parent().add_child(fx)
	fx.global_position = pos
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fx, "modulate:a", 0.0, 0.35)
	tween.tween_property(fx, "scale", Vector2(1.6, 1.6), 0.35)
	tween.chain().tween_callback(fx.queue_free)


func _update_frame(column: int) -> void:
	if sprite == null:
		return
	var row := 1 if facing_right else 0
	sprite.frame = row * 3 + clampi(column, 0, 2)


func get_hit_boxes() -> Array:
	var top := global_position.y + 3.0 - frame_size.y * visual_scale
	return [
		{
			"rect": Rect2(
				global_position.x - frame_size.x * visual_scale * 0.42,
				top,
				frame_size.x * visual_scale * 0.84,
				frame_size.y * visual_scale - 3.0
			),
			"multiplier": 1.0,
			"region": "body",
		},
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
	awake = true
	health = maxi(health - amount, 0)
	Global.spawn_damage_number(global_position + Vector2(0, -frame_size.y * visual_scale * 0.75), amount)
	sprite.modulate = Color.WHITE
	attack_flash = 0.12
	if health <= 0:
		_die()


func _die() -> void:
	if dead:
		return
	dead = true
	remove_from_group("Enemies")
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	ENEMY_DROPS.spawn(get_parent(), global_position, 2, is_elite)
	Global.enemy_killed.emit()
	died.emit()
	Sfx.play("enemy_death", 0.95, -8.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(sprite, "rotation", 0.2, 0.35)
	tween.chain().tween_callback(queue_free)
