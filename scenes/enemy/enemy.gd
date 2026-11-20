extends CharacterBody2D

signal died

enum EnemyType { MELEE, RANGED, ELITE }

const STATS := {
	EnemyType.MELEE: {
		"health_min": 11,
		"health_max": 20,
		"damage": 8,
		"move_speed": 70.0,
		"attack_range": 18.0,
		"detect_range": 38.0,
		"attack_interval": 1.0,
		"wander_radius": 56.0,
		"wander_pause": 1.5,
		"tint": Color(0.72, 1.0, 0.72),
		"scale": 1.0,
		"projectile_speed": 0.0,
	},
	EnemyType.RANGED: {
		"health_min": 8,
		"health_max": 13,
		"damage": 6,
		"move_speed": 55.0,
		"attack_range": 110.0,
		"detect_range": 110.0,
		"retreat_distance": 60.0,
		"retreat_interval": 1.0,
		"retreat_duration": 0.3,
		"attack_interval": 1.5,
		"wander_radius": 48.0,
		"wander_pause": 2.0,
		"tint": Color(0.78, 0.68, 1.0),
		"scale": 1.0,
		"projectile_speed": 125.0,
	},
	EnemyType.ELITE: {
		"health_min": 20,
		"health_max": 30,
		"damage": 10,
		"move_speed": 62.0,
		"attack_range": 20.0,
		"detect_range": 42.0,
		"attack_interval": 1.2,
		"wander_radius": 72.0,
		"wander_pause": 1.2,
		"tint": Color(1.0, 0.55, 0.55),
		"scale": 1.25,
		"projectile_speed": 0.0,
	},
}

# 区域危险度：0 = 北（营地外围），1 = 中段，2 = 南（靠近 boss）
const TIER_TINTS := [
	Color(0.86, 1.0, 0.8),
	Color(1.0, 1.0, 1.0),
	Color(0.72, 0.36, 0.38),
]
const TIER_SCALES := [0.9, 1.0, 1.14]
const TIER_PIP_COLORS := [
	Color(0.72, 0.95, 0.55),
	Color(1.0, 0.82, 0.35),
	Color(1.0, 0.3, 0.25),
]
const TIER_PITCH := [1.12, 1.0, 0.86]

# 掉落表按区域危险度：0 = 北，1 = 中，2 = 南
const DROP_TABLE := [
	{"gland_min": 1, "gland_max": 2, "shell_chance": 0.25, "slime_chance": 0.35},
	{"gland_min": 1, "gland_max": 2, "shell_chance": 0.45, "slime_chance": 0.5},
	{"gland_min": 2, "gland_max": 3, "shell_chance": 0.7, "slime_chance": 0.7},
]

@export var enemy_type: EnemyType = EnemyType.MELEE
@export var region_tier := 1
@export var hit_aggro_time := 5.0

@onready var move_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var tool_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/ToolStateMachine/playback")
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_fill: ColorRect = $HealthBar/Fill

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemy/projectile.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/level/pickup_item.tscn")
const TEX_MELEE: Texture2D = preload("res://graphics/enemies/enemy_melee.png")
const TEX_RANGED: Texture2D = preload("res://graphics/enemies/enemy_ranged.png")
const TEX_ELITE: Texture2D = preload("res://graphics/enemies/enemy_elite.png")

var max_health: int
var health: int
var damage: int
var move_speed: float
var attack_range: float
var detect_range: float
var retreat_distance: float
var retreat_interval: float
var retreat_duration: float
var attack_interval: float
var wander_radius: float
var wander_pause: float
var projectile_speed: float
var base_tint: Color
var health_multiplier := 1.0

var player: Node2D
var spawn_position: Vector2
var wander_target: Vector2
var wander_wait := 0.0
var attack_cooldown := 0.0
var time_since_player_hit := 999.0
var permanent_aggro := false
var retreat_time := 0.0
var retreat_cooldown := 0.0
var retreat_direction := Vector2.ZERO
var facing := Vector2.DOWN
var dead := false
var stuck_time := 0.0
var last_position := Vector2.ZERO
var windup_time := 0.0
var windup_kind := ""
var strafe_sign := 0
var strafe_timer := 0.0
var aggro_timer := 0.0


func _ready() -> void:
	var stats: Dictionary = STATS[enemy_type]
	var base_health := randi_range(int(stats["health_min"]), int(stats["health_max"]))
	max_health = maxi(1, int(round(float(base_health) * health_multiplier)))
	health = max_health
	damage = int(stats["damage"])
	move_speed = float(stats["move_speed"])
	attack_range = float(stats["attack_range"])
	detect_range = float(stats["detect_range"])
	retreat_distance = float(stats.get("retreat_distance", 0.0))
	retreat_interval = float(stats.get("retreat_interval", 0.0))
	retreat_duration = float(stats.get("retreat_duration", 0.0))
	attack_interval = float(stats["attack_interval"])
	wander_radius = float(stats["wander_radius"])
	wander_pause = float(stats["wander_pause"])
	projectile_speed = float(stats["projectile_speed"])
	region_tier = clampi(region_tier, 0, 2)
	base_tint = TIER_TINTS[region_tier]
	sprite.modulate = base_tint
	sprite.scale = Vector2.ONE * float(stats["scale"]) * float(TIER_SCALES[region_tier])

	match enemy_type:
		EnemyType.MELEE:
			sprite.texture = TEX_MELEE
			$HealthBar.position.y = -26.0
		EnemyType.RANGED:
			sprite.texture = TEX_RANGED
			$HealthBar.position.y = -28.0
		EnemyType.ELITE:
			sprite.texture = TEX_ELITE
			$HealthBar.position.y = -32.0

	var body := CapsuleShape2D.new()
	match enemy_type:
		EnemyType.MELEE:
			body.radius = 6.0
			body.height = 14.0
		EnemyType.RANGED:
			body.radius = 7.0
			body.height = 16.0
		EnemyType.ELITE:
			body.radius = 8.0
			body.height = 18.0
	$CollisionShape2D.shape = body

	spawn_position = global_position
	wander_target = spawn_position
	last_position = global_position
	player = get_tree().get_first_node_in_group("Player") as Node2D
	_update_health_bar()
	_build_tier_pips()


func _build_tier_pips() -> void:
	for i in region_tier + 1:
		var pip := ColorRect.new()
		pip.size = Vector2(3, 2)
		pip.position = Vector2(-12.0 + i * 5.0, -7.0)
		pip.color = TIER_PIP_COLORS[region_tier]
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$HealthBar.add_child(pip)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as Node2D

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if aggro_timer > 0.0:
		aggro_timer -= delta
	time_since_player_hit += delta

	if windup_time > 0.0:
		windup_time -= delta
		velocity = Vector2.ZERO
		_update_animation()
		if windup_time <= 0.0:
			_execute_windup()
		move_and_slide()
		return

	if enemy_type == EnemyType.RANGED:
		_process_ranged(delta)
	else:
		_process_melee(delta)

	_apply_separation()
	_update_animation()
	move_and_slide()
	_keep_out_of_boss_island()
	_check_stuck(delta)


func _process_melee(delta: float) -> void:
	if not _has_aggro():
		_wander(delta)
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	facing = _cardinal(to_player)

	if distance <= attack_range:
		if attack_cooldown <= 0.0 and not _player_in_safe_zone():
			_start_windup("melee")
			return
		_strafe(delta, to_player)
		return

	# 冷却期间绕着玩家走，而不是贴脸站桩
	if attack_cooldown > 0.0 and distance <= attack_range + 22.0:
		_strafe(delta, to_player)
		return

	var dir := to_player.normalized()
	var next_position := global_position + dir * move_speed * delta
	if _point_in_safe_zone(next_position, 6.0):
		velocity = Vector2.ZERO
		return
	velocity = dir * move_speed


func _process_ranged(delta: float) -> void:
	if player == null:
		_wander(delta)
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var player_safe := _point_in_safe_zone(player.global_position)

	if retreat_cooldown > 0.0:
		retreat_cooldown -= delta

	if retreat_time > 0.0:
		retreat_time -= delta
		var next_position := global_position + retreat_direction * move_speed * delta
		if _point_in_safe_zone(next_position, 6.0):
			velocity = Vector2.ZERO
		else:
			velocity = retreat_direction * move_speed
		return

	if not player_safe and retreat_distance > 0.0 and distance < retreat_distance and retreat_cooldown <= 0.0:
		facing = _cardinal(to_player)
		retreat_direction = -to_player.normalized() if distance > 0.01 else Vector2.ZERO
		retreat_time = retreat_duration
		retreat_cooldown = retreat_interval
		velocity = retreat_direction * move_speed
		return

	if not player_safe and _has_aggro():
		velocity = Vector2.ZERO
		facing = _cardinal(to_player)
		if distance <= attack_range and attack_cooldown <= 0.0:
			_start_windup("ranged")
		return

	_wander(delta)


func _wander(delta: float) -> void:
	if wander_wait > 0.0:
		wander_wait -= delta
		velocity = Vector2.ZERO
		return

	if global_position.distance_to(wander_target) < 6.0:
		velocity = Vector2.ZERO
		wander_wait = randf_range(wander_pause, wander_pause * 2.0)
		wander_target = _pick_wander_target()
		return

	var dir := (wander_target - global_position).normalized()
	facing = _cardinal(dir)
	var next_position := global_position + dir * move_speed * 0.5 * delta
	if _point_in_safe_zone(next_position, 6.0):
		wander_target = _pick_wander_target()
		velocity = Vector2.ZERO
		return
	velocity = dir * move_speed * 0.5


func _pick_wander_target() -> Vector2:
	for i in 10:
		var candidate := spawn_position + Vector2.from_angle(randf() * TAU) * randf_range(8.0, wander_radius)
		if not _point_in_safe_zone(candidate, 8.0):
			return candidate
	return spawn_position


func _strafe(delta: float, to_player: Vector2) -> void:
	if strafe_timer <= 0.0:
		if strafe_sign == 0 or randf() < 0.3:
			strafe_sign = 1 if randf() < 0.5 else -1
		strafe_timer = randf_range(0.45, 0.9)
	strafe_timer -= delta

	var distance := to_player.length()
	if distance < 0.01:
		return
	var side := to_player.normalized().orthogonal() * float(strafe_sign)
	var radial := to_player.normalized() * clampf(((attack_range + 4.0) - distance) * 0.06, -0.6, 0.6)
	var move := (side + radial).normalized()
	var next_position := global_position + move * move_speed * 0.6 * delta
	if _point_in_safe_zone(next_position, 6.0):
		strafe_sign = -strafe_sign
		strafe_timer = 0.5
		velocity = Vector2.ZERO
		return
	velocity = move * move_speed * 0.6


func _apply_separation() -> void:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("Enemies"):
		if other == self:
			continue
		var node := other as Node2D
		if node == null:
			continue
		var d := global_position - node.global_position
		var dist := d.length()
		if dist > 0.01 and dist < 18.0:
			push += d.normalized() * (18.0 - dist) / 18.0
	if player != null:
		var pd := global_position - player.global_position
		var pdist := pd.length()
		if pdist > 0.01 and pdist < 14.0:
			push += pd.normalized() * (14.0 - pdist) / 14.0
	velocity += push * 70.0


func _start_windup(kind: String) -> void:
	windup_kind = kind
	windup_time = 0.45 if enemy_type == EnemyType.ELITE else 0.3
	attack_cooldown = maxf(attack_interval - windup_time, 0.1)
	velocity = Vector2.ZERO
	sprite.modulate = Color(1.0, 0.42, 0.32)


func _execute_windup() -> void:
	var kind := windup_kind
	windup_kind = ""
	sprite.modulate = base_tint
	if kind == "melee":
		_melee_attack()
	elif kind == "ranged":
		_ranged_attack()


func _melee_attack() -> void:
	_play_attack_animation()
	_play_attack_sound()
	if player != null and global_position.distance_to(player.global_position) <= attack_range + 8.0 and not _player_in_safe_zone():
		player.call("take_damage", damage)
	if player != null:
		aggro_timer = 3.0


func _ranged_attack() -> void:
	_play_attack_animation()
	_play_attack_sound()
	if player == null:
		return
	var target := player.global_position
	var distance := global_position.distance_to(target)
	var lead := clampf(distance / maxf(projectile_speed, 1.0) * 0.8, 0.0, 0.55)
	if player is CharacterBody2D:
		target += (player as CharacterBody2D).velocity * lead
	var dir := (target - global_position).normalized()
	var dirs: Array[Vector2] = [dir]
	# 偶尔来一次三连扇形射击，增加变化
	if randf() < 0.3:
		dirs = [dir.rotated(-0.16), dir, dir.rotated(0.16)]
	for shot_dir in dirs:
		var projectile := PROJECTILE_SCENE.instantiate() as Node2D
		if projectile == null:
			continue
		projectile.global_position = global_position + shot_dir * 14.0
		get_parent().add_child(projectile)
		projectile.call("setup", shot_dir, projectile_speed, damage)


func _play_attack_animation() -> void:
	$AnimationTree.set("parameters/ToolStateMachine/sword/blend_position", facing)
	tool_state_machine.travel("sword")
	$AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _play_attack_sound() -> void:
	if player != null and global_position.distance_to(player.global_position) > 360.0:
		return
	Sfx.play("enemy_strike", float(TIER_PITCH[region_tier]), -9.0)


func apply_stagger(duration: float) -> void:
	windup_time = 0.0
	attack_cooldown = maxf(attack_cooldown, duration)
	sprite.modulate = Color(0.7, 0.8, 1.0)
	var t := create_tween()
	t.tween_property(sprite, "modulate", base_tint, 0.25)


func take_damage(amount: int) -> void:
	take_damage_from(amount, Vector2.INF)


func take_damage_from(amount: int, _source_pos: Vector2) -> void:
	if dead:
		return
	health = maxi(health - amount, 0)
	time_since_player_hit = 0.0
	aggro_timer = 5.0
	if enemy_type == EnemyType.ELITE:
		permanent_aggro = true
	_update_health_bar()
	_flash()
	Global.spawn_damage_number(global_position + Vector2(0, -20), amount)
	if health <= 0:
		_die()


func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	if player == null or global_position.distance_to(player.global_position) <= 420.0:
		Sfx.play("enemy_death", float(TIER_PITCH[region_tier]) * 0.92, -6.0)
	remove_from_group("Enemies")
	$CollisionShape2D.set_deferred("disabled", true)
	_spawn_drops()
	died.emit()
	Global.enemy_killed.emit()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)


func _spawn_drops() -> void:
	var cfg: Dictionary = DROP_TABLE[clampi(region_tier, 0, 2)]
	var drops: Array[String] = []

	var glands := randi_range(int(cfg["gland_min"]), int(cfg["gland_max"]))
	if enemy_type == EnemyType.ELITE:
		glands += 2
	for i in glands:
		drops.append("gland")

	var shell_chance := float(cfg["shell_chance"])
	var slime_chance := float(cfg["slime_chance"])
	if enemy_type == EnemyType.ELITE:
		shell_chance = 1.0
		slime_chance = minf(slime_chance + 0.3, 1.0)
	elif enemy_type == EnemyType.RANGED:
		shell_chance = minf(shell_chance + 0.1, 1.0)
	if randf() < shell_chance:
		drops.append("shell")
		# 中、南段的怪有几率多掉一个岩甲碎片
		if region_tier >= 1 and randf() < shell_chance * 0.35:
			drops.append("shell")
	if randf() < slime_chance:
		drops.append("slime")
		if region_tier >= 2 and randf() < slime_chance * 0.4:
			drops.append("slime")

	var parent := get_parent()
	if parent == null:
		return
	for i in drops.size():
		var item := PICKUP_SCENE.instantiate()
		var angle := TAU * float(i) / float(drops.size())
		var target := global_position + Vector2(cos(angle), sin(angle)) * 9.0
		var drop_pos := Global.find_reachable_position(target, 24.0)
		if not is_finite(drop_pos.x):
			drop_pos = Global.find_reachable_position(global_position, 24.0)
		if not is_finite(drop_pos.x):
			item.free()
			continue
		parent.add_child(item)
		item.global_position = drop_pos
		match drops[i]:
			"gland":
				item.call("setup", "gland", "龙兽鳞片", Color(1.0, 0.22, 0.22, 1.0))
			"shell":
				item.call("setup", "shell", "岩甲碎片", Color(0.78, 0.78, 0.82, 1.0))
			"slime":
				item.call("setup", "slime", "灼热灰烬", Color(0.96, 0.98, 1.0, 1.0))


func _flash() -> void:
	sprite.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", base_tint, 0.15)


func _update_health_bar() -> void:
	if health_fill == null:
		return
	var ratio := float(health) / float(max_health)
	health_fill.offset_right = -12.0 + 24.0 * ratio


func _update_animation() -> void:
	if velocity.length() > 1.0:
		var dir := _cardinal(velocity)
		move_state_machine.travel("move")
		$AnimationTree.set("parameters/MoveStateMachine/move/blend_position", dir)
		$AnimationTree.set("parameters/MoveStateMachine/idle/blend_position", dir)
		$AnimationTree.set("parameters/ToolStateMachine/sword/blend_position", dir)
	else:
		move_state_machine.travel("idle")


func _keep_out_of_boss_island() -> void:
	# 普通怪不能进入 Boss 岛（桥可以让玩家通过，但怪只能在桥外停下）
	if global_position.y > 1300.0 and global_position.x > 140.0 and global_position.x < 760.0:
		global_position.y = 1298.0
		velocity = Vector2.ZERO


func _check_stuck(delta: float) -> void:
	if velocity.length() <= 1.0:
		stuck_time = 0.0
	elif global_position.distance_to(last_position) < 0.5:
		stuck_time += delta
		if stuck_time >= 1.0:
			wander_target = _pick_wander_target()
			stuck_time = 0.0
	else:
		stuck_time = 0.0
	last_position = global_position


func _has_aggro() -> bool:
	if player == null:
		return false
	if aggro_timer > 0.0:
		return true
	if enemy_type == EnemyType.ELITE and permanent_aggro:
		return true
	if time_since_player_hit < hit_aggro_time:
		return true
	return global_position.distance_to(player.global_position) <= detect_range


func _player_in_safe_zone() -> bool:
	return player != null and _point_in_safe_zone(player.global_position)


func _point_in_safe_zone(point: Vector2, margin: float = 0.0) -> bool:
	for zone in get_tree().get_nodes_in_group("SafeZones"):
		if zone.has_method("contains_point") and bool(zone.call("contains_point", point, margin)):
			return true
	return false


func _cardinal(v: Vector2) -> Vector2:
	if v == Vector2.ZERO:
		return facing
	if absf(v.x) > absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, signf(v.y))
