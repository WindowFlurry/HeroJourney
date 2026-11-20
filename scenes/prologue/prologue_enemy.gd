extends CharacterBody2D

signal died

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/prologue/prologue_projectile.tscn")
const TEX_MELEE: Texture2D = preload("res://graphics/enemies/enemy_melee.png")
const TEX_RANGED: Texture2D = preload("res://graphics/enemies/enemy_ranged.png")
const TEX_ELITE: Texture2D = preload("res://graphics/enemies/enemy_elite.png")

const NORMAL_STATS := {
	"melee": {"health": 22, "damage": 8, "speed": 48.0, "range": 18.0, "tint": Color(1.0, 0.58, 0.28)},
	"ranged": {"health": 16, "damage": 7, "speed": 38.0, "range": 132.0, "tint": Color(1.0, 0.38, 0.2)},
	"elite": {"health": 46, "damage": 11, "speed": 44.0, "range": 23.0, "tint": Color(0.95, 0.24, 0.16)},
}

@export var enemy_kind := "melee"
@export var max_health := 22
@export var move_speed := 48.0
@export var attack_damage := 8
@export var attack_range := 18.0

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


func configure(kind: String) -> void:
	enemy_kind = kind


func _ready() -> void:
	add_to_group("Enemies")
	player = get_tree().get_first_node_in_group("Player") as Node2D
	collision_layer = 4
	collision_mask = 3
	_build_visual()
	_configure_stats()
	health = max_health


func _build_visual() -> void:
	sprite = Sprite2D.new()
	sprite.hframes = 26
	sprite.vframes = 4
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = TEX_ELITE if enemy_kind == "elite" else (
		TEX_RANGED if enemy_kind == "ranged" else TEX_MELEE
	)
	sprite.position = Vector2(0, -18)
	sprite.scale = Vector2(1.4, 1.4)
	sprite.frame = 0
	add_child(sprite)

	body_shape = CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 7.0
	capsule.height = 16.0
	body_shape.shape = capsule
	body_shape.position = Vector2(0, -9)
	add_child(body_shape)


func _configure_stats() -> void:
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

	_process_normal(delta)
	_update_animation(delta)
	move_and_slide()


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


func _update_animation(delta: float) -> void:
	if sprite == null:
		return
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 3 if facing.x > 0.0 else 2
	elif facing.y < 0.0:
		row = 1
	var column := 2 + (int(walk_clock * 7.0) % 4) if velocity.length() > 1.0 else 0
	sprite.frame = row * 26 + column


func is_hit_by_attack(attacker_pos: Vector2, dir: Vector2, reach: float) -> bool:
	var center := global_position + Vector2(0, -11)
	var extents := Vector2(9, 12)
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
	Global.spawn_damage_number(global_position + Vector2(0, -28), amount)
	var tween := create_tween()
	sprite.modulate = Color.WHITE
	tween.tween_property(sprite, "modulate", base_tint, 0.13)
	if health <= 0:
		_die()


func apply_stagger(duration: float) -> void:
	attack_cooldown = maxf(attack_cooldown, duration)
	windup_timer = 0.0


func _die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	remove_from_group("Enemies")
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	Sfx.play("enemy_death", 1.05, -8.0)
	died.emit()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_property(sprite, "rotation", 0.18, 0.25)
	tween.chain().tween_callback(queue_free)


func _cardinal(value: Vector2) -> Vector2:
	if value == Vector2.ZERO:
		return facing
	if absf(value.x) > absf(value.y):
		return Vector2(signf(value.x), 0.0)
	return Vector2(0.0, signf(value.y))
