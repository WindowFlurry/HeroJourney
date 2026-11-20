extends Node2D

const MELEE := 0
const RANGED := 1
const ELITE := 2

const CAPS := {MELEE: 11, RANGED: 6, ELITE: 3}
const WEIGHTS := {MELEE: 0.6, RANGED: 0.25, ELITE: 0.15}
const REGION_POINTS := [
	[0, 1, 2, 3],
	[4, 5, 6, 7, 8, 9, 10, 11, 23, 24, 25, 26],
	[12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 27, 28],
]
const REGION_TYPES := [
	[MELEE],
	[MELEE, RANGED],
	[RANGED, ELITE],
]
# 区域血量倍率：越靠近 Boss 越硬
const REGION_HP_MULT := [1.0, 1.55, 2.0]
const INITIAL_SPAWNS := [
	{"type": MELEE, "point": 0},
	{"type": MELEE, "point": 1},
	{"type": RANGED, "point": 4},
	{"type": MELEE, "point": 6},
	{"type": RANGED, "point": 7},
	{"type": MELEE, "point": 9},
]

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")
@export var spawn_chance := 0.85
@export var elite_grace_time := 40.0
@export var elite_respawn_cooldown := 40.0
@export var min_player_distance := 200.0
@export var min_enemy_distance := 32.0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_points: Node2D = $SpawnPoints

var player: Node2D
var elapsed_time := 0.0
var elite_ready_at := 0.0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player") as Node2D
	elite_ready_at = elite_grace_time
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_initial_enemies()


func _process(delta: float) -> void:
	elapsed_time += delta


func _spawn_initial_enemies() -> void:
	for entry in INITIAL_SPAWNS:
		var point := int(entry["point"])
		_spawn_enemy_at(int(entry["type"]), point, _hp_mult_for_point(point), _tier_for_point(point))


func _on_spawn_timer_timeout() -> void:
	if randf() > spawn_chance:
		return

	var valid_indices := _valid_spawn_indices()
	if valid_indices.is_empty():
		return

	var eligible: Array[int] = []
	var type_points: Dictionary = {}
	for type in [MELEE, RANGED, ELITE]:
		if _count_type(type) >= int(CAPS[type]):
			continue
		if type == ELITE and elapsed_time < elite_ready_at:
			continue
		var points: Array[int] = []
		for region_index in REGION_POINTS.size():
			if type in REGION_TYPES[region_index]:
				for index in REGION_POINTS[region_index]:
					var idx := int(index)
					if valid_indices.has(idx):
						points.append(idx)
		if not points.is_empty():
			eligible.append(type)
			type_points[type] = points

	if eligible.is_empty():
		return

	var chosen_type := _pick_weighted_type(eligible)
	var chosen_points = type_points[chosen_type]
	var point_index := int(chosen_points.pick_random())
	_spawn_enemy_at(chosen_type, point_index, _hp_mult_for_point(point_index), _tier_for_point(point_index))


func _count_type(type: int) -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		var value = enemy.get("enemy_type")
		if value == null:
			continue
		if int(value) == type:
			count += 1
	return count


func _pick_weighted_type(eligible: Array[int]) -> int:
	var total := 0.0
	for type in eligible:
		total += float(WEIGHTS[type])
	var roll := randf() * total
	for type in eligible:
		roll -= float(WEIGHTS[type])
		if roll <= 0.0:
			return type
	return eligible[eligible.size() - 1]


func _valid_spawn_indices() -> Array[int]:
	var result: Array[int] = []
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var markers := spawn_points.get_children()
	for i in markers.size():
		var marker := markers[i] as Marker2D
		if marker == null:
			continue
		var point := marker.global_position
		var params := PhysicsPointQueryParameters2D.new()
		params.position = point
		params.collision_mask = 1
		params.collide_with_areas = false
		params.collide_with_bodies = true
		var hits: Array[Dictionary] = space.intersect_point(params, 1)
		if not hits.is_empty():
			continue
		if _point_in_safe_zone(point):
			continue
		if player != null and point.distance_to(player.global_position) < min_player_distance:
			continue
		if _point_near_enemy(point):
			continue
		result.append(i)
	return result


func _point_in_safe_zone(point: Vector2) -> bool:
	for zone in get_tree().get_nodes_in_group("SafeZones"):
		if zone.has_method("contains_point") and bool(zone.call("contains_point", point)):
			return true
	return false


func _point_near_enemy(point: Vector2) -> bool:
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		var node := enemy as Node2D
		if node != null and node.global_position.distance_to(point) < min_enemy_distance:
			return true
	return false


func _hp_mult_for_point(point_index: int) -> float:
	for r in REGION_POINTS.size():
		if point_index in REGION_POINTS[r]:
			return float(REGION_HP_MULT[r])
	return 1.0


func _tier_for_point(point_index: int) -> int:
	for r in REGION_POINTS.size():
		if point_index in REGION_POINTS[r]:
			return r
	return 1


func _spawn_enemy_at(type: int, point_index: int, health_mult: float = 1.0, tier: int = 1) -> void:
	if point_index < 0 or point_index >= spawn_points.get_child_count():
		return
	var marker := spawn_points.get_child(point_index) as Marker2D
	if marker == null:
		return

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return
	enemy.set("enemy_type", type)
	enemy.set("health_multiplier", health_mult)
	enemy.set("region_tier", tier)
	enemy.position = marker.global_position

	var objects := get_parent().get_node_or_null("Objects")
	if objects == null:
		objects = get_parent()
	objects.add_child(enemy)

	enemy.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(enemy, "modulate:a", 1.0, 0.35)

	if type == ELITE:
		enemy.connect("died", _on_elite_died)


func _on_elite_died() -> void:
	elite_ready_at = maxf(elite_ready_at, elapsed_time + elite_respawn_cooldown)
