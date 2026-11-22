extends "res://scenes/prologue/prologue_scene_base.gd"

const FLOOR: Texture2D = preload("res://graphics/monastery/floor.png")
const WALL: Texture2D = preload("res://graphics/monastery/wall.png")
const GRAVEYARD: Texture2D = preload("res://graphics/monastery/graveyard.png")
const CARPET: Texture2D = preload("res://graphics/monastery/carpet.png")
const PILLAR: Texture2D = preload("res://graphics/monastery/pillar.png")
const PEW: Texture2D = preload("res://graphics/monastery/pew.png")
const CANDLE: Texture2D = preload("res://graphics/monastery/candle.png")
const GRAVESTONE: Texture2D = preload("res://graphics/monastery/gravestone.png")
const FENCE: Texture2D = preload("res://graphics/monastery/iron_fence.png")
const ALTAR: Texture2D = preload("res://graphics/monastery/altar.png")
const GLASS: Texture2D = preload("res://graphics/monastery/stained_glass.png")
const BANNER: Texture2D = preload("res://graphics/monastery/banner.png")
const DEAD_TREE: Texture2D = preload("res://graphics/monastery/dead_tree.png")
const RUBBLE: Texture2D = preload("res://graphics/monastery/rubble.png")
const LEVER: Texture2D = preload("res://graphics/monastery/lever.png")
const RELIQUARY: Texture2D = preload("res://graphics/monastery/reliquary.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")

const ENEMY_SCENE: PackedScene = preload("res://scenes/monastery/monastery_enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/monastery/still_sworn.tscn")
const STELE_SCENE: PackedScene = preload("res://scenes/level/oath_stele.tscn")

const TILE_CHOICES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
]
const CARPET_CHOICES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]

const NAV_CELL := 32
const NAV_MIN := Vector2(48, 32)
const NAV_MAX := Vector2(1072, 768)

const ENTRANCE := Vector2(560, 680)
const CHECKPOINT := Vector2(560, 480)
const CHEST_POS := Vector2(190, 380)
const LEVER_POS := Vector2(960, 380)
const LORE_POS := Vector2(150, 330)
const CHAPEL_DOOR_RECT := Rect2(520, 240, 80, 32)

var boss
var boss_started := false
var chapel_door: StaticBody2D
var chapel_door_visual: Sprite2D
var checkpoint_pos := ENTRANCE
var lore_seen := false
var stele
var objective_done := false
var nav_walkable := {}
var nav_cols := 0
var nav_rows := 0


func on_scene_ready() -> void:
	add_to_group("MonasteryNav")
	build_monastery()
	resolve_spawn(ENTRANCE)
	player.set_spawn_position(player.global_position)
	checkpoint_pos = player.global_position
	hud.call("show_banner", "失誓修道院", "失誓者沉眠的旧礼拜堂", 2.8)
	refresh_objective()
	if Global.second_stele_lit:
		objective_done = true
	await get_tree().physics_frame
	_build_nav_grid()
	_build_enemies()
	_build_boss()
	_build_stele()


func refresh_objective() -> void:
	if Global.second_stele_lit:
		set_objective("失誓修道院已净化")
		set_tutorial("祭坛旁的誓火石碑已经点燃")
	elif Global.roland_defeated:
		set_objective("点燃第二座誓火石碑")
		set_tutorial("石碑在礼拜堂祭坛前")
	elif boss_started:
		set_objective("击败失誓骑士罗兰")
		set_tutorial("观察剑光与冲锋预警，护盾期间不要硬拼")
	elif Global.monastery_chapel_open:
		set_objective("进入礼拜堂")
		set_tutorial("穿过礼拜堂大门，面对失誓骑士罗兰")
	elif Global.monastery_chest_opened and not Global.monastery_right_seal:
		set_objective("前往钟楼拉下铁闸")
		set_tutorial("钟楼在礼拜堂右侧")
	elif Global.monastery_right_seal and not Global.monastery_chest_opened:
		set_objective("前往圣物室解开封印")
		set_tutorial("圣物室在礼拜堂左侧")
	else:
		set_objective("打开圣物室与钟楼的封印")
		set_tutorial("圣物室在左，钟楼在右")


func _draw() -> void:
	draw_rect(Rect2(-100, -100, 1400, 1000), Color(0.045, 0.05, 0.07))


func build_monastery() -> void:
	var modulate_node := CanvasModulate.new()
	modulate_node.color = Color(0.76, 0.79, 0.9)
	add_child(modulate_node)

	# 墓地
	_floor(Rect2(160, 552, 800, 168), GRAVEYARD, 701)
	# 礼拜堂、中殿、左右侧室
	_floor(Rect2(240, 80, 640, 160), FLOOR, 702)
	_floor(Rect2(320, 240, 480, 280), FLOOR, 703)
	_floor(Rect2(96, 288, 192, 176), FLOOR, 704)
	_floor(Rect2(832, 288, 192, 176), FLOOR, 705)
	# 门洞地面
	_floor(Rect2(520, 240, 80, 32), FLOOR, 706)
	_floor(Rect2(520, 520, 80, 32), FLOOR, 707)
	_floor(Rect2(288, 352, 32, 64), FLOOR, 708)
	_floor(Rect2(800, 352, 32, 64), FLOOR, 709)
	# 中央红毯
	add_tile_area(Rect2(544, 80, 32, 640), CARPET, CARPET_CHOICES, 2, 710)

	# 外墙
	_wall(Rect2(48, 32, 1024, 16))
	_wall(Rect2(48, 32, 16, 720))
	_wall(Rect2(1056, 32, 16, 720))
	_wall(Rect2(48, 752, 1024, 16))

	# 礼拜堂
	_wall(Rect2(208, 48, 704, 32))
	_wall(Rect2(208, 48, 32, 224))
	_wall(Rect2(880, 48, 32, 224))
	_wall(Rect2(208, 240, 312, 32))
	_wall(Rect2(600, 240, 312, 32))

	# 中殿与侧室共用的墙
	_wall(Rect2(288, 256, 32, 96))
	_wall(Rect2(288, 416, 32, 104))
	_wall(Rect2(800, 256, 32, 96))
	_wall(Rect2(800, 416, 32, 104))
	# 侧室外墙
	_wall(Rect2(64, 256, 256, 32))
	_wall(Rect2(64, 464, 256, 32))
	_wall(Rect2(64, 256, 32, 240))
	_wall(Rect2(800, 256, 256, 32))
	_wall(Rect2(800, 464, 256, 32))
	_wall(Rect2(1024, 256, 32, 240))
	# 中殿底部与墓地
	_wall(Rect2(288, 520, 232, 32))
	_wall(Rect2(600, 520, 232, 32))
	_wall(Rect2(160, 520, 360, 32))
	_wall(Rect2(600, 520, 360, 32))
	_wall(Rect2(128, 520, 32, 232))
	_wall(Rect2(960, 520, 32, 232))
	_wall(Rect2(128, 720, 864, 32))

	_build_chapel_door()
	_build_props()


func _floor(rect: Rect2, tex: Texture2D, seed: int) -> void:
	add_tile_area(rect, tex, TILE_CHOICES, 2, seed)


func _wall(rect: Rect2) -> void:
	add_tile_area(rect, WALL, TILE_CHOICES, 2, int(rect.position.x + rect.position.y * 3))
	add_blocker(rect)


func _prop(tex: Texture2D, pos: Vector2, prop_scale: float = 2.0, flip: bool = false) -> Sprite2D:
	var sprite := add_sprite(tex, pos, prop_scale)
	sprite.position = pos + Vector2(0, 2.0 - tex.get_height() * prop_scale * 0.5)
	sprite.flip_h = flip
	sprite.z_index = 1
	return sprite


func _glow(pos: Vector2, color: Color, glow_scale: float = 2.0) -> void:
	var sprite := add_sprite(GLOW, pos + Vector2(0, -24), glow_scale)
	sprite.modulate = color
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 2


func _build_props() -> void:
	# 墓地
	for pos in [
		Vector2(210, 610), Vector2(280, 650), Vector2(880, 620),
		Vector2(930, 665), Vector2(320, 670), Vector2(820, 575),
	]:
		_prop(GRAVESTONE, pos, 1.8, pos.x > 560.0)
	for pos in [Vector2(250, 690), Vector2(870, 690), Vector2(740, 690)]:
		_prop(FENCE, pos, 2.0, false)
	_prop(DEAD_TREE, Vector2(185, 565), 2.0, true)
	_prop(DEAD_TREE, Vector2(940, 585), 2.0, false)
	_prop(RUBBLE, Vector2(450, 660), 1.5)
	_prop(RUBBLE, Vector2(700, 640), 1.5)

	# 中殿
	for pos in [Vector2(360, 300), Vector2(360, 440), Vector2(760, 300), Vector2(760, 440)]:
		_prop(PILLAR, pos, 2.0)
		add_blocker(Rect2(pos.x - 8, pos.y - 18, 16, 18))
	for pos in [Vector2(410, 340), Vector2(410, 420), Vector2(650, 340), Vector2(650, 420)]:
		_prop(PEW, pos, 2.0, pos.x > 560.0)
		add_blocker(Rect2(pos.x - 28, pos.y - 8, 56, 14))
	_prop(BANNER, Vector2(320, 300), 2.0)
	_prop(BANNER, Vector2(800, 300), 2.0, true)
	for pos in [Vector2(330, 470), Vector2(790, 470)]:
		_prop(CANDLE, pos, 2.0)
		_glow(pos, Color(1.0, 0.55, 0.2, 0.35), 1.8)

	# 侧室
	_prop(RELIQUARY, CHEST_POS, 1.6)
	add_world_label("补给", CHEST_POS + Vector2(-24, -34), 7, Color(1.0, 0.84, 0.5))
	_prop(GRAVESTONE, LORE_POS, 1.5)
	add_world_label("老骑士手记", LORE_POS + Vector2(-38, -34), 7, Color(0.86, 0.82, 0.7))
	_prop(LEVER, LEVER_POS, 2.0)
	_glow(LEVER_POS, Color(0.55, 0.75, 1.0, 0.25), 1.5)
	for pos in [Vector2(170, 330), Vector2(930, 340)]:
		_prop(CANDLE, pos, 2.0)
		_glow(pos, Color(1.0, 0.55, 0.2, 0.35), 1.8)
	add_world_label("钟楼铁闸", LEVER_POS + Vector2(-42, -36), 7, Color(0.8, 0.86, 1.0))
	add_world_label("圣物室", Vector2(140, 260), 8, Color(0.82, 0.78, 0.66))

	# 存档点
	_prop(ALTAR, CHECKPOINT, 1.2)
	_prop(CANDLE, CHECKPOINT + Vector2(-18, 10), 1.8)
	_prop(CANDLE, CHECKPOINT + Vector2(18, 10), 1.8)
	_glow(CHECKPOINT, Color(1.0, 0.62, 0.25, 0.4), 2.2)
	add_world_label("存档点", CHECKPOINT + Vector2(-30, -38), 7, Color(1.0, 0.86, 0.55))

	# 礼拜堂
	_prop(ALTAR, Vector2(560, 130), 2.0)
	for pos in [Vector2(420, 65), Vector2(560, 65), Vector2(700, 65)]:
		_prop(GLASS, pos, 2.0)
		_glow(pos + Vector2(0, 24), Color(0.45, 0.65, 1.0, 0.25), 2.4)
	for pos in [Vector2(280, 110), Vector2(840, 110)]:
		_prop(BANNER, pos, 2.0, pos.x > 560.0)
	for pos in [Vector2(350, 210), Vector2(770, 210), Vector2(420, 180), Vector2(700, 180)]:
		_prop(CANDLE, pos, 2.0)
		_glow(pos, Color(1.0, 0.55, 0.2, 0.35), 1.8)
	add_world_label("礼拜堂", Vector2(500, 210), 8, Color(1.0, 0.84, 0.55))


func _build_chapel_door() -> void:
	chapel_door = add_blocker(CHAPEL_DOOR_RECT)
	chapel_door_visual = _prop(FENCE, Vector2(560, 256), 2.4)
	chapel_door_visual.z_index = 2
	var open := Global.monastery_chapel_open or Global.roland_defeated or Global.second_stele_lit
	_set_chapel_door(open)


func _set_chapel_door(open: bool) -> void:
	if chapel_door != null:
		for child in chapel_door.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", open)
	if chapel_door_visual != null:
		chapel_door_visual.visible = not open


func _build_enemies() -> void:
	for entry in [
		["mourner", Vector2(330, 610)],
		["bone_gleaner", Vector2(760, 620)],
		["mourner", Vector2(860, 570)],
		["bone_gleaner", Vector2(420, 400)],
		["mourner", Vector2(700, 340)],
		["mourner", Vector2(500, 300)],
		["bone_gleaner", Vector2(220, 430)],
		["mourner", Vector2(150, 420)],
		["ember_crown", Vector2(930, 380)],
	]:
		_spawn_enemy(str(entry[0]), entry[1])


func _spawn_enemy(kind: String, pos: Vector2) -> void:
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	enemy.call("configure", kind)
	enemy.position = pos
	objects.add_child(enemy)


func _build_boss() -> void:
	if Global.roland_defeated:
		return
	boss = BOSS_SCENE.instantiate() as Node2D
	boss.position = Vector2(560, 170)
	objects.add_child(boss)
	boss.connect("died", _on_boss_died)


func _build_stele() -> void:
	stele = STELE_SCENE.instantiate() as Node2D
	stele.set("reveal_flag", "roland_defeated")
	stele.set("lit_flag", "second_stele_lit")
	stele.set("reveal_notice", "失誓骑士罗兰倒下了，誓火石碑显现")
	stele.set("lit_notice", "誓火石碑已点燃，失誓修道院得到净化")
	stele.set("victory_title", "第二关完成")
	stele.set("victory_location", "失誓修道院")
	stele.set("reveal_delay", 1.0)
	stele.position = Vector2(560, 100)
	stele.scale = Vector2(1.5, 1.5)
	objects.add_child(stele)


func _build_nav_grid() -> void:
	nav_walkable.clear()
	nav_cols = int((NAV_MAX.x - NAV_MIN.x) / NAV_CELL)
	nav_rows = int((NAV_MAX.y - NAV_MIN.y) / NAV_CELL)
	for y in nav_rows:
		for x in nav_cols:
			var center := NAV_MIN + (Vector2(x, y) + Vector2(0.5, 0.5)) * NAV_CELL
			var params := PhysicsPointQueryParameters2D.new()
			params.position = center + Vector2(0, -5)
			params.collision_mask = 1
			params.collide_with_areas = false
			var hits := get_world_2d().direct_space_state.intersect_point(params, 1)
			nav_walkable[Vector2i(x, y)] = hits.is_empty()


func _nav_cell_for(pos: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int((pos.x - NAV_MIN.x) / NAV_CELL), 0, maxi(nav_cols - 1, 0)),
		clampi(int((pos.y - NAV_MIN.y) / NAV_CELL), 0, maxi(nav_rows - 1, 0))
	)


func _nav_walkable(cell: Vector2i) -> bool:
	return bool(nav_walkable.get(cell, false))


func _nav_nearest_walkable(cell: Vector2i) -> Vector2i:
	if _nav_walkable(cell):
		return cell
	for radius in range(1, 5):
		for dx in range(-radius, radius + 1):
			for dy in [-radius, radius]:
				var candidate := cell + Vector2i(dx, dy)
				if _nav_walkable(candidate):
					return candidate
		for dy in range(-radius + 1, radius):
			for dx in [-radius, radius]:
				var candidate := cell + Vector2i(dx, dy)
				if _nav_walkable(candidate):
					return candidate
	return cell


func _nav_h(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func find_path(from: Vector2, to: Vector2) -> Array:
	if nav_walkable.is_empty():
		return []
	var start := _nav_nearest_walkable(_nav_cell_for(from))
	var goal := _nav_nearest_walkable(_nav_cell_for(to))
	if not _nav_walkable(start) or not _nav_walkable(goal):
		return []
	if start == goal:
		return []
	var open := {start: 0}
	var came := {}
	var g := {start: 0}
	var f := {start: _nav_h(start, goal)}
	var closed := {}
	while not open.is_empty():
		var current := start
		var best := INF
		for candidate in open:
			var value := float(f[candidate])
			if value < best:
				best = value
				current = candidate
		if current == goal:
			var path: Array = []
			var cursor := goal
			while cursor != start:
				path.push_front(NAV_MIN + (Vector2(cursor.x, cursor.y) + Vector2(0.5, 0.5)) * NAV_CELL)
				cursor = came[cursor]
			return path
		open.erase(current)
		closed[current] = true
		for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor: Vector2i = current + direction
			if not _nav_walkable(neighbor) or closed.has(neighbor):
				continue
			var tentative := float(g[current]) + 1.0
			if tentative < float(g.get(neighbor, INF)):
				came[neighbor] = current
				g[neighbor] = tentative
				f[neighbor] = tentative + _nav_h(neighbor, goal)
				open[neighbor] = tentative
	return []


func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.collide_with_areas = false
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func on_scene_process(_delta: float) -> void:
	if player == null:
		return
	if Global.second_stele_lit and not objective_done:
		objective_done = true
		refresh_objective()
		return

	var interact_text := "[%s]" % Settings.binding_text("interact")

	if not Global.monastery_chapel_open:
		if not Global.monastery_right_seal and player.global_position.distance_to(LEVER_POS) <= 44.0:
			hud.call("show_interaction", "%s 拉下钟楼铁闸" % interact_text)
			if Input.is_action_just_pressed("interact"):
				_pull_lever()
			return
		if not Global.monastery_chest_opened and player.global_position.distance_to(CHEST_POS) <= 40.0:
			hud.call("show_interaction", "%s 解开圣物室封印" % interact_text)
			if Input.is_action_just_pressed("interact"):
				_open_chest()
			return

	if player.global_position.distance_to(CHECKPOINT) <= 42.0:
		hud.call("show_interaction", "%s 检查蜡烛" % interact_text)
		if Input.is_action_just_pressed("interact"):
			_set_checkpoint()
		return

	if not lore_seen and player.global_position.distance_to(LORE_POS) <= 40.0:
		hud.call("show_interaction", "%s 阅读老骑士手记" % interact_text)
		if Input.is_action_just_pressed("interact"):
			lore_seen = true
			hud.call("show_dialog", "老骑士手记", "罗兰曾是最忠诚的银誓骑士。封印碎裂后，他仍守在礼拜堂，拒绝承认誓约已经背弃。别让他的剑再替龙焰守门。")
		return

	if (
		not boss_started
		and not Global.roland_defeated
		and Global.monastery_chapel_open
		and boss != null
		and player.global_position.y < 245.0
		and player.global_position.x > 240.0
		and player.global_position.x < 880.0
	):
		_start_boss()
		return

	hud.call("clear_interaction")


func _pull_lever() -> void:
	Global.monastery_right_seal = true
	SaveGame.save_game("失誓修道院")
	hud.call("show_notice", "钟楼封印已解除")
	_try_open_chapel()
	refresh_objective()


func _open_chest() -> void:
	Global.monastery_chest_opened = true
	Global.add_item("herb", 2)
	SaveGame.save_game("失誓修道院")
	hud.call("show_notice", "圣物室封印已解除，获得 2 株草药")
	_try_open_chapel()
	refresh_objective()


func _try_open_chapel() -> void:
	if Global.monastery_chapel_open:
		return
	if not Global.monastery_chest_opened or not Global.monastery_right_seal:
		return
	Global.monastery_chapel_open = true
	SaveGame.save_game("失誓修道院")
	_set_chapel_door(true)
	hud.call("show_notice", "两处封印都已解除，礼拜堂大门开启")
	refresh_objective()


func _set_checkpoint() -> void:
	checkpoint_pos = CHECKPOINT
	player.set_spawn_position(CHECKPOINT)
	SaveGame.save_game("失誓修道院回廊")
	hud.call("show_notice", "已记录检查点")


func _start_boss() -> void:
	boss_started = true
	_set_chapel_door(false)
	if boss != null:
		boss.call("activate")
	Sfx.play("danger", 0.55, 0.0)
	hud.call("show_banner", "失誓骑士罗兰", "失誓修道院的守门人", 2.2)
	refresh_objective()


func _on_boss_died() -> void:
	Global.roland_defeated = true
	boss_started = false
	SaveGame.save_game("失誓修道院")
	_set_chapel_door(true)
	hud.call("show_banner", "失誓骑士罗兰倒下了", "失誓的锁链断裂了", 2.2)
	refresh_objective()


func on_after_revive() -> void:
	player.global_position = checkpoint_pos
	if boss_started and not Global.roland_defeated and boss != null and is_instance_valid(boss):
		boss.call("reset_fight")
		boss_started = false
		_set_chapel_door(true)
	refresh_objective()
