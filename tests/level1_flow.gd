extends SceneTree

# 第一关“抢修 + 追踪”冒烟测试。
# 运行：
#   Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/level1_flow.gd

const GAME := "res://scenes/level/game.tscn"

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

	G.bridge_repaired = false
	G.bridge_repair_stage = 0
	G.bridge_tracking_done = false
	G.bridge_crate_west = false
	G.bridge_crate_east = false
	G.material_crafted = false
	G.mask_crafted = false
	G.mask_equipped = false
	G.boss_defeated = false
	G.first_stele_lit = false
	G.inventory["material"] = 0

	change_scene_to_file(GAME)
	await _wait_frames(40)
	_check(current_scene != null and current_scene.scene_file_path == GAME, "进入第一关")

	var caches: Array = []
	for node in get_nodes_in_group("Pickups"):
		var flag := str(node.get("flag_name"))
		if flag == "bridge_crate_west" or flag == "bridge_crate_east":
			caches.append(node)
	_check(caches.size() == 2, "第一关生成两处明面建材补给")
	_check(current_scene.get_node_or_null("Objects/TrackingQuest") != null, "第一关生成血迹追踪")
	_check(current_scene.get_node_or_null("Layers/EastLand") != null, "东侧林地扩展已生成")
	var east_reach: Vector2 = G.find_reachable_position(Vector2(1100, 900), 8.0)
	_check(east_reach == Vector2(1100, 900), "东侧扩展区域可以行走")
	var second_camp_safe := false
	for zone in get_nodes_in_group("SafeZones"):
		if str(zone.get("location_name")) == "前哨营地":
			second_camp_safe = true
	_check(second_camp_safe, "前哨营地安全区存在")

	if caches.size() > 0:
		caches[0].call("collect")
		await _wait_frames(2)
	_check(int(G.inventory.get("material", 0)) >= 1, "拾取补给获得建材")
	_check(G.bridge_crate_west or G.bridge_crate_east, "补给拾取状态写入存档标记")

	var player = get_first_node_in_group("Player")
	player.set("invulnerable_timer", 999.0)
	var bridge = current_scene.get_node("Layers/BrokenBridge")
	_check(int(bridge.get("repair_stage")) == 0, "木桥初始为第 0/3 段")

	player.global_position = Vector2(400, 1134)
	await _wait_frames(10)
	_check(bool(bridge.get("near_repair")), "走进木桥抢修范围")
	Input.action_press("interact")
	await _wait_frames(3)
	_check(bool(bridge.get("channeling")), "实际按住交互开始读条")
	Input.action_release("interact")
	await _wait_frames(3)
	_check(not bool(bridge.get("channeling")), "松开交互中断读条")

	await create_timer(3.2).timeout
	_check(get_nodes_in_group("BridgeEventEnemies").size() > 0, "桥边会持续刷新额外怪物")
	player.global_position = Vector2(88, -80)
	await create_timer(1.5).timeout
	_check(get_nodes_in_group("BridgeEventEnemies").size() == 0, "离开桥的范围后额外怪物消失")
	player.global_position = Vector2(400, 1134)
	await _wait_frames(6)
	for enemy in get_nodes_in_group("Enemies"):
		if enemy.get("enemy_type") != null:
			enemy.call("take_damage", 9999)

	G.inventory["material"] = 3
	bridge.set("near_repair", true)
	Input.action_press("interact")
	bridge.call("_start_channel")
	await _wait_frames(2)
	_check(bool(bridge.get("channeling")), "按住交互进入抢修读条")
	bridge.call("_update_channel", 9.2)
	await _wait_frames(2)
	_check(int(G.bridge_repair_stage) == 1, "完成一段读条后进度变为 1/3")
	_check(int(G.inventory.get("material", 0)) == 2, "每段抢修消耗一份建材")
	for i in 2:
		bridge.call("_start_channel")
		await _wait_frames(2)
		bridge.call("_update_channel", 9.2)
		await _wait_frames(2)
	Input.action_release("interact")
	_check(G.bridge_repaired, "三段抢修完成后木桥修复")
	_check(int(G.bridge_repair_stage) == 3, "抢修进度保存为 3/3")
	_check(bool(bridge.get("repaired")), "木桥视觉切换为修复状态")
	var blocker: CollisionShape2D = bridge.get_node("Blocker/CollisionShape2D")
	_check(blocker.disabled, "修复后木桥碰撞体解除")

	var hud = get_first_node_in_group("HUD")
	hud.call("show_channel", 0.5, "测试读条")
	_check(hud.get("channel_root") != null and hud.get("channel_root").visible, "HUD 读条显示")
	hud.call("hide_channel")
	_check(not hud.get("channel_root").visible, "HUD 读条隐藏")

	var quest = current_scene.get_node_or_null("Objects/TrackingQuest")
	_check(quest != null, "血迹追踪节点存在")
	if quest != null:
		var points: Array = quest.get("points")
		for point in points:
			player.global_position = point
			await _wait_frames(2)
			quest.call("_confirm_trace")
			await _wait_frames(1)
		_check(int(quest.get("step")) == points.size(), "走完整条血迹路线")
		_check(hud.banner_label.text == "血迹的来历", "血迹终点有说明性文字")
		var cache = quest.get("cache")
		var cache_pos := Vector2.ZERO
		if cache != null and is_instance_valid(cache):
			cache_pos = cache.global_position
			player.global_position = cache_pos
			await _wait_frames(3)
			cache.call("collect")
			await _wait_frames(3)
			await create_timer(1.3).timeout
			var guards := get_nodes_in_group("TrackingGuards")
			_check(guards.size() >= 4, "追踪终点守卫会从远处赶来")
			var far_enough := true
			for guard in guards:
				var guard_node := guard as Node2D
				if guard_node != null and guard_node.global_position.distance_to(cache_pos) < 160.0:
					far_enough = false
			_check(far_enough, "追踪守卫不在玩家脸上刷新")
		_check(G.bridge_tracking_done, "追踪终点拿到第三份建材")

	var boss = current_scene.get_node("Layers/Boss")
	var curtain_blocker = current_scene.get_node("Layers/ArenaCurtain/Blocker")
	_check(curtain_blocker.collision_layer == 1, "Boss雾墙会实际阻挡玩家")
	boss.set("active", true)
	player.global_position = Vector2(520, 1299)
	_check(bool(boss.call("_player_on_island")), "Boss激活后贴近雾墙不误判离场")
	player.global_position = Vector2(520, 1270)
	_check(not bool(boss.call("_player_on_island")), "越过雾墙才判定离开")
	player.global_position = Vector2(520, 1400)
	boss.set("health", int(boss.max_health * 0.73))
	boss.call("take_damage", 5)
	await _wait_frames(4)
	var summons_one := get_nodes_in_group("BossSummons")
	_check(summons_one.size() >= 3, "格鲁姆第一次掷出灰烬幼兽")
	_check(int(boss.get("summon_count")) == 1, "投掷技能第一次触发")
	boss.set("health", int(boss.max_health * 0.47))
	boss.call("take_damage", 5)
	await _wait_frames(4)
	var summons := get_nodes_in_group("BossSummons")
	_check(summons.size() >= 6, "格鲁姆可以多次掷出灰烬幼兽")
	_check(int(boss.get("summon_count")) == 2, "投掷技能可以重复触发")
	if summons.size() > 0:
		_check(float(summons[0].get("move_speed")) >= 150.0, "灰烬幼兽速度明显快于普通怪")
	await create_timer(1.15).timeout
	var landed := 0
	for cub in summons:
		var cub_node := cub as Node2D
		if cub_node != null and cub_node.process_mode == Node.PROCESS_MODE_INHERIT and cub_node.global_position.distance_to(player.global_position) < 220.0:
			landed += 1
	_check(landed >= 6, "多只灰烬幼兽被掷到玩家身边并开始追击")
	var before_pickups := get_nodes_in_group("Pickups").size()
	var killed := false
	for cub in summons:
		var cub_node := cub as Node2D
		if not killed and cub_node != null and cub_node.process_mode == Node.PROCESS_MODE_INHERIT:
			cub_node.call("take_damage", 999)
			killed = true
	await _wait_frames(3)
	if killed:
		_check(get_nodes_in_group("Pickups").size() == before_pickups, "灰烬幼兽被击杀后不掉落道具")

	SG.load_into_global()
	_check(G.bridge_repaired and int(G.bridge_repair_stage) == 3, "重新读档保留木桥修复进度")

	_restore_save()
	print("LEVEL1 RESULT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
