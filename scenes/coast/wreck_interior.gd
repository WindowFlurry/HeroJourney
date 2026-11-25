extends "res://scenes/prologue/prologue_scene_base.gd"

const WOOD: Texture2D = preload("res://graphics/coast/wood.png")
const SHIP_WALL: Texture2D = preload("res://graphics/coast/ship_wall.png")
const SHIP_RIB: Texture2D = preload("res://graphics/coast/ship_rib.png")
const CARGO: Texture2D = preload("res://graphics/coast/cargo.png")
const CRATE: Texture2D = preload("res://graphics/coast/crate.png")
const BARREL: Texture2D = preload("res://graphics/coast/barrel.png")
const CANDLE: Texture2D = preload("res://graphics/monastery/candle.png")
const TIDE_POOL: Texture2D = preload("res://graphics/coast/tide_pool.png")
const LENS: Texture2D = preload("res://graphics/coast/wreck_lens.png")
const DOOR: Texture2D = preload("res://graphics/coast/door_wood.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")
const ENEMY_SCENE: PackedScene = preload("res://scenes/coast/coast_enemy.tscn")
const FENCE_GATE_SCENE: PackedScene = preload("res://scenes/coast/fence_gate.tscn")

const ENTRANCE := Vector2(320, 330)
const LENS_POS := Vector2(320, 140)
const EXIT_POS := Vector2(320, 386)

var lens_sprite: Sprite2D
var lens_glow: Sprite2D
var lens_label: Label
var lens_gate: Node2D


func on_scene_ready() -> void:
	build_room()
	resolve_spawn(ENTRANCE, {"entrance": ENTRANCE})
	player.set_spawn_position(player.global_position)
	hud.call("show_banner", "沉船内部", "搁浅的旧帆船", 2.2)
	_build_props()
	_build_falcon()
	_refresh_objective()


func _draw() -> void:
	draw_rect(Rect2(-120, -120, 880, 680), Color(0.035, 0.03, 0.027))


func build_room() -> void:
	var modulate_node := CanvasModulate.new()
	modulate_node.color = Color(0.92, 0.8, 0.7)
	add_child(modulate_node)
	_floor(Rect2(100, 100, 440, 280), WOOD, 1201)
	_wall(Rect2(80, 80, 480, 20))
	_wall(Rect2(80, 100, 20, 280))
	_wall(Rect2(540, 100, 20, 280))
	_wall(Rect2(80, 380, 220, 20))
	_wall(Rect2(340, 380, 220, 20))
	_floor(Rect2(300, 380, 40, 20), WOOD, 1202)


func _floor(rect: Rect2, tex: Texture2D, seed: int) -> void:
	add_tile_area(rect, tex, _choices(), 2, seed)


func _choices() -> Array[Vector2i]:
	return [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
	]


func _wall(rect: Rect2) -> void:
	var layer := add_tile_area(rect, SHIP_WALL, _choices(), 2, int(rect.position.x + rect.position.y))
	layer.z_index = 0
	add_blocker(rect)


func _prop(tex: Texture2D, pos: Vector2, prop_scale: float = 2.0, flip: bool = false) -> Sprite2D:
	var sprite := add_sprite(tex, pos, prop_scale)
	sprite.position = pos + Vector2(0, 2.0 - tex.get_height() * prop_scale * 0.5)
	sprite.flip_h = flip
	sprite.z_index = 4
	return sprite


func _build_props() -> void:
	for pos in [Vector2(140, 160), Vector2(500, 160), Vector2(140, 320), Vector2(500, 320)]:
		_prop(SHIP_RIB, pos, 1.0)
	_prop(CRATE, Vector2(180, 300), 1.0)
	_prop(BARREL, Vector2(460, 300), 1.0)
	_prop(CARGO, Vector2(180, 350), 0.8)
	_prop(TIDE_POOL, Vector2(400, 330), 0.9)
	_prop(CANDLE, Vector2(230, 160), 1.5)
	var candle_glow := add_sprite(GLOW, Vector2(230, 136), 1.4)
	candle_glow.modulate = Color(1.0, 0.55, 0.2, 0.28)
	candle_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	candle_glow.z_index = 3
	_prop(DOOR, Vector2(320, 386), 1.2)
	add_world_label("船尾出口", Vector2(265, 400), 7, Color(0.9, 0.8, 0.62))

	lens_sprite = _prop(LENS, LENS_POS, 2.0)
	lens_glow = add_sprite(GLOW, LENS_POS + Vector2(0, -18), 1.9)
	lens_glow.modulate = Color(1.0, 0.72, 0.28, 0.4)
	lens_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	lens_glow.z_index = 3
	lens_label = add_world_label("灯塔透镜", LENS_POS + Vector2(-55, -44), 7, Color(1.0, 0.84, 0.5))
	if Global.coast_lens_found:
		lens_sprite.visible = false
		lens_glow.visible = false
		lens_label.visible = false
	lens_gate = FENCE_GATE_SCENE.instantiate() as Node2D
	objects.add_child(lens_gate)
	lens_gate.call("setup", Vector2(320, 190), 440.0, 44.0, Global.coast_falcon_defeated)


func _build_falcon() -> void:
	if Global.coast_lens_found or Global.coast_falcon_defeated:
		return
	var falcon := ENEMY_SCENE.instantiate() as Node2D
	falcon.call("configure", "cinder_falcon")
	falcon.position = Vector2(320, 300)
	objects.add_child(falcon)
	falcon.call("set_leash_rect", Rect2(120, 270, 400, 110))
	falcon.connect("died", _on_falcon_died)


func _on_falcon_died() -> void:
	if Global.coast_falcon_defeated:
		return
	Global.coast_falcon_defeated = true
	SaveGame.save_game("沉船内部")
	if lens_gate != null and is_instance_valid(lens_gate):
		lens_gate.call("open")
	hud.call("show_notice", "烬隼倒下了，透镜围栏打开了")
	_refresh_objective()
	Sfx.play("craft", 1.0, 1.5)


func _refresh_objective() -> void:
	if Global.coast_lens_found:
		set_objective("离开沉船")
		set_tutorial("透镜已经取走，从船尾的门返回海岸")
	elif Global.coast_falcon_defeated:
		set_objective("拾取灯塔透镜")
		set_tutorial("围栏已经打开，走进围栏拿取透镜")
	else:
		set_objective("击败船舱里的烬隼")
		set_tutorial("透镜就在围栏后面，击败烬隼才能打开围栏")


func on_scene_process(_delta: float) -> void:
	if player == null:
		return
	var interact_text := "[%s]" % Settings.binding_text("interact")
	if not Global.coast_lens_found and Global.coast_falcon_defeated and player.global_position.distance_to(LENS_POS) <= 38.0:
		hud.call("show_interaction", "%s 拾取灯塔透镜" % interact_text)
		if Input.is_action_just_pressed("interact"):
			_pick_lens()
		return
	if player.global_position.distance_to(EXIT_POS) <= 40.0:
		hud.call("show_interaction", "%s 离开沉船" % interact_text)
		if Input.is_action_just_pressed("interact"):
			travel_to("res://scenes/coast/coast.tscn", "wreck_exit")
		return
	hud.call("clear_interaction")


func _pick_lens() -> void:
	if Global.coast_lens_found:
		return
	Global.coast_lens_found = true
	SaveGame.save_game("沉船内部")
	lens_sprite.visible = false
	lens_glow.visible = false
	lens_label.visible = false
	hud.call("show_notice", "获得灯塔透镜，从船尾的门返回海岸")
	_refresh_objective()
	Sfx.play("craft", 1.0, 1.5)


func on_after_revive() -> void:
	player.global_position = ENTRANCE
	_refresh_objective()
