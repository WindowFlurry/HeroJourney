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
const COAST_GATE_SCENE: PackedScene = preload("res://scenes/level/coast_gate.tscn")

const TILE_CHOICES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
]
const CARPET_CHOICES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]

const NAV_CELL := 32
const NAV_MIN := Vector2(64, 48)
const NAV_MAX := Vector2(1696, 1328)

const ENTRANCE := Vector2(888, 1270)
const CHECKPOINT := Vector2(888, 850)
const CHEST_POS := Vector2(330, 650)
const LEVER_POS := Vector2(1440, 650)
const LORE_POS := Vector2(230, 570)
const CHAPEL_DOOR_RECT := Rect2(848, 352, 80, 32)
const CANDLE_POSITIONS: Array[Vector2] = [
	Vector2(330, 1080),
	Vector2(220, 740),
	Vector2(1550, 740),
]

var boss
var boss_started := false
var chapel_door: StaticBody2D
var chapel_door_visual: Sprite2D
var checkpoint_pos := ENTRANCE
var lore_seen := false
var stele
var objective_done := false
var candles: Array = []
var nav_walkable := {}
var nav_cols := 0
var nav_rows := 0
var nav_astar: AStarGrid2D


func on_scene_ready() -> void:
	add_to_group("MonasteryNav")
	build_monastery()
	resolve_spawn(ENTRANCE)
	player.set_spawn_position(player.global_position)
	checkpoint_pos = player.global_position
	hud.call("show_banner", "失誓修道院", "雾中的墓园与失誓者", 2.8)
	refresh_objective()
	if Global.second_stele_lit:
		objective_done = true
	await get_tree().physics_frame
	_build_nav_grid()
	_build_enemies()
	_build_boss()
	_build_stele()
	_build_coast_gate()
	if _candle_count() >= 3 and boss != null and is_instance_valid(boss):
		boss.call("apply_shield_weakness")


func refresh_objective() -> void:
	var lit := _candle_count()
	if Global.second_stele_lit:
		set_objective("失誓修道院已净化")
		set_tutorial("祭坛旁的誓火石碑已经点燃")
	elif Global.roland_defeated:
		set_objective("点燃第二座誓火石碑")
		set_tutorial("石碑在礼拜堂祭坛前")
	elif boss_started:
		set_objective("击败失誓骑士罗兰")
		if lit >= 3:
			set_tutorial("三盏残烛的圣火削弱了罗兰的护盾")
		else:
			set_tutorial("观察剑光与冲锋预警，护盾期间不要硬拼")
	elif Global.monastery_chapel_open:
		set_objective("进入礼拜堂")
		set_tutorial("穿过礼拜堂大门，面对失誓骑士罗兰")
	elif Global.monastery_chest_opened and not Global.monastery_right_seal:
		set_objective("前往钟楼拉下铁闸")
		set_tutorial("钟楼在礼拜堂右侧 · 残烛 %d/3" % lit)
	elif Global.monastery_right_seal and not Global.monastery_chest_opened:
		set_objective("前往圣物室解开封印")
		set_tutorial("圣物室在礼拜堂左侧 · 残烛 %d/3" % lit)
	else:
		set_objective("打开圣物室与钟楼的封印")
		set_tutorial("圣物室在左，钟楼在右 · 残烛 %d/3（点亮可削弱罗兰）" % lit)


func _draw() -> void:
	draw_rect(Rect2(-200, -200, 2200, 1800), Color(0.045, 0.05, 0.07))


func build_monastery() -> void:
	var modulate_node := CanvasModulate.new()
	modulate_node.color = Color(0.76, 0.79, 0.9)
	add_child(modulate_node)

	# 南侧入口庭院
	_floor(Rect2(608, 1216, 560, 112), GRAVEYARD, 700)
	# 墓地
	_floor(Rect2(288, 928, 1200, 256), GRAVEYARD, 701)
	# 礼拜堂、中殿、左右侧室
	_floor(Rect2(376, 64, 1024, 288), FLOOR, 702)
	_floor(Rect2(504, 384, 768, 512), FLOOR, 703)
	_floor(Rect2(184, 512, 288, 288), FLOOR, 704)
	_floor(Rect2(1304, 512, 288, 288), FLOOR, 705)
	# 门洞地面
	_floor(Rect2(848, 352, 80, 32), FLOOR, 706)
	_floor(Rect2(848, 896, 80, 32), FLOOR, 707)
	_floor(Rect2(848, 1184, 80, 32), FLOOR, 708)
	_floor(Rect2(472, 608, 32, 64), FLOOR, 709)
	_floor(Rect2(1272, 608, 32, 64), FLOOR, 710)
	# 中央红毯
	add_tile_area(Rect2(872, 96, 32, 800), CARPET, CARPET_CHOICES, 2, 711)

	# 外墙
	_wall(Rect2(48, 32, 1680, 16))
	_wall(Rect2(48, 32, 16, 1312))
	_wall(Rect2(1712, 32, 16, 1312))
	_wall(Rect2(48, 1328, 800, 16))
	_wall(Rect2(928, 1328, 800, 16))
	# 入口外侧的隐形挡板，防止玩家走出地图
	add_blocker(Rect2(848, 1344, 80, 16))

	# 礼拜堂
	_wall(Rect2(344, 48, 1088, 16))
	_wall(Rect2(344, 64, 32, 288))
	_wall(Rect2(1400, 64, 32, 288))
	_wall(Rect2(344, 352, 504, 32))
	_wall(Rect2(928, 352, 504, 32))

	# 中殿
	_wall(Rect2(472, 384, 32, 224))
	_wall(Rect2(472, 672, 32, 224))
	_wall(Rect2(1272, 384, 32, 224))
	_wall(Rect2(1272, 672, 32, 224))

	# 侧室
	_wall(Rect2(152, 480, 320, 32))
	_wall(Rect2(152, 512, 32, 288))
	_wall(Rect2(152, 800, 320, 32))
	_wall(Rect2(1304, 480, 320, 32))
	_wall(Rect2(1592, 512, 32, 288))
	_wall(Rect2(1304, 800, 320, 32))

	# 墓地与中殿、入口之间的墙
	_wall(Rect2(256, 896, 592, 32))
	_wall(Rect2(928, 896, 592, 32))
	_wall(Rect2(256, 928, 32, 256))
	_wall(Rect2(1488, 928, 32, 256))
	_wall(Rect2(256, 1184, 592, 32))
	_wall(Rect2(928, 1184, 592, 32))

	# 入口庭院两侧
	_wall(Rect2(576, 1216, 32, 112))
	_wall(Rect2(1168, 1216, 32, 112))

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
	# 入口庭院
	_prop(PILLAR, Vector2(824, 1216), 2.2)
	_prop(PILLAR, Vector2(952, 1216), 2.2)
	_prop(FENCE, Vector2(1040, 1250), 2.0, false)
	_prop(DEAD_TREE, Vector2(650, 1258), 2.0, true)
	_prop(DEAD_TREE, Vector2(1126, 1258), 2.0, false)
	_prop(RUBBLE, Vector2(700, 1296), 1.5)
	_prop(RUBBLE, Vector2(1076, 1296), 1.5)
	for pos in [Vector2(790, 1276), Vector2(986, 1276)]:
		_prop(CANDLE, pos, 2.0)
		_glow(pos, Color(1.0, 0.55, 0.2, 0.35), 1.8)

	# 墓地
	for pos in [
		Vector2(380, 980), Vector2(520, 1020), Vector2(700, 970),
		Vector2(1100, 980), Vector2(1260, 1020), Vector2(1400, 980),
		Vector2(420, 1120), Vector2(1080, 1120), Vector2(1330, 1130),
	]:
		_prop(GRAVESTONE, pos, 1.8, pos.x > 888.0)
	for pos in [Vector2(320, 1150), Vector2(1450, 1150), Vector2(600, 1150)]:
		_prop(FENCE, pos, 2.0, false)
	_prop(DEAD_TREE, Vector2(300, 950), 2.2, true)
	_prop(DEAD_TREE, Vector2(1470, 950), 2.2, false)
	_prop(DEAD_TREE, Vector2(760, 1150), 2.0, true)
	_prop(DEAD_TREE, Vector2(1010, 1150), 2.0, false)
	_prop(RUBBLE, Vector2(640, 1080), 1.5)
	_prop(RUBBLE, Vector2(1180, 1080), 1.5)
	_prop(RUBBLE, Vector2(900, 1120), 1.5)

	# 中殿
	for pos in [Vector2(620, 430), Vector2(620, 850), Vector2(1156, 430), Vector2(1156, 850)]:
		_prop(PILLAR, pos, 2.0)
		add_blocker(Rect2(pos.x - 8, pos.y - 18, 16, 18))
	for y in [430, 470, 540, 700, 770, 830]:
		for x in [690, 1086]:
			_prop(PEW, Vector2(x, y), 2.0, x > 888.0)
			add_blocker(Rect2(x - 28, y - 8, 56, 14))
	_prop(BANNER, Vector2(560, 430), 2.0)
	_prop(BANNER, Vector2(1216, 430), 2.0, true)
	for pos in [Vector2(560, 610), Vector2(1216, 610)]:
		_prop(CANDLE, pos, 2.0)
		_glow(pos, Color(1.0, 0.55, 0.2, 0.35), 1.8)

	# 侧室
	_prop(RELIQUARY, CHEST_POS, 1.6)
	add_world_label("补给", CHEST_POS + Vector2(-24, -34), 7, Color(1.0, 0.84, 0.5))
	_prop(GRAVESTONE, LORE_POS, 1.5)
	add_world_label("老骑士手记", LORE_POS + Vector2(-38, -34), 7, Color(0.86, 0.82, 0.7))
	_prop(LEVER, LEVER_POS, 2.0)
	_glow(LEVER_POS, Color(0.55, 0.75, 1.0, 0.25), 1.5)
	for pos in [Vector2(400, 600), Vector2(1370, 600)]:
		_prop(CANDLE, pos, 2.0)
		_glow(pos, Color(1.0, 0.55, 0.2, 0.35), 1.8)
	add_world_label("钟楼铁闸", LEVER_POS + Vector2(-42, -36), 7, Color(0.8, 0.86, 1.0))
	add_world_label("圣物室", Vector2(190, 500), 8, Color(0.82, 0.78, 0.66))
	add_world_label("钟楼", Vector2(1450, 500), 8, Color(0.82, 0.86, 1.0))
	add_world_label("← 圣物室", Vector2(510, 584), 7, Color(0.82, 0.78, 0.66))
	add_world_label("钟楼 →", Vector2(1168, 584), 7, Color(0.82, 0.86, 1.0))

	# 存档点
	_prop(ALTAR, CHECKPOINT, 1.2)
	_prop(CANDLE, CHECKPOINT + Vector2(-18, 10), 1.8)
	_prop(CANDLE, CHECKPOINT + Vector2(18, 10), 1.8)
	_glow(CHECKPOINT, Color(1.0, 0.62, 0.25, 0.4), 2.2)
	add_world_label("存档点", CHECKPOINT + Vector2(-30, -38), 7, Color(1.0, 0.86, 0.55))

	# 礼拜堂
	_prop(ALTAR, Vector2(888, 150), 2.0)
	for pos in [Vector2(470, 200), Vector2(470, 310), Vector2(1306, 200), Vector2(1306, 310)]:
		_prop(PILLAR, pos, 2.0)
	for pos in [Vector2(600, 65), Vector2(888, 65), Vector2(1176, 65)]:
		_prop(GLASS, pos, 2.0)
		_glow(pos + Vector2(0, 24), Color(0.45, 0.65, 1.0, 0.25), 2.4)
	for pos in [Vector2(440, 110), Vector2(1336, 110)]:
		_prop(BANNER, pos, 2.0, pos.x > 888.0)
	for pos in [Vector2(500, 320), Vector2(1276, 320), Vector2(700, 300), Vector2(1076, 300)]:
		_prop(CANDLE, pos, 2.0)
		_glow(pos, Color(1.0, 0.55, 0.2, 0.35), 1.8)
	add_world_label("礼拜堂", Vector2(833, 300), 8, Color(1.0, 0.84, 0.55))

	_build_candles()


func _build_candles() -> void:
	candles.clear()
	for i in CANDLE_POSITIONS.size():
		var pos := CANDLE_POSITIONS[i]
		var candle_sprite := _prop(CANDLE, pos, 2.4)
		var glow := add_sprite(GLOW, pos + Vector2(0, -28), 1.9)
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		glow.z_index = 2
		var label := add_world_label("残烛", pos + Vector2(-55, -60), 7, Color(0.78, 0.75, 0.68))
		candles.append({
			"pos": pos,
			"sprite": candle_sprite,
			"glow": glow,
			"label": label,
		})
		_refresh_candle_visual(i)


func _is_candle_lit(index: int) -> bool:
	return (int(Global.monastery_candles_lit) & (1 << index)) != 0


func _candle_count() -> int:
	var count := 0
	for i in CANDLE_POSITIONS.size():
		if _is_candle_lit(i):
			count += 1
	return count


func _refresh_candle_visual(index: int) -> void:
	if index < 0 or index >= candles.size():
		return
	var entry: Dictionary = candles[index]
	var lit := _is_candle_lit(index)
	var candle_sprite: Sprite2D = entry["sprite"]
	candle_sprite.modulate = Color.WHITE if lit else Color(0.55, 0.55, 0.62)
	var glow: Sprite2D = entry["glow"]
	glow.modulate = Color(1.0, 0.55, 0.2, 0.38) if lit else Color(0.0, 0.0, 0.0, 0.0)
	var label: Label = entry["label"]
	label.text = "残烛（已燃）" if lit else "残烛"
	label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55) if lit else Color(0.78, 0.75, 0.68))


func _light_candle(index: int) -> void:
	if _is_candle_lit(index):
		return
	Global.monastery_candles_lit |= (1 << index)
	_refresh_candle_visual(index)
	var count := _candle_count()
	player.call("heal_by", 20)
	player.call("apply_holy_blessing", 60.0, 3)
	SaveGame.save_game("失誓修道院")
	if count >= 3:
		if boss != null and is_instance_valid(boss):
			boss.call("apply_shield_weakness")
		hud.call("show_notice", "三盏残烛的圣火汇聚：攻击 +3，罗兰的护盾被削弱")
	else:
		hud.call("show_notice", "残烛已点燃（%d/3）：恢复 20 生命，攻击 +3（60 秒）" % count)
	refresh_objective()


func _build_chapel_door() -> void:
	chapel_door = add_blocker(CHAPEL_DOOR_RECT)
	chapel_door_visual = _prop(FENCE, Vector2(888, 382), 2.6)
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
		["mourner", Vector2(500, 1020)],
		["bone_gleaner", Vector2(1300, 1040)],
		["mourner", Vector2(820, 980)],
		["bone_gleaner", Vector2(600, 760)],
		["mourner", Vector2(1180, 760)],
		["bone_gleaner", Vector2(800, 470)],
		["mourner", Vector2(1000, 470)],
		["mourner", Vector2(380, 560)],
		["bone_gleaner", Vector2(360, 730)],
		["mourner", Vector2(1500, 580)],
		["ember_crown", Vector2(1430, 740)],
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
	boss.position = Vector2(888, 230)
	objects.add_child(boss)
	boss.connect("died", _on_boss_died)


func _build_stele() -> void:
	stele = STELE_SCENE.instantiate() as Node2D
	stele.set("reveal_flag", "roland_defeated")
	stele.set("lit_flag", "second_stele_lit")
	stele.set("reveal_notice", "失誓骑士罗兰倒下了，誓火石碑显现")
	stele.set("lit_notice", "誓火石碑已点燃，失誓修道院得到净化；礼拜堂右侧出现了通往赤烬海岸的门")
	stele.set("victory_title", "第二关完成")
	stele.set("victory_location", "失誓修道院")
	stele.set("reveal_delay", 1.0)
	stele.position = Vector2(888, 110)
	stele.scale = Vector2(1.5, 1.5)
	objects.add_child(stele)


func _build_coast_gate() -> void:
	var coast_gate := COAST_GATE_SCENE.instantiate() as Node2D
	coast_gate.position = Vector2(1180, 290)
	objects.add_child(coast_gate)


func _build_nav_grid() -> void:
	nav_walkable.clear()
	nav_cols = int((NAV_MAX.x - NAV_MIN.x) / NAV_CELL)
	nav_rows = int((NAV_MAX.y - NAV_MIN.y) / NAV_CELL)
	nav_astar = AStarGrid2D.new()
	nav_astar.region = Rect2i(0, 0, nav_cols, nav_rows)
	nav_astar.cell_size = Vector2(NAV_CELL, NAV_CELL)
	nav_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	nav_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	nav_astar.update()
	for y in nav_rows:
		for x in nav_cols:
			var center := NAV_MIN + (Vector2(x, y) + Vector2(0.5, 0.5)) * NAV_CELL
			var params := PhysicsPointQueryParameters2D.new()
			params.position = center + Vector2(0, -5)
			params.collision_mask = 1
			params.collide_with_areas = false
			var hits := get_world_2d().direct_space_state.intersect_point(params, 1)
			var walkable := hits.is_empty()
			nav_walkable[Vector2i(x, y)] = walkable
			if not walkable:
				nav_astar.set_point_solid(Vector2i(x, y), true)


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


func find_path(from: Vector2, to: Vector2) -> Array:
	if nav_astar == null or nav_walkable.is_empty():
		return []
	var start := _nav_nearest_walkable(_nav_cell_for(from))
	var goal := _nav_nearest_walkable(_nav_cell_for(to))
	if not _nav_walkable(start) or not _nav_walkable(goal):
		return []
	if start == goal:
		return []
	var path: Array = []
	for id in nav_astar.get_id_path(start, goal):
		var cell := Vector2i(int(id.x), int(id.y))
		path.append(NAV_MIN + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * NAV_CELL)
	return path


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

	for i in candles.size():
		if _is_candle_lit(i):
			continue
		var candle_pos: Vector2 = candles[i]["pos"]
		if player.global_position.distance_to(candle_pos) <= 38.0:
			hud.call("show_interaction", "%s 点燃残烛" % interact_text)
			if Input.is_action_just_pressed("interact"):
				_light_candle(i)
			return

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
		and player.global_position.y < 340.0
		and player.global_position.x > 360.0
		and player.global_position.x < 1416.0
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
