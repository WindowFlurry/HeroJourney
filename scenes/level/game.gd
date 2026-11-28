extends Node2D

const WHITE_BIRCH_SCENE: PackedScene = preload("res://scenes/level/white_birch.tscn")
const STUMP: Texture2D = preload("res://graphics/trees/white_birch/white_birch_stump.png")
const LOG: Texture2D = preload("res://graphics/trees/white_birch/white_birch_log.png")
const FLOWER: Texture2D = preload("res://graphics/trees/white_birch/white_birch_flower.png")
const FERN: Texture2D = preload("res://graphics/trees/white_birch/white_birch_fern.png")
const SIGN: Texture2D = preload("res://graphics/trees/white_birch/white_birch_sign.png")
const TOWN_RETURN_GATE_SCRIPT: Script = preload("res://scenes/level/town_return_gate.gd")
const TRACKING_QUEST_SCRIPT: Script = preload("res://scenes/level/tracking_quest.gd")
const PICKUP_SCENE: PackedScene = preload("res://scenes/level/pickup_item.tscn")
const MATERIAL_ICON: Texture2D = preload("res://graphics/items/material.png")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/enemy.tscn")
const MATERIAL_CACHES := [
	{"pos": Vector2(-140, 900), "flag": "bridge_crate_west", "label": "西侧补给"},
	{"pos": Vector2(500, 780), "flag": "bridge_crate_east", "label": "东侧补给"},
]
const EAST_RECT := Rect2(560, 470, 760, 720)
const EAST_TREE_SPOTS := [
	Vector2(650, 545), Vector2(770, 520), Vector2(900, 525), Vector2(1040, 545),
	Vector2(1180, 570), Vector2(1290, 650), Vector2(660, 870), Vector2(800, 900),
	Vector2(1280, 900), Vector2(700, 1100), Vector2(900, 1160), Vector2(1100, 1140),
]
const EAST_DETAIL_SPOTS := [
	Vector2(720, 850), Vector2(1000, 650), Vector2(1240, 760), Vector2(760, 1000),
]
const EAST_ENEMY_SPOTS := [
	{"pos": Vector2(740, 800), "type": 0, "tier": 1},
	{"pos": Vector2(900, 650), "type": 1, "tier": 1},
	{"pos": Vector2(1080, 900), "type": 0, "tier": 2},
	{"pos": Vector2(1040, 1150), "type": 1, "tier": 2},
]

# A/B/C 常见，D/E 稀有；五种都会出现
const BIRCH_STYLE_POOL := [0, 0, 0, 1, 1, 2, 2, 3, 4]
const BIRCH_STYLE_SIZES := [
	Vector2(32, 56),
	Vector2(44, 56),
	Vector2(32, 32),
	Vector2(48, 56),
	Vector2(32, 56),
]
const STUMP_SIZE := Vector2(32, 22)
const LOG_SIZE := Vector2(48, 18)
const SIGN_SIZE := Vector2(40, 30)
const THICK_STUMPS := 3
const THICK_LOGS := 2

var rng := RandomNumberGenerator.new()
var objects: Node2D
var birch_rects: Array[Rect2] = []
var thick_rects: Array[Rect2] = []
var brown_rects: Array[Rect2] = []


func _ready() -> void:
	rng.seed = 20261120
	objects = get_node_or_null("Objects")
	if objects == null:
		return
	_build_return_gate()
	_build_east_extension()
	await _build_white_birch_forest()
	if not is_inside_tree():
		return
	_build_level_quests()
	SaveGame.save_game("白桦林地")


func _build_return_gate() -> void:
	var gate := Node2D.new()
	gate.set_script(TOWN_RETURN_GATE_SCRIPT)
	gate.position = Vector2(200, -60)
	gate.set("label_text", "返回白鹿镇")
	objects.add_child(gate)


func _build_east_extension() -> void:
	var layers := get_node_or_null("Layers")
	if layers == null:
		return
	var water := layers.get_node_or_null("WaterWorld") as TileMapLayer
	var land := layers.get_node_or_null("LandExtension") as TileMapLayer
	if land == null or land.tile_set == null:
		return

	var start_cell := land.local_to_map(EAST_RECT.position)
	var end_cell := land.local_to_map(EAST_RECT.position + EAST_RECT.size)

	var east_land := TileMapLayer.new()
	east_land.name = "EastLand"
	east_land.tile_set = land.tile_set
	east_land.z_index = 0
	layers.add_child(east_land)

	var cells: Array[Vector2i] = []
	for y in range(start_cell.y, end_cell.y):
		for x in range(start_cell.x, end_cell.x):
			var cell := Vector2i(x, y)
			if water != null:
				water.erase_cell(cell)
			cells.append(cell)
	if not cells.is_empty():
		east_land.set_cells_terrain_connect(cells, 0, 0, false)

	_add_east_sign()
	for spot in EAST_TREE_SPOTS:
		var birch := WHITE_BIRCH_SCENE.instantiate() as Node2D
		if birch == null:
			continue
		birch.set("style_index", int(BIRCH_STYLE_POOL[rng.randi_range(0, BIRCH_STYLE_POOL.size() - 1)]))
		birch.set("scale_override", rng.randf_range(0.95, 1.08))
		birch.position = spot
		objects.add_child(birch)
	for i in EAST_DETAIL_SPOTS.size():
		var spot: Vector2 = EAST_DETAIL_SPOTS[i]
		_add_sprite(STUMP if i % 2 == 0 else LOG, spot, 1.0, rng.randf() < 0.5)
	for i in 10:
		var detail := Vector2(rng.randf_range(600.0, 1280.0), rng.randf_range(520.0, 1160.0))
		_add_sprite(FLOWER if i % 2 == 0 else FERN, detail, rng.randf_range(0.9, 1.1), rng.randf() < 0.5)
	for entry in EAST_ENEMY_SPOTS:
		_spawn_east_enemy(entry)

func _add_east_sign() -> void:
	var pos := Vector2(600, 640)
	var sign_sprite := Sprite2D.new()
	sign_sprite.texture = SIGN
	sign_sprite.position = pos + Vector2(0, -15)
	sign_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sign_sprite.z_index = 1
	objects.add_child(sign_sprite)
	_add_cache_label("东侧林地", pos + Vector2(-55, -52))
	_add_cache_label("伐木队营地", Vector2(1180, 1030))

func _spawn_east_enemy(entry: Dictionary) -> void:
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	if enemy == null:
		return
	var pos: Vector2 = entry["pos"]
	enemy.set("enemy_type", int(entry["type"]))
	enemy.set("region_tier", int(entry["tier"]))
	enemy.set("health_multiplier", 1.15)
	enemy.position = pos
	objects.add_child(enemy)
	enemy.global_position = pos


func _build_level_quests() -> void:
	if Global.bridge_repaired:
		return
	for entry in MATERIAL_CACHES:
		var flag := str(entry["flag"])
		if bool(Global.get(flag)):
			continue
		_spawn_material_cache(Vector2(entry["pos"]), flag, str(entry["label"]))

	var tracking := Node2D.new()
	tracking.name = "TrackingQuest"
	tracking.set_script(TRACKING_QUEST_SCRIPT)
	tracking.position = Vector2.ZERO
	objects.add_child(tracking)


func _spawn_material_cache(pos: Vector2, flag: String, label_text: String) -> void:
	var cache_pos := _reachable(pos)
	var pickup := PICKUP_SCENE.instantiate() as Node2D
	if pickup == null:
		return
	pickup.set("flag_name", flag)
	pickup.set("pickup_notice", "获得建材")
	pickup.position = cache_pos
	objects.add_child(pickup)
	pickup.global_position = cache_pos
	pickup.call("setup", "material", "建材", Color(0.95, 0.78, 0.35), MATERIAL_ICON)
	_add_cache_label(label_text, cache_pos + Vector2(-55, -42))
	_spawn_cache_guards(cache_pos)


func _spawn_cache_guards(pos: Vector2) -> void:
	var plans := [
		{"type": 0, "offset": Vector2(-80, 10)},
		{"type": 1, "offset": Vector2(80, 4)},
	]
	for plan in plans:
		var enemy := ENEMY_SCENE.instantiate() as Node2D
		if enemy == null:
			continue
		var offset: Vector2 = plan["offset"]
		var enemy_pos := _reachable(pos + offset)
		enemy.set("enemy_type", int(plan["type"]))
		enemy.set("region_tier", 1)
		enemy.set("health_multiplier", 1.0)
		enemy.position = enemy_pos
		objects.add_child(enemy)
		enemy.global_position = enemy_pos


func _reachable(point: Vector2) -> Vector2:
	var pos := Global.find_reachable_position(point, 72.0)
	return point if pos == Vector2.INF else pos


func _add_cache_label(text: String, pos: Vector2) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(110, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	objects.add_child(label)


func _build_white_birch_forest() -> void:
	var brown_trees := get_tree().get_nodes_in_group("Trees")
	var spots: Array[Vector2] = []
	for tree in brown_trees:
		if not is_instance_valid(tree):
			continue
		var node := tree as Node2D
		if node == null:
			continue
		if rng.randf() < 0.22:
			brown_rects.append(Rect2(node.global_position - Vector2(16, 16), Vector2(32, 32)))
			continue
		spots.append(node.global_position + Vector2(0, 13))
		node.queue_free()

	# 等旧树碰撞移除后再做落点检测
	await get_tree().process_frame

	for pos in spots:
		var style := int(BIRCH_STYLE_POOL[rng.randi_range(0, BIRCH_STYLE_POOL.size() - 1)])
		var s := rng.randf_range(0.95, 1.05)
		if _spawn_birch(pos, style, s):
			if rng.randf() < 0.35:
				var extra := pos + Vector2(
					rng.randf_range(-55.0, 55.0),
					rng.randf_range(-24.0, 24.0)
				)
				var extra_style := int(BIRCH_STYLE_POOL[rng.randi_range(0, BIRCH_STYLE_POOL.size() - 1)])
				var extra_scale := rng.randf_range(0.95, 1.05)
				_spawn_birch(extra, extra_style, extra_scale)
			_add_small_details(pos)

	_scatter_thick_debris(spots)
	_add_forest_sign()


func _spawn_birch(pos: Vector2, style: int, sprite_scale: float) -> bool:
	if not _ground_free(pos):
		return false
	var rect := _birch_rect(pos, style, sprite_scale).grow(2.0)
	if _overlaps_any(rect, birch_rects):
		return false
	if _overlaps_any(rect, brown_rects):
		return false
	if _overlaps_any(rect, thick_rects):
		return false

	var birch := WHITE_BIRCH_SCENE.instantiate() as Node2D
	if birch == null:
		return false
	birch.set("style_index", style)
	birch.set("scale_override", sprite_scale)
	birch.position = pos
	objects.add_child(birch)
	birch_rects.append(rect)
	return true


func _birch_rect(pos: Vector2, style: int, sprite_scale: float) -> Rect2:
	var size: Vector2 = BIRCH_STYLE_SIZES[clampi(style, 0, BIRCH_STYLE_SIZES.size() - 1)]
	var w := size.x * sprite_scale
	var h := size.y * sprite_scale
	return Rect2(pos.x - w * 0.5, pos.y + 3.0 * sprite_scale - h, w, h)


func _scatter_thick_debris(spots: Array[Vector2]) -> void:
	var candidates: Array[Vector2] = []
	for pos in spots:
		for i in 3:
			candidates.append(pos + Vector2(
				rng.randf_range(-80.0, 80.0),
				rng.randf_range(-40.0, 40.0)
			))
	for i in 30:
		candidates.append(Vector2(rng.randf_range(-320.0, 540.0), rng.randf_range(200.0, 980.0)))

	var stump_placed := 0
	var log_placed := 0
	for pos in candidates:
		if stump_placed >= THICK_STUMPS and log_placed >= THICK_LOGS:
			break
		if not _ground_free(pos):
			continue
		if stump_placed < THICK_STUMPS:
			var stump_rect := _detail_rect(pos, STUMP_SIZE).grow(2.0)
			if not _overlaps_any(stump_rect, birch_rects) and not _overlaps_any(stump_rect, brown_rects) and not _overlaps_any(stump_rect, thick_rects):
				_add_sprite(STUMP, pos, 1.0, rng.randf() < 0.5)
				thick_rects.append(stump_rect)
				stump_placed += 1
				continue
		if log_placed < THICK_LOGS:
			var log_rect := _detail_rect(pos, LOG_SIZE).grow(2.0)
			if not _overlaps_any(log_rect, birch_rects) and not _overlaps_any(log_rect, brown_rects) and not _overlaps_any(log_rect, thick_rects):
				_add_sprite(LOG, pos, 1.0, rng.randf() < 0.5)
				thick_rects.append(log_rect)
				log_placed += 1


func _add_small_details(pos: Vector2) -> void:
	if rng.randf() < 0.40:
		var flower_pos := _offset_spot(pos, 30.0, 15.0)
		if flower_pos != Vector2.INF:
			_add_sprite(FLOWER, flower_pos, rng.randf_range(0.9, 1.1), rng.randf() < 0.5)
	if rng.randf() < 0.40:
		var fern_pos := _offset_spot(pos, 32.0, 16.0)
		if fern_pos != Vector2.INF:
			_add_sprite(FERN, fern_pos, rng.randf_range(0.9, 1.1), rng.randf() < 0.5)


func _offset_spot(pos: Vector2, radius: float, height: float) -> Vector2:
	for i in 4:
		var candidate := pos + Vector2(
			rng.randf_range(-radius, radius),
			rng.randf_range(-height, height)
		)
		if _ground_free(candidate):
			return candidate
	return Vector2.INF


func _detail_rect(pos: Vector2, size: Vector2) -> Rect2:
	return Rect2(pos.x - size.x * 0.5, pos.y + 2.0 - size.y, size.x, size.y)


func _overlaps_any(rect: Rect2, list: Array[Rect2]) -> bool:
	for other in list:
		if rect.intersects(other):
			return true
	return false


func _ground_free(pos: Vector2) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos + Vector2(0, -5)
	params.collision_mask = 1
	params.collide_with_areas = false
	var hits := get_world_2d().direct_space_state.intersect_point(params, 1)
	return hits.is_empty()


func _add_sprite(tex: Texture2D, pos: Vector2, sprite_scale: float, flip: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos + Vector2(0, 2.0 - tex.get_height() * 0.5)
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.flip_h = flip
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 0
	objects.add_child(sprite)


func _add_forest_sign() -> void:
	var candidates := [
		Vector2(250, 220),
		Vector2(180, 250),
		Vector2(330, 250),
		Vector2(0, 240),
		Vector2(420, 260),
		Vector2(-100, 300),
	]
	for pos in candidates:
		if not _ground_free(pos):
			continue
		var rect := Rect2(pos.x - SIGN_SIZE.x * 0.5, pos.y - SIGN_SIZE.y, SIGN_SIZE.x, SIGN_SIZE.y).grow(2.0)
		if _overlaps_any(rect, birch_rects) or _overlaps_any(rect, brown_rects) or _overlaps_any(rect, thick_rects):
			continue
		var sign := Sprite2D.new()
		sign.texture = SIGN
		sign.position = pos + Vector2(0, -15)
		sign.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sign.z_index = 1
		objects.add_child(sign)

		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
		var label := Label.new()
		label.text = "白桦林地"
		label.position = pos + Vector2(-45, -55)
		label.size = Vector2(90, 14)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
		label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
		label.add_theme_constant_override("outline_size", 2)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 20
		objects.add_child(label)
		return
