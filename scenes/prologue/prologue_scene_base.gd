extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/prologue/prologue_hud.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const GRASS: Texture2D = preload("res://graphics/tilesets/grass.png")
const SOIL: Texture2D = preload("res://graphics/tilesets/soil.png")
const WOOD_FLOOR: Texture2D = preload("res://graphics/camp/camp_floor.png")
const TREE: Texture2D = preload("res://graphics/tilesets/trees.png")
const PLAYER_SHEET: Texture2D = preload("res://graphics/characters/player_animations.png")
const MOUNTAIN: Texture2D = preload("res://graphics/tilesets/mountain.png")

var objects: Node2D
var player
var hud
var loaded_from_save := false
var transitioning := false


func _ready() -> void:
	loaded_from_save = not SaveGame.pending_player_data.is_empty()
	_create_runtime()
	player.prologue_mode = true
	player.speed = 78.0
	if not Global.profession.is_empty():
		player.call("setup_profession", Global.profession, false)
	hud.revive_requested.connect(_on_revive_requested)
	on_scene_ready()


func _create_runtime() -> void:
	objects = Node2D.new()
	objects.name = "Objects"
	add_child(objects)
	player = PLAYER_SCENE.instantiate()
	player.z_index = 10
	objects.add_child(player)
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	var pause_menu := PAUSE_SCENE.instantiate()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func on_scene_ready() -> void:
	pass


func _process(delta: float) -> void:
	if transitioning:
		return
	if bool(hud.get("dialog_active")) or bool(hud.get("select_active")) or bool(hud.get("character_open")) or bool(hud.get("death_open")):
		hud.call("clear_interaction")
		return
	on_scene_process(delta)


func on_scene_process(_delta: float) -> void:
	pass


func resolve_spawn(default_position: Vector2, entries: Dictionary = {}) -> void:
	var spawn_id := Global.prologue_scene_spawn
	if not spawn_id.is_empty() and entries.has(spawn_id):
		player.global_position = entries[spawn_id]
	elif not loaded_from_save:
		player.global_position = default_position
	Global.prologue_scene_spawn = ""


func travel_to(scene_path: String, spawn_id: String = "") -> void:
	if transitioning:
		return
	transitioning = true
	SaveGame.pending_player_data = player.call("get_save_data")
	Global.prologue_scene_spawn = spawn_id
	get_tree().change_scene_to_file(scene_path)


func set_objective(text: String) -> void:
	hud.call("set_objective", text)


func set_tutorial(text: String) -> void:
	hud.call("show_tutorial", text)


func add_tile_area(
	rect: Rect2,
	texture: Texture2D,
	tile_choices: Array[Vector2i],
	tile_scale: int = 2,
	seed: int = 1,
	offset: Vector2i = Vector2i.ZERO,
) -> TileMapLayer:
	var tile_source := TileSetAtlasSource.new()
	tile_source.texture = texture
	tile_source.texture_region_size = Vector2i(16, 16)
	for coords in tile_choices:
		tile_source.create_tile(coords)
	var tile_set := TileSet.new()
	tile_set.add_source(tile_source, 0)
	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	layer.position = rect.position
	layer.scale = Vector2(tile_scale, tile_scale)
	layer.z_index = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var cols := ceili(rect.size.x / (16.0 * tile_scale))
	var rows := ceili(rect.size.y / (16.0 * tile_scale))
	for y in rows:
		for x in cols:
			var coords: Vector2i = tile_choices[rng.randi_range(0, tile_choices.size() - 1)]
			layer.set_cell(Vector2i(x, y) + offset, 0, coords)
	objects.add_child(layer)
	return layer


func add_blocker(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	objects.add_child(body)
	return body


func add_tree(pos: Vector2, tree_scale: float = 1.3, flip: bool = false) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = TREE
	atlas.region = Rect2(0 if not flip else 32, 0, 32, 32)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position = pos
	sprite.scale = Vector2.ONE * tree_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	objects.add_child(sprite)


func add_sprite(texture: Texture2D, pos: Vector2, sprite_scale: float = 1.0, tint: Color = Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	objects.add_child(sprite)
	return sprite


func add_atlas_sprite(
	texture: Texture2D,
	region: Rect2,
	pos: Vector2,
	sprite_scale: float = 1.0,
	tint: Color = Color.WHITE,
) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return add_sprite(atlas, pos, sprite_scale, tint)


func add_person(pos: Vector2, tint: Color = Color.WHITE, frame: int = 0) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = PLAYER_SHEET
	atlas.region = Rect2((frame % 26) * 48, 0, 48, 48)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position = pos
	sprite.scale = Vector2(1.4, 1.4)
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 3
	objects.add_child(sprite)
	return sprite


func add_world_label(text: String, pos: Vector2, size: int = 9, color: Color = Color(1.0, 0.86, 0.55)) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(110, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", hud.ui_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	objects.add_child(label)
	return label


func _on_revive_requested() -> void:
	player.call("revive_at_camp")
	player.call("set_input_locked", false)
	on_after_revive()


func on_after_revive() -> void:
	pass

