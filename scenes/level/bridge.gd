extends Node2D

@onready var broken_sprite: Sprite2D = $Broken
@onready var repaired_sprite: Sprite2D = $Repaired
@onready var blocker: CollisionShape2D = $Blocker/CollisionShape2D
@onready var fog_blocker: CollisionShape2D = $FogBlocker/CollisionShape2D
@onready var repair_area: Area2D = $RepairArea
@onready var fog_area: Area2D = $FogArea

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/enemy.tscn")
const STAGE_TIME := 4.5
const REQUIRED_STAGES := 3
# 玩家离桥超过这个距离后，额外刷出来的怪物会消失（视野内的除外）。
const EVENT_RANGE := 230.0
const EVENT_ENEMY_GROUP := "BridgeEventEnemies"
const MELEE := 0
const RANGED := 1
const ELITE := 2

# 断桥四周的刷怪点，离修桥点 200～350 像素，怪物需要跑过来。
const EVENT_SPAWN_POINTS := [
	Vector2(400, 900), Vector2(250, 940), Vector2(550, 940),
	Vector2(300, 1120), Vector2(520, 1120), Vector2(300, 1180),
	Vector2(520, 1180), Vector2(400, 1040),
]

var player
var hud
var near_repair := false
var near_fog := false
var repaired := false
var repair_stage := 0
var channeling := false
var channel_time := 0.0
var start_cooldown := 0.0

# 连续刷怪：小股怪不断来，间隔一段时间来一大波，大波之后留出修桥空档。
var event_started := false
var spawn_clock := 0.0
var big_wave_timer := 0.0
var spawn_pause := 0.0
var was_in_range := false
var despawn_timer := 0.0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	hud = get_tree().get_first_node_in_group("HUD")
	repair_area.body_entered.connect(_on_repair_entered)
	repair_area.body_exited.connect(_on_repair_exited)
	fog_area.body_entered.connect(_on_fog_entered)
	fog_area.body_exited.connect(_on_fog_exited)
	if player != null and player.has_signal("died"):
		player.died.connect(_on_player_died)
	repair_stage = clampi(int(Global.bridge_repair_stage), 0, REQUIRED_STAGES)
	repaired = Global.bridge_repaired or repair_stage >= REQUIRED_STAGES
	if repaired:
		repair_stage = REQUIRED_STAGES
		Global.bridge_repair_stage = REQUIRED_STAGES
	_apply_state()


func _apply_state() -> void:
	broken_sprite.visible = not repaired
	repaired_sprite.visible = repaired
	broken_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.82, 0.55), float(repair_stage) / float(REQUIRED_STAGES))
	blocker.disabled = repaired
	fog_blocker.disabled = Global.mask_equipped


func _on_repair_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near_repair = true


func _on_repair_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near_repair = false
		if channeling:
			_cancel_channel("离开木桥，抢修中断")
		if hud != null:
			hud.call("hide_hint")
			hud.call("hide_channel")


func _on_fog_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near_fog = true


func _on_fog_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near_fog = false
		if hud != null:
			hud.call("hide_hint")


func _on_player_died() -> void:
	if channeling:
		_cancel_channel("")


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	start_cooldown = maxf(0.0, start_cooldown - delta)
	if Global.mask_equipped:
		fog_blocker.disabled = true

	var materials := int(Global.inventory.get("material", 0))
	var in_range: bool = player != null and is_instance_valid(player) and player.global_position.distance_to(global_position) <= EVENT_RANGE
	if in_range:
		was_in_range = true
		if not repaired and materials > 0:
			_update_spawner(delta)
	else:
		if was_in_range:
			was_in_range = false
			event_started = false
			spawn_clock = 0.0
			big_wave_timer = 0.0
			spawn_pause = 0.0
			_despawn_event_enemies()
		despawn_timer -= delta
		if despawn_timer <= 0.0:
			despawn_timer = 0.4
			_despawn_event_enemies()

	if channeling:
		if not near_repair or repaired or player == null or not is_instance_valid(player) or bool(player.get("dead")):
			_cancel_channel("抢修中断")
		else:
			_update_channel(delta)
		return

	if near_fog and repaired and not Global.mask_equipped:
		if int(Global.inventory.get("mask", 0)) > 0:
			if hud != null:
				hud.call("show_hint", "按 %s 带上灰烬护符" % Settings.binding_text("interact"))
			if Input.is_action_just_pressed("interact"):
				_equip_mask()
		else:
			if hud != null:
				hud.call("show_hint", "你需要灰烬护符……")
		return

	if near_repair and not repaired:
		if materials > 0:
			if hud != null:
				hud.call("show_hint", "按住 %s 抢修木桥（%d/%d · 4.5 秒）" % [
					Settings.binding_text("interact"),
					repair_stage + 1,
					REQUIRED_STAGES,
				])
			if Input.is_action_pressed("interact") and start_cooldown <= 0.0:
				_start_channel()
		else:
			if hud != null:
				hud.call("show_hint", "需要建材 %d/%d：寻找伐木队补给" % [repair_stage, REQUIRED_STAGES])
		return

	if near_repair or near_fog:
		if hud != null:
			hud.call("hide_hint")


func _start_channel() -> void:
	if channeling or repaired or player == null:
		return
	if int(Global.inventory.get("material", 0)) <= 0:
		return
	channeling = true
	channel_time = 0.0
	player.call("set_input_locked", true)
	if hud != null:
		hud.call("hide_hint")
		hud.call("show_channel", 0.0, "抢修木桥 第 %d/%d 段" % [repair_stage + 1, REQUIRED_STAGES])
	Sfx.play("warn", 0.9, -10.0)


func _update_channel(delta: float) -> void:
	if not Input.is_action_pressed("interact"):
		_cancel_channel("松开按键，抢修中断")
		return
	channel_time += delta
	if hud != null:
		hud.call("show_channel", channel_time / STAGE_TIME, "抢修木桥 第 %d/%d 段" % [repair_stage + 1, REQUIRED_STAGES])
	if channel_time >= STAGE_TIME:
		_complete_stage()


func _complete_stage() -> void:
	if not channeling:
		return
	channeling = false
	channel_time = 0.0
	start_cooldown = 1.0
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.call("set_input_locked", false)
	if hud != null:
		hud.call("hide_channel")

	if int(Global.inventory.get("material", 0)) <= 0:
		if hud != null:
			hud.call("show_notice", "建材不足，抢修中断")
		return

	Global.remove_items({"material": 1})
	repair_stage += 1
	Global.bridge_repair_stage = repair_stage
	Sfx.play("craft")

	if repair_stage >= REQUIRED_STAGES:
		repaired = true
		Global.bridge_repaired = true
		event_started = false
		_apply_state()
		SaveGame.save_game("前哨木桥")
		if hud != null:
			hud.call("show_banner", "前哨木桥修复完成", "灰烬护符可以抵挡龙焰烟尘", 2.6)
			hud.call("show_notice", "木桥已修复")
	else:
		_apply_state()
		SaveGame.save_game("前哨木桥")
		if hud != null:
			hud.call("show_notice", "木桥第 %d/%d 段已固定" % [repair_stage, REQUIRED_STAGES])


func _cancel_channel(reason: String) -> void:
	if not channeling:
		return
	channeling = false
	channel_time = 0.0
	start_cooldown = 0.5
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.call("set_input_locked", false)
	if hud != null:
		hud.call("hide_channel")
		if not reason.is_empty():
			hud.call("show_notice", reason)


func _update_spawner(delta: float) -> void:
	if repaired or repair_stage >= REQUIRED_STAGES:
		return
	if player == null or not is_instance_valid(player) or bool(player.get("dead")):
		return
	if int(Global.inventory.get("material", 0)) <= 0:
		return

	if not event_started:
		event_started = true
		spawn_pause = 1.5
		big_wave_timer = randf_range(10.0, 12.0)
		spawn_clock = 1.0

	if spawn_pause > 0.0:
		spawn_pause -= delta
		return

	big_wave_timer -= delta
	spawn_clock -= delta

	if big_wave_timer <= 0.0:
		_spawn_big_wave()
		big_wave_timer = randf_range(15.0, 18.0)
		spawn_pause = randf_range(5.0, 6.0)
		return

	if spawn_clock <= 0.0:
		var nearby := _nearby_enemy_count()
		if nearby < 7:
			_spawn_enemy(MELEE if randf() < 0.7 else RANGED, _random_spawn_pos())
		spawn_clock = randf_range(3.2, 4.6)


func _spawn_big_wave() -> void:
	Sfx.play("danger", 0.75, -6.0)
	if _nearby_enemy_count() >= 10:
		return
	_spawn_enemy(MELEE, _random_spawn_pos())
	_spawn_enemy(MELEE, _random_spawn_pos())
	_spawn_enemy(RANGED, _random_spawn_pos())
	_spawn_enemy(RANGED, _random_spawn_pos())
	_spawn_enemy(ELITE, _random_spawn_pos())


func _random_spawn_pos() -> Vector2:
	var target: Vector2 = global_position + Vector2(0, -58)
	if player != null and is_instance_valid(player):
		target = player.global_position
	var points: Array = EVENT_SPAWN_POINTS.duplicate()
	points.shuffle()
	for point in points:
		var base_point: Vector2 = point
		var candidate := base_point + Vector2(randf_range(-24.0, 24.0), randf_range(-16.0, 16.0))
		var pos := Global.find_reachable_position(candidate, 48.0)
		if pos == Vector2.INF or _point_in_safe_zone(pos):
			continue
		if _has_clear_path(pos, target):
			return pos
	for i in 8:
		var candidate := target + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 170.0)
		var pos := Global.find_reachable_position(candidate, 48.0)
		if pos == Vector2.INF or _point_in_safe_zone(pos):
			continue
		if _has_clear_path(pos, target):
			return pos
	return Vector2.INF


func _has_clear_path(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.collide_with_areas = false
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _camera_view_rect() -> Rect2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return Rect2(Vector2.INF, Vector2.ZERO)
	var size := get_viewport().get_visible_rect().size / camera.zoom
	var center := camera.get_screen_center_position()
	return Rect2(center - size * 0.5, size).grow(64.0)


func _despawn_event_enemies() -> void:
	var view := _camera_view_rect()
	for node in get_tree().get_nodes_in_group(EVENT_ENEMY_GROUP):
		if not is_instance_valid(node):
			continue
		var enemy := node as Node2D
		if enemy == null:
			continue
		if view.has_point(enemy.global_position):
			continue
		node.queue_free()


func _nearby_enemy_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("Enemies"):
		var enemy_node := node as Node2D
		if enemy_node != null and enemy_node.global_position.distance_to(global_position) <= 420.0:
			count += 1
	return count


func _point_in_safe_zone(point: Vector2) -> bool:
	for zone in get_tree().get_nodes_in_group("SafeZones"):
		if zone.has_method("contains_point") and bool(zone.call("contains_point", point, 8.0)):
			return true
	return false


func _spawn_enemy(type: int, spawn_pos: Vector2) -> void:
	if spawn_pos == Vector2.INF:
		return
	var pos := Global.find_reachable_position(spawn_pos, 48.0)
	if pos == Vector2.INF:
		pos = spawn_pos
	if _point_in_safe_zone(pos):
		pos = Global.find_reachable_position(spawn_pos + Vector2(240, 40), 48.0)
	if pos == Vector2.INF or _point_in_safe_zone(pos):
		return
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	if enemy == null:
		return
	enemy.set("enemy_type", type)
	enemy.set("region_tier", 1)
	enemy.set("health_multiplier", 1.0 + 0.08 * repair_stage)
	enemy.position = pos
	var objects := get_tree().current_scene.get_node_or_null("Objects")
	if objects == null:
		objects = get_parent()
	objects.add_child(enemy)
	enemy.global_position = pos
	enemy.set("aggro_timer", 999.0)
	enemy.add_to_group(EVENT_ENEMY_GROUP)


func _equip_mask() -> void:
	if Global.mask_equipped:
		return
	if int(Global.inventory.get("mask", 0)) <= 0:
		return
	Global.mask_equipped = true
	fog_blocker.disabled = true
	Sfx.play("pickup")
	if hud != null:
		hud.call("hide_hint")
		hud.call("show_notice", "已带上灰烬护符")
