extends Control

signal closed

@onready var text_label: Label = $Book/Text

var player
var hud
var base_text := ""
var grant_key_on_close := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_tree().get_first_node_in_group("Player")
	hud = get_tree().get_first_node_in_group("HUD")
	base_text = text_label.text


func open() -> void:
	if visible:
		return
	text_label.text = base_text
	grant_key_on_close = true
	visible = true
	get_tree().paused = true


func open_note(title: String, body: String) -> void:
	if visible:
		return
	text_label.text = title + "\n" + body
	grant_key_on_close = false
	visible = true
	get_tree().paused = true


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	if grant_key_on_close and player != null and not bool(player.get("camp_key_granted")):
		player.call("give_camp_key")
		if hud != null:
			hud.call("show_notice", "获得营地钥匙")
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
