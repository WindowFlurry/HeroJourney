extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal training_action(action_name: String)

const WEAPON_DATA := {
	"fist": {"name": "拳头", "damage": 4, "interval": 0.28, "reach": 20.0},
	"axe": {"name": "斧头", "damage": 10, "interval": 0.60, "reach": 36.0},
	"sword": {"name": "剑", "damage": 6, "interval": 0.45, "reach": 28.0},
}
const ATTACK_UPGRADE_CAP := 8
const CAMPFIRE_HEAL_RATE := 10.0
const PROLOGUE_PROJECTILE: PackedScene = preload("res://scenes/prologue/prologue_projectile.tscn")

const PROFESSION_DATA := {
	"warrior": {
		"name": "战士",
		"position": "近战、正面承伤与击退",
		"max_health": 120,
		"defense": 3,
		"weapon": "旧铁长剑",
		"weapon_item": "warrior_weapon",
		"damage": 11,
		"reach": 34.0,
		"attack_interval": 0.42,
		"skill": "破阵冲锋",
		"skill_cooldown": 5.0,
		"weapon_skill": "横斩",
		"ranged": false,
	},
	"ranger": {
		"name": "游侠",
		"position": "中距离、机动与持续输出",
		"max_health": 95,
		"defense": 2,
		"weapon": "猎弓",
		"weapon_item": "ranger_weapon",
		"damage": 7,
		"reach": 170.0,
		"attack_interval": 0.34,
		"skill": "翻滚",
		"skill_cooldown": 4.5,
		"weapon_skill": "三连射",
		"ranged": true,
	},
	"mage": {
		"name": "法师",
		"position": "远程、爆发与位移",
		"max_health": 85,
		"defense": 1,
		"weapon": "见习法杖",
		"weapon_item": "mage_weapon",
		"damage": 9,
		"reach": 150.0,
		"attack_interval": 0.52,
		"skill": "闪现",
		"skill_cooldown": 5.0,
		"weapon_skill": "蓄力火球",
		"ranged": true,
	},
}

@export var max_health := 100
@export var invulnerable_time := 0.5
@export var pickup_radius := 40.0
@export var herb_heal_amount := 20
@export var herb_hold_time := 0.5
@export var dash_speed := 330.0
@export var dash_duration := 0.16
@export var dash_cooldown := 5.0
@export var dash_damage := 6
@export var dash_hit_radius := 16.0

@onready var move_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var tool_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/ToolStateMachine/playback")
@onready var sprite: Sprite2D = $Sprite2D
@onready var heal_aura: Sprite2D = $HealAura
@onready var heal_plus: Sprite2D = $HealPlus

var direction: Vector2
var last_direction := Vector2.DOWN
var aim_direction := Vector2.DOWN
var mouse_direction := Vector2.DOWN
var speed := 100
var health := 100
var attack_cooldown := 0.0
var invulnerable_timer := 0.0
var spawn_position: Vector2
var dead := false
var has_camp_key := false
var camp_key_granted := false
var attack_upgrades := 0
var defense := 1
var defense_cap := 5
var defense_step := 2
var defense_upgrades := 0
var armor_tier := 1
var has_axe := false
var has_sword := false
var current_weapon := "fist"
var herb_hold := 0.0
var herb_hold_used := false
var knockback_timer := 0.0
var knockback_dir := Vector2.ZERO
var knockback_speed := 260.0
var shake_time := 0.0
var shake_strength := 0.0
var hitstop_active := false
var dash_timer := 0.0
var dash_cd_timer := 0.0
var dash_dir := Vector2.ZERO
var dash_hit := {}
var dash_trail_timer := 0.0
var heavy_timer := 0.0
var heavy_struck := false
var combo_timer := 0.0
var combo_strike_timer := 0.0
var combo_hits := 0
var profession := ""
var prologue_mode := false
var input_locked := false
var weapon_skill_cd_timer := 0.0
var selected_quick_slot := 0
var base_armor_equipped := false
var mage_charge_timer := 0.0
var campfire_heal_accum := 0.0
var campfire_plus_timer := 0.0
var last_hit_from_boss := false
var holy_blessing_timer := 0.0
var holy_blessing_bonus := 0

const LOST_BAG_SCENE: PackedScene = preload("res://scenes/level/lost_bag.tscn")
const LOST_ITEM_IDS := ["gland", "shell", "slime", "herb", "vine"]


func _ready() -> void:
	health = max_health
	spawn_position = global_position
	aim_direction = last_direction
	mouse_direction = last_direction
	for node_name in ["AxeSound", "WalkSound"]:
		var snd := get_node_or_null("Sounds/" + node_name) as AudioStreamPlayer
		if snd != null:
			snd.bus = "SFX"
	health_changed.emit(health, max_health)
	Global.enemy_killed.connect(_on_enemy_killed)
	_apply_weapon_animations()
	if not SaveGame.pending_player_data.is_empty():
		apply_save_data(SaveGame.pending_player_data)
		SaveGame.pending_player_data = {}
	if profession.is_empty() and not Global.profession.is_empty():
		profession = Global.profession
		_apply_profession_weapon()


func _process(delta: float) -> void:
	if dead:
		return
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		mouse_direction = to_mouse.normalized()
		aim_direction = _cardinal(mouse_direction)
	if shake_time > 0.0:
		shake_time -= delta
		$Camera2D.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
	elif $Camera2D.offset != Vector2.ZERO:
		$Camera2D.offset = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if dead:
		return
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
	if weapon_skill_cd_timer > 0.0:
		weapon_skill_cd_timer -= delta
	if holy_blessing_timer > 0.0:
		holy_blessing_timer = maxf(0.0, holy_blessing_timer - delta)

	if input_locked:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		animation()
		return
	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity = knockback_dir * knockback_speed
		move_and_slide()
		animation()
		return
	if mage_charge_timer > 0.0:
		mage_charge_timer -= delta
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		sprite.modulate = Color(1.0, 0.5 + 0.3 * absf(sin(mage_charge_timer * 18.0)), 0.18)
		if mage_charge_timer <= 0.0:
			mage_charge_timer = 0.0
			sprite.modulate = Color.WHITE
			_fire_prologue_projectile(mouse_direction, 24, 155.0, Color(1.0, 0.48, 0.16), 8.0, true, "orb")
			_shake_screen(2.0, 0.12)
		move_and_slide()
		animation()
		return

	direction = Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		last_direction = _cardinal(direction)

	if not profession.is_empty():
		if Input.is_action_just_pressed("weapon_1"):
			select_quick_slot(0)
		if Input.is_action_just_pressed("weapon_2"):
			select_quick_slot(1)
		if Input.is_action_just_pressed("weapon_3"):
			select_quick_slot(2)
		if Input.is_action_just_pressed("weapon_4"):
			select_quick_slot(3)
	else:
		if Input.is_action_just_pressed("weapon_1"):
			switch_weapon("fist")
		if Input.is_action_just_pressed("weapon_2"):
			switch_weapon("axe")
		if Input.is_action_just_pressed("weapon_3"):
			switch_weapon("sword")

	if dash_cd_timer > 0.0:
		dash_cd_timer -= delta
	if Input.is_action_just_pressed("dash"):
		_trigger_skill()
	if not profession.is_empty() and Input.is_action_just_pressed("weapon_skill"):
		_use_selected_quick_action()
	if heavy_timer > 0.0:
		_process_heavy(delta)
		move_and_slide()
		animation()
		return
	if combo_timer > 0.0:
		_process_combo(delta)
		move_and_slide()
		animation()
		return
	if dash_timer > 0.0:
		_process_dash(delta)
		move_and_slide()
		animation()
		return

	if Input.is_action_just_pressed("action") and attack_cooldown <= 0.0:
		_attack()
	if Input.is_action_just_pressed("interact"):
		_pickup_nearby()

	if Input.is_action_pressed("use_herb"):
		herb_hold += delta
		if herb_hold >= herb_hold_time and not herb_hold_used:
			herb_hold_used = true
			_use_herb()
	else:
		herb_hold = 0.0
		herb_hold_used = false

	if direction:
		if not $Sounds/WalkSoundTimer.time_left:
			$Sounds/WalkSoundTimer.start()
	else:
		$Sounds/WalkSoundTimer.stop()

	var current_speed := (speed * 2) if Input.is_action_pressed("run") else speed
	velocity = direction * current_speed
	move_and_slide()
	animation()


func animation() -> void:
	$AnimationTree.set("parameters/MoveStateMachine/move/blend_position", aim_direction)
	$AnimationTree.set("parameters/MoveStateMachine/idle/blend_position", aim_direction)
	if direction:
		move_state_machine.travel("move")
	else:
		move_state_machine.travel("idle")


func _attack() -> void:
	if not profession.is_empty():
		_attack_as_profession()
		return
	var data: Dictionary = WEAPON_DATA[current_weapon]
	attack_cooldown = float(data["interval"])
	var reach := float(data["reach"])
	var damage := get_weapon_damage()
	var attack_dir := mouse_direction
	var visual_dir := aim_direction

	if current_weapon == "fist":
		# 无武器：用原“锄头”动画槽位承载拳头动作（14-15 帧）
		$AnimationTree.set("parameters/ToolStateMachine/hoe/blend_position", visual_dir)
		tool_state_machine.start("hoe")
		Sfx.play("punch")
	else:
		$AnimationTree.set("parameters/ToolStateMachine/axe/blend_position", visual_dir)
		tool_state_machine.start("axe")
		if current_weapon == "sword":
			Sfx.play("sword")
		else:
			$Sounds/AxeSound.play()
	$AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	var hit_any := false
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		var enemy_node := enemy as Node2D
		if enemy_node == null or enemy_node.is_queued_for_deletion():
			continue
		var hit := false
		if enemy_node.has_method("is_hit_by_attack"):
			hit = bool(enemy_node.call("is_hit_by_attack", global_position, attack_dir, reach))
		else:
			var to_enemy: Vector2 = enemy_node.global_position - global_position
			hit = to_enemy.length() <= reach and to_enemy.dot(attack_dir) > 0.0
		if hit:
			hit_any = true
			if enemy_node.has_method("take_damage_from"):
				enemy_node.call("take_damage_from", damage, global_position)
			else:
				enemy_node.call("take_damage", damage)

	if hit_any:
		Sfx.play("hit")
		_shake_screen(1.7, 0.11)
		_hit_stop(0.05)


func _attack_as_profession() -> void:
	var data: Dictionary = PROFESSION_DATA[profession]
	attack_cooldown = float(data["attack_interval"])
	_play_profession_attack_animation()
	training_action.emit("attack")
	if bool(data["ranged"]):
		var speed := 245.0 if profession == "ranger" else 185.0
		var color := Color(0.95, 0.82, 0.38) if profession == "ranger" else Color(0.55, 0.8, 1.0)
		_fire_prologue_projectile(
			mouse_direction,
			get_weapon_damage(),
			speed,
			color,
			3.0,
			false,
			"arrow" if profession == "ranger" else "orb",
		)
		return
	if _hit_enemies(float(data["reach"]), get_weapon_damage(), mouse_direction):
		Sfx.play("hit")
		_shake_screen(2.0, 0.12)
		_hit_stop(0.05)


func _play_profession_attack_animation() -> void:
	if profession == "warrior":
		$AnimationTree.set("parameters/ToolStateMachine/axe/blend_position", aim_direction)
		tool_state_machine.start("axe")
		Sfx.play("sword")
	else:
		$AnimationTree.set("parameters/ToolStateMachine/hoe/blend_position", aim_direction)
		tool_state_machine.start("hoe")
		Sfx.play("punch", 1.25)
	$AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _fire_prologue_projectile(
	direction_value: Vector2,
	damage_value: int,
	speed_value: float,
	color: Color,
	radius: float,
	explode: bool = false,
	style: String = "orb",
) -> void:
	var projectile := PROLOGUE_PROJECTILE.instantiate() as Node2D
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction_value * 12.0
	projectile.call("setup_friendly", direction_value, speed_value, damage_value, color, radius, explode, style)


func _use_selected_quick_action() -> void:
	var item_id := Global.hotbar[selected_quick_slot]
	if item_id.is_empty() or int(Global.hotbar_counts[selected_quick_slot]) <= 0:
		return
	if item_id == get_profession_weapon_item():
		_use_profession_weapon_skill()
	elif item_id == "herb":
		_use_herb(true)
	else:
		var hud := get_tree().get_first_node_in_group("HUD")
		if hud != null:
			hud.call("show_notice", "%s不能直接使用" % str(Global.ITEM_NAMES.get(item_id, item_id)))


func _use_profession_weapon_skill() -> void:
	if weapon_skill_cd_timer > 0.0 or dead or input_locked:
		return
	training_action.emit("weapon_skill")
	_play_profession_attack_animation()
	match profession:
		"warrior":
			weapon_skill_cd_timer = 4.2
			if _hit_enemies(46.0, 18, mouse_direction, 0.5):
				_shake_screen(3.0, 0.18)
				_hit_stop(0.07)
		"ranger":
			weapon_skill_cd_timer = 3.5
			for offset in [-0.16, 0.0, 0.16]:
				_fire_prologue_projectile(
					mouse_direction.rotated(offset),
					7,
					270.0,
					Color(0.95, 0.82, 0.38),
					3.0,
					false,
					"arrow",
				)
		"mage":
			weapon_skill_cd_timer = 5.0
			mage_charge_timer = 0.55
			Sfx.play("charge")
	Sfx.play("sword" if profession == "warrior" else "dash", 0.9)
	_shake_screen(1.5, 0.1)


func _on_enemy_killed() -> void:
	dash_cd_timer = 0.0


func _shake_screen(strength: float, duration: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_time = maxf(shake_time, duration)


func _hit_stop(duration: float) -> void:
	if hitstop_active:
		return
	hitstop_active = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	hitstop_active = false


func _start_dash() -> void:
	# 朝角色当前面朝的方向冲刺（面朝方向跟随鼠标），而不是移动输入方向
	dash_dir = mouse_direction
	if dash_dir == Vector2.ZERO:
		dash_dir = last_direction
	dash_timer = dash_duration
	dash_cd_timer = dash_cooldown
	dash_trail_timer = 0.0
	dash_hit.clear()
	Sfx.play("dash")


func _trigger_skill() -> void:
	if dead or dash_cd_timer > 0.0 or dash_timer > 0.0 or heavy_timer > 0.0 or combo_timer > 0.0:
		return
	if not profession.is_empty():
		match profession:
			"warrior":
				dash_damage = 15
				dash_duration = 0.2
			"ranger":
				dash_damage = 0
				dash_duration = 0.24
			"mage":
				dash_damage = 0
				dash_duration = 0.1
		_start_dash()
		dash_cd_timer = get_skill_cooldown()
		training_action.emit("skill")
		return
	match current_weapon:
		"fist":
			_start_dash()
		"axe":
			_start_heavy()
		"sword":
			_start_combo()


func get_skill_name() -> String:
	if not profession.is_empty():
		return str(PROFESSION_DATA[profession]["skill"])
	match current_weapon:
		"axe":
			return "重击"
		"sword":
			return "连击"
	return "冲刺"


func get_weapon_skill_name() -> String:
	if not profession.is_empty():
		return str(PROFESSION_DATA[profession]["weapon_skill"])
	return ""


func get_skill_cooldown() -> float:
	if not profession.is_empty():
		return float(PROFESSION_DATA[profession]["skill_cooldown"])
	return dash_cooldown if current_weapon == "fist" else 6.5


func _start_heavy() -> void:
	dash_cd_timer = get_skill_cooldown()
	heavy_timer = 0.45
	heavy_struck = false
	velocity = Vector2.ZERO
	Sfx.play("charge")


func _process_heavy(delta: float) -> void:
	heavy_timer -= delta
	velocity = Vector2.ZERO
	sprite.modulate = Color(1.0, 0.65 + 0.25 * sin((0.45 - heavy_timer) * 18.0), 0.3)
	if heavy_timer <= 0.0:
		heavy_timer = 0.0
		sprite.modulate = Color.WHITE
		if not heavy_struck:
			heavy_struck = true
			_heavy_strike()


func _heavy_strike() -> void:
	move_and_collide(mouse_direction * 10.0)
	var data: Dictionary = WEAPON_DATA["axe"]
	var reach := float(data["reach"]) + 6.0
	var damage := maxi(1, int(round(get_weapon_damage() * 1.3)))
	_play_tool_attack()
	$Sounds/AxeSound.play()
	if _hit_enemies(reach, damage, mouse_direction, 0.5):
		Sfx.play("hit")
		_shake_screen(3.5, 0.2)
		_hit_stop(0.09)


func _start_combo() -> void:
	dash_cd_timer = get_skill_cooldown()
	combo_timer = 0.78
	combo_strike_timer = 0.0
	combo_hits = 0
	velocity = Vector2.ZERO


func _process_combo(delta: float) -> void:
	combo_timer -= delta
	combo_strike_timer -= delta
	velocity = Vector2.ZERO
	if combo_strike_timer <= 0.0 and combo_hits < 3:
		combo_strike_timer = 0.22
		combo_hits += 1
		_combo_strike(combo_hits)
	if combo_timer <= 0.0:
		combo_timer = 0.0


func _combo_strike(index: int) -> void:
	move_and_collide(mouse_direction * 5.0)
	var data: Dictionary = WEAPON_DATA["sword"]
	var reach := float(data["reach"]) + (4.0 if index == 3 else 0.0)
	var mult := 1.0 if index == 3 else 0.7
	var damage := maxi(1, int(round(get_weapon_damage() * mult)))
	_play_tool_attack()
	Sfx.play("sword")
	if _hit_enemies(reach, damage, mouse_direction):
		_shake_screen(1.6, 0.08)
		_hit_stop(0.04)


func _play_tool_attack() -> void:
	$AnimationTree.set("parameters/ToolStateMachine/axe/blend_position", aim_direction)
	tool_state_machine.start("axe")
	$AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _hit_enemies(reach: float, damage: int, dir: Vector2, stagger: float = 0.0) -> bool:
	var hit_any := false
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		var enemy_node := enemy as Node2D
		if enemy_node == null or enemy_node.is_queued_for_deletion():
			continue
		var hit := false
		var multiplier := 1.0
		if enemy_node.has_method("get_hit_info"):
			var info = enemy_node.call("get_hit_info", global_position, dir, reach)
			hit = bool(info.get("hit", false))
			multiplier = float(info.get("multiplier", 1.0))
		elif enemy_node.has_method("is_hit_by_attack"):
			hit = bool(enemy_node.call("is_hit_by_attack", global_position, dir, reach))
		else:
			var to_enemy: Vector2 = enemy_node.global_position - global_position
			hit = to_enemy.length() <= reach and to_enemy.dot(dir) > 0.0
		if hit:
			hit_any = true
			var final_damage := maxi(1, int(round(float(damage) * multiplier)))
			if enemy_node.has_method("take_damage_from"):
				enemy_node.call("take_damage_from", final_damage, global_position)
			else:
				enemy_node.call("take_damage", final_damage)
			if stagger > 0.0 and enemy_node.has_method("apply_stagger"):
				enemy_node.call("apply_stagger", stagger)
	return hit_any


func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = dash_dir * dash_speed
	dash_trail_timer -= delta
	if dash_trail_timer <= 0.0:
		dash_trail_timer = 0.035
		_spawn_dash_ghost()
	_dash_damage()
	if dash_timer <= 0.0:
		velocity = Vector2.ZERO


func _dash_damage() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		var enemy_node := enemy as Node2D
		if enemy_node == null or enemy_node.is_queued_for_deletion():
			continue
		var id := enemy_node.get_instance_id()
		if dash_hit.has(id):
			continue
		var hit_center := enemy_node.global_position
		if enemy_node.is_in_group("TrainingDummies"):
			hit_center += Vector2(0, -16)
		else:
			hit_center += Vector2(0, -11)
		if hit_center.distance_to(global_position) > dash_hit_radius + 3.0:
			continue
		dash_hit[id] = true
		if enemy_node.has_method("take_damage_from"):
			enemy_node.call("take_damage_from", dash_damage, global_position)
		else:
			enemy_node.call("take_damage", dash_damage)
		if profession == "warrior" and enemy_node.has_method("apply_stagger"):
			enemy_node.call("apply_stagger", 0.45)


func _spawn_dash_ghost() -> void:
	var ghost := $Sprite2D.duplicate() as Sprite2D
	if ghost == null:
		return
	ghost.modulate = Color(0.55, 0.8, 1.0, 0.45)
	ghost.z_index = $Sprite2D.z_index - 1
	get_parent().add_child(ghost)
	ghost.global_position = $Sprite2D.global_position
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)


func take_damage(amount: int, from_boss: bool = false) -> void:
	if dead or invulnerable_timer > 0.0 or dash_timer > 0.0 or _in_safe_zone():
		return
	last_hit_from_boss = from_boss
	var reduced := maxi(amount - defense, 1)
	health = maxi(health - reduced, 0)
	health_changed.emit(health, max_health)
	invulnerable_timer = invulnerable_time
	_flash_damage()
	Sfx.play("hurt")
	_shake_screen(2.2, 0.16)
	Global.spawn_float_text(global_position + Vector2(0, -30), "-%d  防%d" % [reduced, defense], Color(0.62, 0.82, 1.0), 8, 16.0, 0.6)
	if health <= 0:
		_die()


func _die() -> void:
	dead = true
	mage_charge_timer = 0.0
	velocity = Vector2.ZERO
	shake_time = 0.0
	shake_strength = 0.0
	$Camera2D.offset = Vector2.ZERO
	# 被 Boss 击败不掉落素材；序章与普通怪战斗仍按原规则处理
	if not last_hit_from_boss and not prologue_mode:
		_drop_lost_items()
	died.emit()


func _drop_lost_items() -> void:
	var lost := {}
	for id in LOST_ITEM_IDS:
		var count := int(Global.inventory.get(id, 0))
		var amount := int(count / 3.0)
		if amount > 0:
			lost[id] = amount
	if lost.is_empty():
		return
	Global.remove_items(lost)
	var bag := LOST_BAG_SCENE.instantiate()
	if bag == null:
		return
	get_parent().add_child(bag)
	bag.global_position = global_position
	bag.call("setup", lost)


func set_spawn_position(pos: Vector2) -> void:
	spawn_position = pos


func give_camp_key() -> void:
	has_camp_key = true
	camp_key_granted = true


func consume_camp_key() -> void:
	has_camp_key = false


func upgrade_attack() -> bool:
	if attack_upgrades >= ATTACK_UPGRADE_CAP:
		return false
	attack_upgrades += 1
	return true


func upgrade_defense() -> bool:
	if defense >= defense_cap:
		return false
	defense = mini(defense + defense_step, defense_cap)
	defense_upgrades += 1
	return true


func equip_axe() -> bool:
	if has_axe:
		return false
	has_axe = true
	switch_weapon("axe")
	return true


func equip_sword() -> bool:
	if has_sword:
		return false
	has_sword = true
	switch_weapon("sword")
	return true


func has_weapon(weapon: String) -> bool:
	match weapon:
		"fist":
			return true
		"axe":
			return has_axe
		"sword":
			return has_sword
	return false


func switch_weapon(weapon: String) -> bool:
	if heavy_timer > 0.0 or combo_timer > 0.0 or dash_timer > 0.0:
		return false
	if not WEAPON_DATA.has(weapon):
		return false
	if not has_weapon(weapon):
		var hud := get_tree().get_first_node_in_group("HUD")
		if hud != null:
			hud.call("show_notice", "还没有%s" % WEAPON_DATA[weapon]["name"])
		return false
	current_weapon = weapon
	_apply_weapon_animations()
	var hud := get_tree().get_first_node_in_group("HUD")
	if hud != null:
		hud.call("_refresh_weapon_bar")
		hud.call("_refresh_stats")
	return true


func setup_profession(id: String, apply_stats: bool = true) -> bool:
	if not PROFESSION_DATA.has(id):
		return false
	profession = id
	mage_charge_timer = 0.0
	Global.profession = id
	var data: Dictionary = PROFESSION_DATA[id]
	if apply_stats:
		max_health = int(data["max_health"])
		health = max_health
		defense = int(data["defense"])
		if base_armor_equipped:
			defense += 1
	current_weapon = "sword" if id == "warrior" else "axe"
	has_sword = id == "warrior"
	has_axe = id != "warrior"
	_apply_weapon_animations()
	health_changed.emit(health, max_health)
	return true


func _apply_profession_weapon() -> void:
	current_weapon = "sword" if profession == "warrior" else "axe"
	has_sword = profession == "warrior"
	has_axe = profession != "warrior"
	_apply_weapon_animations()


func get_profession_name() -> String:
	if profession.is_empty() or not PROFESSION_DATA.has(profession):
		return "见习冒险者"
	return str(PROFESSION_DATA[profession]["name"])


func get_profession_weapon_item() -> String:
	if profession.is_empty() or not PROFESSION_DATA.has(profession):
		return ""
	return str(PROFESSION_DATA[profession]["weapon_item"])


func equip_base_armor() -> void:
	if base_armor_equipped:
		return
	base_armor_equipped = true
	defense += 1


func select_quick_slot(index: int) -> void:
	selected_quick_slot = clampi(index, 0, Global.HOTBAR_SIZE - 1)
	var hud := get_tree().get_first_node_in_group("HUD")
	if hud != null and hud.has_method("refresh_quick_slots"):
		hud.call("refresh_quick_slots")


func cycle_quick_slot(direction_value: int) -> void:
	if profession.is_empty() or input_locked:
		return
	selected_quick_slot = posmod(selected_quick_slot + direction_value, Global.HOTBAR_SIZE)
	var hud := get_tree().get_first_node_in_group("HUD")
	if hud != null and hud.has_method("refresh_quick_slots"):
		hud.call("refresh_quick_slots")


func _unhandled_input(event: InputEvent) -> void:
	if profession.is_empty() or input_locked or not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed:
		return
	if mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
		cycle_quick_slot(-1)
		get_viewport().set_input_as_handled()
	elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		cycle_quick_slot(1)
		get_viewport().set_input_as_handled()


func get_weapon_damage() -> int:
	var bonus := holy_blessing_bonus if holy_blessing_timer > 0.0 else 0
	if not profession.is_empty():
		# 主岛的“攻击 +10%”合成升级同样作用于职业武器
		var base := float(PROFESSION_DATA[profession]["damage"])
		return maxi(1, int(round(base * (1.0 + attack_upgrades * 0.1))) + bonus)
	return maxi(1, get_weapon_damage_for_upgrades(attack_upgrades) + bonus)


func apply_holy_blessing(duration: float = 60.0, bonus: int = 3) -> void:
	holy_blessing_timer = maxf(holy_blessing_timer, duration)
	holy_blessing_bonus = maxi(holy_blessing_bonus, bonus)


func get_weapon_damage_for_upgrades(upgrades: int) -> int:
	var base := float(WEAPON_DATA[current_weapon]["damage"])
	var raw := base * (1.0 + upgrades * 0.1)
	if current_weapon == "fist":
		return maxi(1, int(ceil(raw)))
	return maxi(1, int(round(raw)))


func get_weapon_base_damage() -> int:
	if not profession.is_empty():
		return int(PROFESSION_DATA[profession]["damage"])
	return int(WEAPON_DATA[current_weapon]["damage"])


func get_weapon_name() -> String:
	if not profession.is_empty():
		return str(PROFESSION_DATA[profession]["weapon"])
	return str(WEAPON_DATA[current_weapon]["name"])


func get_attack_upgrade_cap() -> int:
	return ATTACK_UPGRADE_CAP


func _apply_weapon_animations() -> void:
	var root := $AnimationTree.tree_root as AnimationNodeBlendTree
	if root == null:
		return
	var sm := root.get_node("ToolStateMachine") as AnimationNodeStateMachine
	if sm == null:
		return
	var bs := sm.get_node("axe") as AnimationNodeBlendSpace2D
	if bs == null:
		return
	var suffix := "sword" if current_weapon == "sword" else "axe"
	var names := [
		"%s_left" % suffix, "%s_down" % suffix, "%s_up" % suffix,
		"%s_left" % suffix, "%s_left" % suffix,
		"%s_right" % suffix, "%s_right" % suffix, "%s_right" % suffix,
	]
	for i in names.size():
		var node := bs.get_blend_point_node(i) as AnimationNodeAnimation
		if node != null:
			node.animation = StringName(names[i])


func equip_tier2_armor() -> bool:
	if armor_tier >= 2:
		return false
	armor_tier = 2
	defense_cap = 9
	defense = maxi(defense, 7)
	defense_upgrades = maxi(defense_upgrades, 2)
	return true


func _pickup_nearby() -> void:
	var hud := get_tree().get_first_node_in_group("HUD")
	for node in get_tree().get_nodes_in_group("Pickups"):
		var item := node as Node2D
		if item == null or item.global_position.distance_to(global_position) > pickup_radius:
			continue
		var item_id = item.get("item_id")
		if item_id != null and Global.is_item_full(str(item_id)):
			if hud != null:
				hud.call("show_notice", "%s已满（%d/%d）" % [Global.ITEM_NAMES.get(str(item_id), "道具"), int(Global.inventory.get(str(item_id), 0)), Global.item_cap(str(item_id))])
			continue
		item.call("collect")


func campfire_heal(delta: float) -> void:
	if dead:
		return
	if health >= max_health:
		campfire_heal_accum = 0.0
		return
	campfire_heal_accum += delta * CAMPFIRE_HEAL_RATE
	var amount := int(campfire_heal_accum)
	if amount > 0:
		campfire_heal_accum -= float(amount)
		health = mini(health + amount, max_health)
		health_changed.emit(health, max_health)
	campfire_plus_timer -= delta
	if campfire_plus_timer <= 0.0:
		campfire_plus_timer = 0.6
		_spawn_campfire_plus()


func campfire_heal_stop() -> void:
	campfire_heal_accum = 0.0
	campfire_plus_timer = 0.0


func _spawn_campfire_plus() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var plus := Sprite2D.new()
	plus.texture = heal_plus.texture
	plus.modulate = Color(0.45, 1.0, 0.55, 1.0)
	plus.z_index = 3
	get_parent().add_child(plus)
	plus.global_position = global_position + Vector2(randf_range(-6.0, 6.0), -16.0)
	var t := plus.create_tween()
	t.set_parallel(true)
	t.tween_property(plus, "position:y", plus.position.y - 18.0, 0.7)
	t.tween_property(plus, "modulate:a", 0.0, 0.7)
	t.chain().tween_callback(plus.queue_free)


func _use_herb(from_hotbar: bool = false) -> void:
	if dead or health >= max_health:
		return
	if from_hotbar:
		if not Global.consume_hotbar_item(selected_quick_slot, 1):
			return
	else:
		if int(Global.inventory.get("herb", 0)) <= 0:
			return
		Global.remove_items({"herb": 1})
	var healed := mini(health + herb_heal_amount, max_health) - health
	health = mini(health + herb_heal_amount, max_health)
	health_changed.emit(health, max_health)
	Global.spawn_float_text(global_position + Vector2(0, -30), "+%d" % healed, Color(0.5, 1.0, 0.6), 9, 16.0, 0.6)
	Sfx.play("heal")
	_show_heal_effect()


func _show_heal_effect() -> void:
	heal_aura.visible = true
	heal_plus.visible = true
	heal_aura.modulate = Color(0.35, 1.0, 0.45, 0.9)
	heal_aura.scale = Vector2(1.8, 1.8)
	heal_plus.modulate = Color(0.55, 1.0, 0.55, 1.0)
	heal_plus.position = Vector2(0, -26)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(heal_aura, "modulate:a", 0.0, 0.8)
	tween.tween_property(heal_aura, "scale", Vector2(2.6, 2.6), 0.8)
	tween.tween_property(heal_plus, "position:y", -40.0, 0.8)
	tween.tween_property(heal_plus, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(_hide_heal_effect)


func _hide_heal_effect() -> void:
	heal_aura.visible = false
	heal_plus.visible = false


func revive_at_camp() -> void:
	health = max_health
	mage_charge_timer = 0.0
	last_hit_from_boss = false
	global_position = spawn_position
	velocity = Vector2.ZERO
	input_locked = false
	invulnerable_timer = invulnerable_time
	dead = false
	health_changed.emit(health, max_health)
	if not prologue_mode:
		SaveGame.save_game("营地")


func set_input_locked(locked: bool) -> void:
	input_locked = locked
	if locked:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO


func apply_knockback(dir: Vector2, force_speed: float = 260.0, duration: float = 0.28) -> void:
	if dead or input_locked or dash_timer > 0.0 or dir == Vector2.ZERO:
		return
	knockback_dir = dir.normalized()
	knockback_speed = force_speed
	knockback_timer = duration


func get_save_data() -> Dictionary:
	return {
		"position": [spawn_position.x, spawn_position.y],
		"health": health,
		"max_health": max_health,
		"has_axe": has_axe,
		"has_sword": has_sword,
		"current_weapon": current_weapon,
		"attack_upgrades": attack_upgrades,
		"defense": defense,
		"defense_upgrades": defense_upgrades,
		"armor_tier": armor_tier,
		"has_camp_key": has_camp_key,
		"camp_key_granted": camp_key_granted,
		"profession": profession,
		"base_armor_equipped": base_armor_equipped,
		"selected_quick_slot": selected_quick_slot,
	}


func apply_save_data(data: Dictionary) -> void:
	var pos = data.get("position", [spawn_position.x, spawn_position.y])
	spawn_position = Vector2(float(pos[0]), float(pos[1]))
	global_position = spawn_position
	max_health = int(data.get("max_health", max_health))
	health = clampi(int(data.get("health", max_health)), 1, max_health)
	has_axe = bool(data.get("has_axe", false))
	has_sword = bool(data.get("has_sword", false))
	current_weapon = str(data.get("current_weapon", "fist"))
	attack_upgrades = int(data.get("attack_upgrades", 0))
	defense = int(data.get("defense", 1))
	defense_upgrades = int(data.get("defense_upgrades", 0))
	armor_tier = int(data.get("armor_tier", 1))
	has_camp_key = bool(data.get("has_camp_key", false))
	camp_key_granted = bool(data.get("camp_key_granted", false))
	profession = str(data.get("profession", Global.profession))
	base_armor_equipped = bool(data.get("base_armor_equipped", false))
	selected_quick_slot = clampi(int(data.get("selected_quick_slot", 0)), 0, Global.HOTBAR_SIZE - 1)
	defense_cap = 9 if armor_tier >= 2 else 5
	if not profession.is_empty() and PROFESSION_DATA.has(profession):
		_apply_profession_weapon()
	if not has_weapon(current_weapon):
		current_weapon = "fist"
	_apply_weapon_animations()
	health_changed.emit(health, max_health)


func _heal_to_full() -> void:
	if dead:
		return
	health = max_health
	health_changed.emit(health, max_health)


func debug_set_health(value: int) -> void:
	if dead:
		return
	health = clampi(value, 1, max_health)
	health_changed.emit(health, max_health)


func heal_by(amount: int) -> void:
	if dead or amount <= 0:
		return
	var before := health
	health = mini(health + amount, max_health)
	var healed := health - before
	if healed <= 0:
		return
	health_changed.emit(health, max_health)
	Global.spawn_float_text(global_position + Vector2(0, -30), "+%d" % healed, Color(0.5, 1.0, 0.6), 9, 16.0, 0.6)
	Sfx.play("heal")
	_show_heal_effect()


func _flash_damage() -> void:
	sprite.modulate = Color(1.0, 0.35, 0.35)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _in_safe_zone() -> bool:
	for zone in get_tree().get_nodes_in_group("SafeZones"):
		if zone.has_method("contains_point") and bool(zone.call("contains_point", global_position)):
			return true
	return false


func _cardinal(v: Vector2) -> Vector2:
	if v == Vector2.ZERO:
		return last_direction
	if absf(v.x) > absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, signf(v.y))


func _on_walk_sound_timer_timeout() -> void:
	$Sounds/WalkSound.play()
