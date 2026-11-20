extends Control

signal closed

const RECIPES := [
	{"page": 0, "type": "vine_to_herb", "req": {"vine": 1}},
	{"page": 0, "type": "attack", "req": {}},
	{"page": 0, "type": "defense", "req": {}},
	{"page": 1, "type": "axe", "req": {"slime": 2, "shell": 2, "gland": 6}},
	{"page": 1, "type": "sword", "req": {"slime": 2, "shell": 1, "gland": 5}},
	{"page": 1, "type": "armor", "req": {"shell": 3, "gland": 3}},
	{"page": 0, "type": "material", "req": {"herb": 3, "vine": 3, "gland": 3, "shell": 2, "slime": 2}},
	{"page": 0, "type": "mask", "req": {"gland": 2, "shell": 2, "slime": 2}},
]

const ITEM_ICONS := {
	"herb": preload("res://graphics/items/herb.png"),
	"vine": preload("res://graphics/items/vine.png"),
	"gland": preload("res://graphics/items/gland.png"),
	"shell": preload("res://graphics/items/shell.png"),
	"slime": preload("res://graphics/items/slime.png"),
	"material": preload("res://graphics/items/material.png"),
	"mask": preload("res://graphics/items/mask.png"),
}
const ITEM_NAMES := {
	"herb": "草药",
	"vine": "焦藤",
	"gland": "鳞片",
	"shell": "岩甲",
	"slime": "灰烬",
	"material": "建材",
	"mask": "护符",
}
const ICON_FIST := preload("res://graphics/ui/weapon_fist.png")
const ICON_AXE := preload("res://graphics/ui/weapon_axe.png")
const ICON_SWORD := preload("res://graphics/ui/weapon_sword.png")
const ICON_SHIELD := preload("res://graphics/items/shield_up.png")
const ICON_ARMOR := preload("res://graphics/items/armor2.png")

@onready var tab_items: Button = $TabItems
@onready var tab_gear: Button = $TabGear
@onready var page_title: Label = $PageTitle
@onready var stats_label: Label = $Stats
@onready var recipes_box: VBoxContainer = $Scroll/Recipes

var player
var hud
var page := 0
var ui_font: SystemFont


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_tree().get_first_node_in_group("Player")
	hud = get_tree().get_first_node_in_group("HUD")
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Microsoft YaHei", "KaiTi"])
	tab_items.pressed.connect(_set_page.bind(0))
	tab_gear.pressed.connect(_set_page.bind(1))
	_set_page(0)


func open() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	_refresh()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _set_page(p: int) -> void:
	page = p
	var active := Color(1, 0.85, 0.45)
	var inactive := Color(0.55, 0.5, 0.45)
	tab_items.modulate = Color.WHITE
	tab_gear.modulate = Color.WHITE
	tab_items.add_theme_color_override("font_color", active if page == 0 else inactive)
	tab_gear.add_theme_color_override("font_color", active if page == 1 else inactive)
	tab_items.add_theme_color_override("font_hover_color", active)
	tab_gear.add_theme_color_override("font_hover_color", active)
	if visible:
		_refresh()


func _recipe_cost(recipe: Dictionary) -> Dictionary:
	if player == null:
		return recipe["req"]
	match recipe["type"]:
		"attack":
			var n := int(player.attack_upgrades) + 1
			return {"herb": mini(n, Global.item_cap("herb")), "gland": maxi(1, int(ceil(n / 2.0)))}
		"defense":
			var n := int(player.defense_upgrades) + 1
			return {"vine": n, "shell": maxi(1, int(ceil(n / 2.0)))}
	return recipe["req"]


func _recipe_title(recipe: Dictionary, locked: bool) -> String:
	var title := ""
	match recipe["type"]:
		"vine_to_herb": title = "草药"
		"attack": title = "攻击 +10%"
		"defense": title = "防御 +1"
		"axe": title = "斧头 · 重击"
		"sword": title = "剑 · 轻击"
		"armor": title = "护甲 II"
		"material": title = "建材 · 修桥"
		"mask": title = "灰烬护符"
	if locked:
		match recipe["type"]:
			"material": title += " · 需斧剑+护甲"
			"mask": title += " · 需修桥"
	return title


func _recipe_icon(recipe: Dictionary) -> Texture2D:
	match recipe["type"]:
		"vine_to_herb": return ITEM_ICONS["herb"]
		"attack":
			match str(player.current_weapon):
				"axe": return ICON_AXE
				"sword": return ICON_SWORD
			return ICON_FIST
		"defense": return ICON_SHIELD
		"axe": return ICON_AXE
		"sword": return ICON_SWORD
		"armor": return ICON_ARMOR
		"material": return ITEM_ICONS["material"]
		"mask": return ITEM_ICONS["mask"]
	return null


func _row_style(active: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1.0, 0.93, 0.75, 0.55) if active else Color(0.9, 0.85, 0.75, 0.3)
	s.border_color = Color(0.55, 0.4, 0.18, 0.85) if active else Color(0.5, 0.45, 0.38, 0.35)
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	return s


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	return s


func _refresh() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
	page_title.text = "道具配方" if page == 0 else "武器 / 防具配方"
	stats_label.text = "攻击 %d（%s）     防御 %d / %d" % [player.get_weapon_damage(), player.get_weapon_name(), player.defense, player.defense_cap]
	for child in recipes_box.get_children():
		recipes_box.remove_child(child)
		child.queue_free()
	for recipe in RECIPES:
		if int(recipe["page"]) != page:
			continue
		var maxed := _is_maxed(recipe["type"])
		var locked := _is_locked(recipe["type"])
		var cost := _recipe_cost(recipe)
		recipes_box.add_child(_build_recipe_row(recipe, cost, maxed, locked))


func _build_recipe_row(recipe: Dictionary, cost: Dictionary, maxed: bool, locked: bool) -> Control:
	var active := not maxed and not locked and Global.has_items(cost)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _row_style(active))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 5)
	margin.add_child(hbox)

	var icon := TextureRect.new()
	icon.texture = _recipe_icon(recipe)
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbox.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	hbox.add_child(info)

	var title := Label.new()
	title.text = _recipe_title(recipe, locked)
	title.add_theme_font_override("font", ui_font)
	title.add_theme_font_size_override("font_size", 7)
	title.add_theme_color_override("font_color", Color(0.24, 0.13, 0.07) if active else Color(0.5, 0.45, 0.4))
	info.add_child(title)

	var ingredients := HBoxContainer.new()
	ingredients.add_theme_constant_override("separation", 3)
	info.add_child(ingredients)
	for key in cost:
		var item := VBoxContainer.new()
		item.add_theme_constant_override("separation", 0)
		var item_icon := TextureRect.new()
		item_icon.texture = ITEM_ICONS.get(key, null)
		item_icon.custom_minimum_size = Vector2(9, 9)
		item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_icon.stretch_mode = TextureRect.STRETCH_SCALE
		item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		item_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item.add_child(item_icon)
		var need := int(cost[key])
		var have := int(Global.inventory.get(key, 0))
		var count := Label.new()
		count.text = "%s×%d" % [ITEM_NAMES.get(key, key), need]
		count.add_theme_font_override("font", ui_font)
		count.add_theme_font_size_override("font_size", 4)
		count.add_theme_color_override("font_color", Color(0.35, 0.2, 0.12) if have >= need else Color(0.72, 0.16, 0.1))
		count.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item.add_child(count)
		ingredients.add_child(item)

	var btn := Button.new()
	if maxed:
		btn.text = "已拥有" if recipe["type"] in ["axe", "sword", "material", "mask"] else "已满"
	else:
		btn.text = "锁定" if locked else "合成"
	btn.custom_minimum_size = Vector2(36, 16)
	btn.disabled = maxed or locked or not Global.has_items(cost)
	btn.add_theme_font_override("font", ui_font)
	btn.add_theme_font_size_override("font_size", 7)
	btn.add_theme_color_override("font_color", Color(1.0, 0.93, 0.8))
	btn.add_theme_color_override("font_disabled_color", Color(0.72, 0.68, 0.6))
	btn.add_theme_stylebox_override("normal", _button_style(Color(0.36, 0.25, 0.13, 0.95), Color(0.66, 0.48, 0.2)))
	btn.add_theme_stylebox_override("hover", _button_style(Color(0.46, 0.33, 0.16, 1.0), Color(0.85, 0.65, 0.3)))
	btn.add_theme_stylebox_override("pressed", _button_style(Color(0.52, 0.37, 0.18, 1.0), Color(0.95, 0.75, 0.35)))
	btn.add_theme_stylebox_override("disabled", _button_style(Color(0.45, 0.42, 0.36, 0.55), Color(0.5, 0.47, 0.4, 0.4)))
	btn.pressed.connect(_craft.bind(recipe))
	hbox.add_child(btn)
	return panel


func _is_maxed(type: String) -> bool:
	if player == null:
		return false
	match type:
		"vine_to_herb":
			return Global.is_item_full("herb")
		"attack":
			return player.attack_upgrades >= player.get_attack_upgrade_cap()
		"defense":
			return player.defense >= player.defense_cap
		"axe":
			return player.has_axe
		"sword":
			return player.has_sword
		"armor":
			return player.armor_tier >= 2
		"material":
			return Global.material_crafted
		"mask":
			return Global.mask_crafted
	return false


func _is_locked(type: String) -> bool:
	if player == null:
		return false
	match type:
		"material":
			return not ((player.has_axe or player.has_sword) and player.armor_tier >= 2)
		"mask":
			return not Global.bridge_repaired
	return false


func _craft(recipe: Dictionary) -> void:
	if _is_maxed(recipe["type"]) or _is_locked(recipe["type"]):
		return
	var cost := _recipe_cost(recipe)
	if not Global.has_items(cost):
		if hud != null:
			hud.call("show_notice", "材料不足")
		return
	Global.remove_items(cost)
	match recipe["type"]:
		"vine_to_herb":
			Global.add_item("herb", 1)
			_notice("草药 +1")
		"attack":
			var before := int(player.get_weapon_damage())
			player.call("upgrade_attack")
			_notice("攻击力 %d → %d（%s）" % [before, player.get_weapon_damage(), player.get_weapon_name()])
		"defense":
			var before := int(player.defense)
			player.call("upgrade_defense")
			_notice("防御力 %d → %d" % [before, player.defense])
		"axe":
			player.call("equip_axe")
			_notice("获得斧头（已装备）")
		"sword":
			player.call("equip_sword")
			_notice("获得剑（已装备）")
		"armor":
			player.call("equip_tier2_armor")
			_notice("获得二级护甲：防御力 → %d" % player.defense)
		"material":
			Global.add_item("material", 1)
			Global.material_crafted = true
			_notice("获得建材")
		"mask":
			Global.add_item("mask", 1)
			Global.mask_crafted = true
			_notice("获得灰烬护符")
	Sfx.play("craft")
	_flash_stats()
	SaveGame.save_game("营地")
	_refresh()


func _notice(text: String) -> void:
	if hud != null:
		hud.call("show_notice", text)


func _flash_stats() -> void:
	if stats_label == null:
		return
	stats_label.modulate = Color(1.0, 0.82, 0.32)
	var t := create_tween()
	t.tween_property(stats_label, "modulate", Color.WHITE, 0.5)
