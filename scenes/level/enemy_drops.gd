extends RefCounted

# 第二、三关普通敌人的掉落。第一关已有自己的 DROP_TABLE；
# 这里复用同一套拾取物，但按区域和精英等级调整数量。

const PICKUP_SCENE: PackedScene = preload("res://scenes/level/pickup_item.tscn")
const ITEM_DATA := {
	"gland": {"name": "龙兽鳞片", "color": Color(1.0, 0.22, 0.22, 1.0)},
	"shell": {"name": "岩甲碎片", "color": Color(0.78, 0.78, 0.82, 1.0)},
	"slime": {"name": "灼热灰烬", "color": Color(0.96, 0.98, 1.0, 1.0)},
	"herb": {"name": "草药", "color": Color(0.4, 1.0, 0.48, 1.0)},
}
const ICONS := {
	"gland": preload("res://graphics/items/gland.png"),
	"shell": preload("res://graphics/items/shell.png"),
	"slime": preload("res://graphics/items/slime.png"),
	"herb": preload("res://graphics/items/herb.png"),
}


static func spawn(parent: Node, origin: Vector2, tier: int, elite: bool) -> void:
	if parent == null:
		return
	var drops: Array[String] = []
	var material_count := 2 if elite else 1
	if tier >= 2 and not elite and randf() < 0.35:
		material_count += 1
	if elite:
		material_count += 1
	for i in material_count:
		drops.append(_random_material(tier))
	var herb_chance := 0.45 if elite else 0.16
	if tier >= 2:
		herb_chance += 0.04
	if randf() < herb_chance and not Global.is_item_full("herb"):
		drops.append("herb")
	while drops.size() > 4:
		drops.pop_back()

	for i in drops.size():
		var angle := TAU * float(i) / float(maxi(drops.size(), 1))
		var target := origin + Vector2(cos(angle), sin(angle)) * 10.0
		var drop_pos := Global.find_reachable_position(target, 24.0)
		if not is_finite(drop_pos.x):
			drop_pos = Global.find_reachable_position(origin, 24.0)
		if not is_finite(drop_pos.x):
			continue
		var item := PICKUP_SCENE.instantiate()
		parent.add_child(item)
		item.global_position = drop_pos
		var item_id := drops[i]
		var data: Dictionary = ITEM_DATA[item_id]
		item.call("setup", item_id, str(data["name"]), data["color"], ICONS.get(item_id, null))


static func _random_material(tier: int) -> String:
	var roll := randf()
	if tier >= 2:
		if roll < 0.45:
			return "gland"
		if roll < 0.75:
			return "shell"
		return "slime"
	if roll < 0.45:
		return "slime"
	if roll < 0.75:
		return "gland"
	return "shell"
