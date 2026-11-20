extends Node2D

@onready var blocker: CollisionShape2D = $Blocker/CollisionShape2D

var active := false


func _ready() -> void:
	visible = false
	blocker.disabled = true
	_set_particles(false)


func activate() -> void:
	if active:
		return
	active = true
	visible = true
	modulate.a = 0.0
	blocker.disabled = false
	_set_particles(true)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.45)


func lift() -> void:
	if not active:
		return
	active = false
	blocker.disabled = true
	_set_particles(false)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 1.0)
	t.tween_callback(func() -> void: visible = false)


func lift_immediate() -> void:
	active = false
	blocker.disabled = true
	_set_particles(false)
	visible = false


func _set_particles(on: bool) -> void:
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = on
