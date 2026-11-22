extends CharacterBody2D

signal died

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/prologue/prologue_projectile.tscn")
const SHEETS := {
	"mourner": preload("res://graphics/enemies/monastery/mourner_sheet.png"),
	"bone_gleaner": preload("res://graphics/enemies/monastery/bone_gleaner_sheet.png"),
	"ember_crown": preload("res://graphics/enemies/monastery/ember_crown_sheet.png"),
}
const STATS := {
	"mourner": {
		"health": 26,
		"damage": 7,
		"speed": 40.0,
		"range": 155.0,
		"cooldown": 2.1,
		"ranged": true,
		"color": Color(0.55, 0.72, 1.0),
		"size": Vector2(40, 40),
	},
	"bone_gleaner": {
		"health": 42,
		"damage": 10,
		"speed": 62.0,
		"range": 27.0,
		"cooldown": 1.25,
		"ranged": false,
		"color": Color(1.0, 0.68, 0.42),
		"size": Vector2(48, 40),
	},
	"ember_crown": {
		"health": 82,
		"damage": 14,
		"speed": 34.0,
		"range": 170.0,
		"cooldown": 2.4,
		"ranged": true,
		"color": Color(1.0, 0.42, 0.18),
		"size": Vector2(48, 48),
	},
}

@export var enemy_kind := "mourner"

var max_health := 26
var health := 26
var damage := 7
var move_speed := 40.0
var attack_range := 155.0
var attack_cooldown := 2.1
var is_ranged := true
var projectile_color := Color(0.55, 0.72, 1.0)
var frame_size := Vector2(40, 40)
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


func configure(kind: String) -> void:
	enemy_kind = kind


func _ready() -> void:
	add_to_group("Enemies")
	player = get_tree().get_first_node_in_group("Player") as Node2D
	nav = get_tree().get_first_node_in_group("MonasteryNav")
	collision_layer = 4
	collision_mask = 3
	_build_visual()
	_configure_stats()
	health = max_health


func _build_visual() -> void:
	var sheet: Texture2D = SHEETS.get(enemy_kind, SHEETS["mourner"])
	frame_size = sheet.get_size() / Vector2(3, 2)
	sprite = Sprite2D.new()
	sprite.texture = sheet
	sprite.hframes = 3
	sprite.vframes = 2
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, 3.0 - frame_size.y * 0.5)
	sprite.z_index = 3
	add_child(sprite)

	body_shape = CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 8.0
	capsule.height = 16.0
	body_shape.shape = capsule
	body_shape.position = Vector2(0, -9)
	add_child(body_shape)
	if enemy_kind == "ember_crown":
		capsule.radius = 11.0
		capsule.height = 22.0
		body_shape.position = Vector2(0, -12)
		scale = Vector2(1.12, 1.12)


func _configure_stats() -> void:
	var stats: Dictionary = STATS.get(enemy_kind, STATS["mourner"])
	max_health = int(stats["health"])
	damage = int(stats["damage"])
	move_speed = float(stats["speed"])
	attack_range = float(stats["range"])
	attack_cooldown = float(stats["cooldown"])
	is_ranged = bool(stats["ranged"])
	projectile_color = stats["color"]
	base_tint = Color.WHITE
	sprite.modulate = base_tint


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null or bool(player.get("dead")):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	cooldown_timer = maxf(0.0, cooldown_timer - delta)
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
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	facing_right = to_player.x >= 0.0
	var has_los := true
	if nav != null and is_instance_valid(nav):
		has_los = bool(nav.call("has_line_of_sight", global_position, player.global_position))
	if is_ranged:
		if has_los and distance <= attack_range:
			velocity = Vector2.ZERO
			if cooldown_timer <= 0.0:
				_start_attack()
				_update_frame(2)
			else:
				_update_frame(0)
			move_and_slide()
			return
	else:
		if has_los and distance <= attack_range + 4.0:
			velocity = Vector2.ZERO
			if cooldown_timer <= 0.0:
				_start_attack()
				_update_frame(2)
			else:
				_update_frame(0)
			move_and_slide()
			return
	_move_with_nav(delta, to_player)
	move_and_slide()


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
	attack_windup = 0.42 if enemy_kind != "ember_crown" else 0.65
	cooldown_timer = attack_cooldown
	attack_flash = attack_windup
	Sfx.play("warn", 1.25, -12.0)


func _execute_attack() -> void:
	if player == null or bool(player.get("dead")):
		return
	var target: Vector2 = player.global_position + Vector2(0, -12)
	var origin := global_position + Vector2(0, -22)
	var dir := (target - origin).normalized()
	if is_ranged:
		var projectile := PROJECTILE_SCENE.instantiate() as Node2D
		if projectile != null:
			get_parent().add_child(projectile)
			projectile.global_position = origin
			projectile.call("setup_enemy_target", dir, 120.0 if enemy_kind == "mourner" else 145.0, damage, target)
			projectile.set("projectile_color", projectile_color)
		Sfx.play("enemy_strike", 0.95, -10.0)
	else:
		if global_position.distance_to(player.global_position) <= attack_range + 14.0:
			player.call("take_damage", damage)
		Sfx.play("enemy_strike", 1.05, -8.0)


func _update_frame(column: int) -> void:
	if sprite == null:
		return
	var row := 1 if facing_right else 0
	sprite.frame = row * 3 + clampi(column, 0, 2)


func get_hit_boxes() -> Array:
	var top := global_position.y + 3.0 - frame_size.y
	return [
		{
			"rect": Rect2(global_position.x - frame_size.x * 0.42, top, frame_size.x * 0.84, frame_size.y - 3.0),
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
	health = maxi(health - amount, 0)
	Global.spawn_damage_number(global_position + Vector2(0, -frame_size.y * 0.75), amount)
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
	died.emit()
	Sfx.play("enemy_death", 0.95, -8.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(sprite, "rotation", 0.2, 0.35)
	tween.chain().tween_callback(queue_free)
