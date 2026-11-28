extends Node

enum Seeds {CORN, TOMATO, PUMPKIN}

signal inventory_changed
signal enemy_killed

const ITEM_NAMES := {
	"gland": "龙兽鳞片",
	"shell": "岩甲碎片",
	"slime": "灼热灰烬",
	"herb": "草药",
	"vine": "焦枯藤蔓",
	"material": "建材",
	"mask": "灰烬护符",
	"warrior_weapon": "旧铁长剑",
	"ranger_weapon": "猎弓",
	"mage_weapon": "见习法杖",
	"recruit_armor": "见习者皮甲",
	"silver_oath_sigil": "银誓徽记",
	"white_deer_letter": "白鹿镇推荐信",
}

# 有携带上限的道具
const ITEM_CAPS := {
	"herb": 5,
}
const HOTBAR_SIZE := 4
const WHITE_DEER_TOWN_SCENE := "res://scenes/prologue/white_deer_town.tscn"
const WHITE_DEER_GUILD_RETURN := Vector2(360, 190)
const EQUIPMENT_SLOTS := ["helmet", "chest", "pants", "shoes"]

var inventory := {
	"gland": 0,
	"shell": 0,
	"slime": 0,
	"herb": 0,
	"vine": 0,
	"material": 0,
	"mask": 0,
	"warrior_weapon": 0,
	"ranger_weapon": 0,
	"mage_weapon": 0,
	"recruit_armor": 0,
	"silver_oath_sigil": 0,
	"white_deer_letter": 0,
}
var hotbar: Array[String] = ["", "", "", ""]
var hotbar_counts: Array[int] = [0, 0, 0, 0]
var equipment := {
	"helmet": {"id": "", "count": 0},
	"chest": {"id": "", "count": 0},
	"pants": {"id": "", "count": 0},
	"shoes": {"id": "", "count": 0},
}

var bridge_repaired := false
var bridge_repair_stage := 0
var bridge_tracking_done := false
var bridge_crate_west := false
var bridge_crate_east := false
var material_crafted := false
var mask_crafted := false
var mask_equipped := false
var camp_gate_open := false
var boss_defeated := false

# 《赤冠之龙》序章状态。旧剧情字段继续保留，只用于兼容旧玩法模块。
var prologue_started := false
var prologue_completed := false
var gareth_talked := false
var profession := ""
var profession_reselects := 0
var tutorial_attack_done := false
var tutorial_skill_done := false
var tutorial_weapon_skill_done := false
var prologue_chest_opened := false
var village_attack_started := false
var wave1_cleared := false
var wave2_cleared := false
var east_gate_cleared := false
var prologue_scene_spawn := ""
var prologue_travel := false
var guild_registered := false
var first_stele_lit := false
var roland_defeated := false
var second_stele_lit := false
var monastery_chest_opened := false
var monastery_chapel_open := false
var monastery_right_seal := false
var monastery_bell_solved := false
var monastery_candles_lit := 0
var coast_lens_found := false
var coast_falcon_defeated := false
var coast_tide_guardian_defeated := false
var coast_tide_key := false
var coast_lighthouse_guards_defeated := false
var coast_lighthouse_lit := false
var coast_mirror_cliff_guard := false
var coast_mirror_cave_guard := false
var coast_mirror_wreck_guard := false
var coast_mirror_cliff := false
var coast_mirror_cave := false
var coast_mirror_wreck := false
var coast_beam_aligned := false
var coast_chest_opened := false
var coast_vault_opened := false
var ska_defeated := false
var third_stele_lit := false
var town_return_pending := false
var pending_route_unlock := ""


func _ready() -> void:
	_disable_ime()
	_show_mouse()


func quit_game() -> void:
	# 先停掉正在播放的音频，释放环境音节点，等两帧再退出，避免音频资源在退出时残留。
	for node in get_tree().get_nodes_in_group("Ambience"):
		node.queue_free()
	for node in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		var p := node as AudioStreamPlayer
		if p != null and p.playing:
			p.stop()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


func return_to_white_deer_town() -> void:
	if town_return_pending:
		return
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == WHITE_DEER_TOWN_SCENE:
		return
	var player := get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	town_return_pending = true
	var test_jump := get_tree().root.get_node_or_null("TestJump")
	if test_jump != null and bool(test_jump.get("is_open")):
		test_jump.call("close_menu")
	var data: Dictionary = player.call("get_save_data")
	data["position"] = [WHITE_DEER_GUILD_RETURN.x, WHITE_DEER_GUILD_RETURN.y]
	SaveGame.pending_player_data = data
	prologue_scene_spawn = "guild"
	prologue_travel = true
	prologue_completed = true
	if player.has_method("set_input_locked"):
		player.call("set_input_locked", true)
	get_tree().paused = false
	get_tree().change_scene_to_file(WHITE_DEER_TOWN_SCENE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_disable_ime()
		_show_mouse()


func _show_mouse() -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _disable_ime() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# 游戏不需要输入法，关闭它避免中文输入法吞掉 Esc 等按键
	DisplayServer.window_set_ime_active(false)


func item_cap(id: String) -> int:
	return int(ITEM_CAPS.get(id, 999999))


func is_item_full(id: String) -> bool:
	return int(inventory.get(id, 0)) >= item_cap(id)


func add_item(id: String, amount: int = 1, ignore_cap: bool = false) -> void:
	var target := int(inventory.get(id, 0)) + amount
	if not ignore_cap:
		target = mini(target, item_cap(id))
	inventory[id] = target
	inventory_changed.emit()


func spawn_damage_number(pos: Vector2, amount: int, color: Color = Color(0, 0, 0, 0)) -> void:
	var size := 9
	var col := color
	if color.a <= 0.0:
		if amount >= 11:
			size = 12
			col = Color(1.0, 0.52, 0.22)
		elif amount >= 8:
			size = 10
			col = Color(1.0, 0.84, 0.3)
		elif amount >= 6:
			size = 9
			col = Color(1.0, 0.95, 0.7)
		else:
			size = 8
			col = Color(0.92, 0.92, 0.88)
	spawn_float_text(pos, str(amount), col, size, 14.0, 0.55)


func spawn_float_text(pos: Vector2, text: String, color: Color, size: int = 9, rise: float = 14.0, duration: float = 0.55) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var root := get_tree().current_scene
	if root == null:
		return
	var label := Label.new()
	label.text = text
	label.z_index = 30
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.03, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(52.0, 14.0)
	label.position = pos + Vector2(-26.0, -20.0)
	root.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - rise, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(label.queue_free)


func has_items(req: Dictionary) -> bool:
	for id in req:
		if int(inventory.get(id, 0)) < int(req[id]):
			return false
	return true


func remove_items(req: Dictionary) -> void:
	for id in req:
		inventory[id] = maxi(int(inventory.get(id, 0)) - int(req[id]), 0)
	inventory_changed.emit()


func move_item_to_hotbar(target: int, drag_data: Dictionary) -> void:
	if target < 0 or target >= HOTBAR_SIZE:
		return
	match str(drag_data.get("kind", "")):
		"inventory_item":
			var item_id := str(drag_data.get("item_id", ""))
			if int(inventory.get(item_id, 0)) <= 0:
				return
			_take_inventory_item(item_id)
			if hotbar[target] != item_id:
				_return_slot_item(hotbar[target], hotbar_counts[target])
				hotbar[target] = item_id
				hotbar_counts[target] = 1
			else:
				hotbar_counts[target] += 1
		"hotbar_item":
			var source := int(drag_data.get("slot_index", -1))
			if source < 0 or source >= HOTBAR_SIZE or source == target:
				return
			var source_id := hotbar[source]
			var source_count := hotbar_counts[source]
			hotbar[source] = hotbar[target]
			hotbar_counts[source] = hotbar_counts[target]
			hotbar[target] = source_id
			hotbar_counts[target] = source_count
		"equipment_item":
			var source_slot := str(drag_data.get("slot", ""))
			if not equipment.has(source_slot):
				return
			var source_data: Dictionary = equipment[source_slot]
			var source_id := str(source_data.get("id", ""))
			if source_id.is_empty():
				return
			_return_slot_item(hotbar[target], hotbar_counts[target])
			hotbar[target] = source_id
			hotbar_counts[target] = 1
			_clear_equipment(source_slot, false)
	inventory_changed.emit()


func clear_hotbar_slot(index: int) -> void:
	if index < 0 or index >= HOTBAR_SIZE:
		return
	_return_slot_item(hotbar[index], hotbar_counts[index])
	hotbar[index] = ""
	hotbar_counts[index] = 0
	inventory_changed.emit()


func move_item_to_equipment(target_slot: String, drag_data: Dictionary) -> void:
	if not equipment.has(target_slot):
		return
	var item_id := str(drag_data.get("item_id", ""))
	if not can_equip(target_slot, item_id):
		return
	var source_kind := str(drag_data.get("kind", ""))
	if source_kind == "inventory_item":
		if int(inventory.get(item_id, 0)) <= 0:
			return
		_take_inventory_item(item_id)
	elif source_kind == "hotbar_item":
		var source := int(drag_data.get("slot_index", -1))
		if source < 0 or source >= HOTBAR_SIZE or hotbar[source] != item_id or hotbar_counts[source] <= 0:
			return
		hotbar_counts[source] -= 1
		if hotbar_counts[source] <= 0:
			hotbar[source] = ""
	elif source_kind == "equipment_item":
		var source_slot := str(drag_data.get("slot", ""))
		if not equipment.has(source_slot) or source_slot == target_slot or str(equipment[source_slot].get("id", "")) != item_id:
			return
		_clear_equipment(source_slot, false)
	else:
		return
	_clear_equipment(target_slot, true)
	equipment[target_slot] = {"id": item_id, "count": 1}
	inventory_changed.emit()


func clear_equipment_slot(slot: String) -> void:
	if not equipment.has(slot):
		return
	_clear_equipment(slot, true)
	inventory_changed.emit()


func consume_hotbar_item(index: int, amount: int = 1) -> bool:
	if index < 0 or index >= HOTBAR_SIZE or hotbar_counts[index] < amount:
		return false
	hotbar_counts[index] -= amount
	if hotbar_counts[index] <= 0:
		hotbar[index] = ""
		hotbar_counts[index] = 0
	inventory_changed.emit()
	return true


func can_equip(slot: String, item_id: String) -> bool:
	match slot:
		"chest":
			return item_id == "recruit_armor" or item_id.contains("armor")
		"helmet":
			return item_id.contains("helmet")
		"pants":
			return item_id.contains("pants")
		"shoes":
			return item_id.contains("shoes")
	return false


func ensure_hotbar_defaults(fill_empty: bool = true) -> void:
	var defaults := [
		{
			"warrior": "warrior_weapon",
			"ranger": "ranger_weapon",
			"mage": "mage_weapon",
		}.get(profession, ""),
		"recruit_armor",
		"herb",
		"silver_oath_sigil",
	]
	if fill_empty:
		for i in HOTBAR_SIZE:
			var default_id := str(defaults[i])
			if hotbar[i].is_empty() and int(inventory.get(default_id, 0)) > 0:
				_take_inventory_item(default_id)
				hotbar[i] = str(defaults[i])
				hotbar_counts[i] = 1
	for i in HOTBAR_SIZE:
		if hotbar_counts[i] <= 0:
			hotbar[i] = ""
			hotbar_counts[i] = 0


func ensure_equipment_defaults() -> void:
	if str(equipment["chest"].get("id", "")).is_empty() and int(inventory.get("recruit_armor", 0)) > 0:
		_take_inventory_item("recruit_armor")
		equipment["chest"] = {"id": "recruit_armor", "count": 1}


func _take_inventory_item(item_id: String) -> void:
	inventory[item_id] = maxi(int(inventory.get(item_id, 0)) - 1, 0)


func _return_slot_item(item_id: String, count: int) -> void:
	if not item_id.is_empty() and count > 0:
		inventory[item_id] = int(inventory.get(item_id, 0)) + count


func _clear_equipment(slot: String, return_to_inventory: bool) -> void:
	var data: Dictionary = equipment.get(slot, {})
	if return_to_inventory:
		_return_slot_item(str(data.get("id", "")), int(data.get("count", 0)))
	equipment[slot] = {"id": "", "count": 0}


func apply_save_data(data: Dictionary) -> void:
	var saved_inventory = data.get("inventory", {})
	if saved_inventory is Dictionary:
		for id in inventory:
			inventory[id] = int(saved_inventory.get(id, 0))
		# 旧存档中的药水统一折算为草药
		var legacy_potions := int(saved_inventory.get("potion", 0))
		if legacy_potions > 0:
			inventory["herb"] = mini(inventory["herb"] + legacy_potions, item_cap("herb"))
	var flags = data.get("flags", {})
	if flags is Dictionary:
		bridge_repaired = bool(flags.get("bridge_repaired", false))
		bridge_repair_stage = int(flags.get("bridge_repair_stage", 3 if bridge_repaired else 0))
		bridge_tracking_done = bool(flags.get("bridge_tracking_done", false))
		bridge_crate_west = bool(flags.get("bridge_crate_west", false))
		bridge_crate_east = bool(flags.get("bridge_crate_east", false))
		if bridge_repaired:
			bridge_repair_stage = 3
		elif bridge_repair_stage >= 3:
			bridge_repaired = true
		material_crafted = bool(flags.get("material_crafted", false))
		mask_crafted = bool(flags.get("mask_crafted", false))
		mask_equipped = bool(flags.get("mask_equipped", false))
		camp_gate_open = bool(flags.get("camp_gate_open", false))
		boss_defeated = bool(flags.get("boss_defeated", false))
		prologue_started = bool(flags.get("prologue_started", false))
		prologue_completed = bool(flags.get("prologue_completed", false))
		gareth_talked = bool(flags.get("gareth_talked", false))
		profession = str(flags.get("profession", ""))
		profession_reselects = int(flags.get("profession_reselects", 0))
		tutorial_attack_done = bool(flags.get("tutorial_attack_done", false))
		tutorial_skill_done = bool(flags.get("tutorial_skill_done", false))
		tutorial_weapon_skill_done = bool(flags.get("tutorial_weapon_skill_done", false))
		prologue_chest_opened = bool(flags.get("prologue_chest_opened", false))
		village_attack_started = bool(flags.get("village_attack_started", false))
		wave1_cleared = bool(flags.get("wave1_cleared", false))
		wave2_cleared = bool(flags.get("wave2_cleared", false))
		east_gate_cleared = bool(flags.get("east_gate_cleared", flags.get("riftwing_defeated", false)))
		guild_registered = bool(flags.get("guild_registered", false))
		first_stele_lit = bool(flags.get("first_stele_lit", false))
		roland_defeated = bool(flags.get("roland_defeated", false))
		second_stele_lit = bool(flags.get("second_stele_lit", false))
		monastery_chest_opened = bool(flags.get("monastery_chest_opened", false))
		monastery_chapel_open = bool(flags.get("monastery_chapel_open", false))
		monastery_right_seal = bool(flags.get("monastery_right_seal", false))
		monastery_bell_solved = bool(flags.get("monastery_bell_solved", false))
		monastery_candles_lit = int(flags.get("monastery_candles_lit", 0))
		coast_lens_found = bool(flags.get("coast_lens_found", false))
		coast_falcon_defeated = bool(flags.get("coast_falcon_defeated", false))
		coast_tide_guardian_defeated = bool(flags.get("coast_tide_guardian_defeated", false))
		coast_tide_key = bool(flags.get("coast_tide_key", false))
		coast_lighthouse_guards_defeated = bool(flags.get("coast_lighthouse_guards_defeated", false))
		coast_lighthouse_lit = bool(flags.get("coast_lighthouse_lit", false))
		coast_mirror_cliff_guard = bool(flags.get("coast_mirror_cliff_guard", false))
		coast_mirror_cave_guard = bool(flags.get("coast_mirror_cave_guard", false))
		coast_mirror_wreck_guard = bool(flags.get("coast_mirror_wreck_guard", false))
		coast_mirror_cliff = bool(flags.get("coast_mirror_cliff", false))
		coast_mirror_cave = bool(flags.get("coast_mirror_cave", false))
		coast_mirror_wreck = bool(flags.get("coast_mirror_wreck", false))
		coast_beam_aligned = bool(flags.get("coast_beam_aligned", false))
		coast_chest_opened = bool(flags.get("coast_chest_opened", false))
		coast_vault_opened = bool(flags.get("coast_vault_opened", false))
		ska_defeated = bool(flags.get("ska_defeated", false))
		third_stele_lit = bool(flags.get("third_stele_lit", false))
		# 兼容旧存档：旧版没有 bridge_repair_stage 字段，Boss 击败即视为点碑。
		# 新流程必须由玩家手动点燃第一关石碑，不能因为 Boss 已死就自动点亮。
		if boss_defeated and not flags.has("bridge_repair_stage"):
			first_stele_lit = true
		# 兼容旧存档：旧版没有 monastery_bell_solved 字段。
		# 新流程第二关石碑必须由玩家手动点燃。
		if roland_defeated and not flags.has("monastery_bell_solved"):
			second_stele_lit = true
		# 兼容旧存档：旧版没有 coast_beam_aligned 字段；新流程第三关石碑要玩家手动点燃。
		if ska_defeated and not flags.has("coast_beam_aligned"):
			third_stele_lit = true
	var saved_hotbar = data.get("hotbar", [])
	hotbar = ["", "", "", ""]
	hotbar_counts = [0, 0, 0, 0]
	var has_saved_hotbar := false
	if saved_hotbar is Array:
		has_saved_hotbar = saved_hotbar.size() > 0
	if has_saved_hotbar:
		for i in mini(saved_hotbar.size(), HOTBAR_SIZE):
			hotbar[i] = str(saved_hotbar[i])
			if hotbar[i] == "potion":
				hotbar[i] = "herb"
		var saved_counts = data.get("hotbar_counts", [])
		if saved_counts is Array and not saved_counts.is_empty():
			for i in mini(saved_counts.size(), HOTBAR_SIZE):
				hotbar_counts[i] = int(saved_counts[i])
		else:
			for i in HOTBAR_SIZE:
				if not hotbar[i].is_empty() and int(inventory.get(hotbar[i], 0)) > 0:
					_take_inventory_item(hotbar[i])
					hotbar_counts[i] = 1
	ensure_hotbar_defaults(not has_saved_hotbar)
	equipment = {
		"helmet": {"id": "", "count": 0},
		"chest": {"id": "", "count": 0},
		"pants": {"id": "", "count": 0},
		"shoes": {"id": "", "count": 0},
	}
	var saved_equipment = data.get("equipment", {})
	if saved_equipment is Dictionary and not saved_equipment.is_empty():
		for slot in EQUIPMENT_SLOTS:
			var saved_slot = saved_equipment.get(slot, {})
			if saved_slot is Dictionary:
				equipment[slot] = {
					"id": str(saved_slot.get("id", "")),
					"count": int(saved_slot.get("count", 0)),
				}
	else:
		ensure_equipment_defaults()
	inventory_changed.emit()


func reset_state() -> void:
	for id in inventory:
		inventory[id] = 0
	for i in HOTBAR_SIZE:
		hotbar[i] = ""
		hotbar_counts[i] = 0
	for slot in EQUIPMENT_SLOTS:
		equipment[slot] = {"id": "", "count": 0}
	bridge_repaired = false
	bridge_repair_stage = 0
	bridge_tracking_done = false
	bridge_crate_west = false
	bridge_crate_east = false
	material_crafted = false
	mask_crafted = false
	mask_equipped = false
	camp_gate_open = false
	boss_defeated = false
	prologue_started = false
	prologue_completed = false
	gareth_talked = false
	profession = ""
	profession_reselects = 0
	tutorial_attack_done = false
	tutorial_skill_done = false
	tutorial_weapon_skill_done = false
	prologue_chest_opened = false
	village_attack_started = false
	wave1_cleared = false
	wave2_cleared = false
	east_gate_cleared = false
	guild_registered = false
	first_stele_lit = false
	roland_defeated = false
	second_stele_lit = false
	monastery_chest_opened = false
	monastery_chapel_open = false
	monastery_right_seal = false
	monastery_bell_solved = false
	monastery_candles_lit = 0
	coast_lens_found = false
	coast_falcon_defeated = false
	coast_tide_guardian_defeated = false
	coast_tide_key = false
	coast_lighthouse_guards_defeated = false
	coast_lighthouse_lit = false
	coast_mirror_cliff_guard = false
	coast_mirror_cave_guard = false
	coast_mirror_wreck_guard = false
	coast_mirror_cliff = false
	coast_mirror_cave = false
	coast_mirror_wreck = false
	coast_beam_aligned = false
	coast_chest_opened = false
	coast_vault_opened = false
	ska_defeated = false
	third_stele_lit = false
	prologue_scene_spawn = ""
	prologue_travel = false
	town_return_pending = false
	pending_route_unlock = ""
	inventory_changed.emit()

func find_reachable_position(pos: Vector2, max_radius: float = 32.0) -> Vector2:
	var space := get_tree().root.world_2d.direct_space_state
	if _is_position_walkable(space, pos):
		return pos
	for ring in range(1, 5):
		var radius := max_radius * float(ring) / 4.0
		for i in 8:
			var angle := TAU * float(i) / 8.0 + float(ring) * 0.31
			var candidate := pos + Vector2(cos(angle), sin(angle)) * radius
			if _is_position_walkable(space, candidate):
				return candidate
	return Vector2(INF, INF)


func _is_position_walkable(space: PhysicsDirectSpaceState2D, pos: Vector2) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	return space.intersect_point(params, 1).is_empty()
