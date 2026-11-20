extends Panel

signal item_returned(drag_data: Dictionary)

var item_id := ""


func setup(id: String) -> void:
	item_id = id
	mouse_filter = Control.MOUSE_FILTER_STOP


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty() or int(Global.inventory.get(item_id, 0)) <= 0:
		return null
	var preview := Label.new()
	preview.text = str(Global.ITEM_NAMES.get(item_id, item_id))
	preview.add_theme_font_size_override("font_size", 7)
	preview.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	preview.position = Vector2(8, 8)
	set_drag_preview(preview)
	return {"kind": "inventory_item", "item_id": item_id}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return item_id.is_empty() and data is Dictionary and str(data.get("kind", "")) in ["hotbar_item", "equipment_item"]


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	item_returned.emit(data.duplicate())

