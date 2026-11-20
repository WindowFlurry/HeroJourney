extends Node2D

const PICKUP_SCENE: PackedScene = preload("res://scenes/level/pickup_item.tscn")
const HERB_TEX: Texture2D = preload("res://graphics/items/herb.png")
const VINE_TEX: Texture2D = preload("res://graphics/items/vine.png")
const MAX_ITEMS := 10
const INITIAL_ITEMS := 5
const MIN_DISTANCE := 96.0
const SPAWN_INTERVAL := 10.0
const HERB_COLOR := Color(0.4, 1.0, 0.45, 1.0)
const VINE_COLOR := Color(0.72, 0.5, 1.0, 1.0)

@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.wait_time = SPAWN_INTERVAL
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	for i in INITIAL_ITEMS:
		_spawn_one()


func _on_timer_timeout() -> void:
	if _forage_count() < MAX_ITEMS:
		_spawn_one()


func _forage_count() -> int:
	return get_tree().get_nodes_in_group("Forage").size()


func _spawn_one() -> void:
	if _forage_count() >= MAX_ITEMS:
		return
	var pos := _find_position()
	if not is_finite(pos.x):
		return
	var is_herb := randf() < 0.33
	var item := PICKUP_SCENE.instantiate()
	var objects := get_parent().get_node_or_null("Objects")
	if objects == null:
		objects = get_parent()
	objects.add_child(item)
	item.position = pos
	if is_herb:
		item.call("setup", "herb", "草药", HERB_COLOR, HERB_TEX)
	else:
		item.call("setup", "vine", "焦枯藤蔓", VINE_COLOR, VINE_TEX)
	item.add_to_group("Forage")


func _find_position() -> Vector2:
	for attempt in 40:
		var base := Vector2(randf_range(-700.0, 900.0), randf_range(-100.0, 1150.0))
		if _point_in_safe_zone(base):
			continue
		var pos := Global.find_reachable_position(base, 24.0)
		if not is_finite(pos.x):
			continue
		if _point_in_safe_zone(pos):
			continue
		if _too_close(pos):
			continue
		return pos
	return Vector2(INF, INF)


func _point_in_safe_zone(pos: Vector2) -> bool:
	for zone in get_tree().get_nodes_in_group("SafeZones"):
		if zone.has_method("contains_point") and bool(zone.call("contains_point", pos)):
			return true
	return false


func _too_close(pos: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("Forage"):
		var item := node as Node2D
		if item != null and item.global_position.distance_to(pos) < MIN_DISTANCE:
			return true
	return false
