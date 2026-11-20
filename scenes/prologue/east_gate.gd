extends "res://scenes/prologue/prologue_scene_base.gd"

const ENEMY_SCENE: PackedScene = preload("res://scenes/prologue/prologue_enemy.tscn")
const DOOR: Texture2D = preload("res://graphics/camp/gate_closed.png")
const VILLAGE_SCENE := "res://scenes/prologue/grayfir_village.tscn"
const TOWN_SCENE := "res://scenes/prologue/white_deer_town.tscn"

var gate_position := Vector2(735, 180)
var return_position := Vector2(55, 180)
var arena_rect := Rect2(410, 65, 320, 225)
var generation := 0
var current_wave := ""
var wave_remaining := 0
var dialog_context := ""
var gate_body: StaticBody2D


func on_scene_ready() -> void:
	build_gate_area()
	resolve_spawn(Vector2(105, 180))
	player.set_spawn_position(Vector2(105, 180))
	hud.dialog_finished.connect(_on_dialog_finished)
	if Global.riftwing_defeated:
		open_gate()
		set_objective("前往白鹿镇")
		set_tutorial("沿东侧道路离开灰杉村")
	elif Global.village_attack_started:
		resume_assault()
	else:
		refresh_ready_objective()
		if can_start_assault():
			start_assault()


func _draw() -> void:
	draw_rect(Rect2(-100, -80, 1000, 520), Color(0.11, 0.19, 0.13))


func build_gate_area() -> void:
	add_tile_area(Rect2(0, 0, 800, 370), GRASS, [Vector2i(1, 1)], 2, 81)
	add_tile_area(Rect2(0, 145, 800, 70), SOIL, [Vector2i(1, 1)], 2, 82)
	add_tile_area(Rect2(405, 60, 335, 240), SOIL, [Vector2i(1, 1)], 2, 83)
	add_blocker(Rect2(0, 0, 800, 18))
	add_blocker(Rect2(0, 355, 800, 15))
	add_blocker(Rect2(0, 18, 18, 337))
	add_blocker(Rect2(782, 18, 18, 337))
	gate_body = add_blocker(Rect2(725, 80, 20, 210))
	add_sprite(DOOR, gate_position, 1.9)
	add_sprite(DOOR, return_position, 1.4)
	for pos in [
		Vector2(40, 65), Vector2(105, 45), Vector2(185, 42), Vector2(265, 38),
		Vector2(350, 42), Vector2(435, 35), Vector2(520, 42), Vector2(610, 46),
		Vector2(700, 55), Vector2(760, 95), Vector2(760, 300),
		Vector2(40, 310), Vector2(140, 330), Vector2(230, 340),
	]:
		add_tree(pos, 1.2, int(pos.x) % 2 == 0)
	add_world_label("灰杉村东门", Vector2(646, 55), 12, Color(1.0, 0.8, 0.45))
	add_world_label("返回村庄", return_position + Vector2(-32, -35), 6, Color(0.86, 0.77, 0.6))


func can_start_assault() -> bool:
	return (
		Global.gareth_talked
		and not Global.profession.is_empty()
		and Global.tutorial_weapon_skill_done
		and Global.prologue_chest_opened
	)


func refresh_ready_objective() -> void:
	if can_start_assault():
		set_objective("前往东门")
		set_tutorial("检查东门，准备迎击龙类")
	elif not Global.gareth_talked:
		set_objective("返回村庄，拜访加雷斯")
		set_tutorial("尚未获得出征许可")
	elif Global.profession.is_empty():
		set_objective("返回山谷选择职业")
		set_tutorial("先在山谷完成职业选择")
	elif not Global.tutorial_weapon_skill_done:
		set_objective("返回山谷完成训练")
		set_tutorial("尚未完成全部职业训练")
	else:
		set_objective("返回铁匠铺领取补给")
		set_tutorial("补给尚未领取")


func start_assault() -> void:
	if Global.village_attack_started or not can_start_assault():
		return
	Global.village_attack_started = true
	generation += 1
	var active_generation := generation
	player.call("set_input_locked", true)
	hud.call("set_attack_tint", true)
	hud.call("show_banner", "灰杉村遇袭", "赤色龙焰照亮了东门", 1.7)
	Sfx.play("danger", 0.7, 0.0)
	set_objective("击退第一波翼蜥")
	set_tutorial("观察红橙色预警，使用职业技能躲避")
	await get_tree().create_timer(1.7).timeout
	if active_generation != generation or transitioning:
		return
	player.call("set_input_locked", false)
	spawn_wave_one(active_generation)


func resume_assault() -> void:
	generation += 1
	var active_generation := generation
	hud.call("set_attack_tint", true)
	if not Global.wave1_cleared:
		spawn_wave_one(active_generation)
	elif not Global.wave2_cleared:
		spawn_wave_two(active_generation)
	else:
		spawn_boss(active_generation)


func spawn_wave_one(active_generation: int) -> void:
	current_wave = "wave1"
	wave_remaining = 3
	spawn_enemy("melee", Vector2(520, 115), active_generation)
	spawn_enemy("melee", Vector2(585, 247), active_generation)
	spawn_enemy("ranged", Vector2(625, 145), active_generation)
	set_objective("击退第一波翼蜥")
	set_tutorial("观察红橙色预警，使用职业技能躲避")


func spawn_wave_two(active_generation: int) -> void:
	current_wave = "wave2"
	wave_remaining = 3
	spawn_enemy("melee", Vector2(505, 95), active_generation)
	spawn_enemy("melee", Vector2(640, 260), active_generation)
	spawn_enemy("elite", Vector2(655, 155), active_generation)
	set_objective("击退第二波翼蜥与精英")
	set_tutorial("精英翼蜥攻击前摇更长，注意闪避")


func spawn_boss(active_generation: int) -> void:
	current_wave = "boss"
	var boss := ENEMY_SCENE.instantiate() as Node2D
	boss.call("configure", "boss")
	boss.set("arena_rect", arena_rect)
	boss.position = Vector2(650, 180)
	boss.add_to_group("PrologueCombatant")
	boss.connect("boss_health_changed", _on_boss_health_changed)
	boss.connect("died", _on_boss_died.bind(active_generation))
	objects.add_child(boss)
	hud.call("show_boss", "裂翼兽", int(boss.get("max_health")))
	hud.call("show_banner", "裂翼兽", "受赤冠之龙气息影响的幼年龙兽", 1.8)
	Sfx.play("danger", 0.55, 0.0)
	set_objective("击败裂翼兽")
	set_tutorial("冲撞、龙息弹与振翼都有明确预警")


func spawn_enemy(kind: String, pos: Vector2, active_generation: int) -> void:
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	enemy.call("configure", kind)
	enemy.set("arena_rect", arena_rect)
	enemy.position = pos
	enemy.add_to_group("PrologueCombatant")
	enemy.connect("died", _on_wave_enemy_died.bind(active_generation))
	objects.add_child(enemy)


func _on_wave_enemy_died(active_generation: int) -> void:
	if active_generation != generation or transitioning:
		return
	wave_remaining = maxi(wave_remaining - 1, 0)
	if wave_remaining > 0:
		return
	if current_wave == "wave1":
		Global.wave1_cleared = true
		current_wave = "transition"
		await get_tree().create_timer(0.9).timeout
		if active_generation == generation and not Global.riftwing_defeated:
			spawn_wave_two(active_generation)
	elif current_wave == "wave2":
		Global.wave2_cleared = true
		current_wave = "transition"
		await get_tree().create_timer(1.1).timeout
		if active_generation == generation and not Global.riftwing_defeated:
			spawn_boss(active_generation)


func _on_boss_health_changed(current: int, maximum: int) -> void:
	hud.call("update_boss", current, maximum)


func _on_boss_died(active_generation: int) -> void:
	if active_generation != generation:
		return
	Global.riftwing_defeated = true
	player.call("set_input_locked", true)
	if int(Global.inventory.get("silver_oath_sigil", 0)) <= 0:
		Global.add_item("silver_oath_sigil", 1)
	if int(Global.inventory.get("white_deer_letter", 0)) <= 0:
		Global.add_item("white_deer_letter", 1)
	Global.add_item("potion", 1)
	hud.call("hide_boss")
	hud.call("show_banner", "赤冠的爪牙倒下了", "远方传来自龙骨山的龙吼", 2.3)
	Sfx.play("danger", 0.42, 0.0)
	open_gate()
	SaveGame.save_game("灰杉村东门")
	set_objective("前往白鹿镇")
	set_tutorial("沿东侧道路离开灰杉村")
	await get_tree().create_timer(2.8).timeout
	if transitioning:
		return
	dialog_context = "victory"
	hud.call("show_dialog", "加雷斯爵士", "那不是普通野兽。它只是赤冠之龙的眼睛和爪牙。去白鹿镇找冒险者公会。告诉他们，银誓的封印已经破了。")


func open_gate() -> void:
	if gate_body != null:
		for child in gate_body.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)


func _on_dialog_finished() -> void:
	if dialog_context == "victory":
		dialog_context = ""
		player.call("set_input_locked", false)


func on_scene_process(_delta: float) -> void:
	if Global.riftwing_defeated and player.global_position.x >= 755.0:
		travel_to(TOWN_SCENE)
		return
	if not Global.village_attack_started and player.global_position.distance_to(return_position) <= 42.0:
		hud.call("show_interaction", "[%s] 返回灰杉村" % Settings.binding_text("interact"))
		if Input.is_action_just_pressed("interact"):
			travel_to(VILLAGE_SCENE, "east_gate")
	else:
		hud.call("clear_interaction")


func _clear_combatants() -> void:
	for node in get_tree().get_nodes_in_group("PrologueCombatant"):
		if is_instance_valid(node):
			node.queue_free()


func on_after_revive() -> void:
	generation += 1
	_clear_combatants()
	hud.call("hide_boss")
	player.global_position = Vector2(105, 180)
	if Global.village_attack_started and not Global.riftwing_defeated:
		var active_generation := generation
		if not Global.wave1_cleared:
			spawn_wave_one(active_generation)
		elif not Global.wave2_cleared:
			spawn_wave_two(active_generation)
		else:
			spawn_boss(active_generation)
	else:
		refresh_ready_objective()

