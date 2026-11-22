extends Node2D

const WHITE_BIRCH_SCENE: PackedScene = preload("res://scenes/level/white_birch.tscn")
const STUMP: Texture2D = preload("res://graphics/trees/white_birch/white_birch_stump.png")
const LOG: Texture2D = preload("res://graphics/trees/white_birch/white_birch_log.png")
const FLOWER: Texture2D = preload("res://graphics/trees/white_birch/white_birch_flower.png")
const FERN: Texture2D = preload("res://graphics/trees/white_birch/white_birch_fern.png")
const SIGN: Texture2D = preload("res://graphics/trees/white_birch/white_birch_sign.png")
const MONASTERY_GATE_SCENE: PackedScene = preload("res://scenes/level/monastery_gate.tscn")

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
	var gate := MONASTERY_GATE_SCENE.instantiate() as Node2D
	if gate != null:
		gate.position = Vector2(230, 10)
		objects.add_child(gate)
	var end_gate := MONASTERY_GATE_SCENE.instantiate() as Node2D
	if end_gate != null:
		end_gate.position = Vector2(560, 1370)
		objects.add_child(end_gate)
	_build_white_birch_forest()


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
