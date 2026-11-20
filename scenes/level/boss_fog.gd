extends Node2D

# 前哨木桥修好前笼罩白桦林地的龙焰烟尘；修好后向右退场，露出林地。

var revealed := false


func _ready() -> void:
	if Global.mask_equipped:
		revealed = true
		visible = false
	else:
		_set_emitting(true)


func _process(_delta: float) -> void:
	if not revealed and Global.mask_equipped:
		reveal()


func reveal() -> void:
	if revealed:
		return
	revealed = true
	_set_emitting(true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", position.x + 640.0, 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_finish_reveal)


func _finish_reveal() -> void:
	visible = false
	_set_emitting(false)


func _set_emitting(on: bool) -> void:
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = on
