extends SceneTree

# 路线/回镇/存档冒烟测试。
# 运行：
#   Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/route_smoke.gd
# 测试开始前会备份 user://savegame.json，结束后恢复，不会保留测试存档。

const TOWN := "res://scenes/prologue/white_deer_town.tscn"
const GAME := "res://scenes/level/game.tscn"
const MONASTERY := "res://scenes/monastery/monastery.tscn"
const COAST := "res://scenes/coast/coast.tscn"
const GRAYFIR := "res://scenes/prologue/grayfir_village.tscn"

var G
var SG
var failures := 0
var had_save := false
var save_backup := PackedByteArray()


func _init() -> void:
	call_deferred("_run")


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS  ", message)
	else:
		failures += 1
		print("FAIL  ", message)


func _backup_save() -> void:
	if not FileAccess.file_exists(SG.PATH):
		return
	var file := FileAccess.open(SG.PATH, FileAccess.READ)
	if file == null:
		return
	had_save = true
	save_backup = file.get_buffer(file.get_length())
	file.close()


func _restore_save() -> void:
	if had_save:
		var file := FileAccess.open(SG.PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(save_backup)
			file.close()
		return
	if FileAccess.file_exists(SG.PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SG.PATH))


func _reset_transients() -> void:
	G.prologue_scene_spawn = ""
	G.prologue_travel = false
	G.town_return_pending = false
	G.pending_route_unlock = ""


func _go_scene(path: String, frames: int = 20) -> void:
	change_scene_to_file(path)
	await _wait_frames(frames)
	_check(current_scene != null and current_scene.scene_file_path == path, "进入 %s" % path.get_file())


func _player_pos() -> Vector2:
	var player := get_first_node_in_group("Player")
	return player.global_position if player != null else Vector2.INF


func _run() -> void:
	await process_frame
	G = root.get_node("Global")
	SG = root.get_node("SaveGame")
	_backup_save()

	await _go_scene(TOWN, 12)
	_check(_player_pos() == Vector2(62, 154), "白鹿镇从西侧入口出生")
	_check(current_scene.call("_route_unlocked", "west"), "西侧路线始终开放")
	_check(not current_scene.call("_route_unlocked", "north"), "未报到时北侧路线锁定")
	_check(not current_scene.call("_route_unlocked", "east"), "第一座石碑前东侧路线锁定")
	_check(not current_scene.call("_route_unlocked", "south"), "第二座石碑前南侧路线锁定")
	var town_player = get_first_node_in_group("Player")
	town_player.health = 10
	current_scene.call("_rest_at_guild")
	_check(town_player.health == town_player.max_health, "公会长椅可以恢复生命")

	G.guild_registered = true
	_check(current_scene.call("_route_unlocked", "north"), "报到后北侧路线开放")
	G.first_stele_lit = true
	current_scene.call("_go_white_birch")
	await _wait_frames(20)
	_check(current_scene.scene_file_path == GAME, "镇北 120 白桦径进入第一关")
	_check(_player_pos() == Vector2(88, -80), "第一关出生点正确")

	G.return_to_white_deer_town()
	await _wait_frames(20)
	_check(current_scene.scene_file_path == TOWN, "第一关返回白鹿镇")
	_check(_player_pos() == Vector2(360, 190), "回到公会门口")

	_reset_transients()
	await _go_scene(TOWN, 15)
	current_scene.call("_go_grayfir")
	await _wait_frames(20)
	_check(current_scene.scene_file_path == GRAYFIR, "镇西 110 灰鹿古道进入灰杉村")
	_check(_player_pos() == Vector2(620, 330), "灰杉村东侧出生")

	_reset_transients()
	G.first_stele_lit = true
	await _go_scene(TOWN, 15)
	current_scene.call("_go_monastery")
	await _wait_frames(20)
	_check(current_scene.scene_file_path == MONASTERY, "镇东 130 失誓朝圣路进入修道院")
	_check(_player_pos() == Vector2(888, 1270), "修道院入口出生")

	_reset_transients()
	G.second_stele_lit = true
	await _go_scene(TOWN, 15)
	current_scene.call("_go_coast")
	await _wait_frames(20)
	_check(current_scene.scene_file_path == COAST, "镇南 140 赤烬驿道进入海岸")
	_check(_player_pos() == Vector2(240, 1500), "海岸入口出生")

	# 裂牙格鲁姆：死亡后石碑显现，需要玩家手动点燃才会回镇
	_reset_transients()
	G.boss_defeated = false
	G.first_stele_lit = false
	await _go_scene(GAME, 20)
	var boss := current_scene.get_node("Layers/Boss")
	boss.call("_die")
	await _wait(8.5)
	_check(current_scene.scene_file_path == GAME, "格鲁姆死亡后留在岛上")
	_check(G.boss_defeated and not G.first_stele_lit, "格鲁姆死亡不会自动点亮石碑")
	var stele := current_scene.get_node_or_null("Layers/BossIsland/OathStele")
	_check(stele != null, "第一关誓火石碑存在")
	SG.load_into_global()
	_check(not G.first_stele_lit, "重载存档不会自动点亮第一关石碑")
	if stele != null:
		stele.call("_light")
		await _wait(1.6)
	_check(current_scene.scene_file_path == TOWN, "点燃石碑后回镇")
	_check(G.first_stele_lit and _player_pos() == Vector2(360, 190), "第一座石碑由玩家点燃并回到公会")

	# 罗兰：直接调用死亡处理，验证回镇和路线解锁
	_reset_transients()
	G.roland_defeated = false
	G.second_stele_lit = false
	await _go_scene(MONASTERY, 30)
	var nav_panel = current_scene.get("nav_panel")
	_check(nav_panel != null and nav_panel.visible, "修道院目标导航面板显示")
	var monk_enemy = null
	for node in get_nodes_in_group("Enemies"):
		if node.get("enemy_kind") != null:
			monk_enemy = node
			break
	_check(monk_enemy != null, "找到修道院普通怪")
	if monk_enemy != null:
		monk_enemy.call("_die")
		await _wait_frames(3)
		_check(get_nodes_in_group("Pickups").size() > 0, "修道院普通怪死亡后产生掉落")
	current_scene.call("_on_boss_died")
	await _wait(0.6)
	_check(current_scene.scene_file_path == MONASTERY, "罗兰死亡后留在修道院")
	_check(G.roland_defeated and not G.second_stele_lit, "罗兰死亡不会自动点亮第二座石碑")
	var monastery_stele = current_scene.get("stele")
	_check(monastery_stele != null, "第二关誓火石碑存在")
	SG.load_into_global()
	_check(not G.second_stele_lit, "重载存档不会自动点亮第二关石碑")
	if monastery_stele != null:
		monastery_stele.call("_light")
		await _wait(1.6)
	_check(current_scene.scene_file_path == TOWN, "点燃第二座石碑后回镇")
	_check(G.second_stele_lit, "第二座石碑由玩家点燃")

	# 斯卡：直接调用死亡处理
	_reset_transients()
	G.ska_defeated = false
	G.third_stele_lit = false
	await _go_scene(COAST, 30)
	var coast_enemy = null
	for node in get_nodes_in_group("Enemies"):
		if node.get("enemy_kind") != null:
			coast_enemy = node
			break
	_check(coast_enemy != null, "找到海岸普通怪")
	if coast_enemy != null:
		coast_enemy.call("_die")
		await _wait_frames(3)
		_check(get_nodes_in_group("Pickups").size() > 0, "海岸普通怪死亡后产生掉落")
	current_scene.call("_on_boss_died")
	await _wait(0.6)
	_check(current_scene.scene_file_path == COAST, "斯卡死亡后留在海岸")
	_check(G.ska_defeated and not G.third_stele_lit, "斯卡死亡不会自动点亮第三座石碑")
	var coast_stele = current_scene.get("stele")
	_check(coast_stele != null, "第三关誓火石碑存在")
	SG.load_into_global()
	_check(not G.third_stele_lit, "重载存档不会自动点亮第三关石碑")
	if coast_stele != null:
		coast_stele.call("_light")
		await _wait(1.6)
	_check(current_scene.scene_file_path == TOWN, "点燃第三座石碑后回镇")
	_check(G.third_stele_lit, "第三座石碑由玩家点燃")

	# 回镇存档可继续
	SG.load_into_global()
	_check(SG.pending_scene_path == TOWN, "回镇存档场景为白鹿镇")
	_check(SG.pending_player_data.get("position", []) == [360.0, 190.0], "回镇存档位置为公会门口")

	_restore_save()
	print("SMOKE RESULT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
