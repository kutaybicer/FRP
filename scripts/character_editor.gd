class_name CharacterEditor
extends Window
## Karakter / yaratık kartı: kimlik, görünüm, istatistikler, notlar.
## Değişiklikler doğrudan karakter sözlüğüne yazılır ve "changed" sinyali yayılır.

signal changed(id: String)
signal place_requested(id: String)
signal duplicate_requested(id: String)
signal delete_requested(id: String)

const GOLD := Color("e0b85c")
const COLOR_KEYS := {"skin": "Ten", "hair_color": "Saç / Tüy", "eye_color": "Göz", "cloth": "Kıyafet", "accent": "Süsleme / Kürk",
		"bg": "Arka Plan", "mark_color": "İşaret / Dövme", "horn_color": "Boynuz"}
const CREATURE_COLOR_KEYS := {"col": "Ana Renk", "col2": "İkinci Renk", "bg": "Arka Plan"}

var ch: Dictionary = {}
var _portrait: PortraitRect
var _title: Label
var _tabs: TabContainer
var _refresh_timer: Timer
var _stat_labels := {}
var _derived: Label


func _init() -> void:
	title = "Karakter Kartı"
	size = Vector2i(1120, 740)
	min_size = Vector2i(900, 600)
	transient = true
	wrap_controls = false
	visible = false
	close_requested.connect(hide)


func _ready() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.085)
	sb.set_content_margin_all(12)
	bg.add_theme_stylebox_override("panel", sb)
	add_child(bg)
	var root := VBoxContainer.new()
	bg.add_child(root)
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 14)
	root.add_child(main)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 340
	main.add_child(left)
	_portrait = PortraitRect.new({}, 330, 512)
	left.add_child(_portrait)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", Defs.font_title)
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", GOLD)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_title)
	var sub := Label.new()
	sub.name = "Sub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	left.add_child(sub)
	var rnd := HBoxContainer.new()
	rnd.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(rnd)
	rnd.add_child(_btn("Rastgele Görünüm", _random_look))
	rnd.add_child(_btn("Rastgele İsim", _random_name))
	var rnd2 := HBoxContainer.new()
	rnd2.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(rnd2)
	rnd2.add_child(_btn("Her Şeyi Rastgele", _random_all))

	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(_tabs)

	var bottom := HBoxContainer.new()
	root.add_child(bottom)
	bottom.add_child(_btn("Haritaya Yerleştir", func() -> void: place_requested.emit(ch["id"])))
	bottom.add_child(_btn("Kopyasını Oluştur", func() -> void: duplicate_requested.emit(ch["id"])))
	var del := _btn("Sil", func() -> void: delete_requested.emit(ch["id"]))
	del.add_theme_color_override("font_color", Color("ff8a7a"))
	bottom.add_child(del)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(sp)
	bottom.add_child(_btn("Kapat", hide))

	_refresh_timer = Timer.new()
	_refresh_timer.one_shot = true
	_refresh_timer.wait_time = 0.12
	_refresh_timer.timeout.connect(func() -> void: _portrait.set_look(ch["look"]))
	add_child(_refresh_timer)


func open(character: Dictionary) -> void:
	ch = character
	_rebuild()
	if not visible:
		popup_centered()
	grab_focus()


func _changed(look_changed := false) -> void:
	_update_header()
	if look_changed:
		_refresh_timer.start()
	changed.emit(ch.get("id", ""))


func _update_header() -> void:
	_title.text = str(ch.get("name", ""))
	var sub: Label = _title.get_parent().get_node("Sub")
	sub.text = Lore.describe(ch) + "  •  " + Lore.ROLES.get(ch.get("role", "pc"), "")
	title = "Karakter Kartı — " + str(ch.get("name", ""))


func _rebuild() -> void:
	var cur := _tabs.current_tab
	for c in _tabs.get_children():
		_tabs.remove_child(c)
		c.queue_free()
	_portrait.set_look(ch["look"])
	_update_header()
	_tab_identity()
	_tab_look()
	_tab_stats()
	_tab_notes()
	_tabs.current_tab = clampi(cur, 0, _tabs.get_tab_count() - 1)


func _is_creature() -> bool:
	return ch.get("kind", "") == "creature"


func _is_bust() -> bool:
	return str(ch["look"].get("body", "bust")) == "bust"


# =============================================================== sekmeler

func _page(title_text: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(sc)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, title_text)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	sc.add_child(box)
	return box


func _grid(box: Control, cols := 2) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 6)
	box.add_child(g)
	return g


func _row(g: GridContainer, label: String, ctrl: Control) -> void:
	var l := Label.new()
	l.text = label
	l.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	g.add_child(l)
	ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(ctrl)


func _tab_identity() -> void:
	var box := _page("Kimlik")
	var g := _grid(box)
	var name_row := HBoxContainer.new()
	var ne := LineEdit.new()
	ne.text = str(ch.get("name", ""))
	ne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ne.text_changed.connect(func(t: String) -> void:
		ch["name"] = t
		_changed())
	name_row.add_child(ne)
	name_row.add_child(_btn("Zar", func() -> void:
		_random_name()
		ne.text = ch["name"]))
	_row(g, "Ad", name_row)

	if _is_creature():
		var sp: Dictionary = Lore.creatures.get(ch.get("species", ""), {})
		var l := Label.new()
		l.text = "%s  (%s)" % [sp.get("name", "?"), sp.get("cat", "")]
		_row(g, "Yaratık türü", l)
	else:
		_row(g, "Rol", _option(Lore.ROLES, ch.get("role", "pc"), func(k: String) -> void:
			ch["role"] = k
			_changed(), ["pc", "npc"]))
		var pl := LineEdit.new()
		pl.text = str(ch.get("player", ""))
		pl.placeholder_text = "Bu karakteri oynayan kişi"
		pl.text_changed.connect(func(t: String) -> void: ch["player"] = t)
		_row(g, "Oyuncu", pl)
		var races := {}
		for k in Lore.races:
			races[k] = Lore.races[k]["name"]
		_row(g, "Irk", _option(races, ch.get("race", "human"), func(k: String) -> void:
			ch["race"] = k
			_apply_race_look(k)
			Lore.recalc(ch)
			_changed(true)
			_rebuild()))
		var classes := {}
		for k in Lore.classes:
			classes[k] = Lore.classes[k]["name"] + ("  (NPC)" if Lore.classes[k].get("npc", false) else "")
		_row(g, "Sınıf", _option(classes, ch.get("class", "fighter"), func(k: String) -> void:
			ch["class"] = k
			_apply_class_look(k)
			Lore.recalc(ch)
			_changed(true)
			_rebuild()))
		_row(g, "Seviye", _spin(1, 20, int(ch.get("level", 1)), func(v: float) -> void:
			ch["level"] = int(v)
			Lore.recalc(ch)
			_changed()
			_refresh_derived()))
	var al := {}
	for a in Lore.ALIGNMENTS:
		al[a] = a
	_row(g, "Yönelim", _option(al, ch.get("alignment", "Tam Tarafsız"), func(k: String) -> void: ch["alignment"] = k))
	_row(g, "Taraf (jeton rengi)", _option(Lore.DISPOSITIONS, ch.get("disposition", "neutral"), func(k: String) -> void:
		ch["disposition"] = k
		_changed()))
	var sizes := {}
	for k in Lore.SIZE_ORDER:
		sizes[k] = Lore.SIZES[k]["name"]
	_row(g, "Boyut", _option(sizes, ch.get("size", "medium"), func(k: String) -> void:
		ch["size"] = k
		_changed()))
	var bgl := LineEdit.new()
	bgl.text = str(ch.get("background", ""))
	bgl.placeholder_text = "Asker, soylu, yetim, tapınak hizmetkârı..."
	bgl.text_changed.connect(func(t: String) -> void: ch["background"] = t)
	_row(g, "Geçmiş", bgl)

	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	if _is_creature():
		var sp: Dictionary = Lore.creatures.get(ch.get("species", ""), {})
		desc.text = "Saldırılar: " + str(ch.get("attacks", sp.get("attacks", "")))
	else:
		var r: Dictionary = Lore.races.get(ch.get("race", ""), {})
		var bonus := []
		for s in r.get("bonus", {}):
			bonus.append("%s +%d" % [Lore.STAT_SHORT[s], r["bonus"][s]])
		desc.text = "%s\nIrk bonusu: %s  •  Hız: %s m" % [r.get("desc", ""), ", ".join(bonus), str(r.get("speed", 9))]
	box.add_child(HSeparator.new())
	box.add_child(desc)


func _tab_look() -> void:
	var box := _page("Görünüm")
	var L: Dictionary = ch["look"]
	if not _is_bust():
		var info := Label.new()
		info.text = "Bu yaratığın çizimi türüne göre otomatik yapılır. Renklerini değiştirebilirsin."
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(info)
		var g := _grid(box, 4)
		for k in CREATURE_COLOR_KEYS:
			_color_row(g, CREATURE_COLOR_KEYS[k], L, k)
		return
	var g := _grid(box, 4)
	var names := {"head": "Kafa", "face": "Yüz", "ears": "Kulak", "hair": "Saç", "beard": "Sakal", "horns": "Boynuz",
			"marks": "İşaretler", "helm": "Başlık", "outfit": "Kıyafet", "item": "Eşya / Silah", "wings": "Kanat"}
	for k in names:
		var key: String = k
		_row(g, names[k], _option(Lore.LOOK_OPTIONS[k], str(L.get(k, "")), func(v: String) -> void:
			L[key] = v
			_changed(true)))
	box.add_child(HSeparator.new())
	var checks := HBoxContainer.new()
	box.add_child(checks)
	for k in {"tusks": "Dişler", "glow_eyes": "Parlayan Gözler", "halo": "Hale", "ghost": "Hayalet"}.keys():
		var key: String = k
		var c := CheckBox.new()
		c.text = {"tusks": "Azı Dişleri", "glow_eyes": "Parlayan Gözler", "halo": "Hale", "ghost": "Hayaletimsi"}[k]
		c.button_pressed = bool(L.get(k, false))
		c.toggled.connect(func(on: bool) -> void:
			L[key] = on
			_changed(true))
		checks.add_child(c)
	var sl := _grid(box, 4)
	_slider_row(sl, "Yapı (zayıf → iri)", L, "build", 0.7, 1.5)
	_slider_row(sl, "Kafa boyu", L, "head_size", 0.8, 1.25)
	_slider_row(sl, "Kaş (sakin → sert)", L, "brow", 0.0, 0.7)
	box.add_child(HSeparator.new())
	var cg := _grid(box, 4)
	for k in COLOR_KEYS:
		_color_row(cg, COLOR_KEYS[k], L, k)


func _tab_stats() -> void:
	var box := _page("İstatistikler")
	var g := _grid(box, 5)
	for h in ["Yetenek", "Puan", "Irk", "Toplam", "Değiştirici"]:
		var l := Label.new()
		l.text = h
		l.add_theme_color_override("font_color", GOLD)
		g.add_child(l)
	_stat_labels.clear()
	for s in Lore.STATS:
		var key: String = s
		var l := Label.new()
		l.text = Lore.STAT_NAMES[s]
		g.add_child(l)
		var sp := _spin(1, 30, int(ch["stats"].get(s, 10)), func(v: float) -> void:
			ch["stats"][key] = int(v)
			_refresh_derived()
			_changed())
		g.add_child(sp)
		var bonus := 0
		if not _is_creature():
			bonus = int(Lore.races.get(ch.get("race", ""), {}).get("bonus", {}).get(s, 0))
		var bl := Label.new()
		bl.text = ("+%d" % bonus) if bonus > 0 else "—"
		g.add_child(bl)
		var tl := Label.new()
		g.add_child(tl)
		var ml := Label.new()
		ml.add_theme_color_override("font_color", GOLD)
		ml.add_theme_font_size_override("font_size", 18)
		g.add_child(ml)
		_stat_labels[s] = [tl, ml]
	var btns := HBoxContainer.new()
	box.add_child(btns)
	if not _is_creature():
		btns.add_child(_btn("4d6 At (zar)", func() -> void:
			Lore.roll_stats(ch)
			_changed()
			_rebuild()))
		btns.add_child(_btn("Standart Dizi", func() -> void:
			Lore.apply_standard_array(ch)
			_changed()
			_rebuild()))
		btns.add_child(_btn("Can / ZS Yeniden Hesapla", func() -> void:
			Lore.recalc(ch)
			_changed()
			_rebuild()))
	box.add_child(HSeparator.new())
	var g2 := _grid(box, 4)
	_row(g2, "Can (şu an)", _spin(-50, 2000, int(ch.get("hp", 1)), func(v: float) -> void:
		ch["hp"] = int(v)
		_changed()))
	_row(g2, "Can (en fazla)", _spin(1, 2000, int(ch.get("hp_max", 1)), func(v: float) -> void:
		ch["hp_max"] = int(v)
		_changed()))
	_row(g2, "Zırh Sınıfı (ZS)", _spin(0, 40, int(ch.get("ac", 10)), func(v: float) -> void:
		ch["ac"] = int(v)
		_changed()))
	var spd := SpinBox.new()
	spd.min_value = 0
	spd.max_value = 60
	spd.step = 1.5
	spd.value = float(ch.get("speed", 9))
	spd.suffix = "m"
	spd.value_changed.connect(func(v: float) -> void: ch["speed"] = v)
	_row(g2, "Hız", spd)
	if _is_creature():
		var cr := LineEdit.new()
		cr.text = str(ch.get("cr", ""))
		cr.text_changed.connect(func(t: String) -> void:
			ch["cr"] = t
			_changed())
		_row(g2, "Tehlike Derecesi", cr)
	else:
		_row(g2, "Tecrübe (XP)", _spin(0, 999999, int(ch.get("xp", 0)), func(v: float) -> void: ch["xp"] = int(v)))
		_row(g2, "Altın", _spin(0, 9999999, int(ch.get("gold", 0)), func(v: float) -> void: ch["gold"] = int(v)))
	_derived = Label.new()
	_derived.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	box.add_child(_derived)
	if _is_creature():
		box.add_child(_small("Saldırılar ve yetenekler"))
		box.add_child(_text_edit(str(ch.get("attacks", "")), func(t: String) -> void: ch["attacks"] = t))
	_refresh_derived()


func _tab_notes() -> void:
	var box := _page("Notlar")
	box.add_child(_small("Kişilik, idealler, bağlar, kusurlar"))
	box.add_child(_text_edit(str(ch.get("personality", "")), func(t: String) -> void: ch["personality"] = t))
	box.add_child(_small("DM notları (sırlar, hikâyedeki yeri, ilişkiler)"))
	var te := _text_edit(str(ch.get("notes", "")), func(t: String) -> void: ch["notes"] = t)
	te.custom_minimum_size.y = 220
	box.add_child(te)


func _refresh_derived() -> void:
	for s in _stat_labels:
		var total := Lore.total_stat(ch, s)
		_stat_labels[s][0].text = str(total)
		_stat_labels[s][1].text = Lore.mod_text(total)
	if _derived:
		var dex := Lore.modifier(Lore.total_stat(ch, "dex"))
		var wis := Lore.modifier(Lore.total_stat(ch, "wis"))
		var txt := "İnisiyatif: %s   •   Pasif Algı: %d" % [("+%d" % dex) if dex >= 0 else str(dex), 10 + wis]
		if not _is_creature():
			txt += "   •   Yetkinlik Bonusu: +%d" % Lore.proficiency(int(ch.get("level", 1)))
		_derived.text = txt


# =============================================================== rastgele

func _random_look() -> void:
	if _is_creature():
		var fresh := Lore.new_creature(ch["species"])
		ch["look"] = fresh["look"]
	else:
		ch["look"] = Lore.random_look(ch.get("race", "human"), ch.get("class", "fighter"))
	_changed(true)
	_rebuild()


func _random_name() -> void:
	if _is_creature():
		ch["name"] = Lore.creatures[ch["species"]]["name"] + " " + Defs.random_name()
	else:
		ch["name"] = Lore.random_name(ch.get("race", "human"))
	_changed()
	_update_header()


func _random_all() -> void:
	if _is_creature():
		_random_look()
		return
	var pcs := []
	for k in Lore.classes:
		if not Lore.classes[k].get("npc", false) or ch.get("role", "") == "npc":
			pcs.append(k)
	ch["race"] = Lore.races.keys().pick_random()
	ch["class"] = pcs.pick_random()
	ch["name"] = Lore.random_name(ch["race"])
	ch["look"] = Lore.random_look(ch["race"], ch["class"])
	ch["alignment"] = Lore.ALIGNMENTS.pick_random()
	Lore.roll_stats(ch)
	_changed(true)
	_rebuild()


## Irk değişince ırka özgü görünümü uygula (kıyafet ve renkler korunur)
func _apply_race_look(race_id: String) -> void:
	var fresh := Lore.random_look(race_id, ch.get("class", "fighter"))
	var L: Dictionary = ch["look"]
	for k in ["head", "face", "ears", "horns", "tusks", "marks", "glow_eyes", "halo", "wings", "nose", "brow", "build",
			"head_size", "skin", "hair_color", "eye_color", "hair", "beard", "mark_color", "horn_color"]:
		L[k] = fresh.get(k, Lore.base_look.get(k))


func _apply_class_look(class_id: String) -> void:
	var fresh := Lore.random_look(ch.get("race", "human"), class_id)
	var L: Dictionary = ch["look"]
	for k in ["outfit", "item", "cloth", "accent", "bg", "helm"]:
		L[k] = fresh[k]


# =============================================================== küçük yardımcılar

func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	return l


func _option(items: Dictionary, current: String, cb: Callable, only: Array = []) -> OptionButton:
	var o := OptionButton.new()
	var keys: Array = []
	for k in items:
		if only.is_empty() or k in only:
			keys.append(k)
			o.add_item(str(items[k]))
	o.selected = maxi(0, keys.find(current))
	o.item_selected.connect(func(i: int) -> void: cb.call(str(keys[i])))
	return o


func _spin(lo: float, hi: float, v: float, cb: Callable) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.value = v
	s.value_changed.connect(cb)
	return s


func _text_edit(text: String, cb: Callable) -> TextEdit:
	var t := TextEdit.new()
	t.text = text
	t.custom_minimum_size.y = 140
	t.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	t.text_changed.connect(func() -> void: cb.call(t.text))
	return t


func _color_row(g: GridContainer, label: String, L: Dictionary, key: String) -> void:
	var cp := ColorPickerButton.new()
	var v = L.get(key, Color.WHITE)
	cp.color = v if v is Color else Color(str(v))
	cp.custom_minimum_size = Vector2(80, 28)
	cp.edit_alpha = false
	cp.color_changed.connect(func(c: Color) -> void:
		L[key] = c
		_changed(true))
	_row(g, label, cp)


func _slider_row(g: GridContainer, label: String, L: Dictionary, key: String, lo: float, hi: float) -> void:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = float(L.get(key, lo))
	s.custom_minimum_size.x = 120
	s.value_changed.connect(func(v: float) -> void:
		L[key] = v
		_changed(true))
	_row(g, label, s)
