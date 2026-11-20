extends "res://scenes/prologue/prologue_scene_base.gd"

const TABLE: Texture2D = preload("res://graphics/camp/diary_table.png")
const LOG: Texture2D = preload("res://graphics/camp/camp_log.png")
const FIRE: Texture2D = preload("res://graphics/camp/campfire.png")
const DOOR: Texture2D = preload("res://graphics/camp/gate_closed.png")
const VILLAGE_SCENE := "res://scenes/prologue/grayfir_village.tscn"

var door_position := Vector2(330, 318)
var gareth_position := Vector2(238, 155)
var dialog_context := ""


func on_scene_ready() -> void:
	build_house()
	resolve_spawn(door_position + Vector2(0, -42))
	player.set_spawn_position(door_position + Vector2(0, -42))
	hud.dialog_finished.connect(_on_dialog_finished)
	refresh_objective()


func build_house() -> void:
	add_tile_area(Rect2(48, 55, 480, 250), WOOD_FLOOR, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	], 2, 16)
	add_blocker(Rect2(0, 0, 576, 55))
	add_blocker(Rect2(0, 305, 576, 45))
	add_blocker(Rect2(0, 55, 48, 250))
	add_blocker(Rect2(528, 55, 48, 250))
	add_sprite(TABLE, Vector2(140, 124), 1.8)
	add_sprite(LOG, Vector2(432, 126), 1.7)
	add_atlas_sprite(FIRE, Rect2(0, 0, 32, 32), Vector2(430, 218), 1.4, Color(1.0, 0.8, 0.65))
	add_sprite(DOOR, door_position, 1.7)
	add_person(gareth_position, Color(0.72, 0.82, 1.0))
	add_world_label("加雷斯的屋子", Vector2(207, 31), 11, Color(1.0, 0.84, 0.5))
	add_world_label("加雷斯爵士", gareth_position + Vector2(-45, -49), 7, Color(0.75, 0.84, 1.0))
	add_world_label("旧地图与银誓记录", Vector2(98, 161), 7, Color(0.76, 0.68, 0.53))


func refresh_objective() -> void:
	if not Global.gareth_talked:
		set_objective("与加雷斯爵士交谈")
		set_tutorial("[%s] 与加雷斯交谈" % Settings.binding_text("interact"))
	elif Global.profession.is_empty():
		set_objective("前往山谷选择职业")
		set_tutorial("离开屋子，沿村庄中段的山路一直向北前往山谷")
	elif not Global.tutorial_weapon_skill_done:
		set_objective("返回山谷完成训练")
		set_tutorial("回到山谷，完成职业技能与武器特技训练")
	elif not Global.prologue_chest_opened:
		set_objective("前往铁匠铺领取补给")
		set_tutorial("铁匠铺位于村庄西南侧")
	else:
		set_objective("前往东门")
		set_tutorial("沿村庄道路向东前往东门")


func on_scene_process(_delta: float) -> void:
	var near_gareth: bool = player.global_position.distance_to(gareth_position) <= 38.0
	var near_door: bool = player.global_position.distance_to(door_position) <= 34.0
	if near_gareth:
		hud.call("show_interaction", "[%s] 与加雷斯交谈" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_talk_to_gareth()
	elif near_door:
		hud.call("show_interaction", "[%s] 离开屋子" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			travel_to(VILLAGE_SCENE, "gareth_house")
	else:
		hud.call("clear_interaction")


func _talk_to_gareth() -> void:
	dialog_context = "intro"
	Global.gareth_talked = true
	var text := "丰收祭开始了。先去山谷触摸职业石碑，确定你今后的战斗方式。完成训练后，铁匠奥托会为你准备好补给。"
	if Global.prologue_chest_opened:
		text = "补给已经备好。沿东侧道路去东门，那里需要你。"
	elif not Global.profession.is_empty():
		if not Global.tutorial_weapon_skill_done:
			text = "训练还没结束。回山谷把职业技能和武器特技练熟。"
		else:
			text = "去铁匠铺找奥托领取补给，然后前往东门。"
	hud.call("show_dialog", "加雷斯爵士", text)
	refresh_objective()
	SaveGame.save_game("加雷斯的屋子")


func _on_dialog_finished() -> void:
	if dialog_context == "intro":
		dialog_context = ""
		refresh_objective()


func on_after_revive() -> void:
	player.global_position = door_position + Vector2(0, -42)

