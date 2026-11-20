extends Node2D

const WHITE_BIRCH_SCENE: PackedScene = preload("res://scenes/level/white_birch.tscn")
const STUMP: Texture2D = preload("res://graphics/trees/white_birch/white_birch_stump.png")
const LOG: Texture2D = preload("res://graphics/trees/white_birch/white_birch_log.png")
const FLOWER: Texture2D = preload("res://graphics/trees/white_birch/white_birch_flower.png")
const FERN: Texture2D = preload("res://graphics/trees/white_birch/white_birch_fern.png")
const SIGN: Texture2D = preload("res://graphics/trees/white_birch/white_birch_sign.png")

# A/B/C 常见，D/E 稀有；五种都会出现
const BIRCH_STYLE_POOL := [0, 0, 0, 1, 1, 2, 2, 3, 4]

var rng := RandomNumberGenerator.new()
var objects: Node2D
var placed_birches: Array[Vector2] = []


func _ready() -> void:
	rng.seed = 20261120
	objects = get_node_or_null("Objects")
	if objects == null:
		return
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
			continue
		spots.append(node.global_position + Vector2(0, 13))
		node.queue_free()

	# 等旧树碰撞移除后再做落点检测
	await get_tree().process_frame

	for pos in spots:
		if not _can_place(pos):
			continue
		_spawn_birch(pos)
		if rng.randf() < 0.45:
			var extra := pos + Vector2(
				rng.randf_range(-55.0, 55.0),
				rng.randf_range(-24.0, 24.0)
			)
			if _can_place(extra):
				_spawn_birch(extra)
		_add_details(pos)

	_add_forest_sign()


func _spawn_birch(pos: Vector2) -> void:
	var birch := WHITE_BIRCH_SCENE.instantiate() as Node2D
	if birch == null:
		return
	var style: int = int(BIRCH_STYLE_POOL[rng.randi_range(0, BIRCH_STYLE_POOL.size() - 1)])
	birch.set("style_index", style)
	birch.position = pos
	objects.add_child(birch)
	placed_birches.append(pos)


func _can_place(pos: Vector2) -> bool:
	if not _ground_free(pos):
		return false
	for placed in placed_birches:
		if placed.distance_to(pos) < 24.0:
			return false
	return true


func _ground_free(pos: Vector2) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos + Vector2(0, -5)
	params.collision_mask = 1
	params.collide_with_areas = false
	var hits := get_world_2d().direct_space_state.intersect_point(params, 1)
	return hits.is_empty()


func _add_details(pos: Vector2) -> void:
	if rng.randf() < 0.28:
		var stump_pos := _offset_spot(pos, 34.0, 16.0)
		if stump_pos != Vector2.INF:
			_add_sprite(STUMP, stump_pos, rng.randf_range(0.9, 1.0), false)
	if rng.randf() < 0.20:
		var log_pos := _offset_spot(pos, 38.0, 18.0)
		if log_pos != Vector2.INF:
			_add_sprite(LOG, log_pos, rng.randf_range(0.9, 1.0), rng.randf() < 0.5)
	if rng.randf() < 0.55:
		var flower_pos := _offset_spot(pos, 28.0, 14.0)
		if flower_pos != Vector2.INF:
			_add_sprite(FLOWER, flower_pos, rng.randf_range(0.9, 1.1), rng.randf() < 0.5)
	if rng.randf() < 0.55:
		var fern_pos := _offset_spot(pos, 30.0, 15.0)
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
