extends Node

# 单存档：只保留上一次游戏的进度。新游戏会覆盖旧存档。

const PATH := "user://savegame.json"
const CURRENT_VERSION := 2

var pending_player_data: Dictionary = {}
var pending_scene_path := ""


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func get_save_info() -> Dictionary:
	var data := _read_save()
	if data.is_empty():
		return {}
	return {
		"version": int(data.get("version", 1)),
		"location": str(data.get("location", "未知")),
		"timestamp": str(data.get("timestamp", "")),
		"scene": str(data.get("scene", "")),
	}


func is_outdated() -> bool:
	var data := _read_save()
	return not data.is_empty() and int(data.get("version", 1)) < CURRENT_VERSION


func save_game(location: String) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	var scene_path := ""
	if get_tree().current_scene != null:
		scene_path = get_tree().current_scene.scene_file_path
	var data := {
		"version": CURRENT_VERSION,
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"location": location,
		"scene": scene_path,
		"player": player.call("get_save_data"),
		"inventory": Global.inventory.duplicate(),
		"hotbar": Global.hotbar.duplicate(),
		"hotbar_counts": Global.hotbar_counts.duplicate(),
		"equipment": Global.equipment.duplicate(true),
		"flags": {
			"bridge_repaired": Global.bridge_repaired,
			"bridge_repair_stage": Global.bridge_repair_stage,
			"bridge_tracking_done": Global.bridge_tracking_done,
			"bridge_crate_west": Global.bridge_crate_west,
			"bridge_crate_east": Global.bridge_crate_east,
			"material_crafted": Global.material_crafted,
			"mask_crafted": Global.mask_crafted,
			"mask_equipped": Global.mask_equipped,
			"camp_gate_open": Global.camp_gate_open,
			"boss_defeated": Global.boss_defeated,
			"prologue_started": Global.prologue_started,
			"prologue_completed": Global.prologue_completed,
			"gareth_talked": Global.gareth_talked,
			"profession": Global.profession,
			"profession_reselects": Global.profession_reselects,
			"tutorial_attack_done": Global.tutorial_attack_done,
			"tutorial_skill_done": Global.tutorial_skill_done,
			"tutorial_weapon_skill_done": Global.tutorial_weapon_skill_done,
			"prologue_chest_opened": Global.prologue_chest_opened,
			"village_attack_started": Global.village_attack_started,
			"wave1_cleared": Global.wave1_cleared,
			"wave2_cleared": Global.wave2_cleared,
			"east_gate_cleared": Global.east_gate_cleared,
			"guild_registered": Global.guild_registered,
			"first_stele_lit": Global.first_stele_lit,
			"roland_defeated": Global.roland_defeated,
			"second_stele_lit": Global.second_stele_lit,
			"monastery_chest_opened": Global.monastery_chest_opened,
			"monastery_chapel_open": Global.monastery_chapel_open,
			"monastery_right_seal": Global.monastery_right_seal,
			"monastery_bell_solved": Global.monastery_bell_solved,
			"monastery_candles_lit": Global.monastery_candles_lit,
			"coast_lens_found": Global.coast_lens_found,
			"coast_falcon_defeated": Global.coast_falcon_defeated,
			"coast_tide_guardian_defeated": Global.coast_tide_guardian_defeated,
			"coast_tide_key": Global.coast_tide_key,
			"coast_lighthouse_guards_defeated": Global.coast_lighthouse_guards_defeated,
			"coast_lighthouse_lit": Global.coast_lighthouse_lit,
			"coast_mirror_cliff_guard": Global.coast_mirror_cliff_guard,
			"coast_mirror_cave_guard": Global.coast_mirror_cave_guard,
			"coast_mirror_wreck_guard": Global.coast_mirror_wreck_guard,
			"coast_mirror_cliff": Global.coast_mirror_cliff,
			"coast_mirror_cave": Global.coast_mirror_cave,
			"coast_mirror_wreck": Global.coast_mirror_wreck,
			"coast_beam_aligned": Global.coast_beam_aligned,
			"coast_chest_opened": Global.coast_chest_opened,
			"coast_vault_opened": Global.coast_vault_opened,
			"ska_defeated": Global.ska_defeated,
			"third_stele_lit": Global.third_stele_lit,
		},
	}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()


func delete_save() -> void:
	pending_player_data = {}
	pending_scene_path = ""
	if not FileAccess.file_exists(PATH):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func load_into_global() -> bool:
	var data := _read_save()
	if data.is_empty():
		return false
	if int(data.get("version", 1)) < CURRENT_VERSION:
		return false
	Global.apply_save_data(data)
	Global.prologue_travel = false
	Global.prologue_scene_spawn = ""
	Global.town_return_pending = false
	Global.pending_route_unlock = ""
	pending_player_data = data.get("player", {})
	pending_scene_path = str(data.get("scene", "res://scenes/prologue/grayfir_village.tscn"))
	if pending_scene_path.is_empty() or not ResourceLoader.exists(pending_scene_path):
		pending_scene_path = "res://scenes/prologue/grayfir_village.tscn"
	return true


func _read_save() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}
