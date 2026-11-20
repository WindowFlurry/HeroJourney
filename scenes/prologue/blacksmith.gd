extends "res://scenes/prologue/prologue_scene_base.gd"

const FIRE: Texture2D = preload("res://graphics/camp/campfire.png")
const TABLE: Texture2D = preload("res://graphics/camp/diary_table.png")
const LOG: Texture2D = preload("res://graphics/camp/camp_log.png")
const DOOR: Texture2D = preload("res://graphics/camp/gate_closed.png")
const SWORD: Texture2D = preload("res://graphics/objects/waste_sword.png")
const SHIELD: Texture2D = preload("res://graphics/items/shield_up.png")
const VILLAGE_SCENE := "res://scenes/prologue/grayfir_village.tscn"

var door_position := Vector2(425, 318)
var chest_position := Vector2(295, 206)
var smith_position := Vector2(180, 150)


func on_scene_ready() -> void:
	build_shop()
	resolve_spawn(door_position + Vector2(0, -42))
	player.set_spawn_position(door_position + Vector2(0, -42))
	refresh_objective()


func build_shop() -> void:
	add_tile_area(Rect2(48, 55, 480, 250), WOOD_FLOOR, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	], 2, 44)
	add_blocker(Rect2(0, 0, 576, 55))
	add_blocker(Rect2(0, 305, 576, 45))
	add_blocker(Rect2(0, 55, 48, 250))
	add_blocker(Rect2(528, 55, 48, 250))
	add_atlas_sprite(FIRE, Rect2(0, 0, 32, 32), Vector2(135, 190), 1.6)
	add_sprite(TABLE, Vector2(270, 120), 1.7)
	add_sprite(LOG, chest_position, 1.4)
	add_sprite(SHIELD, chest_position + Vector2(0, -18), 2.2, Color(1.0, 0.84, 0.45))
	add_sprite(SWORD, Vector2(432, 125), 1.8)
	add_sprite(DOOR, door_position, 1.7)
	add_person(smith_position, Color(0.92, 0.64, 0.34))
	add_world_label("铁匠铺", Vector2(245, 31), 12, Color(1.0, 0.84, 0.5))
	add_world_label("铁匠奥托", smith_position + Vector2(-35, -48), 7, Color(0.96, 0.72, 0.46))
	add_world_label("补给宝箱", chest_position + Vector2(-34, 30), 7, Color(0.96, 0.78, 0.42))


func refresh_objective() -> void:
	if Global.prologue_chest_opened:
		set_objective("前往东门")
		set_tutorial("补给已经领取，离开铁匠铺前往东门")
	elif not Global.profession.is_empty() and Global.tutorial_weapon_skill_done:
		set_objective("打开补给宝箱")
		set_tutorial("[%s] 打开补给宝箱 · [%s] 查看角色" % [
			Settings.binding_text("interact"),
			Settings.binding_text("character_menu"),
		])
	else:
		set_objective("完成山谷训练")
		set_tutorial("先返回山谷选择职业并完成训练")


func on_scene_process(_delta: float) -> void:
	var near_chest: bool = player.global_position.distance_to(chest_position) <= 38.0
	var near_door: bool = player.global_position.distance_to(door_position) <= 34.0
	if near_chest and not Global.prologue_chest_opened:
		hud.call("show_interaction", "[%s] 打开补给宝箱" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			_open_chest()
	elif near_door:
		hud.call("show_interaction", "[%s] 返回灰杉村" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			travel_to(VILLAGE_SCENE, "blacksmith")
	else:
		hud.call("clear_interaction")


func _open_chest() -> void:
	if Global.profession.is_empty() or not Global.tutorial_weapon_skill_done:
		hud.call("show_notice", "先在山谷完成职业选择与训练")
		return
	Global.prologue_chest_opened = true
	var weapon_item := str(player.call("get_profession_weapon_item"))
	if int(Global.inventory.get(weapon_item, 0)) <= 0:
		Global.add_item(weapon_item, 1)
	if int(Global.inventory.get("recruit_armor", 0)) <= 0 and str(Global.equipment["chest"].get("id", "")).is_empty():
		Global.add_item("recruit_armor", 1)
		Global.move_item_to_equipment("chest", {"kind": "inventory_item", "item_id": "recruit_armor"})
	Global.add_item("herb", 2)
	if int(Global.inventory.get("silver_oath_sigil", 0)) <= 0:
		Global.add_item("silver_oath_sigil", 1)
	Global.ensure_hotbar_defaults()
	player.call("equip_base_armor")
	player.set_spawn_position(door_position + Vector2(0, -42))
	hud.call("show_notice", "获得见习者皮甲、2株草药与银誓徽记", 3.0)
	SaveGame.save_game("灰杉村铁匠铺")
	refresh_objective()


func on_after_revive() -> void:
	player.global_position = door_position + Vector2(0, -42)
