extends Node2D

const FENCE: Texture2D = preload("res://graphics/monastery/iron_fence.png")
const GATE: Texture2D = preload("res://graphics/coast/gate_bars.png")
const GLOW: Texture2D = preload("res://graphics/fx/glow_white.png")

var gate_blocker: StaticBody2D
var gate_sprite: Sprite2D
var gate_glow: Sprite2D
var opened := false


func setup(center: Vector2, width: float, gate_width: float, open_now: bool, side_depth: float = 0.0) -> void:
	global_position = center
	z_index = 4
	var half := width * 0.5
	var gate_half := gate_width * 0.5
	# 两侧围栏
	var x := -half
	while x <= half:
		if absf(x) > gate_half + 14.0:
			_fence_piece(Vector2(x, 0), 0.0)
		x += 32.0
	_add_blocker(Vector2((-half - gate_half) * 0.5, -20), Vector2(maxf(half - gate_half, 0), 40))
	_add_blocker(Vector2((half + gate_half) * 0.5, -20), Vector2(maxf(half - gate_half, 0), 40))

	# 围栏门
	gate_sprite = Sprite2D.new()
	gate_sprite.texture = GATE
	gate_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gate_sprite.position = Vector2(0, -24)
	gate_sprite.z_index = 4
	add_child(gate_sprite)
	gate_glow = Sprite2D.new()
	gate_glow.texture = GLOW
	gate_glow.position = Vector2(0, -24)
	gate_glow.scale = Vector2(1.6, 1.6)
	gate_glow.modulate = Color(1.0, 0.58, 0.22, 0.22)
	gate_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	gate_glow.z_index = 3
	add_child(gate_glow)
	gate_blocker = _add_blocker(Vector2(0, -20), Vector2(gate_width, 40))

	# 钥匙笼：侧栏和后栏，防止从侧面绕过去
	if side_depth > 0.0:
		var y := -32.0
		while y >= -side_depth:
			_fence_piece(Vector2(-half, y), PI * 0.5)
			_fence_piece(Vector2(half, y), PI * 0.5)
			y -= 32.0
		_add_blocker(Vector2(-half, -side_depth * 0.5), Vector2(16, side_depth))
		_add_blocker(Vector2(half, -side_depth * 0.5), Vector2(16, side_depth))
		var bx := -half
		while bx <= half:
			_fence_piece(Vector2(bx, -side_depth), 0.0)
			bx += 32.0
		_add_blocker(Vector2(0, -side_depth), Vector2(width, 40))

	if open_now:
		_set_open_instant()


func _fence_piece(pos: Vector2, rot: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = FENCE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2.0, 2.0)
	sprite.rotation = rot
	sprite.position = pos + Vector2(0, -16)
	sprite.z_index = 4
	add_child(sprite)


func _add_blocker(center: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	return body


func open() -> void:
	if opened:
		return
	opened = true
	for child in gate_blocker.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(gate_sprite, "position:y", gate_sprite.position.y - 48.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(gate_sprite, "modulate:a", 0.0, 0.55)
	tween.tween_property(gate_glow, "modulate:a", 0.0, 0.55)
	Sfx.play("craft", 1.0, 1.5)


func _set_open_instant() -> void:
	opened = true
	for child in gate_blocker.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	gate_sprite.visible = false
	gate_glow.visible = false
