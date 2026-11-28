extends SceneTree

# 第二关钟楼谜题 / 35 秒守钟冒烟测试。
# 运行：
#   Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/monastery_bell.gd

const MONASTERY := "res://scenes/monastery/monastery.tscn"

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


func _run() -> void:
	await process_frame
	G = root.get_node("Global")
	SG = root.get_node("SaveGame")
	_backup_save()

	G.monastery_chest_opened = false
	G.monastery_chapel_open = false
	G.monastery_right_seal = false
	G.monastery_bell_solved = false
	G.monastery_candles_lit = 0
	G.roland_defeated = false
	G.second_stele_lit = false

	change_scene_to_file(MONASTERY)
	await _wait_frames(30)
	_check(current_scene != null and current_scene.scene_file_path == MONASTERY, "进入修道院")
	var scene = current_scene
	var bells: Array = scene.get("bell_nodes")
	_check(bells.size() == 3, "钟楼有三座铜钟")
	_check(not bool(scene.get("bell_puzzle_solved")), "钟楼谜题初始未解")
	_check(scene.get("bell_panel") != null, "守钟倒计时面板存在")

	scene.call("_ring_bell", 0)
	await _wait_frames(2)
	_check(int(scene.get("bell_progress")) == 0, "敲错钟声会重置顺序")
	_check(get_nodes_in_group("BellDefenseEnemies").size() > 0, "敲错钟声会引来守墓人")
	scene.call("_clear_bell_enemies")
	await _wait_frames(2)

	scene.call("_ring_bell", 1)
	scene.call("_ring_bell", 0)
	scene.call("_ring_bell", 2)
	await _wait_frames(2)
	_check(bool(scene.get("bell_puzzle_solved")), "按中→左→右解开钟序")
	_check(bool(scene.get("bell_defense_active")), "钟序完成后进入 35 秒守钟")
	_check(G.monastery_bell_solved, "钟序进度写入存档标记")
	_check(scene.get("bell_panel").visible, "守钟面板显示")

	var player = get_first_node_in_group("Player")
	player.set("invulnerable_timer", 999.0)
	player.global_position = Vector2(1440, 650)
	scene.set_process(false)
	scene.call("on_scene_process", 1.0)
	await _wait_frames(3)
	_check(get_nodes_in_group("BellWindowClimbers").size() > 0, "塔窗会有怪爬进来")
	for i in 35:
		player.global_position = Vector2(1440, 650)
		scene.call("on_scene_process", 1.0)
	await _wait_frames(3)
	_check(G.monastery_right_seal, "守钟 35 秒后解除钟楼封印")
	_check(not bool(scene.get("bell_defense_active")), "守钟结束后关闭事件")
	_check(not scene.get("bell_panel").visible, "守钟面板隐藏")
	_check(get_nodes_in_group("BellDefenseEnemies").size() == 0, "守钟成功后清理守墓人")

	_restore_save()
	print("BELL RESULT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
