extends Node2D

# 第一关支线：沿血迹追踪受伤的灰烬兽，找到伐木队藏起来的第三份建材。

const PICKUP_SCENE: PackedScene = preload("res://scenes/level/pickup_item.tscn")
const MATERIAL_ICON: Texture2D = preload("res://graphics/items/material.png")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/enemy.tscn")

const TRAIL_POINTS: Array[Vector2] = [
	Vector2(620, 700),
	Vector2(720, 720),
	Vector2(820, 745),
	Vector2(920, 770),
	Vector2(1020, 800),
	Vector2(1110, 840),
	Vector2(1170, 910),
	Vector2(1180, 1000),
	Vector2(1180, 1080),
]
const TRACE_TEXTS: Array[String] = [
	"血迹从林子里一路滴过来，还是新鲜的。",
	"靴印一深一浅，像是有人拖着伤腿在跑。",
	"树皮上有灰烬兽的爪痕，伐木队在这里被追上过。",
	"散落的木屑和断绳指向东边。",
	"脚印越来越浅，伤者快撑不住了。",
	"这里有拖拽重物的痕迹，方向一直没变。",
	"血迹拐向营地，前面应该就是藏东西的地方。",
	"地上刻着伐木队的记号，补给就在附近。",
	"最后一段血迹停在营地门口，伤者把建材藏了进去。",
]
const CACHE_POS := Vector2(1200, 1100)
const STEP_RADIUS := 46.0
const GUARD_RADIUS := 150.0
const STORY_RADIUS := 200.0

var player
var hud
var points: Array[Vector2] = []
var step := 0
var done := false
var story_shown := false
var guards_spawned := false
var cache
var trail_label: Label
var cache_label: Label


func _ready() -> void:
	z_index = 1
	done = Global.bridge_tracking_done or Global.bridge_repaired
	if done:
		queue_free()
		return
	hud = get_tree().get_first_node_in_group("HUD")
	player = get_tree().get_first_node_in_group("Player")
	for point in TRAIL_POINTS:
		points.append(_reachable(point))
	_build_trail_label()
	queue_redraw()


func _reachable(point: Vector2) -> Vector2:
	var pos := Global.find_reachable_position(point, 72.0)
	return point if pos == Vector2.INF else pos


func _build_trail_label() -> void:
	trail_label = _make_world_label("血迹", points[0] + Vector2(-30, -36), Color(0.95, 0.32, 0.24))
	add_child(trail_label)


func _make_world_label(text: String, pos: Vector2, color: Color) -> Label:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(60, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	return label


func _draw() -> void:
	if done:
		return
	var color := Color(0.38, 0.06, 0.04, 0.85)
	for i in range(mini(step + 1, points.size())):
		var p := points[i]
		draw_circle(p + Vector2(-3.0, 0.0), 3.0, color)
		draw_circle(p + Vector2(4.0, 2.0), 2.5, color)
	if step < points.size():
		var current := points[step]
		draw_arc(current, 14.0, 0.0, TAU, 24, Color(0.95, 0.35, 0.22, 0.35), 1.0)


func _process(_delta: float) -> void:
	if done:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return

	if step < points.size():
		if trail_label != null:
			trail_label.visible = step == 0
		if not story_shown and player.global_position.distance_to(points[0]) <= STORY_RADIUS:
			story_shown = true
			Sfx.play("warn", 0.9, -12.0)
			if hud != null:
				hud.call("show_banner", "伐木队的血迹", "血迹还没干，有人往东逃了", 2.8)
				hud.call("show_notice", "跟着血迹，找到幸存的伐木工")
		if player.global_position.distance_to(points[step]) <= STEP_RADIUS:
			if hud != null:
				hud.call("show_hint", "[%s] 查看血迹" % Settings.binding_text("interact"))
			if Input.is_action_just_pressed("interact"):
				_confirm_trace()
		elif hud != null:
			hud.call("hide_hint")
		return

	if hud != null:
		hud.call("hide_hint")
	if cache == null or not is_instance_valid(cache):
		_finish()
		return
	if not guards_spawned and player.global_position.distance_to(cache.global_position) <= GUARD_RADIUS:
		_spawn_guards()


func _confirm_trace() -> void:
	if step >= points.size() or done:
		return
	var index := step
	step += 1
	Sfx.play("pickup", 1.25, -14.0)
	queue_redraw()
	if hud != null:
		hud.call("hide_hint")
		if index < TRACE_TEXTS.size():
			hud.call("show_notice", TRACE_TEXTS[index])
	if step >= points.size():
		_spawn_cache()
		if hud != null:
			hud.call("show_banner", "血迹的来历", "伐木队遭灰烬兽袭击，伤者把最后一份建材拖到营地藏好。", 4.0)


func _spawn_cache() -> void:
	var objects := get_parent()
	if objects == null:
		objects = get_tree().current_scene
	cache = PICKUP_SCENE.instantiate() as Node2D
	if cache == null:
		return
	cache.set("flag_name", "bridge_tracking_done")
	cache.set("pickup_notice", "找到第三份建材")
	cache.position = _reachable(CACHE_POS)
	objects.add_child(cache)
	cache.global_position = cache.position
	cache.call("setup", "material", "建材", Color(0.95, 0.78, 0.35), MATERIAL_ICON)
	cache_label = _make_world_label("伐木队补给", cache.position + Vector2(-55, -40), Color(0.95, 0.82, 0.5))
	objects.add_child(cache_label)


func _spawn_guards() -> void:
	guards_spawned = true
	if hud != null:
		hud.call("show_notice", "灌木丛里传来急促的脚步声……")
	Sfx.play("warn", 0.95, -8.0)
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	var objects := get_parent()
	if objects == null:
		objects = get_tree().current_scene
	var base: Vector2 = cache.global_position if cache != null and is_instance_valid(cache) else _reachable(CACHE_POS)
	var plans := [
		{"type": 2, "offset": Vector2(-360, -120)},
		{"type": 0, "offset": Vector2(-300, -240)},
		{"type": 0, "offset": Vector2(-340, 60)},
		{"type": 1, "offset": Vector2(-200, 80)},
	]
	for plan in plans:
		var offset: Vector2 = plan["offset"]
		var pos := _reachable(base + offset)
		var enemy := ENEMY_SCENE.instantiate() as Node2D
		if enemy == null:
			continue
		enemy.set("enemy_type", int(plan["type"]))
		enemy.set("region_tier", 2)
		enemy.set("health_multiplier", 1.15)
		enemy.position = pos
		objects.add_child(enemy)
		enemy.global_position = pos
		enemy.set("aggro_timer", 999.0)
		enemy.add_to_group("TrackingGuards")


func _finish() -> void:
	done = true
	visible = false
	set_process(false)
	if trail_label != null:
		trail_label.visible = false
	if cache_label != null:
		cache_label.visible = false
	queue_redraw()
	if hud != null:
		hud.call("show_notice", "第三份建材已到手")
