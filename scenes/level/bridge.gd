extends Node2D

@onready var broken_sprite: Sprite2D = $Broken
@onready var repaired_sprite: Sprite2D = $Repaired
@onready var blocker: CollisionShape2D = $Blocker/CollisionShape2D
@onready var fog_blocker: CollisionShape2D = $FogBlocker/CollisionShape2D
@onready var repair_area: Area2D = $RepairArea
@onready var fog_area: Area2D = $FogArea

var player
var hud
var near_repair := false
var near_fog := false
var repaired := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	hud = get_tree().get_first_node_in_group("HUD")
	repair_area.body_entered.connect(_on_repair_entered)
	repair_area.body_exited.connect(_on_repair_exited)
	fog_area.body_entered.connect(_on_fog_entered)
	fog_area.body_exited.connect(_on_fog_exited)
	repaired = Global.bridge_repaired
	_apply_state()


func _apply_state() -> void:
	broken_sprite.visible = not repaired
	repaired_sprite.visible = repaired
	blocker.disabled = repaired
	fog_blocker.disabled = Global.mask_equipped


func _on_repair_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near_repair = true


func _on_repair_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near_repair = false
		if hud != null:
			hud.call("hide_hint")


func _on_fog_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near_fog = true


func _on_fog_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		near_fog = false
		if hud != null:
			hud.call("hide_hint")


func _process(_delta: float) -> void:
	if get_tree().paused:
		return
	if Global.mask_equipped:
		fog_blocker.disabled = true
	if near_fog and repaired and not Global.mask_equipped:
		if int(Global.inventory.get("mask", 0)) > 0:
			if hud != null:
				hud.call("show_hint", "按 F 带上灰烬护符")
			if Input.is_action_just_pressed("interact"):
				_equip_mask()
		else:
			if hud != null:
				hud.call("show_hint", "你需要灰烬护符……")
		return
	if near_repair and not repaired:
		if int(Global.inventory.get("material", 0)) > 0:
			if hud != null:
				hud.call("show_hint", "按 F 修建断桥")
			if Input.is_action_just_pressed("interact"):
				_repair_bridge()
		else:
			if hud != null:
				hud.call("show_hint", "需要建材……")
		return
	if near_repair or near_fog:
		if hud != null:
			hud.call("hide_hint")


func _equip_mask() -> void:
	if Global.mask_equipped:
		return
	if int(Global.inventory.get("mask", 0)) <= 0:
		return
	Global.mask_equipped = true
	fog_blocker.disabled = true
	Sfx.play("pickup")
	if hud != null:
		hud.call("hide_hint")
		hud.call("show_notice", "已带上灰烬护符")


func _repair_bridge() -> void:
	if repaired:
		return
	if int(Global.inventory.get("material", 0)) <= 0:
		return
	Global.remove_items({"material": 1})
	Global.bridge_repaired = true
	repaired = true
	_apply_state()
	SaveGame.save_game("断桥")
	Sfx.play("craft")
	if hud != null:
		hud.call("hide_hint")
		hud.call("show_notice", "桥梁已修复")
