class_name CombatHit

# 统一的受击判定：boxes 是 [{"rect": Rect2, "multiplier": float, "region": String}, ...]
# rect 使用全局坐标，覆盖怪物可见模型的对应部位。

static func melee(boxes: Array, attacker_pos: Vector2, dir: Vector2, reach: float) -> Dictionary:
	var best := {}
	var best_distance := INF
	for box in boxes:
		var rect: Rect2 = box["rect"]
		var closest := Vector2(
			clampf(attacker_pos.x, rect.position.x, rect.end.x),
			clampf(attacker_pos.y, rect.position.y, rect.end.y)
		)
		var offset := closest - attacker_pos
		var distance := offset.length()
		if distance > reach:
			continue
		if distance > 0.5:
			if offset.normalized().dot(dir) <= 0.0 and not rect.has_point(attacker_pos):
				continue
		if distance < best_distance:
			best_distance = distance
			best = {
				"hit": true,
				"multiplier": float(box.get("multiplier", 1.0)),
				"region": str(box.get("region", "")),
			}
	return best


static func point(boxes: Array, point: Vector2, radius: float) -> Dictionary:
	var best := {}
	var best_area := INF
	for box in boxes:
		var rect: Rect2 = box["rect"].grow(radius)
		if not rect.has_point(point):
			continue
		var area := rect.size.x * rect.size.y
		if area < best_area:
			best_area = area
			best = {
				"hit": true,
				"multiplier": float(box.get("multiplier", 1.0)),
				"region": str(box.get("region", "")),
			}
	return best
