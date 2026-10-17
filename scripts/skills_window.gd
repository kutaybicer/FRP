class_name SkillsWindow
extends Window
## Yetenek kütüphanesi: oyundaki tüm yetenekler. Ada / açıklamaya göre arama, kategori ve tür süzgeci.
## Seçili yetenek, seçilen karakterin yetenek defterine eklenir (çift tık ya da düğme).

signal add_requested(char_id: String, skill: Dictionary)

const GOLD := Color("e0b85c")

var characters: Dictionary = {}
var _search: LineEdit
var _cat: OptionButton
var _type: OptionButton
var _list: ItemList
var _count: Label
var _who: OptionButton
var _d_name: Label
var _d_meta: Label
var _d_desc: RichTextLabel
var _add_btn: Button
var _shown: Array = []
var _sel: Dictionary = {}


func _init() -> void:
	title = "Yetenekler — Kütüphane"
	size = Vector2i(1060, 660)
	min_size = Vector2i(760, 480)
	visible = false
	transient = true
	exclusive = false
	wrap_controls = false
	close_requested.connect(hide)
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.085)
	sb.set_content_margin_all(12)
	bg.add_theme_stylebox_override("panel", sb)
	add_child(bg)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	bg.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	_search = LineEdit.new()
	_search.placeholder_text = "Yetenek ara (ör. ateş, kılıç, ölü, hayvan, şifa...)"
	_search.clear_button_enabled = true
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_t: String) -> void: _refill())
	top.add_child(_search)
	_cat = OptionButton.new()
	_cat.add_item("Tüm kategoriler")
	for c in Skills.categories():
		_cat.add_item(c)
	_cat.item_selected.connect(func(_i: int) -> void: _refill())
	top.add_child(_cat)
	_type = OptionButton.new()
	_type.add_item("Tüm türler")
	for t in Skills.TYPES:
		_type.add_item(t)
	_type.item_selected.connect(func(_i: int) -> void: _refill())
	top.add_child(_type)

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 12)
	root.add_child(mid)
	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.size_flags_stretch_ratio = 1.1
	mid.add_child(lv)
	_count = Label.new()
	_count.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	lv.add_child(_count)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_select)
	_list.item_activated.connect(func(i: int) -> void:
		_on_select(i)
		_add())
	lv.add_child(_list)

	var rv := VBoxContainer.new()
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.add_theme_constant_override("separation", 8)
	mid.add_child(rv)
	_d_name = Label.new()
	_d_name.add_theme_font_override("font", Defs.font_title)
	_d_name.add_theme_font_size_override("font_size", 26)
	_d_name.add_theme_color_override("font_color", GOLD)
	_d_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(_d_name)
	_d_meta = Label.new()
	_d_meta.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	_d_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(_d_meta)
	_d_desc = RichTextLabel.new()
	_d_desc.bbcode_enabled = true
	_d_desc.fit_content = true
	_d_desc.add_theme_font_size_override("normal_font_size", 18)
	_d_desc.custom_minimum_size.y = 120
	rv.add_child(_d_desc)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(sp)
	var hint := Label.new()
	hint.text = "Eklenen yetenek karakterin defterine kopyalanır; orada adını ve açıklamasını dilediğin gibi değiştirebilirsin."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.6, 0.56, 0.48))
	hint.add_theme_font_size_override("font_size", 13)
	rv.add_child(hint)
	var wr := HBoxContainer.new()
	rv.add_child(wr)
	var wl := Label.new()
	wl.text = "Karakter:"
	wr.add_child(wl)
	_who = OptionButton.new()
	_who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_who.clip_text = true
	wr.add_child(_who)
	_add_btn = Button.new()
	_add_btn.text = "Yetenek Defterine Ekle  >"
	_add_btn.add_theme_color_override("font_color", GOLD)
	_add_btn.pressed.connect(_add)
	rv.add_child(_add_btn)
	_refill()


## target: önceden seçili gelecek karakter (boşsa son seçim kalır)
func open(target := "") -> void:
	_who.clear()
	var ids := characters.keys()
	for id in ids:
		var ch: Dictionary = characters[id]
		_who.add_item("%s  (%s)" % [ch.get("name", "?"), Lore.ROLES.get(ch.get("role", ""), "")])
		_who.set_item_metadata(_who.item_count - 1, id)
		if id == target:
			_who.selected = _who.item_count - 1
	if _who.item_count == 0:
		_who.add_item("(önce bir karakter oluştur)")
		_who.set_item_metadata(0, "")
	_update_add()
	if not visible:
		popup_centered()
	_search.grab_focus()


func _refill() -> void:
	var q := _search.text.strip_edges().to_lower()
	var cat := "" if _cat.selected <= 0 else _cat.get_item_text(_cat.selected)
	var typ := "" if _type.selected <= 0 else _type.get_item_text(_type.selected)
	_list.clear()
	_shown.clear()
	for s: Dictionary in Skills.all():
		if cat != "" and s["cat"] != cat:
			continue
		if typ != "" and s["type"] != typ:
			continue
		if q != "":
			var hay := (str(s["name"]) + " " + str(s["cat"]) + " " + str(s["tags"]) + " " + str(s["desc"])).to_lower()
			# önce ada göre; adda yoksa kategori, sınıf ve açıklamada da ara
			if not hay.contains(q):
				continue
		_shown.append(s)
	# adı aramayla başlayanlar en üste
	if q != "":
		_shown.sort_custom(func(a, b) -> bool:
			var an := str(a["name"]).to_lower()
			var bn := str(b["name"]).to_lower()
			var ar := 0 if an.begins_with(q) else (1 if an.contains(q) else 2)
			var br := 0 if bn.begins_with(q) else (1 if bn.contains(q) else 2)
			return ar < br if ar != br else an < bn)
	for s in _shown:
		_list.add_item("%s   —   %s  •  %s" % [s["name"], s["type"], s["cat"]])
	_count.text = "%d yetenek bulundu (toplam %d)" % [_shown.size(), Skills.all().size()]
	if not _shown.is_empty():
		_list.select(0)
		_on_select(0)
	else:
		_sel = {}
		_d_name.text = "Sonuç yok"
		_d_meta.text = ""
		_d_desc.text = "Başka bir kelime dene ya da süzgeçleri temizle."
	_update_add()


func _on_select(i: int) -> void:
	if i < 0 or i >= _shown.size():
		return
	_sel = _shown[i]
	_d_name.text = str(_sel["name"])
	_d_meta.text = "%s  •  %s%s" % [_sel["cat"], _sel["type"], ("\nUygun: " + str(_sel["tags"])) if str(_sel["tags"]) != "" else ""]
	_d_desc.text = str(_sel["desc"])
	_update_add()


func _update_add() -> void:
	_add_btn.disabled = _sel.is_empty() or _who.item_count == 0 or str(_who.get_item_metadata(maxi(0, _who.selected))) == ""


func _add() -> void:
	if _sel.is_empty() or _who.selected < 0:
		return
	var id := str(_who.get_item_metadata(_who.selected))
	if id == "":
		return
	add_requested.emit(id, _sel)
