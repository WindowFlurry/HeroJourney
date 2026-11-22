extends Node2D

const ARROW_TEXTURE: Texture2D = preload("res://graphics/projectiles/arrow.png")

var direction := Vector2.RIGHT
var speed := 180.0
var damage := 8
var projectile_color := Color(1.0, 0.55, 0.16)
var radius := 3.0
var explode_on_impact := false
var friendly := true
var life := 2.4
var dead := false
var hit_targets := {}
var target_position := Vector2(INF, INF)
var has_target := false
var projectile_style := "orb"


func _ready() -> void:
	z_index = 4
	add_to_group("PrologueProjectiles")
	queue_redraw()


func setup_friendly(
	new_direction: Vector2,
	new_speed: float,
	new_damage: int,
	color: Color,
	new_radius: float,
	should_explode: bool = false,
	style: String = "orb",
) -> void:
	direction = new_direction.normalized()
	speed = new_speed
	damage = new_damage
	projectile_color = color
	radius = new_radius
	explode_on_impact = should_explode
	friendly = true
	life = 2.2
	projectile_style = style
	if projectile_style == "arrow":
		rotation = direction.angle() - PI * 0.5
	queue_redraw()


func setup_enemy_target(new_direction: Vector2, new_speed: float, new_damage: int, target: Vector2) -> void:
	direction = new_direction.normalized()
	speed = new_speed
	damage = new_damage
	projectile_color = Color(1.0, 0.28, 0.08)
	projectile_style = "orb"
	radius = 5.0
	explode_on_impact = true
	friendly = false
	target_position = target
	has_target = true
	life = maxf(global_position.distance_to(target) / maxf(new_speed, 1.0) + 0.5, 0.5)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if dead:
		return
	var old_position := global_position
	var next_position := old_position + direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(old_position, next_position, 1)
	query.collide_with_areas = false
	var wall_hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall_hit.is_empty():
		global_position = wall_hit.position
		_finish(wall_hit.position)
		return
	global_position = next_position
	life -= delta
	if projectile_style != "arrow":
		rotation += delta * 2.5
	if has_target and global_position.distance_to(target_position) <= speed * delta + 4.0:
		global_position = target_position
		_explode()
		return
	if friendly:
		_check_enemies()
	else:
		_check_player()
	if life <= 0.0:
		_finish(global_position)


func _check_enemies() -> void:
	for node in get_tree().get_nodes_in_group("Enemies"):
		var enemy := node as Node2D
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var multiplier := 1.0
		if enemy.has_method("hit_test_projectile"):
			var info = enemy.call("hit_test_projectile", global_position, radius + 4.0)
			if not bool(info.get("hit", false)):
				continue
			multiplier = float(info.get("multiplier", 1.0))
		elif global_position.distance_to(_enemy_center(enemy)) > _enemy_hit_radius(enemy):
			continue
		_damage_enemy(enemy, multiplier)
		if not explode_on_impact:
			_finish(global_position)
			return
		_explode()
		return


func _check_player() -> void:
	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player == null or bool(player.get("dead")):
		return
	var center := player.global_position + Vector2(0, -12)
	if global_position.distance_to(center) > radius + 9.0:
		return
	player.call("take_damage", damage)
	if explode_on_impact:
		_explode()
	else:
		_finish(global_position)


func _damage_enemy(enemy: Node2D, multiplier: float = 1.0) -> void:
	var id := enemy.get_instance_id()
	if hit_targets.has(id):
		return
	hit_targets[id] = true
	var final_damage := maxi(1, int(round(float(damage) * multiplier)))
	if enemy.has_method("take_damage_from"):
		enemy.call("take_damage_from", final_damage, global_position)
	else:
		enemy.call("take_damage", final_damage)


func _explode() -> void:
	if dead:
		return
	dead = true
	var blast_radius := 34.0
	if friendly:
		for node in get_tree().get_nodes_in_group("Enemies"):
			var enemy := node as Node2D
			if enemy == null or enemy.is_queued_for_deletion():
				continue
			var multiplier := 1.0
			if enemy.has_method("hit_test_projectile"):
				var info = enemy.call("hit_test_projectile", global_position, blast_radius)
				if not bool(info.get("hit", false)):
					continue
				multiplier = float(info.get("multiplier", 1.0))
			elif global_position.distance_to(_enemy_center(enemy)) > blast_radius + _enemy_hit_radius(enemy) * 0.45:
				continue
			var los := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1)
			los.collide_with_areas = false
			if not get_world_2d().direct_space_state.intersect_ray(los).is_empty():
				continue
			_damage_enemy(enemy, multiplier)
	_spawn_burst()
	queue_free()


func _finish(at_position: Vector2) -> void:
	if dead:
		return
	if explode_on_impact:
		global_position = at_position
		_explode()
		return
	dead = true
	queue_free()


func _spawn_burst() -> void:
	var burst := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 16:
		points.append(Vector2.from_angle(TAU * i / 16.0) * 12.0)
	burst.polygon = points
	burst.color = Color(projectile_color, 0.55)
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.z_index = 3
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2(2.4, 2.4), 0.22)
	tween.tween_property(burst, "modulate:a", 0.0, 0.22)
	tween.tween_callback(burst.queue_free)


func _enemy_center(enemy: Node2D) -> Vector2:
	if enemy.is_in_group("TrainingDummies"):
		return enemy.global_position + Vector2(0, -16)
	return enemy.global_position + Vector2(0, -11)


func _enemy_hit_radius(enemy: Node2D) -> float:
	if enemy.is_in_group("TrainingDummies"):
		return radius + 11.0
	return radius + 9.0


func _draw() -> void:
	if projectile_style == "arrow":
		var arrow_size := Vector2(8.0 / 3.0, 28.8 / 3.0)
		draw_texture_rect(ARROW_TEXTURE, Rect2(-arrow_size * 0.5, arrow_size), false)
		return
	draw_circle(Vector2.ZERO, radius + 2.0, Color(projectile_color, 0.22))
	draw_circle(Vector2.ZERO, radius, projectile_color)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.25), maxf(radius * 0.35, 1.0), Color(1.0, 0.96, 0.75, 0.9))

