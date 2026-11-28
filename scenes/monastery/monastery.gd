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
const RELIQUARY: Texture2D = preload("res://graphics/monastery/reliquary.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")

const ENEMY_SCENE: PackedScene = preload("res://scenes/monastery/monastery_enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/monastery/still_sworn.tscn")
const STELE_SCENE: PackedScene = preload("res://scenes/level/oath_stele.tscn")
const RETURN_GATE_SCRIPT: Script = preload("res://scenes/level/town_return_gate.gd")
const BELL_NODE_SCRIPT: Script = preload("res://scenes/monastery/bell_node.gd")

const TILE_CHOICES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
]
const CARPET_CHOICES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]

const NAV_CELL := 32
const NAV_MIN := Vector2(64, 48)
const NAV_MAX := Vector2(1696, 1328)

const ENTRANCE := Vector2(888, 1270)
const RETURN_POS := Vector2(630, 1240)
const CHAPEL_TARGET := Vector2(888, 368)
const BOSS_TARGET := Vector2(888, 230)
const STELE_POS := Vector2(888, 110)
const CHECKPOINT := Vector2(888, 850)
const CHEST_POS := Vector2(330, 650)
const LORE_POS := Vector2(230, 570)
const CHAPEL_DOOR_RECT := Rect2(848, 352, 80, 32)
const CANDLE_POSITIONS: Array[Vector2] = [
	Vector2(330, 1080),
	Vector2(220, 740),
	Vector2(1550, 740),
]
const BELL_POSITIONS: Array[Vector2] = [
	Vector2(1350, 650),
	Vector2(1440, 650),
	Vector2(1530, 650),
]
const BELL_ORDER: Array[int] = [1, 0, 2]
const BELL_CENTER := Vector2(1440, 650)
const BELL_ROOM_RECT := Rect2(1304, 512, 288, 288)
const BELL_DEFENSE_TIME := 35.0
const BELL_LEAVE_LIMIT := 3.0
const BELL_DOOR_SPAWN := Vector2(1284, 640)
const BELL_WINDOW_OUTSIDE := Vector2(1664, 590)
const BELL_WINDOW_LAND := Vector2(1552, 640)
const BELL_INNER_SPAWNS: Array[Vector2] = [
	Vector2(1350, 700), Vector2(1530, 700), Vector2(1440, 740),
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
var nav_panel: Panel
var nav_label: Label
var nav_beacon: Sprite2D
var bell_panel: Panel
var bell_label: Label
var bell_progress := 0
var bell_puzzle_solved := false
var bell_defense_active := false
var bell_defense_timer := 0.0
var bell_leave_timer := 0.0
var bell_spawn_clock := 0.0
var bell_spawn_pause := 0.0
var bell_spawn_batch := 0
var bell_nodes: Array = []
var bell_ring: Line2D
var bell_clue_seen := false


func on_scene_ready() -> void:
	add_to_group("MonasteryNav")
	build_monastery()
	_build_nav_ui()
	resolve_spawn(ENTRANCE)
	player.set_spawn_position(player.global_position)
	checkpoint_pos = player.global_position
	bell_puzzle_solved = Global.monastery_bell_solved or Global.monastery_right_seal
	bell_progress = BELL_ORDER.size() if bell_puzzle_solved else 0
	bell_defense_timer = BELL_DEFENSE_TIME
	_build_bell_event()
	hud.call("show_banner", "失誓修道院", "雾中的墓园与失誓者", 2.8)
	refresh_objective()
	SaveGame.save_game("失誓修道院")
	if Global.second_stele_lit:
		objective_done = true
	await get_tree().physics_frame
	_build_nav_grid()
	_build_enemies()
	_build_boss()
	_build_stele()
	_build_return_gate()
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
		if not bell_puzzle_solved:
			set_objective("按彩窗顺序敲响三座铜钟")
			set_tutorial("钟楼彩窗：中 → 左 → 右")
		elif bell_defense_active:
			set_objective("守住钟楼 35 秒")
			set_tutorial("留在钟楼房间内，离开 3 秒会失败")
		else:
			set_objective("回到钟楼重新守钟")
			set_tutorial("在钟楼中央按交互键重新开始")
	elif Global.monastery_right_seal and not Global.monastery_chest_opened:
		set_objective("前往圣物室解开封印")
		set_tutorial("圣物室在礼拜堂左侧 · 残烛 %d/3" % lit)
	else:
		set_objective("打开圣物室与钟楼的封印")
		set_tutorial("圣物室在左；钟楼在右，按彩窗顺序敲钟 · 残烛 %d/3" % lit)


func _build_nav_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	nav_panel = Panel.new()
	nav_panel.position = Vector2(8, 6)
	nav_panel.size = Vector2(80, 23)
	nav_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.035, 0.03, 0.86)
	style.border_color = Color(0.73, 0.55, 0.24, 0.68)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	nav_panel.add_theme_stylebox_override("panel", style)
	root.add_child(nav_panel)
	nav_label = Label.new()
	nav_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nav_label.add_theme_font_override("font", hud.ui_font)
	nav_label.add_theme_font_size_override("font_size", 6)
	nav_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.64))
	nav_label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	nav_label.add_theme_constant_override("outline_size", 2)
	nav_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav_panel.add_child(nav_label)
	nav_panel.visible = false

	bell_panel = Panel.new()
	bell_panel.anchor_left = 0.0
	bell_panel.anchor_right = 0.0
	bell_panel.anchor_top = 0.0
	bell_panel.anchor_bottom = 0.0
	bell_panel.offset_left = 8.0
	bell_panel.offset_right = 152.0
	bell_panel.offset_top = 34.0
	bell_panel.offset_bottom = 62.0
	bell_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bell_style := StyleBoxFlat.new()
	bell_style.bg_color = Color(0.05, 0.04, 0.03, 0.9)
	bell_style.border_color = Color(0.92, 0.68, 0.25, 0.8)
	bell_style.set_border_width_all(1)
	bell_style.set_corner_radius_all(3)
	bell_panel.add_theme_stylebox_override("panel", bell_style)
	root.add_child(bell_panel)
	bell_label = Label.new()
	bell_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bell_label.add_theme_font_override("font", hud.ui_font)
	bell_label.add_theme_font_size_override("font_size", 8)
	bell_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	bell_label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	bell_label.add_theme_constant_override("outline_size", 2)
	bell_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bell_panel.add_child(bell_label)
	bell_panel.visible = false

	nav_beacon = Sprite2D.new()
	nav_beacon.texture = GLOW
	nav_beacon.scale = Vector2(1.6, 1.6)
	nav_beacon.modulate = Color(1.0, 0.72, 0.3, 0.0)
	nav_beacon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	nav_beacon.z_index = 3
	nav_beacon.visible = false
	objects.add_child(nav_beacon)


func _update_nav_ui() -> void:
	if nav_panel == null or nav_beacon == null or player == null:
		return
	if Global.second_stele_lit or bool(player.get("dead")):
		nav_panel.visible = false
		nav_beacon.visible = false
		return
	var info := _nav_target()
	if info.is_empty():
		nav_panel.visible = false
		nav_beacon.visible = false
		return
	var target: Vector2 = info["target"]
	var delta: Vector2 = target - player.global_position
	nav_panel.visible = true
	nav_label.text = "%s %s %d步" % [
		str(info["name"]),
		_direction_arrow(delta),
		int(round(delta.length() / 10.0)),
	]
	nav_beacon.visible = true
	nav_beacon.global_position = target + Vector2(0, -42)
	var pulse := 0.2 + 0.1 * absf(sin(float(Time.get_ticks_msec()) * 0.004))
	nav_beacon.modulate = Color(1.0, 0.72, 0.3, pulse)


func _nav_target() -> Dictionary:
	if Global.second_stele_lit:
		return {}
	if Global.roland_defeated:
		return {"name": "石碑", "target": STELE_POS}
	if boss_started:
		var boss_target := BOSS_TARGET
		if boss != null and is_instance_valid(boss):
			boss_target = boss.global_position
		return {"name": "罗兰", "target": boss_target}
	if Global.monastery_chapel_open:
		return {"name": "礼拜堂", "target": CHAPEL_TARGET}
	if not Global.monastery_chest_opened:
		return {"name": "圣物室", "target": CHEST_POS}
	if not Global.monastery_right_seal:
		return {"name": "钟楼", "target": BELL_CENTER}
	return {"name": "礼拜堂", "target": CHAPEL_TARGET}


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
	for pos in [Vector2(400, 600), Vector2(1580, 600)]:
		_prop(CANDLE, pos, 2.0)
		_glow(pos, Color(1.0, 0.55, 0.2, 0.35), 1.8)
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


func _build_bell_event() -> void:
	_prop(GLASS, Vector2(1440, 585), 2.0)
	_glow(Vector2(1440, 585), Color(0.45, 0.65, 1.0, 0.22), 2.2)
	add_world_label("彩窗：中 → 左 → 右", Vector2(1340, 590), 7, Color(0.8, 0.86, 1.0))
	_prop(GLASS, Vector2(1592, 620), 1.6)
	_glow(Vector2(1592, 620), Color(0.45, 0.65, 1.0, 0.2), 1.8)
	add_world_label("塔窗", Vector2(1545, 585), 7, Color(0.78, 0.84, 1.0))
	for i in BELL_POSITIONS.size():
		var bell := Node2D.new()
		bell.set_script(BELL_NODE_SCRIPT)
		bell.position = BELL_POSITIONS[i]
		bell.z_index = 1
		objects.add_child(bell)
		bell.set("bell_index", i)
		bell_nodes.append(bell)
		add_world_label(["左钟", "中钟", "右钟"][i], BELL_POSITIONS[i] + Vector2(-30, 12), 7, Color(0.86, 0.8, 0.62))

	bell_ring = Line2D.new()
	bell_ring.width = 2.0
	bell_ring.default_color = Color(0.95, 0.72, 0.3, 0.5)
	bell_ring.z_index = 1
	bell_ring.visible = false
	var room_end := BELL_ROOM_RECT.position + BELL_ROOM_RECT.size
	for point in [
		BELL_ROOM_RECT.position,
		Vector2(room_end.x, BELL_ROOM_RECT.position.y),
		room_end,
		Vector2(BELL_ROOM_RECT.position.x, room_end.y),
		BELL_ROOM_RECT.position,
	]:
		bell_ring.add_point(point)
	objects.add_child(bell_ring)
	_refresh_bell_visuals()


func _refresh_bell_visuals() -> void:
	var next := -1
	if not bell_puzzle_solved and bell_progress < BELL_ORDER.size():
		next = BELL_ORDER[bell_progress]
	for i in bell_nodes.size():
		bell_nodes[i].call("set_state", i == next, bell_puzzle_solved)
	if bell_ring != null:
		bell_ring.visible = bell_defense_active


func _update_bell_ui(override_text: String = "") -> void:
	if bell_panel == null:
		return
	bell_panel.visible = bell_defense_active
	if not bell_defense_active:
		return
	if not override_text.is_empty():
		bell_label.text = override_text
		bell_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.32))
	else:
		bell_label.text = "守钟 %02d 秒" % int(ceil(maxf(bell_defense_timer, 0.0)))
		bell_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))


func _ring_bell(index: int) -> void:
	if bell_puzzle_solved or Global.monastery_right_seal:
		return
	var expected := BELL_ORDER[bell_progress]
	if index != expected:
		bell_progress = 0
		_refresh_bell_visuals()
		hud.call("show_notice", "钟声乱了，守墓人被引来！")
		Sfx.play("warn", 0.8, -6.0)
		_spawn_bell_intruders(3)
		return

	bell_progress += 1
	Sfx.play("craft", 1.0, 2.0)
	if bell_progress >= BELL_ORDER.size():
		bell_puzzle_solved = true
		Global.monastery_bell_solved = true
		SaveGame.save_game("失誓修道院")
		_refresh_bell_visuals()
		_start_bell_defense()
	else:
		hud.call("show_notice", "钟声正确（%d/%d）" % [bell_progress, BELL_ORDER.size()])
		_refresh_bell_visuals()


func _spawn_bell_intruders(count: int) -> void:
	for i in count:
		var pos := _bell_door_pos()
		var enemy := _spawn_enemy("bone_gleaner", pos)
		if enemy != null:
			enemy.set("awake", true)
			enemy.add_to_group("BellDefenseEnemies")


func _start_bell_defense() -> void:
	if bell_defense_active or Global.monastery_right_seal:
		return
	bell_defense_active = true
	bell_defense_timer = BELL_DEFENSE_TIME
	bell_leave_timer = 0.0
	bell_spawn_clock = 0.8
	bell_spawn_pause = 0.0
	bell_spawn_batch = 0
	_update_bell_ui()
	_refresh_bell_visuals()
	hud.call("show_banner", "钟声齐鸣", "留在钟楼房间内，守住 35 秒", 2.4)
	refresh_objective()


func _update_bell_defense(delta: float) -> void:
	if player == null or not is_instance_valid(player) or bool(player.get("dead")):
		_fail_bell_defense()
		return
	if not BELL_ROOM_RECT.has_point(player.global_position):
		bell_leave_timer += delta
		_update_bell_ui("回到钟楼房间内！")
		if bell_leave_timer >= BELL_LEAVE_LIMIT:
			_fail_bell_defense()
		return

	bell_leave_timer = 0.0
	bell_defense_timer -= delta
	_update_bell_spawner(delta)
	_update_bell_ui()
	if bell_defense_timer <= 0.0:
		_complete_bell_defense()


func _update_bell_spawner(delta: float) -> void:
	if bell_spawn_pause > 0.0:
		bell_spawn_pause -= delta
		return
	bell_spawn_clock -= delta
	if bell_spawn_clock > 0.0:
		return
	_spawn_bell_batch()
	bell_spawn_batch += 1
	bell_spawn_clock = randf_range(2.8, 4.5)
	if bell_spawn_batch % 4 == 0:
		bell_spawn_pause = randf_range(4.0, 6.0)


func _spawn_bell_batch() -> void:
	if _bell_enemy_count() >= 8:
		return
	if bell_spawn_batch % 3 == 0:
		_spawn_bell_window_climber()
	else:
		_spawn_bell_enemy("bone_gleaner", _bell_door_pos())
	if bell_spawn_batch > 0 and bell_spawn_batch % 3 == 0:
		_spawn_bell_enemy("bone_gleaner", _bell_door_pos())
	if bell_spawn_batch > 0 and bell_spawn_batch % 6 == 0:
		_spawn_bell_enemy("mourner", _bell_inner_pos())
	if bell_spawn_batch > 0 and bell_spawn_batch % 9 == 0:
		_spawn_bell_enemy("ember_crown", _bell_inner_pos())


func _bell_door_pos() -> Vector2:
	return BELL_DOOR_SPAWN + Vector2(0, randf_range(-18.0, 18.0))


func _bell_inner_pos() -> Vector2:
	return BELL_INNER_SPAWNS[randi() % BELL_INNER_SPAWNS.size()]


func _spawn_bell_window_climber() -> void:
	if _bell_enemy_count() >= 8:
		return
	var enemy := _spawn_enemy("bone_gleaner", BELL_WINDOW_OUTSIDE)
	if enemy == null:
		return
	enemy.set("awake", true)
	enemy.add_to_group("BellDefenseEnemies")
	enemy.add_to_group("BellWindowClimbers")
	enemy.global_position = BELL_WINDOW_OUTSIDE
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", true)
	var start := BELL_WINDOW_OUTSIDE
	var elapsed := 0.0
	while elapsed < 0.65:
		if not is_instance_valid(enemy):
			return
		elapsed += get_process_delta_time()
		enemy.global_position = start.lerp(BELL_WINDOW_LAND, clampf(elapsed / 0.65, 0.0, 1.0))
		await get_tree().process_frame
	if not is_instance_valid(enemy):
		return
	enemy.global_position = BELL_WINDOW_LAND
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	if shape != null and is_instance_valid(shape):
		shape.set_deferred("disabled", false)


func _spawn_bell_enemy(kind: String, pos: Vector2) -> void:
	var enemy := _spawn_enemy(kind, pos)
	if enemy != null:
		enemy.set("awake", true)
		enemy.add_to_group("BellDefenseEnemies")


func _fail_bell_defense() -> void:
	bell_defense_active = false
	bell_defense_timer = BELL_DEFENSE_TIME
	bell_leave_timer = 0.0
	bell_spawn_clock = 0.0
	bell_spawn_pause = 0.0
	bell_spawn_batch = 0
	_update_bell_ui()
	_clear_bell_enemies()
	_refresh_bell_visuals()
	hud.call("show_notice", "离开钟楼太久，守钟失败；回到钟楼中央按交互键重新开始")
	refresh_objective()


func _complete_bell_defense() -> void:
	bell_defense_active = false
	bell_defense_timer = 0.0
	bell_leave_timer = 0.0
	_update_bell_ui()
	Global.monastery_right_seal = true
	Global.monastery_bell_solved = true
	SaveGame.save_game("失誓修道院")
	_clear_bell_enemies()
	_refresh_bell_visuals()
	hud.call("show_banner", "钟楼封印解除", "礼拜堂的另一半封印已解除", 2.6)
	_try_open_chapel()
	refresh_objective()


func _bell_enemy_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("BellDefenseEnemies"):
		if is_instance_valid(node) and not bool(node.get("dead")):
			count += 1
	return count


func _clear_bell_enemies() -> void:
	for node in get_tree().get_nodes_in_group("BellDefenseEnemies"):
		if is_instance_valid(node):
			node.queue_free()


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
		["bone_gleaner", Vector2(500, 1020)],
		["bone_gleaner", Vector2(1300, 1040)],
		["mourner", Vector2(820, 980)],
		["bone_gleaner", Vector2(600, 760)],
		["mourner", Vector2(1180, 760)],
		["bone_gleaner", Vector2(800, 470)],
		["mourner", Vector2(1000, 470)],
		["bone_gleaner", Vector2(380, 560)],
		["bone_gleaner", Vector2(360, 730)],
		["bone_gleaner", Vector2(1500, 580)],
		["ember_crown", Vector2(1430, 740)],
	]:
		_spawn_enemy(str(entry[0]), entry[1])


func _spawn_enemy(kind: String, pos: Vector2) -> Node2D:
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	if enemy == null:
		return null
	enemy.call("configure", kind)
	enemy.position = pos
	objects.add_child(enemy)
	return enemy


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
	stele.set("reveal_notice", "誓火石碑显现")
	stele.set("lit_notice", "誓火石碑已点燃，失誓修道院得到净化")
	stele.set("victory_title", "第二关完成")
	stele.set("victory_location", "失誓修道院")
	stele.set("reveal_delay", 2.0)
	stele.position = Vector2(888, 110)
	stele.scale = Vector2(1.5, 1.5)
	objects.add_child(stele)


func _build_return_gate() -> void:
	var gate := Node2D.new()
	gate.set_script(RETURN_GATE_SCRIPT)
	gate.position = RETURN_POS
	gate.set("label_text", "返回白鹿镇")
	gate.set("interactive", false)
	objects.add_child(gate)


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


func on_scene_process(delta: float) -> void:
	if player == null:
		return
	_update_nav_ui()
	if Global.second_stele_lit and not objective_done:
		objective_done = true
		refresh_objective()
		return
	if bell_defense_active:
		_update_bell_defense(delta)
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

	if not Global.monastery_right_seal and not bell_clue_seen and player.global_position.distance_to(BELL_CENTER) <= 150.0:
		bell_clue_seen = true
		hud.call("show_notice", "彩窗上的钟声顺序：中 → 左 → 右")

	if not Global.monastery_right_seal:
		if bell_puzzle_solved:
			if player.global_position.distance_to(BELL_CENTER) <= 64.0:
				hud.call("show_interaction", "%s 重新守钟" % interact_text)
				if Input.is_action_just_pressed("interact"):
					_start_bell_defense()
				return
		else:
			for i in BELL_POSITIONS.size():
				if player.global_position.distance_to(BELL_POSITIONS[i]) <= 48.0:
					hud.call("show_interaction", "%s 敲响%s" % [interact_text, ["左钟", "中钟", "右钟"][i]])
					if Input.is_action_just_pressed("interact"):
						_ring_bell(i)
					return

	if not Global.monastery_chapel_open:
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

	if player.global_position.distance_to(RETURN_POS) <= 40.0:
		hud.call("show_interaction", "%s 返回白鹿镇公会" % interact_text)
		if Input.is_action_just_pressed("interact"):
			Global.return_to_white_deer_town()
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
	hud.call("show_banner", "失誓骑士罗兰倒下了", "祭坛前的誓火石碑显现了", 2.6)
	refresh_objective()
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.call("set_input_locked", false)


func on_after_revive() -> void:
	player.global_position = checkpoint_pos
	if boss_started and not Global.roland_defeated and boss != null and is_instance_valid(boss):
		boss.call("reset_fight")
		boss_started = false
		_set_chapel_door(true)
	refresh_objective()
