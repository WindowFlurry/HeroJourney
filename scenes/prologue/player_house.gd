extends "res://scenes/prologue/prologue_scene_base.gd"

const TABLE: Texture2D = preload("res://graphics/camp/diary_table.png")
const LOG: Texture2D = preload("res://graphics/camp/camp_log.png")
const DOOR: Texture2D = preload("res://graphics/camp/gate_closed.png")
const VILLAGE_SCENE := "res://scenes/prologue/grayfir_village.tscn"

var door_position := Vector2(330, 318)


func on_scene_ready() -> void:
	build_house()
	resolve_spawn(door_position + Vector2(0, -42))
	player.set_spawn_position(door_position + Vector2(0, -42))
	set_objective("离开住宅，前往加雷斯的屋子")
	set_tutorial("[%s] 靠近门并离开住宅" % Settings.binding_text("interact"))


func build_house() -> void:
	add_tile_area(Rect2(48, 55, 480, 250), WOOD_FLOOR, [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	], 2, 5)
	add_blocker(Rect2(0, 0, 576, 55))
	add_blocker(Rect2(0, 305, 576, 45))
	add_blocker(Rect2(0, 55, 48, 250))
	add_blocker(Rect2(528, 55, 48, 250))
	add_sprite(TABLE, Vector2(145, 125), 1.7)
	add_sprite(LOG, Vector2(430, 125), 1.6)
	add_sprite(DOOR, door_position, 1.7)
	add_person(Vector2(235, 205), Color(1.0, 0.93, 0.78))
	add_world_label("玩家住宅", Vector2(220, 34), 11, Color(1.0, 0.84, 0.5))
	add_world_label("床铺", Vector2(110, 159), 7, Color(0.78, 0.68, 0.51))
	add_world_label("储物桌", Vector2(397, 159), 7, Color(0.78, 0.68, 0.51))


func on_scene_process(_delta: float) -> void:
	if player.global_position.distance_to(door_position) <= 34.0:
		hud.call("show_interaction", "[%s] 离开住宅" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			travel_to(VILLAGE_SCENE, "player_house")
	else:
		hud.call("clear_interaction")


func on_after_revive() -> void:
	player.global_position = door_position + Vector2(0, -42)

