extends Panel

signal item_dropped(target_index: int, drag_data: Dictionary)

var slot_index := 0
var item_id := ""


func setup(index: int) -> void:
	slot_index = index
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
	return {"kind": "hotbar_item", "item_id": item_id, "slot_index": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and str(data.get("kind", "")) in ["inventory_item", "hotbar_item"]


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	item_dropped.emit(slot_index, data.duplicate())
