extends Node

# 设置：音量、全屏、按键绑定。所有按键修改都会直接写入 InputMap 并持久化。

const PATH := "user://settings.cfg"

const ACTIONS := [
	{"action": "left", "label": "移动左"},
	{"action": "right", "label": "移动右"},
	{"action": "up", "label": "移动上"},
	{"action": "down", "label": "移动下"},
	{"action": "action", "label": "攻击"},
	{"action": "run", "label": "疾跑"},
	{"action": "dash", "label": "职业技能"},
	{"action": "weapon_skill", "label": "武器特技"},
	{"action": "interact", "label": "交互 / 拾取"},
	{"action": "character_menu", "label": "角色 / 背包"},
	{"action": "use_herb", "label": "使用草药"},
	{"action": "craft", "label": "打开制作"},
	{"action": "weapon_1", "label": "武器 1"},
	{"action": "weapon_2", "label": "武器 2"},
	{"action": "weapon_3", "label": "武器 3"},
	{"action": "weapon_4", "label": "武器 4"},
	{"action": "pause", "label": "暂停"},
]

var master_volume := 1.0
var sfx_volume := 1.0
var fullscreen := false

var _config := ConfigFile.new()


func _ready() -> void:
	_ensure_sfx_bus()
	_ensure_default_actions()
	_load_settings()


func _ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index("SFX") != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, "SFX")
	AudioServer.set_bus_send(idx, "Master")


func _ensure_default_actions() -> void:
	_ensure_key_action("pause", KEY_ESCAPE)
	_ensure_key_action("dash", KEY_Z)
	_ensure_key_action("character_menu", KEY_E)
	_ensure_key_action("debug_jump", KEY_TAB)
	_ensure_mouse_action("weapon_skill", MOUSE_BUTTON_RIGHT)


func _ensure_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _ensure_mouse_action(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _load_settings() -> void:
	var err := _config.load(PATH)
	if err != OK:
		_apply_volumes()
		return
	master_volume = clampf(float(_config.get_value("audio", "master", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(_config.get_value("audio", "sfx", 1.0)), 0.0, 1.0)
	fullscreen = bool(_config.get_value("video", "fullscreen", false))
	if fullscreen and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_apply_volumes()
	for entry in ACTIONS:
		var action := str(entry["action"])
		if not _config.has_section_key("bindings", action):
			continue
		var saved = _config.get_value("bindings", action, null)
		if saved is Dictionary:
			var ev := _deserialize_event(saved)
			if ev != null:
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, ev)


func _save_settings() -> void:
	_config.set_value("audio", "master", master_volume)
	_config.set_value("audio", "sfx", sfx_volume)
	_config.set_value("video", "fullscreen", fullscreen)
	for entry in ACTIONS:
		var action := str(entry["action"])
		var events := InputMap.action_get_events(action)
		if events.is_empty():
			continue
		var data := _serialize_event(events[0])
		if not data.is_empty():
			_config.set_value("bindings", action, data)
	_config.save(PATH)


func _apply_volumes() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, master_volume <= 0.001)
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(maxf(master_volume, 0.001)))
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_mute(sfx_idx, sfx_volume <= 0.001)
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(maxf(sfx_volume, 0.001)))


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func label_for(action: String) -> String:
	for entry in ACTIONS:
		if str(entry["action"]) == action:
			return str(entry["label"])
	return action


func binding_text(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "未设置"
	var ev: InputEvent = events[0]
	if ev is InputEventKey:
		var code: int = ev.keycode if ev.keycode != 0 else ev.physical_keycode
		return OS.get_keycode_string(code)
	if ev is InputEventMouseButton:
		match (ev as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return "鼠标左键"
			MOUSE_BUTTON_RIGHT:
				return "鼠标右键"
			MOUSE_BUTTON_MIDDLE:
				return "鼠标中键"
			MOUSE_BUTTON_XBUTTON1:
				return "鼠标侧键1"
			MOUSE_BUTTON_XBUTTON2:
				return "鼠标侧键2"
	return "未设置"


func find_conflict(action: String, event: InputEvent) -> String:
	for entry in ACTIONS:
		var other := str(entry["action"])
		if other == action:
			continue
		for ev in InputMap.action_get_events(other):
			if _same_event(ev, event):
				return other
	return ""


func remove_event(action: String, event: InputEvent) -> void:
	InputMap.action_erase_event(action, event)
	_save_settings()


func rebind(action: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_save_settings()


func _same_event(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ak: int = (a as InputEventKey).physical_keycode if (a as InputEventKey).physical_keycode != 0 else (a as InputEventKey).keycode
		var bk: int = (b as InputEventKey).physical_keycode if (b as InputEventKey).physical_keycode != 0 else (b as InputEventKey).keycode
		return ak == bk
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return (a as InputEventMouseButton).button_index == (b as InputEventMouseButton).button_index
	return false


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		return {
			"type": "key",
			"keycode": key.keycode,
			"physical": key.physical_keycode,
			"unicode": key.unicode,
		}
	if event is InputEventMouseButton:
		return {"type": "mouse", "button": (event as InputEventMouseButton).button_index}
	return {}


func _deserialize_event(data: Dictionary) -> InputEvent:
	match str(data.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.keycode = int(data.get("keycode", 0))
			key.physical_keycode = int(data.get("physical", 0))
			key.unicode = int(data.get("unicode", 0))
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(data.get("button", 1))
			return mouse
	return null
