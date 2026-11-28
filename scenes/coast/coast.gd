extends "res://scenes/prologue/prologue_scene_base.gd"

const SAND: Texture2D = preload("res://graphics/coast/sand.png")
const BASALT: Texture2D = preload("res://graphics/coast/basalt.png")
const LAVA: Texture2D = preload("res://graphics/coast/lava.png")
const SEA: Texture2D = preload("res://graphics/coast/sea.png")
const WOOD: Texture2D = preload("res://graphics/coast/wood.png")
const BONE_FLOOR: Texture2D = preload("res://graphics/coast/bone_floor.png")
const ASH: Texture2D = preload("res://graphics/coast/ash.png")
const WET_SAND: Texture2D = preload("res://graphics/coast/wet_sand.png")
const CHARRED: Texture2D = preload("res://graphics/coast/charred.png")
const SEAWEED_GROUND: Texture2D = preload("res://graphics/coast/seaweed_ground.png")
const STONE_PATH: Texture2D = preload("res://graphics/coast/stone_path.png")
const CLIFF_WALL: Texture2D = preload("res://graphics/coast/cliff_wall.png")
const SHIP_WALL: Texture2D = preload("res://graphics/coast/ship_wall.png")
const SHIPWRECK: Texture2D = preload("res://graphics/coast/shipwreck.png")
const SHIPWRECK_MAIN: Texture2D = preload("res://graphics/coast/shipwreck_main.png")
const SHIPWRECK_SMALL: Texture2D = preload("res://graphics/coast/shipwreck_small.png")
const BROKEN_MAST: Texture2D = preload("res://graphics/coast/broken_mast.png")
const TORN_SAIL: Texture2D = preload("res://graphics/coast/torn_sail.png")
const PIER: Texture2D = preload("res://graphics/coast/pier.png")
const ROWBOAT: Texture2D = preload("res://graphics/coast/rowboat.png")
const TENT: Texture2D = preload("res://graphics/coast/tent.png")
const CAMPFIRE: Texture2D = preload("res://graphics/coast/campfire.png")
const SIGNPOST: Texture2D = preload("res://graphics/coast/signpost.png")
const CARGO: Texture2D = preload("res://graphics/coast/cargo.png")
const BARREL: Texture2D = preload("res://graphics/coast/barrel.png")
const CRATE: Texture2D = preload("res://graphics/coast/crate.png")
const PLANKS: Texture2D = preload("res://graphics/coast/planks.png")
const SEAWEED: Texture2D = preload("res://graphics/coast/seaweed.png")
const TIDE_POOL: Texture2D = preload("res://graphics/coast/tide_pool.png")
const BASALT_COLUMN: Texture2D = preload("res://graphics/coast/basalt_column.png")
const CAVE_MOUTH: Texture2D = preload("res://graphics/coast/cave_mouth.png")
const CRYSTAL: Texture2D = preload("res://graphics/coast/crystal.png")
const DRAGON_SKULL: Texture2D = preload("res://graphics/coast/dragon_skull.png")
const RIBCAGE: Texture2D = preload("res://graphics/coast/ribcage.png")
const BRAZIER: Texture2D = preload("res://graphics/coast/brazier.png")
const LANTERN_POST: Texture2D = preload("res://graphics/coast/lantern_post.png")
const KEEPER_HUT: Texture2D = preload("res://graphics/coast/keeper_hut.png")
const WHALE_BONES: Texture2D = preload("res://graphics/coast/whale_bones.png")
const GULL: Texture2D = preload("res://graphics/coast/gull.png")
const CRAB: Texture2D = preload("res://graphics/coast/crab.png")
const SHELLS: Texture2D = preload("res://graphics/coast/shells.png")
const ANCHOR: Texture2D = preload("res://graphics/coast/anchor.png")
const PILGRIM: Texture2D = preload("res://graphics/coast/pilgrim.png")
const LIGHTHOUSE: Texture2D = preload("res://graphics/coast/lighthouse.png")
const LIGHTHOUSE_SHORT: Texture2D = preload("res://graphics/coast/lighthouse_short.png")
const DOOR: Texture2D = preload("res://graphics/coast/door_wood.png")
const TIDE_KEY: Texture2D = preload("res://graphics/coast/tide_key.png")
const TIDE_GATE: Texture2D = preload("res://graphics/coast/tide_gate.png")
const DRAGONBONE: Texture2D = preload("res://graphics/coast/dragonbone.png")
const BONE_PILE: Texture2D = preload("res://graphics/coast/bone_pile.png")
const DRIFTWOOD: Texture2D = preload("res://graphics/coast/driftwood.png")
const LAVA_VENT: Texture2D = preload("res://graphics/coast/lava_vent.png")
const ALTAR: Texture2D = preload("res://graphics/coast/altar.png")
const CHEST: Texture2D = preload("res://graphics/coast/chest.png")
const SEA_ROCK: Texture2D = preload("res://graphics/coast/sea_rock.png")
const DEAD_TREE: Texture2D = preload("res://graphics/monastery/dead_tree.png")
const RUBBLE: Texture2D = preload("res://graphics/monastery/rubble.png")
const CANDLE: Texture2D = preload("res://graphics/monastery/candle.png")
const GRAVESTONE: Texture2D = preload("res://graphics/monastery/gravestone.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")

const ENEMY_SCENE: PackedScene = preload("res://scenes/coast/coast_enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/coast/ska.tscn")
const STELE_SCENE: PackedScene = preload("res://scenes/level/oath_stele.tscn")
const FENCE_GATE_SCENE: PackedScene = preload("res://scenes/coast/fence_gate.tscn")
const RETURN_GATE_SCRIPT: Script = preload("res://scenes/level/town_return_gate.gd")
const MIRROR_SCRIPT: Script = preload("res://scenes/coast/beam_mirror.gd")

const TILE_CHOICES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
]

const NAV_CELL := 32
const NAV_MIN := Vector2(64, 48)
const NAV_MAX := Vector2(2336, 1776)

const ENTRANCE := Vector2(240, 1500)
const RETURN_POS := Vector2(130, 1500)
const CHECKPOINT := Vector2(780, 860)
const PILGRIM_POS := Vector2(300, 1450)
const WATCH_LOG_POS := Vector2(1200, 340)
const WRECK_DOOR_POS := Vector2(950, 1455)
const TIDE_GUARD_POS := Vector2(1450, 850)
const TIDE_KEY_POS := Vector2(1450, 790)
const LIGHTHOUSE_POS := Vector2(700, 800)
const LIGHTHOUSE_INTERACT := Vector2(700, 806)
const CAVE_CHEST_POS := Vector2(310, 470)
const VAULT_CHEST_POS := Vector2(1610, 1350)
const BOSS_GATE_RECT := Rect2(1720, 650, 40, 100)
const BOSS_POS := Vector2(2040, 720)
const STELE_POS := Vector2(2040, 470)
const ARENA_RECT := Rect2(1760, 400, 540, 600)
const ARENA_SAFE := Rect2(1850, 500, 350, 400)

const TIDE_LOW_TIME := 24.0
const TIDE_RISE_TIME := 6.0
const TIDE_HIGH_TIME := 14.0
const TIDE_FALL_TIME := 6.0
const TIDE_RECTS: Array[Rect2] = [
	Rect2(380, 1220, 450, 360),   # 沉船西侧浅滩
	Rect2(1070, 1220, 430, 360),  # 沉船东侧浅滩
	Rect2(1720, 1220, 520, 360),  # 沉船宝库东侧浅滩
	Rect2(830, 1420, 240, 160),   # 沉船正南入口
	Rect2(830, 1220, 240, 20),    # 沉船正北
	Rect2(1500, 1460, 220, 120),  # 宝库正南入口
	Rect2(1500, 1220, 220, 60),   # 宝库正北
]
const BOSS_TIDE_RECTS: Array[Rect2] = [
	Rect2(1760, 400, 90, 600),
	Rect2(2210, 400, 90, 600),
	Rect2(1850, 400, 360, 100),
	Rect2(1850, 900, 360, 100),
]
const MIRROR_DATA := [
	{
		"id": "cliff",
		"pos": Vector2(1150, 260),
		"target": Vector2(1150, 120),
		"target_facing": 3,
		"initial": 0,
		"label": "崖顶铜镜",
		"marker": "崖顶标记",
		"guard": "menhir_golem",
		"guard_pos": Vector2(1150, 330),
		"adds": [
			["dragonfire_digger", Vector2(1070, 300)], ["dragonfire_digger", Vector2(1230, 300)],
			["ash_feather", Vector2(1070, 220)], ["ash_feather", Vector2(1230, 220)],
		],
		"leash": Rect2(1010, 140, 280, 280),
		"alarm_offsets": [Vector2(-80, 70), Vector2(80, 70), Vector2(0, 90)],
		"flag": "coast_mirror_cliff",
		"guard_flag": "coast_mirror_cliff_guard",
	},
	{
		"id": "cave",
		"pos": Vector2(360, 580),
		"target": Vector2(520, 580),
		"target_facing": 0,
		"initial": 1,
		"label": "海蚀洞铜镜",
		"marker": "海蚀洞标记",
		"guard": "menhir_golem",
		"guard_pos": Vector2(440, 560),
		"adds": [
			["ash_feather", Vector2(290, 610)], ["ash_feather", Vector2(470, 610)],
			["slag_skink", Vector2(300, 540)], ["slag_skink", Vector2(500, 540)],
		],
		"leash": Rect2(240, 400, 300, 280),
		"alarm_offsets": [Vector2(-70, 60), Vector2(70, 60), Vector2(0, -70)],
		"flag": "coast_mirror_cave",
		"guard_flag": "coast_mirror_cave_guard",
	},
	{
		"id": "wreck",
		"pos": Vector2(1035, 1230),
		"target": Vector2(1200, 1230),
		"target_facing": 0,
		"initial": 1,
		"label": "沉船桅杆铜镜",
		"marker": "龙骨山标记",
		"guard": "cinder_falcon",
		"guard_pos": Vector2(1120, 1230),
		"adds": [
			["gamehound", Vector2(980, 1230)], ["gamehound", Vector2(1200, 1230)],
			["ash_feather", Vector2(940, 1240)], ["ash_feather", Vector2(1180, 1240)],
		],
		"leash": Rect2(900, 1200, 320, 120),
		"alarm_offsets": [Vector2(-100, 0), Vector2(100, 0), Vector2(160, 0)],
		"flag": "coast_mirror_wreck",
		"guard_flag": "coast_mirror_wreck_guard",
	},
]
const MIRROR_ALARM_KINDS := ["slag_skink", "slag_skink", "ash_feather"]

var boss
var boss_started := false
var boss_phase := 1
var boss_tide_active := false
var boss_tide_damage_timer := 0.0
var gate: StaticBody2D
var gate_visual: Sprite2D
var tide_gate_open := false
var checkpoint_pos := ENTRANCE
var stele
var objective_done := false
var nav_walkable := {}
var nav_cols := 0
var nav_rows := 0
var nav_astar: AStarGrid2D

var tide_state := "low"
var tide_timer := TIDE_LOW_TIME
var tide_panel: Panel
var tide_label: Label
var tide_overlays: Array = []
var boss_tide_overlays: Array = []
var tide_damage_timer := 0.0

var lighthouse_glow: Sprite2D
var beam: Line2D
var key_sprite: Sprite2D
var key_glow: Sprite2D
var key_label: Label
var key_gate: Node2D
var quest_panel: Panel
var quest_title: Label
var quest_lines: Array = []
var quest_hint: Label
var objective_beacon: Sprite2D
var pilgrim_talked := false
var watch_log_seen := false
var cave_chest_sprite: Sprite2D
var cave_chest_label: Label
var vault_chest_sprite: Sprite2D
var vault_chest_label: Label
var mirrors := {}
var mirror_markers := {}
var mirror_alarm_ready := {}
var cave_tide_blocker: CollisionShape2D


func on_scene_ready() -> void:
	add_to_group("CoastNav")
	build_coast()
	resolve_spawn(ENTRANCE, {
		"wreck_exit": WRECK_DOOR_POS,
		"lighthouse_exit": Vector2(700, 830),
	})
	player.set_spawn_position(player.global_position)
	checkpoint_pos = player.global_position
	_build_tide_ui()
	_build_quest_ui()
	_refresh_tide_passages()
	_apply_progress_visuals()
	_build_return_gate()
	hud.call("show_banner", "赤烬海岸", "赤潮与灰烬的边境", 2.8)
	refresh_objective()
	SaveGame.save_game("赤烬海岸")
	if Global.third_stele_lit:
		objective_done = true
	# 多等一帧，确保潮门等后添加的静态碰撞体已经进入物理空间
	await get_tree().physics_frame
	await get_tree().physics_frame
	_build_nav_grid()
	_build_enemies()
	_build_mirrors()
	_build_boss()
	_build_stele()
	_update_quest_ui()


func refresh_objective() -> void:
	if Global.third_stele_lit:
		set_objective("赤烬海岸已净化")
		set_tutorial("第三座誓火石碑已经点燃")
	elif Global.ska_defeated:
		set_objective("点燃第三座誓火石碑")
		set_tutorial("石碑在龙骨祭坛后方")
	elif boss_started:
		set_objective("击败赤烬龙裔斯卡")
		if boss_phase >= 2:
			set_tutorial("赤潮上涨，待在场地中央，躲开熔岩与火焰")
		else:
			set_tutorial("攻击头部伤害更高，躲开冲锋与火焰吐息")
	elif Global.coast_lighthouse_lit:
		if not Global.coast_beam_aligned:
			set_objective("校准三面灯塔铜镜")
			set_tutorial("崖顶、海蚀洞、沉船桅杆各有一面铜镜 · 先击败守卫")
		elif not Global.coast_tide_key:
			set_objective("取得潮门钥匙")
			set_tutorial("击败高台上的熔岩蛇蜥，夺取潮门钥匙")
		else:
			set_objective("进入龙骨祭坛")
			set_tutorial("灯塔光束与潮门钥匙已经打开潮门")
	elif Global.coast_lens_found:
		set_objective("进入灯塔点亮灯室")
		set_tutorial("从灯塔底部的门进入 · 注意赤潮涨落")
	else:
		set_objective("找到沉船里的灯塔透镜")
		set_tutorial("低潮时从沉船南侧的舱门进入 · 左上角显示潮汐")


func _draw() -> void:
	draw_rect(Rect2(-300, -300, 3000, 2400), Color(0.055, 0.045, 0.04))


func build_coast() -> void:
	var modulate_node := CanvasModulate.new()
	modulate_node.color = Color(0.92, 0.8, 0.7)
	add_child(modulate_node)

	# 高台与低滩
	_floor(Rect2(64, 48, 2272, 1132), BASALT, 801)
	_floor(Rect2(64, 1220, 2272, 360), SAND, 802)
	_floor(Rect2(64, 1580, 2272, 196), SEA, 803)
	# 地面分区：湿沙、灰烬、烧焦地、海藻地、石板路、鲸骨地
	_floor(Rect2(64, 1500, 2272, 80), WET_SAND, 820)
	_floor(Rect2(220, 780, 420, 320), ASH, 821)
	_floor(Rect2(1180, 480, 360, 360), ASH, 822)
	_floor(Rect2(1540, 700, 180, 300), CHARRED, 823)
	_floor(Rect2(900, 860, 260, 180), CHARRED, 824)
	_floor(Rect2(760, 1380, 380, 120), SEAWEED_GROUND, 825)
	_floor(Rect2(300, 1040, 470, 90), STONE_PATH, 826)
	_floor(Rect2(300, 1040, 90, 150), STONE_PATH, 827)
	_floor(Rect2(690, 960, 90, 90), STONE_PATH, 830)
	_floor(Rect2(880, 720, 840, 90), STONE_PATH, 831)
	_floor(Rect2(720, 920, 420, 180), BONE_FLOOR, 828)
	_floor(Rect2(1820, 880, 300, 100), ASH, 829)
	_floor(Rect2(920, 1420, 60, 100), WOOD, 832)
	_floor(Rect2(260, 180, 1480, 200), ASH, 833)
	_floor(Rect2(900, 250, 520, 130), CHARRED, 834)

	# 外墙
	_wall(Rect2(48, 32, 2304, 16))
	_wall(Rect2(48, 32, 16, 1760))
	_wall(Rect2(2336, 32, 16, 1760))
	_wall(Rect2(48, 1776, 2304, 16))
	# 海边礁墙
	_wall(Rect2(48, 1572, 2304, 20))

	# 高台与低滩之间的崖壁，留两处斜坡
	_wall(Rect2(64, 1180, 216, 40))
	_wall(Rect2(380, 1180, 1120, 40))
	_wall(Rect2(1600, 1180, 736, 40))
	_floor(Rect2(280, 1180, 100, 40), BASALT, 804)
	_floor(Rect2(1500, 1180, 100, 40), BASALT, 805)

	# 海蚀洞
	_floor(Rect2(240, 400, 320, 280), BONE_FLOOR, 806)
	_wall(Rect2(220, 380, 340, 20))
	_wall(Rect2(220, 400, 20, 280))
	_wall(Rect2(560, 400, 20, 280))
	_wall(Rect2(220, 680, 150, 20))
	_wall(Rect2(410, 680, 150, 20))
	_floor(Rect2(370, 680, 40, 20), BONE_FLOOR, 807)
	# 海蚀洞入口在涨潮时被海水封住，只有低潮可以进出。
	var cave_body := StaticBody2D.new()
	cave_body.collision_layer = 1
	cave_body.collision_mask = 0
	var cave_shape := CollisionShape2D.new()
	var cave_rect := RectangleShape2D.new()
	cave_rect.size = Vector2(40, 22)
	cave_shape.shape = cave_rect
	cave_shape.position = Vector2(390, 689)
	cave_shape.disabled = true
	cave_body.add_child(cave_shape)
	objects.add_child(cave_body)
	cave_tide_blocker = cave_shape

	# 沉船宝库（可选支路，仍留在海岸地图内）
	_floor_z(Rect2(1530, 1300, 160, 140), WOOD, 810, 3)
	_wall_z(Rect2(1500, 1280, 30, 180), SHIP_WALL, 3)
	_wall_z(Rect2(1690, 1280, 30, 180), SHIP_WALL, 3)
	_wall_z(Rect2(1500, 1280, 220, 20), SHIP_WALL, 3)
	_wall_z(Rect2(1500, 1440, 90, 20), SHIP_WALL, 3)
	_wall_z(Rect2(1630, 1440, 90, 20), SHIP_WALL, 3)
	_floor_z(Rect2(1590, 1440, 40, 20), WOOD, 812, 3)

	# 灯塔前庭
	_floor(Rect2(560, 700, 320, 260), BONE_FLOOR, 813)

	# 龙骨祭坛
	_floor(Rect2(1760, 400, 540, 600), BONE_FLOOR, 814)
	_wall(Rect2(1720, 400, 40, 250))
	_wall(Rect2(1720, 750, 40, 250))
	_wall(Rect2(1720, 380, 600, 20))
	_wall(Rect2(1720, 1000, 600, 20))
	_wall(Rect2(2300, 400, 36, 600))

	_build_gate()
	_build_tide_overlays()
	_build_boss_tide_overlays()
	_build_props()


func _floor(rect: Rect2, tex: Texture2D, seed: int) -> void:
	add_tile_area(rect, tex, TILE_CHOICES, 2, seed)


func _floor_z(rect: Rect2, tex: Texture2D, seed: int, z: int) -> void:
	var layer := add_tile_area(rect, tex, TILE_CHOICES, 2, seed)
	layer.z_index = z


func _wall(rect: Rect2) -> void:
	_wall_z(rect, CLIFF_WALL, 0)


func _wall_z(rect: Rect2, tex: Texture2D, z: int) -> void:
	var layer := add_tile_area(rect, tex, TILE_CHOICES, 2, int(rect.position.x + rect.position.y * 3))
	layer.z_index = z
	add_blocker(rect)


func _prop(tex: Texture2D, pos: Vector2, prop_scale: float = 2.0, flip: bool = false) -> Sprite2D:
	var sprite := add_sprite(tex, pos, prop_scale)
	sprite.position = pos + Vector2(0, 2.0 - tex.get_height() * prop_scale * 0.5)
	sprite.flip_h = flip
	sprite.z_index = 1
	return sprite


func _prop_z(tex: Texture2D, pos: Vector2, prop_scale: float, z: int, flip: bool = false) -> Sprite2D:
	var sprite := _prop(tex, pos, prop_scale, flip)
	sprite.z_index = z
	return sprite


func _glow(pos: Vector2, color: Color, glow_scale: float = 2.0) -> void:
	var sprite := add_sprite(GLOW, pos + Vector2(0, -24), glow_scale)
	sprite.modulate = color
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 2


func _build_return_gate() -> void:
	var gate_node := Node2D.new()
	gate_node.set_script(RETURN_GATE_SCRIPT)
	gate_node.position = RETURN_POS
	gate_node.set("label_text", "返回白鹿镇")
	gate_node.set("interactive", false)
	objects.add_child(gate_node)


func _build_gate() -> void:
	gate = add_blocker(BOSS_GATE_RECT)
	gate_visual = _prop(TIDE_GATE, Vector2(1740, 750), 1.4)
	gate_visual.z_index = 3
	gate_visual.set_meta("home", gate_visual.position)
	add_world_label("龙骨祭坛", Vector2(1945, 1030), 8, Color(1.0, 0.78, 0.48))
	add_world_label("潮门", Vector2(1820, 636), 7, Color(0.9, 0.72, 0.48))


func _build_tide_overlays() -> void:
	tide_overlays.clear()
	for i in TIDE_RECTS.size():
		var rect: Rect2 = TIDE_RECTS[i]
		var layer := add_tile_area(rect, LAVA, TILE_CHOICES, 2, 900 + i)
		layer.z_index = 2
		layer.modulate.a = 0.0
		tide_overlays.append(layer)


func _build_boss_tide_overlays() -> void:
	boss_tide_overlays.clear()
	for i in BOSS_TIDE_RECTS.size():
		var rect: Rect2 = BOSS_TIDE_RECTS[i]
		var layer := add_tile_area(rect, LAVA, TILE_CHOICES, 2, 950 + i)
		layer.z_index = 2
		layer.modulate.a = 0.0
		boss_tide_overlays.append(layer)


func _build_props() -> void:
	# 入口营地：帐篷、篝火、路牌、朝圣者、断栈桥、小舟
	_prop(PIER, Vector2(170, 1596), 1.0)
	_prop(ROWBOAT, Vector2(330, 1568), 1.0)
	add_blocker(Rect2(300, 1556, 60, 12))
	_prop(TENT, Vector2(360, 1442), 1.0)
	add_blocker(Rect2(324, 1430, 72, 12))
	_prop(CAMPFIRE, Vector2(260, 1472), 1.2)
	_glow(Vector2(260, 1472), Color(1.0, 0.55, 0.2, 0.3), 1.6)
	_prop(SIGNPOST, Vector2(378, 1520), 1.0)
	_prop(PILGRIM, PILGRIM_POS, 1.0)
	add_world_label("海滩营地", Vector2(140, 1415), 8, Color(1.0, 0.84, 0.5))
	add_world_label("迷途的朝圣者", Vector2(250, 1395), 7, Color(0.9, 0.84, 0.68))
	add_world_label("沉船湾 →", Vector2(330, 1486), 7, Color(1.0, 0.76, 0.46))
	add_world_label("灯塔 ↑", Vector2(330, 1468), 7, Color(0.74, 0.86, 0.9))
	for pos in [Vector2(600, 1530), Vector2(1080, 1545), Vector2(1480, 1520), Vector2(1780, 1545)]:
		_prop(TIDE_POOL, pos, 1.0)
	for pos in [Vector2(480, 1555), Vector2(1220, 1555), Vector2(1680, 1535)]:
		_prop(SHELLS, pos, 1.0)
	for pos in [Vector2(650, 1535), Vector2(1400, 1510)]:
		_prop(CRAB, pos, 1.0)
	for pos in [Vector2(420, 1300), Vector2(1850, 1320)]:
		_prop(GULL, pos, 1.0)

	# 沉船湾：大型沉船、断桅、破帆、货物
	_prop(SHIPWRECK_MAIN, Vector2(950, 1430), 1.0)
	_prop(BROKEN_MAST, Vector2(1035, 1285), 1.0)
	_prop(TORN_SAIL, Vector2(1040, 1225), 1.0)
	_prop(CARGO, Vector2(820, 1450), 1.0)
	add_blocker(Rect2(796, 1436, 48, 16))
	_prop(BARREL, Vector2(865, 1470), 1.0)
	add_blocker(Rect2(857, 1458, 16, 12))
	_prop(CRATE, Vector2(1035, 1465), 1.0)
	add_blocker(Rect2(1025, 1452, 20, 14))
	_prop(ANCHOR, Vector2(760, 1460), 1.0)
	_prop(PLANKS, Vector2(800, 1495), 1.0)
	_prop(PLANKS, Vector2(1100, 1495), 1.0)
	_prop(SEAWEED, Vector2(790, 1420), 1.0)
	_prop(SEAWEED, Vector2(1120, 1430), 1.0)
	_prop(WHALE_BONES, Vector2(1180, 1410), 1.0)
	add_blocker(Rect2(1116, 1400, 128, 12))
	add_world_label("沉船湾", Vector2(895, 1462), 8, Color(1.0, 0.76, 0.46))
	# 船体是实体，只能从南侧舱门进入内部场景
	add_blocker(Rect2(790, 1254, 320, 176))
	var wreck_door := _prop(DOOR, Vector2(950, 1436), 1.2)
	wreck_door.z_index = 4
	add_world_label("沉船入口", Vector2(895, 1398), 7, Color(1.0, 0.84, 0.5))

	# 灯塔、守塔人小屋、石板路和灯柱
	_prop(LIGHTHOUSE_SHORT, LIGHTHOUSE_POS, 1.0)
	add_blocker(Rect2(675, 782, 50, 20))
	var lighthouse_door := _prop(DOOR, Vector2(700, 802), 1.1)
	lighthouse_door.z_index = 4
	lighthouse_glow = add_sprite(GLOW, Vector2(700, 712), 2.2)
	lighthouse_glow.modulate = Color(1.0, 0.72, 0.3, 0.0)
	lighthouse_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	lighthouse_glow.z_index = 2
	add_world_label("灯塔", Vector2(645, 720), 8, Color(1.0, 0.84, 0.55))
	_prop(KEEPER_HUT, Vector2(600, 800), 1.0)
	add_blocker(Rect2(575, 782, 50, 18))
	add_world_label("守塔人小屋", Vector2(600, 760), 7, Color(0.86, 0.8, 0.68))
	for pos in [Vector2(520, 1080), Vector2(700, 1030), Vector2(540, 930), Vector2(860, 900)]:
		_prop(LANTERN_POST, pos, 1.0)
		_glow(pos, Color(1.0, 0.7, 0.28, 0.28), 1.3)
	_prop(BRAZIER, Vector2(880, 820), 1.0)
	_glow(Vector2(880, 820), Color(1.0, 0.5, 0.18, 0.3), 1.6)
	_prop(ALTAR, CHECKPOINT, 1.2)
	_prop(CANDLE, CHECKPOINT + Vector2(-18, 10), 1.8)
	_prop(CANDLE, CHECKPOINT + Vector2(18, 10), 1.8)
	_glow(CHECKPOINT, Color(1.0, 0.62, 0.25, 0.4), 2.2)
	add_world_label("灯塔营地", CHECKPOINT + Vector2(-55, -38), 7, Color(1.0, 0.86, 0.55))

	beam = Line2D.new()
	beam.points = PackedVector2Array([Vector2(700, 712), Vector2(1740, 690)])
	beam.width = 7.0
	beam.default_color = Color(1.0, 0.76, 0.34, 0.16)
	beam.z_index = 3
	beam.visible = false
	objects.add_child(beam)
	var beam_core := Line2D.new()
	beam_core.points = PackedVector2Array([Vector2(700, 712), Vector2(1740, 690)])
	beam_core.width = 2.0
	beam_core.default_color = Color(1.0, 0.9, 0.55, 0.65)
	beam_core.z_index = 4
	beam_core.visible = false
	objects.add_child(beam_core)
	beam.set_meta("core", beam_core)

	# 海蚀洞：洞口、晶石、水洼、骨堆
	_prop(CAVE_MOUTH, Vector2(390, 700), 1.0)
	add_blocker(Rect2(326, 660, 44, 40))
	add_blocker(Rect2(410, 660, 44, 40))
	_prop(CRYSTAL, Vector2(270, 430), 1.2)
	_glow(Vector2(270, 418), Color(0.4, 0.9, 0.85, 0.25), 1.6)
	_prop(CRYSTAL, Vector2(520, 600), 1.0)
	_glow(Vector2(520, 588), Color(0.4, 0.9, 0.85, 0.22), 1.4)
	_prop(TIDE_POOL, Vector2(450, 620), 1.0)
	_prop(BONE_PILE, Vector2(300, 620), 1.0)
	_prop(WHALE_BONES, Vector2(400, 430), 0.8)
	add_blocker(Rect2(336, 420, 128, 12))
	add_world_label("海蚀洞 · 低潮可进入", Vector2(255, 715), 7, Color(0.84, 0.8, 0.68))
	cave_chest_sprite = _prop(CHEST, CAVE_CHEST_POS, 1.6)
	cave_chest_label = add_world_label("海蚀洞宝箱", CAVE_CHEST_POS + Vector2(-55, -40), 7, Color(0.92, 0.82, 0.56))
	_glow(Vector2(370, 640), Color(1.0, 0.55, 0.2, 0.16), 2.0)

	# 沉船宝库：小型沉船和货箱
	_prop(SHIPWRECK_SMALL, Vector2(1610, 1462), 1.0)
	_prop(BROKEN_MAST, Vector2(1660, 1365), 0.8)
	_prop(TORN_SAIL, Vector2(1665, 1320), 0.7)
	_prop_z(CARGO, Vector2(1545, 1440), 0.8, 4)
	add_blocker(Rect2(1529, 1430, 32, 12))
	_prop_z(BARREL, Vector2(1680, 1440), 1.0, 4)
	add_blocker(Rect2(1672, 1428, 16, 12))
	_prop(PLANKS, Vector2(1580, 1470), 1.0)
	_prop(SEAWEED, Vector2(1520, 1450), 1.0)
	vault_chest_sprite = _prop_z(CHEST, VAULT_CHEST_POS, 1.5, 4)
	vault_chest_label = add_world_label("沉船宝箱", VAULT_CHEST_POS + Vector2(-55, -40), 7, Color(0.92, 0.82, 0.56))
	add_world_label("沉船宝库", Vector2(1530, 1238), 7, Color(1.0, 0.76, 0.46))

	# 龙骨祭坛：巨龙头骨、肋骨、火盆
	_prop(DRAGON_SKULL, Vector2(2040, 660), 1.0)
	add_blocker(Rect2(1960, 632, 160, 30))
	_prop(RIBCAGE, Vector2(2040, 900), 1.0)
	add_blocker(Rect2(1960, 890, 160, 12))
	for pos in [Vector2(1800, 670), Vector2(2280, 670), Vector2(1800, 830), Vector2(2280, 830)]:
		_prop(BRAZIER, pos, 1.0)
		_glow(pos, Color(1.0, 0.45, 0.18, 0.3), 1.8)
	for pos in [Vector2(1860, 520), Vector2(2220, 520), Vector2(1860, 900), Vector2(2220, 900)]:
		_prop(DRAGONBONE, pos, 1.0, pos.x > 2040.0)
		add_blocker(Rect2(pos.x - 30, pos.y - 12, 60, 12))
	_prop(BONE_PILE, Vector2(1940, 960), 1.3)
	_prop(BONE_PILE, Vector2(2140, 960), 1.3)
	_prop(WHALE_BONES, Vector2(1900, 940), 0.8)
	add_blocker(Rect2(1836, 930, 128, 12))
	_prop(ALTAR, Vector2(2040, 540), 1.5)
	_glow(Vector2(2040, 540), Color(1.0, 0.55, 0.2, 0.22), 2.2)

	# 玄武岩高台：岩柱、鲸骨地、碎石、枯树
	for pos in [Vector2(500, 1170), Vector2(700, 1170), Vector2(900, 1170), Vector2(1300, 1170), Vector2(1700, 1170), Vector2(420, 900), Vector2(1200, 700), Vector2(1500, 520)]:
		_prop(BASALT_COLUMN, pos, 1.0)
		add_blocker(Rect2(pos.x - 10, pos.y - 14, 20, 14))
	_prop(WHALE_BONES, Vector2(880, 1000), 1.2)
	add_blocker(Rect2(816, 990, 128, 12))
	_prop(BONE_PILE, Vector2(760, 1050), 1.0)
	_prop(BONE_PILE, Vector2(1040, 980), 1.0)
	_prop(WHALE_BONES, Vector2(1200, 1050), 0.9)
	add_blocker(Rect2(1136, 1040, 128, 12))
	add_world_label("鲸骨地", Vector2(795, 920), 8, Color(0.84, 0.82, 0.72))
	add_world_label("玄武岩高台", Vector2(1050, 1120), 8, Color(0.86, 0.84, 0.8))
	for pos in [Vector2(420, 900), Vector2(980, 980), Vector2(1350, 760), Vector2(1600, 940)]:
		_prop(SEA_ROCK, pos, 1.3, pos.x > 900.0)
		add_blocker(Rect2(pos.x - 12, pos.y - 14, 24, 14))
	for pos in [Vector2(860, 640), Vector2(1160, 820), Vector2(1480, 620)]:
		_prop(DEAD_TREE, pos, 1.5, pos.x > 1000.0)
		add_blocker(Rect2(pos.x - 6, pos.y - 12, 12, 12))
	for pos in [Vector2(380, 1080), Vector2(1260, 1100), Vector2(1660, 1080)]:
		_prop(RUBBLE, pos, 1.2)

	# 潮门钥匙围栏：钥匙缩小放在小灯座上，微弱闪光
	_prop(ALTAR, TIDE_KEY_POS + Vector2(0, 4), 1.0)
	key_sprite = _prop(TIDE_KEY, TIDE_KEY_POS, 1.2)
	key_sprite.z_index = 4
	key_glow = add_sprite(GLOW, TIDE_KEY_POS + Vector2(0, -12), 1.1)
	key_glow.modulate = Color(1.0, 0.76, 0.3, 0.22)
	key_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	key_glow.z_index = 3
	var key_pulse := create_tween().set_loops()
	key_pulse.tween_property(key_glow, "modulate:a", 0.12, 1.4)
	key_pulse.tween_property(key_glow, "modulate:a", 0.24, 1.4)
	key_label = add_world_label("潮门钥匙", TIDE_KEY_POS + Vector2(-55, -48), 7, Color(1.0, 0.84, 0.5))
	if Global.coast_tide_key:
		key_sprite.visible = false
		key_glow.visible = false
		key_label.visible = false
	key_gate = FENCE_GATE_SCENE.instantiate() as Node2D
	objects.add_child(key_gate)
	key_gate.call("setup", Vector2(1450, 820), 160.0, 44.0,
		Global.coast_tide_guardian_defeated or Global.coast_tide_key, 56.0)

	# 灰烬崖：北侧可选探索区，守夜人残记
	for pos in [Vector2(400, 260), Vector2(700, 200), Vector2(1000, 260), Vector2(1300, 200), Vector2(1600, 260)]:
		_prop(BASALT_COLUMN, pos, 1.0)
		add_blocker(Rect2(pos.x - 10, pos.y - 14, 20, 14))
	_prop(DEAD_TREE, Vector2(520, 320), 1.6, true)
	add_blocker(Rect2(514, 308, 12, 12))
	_prop(DEAD_TREE, Vector2(1120, 340), 1.4, false)
	add_blocker(Rect2(1114, 328, 12, 12))
	_prop(DEAD_TREE, Vector2(1520, 300), 1.3, true)
	add_blocker(Rect2(1514, 288, 12, 12))
	_prop(DRAGONBONE, Vector2(1000, 300), 1.0)
	add_blocker(Rect2(970, 288, 60, 12))
	_prop(KEEPER_HUT, Vector2(1280, 320), 0.9)
	add_blocker(Rect2(1253, 302, 54, 18))
	_prop(GRAVESTONE, WATCH_LOG_POS, 1.4)
	_prop(BONE_PILE, Vector2(1160, 300), 1.0)
	_prop(BONE_PILE, Vector2(1320, 350), 1.0)
	for pos in [Vector2(820, 300), Vector2(1460, 280)]:
		_prop(LAVA_VENT, pos, 1.2)
		_glow(pos, Color(1.0, 0.36, 0.12, 0.25), 1.5)
	add_world_label("灰烬崖", Vector2(945, 150), 8, Color(0.84, 0.8, 0.74))
	add_world_label("守夜人残记", WATCH_LOG_POS + Vector2(-55, -42), 7, Color(0.9, 0.84, 0.68))

	# 赤潮浅滩上的残骸
	for pos in [Vector2(520, 1450), Vector2(1220, 1470), Vector2(1420, 1540)]:
		_prop(DRIFTWOOD, pos, 1.1)
	for pos in [Vector2(470, 1360), Vector2(1300, 1300), Vector2(1780, 1500)]:
		_prop(BONE_PILE, pos, 1.0)
	for pos in [Vector2(610, 1330), Vector2(1170, 1420), Vector2(1820, 1360)]:
		_prop(LAVA_VENT, pos, 1.2)
		_glow(pos, Color(1.0, 0.36, 0.12, 0.25), 1.5)
	for pos in [Vector2(520, 1450), Vector2(1220, 1470), Vector2(1420, 1540)]:
		_prop(SEAWEED, pos, 1.0)
	add_world_label("赤潮浅滩", Vector2(1145, 1206), 8, Color(1.0, 0.68, 0.4))


func _build_tide_ui() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	tide_panel = Panel.new()
	tide_panel.position = Vector2(8, 8)
	tide_panel.size = Vector2(126, 26)
	tide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.035, 0.9)
	style.border_color = Color(0.72, 0.44, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	tide_panel.add_theme_stylebox_override("panel", style)
	root.add_child(tide_panel)
	tide_label = Label.new()
	tide_label.position = Vector2(5, 4)
	tide_label.size = Vector2(116, 18)
	tide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tide_label.add_theme_font_override("font", font)
	tide_label.add_theme_font_size_override("font_size", 7)
	tide_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.6))
	tide_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	tide_label.add_theme_constant_override("outline_size", 2)
	tide_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tide_panel.add_child(tide_label)
	_update_tide_ui()


func _apply_progress_visuals() -> void:
	if Global.coast_chest_opened:
		cave_chest_sprite.visible = false
		cave_chest_label.visible = false
		cave_chest_sprite = null
	if Global.coast_vault_opened:
		vault_chest_sprite.visible = false
		vault_chest_label.visible = false
		vault_chest_sprite = null
	if Global.coast_lighthouse_lit:
		_refresh_beam_visual()
		lighthouse_glow.modulate.a = 0.8
	if (Global.coast_lighthouse_lit and Global.coast_beam_aligned and Global.coast_tide_key) or Global.ska_defeated:
		_set_gate(true)


func _set_gate(open: bool) -> void:
	tide_gate_open = open
	if gate != null:
		for child in gate.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", open)
	if gate_visual == null:
		return
	var home: Vector2 = gate_visual.get_meta("home", gate_visual.position)
	if open:
		if gate_visual.visible:
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(gate_visual, "position:y", gate_visual.position.y - 38.0, 0.5)
			tween.tween_property(gate_visual, "modulate:a", 0.0, 0.5)
			tween.chain().tween_callback(func() -> void:
				gate_visual.visible = false
				gate_visual.position = home
				gate_visual.modulate.a = 1.0
			)
	else:
		gate_visual.visible = true
		gate_visual.position = home
		gate_visual.modulate.a = 1.0


func _set_beam(on: bool) -> void:
	if beam != null:
		beam.visible = on
		var core = beam.get_meta("core", null)
		if core != null and is_instance_valid(core):
			core.visible = on


func _open_cave_chest() -> void:
	if Global.coast_chest_opened:
		return
	Global.coast_chest_opened = true
	Global.add_item("herb", 3)
	Global.add_item("shell", 5)
	SaveGame.save_game("赤烬海岸")
	cave_chest_sprite.visible = false
	cave_chest_label.visible = false
	cave_chest_sprite = null
	hud.call("show_notice", "海蚀洞宝箱：获得 3 株草药和 5 枚海壳")
	refresh_objective()


func _open_vault_chest() -> void:
	if Global.coast_vault_opened:
		return
	Global.coast_vault_opened = true
	Global.add_item("herb", 2)
	Global.add_item("gland", 5)
	SaveGame.save_game("赤烬海岸")
	vault_chest_sprite.visible = false
	vault_chest_label.visible = false
	vault_chest_sprite = null
	hud.call("show_notice", "沉船宝箱：获得 2 株草药和 5 份腺体")
	refresh_objective()


func _build_enemies() -> void:
	for entry in [
		["gamehound", Vector2(700, 1500)],
		["gamehound", Vector2(1180, 1480)],
		["ferry_strangler", Vector2(1350, 1510)],
		["ash_feather", Vector2(1150, 1300)],
		["dragonfire_digger", Vector2(550, 1420)],
		["slag_skink", Vector2(1250, 1380)],
		["ash_feather", Vector2(900, 1050)],
		["dragonfire_digger", Vector2(1200, 900)],
		["slag_skink", Vector2(1550, 800)],
		["gamehound", Vector2(1550, 620)],
		["ferry_strangler", Vector2(450, 900)],
		["ash_feather", Vector2(1120, 260)],
		["slag_skink", Vector2(820, 320)],
		["lava_span_basilisk", Vector2(1450, 920)],
	]:
		_spawn_enemy(str(entry[0]), entry[1])


func _spawn_enemy(kind: String, pos: Vector2) -> Node2D:
	if kind == "lava_span_basilisk" and (Global.coast_tide_key or Global.coast_tide_guardian_defeated):
		return null
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	if enemy == null:
		return null
	enemy.call("configure", kind)
	enemy.position = pos
	objects.add_child(enemy)
	if kind == "lava_span_basilisk":
		enemy.call("set_leash_rect", Rect2(1360, 900, 180, 100))
		enemy.connect("died", _on_tide_guardian_died)
	return enemy


func _on_tide_guardian_died() -> void:
	if Global.coast_tide_guardian_defeated:
		return
	Global.coast_tide_guardian_defeated = true
	SaveGame.save_game("赤烬海岸")
	if key_gate != null and is_instance_valid(key_gate):
		key_gate.call("open")
	hud.call("show_notice", "熔岩蛇蜥倒下了，钥匙围栏打开了")
	refresh_objective()
	Sfx.play("craft", 1.0, 1.5)


func _pick_tide_key() -> void:
	if Global.coast_tide_key or not Global.coast_tide_guardian_defeated:
		return
	Global.coast_tide_key = true
	SaveGame.save_game("赤烬海岸")
	key_sprite.visible = false
	key_glow.visible = false
	key_label.visible = false
	hud.call("show_notice", "获得潮门钥匙")
	_try_open_tide_gate()
	refresh_objective()
	Sfx.play("craft", 1.0, 1.5)


func _try_open_tide_gate() -> void:
	if Global.ska_defeated or tide_gate_open:
		return
	if Global.coast_lighthouse_lit and Global.coast_beam_aligned and Global.coast_tide_key:
		_set_gate(true)
		hud.call("show_notice", "灯塔光束与潮门钥匙齐备，潮门开启")
		refresh_objective()
		Sfx.play("craft", 1.0, 1.5)


func _mirror_data(id: String) -> Dictionary:
	for data in MIRROR_DATA:
		if str(data["id"]) == id:
			return data
	return {}


func _build_mirrors() -> void:
	for data in MIRROR_DATA:
		var id := str(data["id"])
		var data_pos: Vector2 = data["pos"]
		var mirror := Node2D.new()
		mirror.set_script(MIRROR_SCRIPT)
		mirror.position = data_pos
		mirror.z_index = 3
		mirror.set("facing", int(data["initial"]))
		objects.add_child(mirror)
		mirrors[id] = mirror
		var aligned := bool(Global.get(str(data["flag"])))
		if aligned:
			mirror.call("set_facing", int(data["target_facing"]))
		mirror.call("set_aligned", aligned)

		var target: Vector2 = data["target"]
		var marker := add_sprite(GLOW, target + Vector2(0, -20), 1.8)
		marker.modulate = Color(1.0, 0.82, 0.38, 0.6) if aligned else Color(0.45, 0.75, 0.85, 0.3)
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		marker.z_index = 2
		mirror_markers[id] = marker
		add_world_label(str(data["marker"]), target + Vector2(-50, -50), 7, Color(0.76, 0.86, 0.94))
		add_world_label(str(data["label"]), data_pos + Vector2(-55, 16), 7, Color(0.88, 0.78, 0.58))
		mirror_alarm_ready[id] = 0

		if not aligned and not bool(Global.get(str(data["guard_flag"]))):
			_spawn_mirror_guard(data)


func _spawn_mirror_guard(data: Dictionary) -> void:
	var id := str(data["id"])
	var guard_pos: Vector2 = data["guard_pos"]
	var guard := _spawn_enemy(str(data["guard"]), guard_pos)
	if guard != null:
		guard.call("set_leash_rect", data["leash"])
		guard.connect("died", _on_mirror_guard_died.bind(id))
	for entry in data["adds"]:
		var add_pos: Vector2 = entry[1]
		_spawn_enemy(str(entry[0]), add_pos)


func _on_mirror_guard_died(id: String) -> void:
	var data := _mirror_data(id)
	if data.is_empty():
		return
	var flag := str(data["guard_flag"])
	if bool(Global.get(flag)):
		return
	Global.set(flag, true)
	SaveGame.save_game("赤烬海岸")
	hud.call("show_notice", "%s的守卫倒下了，可以转动铜镜" % str(data["label"]))
	refresh_objective()
	_update_quest_ui()
	Sfx.play("craft", 1.0, 1.5)


func _rotate_mirror(id: String) -> void:
	var data := _mirror_data(id)
	if data.is_empty() or bool(Global.get(str(data["flag"]))):
		return
	if not bool(Global.get(str(data["guard_flag"]))):
		hud.call("show_notice", "先击败铜镜守卫")
		return
	var mirror = mirrors.get(id)
	if mirror == null or not is_instance_valid(mirror):
		return
	var facing := (int(mirror.get("facing")) + 1) % 4
	mirror.call("set_facing", facing)
	Sfx.play("warn", 0.9, -8.0)
	if facing == int(data["target_facing"]):
		mirror.call("set_aligned", true)
		Global.set(str(data["flag"]), true)
		SaveGame.save_game("赤烬海岸")
		var marker = mirror_markers.get(id)
		if marker != null and is_instance_valid(marker):
			marker.modulate = Color(1.0, 0.82, 0.38, 0.7)
		hud.call("show_notice", "铜镜对准了%s（%d/3）" % [str(data["marker"]), _aligned_mirror_count()])
		refresh_objective()
		_update_quest_ui()
		_check_beam()
		Sfx.play("craft", 1.0, 1.5)
		return

	var now := Time.get_ticks_msec()
	if now >= int(mirror_alarm_ready.get(id, 0)):
		mirror_alarm_ready[id] = now + 6000
		_spawn_mirror_alarm(id)
		hud.call("show_notice", "铜镜方向错误，惊动了海兽")
	else:
		hud.call("show_notice", "铜镜方向不对，继续转动")


func _spawn_mirror_alarm(id: String) -> void:
	var data := _mirror_data(id)
	if data.is_empty():
		return
	var base: Vector2 = data["pos"]
	var offsets: Array = data.get("alarm_offsets", [Vector2(-70, 60), Vector2(70, 60), Vector2(0, 80)])
	for i in MIRROR_ALARM_KINDS.size():
		var offset: Vector2 = offsets[i % offsets.size()]
		var pos := Global.find_reachable_position(base + offset, 48.0)
		if pos == Vector2.INF:
			continue
		var enemy := _spawn_enemy(str(MIRROR_ALARM_KINDS[i]), pos)
		if enemy != null:
			enemy.set("awake", true)


func _aligned_mirror_count() -> int:
	var count := 0
	for data in MIRROR_DATA:
		if bool(Global.get(str(data["flag"]))):
			count += 1
	return count


func _check_beam() -> void:
	if _aligned_mirror_count() < MIRROR_DATA.size():
		refresh_objective()
		_update_quest_ui()
		return
	if Global.coast_beam_aligned:
		return
	Global.coast_beam_aligned = true
	SaveGame.save_game("赤烬海岸")
	_refresh_beam_visual()
	hud.call("show_banner", "灯塔光束贯通", "三面铜镜已对准，潮门可以开启了", 2.8)
	refresh_objective()
	_update_quest_ui()
	_try_open_tide_gate()


func _refresh_beam_visual() -> void:
	if not Global.coast_lighthouse_lit:
		_set_beam(false)
		return
	_set_beam(true)
	var aligned := Global.coast_beam_aligned
	if beam != null:
		beam.width = 9.0 if aligned else 5.0
		beam.default_color = Color(1.0, 0.76, 0.34, 0.32) if aligned else Color(0.5, 0.75, 0.9, 0.14)
		var core = beam.get_meta("core", null)
		if core != null and is_instance_valid(core):
			core.width = 3.0 if aligned else 1.5
			core.default_color = Color(1.0, 0.9, 0.55, 0.85) if aligned else Color(0.55, 0.8, 1.0, 0.4)


func _refresh_tide_passages() -> void:
	if cave_tide_blocker == null:
		return
	cave_tide_blocker.set_deferred("disabled", tide_state == "low")


func _build_boss() -> void:
	if Global.ska_defeated:
		return
	boss = BOSS_SCENE.instantiate() as Node2D
	boss.position = BOSS_POS
	objects.add_child(boss)
	boss.connect("died", _on_boss_died)
	boss.connect("phase_changed", _on_boss_phase)


func _build_stele() -> void:
	stele = STELE_SCENE.instantiate() as Node2D
	stele.set("reveal_flag", "ska_defeated")
	stele.set("lit_flag", "third_stele_lit")
	stele.set("reveal_notice", "誓火石碑显现")
	stele.set("lit_notice", "第三座誓火石碑已点燃，赤烬海岸得到净化；龙骨山的方向传来龙吼")
	stele.set("victory_title", "第三关完成")
	stele.set("victory_location", "赤烬海岸")
	stele.set("reveal_delay", 2.0)
	stele.position = STELE_POS
	stele.scale = Vector2(1.5, 1.5)
	stele.z_index = 5
	objects.add_child(stele)


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
	var nav_shape := RectangleShape2D.new()
	nav_shape.size = Vector2(12, 12)
	for y in nav_rows:
		for x in nav_cols:
			var center := NAV_MIN + (Vector2(x, y) + Vector2(0.5, 0.5)) * NAV_CELL
			var params := PhysicsShapeQueryParameters2D.new()
			params.shape = nav_shape
			params.transform = Transform2D(0.0, center + Vector2(0, -5))
			params.collision_mask = 1
			params.collide_with_areas = false
			var hits := get_world_2d().direct_space_state.intersect_shape(params, 1)
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


func _update_tide_ui() -> void:
	if tide_panel == null or tide_label == null:
		return
	tide_panel.visible = not boss_started
	var seconds := int(ceil(maxf(tide_timer, 0.0)))
	match tide_state:
		"low":
			tide_label.text = "赤潮退去 %02d" % seconds
			tide_label.add_theme_color_override("font_color", Color(0.68, 0.88, 0.84))
		"rising":
			tide_label.text = "赤潮上涨！"
			tide_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))
		"high":
			tide_label.text = "赤潮汹涌 %02d" % seconds
			tide_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.3))
		"falling":
			tide_label.text = "赤潮回落"
			tide_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))


func _build_quest_ui() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	quest_panel = Panel.new()
	quest_panel.position = Vector2(8, 38)
	quest_panel.size = Vector2(126, 120)
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.035, 0.9)
	style.border_color = Color(0.55, 0.42, 0.24)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	quest_panel.add_theme_stylebox_override("panel", style)
	root.add_child(quest_panel)
	quest_title = Label.new()
	quest_title.text = "赤烬海岸"
	quest_title.position = Vector2(0, 2)
	quest_title.size = Vector2(126, 12)
	quest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_title.add_theme_font_override("font", font)
	quest_title.add_theme_font_size_override("font_size", 6)
	quest_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.48))
	quest_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	quest_title.add_theme_constant_override("outline_size", 2)
	quest_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_panel.add_child(quest_title)
	quest_lines.clear()
	for i in 6:
		var line := Label.new()
		line.position = Vector2(6, 16 + i * 12)
		line.size = Vector2(114, 12)
		line.add_theme_font_override("font", font)
		line.add_theme_font_size_override("font_size", 5)
		line.add_theme_color_override("font_color", Color(0.62, 0.6, 0.56))
		line.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		line.add_theme_constant_override("outline_size", 1)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_panel.add_child(line)
		quest_lines.append(line)
	quest_hint = Label.new()
	quest_hint.position = Vector2(6, 90)
	quest_hint.size = Vector2(114, 24)
	quest_hint.add_theme_font_override("font", font)
	quest_hint.add_theme_font_size_override("font_size", 5)
	quest_hint.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
	quest_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	quest_hint.add_theme_constant_override("outline_size", 1)
	quest_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_panel.add_child(quest_hint)
	objective_beacon = add_sprite(GLOW, WRECK_DOOR_POS + Vector2(0, -42), 1.0)
	objective_beacon.modulate = Color(1.0, 0.72, 0.3, 0.32)
	objective_beacon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	objective_beacon.z_index = 3
	objective_beacon.scale = Vector2(1.0, 2.8)
	_update_quest_ui()


func _update_quest_ui() -> void:
	if quest_panel == null or player == null:
		return
	var info := _quest_target()
	var step := int(info["step"])
	var texts := ["找到灯塔透镜", "点亮灯塔", "校准三面铜镜", "取得潮门钥匙", "进入龙骨祭坛 / 击败斯卡", "点燃第三座誓火石碑"]
	for i in texts.size():
		var prefix := "○ "
		var color := Color(0.6, 0.58, 0.54)
		if i < step:
			prefix = "✓ "
			color = Color(0.62, 0.8, 0.64)
		elif i == step:
			prefix = "▸ "
			color = Color(1.0, 0.82, 0.48)
		quest_lines[i].text = prefix + texts[i]
		quest_lines[i].add_theme_color_override("font_color", color)
	if step >= 6:
		quest_hint.text = "赤烬海岸已净化"
		objective_beacon.visible = false
		return
	var target: Vector2 = info["target"]
	var delta: Vector2 = target - player.global_position
	var arrow := _direction_arrow(delta)
	var distance := int(round(delta.length() / 10.0))
	quest_hint.text = "%s %s %d步" % [str(info["name"]), arrow, distance]
	objective_beacon.visible = true
	objective_beacon.global_position = target + Vector2(0, -42)
	var pulse := 0.26 + 0.1 * absf(sin(float(Time.get_ticks_msec()) * 0.004))
	objective_beacon.modulate = Color(1.0, 0.72, 0.3, pulse)


func _quest_target() -> Dictionary:
	if not Global.coast_lens_found:
		return {"name": "沉船湾", "target": WRECK_DOOR_POS, "step": 0}
	if not Global.coast_lighthouse_lit:
		return {"name": "灯塔", "target": LIGHTHOUSE_INTERACT, "step": 1}
	if not Global.coast_beam_aligned:
		return {"name": "铜镜", "target": _quest_mirror_target(), "step": 2}
	if not Global.coast_tide_key:
		var key_target: Vector2 = TIDE_KEY_POS if Global.coast_tide_guardian_defeated else TIDE_GUARD_POS
		return {"name": "潮门钥匙", "target": key_target, "step": 3}
	if not Global.ska_defeated:
		var target: Vector2 = BOSS_POS if boss_started else Vector2(1720, 700)
		return {"name": "龙骨祭坛", "target": target, "step": 4}
	if not Global.third_stele_lit:
		return {"name": "第三座石碑", "target": STELE_POS, "step": 5}
	return {"name": "已完成", "target": player.global_position, "step": 6}


func _quest_mirror_target() -> Vector2:
	for data in MIRROR_DATA:
		if bool(Global.get(str(data["flag"]))):
			continue
		if not bool(Global.get(str(data["guard_flag"]))):
			var guard_pos: Vector2 = data["guard_pos"]
			return guard_pos
		var mirror_pos: Vector2 = data["pos"]
		return mirror_pos
	return LIGHTHOUSE_INTERACT


func _direction_arrow(delta: Vector2) -> String:
	if delta.length() < 24.0:
		return "·"
	var ax := absf(delta.x)
	var ay := absf(delta.y)
	if ax > ay * 1.8:
		return "→" if delta.x > 0.0 else "←"
	if ay > ax * 1.8:
		return "↓" if delta.y > 0.0 else "↑"
	if delta.x > 0.0 and delta.y > 0.0:
		return "↘"
	if delta.x > 0.0 and delta.y < 0.0:
		return "↗"
	if delta.x < 0.0 and delta.y > 0.0:
		return "↙"
	return "↖"


func _talk_pilgrim() -> void:
	var text := ""
	if not Global.coast_lens_found:
		text = "灯塔熄灭后，赤潮就不再退了。透镜被冲进了东边的沉船，低潮时船身才会露出来。沿着路牌往东走，别在涨潮时困在浅滩上。"
	elif not Global.coast_lighthouse_lit:
		text = "拿到透镜了？回西边的灯塔，把它放回灯室。灯光能驱散灰烬雾，打开龙骨祭坛的潮门。"
	elif not Global.ska_defeated:
		text = "潮门开了。斯卡就在龙骨祭坛里，它能掀起赤潮。待在场地中央，别被边缘的熔岩吞掉。"
	else:
		text = "赤潮终于退了。去点燃第三座誓火石碑吧，那是这片海岸最后的事了。"
	hud.call("show_dialog", "迷途的朝圣者", text)
	pilgrim_talked = true


func _set_tide_alpha(alpha: float) -> void:
	for layer in tide_overlays:
		if layer != null and is_instance_valid(layer):
			layer.modulate.a = alpha


func _player_in_tide() -> bool:
	if player == null:
		return false
	for rect in TIDE_RECTS:
		if rect.has_point(player.global_position):
			return true
	return false


func _update_tide(delta: float) -> void:
	if boss_started:
		if tide_panel != null:
			tide_panel.visible = false
		return
	tide_timer -= delta
	if tide_timer <= 0.0:
		match tide_state:
			"low":
				tide_state = "rising"
				tide_timer = TIDE_RISE_TIME
				_set_tide_alpha(0.45)
				hud.call("show_notice", "赤潮开始上涨，低滩会变得危险")
			"rising":
				tide_state = "high"
				tide_timer = TIDE_HIGH_TIME
				_set_tide_alpha(0.85)
				hud.call("show_notice", "赤潮汹涌！离开低滩")
			"high":
				tide_state = "falling"
				tide_timer = TIDE_FALL_TIME
				_set_tide_alpha(0.45)
			"falling":
				tide_state = "low"
				tide_timer = TIDE_LOW_TIME
				_set_tide_alpha(0.0)
				hud.call("show_notice", "赤潮退去了")
	_refresh_tide_passages()
	_update_tide_ui()
	if tide_state == "high":
		tide_damage_timer -= delta
		if tide_damage_timer <= 0.0:
			tide_damage_timer = 0.8
			if _player_in_tide():
				player.call("take_damage", 7)


func start_boss_tide() -> void:
	if boss_tide_active:
		return
	boss_tide_active = true
	for layer in boss_tide_overlays:
		if layer != null and is_instance_valid(layer):
			layer.modulate.a = 0.85
	if tide_panel != null:
		tide_panel.visible = false
	hud.call("show_notice", "赤潮上涨，场地边缘变得危险！")


func _update_boss_tide(delta: float) -> void:
	if not boss_tide_active:
		return
	boss_tide_damage_timer -= delta
	if boss_tide_damage_timer <= 0.0:
		boss_tide_damage_timer = 0.8
		if not ARENA_SAFE.has_point(player.global_position) and ARENA_RECT.has_point(player.global_position):
			player.call("take_damage", 8)


func on_scene_process(delta: float) -> void:
	if player == null:
		return
	_update_tide(delta)
	_update_boss_tide(delta)
	_update_quest_ui()
	if Global.third_stele_lit and not objective_done:
		objective_done = true
		refresh_objective()
		return

	var interact_text := "[%s]" % Settings.binding_text("interact")

	if player.global_position.distance_to(RETURN_POS) <= 40.0:
		hud.call("show_interaction", "%s 返回白鹿镇公会" % interact_text)
		if Input.is_action_just_pressed("interact"):
			Global.return_to_white_deer_town()
		return

	if player.global_position.distance_to(PILGRIM_POS) <= 42.0:
		hud.call("show_interaction", "%s 与迷途的朝圣者交谈" % interact_text)
		if Input.is_action_just_pressed("interact"):
			_talk_pilgrim()
		return

	if not watch_log_seen and player.global_position.distance_to(WATCH_LOG_POS) <= 40.0:
		hud.call("show_interaction", "%s 阅读守夜人残记" % interact_text)
		if Input.is_action_just_pressed("interact"):
			watch_log_seen = true
			hud.call("show_dialog", "守夜人残记", "赤潮不是海。龙骨山下的东西醒来后，海水就被染红了。灯塔的光能暂时压住它，但透镜必须从沉船里取回。")
		return

	for data in MIRROR_DATA:
		var mirror_pos: Vector2 = data["pos"]
		if player.global_position.distance_to(mirror_pos) > 58.0:
			continue
		var id := str(data["id"])
		if bool(Global.get(str(data["flag"]))):
			hud.call("show_interaction", "%s · 已对准" % str(data["label"]))
			return
		if not bool(Global.get(str(data["guard_flag"]))):
			hud.call("show_interaction", "%s · 先击败铜镜守卫" % str(data["label"]))
			return
		hud.call("show_interaction", "%s 转动%s" % [interact_text, str(data["label"])])
		if Input.is_action_just_pressed("interact"):
			_rotate_mirror(id)
		return

	if player.global_position.distance_to(WRECK_DOOR_POS) <= 44.0:
		if tide_state != "low":
			hud.call("show_interaction", "赤潮太高，沉船入口被淹 · 等退潮再来")
			return
		hud.call("show_interaction", "%s 进入沉船" % interact_text)
		if Input.is_action_just_pressed("interact"):
			travel_to("res://scenes/coast/wreck_interior.tscn", "entrance")
		return

	if player.global_position.distance_to(LIGHTHOUSE_INTERACT) <= 48.0:
		hud.call("show_interaction", "%s 进入灯塔" % interact_text)
		if Input.is_action_just_pressed("interact"):
			travel_to("res://scenes/coast/lighthouse_interior.tscn", "entrance")
		return

	if not Global.coast_tide_key and Global.coast_tide_guardian_defeated and player.global_position.distance_to(TIDE_KEY_POS) <= 36.0:
		hud.call("show_interaction", "%s 拾取潮门钥匙" % interact_text)
		if Input.is_action_just_pressed("interact"):
			_pick_tide_key()
		return

	if player.global_position.distance_to(CHECKPOINT) <= 42.0:
		hud.call("show_interaction", "%s 检查营火" % interact_text)
		if Input.is_action_just_pressed("interact"):
			_set_checkpoint()
		return

	if not Global.coast_chest_opened and cave_chest_sprite != null and player.global_position.distance_to(CAVE_CHEST_POS) <= 40.0:
		hud.call("show_interaction", "%s 打开海蚀洞宝箱" % interact_text)
		if Input.is_action_just_pressed("interact"):
			_open_cave_chest()
		return

	if not Global.coast_vault_opened and vault_chest_sprite != null and player.global_position.distance_to(VAULT_CHEST_POS) <= 40.0:
		hud.call("show_interaction", "%s 打开沉船宝箱" % interact_text)
		if Input.is_action_just_pressed("interact"):
			_open_vault_chest()
		return

	if not tide_gate_open and not Global.ska_defeated and player.global_position.distance_to(Vector2(1720, 700)) <= 56.0:
		hud.call("show_interaction", "潮门被锁住了：需要校准灯塔光束与潮门钥匙")
		return

	if (
		not boss_started
		and not Global.ska_defeated
		and tide_gate_open
		and boss != null
		and is_instance_valid(boss)
		and player.global_position.x > 1800.0
		and player.global_position.y > 400.0
		and player.global_position.y < 1000.0
	):
		_start_boss()
		return

	hud.call("clear_interaction")


func _set_checkpoint() -> void:
	checkpoint_pos = CHECKPOINT
	player.set_spawn_position(CHECKPOINT)
	SaveGame.save_game("赤烬海岸灯塔")
	hud.call("show_notice", "已记录检查点")


func _start_boss() -> void:
	boss_started = true
	boss_phase = 1
	_set_gate(false)
	if boss != null and is_instance_valid(boss):
		boss.call("activate")
	Sfx.play("danger", 0.55, 0.0)
	hud.call("show_banner", "赤烬龙裔 · 斯卡", "赤烬海岸的守潮者", 2.2)
	if tide_panel != null:
		tide_panel.visible = false
	refresh_objective()


func _on_boss_phase(new_phase: int) -> void:
	boss_phase = new_phase
	if new_phase >= 2:
		start_boss_tide()
		hud.call("show_banner", "赤潮上涨！", "斯卡进入第二阶段", 2.0)
		refresh_objective()


func _on_boss_died() -> void:
	Global.ska_defeated = true
	boss_started = false
	boss_tide_active = false
	for layer in boss_tide_overlays:
		if layer != null and is_instance_valid(layer):
			layer.modulate.a = 0.0
	if tide_panel != null:
		tide_panel.visible = true
	_set_gate(true)
	SaveGame.save_game("赤烬海岸")
	hud.call("show_banner", "斯卡倒下了", "祭坛后的誓火石碑显现了", 2.6)
	refresh_objective()
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.call("set_input_locked", false)


func on_after_revive() -> void:
	player.global_position = checkpoint_pos
	if boss_started and not Global.ska_defeated and boss != null and is_instance_valid(boss):
		boss.call("reset_fight")
	boss_started = false
	boss_phase = 1
	boss_tide_active = false
	for layer in boss_tide_overlays:
		if layer != null and is_instance_valid(layer):
			layer.modulate.a = 0.0
	if (Global.coast_lighthouse_lit and Global.coast_beam_aligned and Global.coast_tide_key) or Global.ska_defeated:
		_set_gate(true)
	tide_state = "low"
	tide_timer = 18.0
	_set_tide_alpha(0.0)
	_refresh_tide_passages()
	if tide_panel != null:
		tide_panel.visible = true
	refresh_objective()
