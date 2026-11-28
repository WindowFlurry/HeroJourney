extends SceneTree

# 第三关灯塔铜镜 / 潮汐通道冒烟测试。
# 运行：
#   Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/coast_mirror.gd

const COAST := "res://scenes/coast/coast.tscn"

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

	G.coast_lens_found = true
	G.coast_lighthouse_lit = true
	G.coast_tide_key = true
	G.coast_tide_guardian_defeated = true
	G.coast_mirror_cliff_guard = false
	G.coast_mirror_cave_guard = false
	G.coast_mirror_wreck_guard = false
	G.coast_mirror_cliff = false
	G.coast_mirror_cave = false
	G.coast_mirror_wreck = false
	G.coast_beam_aligned = false
	G.ska_defeated = false
	G.third_stele_lit = false

	change_scene_to_file(COAST)
	await _wait_frames(35)
	_check(current_scene != null and current_scene.scene_file_path == COAST, "进入赤烬海岸")
	var mirrors: Dictionary = current_scene.get("mirrors")
	_check(mirrors.size() == 3, "海岸生成三面铜镜")
	_check(not bool(current_scene.get("tide_gate_open")), "铜镜未校准时潮门关闭")
	_check(current_scene.get("cave_tide_blocker") != null, "海蚀洞潮汐挡板存在")

	var player = get_first_node_in_group("Player")
	player.set("invulnerable_timer", 999.0)
	G.coast_mirror_cliff_guard = true
	G.coast_mirror_cave_guard = true
	G.coast_mirror_wreck_guard = true
	for id in ["cliff", "cave", "wreck"]:
		for i in 4:
			current_scene.call("_rotate_mirror", id)
	await _wait_frames(3)
	_check(G.coast_mirror_cliff and G.coast_mirror_cave and G.coast_mirror_wreck, "三面铜镜分别对准标记")
	_check(G.coast_beam_aligned, "三面铜镜完成后光束贯通")
	_check(bool(current_scene.get("tide_gate_open")), "光束与钥匙齐备后潮门打开")

	current_scene.set("tide_state", "high")
	current_scene.call("_refresh_tide_passages")
	await _wait_frames(2)
	var cave_shape: CollisionShape2D = current_scene.get("cave_tide_blocker")
	_check(not cave_shape.disabled, "涨潮时海蚀洞入口封闭")
	current_scene.set("tide_state", "low")
	current_scene.call("_refresh_tide_passages")
	await _wait_frames(2)
	_check(cave_shape.disabled, "低潮时海蚀洞入口开放")

	_restore_save()
	print("COAST RESULT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
