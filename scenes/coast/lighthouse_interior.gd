extends "res://scenes/prologue/prologue_scene_base.gd"

const STONE: Texture2D = preload("res://graphics/coast/stone_path.png")
const BASALT: Texture2D = preload("res://graphics/coast/basalt.png")
const STONE_WALL: Texture2D = preload("res://graphics/coast/stone_wall.png")
const BONE_FLOOR: Texture2D = preload("res://graphics/coast/bone_floor.png")
const LENS: Texture2D = preload("res://graphics/coast/wreck_lens.png")
const ALTAR: Texture2D = preload("res://graphics/coast/altar.png")
const BRAZIER: Texture2D = preload("res://graphics/coast/brazier.png")
const LANTERN_POST: Texture2D = preload("res://graphics/coast/lantern_post.png")
const DOOR: Texture2D = preload("res://graphics/coast/door_wood.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")
const FENCE_GATE_SCENE: PackedScene = preload("res://scenes/coast/fence_gate.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/coast/coast_enemy.tscn")

const ENTRANCE := Vector2(320, 340)
const PEDESTAL_POS := Vector2(320, 150)
const EXIT_POS := Vector2(320, 386)

var beam: Line2D
var pedestal_glow: Sprite2D
var fence_gate: Node2D
var guards: Array = []
var guards_remaining := 0


func on_scene_ready() -> void:
	build_room()
	resolve_spawn(ENTRANCE, {"entrance": ENTRANCE})
	player.set_spawn_position(player.global_position)
	hud.call("show_banner", "灯塔灯室", "守塔人的最后一道光", 2.2)
	_build_props()
	_build_guards()
	_refresh_objective()


func _draw() -> void:
	draw_rect(Rect2(-120, -120, 880, 680), Color(0.035, 0.032, 0.03))


func build_room() -> void:
	var modulate_node := CanvasModulate.new()
	modulate_node.color = Color(0.95, 0.84, 0.72)
	add_child(modulate_node)
	_floor(Rect2(120, 100, 400, 280), STONE, 1301)
	_wall(Rect2(100, 80, 440, 20))
	_wall(Rect2(100, 100, 20, 280))
	_wall(Rect2(520, 100, 20, 280))
	_wall(Rect2(100, 380, 200, 20))
	_wall(Rect2(340, 380, 200, 20))
	_floor(Rect2(300, 380, 40, 20), STONE, 1302)


func _floor(rect: Rect2, tex: Texture2D, seed: int) -> void:
	add_tile_area(rect, tex, _choices(), 2, seed)


func _choices() -> Array[Vector2i]:
	return [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
	]


func _wall(rect: Rect2) -> void:
	var layer := add_tile_area(rect, STONE_WALL, _choices(), 2, int(rect.position.x + rect.position.y))
	layer.z_index = 0
	add_blocker(rect)


func _prop(tex: Texture2D, pos: Vector2, prop_scale: float = 2.0, flip: bool = false) -> Sprite2D:
	var sprite := add_sprite(tex, pos, prop_scale)
	sprite.position = pos + Vector2(0, 2.0 - tex.get_height() * prop_scale * 0.5)
	sprite.flip_h = flip
	sprite.z_index = 4
	return sprite


func _build_props() -> void:
	_prop(ALTAR, PEDESTAL_POS, 1.6)
	_prop(LENS, PEDESTAL_POS + Vector2(0, -18), 2.2)
	pedestal_glow = add_sprite(GLOW, PEDESTAL_POS + Vector2(0, -32), 2.0)
	pedestal_glow.modulate = Color(1.0, 0.72, 0.28, 0.38 if Global.coast_lighthouse_lit else 0.12)
	pedestal_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pedestal_glow.z_index = 3
	for pos in [Vector2(180, 170), Vector2(460, 170)]:
		_prop(BRAZIER, pos, 1.0)
		var glow := add_sprite(GLOW, pos + Vector2(0, -20), 1.6)
		glow.modulate = Color(1.0, 0.5, 0.18, 0.3)
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		glow.z_index = 3
	for pos in [Vector2(160, 330), Vector2(480, 330)]:
		_prop(LANTERN_POST, pos, 1.0)
		var glow := add_sprite(GLOW, pos + Vector2(0, -34), 1.3)
		glow.modulate = Color(1.0, 0.7, 0.28, 0.3)
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		glow.z_index = 3
	_prop(DOOR, EXIT_POS, 1.2)
	add_world_label("灯室", Vector2(265, 118), 8, Color(1.0, 0.84, 0.55))
	add_world_label("出口", Vector2(265, 400), 7, Color(0.9, 0.8, 0.62))
	fence_gate = FENCE_GATE_SCENE.instantiate() as Node2D
	objects.add_child(fence_gate)
	fence_gate.call("setup", Vector2(320, 200), 400.0, 44.0,
		Global.coast_lighthouse_guards_defeated or Global.coast_lighthouse_lit)

	beam = Line2D.new()
	beam.points = PackedVector2Array([PEDESTAL_POS + Vector2(0, -30), Vector2(320, -240)])
	beam.width = 8.0
	beam.default_color = Color(1.0, 0.76, 0.34, 0.18)
	beam.z_index = 3
	beam.visible = Global.coast_lighthouse_lit
	objects.add_child(beam)
	var core := Line2D.new()
	core.points = PackedVector2Array([PEDESTAL_POS + Vector2(0, -30), Vector2(320, -240)])
	core.width = 2.0
	core.default_color = Color(1.0, 0.9, 0.55, 0.7)
	core.z_index = 4
	core.visible = Global.coast_lighthouse_lit
	objects.add_child(core)
	beam.set_meta("core", core)


func _build_guards() -> void:
	if Global.coast_lighthouse_guards_defeated or Global.coast_lighthouse_lit:
		return
	for entry in [
		["ash_feather", Vector2(230, 280)],
		["ash_feather", Vector2(410, 280)],
		["slag_skink", Vector2(320, 305)],
	]:
		var guard := ENEMY_SCENE.instantiate() as Node2D
		guard.call("configure", str(entry[0]))
		guard.position = entry[1]
		objects.add_child(guard)
		guard.call("set_leash_rect", Rect2(120, 260, 400, 120))
		guard.connect("died", _on_guard_died)
		guards.append(guard)
	guards_remaining = guards.size()


func _on_guard_died() -> void:
	guards_remaining -= 1
	if guards_remaining > 0:
		return
	Global.coast_lighthouse_guards_defeated = true
	SaveGame.save_game("灯塔灯室")
	if fence_gate != null and is_instance_valid(fence_gate):
		fence_gate.call("open")
	hud.call("show_notice", "灯室守卫倒下了，围栏打开了")
	_refresh_objective()
	Sfx.play("craft", 1.0, 1.5)


func _refresh_objective() -> void:
	if not Global.coast_lighthouse_guards_defeated and not Global.coast_lighthouse_lit:
		set_objective("击败灯室守卫")
		set_tutorial("灯座就在围栏后面，击败守卫才能打开围栏")
	elif not Global.coast_lens_found:
		set_objective("灯塔缺少透镜")
		set_tutorial("透镜还在沉船里，先回海岸去沉船")
	elif not Global.coast_lighthouse_lit:
		set_objective("点亮灯塔")
		set_tutorial("走到灯室中央，把透镜放回灯座")
	elif not Global.coast_tide_key:
		set_objective("返回海岸，取得潮门钥匙")
		set_tutorial("高台上的熔岩蛇蜥持有潮门钥匙")
	else:
		set_objective("灯塔已点亮")
		set_tutorial("返回海岸，潮门已经打开")


func on_scene_process(_delta: float) -> void:
	if player == null:
		return
	var interact_text := "[%s]" % Settings.binding_text("interact")
	if player.global_position.distance_to(EXIT_POS) <= 40.0:
		hud.call("show_interaction", "%s 离开灯塔" % interact_text)
		if Input.is_action_just_pressed("interact"):
			travel_to("res://scenes/coast/coast.tscn", "lighthouse_exit")
		return
	if not Global.coast_lighthouse_guards_defeated and not Global.coast_lighthouse_lit and player.global_position.distance_to(Vector2(320, 200)) <= 46.0:
		hud.call("show_interaction", "围栏锁着：击败灯室守卫")
		return

	if player.global_position.distance_to(PEDESTAL_POS) <= 48.0 and (Global.coast_lighthouse_guards_defeated or Global.coast_lighthouse_lit):
		if not Global.coast_lens_found:
			hud.call("show_interaction", "%s 检查灯室" % interact_text)
			if Input.is_action_just_pressed("interact"):
				hud.call("show_notice", "灯室里没有透镜，去沉船里找找")
			return
		if not Global.coast_lighthouse_lit:
			hud.call("show_interaction", "%s 放置透镜并点亮灯塔" % interact_text)
			if Input.is_action_just_pressed("interact"):
				_light_lighthouse()
			return
		hud.call("show_interaction", "灯塔已经点亮")
		return
	hud.call("clear_interaction")


func _light_lighthouse() -> void:
	if not Global.coast_lens_found or Global.coast_lighthouse_lit:
		return
	Global.coast_lighthouse_lit = true
	SaveGame.save_game("灯塔灯室")
	beam.visible = true
	var core = beam.get_meta("core", null)
	if core != null and is_instance_valid(core):
		core.visible = true
	pedestal_glow.modulate = Color(1.0, 0.72, 0.28, 0.38)
	hud.call("show_notice", "灯塔重新亮起，龙骨祭坛的潮门已经打开")
	_refresh_objective()
	Sfx.play("craft", 1.0, 1.5)


func on_after_revive() -> void:
	player.global_position = ENTRANCE
	_refresh_objective()
