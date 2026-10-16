class_name BestiaryWindow
extends Window
## Yaratık kataloğu: kategoriye göre süz, ara, tıkla ve kampanyana ekle.

signal picked(species: String)

var _grid: GridContainer
var _search: LineEdit
var _cat := ""
var _cat_buttons: HBoxContainer
var _info: Label
var _looks := {}


func _init() -> void:
	title = "Bestiyer — Yaratık Ekle"
	size = Vector2i(1180, 760)
	min_size = Vector2i(800, 500)
	transient = true
	visible = false
	close_requested.connect(hide)


func _ready() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.085)
	sb.set_content_margin_all(10)
	bg.add_theme_stylebox_override("panel", sb)
	add_child(bg)
	var root := VBoxContainer.new()
	bg.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	_search = LineEdit.new()
	_search.placeholder_text = "Ara: ejderha, kurt, iskelet..."
	_search.custom_minimum_size.x = 260
	_search.text_changed.connect(func(_t: String) -> void: _fill())
	top.add_child(_search)
	_info = Label.new()
	_info.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	top.add_child(_info)
	_cat_buttons = HBoxContainer.new()
	var cs := ScrollContainer.new()
	cs.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cs.custom_minimum_size.y = 40
	cs.add_child(_cat_buttons)
	root.add_child(cs)
	var group := ButtonGroup.new()
	for c in [""] + Lore.CREATURE_CATS:
		var b := Button.new()
		b.text = "Hepsi" if c == "" else c
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.button_pressed = c == ""
		var cat: String = c
		b.pressed.connect(func() -> void:
			_cat = cat
			_fill())
		_cat_buttons.add_child(b)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(sc)
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(_grid)
	var hint := Label.new()
	hint.text = "Bir yaratığa tıkla: kampanyana eklenir ve Karakter aracı seçilir. Haritaya her tıklayışında yeni bir jeton (Kurt 1, Kurt 2...) koyarsın."
	hint.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	root.add_child(hint)


func open() -> void:
	_fill()
	popup_centered()


func _fill() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var q := _search.text.strip_edges().to_lower()
	var count := 0
	for k in Lore.creatures:
		var d: Dictionary = Lore.creatures[k]
		if _cat != "" and d["cat"] != _cat:
			continue
		if q != "" and str(d["name"]).to_lower().find(q) < 0 and str(k).find(q) < 0:
			continue
		count += 1
		var card := Button.new()
		card.custom_minimum_size = Vector2(150, 190)
		card.focus_mode = Control.FOCUS_NONE
		card.tooltip_text = "%s\n%s • Tehlike %s • Can %d • ZS %d\n%s" % [d["name"], Lore.SIZES[d["size"]]["name"], d["cr"], d["hp"], d["ac"], d["attacks"]]
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 6
		v.offset_right = -6
		v.offset_top = 6
		card.add_child(v)
		if not _looks.has(k):
			_looks[k] = Lore.new_creature(k)["look"]
		var pr := PortraitRect.new(_looks[k], 132, 256)
		pr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(pr)
		var l := Label.new()
		l.text = d["name"]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.clip_text = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		var l2 := Label.new()
		l2.text = "Tehlike %s" % d["cr"]
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.add_theme_font_size_override("font_size", 12)
		l2.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
		l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l2)
		var sp: String = k
		card.pressed.connect(func() -> void:
			picked.emit(sp)
			hide())
		_grid.add_child(card)
	_info.text = "  %d yaratık" % count
