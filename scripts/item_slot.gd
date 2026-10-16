class_name ItemSlot
extends Control
## Envanterdeki tek bir kutu: kuşanma yuvası ("equip:helmet") veya çanta gözü ("bag:3").
## Sürükle-bırak destekler; asıl taşıma işini InventoryPanel yapar.

var panel: Object          # InventoryPanel
var location := ""
var item: Dictionary = {}
var placeholder_icon := ""
var caption := ""
var selected := false
var _hover := false


func _init(p: Object, loc: String, it: Dictionary, ph_icon := "", cap := "", px := 68) -> void:
	panel = p
	location = loc
	item = it
	placeholder_icon = ph_icon
	caption = cap
	custom_minimum_size = Vector2(px, px + (16 if cap != "" else 0))
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw())
	_update_tooltip()


func _update_tooltip() -> void:
	if item.is_empty():
		tooltip_text = caption if caption != "" else "Boş"
	else:
		tooltip_text = "%s%s\n%s" % [item.get("name", ""), (" x%d" % int(item.get("qty", 1))) if int(item.get("qty", 1)) > 1 else "", item.get("text", "")]


func _box() -> Rect2:
	var s := minf(size.x, size.y - (16.0 if caption != "" else 0.0))
	return Rect2(Vector2((size.x - s) * 0.5, 0), Vector2(s, s))


func _draw() -> void:
	var r := _box()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.06) if item.is_empty() else Color(0.16, 0.13, 0.1)
	sb.set_corner_radius_all(6)
	var border := Color(0.35, 0.29, 0.2)
	if not item.is_empty():
		border = Lore.RARITIES.get(item.get("rarity", "common"), Lore.RARITIES["common"])["color"]
	if selected:
		border = Color("ffcc33")
	elif _hover:
		border = border.lightened(0.3)
	sb.border_color = border
	sb.set_border_width_all(3 if (selected or not item.is_empty()) else 2)
	draw_style_box(sb, r)
	if not item.is_empty():
		var rc: Color = Lore.RARITIES.get(item.get("rarity", "common"), Lore.RARITIES["common"])["color"]
		if item.get("rarity", "common") != "common":
			draw_circle(r.get_center(), r.size.x * 0.36, Color(rc, 0.18))
		ItemPainter.draw(self, str(item.get("icon", item.get("template", "custom"))), r.get_center(), r.size.x * 0.42, item.get("tint", null))
		var q := int(item.get("qty", 1))
		if q > 1:
			var font := ThemeDB.fallback_font
			var txt := str(q)
			var fs := 13
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var p := r.end - Vector2(w + 6, 5)
			draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.BLACK)
			draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	elif placeholder_icon != "":
		modulate_icon(r)
	if caption != "":
		var font := ThemeDB.fallback_font
		var fs := 11
		var w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2((size.x - w) * 0.5, size.y - 3), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.75, 0.7, 0.6))


func modulate_icon(r: Rect2) -> void:
	# boş yuvada soluk siluet
	draw_set_transform(Vector2.ZERO)
	var c := r.get_center()
	ItemPainter.draw(self, placeholder_icon, c, r.size.x * 0.32, Color(0.3, 0.27, 0.22))
	draw_rect(r.grow(-3), Color(0.08, 0.07, 0.06, 0.55), true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			panel.quick_move(location)
		else:
			panel.select_location(location)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		panel.quick_move(location)
		accept_event()


func _get_drag_data(_pos: Vector2) -> Variant:
	if item.is_empty():
		return null
	var prev := ItemSlot.new(panel, "", item, "", "", 56)
	prev.size = Vector2(56, 56)
	prev.modulate = Color(1, 1, 1, 0.85)
	var holder := Control.new()
	holder.add_child(prev)
	prev.position = Vector2(-28, -28)
	set_drag_preview(holder)
	return {"inv_from": location, "panel": panel}


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("inv_from") and data.get("panel") == panel and panel.can_move(data["inv_from"], location)


func _drop_data(_pos: Vector2, data: Variant) -> void:
	panel.move_item(data["inv_from"], location)
