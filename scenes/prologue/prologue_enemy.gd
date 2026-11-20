extends CharacterBody2D

signal died
signal boss_health_changed(current: int, maximum: int)

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/prologue/prologue_projectile.tscn")
const TEX_MELEE: Texture2D = preload("res://graphics/enemies/enemy_melee.png")
const TEX_RANGED: Texture2D = preload("res://graphics/enemies/enemy_ranged.png")
const TEX_ELITE: Texture2D = preload("res://graphics/enemies/enemy_elite.png")
const TEX_BOSS: Texture2D = preload("res://graphics/boss/boss_sheet.png")

const NORMAL_STATS := {
	"melee": {"health": 22, "damage": 8, "speed": 48.0, "range": 18.0, "tint": Color(1.0, 0.58, 0.28)},
	"ranged": {"health": 16, "damage": 7, "speed": 38.0, "range": 132.0, "tint": Color(1.0, 0.38, 0.2)},
	"elite": {"health": 46, "damage": 11, "speed": 44.0, "range": 23.0, "tint": Color(0.95, 0.24, 0.16)},
}

@export var enemy_kind := "melee"
@export var is_boss := false
@export var max_health := 22
@export var move_speed := 48.0
@export var attack_damage := 8
@export var attack_range := 18.0
@export var arena_rect := Rect2(154, 76, 356, 123)

var health := 22
var dead := false
var player: Node2D
var sprite: Sprite2D
var body_shape: CollisionShape2D
var base_tint := Color.WHITE
var attack_cooldown := 0.6
var windup_timer := 0.0
var facing := Vector2.DOWN
var walk_clock := 0.0
var move_frame := 0
var boss_busy := false
var boss_attack_index := 0
var boss_cycle_timer := 1.2
var warning_visual: Node2D
var hp_fill: ColorRect


func configure(kind: String) -> void:
	enemy_kind = kind
	is_boss = kind == "boss"


func _ready() -> void:
	add_to_group("Enemies")
	player = get_tree().get_first_node_in_group("Player") as Node2D
	collision_layer = 4
	collision_mask = 3
	_build_visual()
	_configure_stats()
	health = max_health
	_update_boss_health()


func _build_visual() -> void:
	sprite = Sprite2D.new()
	sprite.hframes = 13 if is_boss else 26
	sprite.vframes = 4
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = TEX_BOSS if is_boss else (
		TEX_ELITE if enemy_kind == "elite" else (
			TEX_RANGED if enemy_kind == "ranged" else TEX_MELEE
		)
	)
	sprite.position = Vector2(0, -72) if is_boss else Vector2(0, -18)
	sprite.scale = Vector2(0.94, 0.94) if is_boss else Vector2(1.4, 1.4)
	sprite.frame = 0
	add_child(sprite)

	body_shape = CollisionShape2D.new()
	if is_boss:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(42, 52)
		body_shape.shape = rect
		body_shape.position = Vector2(0, -38)
	else:
		var capsule := CapsuleShape2D.new()
		capsule.radius = 7.0
		capsule.height = 16.0
		body_shape.shape = capsule
		body_shape.position = Vector2(0, -9)
	add_child(body_shape)

	if is_boss:
		var bar := ColorRect.new()
		bar.position = Vector2(-25, -149)
		bar.size = Vector2(50, 4)
		bar.color = Color(0.12, 0.05, 0.03, 0.9)
		add_child(bar)
		hp_fill = ColorRect.new()
		hp_fill.position = Vector2(-24, -148)
		hp_fill.size = Vector2(48, 2)
		hp_fill.color = Color(0.92, 0.25, 0.12)
		add_child(hp_fill)


func _configure_stats() -> void:
	if is_boss:
		max_health = 160
		move_speed = 31.0
		attack_damage = 16
		attack_range = 72.0
		base_tint = Color(1.0, 0.8, 0.72)
		sprite.modulate = base_tint
		return
	var stats: Dictionary = NORMAL_STATS.get(enemy_kind, NORMAL_STATS["melee"])
	max_health = int(stats["health"])
	attack_damage = int(stats["damage"])
	move_speed = float(stats["speed"])
	attack_range = float(stats["range"])
	base_tint = stats["tint"]
	sprite.modulate = base_tint
	if enemy_kind == "elite":
		sprite.scale = Vector2(1.75, 1.75)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null or bool(player.get("dead")):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if windup_timer > 0.0:
		windup_timer -= delta
		velocity = Vector2.ZERO
		sprite.modulate = Color(1.0, 0.35, 0.2) if fmod(windup_timer, 0.18) < 0.09 else base_tint
		if windup_timer <= 0.0:
			sprite.modulate = base_tint
			_execute_normal_attack()
		move_and_slide()
		return

	if is_boss:
		_process_boss(delta)
	else:
		_process_normal(delta)
	_update_animation(delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, arena_rect.position.x, arena_rect.end.x)
	global_position.y = clampf(global_position.y, arena_rect.position.y, arena_rect.end.y)


func _process_normal(delta: float) -> void:
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	facing = _cardinal(to_player)
	if distance <= attack_range:
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0:
			_start_normal_windup()
		return

	var desired := to_player.normalized()
	if enemy_kind == "ranged" and distance < 78.0:
		desired = -desired
	elif enemy_kind == "ranged" and distance < attack_range - 10.0:
		desired = desired.orthogonal() * (1.0 if int(Time.get_ticks_msec() / 1500.0) % 2 == 0 else -1.0)
	velocity = desired * move_speed
	walk_clock += delta


func _start_normal_windup() -> void:
	windup_timer = 0.56 if enemy_kind == "elite" else 0.34
	attack_cooldown = 1.35 if enemy_kind == "elite" else (1.25 if enemy_kind == "ranged" else 0.9)
	sprite.modulate = Color(1.0, 0.3, 0.16)
	Sfx.play("warn", 1.35, -12.0)


func _execute_normal_attack() -> void:
	if enemy_kind == "ranged":
		if player != null:
			var target: Vector2 = player.global_position + Vector2(0, -12)
			var origin := global_position + Vector2(0, -22)
			var dir := (target - origin).normalized()
			_spawn_enemy_projectile(dir, target)
		return
	if player != null and global_position.distance_to(player.global_position) <= attack_range + 12.0:
		player.call("take_damage", attack_damage)
	Sfx.play("enemy_strike", 1.1, -8.0)


func _spawn_enemy_projectile(dir: Vector2, target: Vector2) -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as Node2D
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(0, -22)
	projectile.call("setup_enemy_target", dir, 118.0, attack_damage, target)


func _process_boss(delta: float) -> void:
	if boss_busy:
		velocity = Vector2.ZERO
		_update_animation(delta)
		return
	boss_cycle_timer -= delta
	var to_player := player.global_position - global_position
	facing = _cardinal(to_player)
	if to_player.length() > 98.0:
		velocity = to_player.normalized() * move_speed
		walk_clock += delta
	else:
		velocity = Vector2.ZERO
	if boss_cycle_timer <= 0.0:
		_start_boss_attack()


func _start_boss_attack() -> void:
	if boss_busy or dead or player == null:
		return
	boss_busy = true
	velocity = Vector2.ZERO
	var attacks := ["charge", "fireball", "wing"]
	var chosen: String = str(attacks[boss_attack_index % attacks.size()])
	boss_attack_index += 1
	match chosen:
		"charge":
			await _boss_charge()
		"fireball":
			await _boss_fireball()
		_:
			await _boss_wing()
	if dead:
		return
	var recovery := 0.9 if health > max_health / 2 else 0.65
	await get_tree().create_timer(recovery).timeout
	if dead:
		return
	boss_busy = false
	var haste := 1.0 if health > max_health / 2 else 0.85
	boss_cycle_timer = 0.75 * haste


func _boss_charge() -> void:
	if player == null:
		return
	var origin := global_position
	var target: Vector2 = player.global_position
	var dir := (target - origin).normalized()
	facing = _cardinal(dir)
	var length := minf(origin.distance_to(target) + 70.0, 170.0)
	var warning := Polygon2D.new()
	warning.polygon = PackedVector2Array([
		Vector2(0, -9), Vector2(length, -9), Vector2(length, 9), Vector2(0, 9)
	])
	warning.color = Color(1.0, 0.18, 0.06, 0.34)
	warning.rotation = dir.angle()
	warning.z_index = 1
	get_parent().add_child(warning)
	warning.global_position = origin + Vector2(0, -10)
	warning_visual = warning
	_set_boss_frame(6)
	Sfx.play("warn", 0.72)
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(warning):
		return
	warning.queue_free()
	warning_visual = null
	if dead or player == null:
		return
	var start := global_position + Vector2(0, -10)
	var end := start + dir * length
	var tween := create_tween()
	tween.tween_property(self, "global_position", global_position + dir * length, 0.3)
	await tween.finished
	if player != null:
		var closest := Geometry2D.get_closest_point_to_segment(player.global_position, start, end)
		if closest.distance_to(player.global_position) <= 22.0:
			player.call("take_damage", 18)
	Sfx.play("enemy_strike", 0.72, -2.0)
	_set_boss_frame(0)


func _boss_fireball() -> void:
	if player == null:
		return
	_set_boss_frame(8)
	var glow := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 20:
		points.append(Vector2.from_angle(TAU * i / 20.0) * 10.0)
	glow.polygon = points
	glow.color = Color(1.0, 0.28, 0.05, 0.38)
	glow.z_index = 3
	add_child(glow)
	glow.position = Vector2(0, -92)
	var tween := glow.create_tween()
	tween.set_parallel(true)
	tween.tween_property(glow, "scale", Vector2(2.2, 2.2), 0.5)
	tween.tween_property(glow, "modulate:a", 0.1, 0.5)
	Sfx.play("warn", 0.9, -4.0)
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(glow):
		glow.queue_free()
	if dead or player == null:
		return
	var origin := global_position + Vector2(0, -92)
	var target: Vector2 = player.global_position + Vector2(0, -12)
	var projectile := PROJECTILE_SCENE.instantiate() as Node2D
	if projectile != null:
		get_parent().add_child(projectile)
		projectile.global_position = origin
		projectile.call("setup_enemy_target", (target - origin).normalized(), 112.0, 15, target)
	_set_boss_frame(0)


func _boss_wing() -> void:
	var warning := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 40:
		points.append(Vector2.from_angle(TAU * i / 40.0) * 82.0)
	warning.polygon = points
	warning.color = Color(1.0, 0.2, 0.05, 0.28)
	warning.z_index = 1
	get_parent().add_child(warning)
	warning.global_position = global_position + Vector2(0, -10)
	warning_visual = warning
	_set_boss_frame(7)
	Sfx.play("warn", 0.62, -2.0)
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(warning):
		warning.queue_free()
	warning_visual = null
	if dead or player == null:
		return
	if player.global_position.distance_to(global_position) <= 82.0:
		player.call("take_damage", 7)
	Sfx.play("enemy_strike", 0.62, 0.0)
	_set_boss_frame(0)


func _set_boss_frame(column: int) -> void:
	if sprite != null:
		var row := 0
		if absf(facing.x) > absf(facing.y):
			row = 3 if facing.x > 0.0 else 2
		elif facing.y < 0.0:
			row = 1
		sprite.frame = row * 13 + column


func _update_animation(delta: float) -> void:
	if sprite == null:
		return
	if is_boss:
		if not boss_busy:
			move_frame = int(walk_clock * 6.0) % 4
			_set_boss_frame(2 + move_frame if velocity.length() > 1.0 else 0)
		return
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 3 if facing.x > 0.0 else 2
	elif facing.y < 0.0:
		row = 1
	var column := 2 + (int(walk_clock * 7.0) % 4) if velocity.length() > 1.0 else 0
	sprite.frame = row * 26 + column


func is_hit_by_attack(attacker_pos: Vector2, dir: Vector2, reach: float) -> bool:
	var center := global_position + (Vector2(0, -66) if is_boss else Vector2(0, -11))
	var extents := Vector2(26, 46) if is_boss else Vector2(9, 12)
	var local := attacker_pos - center
	if absf(local.x) <= extents.x and absf(local.y) <= extents.y:
		return true
	var closest := center + Vector2(clampf(local.x, -extents.x, extents.x), clampf(local.y, -extents.y, extents.y))
	var offset := closest - attacker_pos
	if offset.length() > reach:
		return false
	return offset.length() < 0.5 or offset.normalized().dot(dir) > 0.0


func take_damage(amount: int) -> void:
	take_damage_from(amount, Vector2.INF)


func take_damage_from(amount: int, _source_pos: Vector2) -> void:
	if dead:
		return
	health = maxi(health - amount, 0)
	Global.spawn_damage_number(global_position + Vector2(0, -120 if is_boss else -28), amount)
	if not is_boss:
		var tween := create_tween()
		sprite.modulate = Color.WHITE
		tween.tween_property(sprite, "modulate", base_tint, 0.13)
	_update_boss_health()
	if health <= 0:
		_die()


func apply_stagger(duration: float) -> void:
	attack_cooldown = maxf(attack_cooldown, duration)
	windup_timer = 0.0


func _update_boss_health() -> void:
	if not is_boss:
		return
	if hp_fill != null:
		hp_fill.size.x = 48.0 * float(health) / float(max_health)
	boss_health_changed.emit(health, max_health)


func _die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	remove_from_group("Enemies")
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if is_instance_valid(warning_visual):
		warning_visual.queue_free()
	Sfx.play("enemy_death", 0.72 if is_boss else 1.05, -2.0 if is_boss else -8.0)
	died.emit()
	if is_boss:
		boss_health_changed.emit(0, max_health)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.9 if is_boss else 0.25)
	tween.tween_property(sprite, "rotation", 0.18, 0.9 if is_boss else 0.25)
	tween.chain().tween_callback(queue_free)


func _cardinal(value: Vector2) -> Vector2:
	if value == Vector2.ZERO:
		return facing
	if absf(value.x) > absf(value.y):
		return Vector2(signf(value.x), 0.0)
	return Vector2(0.0, signf(value.y))

