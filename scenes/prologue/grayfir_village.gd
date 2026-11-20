extends "res://scenes/prologue/prologue_scene_base.gd"

const DOOR: Texture2D = preload("res://graphics/camp/gate_closed.png")
const HILLS: Texture2D = preload("res://graphics/tilesets/hills_wood.png")
const HIGHLAND_TILESET: TileSet = preload("res://scenes/level/hills_tileset.tres")
const DUMMY_SCRIPT: Script = preload("res://scenes/prologue/training_dummy.gd")

const PLAYER_HOUSE_SCENE := "res://scenes/prologue/player_house.tscn"
const GARETH_HOUSE_SCENE := "res://scenes/prologue/gareth_house.tscn"
const BLACKSMITH_SCENE := "res://scenes/prologue/blacksmith.tscn"
const EAST_GATE_SCENE := "res://scenes/prologue/east_gate.tscn"

var entries := {}
var entry_prompts := {}
var stone_positions := {
	"warrior": Vector2(270, 95),
	"ranger": Vector2(350, 95),
	"mage": Vector2(430, 95),
}
var training_center := Vector2(350, 150)
var attack_hits := 0


func on_scene_ready() -> void:
	build_village()
	resolve_spawn(Vector2(305, 255), {
		"player_house": Vector2(145, 240),
		"gareth_house": Vector2(560, 240),
		"blacksmith": Vector2(165, 390),
		"east_gate": Vector2(660, 330),
	})
	player.set_spawn_position(Vector2(305, 255))
	hud.profession_selected.connect(_on_profession_selected)
	player.training_action.connect(_on_training_action)
	refresh_objective()


func _draw() -> void:
	draw_rect(Rect2(-100, -80, 960, 620), Color(0.1, 0.22, 0.19))


func build_village() -> void:
	add_tile_area(Rect2(0, 0, 760, 470), GRASS, [Vector2i(1, 1)], 2, 61)
	add_tile_area(Rect2(80, 220, 620, 70), SOIL, [Vector2i(1, 1)], 2, 62)
	for rect in [
		Rect2(105, 170, 40, 80),
		Rect2(545, 170, 40, 80),
		Rect2(330, 190, 40, 100),
		Rect2(120, 280, 40, 115),
		Rect2(625, 280, 40, 90),
	]:
		add_tile_area(rect, SOIL, [Vector2i(1, 1)], 2, 63)

	add_blocker(Rect2(0, 0, 760, 18))
	add_blocker(Rect2(0, 455, 760, 15))
	add_blocker(Rect2(0, 18, 18, 437))
	add_blocker(Rect2(742, 18, 18, 437))

	_add_building(Rect2(62, 137, 126, 82), "玩家住宅", Vector2(125, 224), "player_house")
	_add_building(Rect2(515, 137, 142, 82), "加雷斯的屋子", Vector2(586, 224), "gareth_house")
	_add_building(Rect2(65, 315, 126, 78), "铁匠铺", Vector2(128, 398), "blacksmith")

	# 村庄北侧的小高地：草地平台，从主路沿石阶正常走上去
	_add_highland(Vector2(190, 20), 10, 6, 4, 2)
	add_world_label("山谷", Vector2(330, 36), 12, Color(1.0, 0.84, 0.5))

	for profession_id in stone_positions:
		var pos: Vector2 = stone_positions[profession_id]
		add_sprite(HILLS, pos, 0.8)
	add_world_label("战士石碑", stone_positions["warrior"] + Vector2(-42, -35), 6, Color(0.96, 0.62, 0.3))
	add_world_label("游侠石碑", stone_positions["ranger"] + Vector2(-42, -35), 6, Color(0.55, 0.9, 0.45))
	add_world_label("法师石碑", stone_positions["mage"] + Vector2(-42, -35), 6, Color(0.55, 0.72, 1.0))

	for pos in [Vector2(315, 150), Vector2(385, 150)]:
		var dummy := Node2D.new()
		dummy.set_script(DUMMY_SCRIPT)
		dummy.position = pos
		objects.add_child(dummy)
	add_world_label("训练木桩", training_center + Vector2(-38, 26), 6, Color(0.9, 0.82, 0.64))

	add_sprite(DOOR, Vector2(665, 330), 1.6)
	add_world_label("东门", Vector2(637, 292), 9, Color(1.0, 0.78, 0.44))
	entries["east_gate"] = Vector2(665, 335)
	entry_prompts["east_gate"] = "前往东门"

	for pos in [
		Vector2(45, 75), Vector2(105, 50), Vector2(160, 50),
		Vector2(580, 52), Vector2(675, 72), Vector2(720, 140), Vector2(728, 220),
		Vector2(42, 220), Vector2(46, 300), Vector2(42, 410),
		Vector2(235, 445), Vector2(315, 455), Vector2(420, 450), Vector2(510, 440),
		Vector2(700, 430),
		# 山谷两侧
		Vector2(160, 120), Vector2(160, 190), Vector2(540, 80),
	]:
		add_tree(pos, 1.2, int(pos.x) % 2 == 0)


func _add_highland(origin: Vector2, width: int, height: int, stair_col: int, stair_width: int) -> void:
	var layer := TileMapLayer.new()
	layer.tile_set = HIGHLAND_TILESET
	layer.position = origin
	layer.scale = Vector2(2, 2)
	layer.z_index = 0
	for y in height:
		for x in width:
			var coords := Vector2i(1, 1)
			if y == 0:
				coords = Vector2i(0 if x == 0 else (2 if x == width - 1 else 1), 0)
			elif y == height - 1:
				coords = Vector2i(0 if x == 0 else (2 if x == width - 1 else 1), 2)
			elif x == 0:
				coords = Vector2i(0, 1)
			elif x == width - 1:
				coords = Vector2i(2, 1)
			layer.set_cell(Vector2i(x, y), 0, coords)
	# 石阶：替换底边的一小段，并向下延伸两级，形成上山台阶
	for i in stair_width:
		for row in 3:
			layer.set_cell(Vector2i(stair_col + i, height - 1 + row), 0, Vector2i(3, 2))
	objects.add_child(layer)


func _add_building(rect: Rect2, title: String, interaction_pos: Vector2, entry_id: String) -> void:
	add_tile_area(rect, WOOD_FLOOR, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	], 2, int(rect.position.x + rect.position.y))
	add_blocker(rect)
	add_sprite(DOOR, interaction_pos + Vector2(0, -6), 1.4)
	add_world_label(title, rect.position + Vector2(0, -24), 8, Color(1.0, 0.84, 0.5))
	entries[entry_id] = interaction_pos
	entry_prompts[entry_id] = "进入" + title


func refresh_objective() -> void:
	if not Global.gareth_talked:
		set_objective("前往加雷斯的屋子")
		set_tutorial("沿村庄道路向东，进入加雷斯的屋子")
	elif Global.profession.is_empty():
		set_objective("前往山谷选择职业")
		set_tutorial("沿村庄主路走到北侧，登上石阶进入山谷")
	elif not Global.tutorial_attack_done:
		set_objective("攻击训练木桩（%d/2）" % mini(attack_hits, 2))
		set_tutorial("[%s] 攻击训练木桩" % Settings.binding_text("action"))
	elif not Global.tutorial_skill_done:
		set_objective("使用一次职业技能")
		set_tutorial("[%s] 释放职业技能" % Settings.binding_text("dash"))
	elif not Global.tutorial_weapon_skill_done:
		set_objective("使用一次武器特技")
		set_tutorial("[%s] 使用武器特技" % Settings.binding_text("weapon_skill"))
	elif not Global.prologue_chest_opened:
		set_objective("前往铁匠铺领取补给")
		set_tutorial("铁匠铺位于村庄西南侧")
	else:
		set_objective("前往东门")
		set_tutorial("沿村庄道路向东前往东门")


func on_scene_process(_delta: float) -> void:
	var nearest_stone := ""
	var nearest_distance := INF
	for profession_id in stone_positions:
		var distance: float = player.global_position.distance_to(stone_positions[profession_id])
		if distance <= 40.0 and distance < nearest_distance:
			nearest_stone = profession_id
			nearest_distance = distance
	if not nearest_stone.is_empty():
		hud.call("show_interaction", "[%s] 触摸%s石碑" % [
			Settings.binding_text("interact"),
			_profession_label(nearest_stone),
		])
		if Input.is_action_just_pressed("interact"):
			if not Global.gareth_talked:
				hud.call("show_notice", "先前往加雷斯的屋子了解情况")
			elif not Global.profession.is_empty() and Global.profession_reselects >= 1:
				hud.call("show_notice", "离开山谷前只能重新选择一次职业")
			else:
				hud.call("open_profession_select", nearest_stone, not Global.profession.is_empty())
		return

	var nearest := ""
	var nearest_distance_entry := INF
	for entry_id in entries:
		var distance: float = player.global_position.distance_to(entries[entry_id])
		if distance <= 40.0 and distance < nearest_distance_entry:
			nearest = entry_id
			nearest_distance_entry = distance
	if nearest.is_empty():
		hud.call("clear_interaction")
		return
	hud.call("show_interaction", "[%s] %s" % [
		Settings.binding_text("interact"),
		entry_prompts[nearest],
	])
	if not Input.is_action_just_pressed("interact"):
		return
	match nearest:
		"player_house":
			travel_to(PLAYER_HOUSE_SCENE)
		"gareth_house":
			travel_to(GARETH_HOUSE_SCENE)
		"blacksmith":
			travel_to(BLACKSMITH_SCENE)
		"east_gate":
			travel_to(EAST_GATE_SCENE)


func _on_profession_selected(profession_id: String) -> void:
	var previous := str(player.get("profession"))
	if not previous.is_empty() and previous != profession_id:
		Global.profession_reselects += 1
	player.call("setup_profession", profession_id)
	Global.profession = profession_id
	var weapon_item := str(player.call("get_profession_weapon_item"))
	if int(Global.inventory.get(weapon_item, 0)) <= 0:
		Global.add_item(weapon_item, 1)
	if Global.hotbar[0].is_empty() or Global.hotbar[0] in ["warrior_weapon", "ranger_weapon", "mage_weapon"]:
		Global.move_item_to_hotbar(0, {"kind": "inventory_item", "item_id": weapon_item})
	player.set_spawn_position(training_center)
	SaveGame.save_game("灰杉村山谷")
	refresh_objective()


func _on_training_action(action_name: String) -> void:
	if player.global_position.distance_to(training_center) > 85.0:
		return
	match action_name:
		"attack":
			if not Global.tutorial_attack_done:
				attack_hits += 1
				if attack_hits >= 2:
					Global.tutorial_attack_done = true
		"skill":
			if Global.tutorial_attack_done:
				Global.tutorial_skill_done = true
		"weapon_skill":
			if Global.tutorial_skill_done:
				Global.tutorial_weapon_skill_done = true
	refresh_objective()


func _profession_label(profession_id: String) -> String:
	return {"warrior": "战士", "ranger": "游侠", "mage": "法师"}.get(profession_id, "")


func on_after_revive() -> void:
	player.global_position = Vector2(305, 255)
