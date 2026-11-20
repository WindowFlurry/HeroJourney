extends Panel

signal item_dropped(target_slot: String, drag_data: Dictionary)

var slot_id := ""
var item_id := ""


func setup(id: String) -> void:
	slot_id = id
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_item(id: String) -> void:
	item_id = id


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty():
		return null
	var preview := Label.new()
	preview.text = str(Global.ITEM_NAMES.get(item_id, item_id))
	preview.add_theme_font_size_override("font_size", 7)
	preview.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	preview.position = Vector2(8, 8)
	set_drag_preview(preview)
	return {"kind": "equipment_item", "item_id": item_id, "slot": slot_id}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and Global.can_equip(slot_id, str(data.get("item_id", "")))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	item_dropped.emit(slot_id, data.duplicate())
