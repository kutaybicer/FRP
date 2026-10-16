class_name InventoryPanel
extends HBoxContainer
## Karakter envanteri: 8 kuşanma yuvası + çanta + seçili eşyanın düzenleme paneli.
## Konumlar: "equip:<yuva>", "bag:<sıra>", "bag:new" (çantanın sonu), "tpl:<şablon>" (yeni eşya)

signal changed

const GOLD := Color("e0b85c")
# kuklanın yerleşimi (3 sütun): "" = boşluk
const DOLL := [["shoulders", "helmet", ""], ["weapon1", "chest", "weapon2"], ["gloves", "legs", ""], ["", "boots", ""]]

var ch: Dictionary = {}
var characters: Dictionary = {}
var _sel_id := ""
var _slots: Array = []
var _doll: GridContainer
var _bag: GridContainer
var _bag_info: Label
var _detail: VBoxContainer
var _picker: PopupPanel


func _init(character: Dictionary, chars: Dictionary) -> void:
	ch = character
	characters = chars
	Lore.ensure_inventory(ch)
	add_theme_constant_override("separation", 16)


func _ready() -> void:
	var left := VBoxContainer.new()
	add_child(left)
	left.add_child(_header("KUŞANILANLAR"))
	_doll = GridContainer.new()
	_doll.columns = 3
	_doll.add_theme_constant_override("h_separation", 6)
	_doll.add_theme_constant_override("v_separation", 4)
	left.add_child(_doll)
	var gold_row := HBoxContainer.new()
	left.add_child(gold_row)
	var gl := Label.new()
	gl.text = "Altın"
	gl.add_theme_color_override("font_color", GOLD)
	gold_row.add_child(gl)
	var gs := SpinBox.new()
	gs.max_value = 9999999
	gs.value = int(ch.get("gold", 0))
	gs.value_changed.connect(func(v: float) -> void:
		ch["gold"] = int(v)
		changed.emit())
	gold_row.add_child(gs)
	var hint := Label.new()
	hint.text = "Sürükle-bırak ile taşı.\nÇift / sağ tık: kuşan ya da çıkar."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	left.add_child(hint)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(mid)
	var top := HBoxContainer.new()
	mid.add_child(top)
	top.add_child(_header("ÇANTA"))
	_bag_info = Label.new()
	_bag_info.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	top.add_child(_bag_info)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var add := Button.new()
	add.text = "+ Eşya Ekle"
	add.focus_mode = Control.FOCUS_NONE
	add.pressed.connect(_open_picker)
	top.add_child(add)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(sc)
	_bag = GridContainer.new()
	_bag.columns = 4
	_bag.add_theme_constant_override("h_separation", 6)
	_bag.add_theme_constant_override("v_separation", 6)
	sc.add_child(_bag)

	var right_sc := ScrollContainer.new()
	right_sc.custom_minimum_size.x = 300
	right_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(right_sc)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_sc.add_child(_detail)

	_build_picker()
	_rebuild()


# =============================================================== veri

func get_item(loc: String) -> Dictionary:
	if loc.begins_with("equip:"):
		return ch["equipment"].get(loc.substr(6), {})
	if loc.begins_with("bag:"):
		var i := loc.substr(4).to_int()
		if loc != "bag:new" and i >= 0 and i < ch["bag"].size():
			return ch["bag"][i]
	return {}


func _find(id: String) -> String:
	for k in ch["equipment"]:
		if ch["equipment"][k].get("id", "") == id:
			return "equip:" + k
	for i in ch["bag"].size():
		if ch["bag"][i].get("id", "") == id:
			return "bag:%d" % i
	return ""


func _take(loc: String) -> Dictionary:
	var it := get_item(loc)
	if loc.begins_with("equip:"):
		ch["equipment"][loc.substr(6)] = {}
	elif loc.begins_with("bag:") and not it.is_empty():
		ch["bag"].remove_at(loc.substr(4).to_int())
	return it


func can_move(from: String, to: String) -> bool:
	if from == to or from == "" or to == "":
		return false
	var it := get_item(from)
	if it.is_empty():
		return false
	if to.begins_with("equip:"):
		if not Lore.slot_accepts(to.substr(6), it):
			return false
		var target := get_item(to)
		if not target.is_empty() and from.begins_with("equip:"):
			return Lore.slot_accepts(from.substr(6), target)
	return true


func move_item(from: String, to: String) -> void:
	if not can_move(from, to):
		return
	var it := get_item(from)
	var target := get_item(to)
	if to.begins_with("equip:"):
		var slot := to.substr(6)
		if from.begins_with("equip:"):
			ch["equipment"][from.substr(6)] = target
			ch["equipment"][slot] = it
		else:
			var idx := from.substr(4).to_int()
			if target.is_empty():
				ch["bag"].remove_at(idx)
			else:
				ch["bag"][idx] = target
			ch["equipment"][slot] = it
	else:
		# çantaya
		if from.begins_with("equip:"):
			ch["equipment"][from.substr(6)] = {}
			if to == "bag:new" or target.is_empty():
				ch["bag"].append(it)
			else:
				ch["bag"].insert(to.substr(4).to_int(), it)
		else:
			var fi := from.substr(4).to_int()
			ch["bag"].remove_at(fi)
			if to == "bag:new" or target.is_empty():
				ch["bag"].append(it)
			else:
				var ti := to.substr(4).to_int()
				ch["bag"].insert(mini(ti, ch["bag"].size()), it)
	_sel_id = str(it.get("id", ""))
	changed.emit()
	_rebuild()


## Çift tık / sağ tık: çantadaysa kuşan, kuşanılmışsa çantaya koy
func quick_move(loc: String) -> void:
	var it := get_item(loc)
	if it.is_empty():
		return
	if loc.begins_with("equip:"):
		move_item(loc, "bag:new")
		return
	var t: Dictionary = Lore.item_templates.get(it.get("template", "custom"), {})
	var want := str(t.get("slot", ""))
	if want == "":
		select_location(loc)
		return
	var target := ""
	if want == "weapon":
		if ch["equipment"]["weapon1"].is_empty():
			target = "equip:weapon1"
		elif ch["equipment"]["weapon2"].is_empty():
			target = "equip:weapon2"
		else:
			target = "equip:weapon1"
	else:
		target = "equip:" + want
	move_item(loc, target)


func select_location(loc: String) -> void:
	if loc.begins_with("tpl:"):
		_add_item(loc.substr(4))
		return
	var it := get_item(loc)
	_sel_id = str(it.get("id", ""))
	for s in _slots:
		s.selected = s.item.get("id", "-") == _sel_id
		s.queue_redraw()
	_build_detail()


func _add_item(template: String) -> void:
	if _picker:
		_picker.hide()
	var it := Lore.new_item(template)
	ch["bag"].append(it)
	_sel_id = it["id"]
	changed.emit()
	_rebuild()


# =============================================================== arayüz

func _rebuild() -> void:
	_slots.clear()
	for c in _doll.get_children():
		_doll.remove_child(c)
		c.queue_free()
	for row in DOLL:
		for slot in row:
			if slot == "":
				var e := Control.new()
				e.custom_minimum_size = Vector2(74, 74)
				_doll.add_child(e)
				continue
			var sd: Dictionary = Lore.SLOTS[slot]
			var s := ItemSlot.new(self, "equip:" + slot, ch["equipment"][slot], sd["icon"], _short(sd["name"]), 74)
			_doll.add_child(s)
			_slots.append(s)
	for c in _bag.get_children():
		_bag.remove_child(c)
		c.queue_free()
	for i in ch["bag"].size():
		var s := ItemSlot.new(self, "bag:%d" % i, ch["bag"][i], "", "", 70)
		_bag.add_child(s)
		_slots.append(s)
	var free := ItemSlot.new(self, "bag:new", {}, "", "", 70)
	free.tooltip_text = "Buraya bırak: çantaya koy"
	_bag.add_child(free)
	var total := 0
	for it in ch["bag"]:
		total += int(it.get("qty", 1))
	_bag_info.text = "  %d eşya" % total
	for s in _slots:
		s.selected = s.item.get("id", "-") == _sel_id and _sel_id != ""
	_build_detail()


func _short(n: String) -> String:
	return n.replace(" (Ana El)", "").replace(" (Yan El)", "")


func _build_detail() -> void:
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	var loc := _find(_sel_id) if _sel_id != "" else ""
	if loc == "":
		_detail.add_child(_header("EŞYA"))
		var l := Label.new()
		l.text = "Düzenlemek için bir eşyaya tıkla ya da \"+ Eşya Ekle\" ile yenisini oluştur.\n\nHer eşyanın adını, adedini, nadirliğini, rengini, ikonunu ve özellik metnini istediğin gibi yazabilirsin."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
		_detail.add_child(l)
		return
	var it := get_item(loc)
	var big := ItemSlot.new(self, "", it, "", "", 110)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_detail.add_child(big)
	var where: String = "Kuşanılmış: " + Lore.SLOTS[loc.substr(6)]["name"] if loc.begins_with("equip:") else "Çantada"
	_detail.add_child(_small(where))
	_detail.add_child(_small("Ad"))
	var ne := LineEdit.new()
	ne.text = str(it.get("name", ""))
	ne.text_changed.connect(func(t: String) -> void:
		it["name"] = t
		_touch(it))
	_detail.add_child(ne)

	var tmpl := {}
	for k in Lore.item_templates:
		tmpl[k] = Lore.item_templates[k]["name"]
	_detail.add_child(_small("Tür (şablon)"))
	_detail.add_child(_option(tmpl, str(it.get("template", "custom")), func(k: String) -> void:
		var old: Dictionary = Lore.item_templates.get(it.get("template", "custom"), {})
		var nt: Dictionary = Lore.item_templates[k]
		if it.get("name", "") == old.get("name", "") or it.get("name", "") == "":
			it["name"] = nt["name"]
		if str(it.get("text", "")).strip_edges() == "" or it.get("text", "") == old.get("text", ""):
			it["text"] = nt["text"]
		if it.get("icon", "") == it.get("template", ""):
			it["icon"] = k
		it["template"] = k
		# artık bu yuvaya uymuyorsa çantaya al
		var cur := _find(it["id"])
		if cur.begins_with("equip:") and not Lore.slot_accepts(cur.substr(6), it):
			ch["equipment"][cur.substr(6)] = {}
			ch["bag"].append(it)
		changed.emit()
		_rebuild()))
	_detail.add_child(_small("İkon"))
	_detail.add_child(_option(tmpl, str(it.get("icon", it.get("template", "custom"))), func(k: String) -> void:
		it["icon"] = k
		_touch(it, true)))
	var rar := {}
	for k in Lore.RARITIES:
		rar[k] = Lore.RARITIES[k]["name"]
	_detail.add_child(_small("Nadirlik"))
	_detail.add_child(_option(rar, str(it.get("rarity", "common")), func(k: String) -> void:
		it["rarity"] = k
		_touch(it, true)))
	var row := HBoxContainer.new()
	_detail.add_child(row)
	var ql := _small("Adet")
	row.add_child(ql)
	var qs := SpinBox.new()
	qs.min_value = 1
	qs.max_value = 9999
	qs.value = int(it.get("qty", 1))
	qs.value_changed.connect(func(v: float) -> void:
		it["qty"] = int(v)
		_touch(it, true))
	row.add_child(qs)
	row = HBoxContainer.new()
	_detail.add_child(row)
	row.add_child(_small("Renk"))
	var cp := ColorPickerButton.new()
	cp.custom_minimum_size = Vector2(44, 26)
	var tv = it.get("tint", null)
	cp.color = tv if tv is Color else Color(0.5, 0.5, 0.5)
	cp.color_changed.connect(func(c: Color) -> void:
		it["tint"] = c
		_touch(it, true))
	row.add_child(cp)
	var reset := Button.new()
	reset.text = "Varsayılan"
	reset.focus_mode = Control.FOCUS_NONE
	reset.tooltip_text = "Orijinal rengi kullan"
	reset.pressed.connect(func() -> void:
		it["tint"] = null
		_touch(it, true)
		_build_detail())
	row.add_child(reset)
	_detail.add_child(_small("Özellikler (serbest metin)"))
	var te := TextEdit.new()
	te.text = str(it.get("text", ""))
	te.custom_minimum_size.y = 150
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.placeholder_text = "ör. Hasar: 1d8 kesici\n+1 büyülü, ateşe karşı direnç..."
	te.text_changed.connect(func() -> void:
		it["text"] = te.text
		_touch(it))
	_detail.add_child(te)

	var btns := HBoxContainer.new()
	_detail.add_child(btns)
	var t: Dictionary = Lore.item_templates.get(it.get("template", "custom"), {})
	if loc.begins_with("equip:"):
		btns.add_child(_btn("Çıkar", func() -> void: move_item(loc, "bag:new")))
	elif str(t.get("slot", "")) != "":
		btns.add_child(_btn("Kuşan", func() -> void: quick_move(loc)))
	btns.add_child(_btn("Kopyala", func() -> void:
		var copy: Dictionary = it.duplicate(true)
		copy["id"] = Lore.new_item("custom")["id"]
		ch["bag"].append(copy)
		_sel_id = copy["id"]
		changed.emit()
		_rebuild()))
	var del := _btn("Sil", func() -> void:
		_take(_find(it["id"]))
		_sel_id = ""
		changed.emit()
		_rebuild())
	del.add_theme_color_override("font_color", Color("ff8a7a"))
	btns.add_child(del)

	# başka karaktere ver
	var others := {}
	for id in characters:
		if characters[id] != ch:
			others[id] = str(characters[id].get("name", "?"))
	if not others.is_empty():
		_detail.add_child(_small("Başka karaktere ver"))
		var grow := HBoxContainer.new()
		_detail.add_child(grow)
		var keys := others.keys()
		var o := OptionButton.new()
		o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		o.clip_text = true
		for k in keys:
			o.add_item(others[k])
		grow.add_child(o)
		grow.add_child(_btn("Ver", func() -> void:
			var other: Dictionary = characters[keys[o.selected]]
			Lore.ensure_inventory(other)
			var moved := _take(_find(it["id"]))
			other["bag"].append(moved)
			_sel_id = ""
			changed.emit()
			_rebuild()))


## Metin değişince: ilgili kutunun ipucunu/çizimini güncelle (paneli yeniden kurmadan)
func _touch(it: Dictionary, redraw_detail := false) -> void:
	for s in _slots:
		if s.item.get("id", "") == it.get("id", "-"):
			s._update_tooltip()
			s.queue_redraw()
	if redraw_detail and _detail.get_child_count() > 0:
		_detail.get_child(0).queue_redraw()
	var total := 0
	for b in ch["bag"]:
		total += int(b.get("qty", 1))
	_bag_info.text = "  %d eşya" % total
	changed.emit()


func _build_picker() -> void:
	_picker = PopupPanel.new()
	add_child(_picker)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(620, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_picker.add_child(sc)
	var box := VBoxContainer.new()
	sc.add_child(box)
	for cat in Lore.ITEM_CATS:
		box.add_child(_header(Lore.ITEM_CATS[cat].to_upper()))
		var g := GridContainer.new()
		g.columns = 7
		g.add_theme_constant_override("h_separation", 6)
		box.add_child(g)
		for k in Lore.item_templates:
			if Lore.item_templates[k]["cat"] != cat:
				continue
			var s := ItemSlot.new(self, "tpl:" + k, Lore.new_item(k), "", Lore.item_templates[k]["name"], 70)
			s.custom_minimum_size = Vector2(82, 88)
			s.tooltip_text = Lore.item_templates[k]["name"] + "\n" + Lore.item_templates[k]["text"]
			g.add_child(s)


func _open_picker() -> void:
	_picker.popup_centered()


# =============================================================== küçük yardımcılar

func _header(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_font_size_override("font_size", 15)
	return l


func _small(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	l.add_theme_font_size_override("font_size", 13)
	return l


func _btn(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func _option(items: Dictionary, current: String, cb: Callable) -> OptionButton:
	var o := OptionButton.new()
	var keys := items.keys()
	for k in keys:
		o.add_item(str(items[k]))
	o.selected = maxi(0, keys.find(current))
	o.item_selected.connect(func(i: int) -> void: cb.call(str(keys[i])))
	return o
