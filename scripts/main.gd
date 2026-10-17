extends Node2D
## Ana sahne: kampanya, haritalar arası gezinme ve tüm arayüz (kodla kurulur).

const AUTOSAVE := "user://autosave.frp"
const T := MapView.Tool
const GOLD := Color("e0b85c")

var campaign: Campaign
var current: MapData
var view: MapView
var cam: CameraRig
var save_path := ""
var dirty := false

var ui: Control
var tool_grid: GridContainer
var tool_options: VBoxContainer
var inspector: VBoxContainer
var right_tabs: TabContainer
var char_list: VBoxContainer
var char_search: LineEdit
var char_filter := "all"
var editor: CharacterEditor
var bestiary: BestiaryWindow
var _chars_pending := false
var dice_tray: PanelContainer
var dice_count: SpinBox
var dice_mod: SpinBox
var dice_adv := 0
var dice_who: OptionButton
var dice_expr: LineEdit
var dice_history: VBoxContainer
var dice_overlay: DiceOverlay
var _roll_log: Array = []
var new_dialog: ConfirmationDialog
var move_btn: Button
var guide: GuideWindow
var nd_start: OptionButton
var nd_size: OptionButton
var nd_cols: SpinBox
var nd_rows: SpinBox
var nd_scale: SpinBox

const SIZE_PRESETS := [["Küçük", 120, 80], ["Orta", 200, 140], ["Büyük", 320, 220], ["Çok Büyük", 480, 320],
		["Devasa", 640, 440], ["Dev Kıta", 900, 620], ["Özel", 0, 0]]
const START_TYPES := ["Rastgele kıta (hazır arazi)", "Boş okyanus — anakarayı ben çizeceğim", "Boş kara (çayır)", "Boş parşömen (eskiz)"]
var breadcrumb: HBoxContainer
var map_tree: Tree
var campaign_name_edit: LineEdit
var status_label: Label
var hint_label: Label
var toast_label: Label
var mode_button: Button
var file_dialog: FileDialog
var confirm: ConfirmationDialog

var _dialog_purpose := ""
var _insp_pending := false
var _tree_building := false
var _toast_time := 0.0
var _gen_seed := 0

var tool_defs := [
	{"tool": T.SELECT, "name": "Seç", "key": KEY_V, "play": true},
	{"tool": T.TERRAIN, "name": "Arazi", "key": KEY_B},
	{"tool": T.FILL, "name": "Kova Dolgu", "key": KEY_G},
	{"tool": T.REGION, "name": "Krallık/Bölge", "key": KEY_R},
	{"tool": T.PATH, "name": "Nehir / Yol", "key": KEY_P},
	{"tool": T.SYMBOL, "name": "Sembol", "key": KEY_S},
	{"tool": T.LABEL, "name": "Yazı", "key": KEY_T},
	{"tool": T.FOG, "name": "Savaş Sisi", "key": KEY_F, "play": true},
	{"tool": T.MEASURE, "name": "Ölç", "key": KEY_M, "play": true},
	{"tool": T.ERASER, "name": "Silgi", "key": KEY_E},
	{"tool": T.PARTY, "name": "Grup Jetonu", "key": KEY_Q},
	{"tool": T.TOKEN, "name": "Karakter", "key": KEY_C, "play": true},
]


func _ready() -> void:
	randomize()
	_gen_seed = randi() % 1000000
	view = MapView.new()
	add_child(view)
	cam = CameraRig.new()
	add_child(cam)
	view.cam = cam
	view.selection_changed.connect(_refresh_inspector)
	view.request_enter.connect(_on_request_enter)
	view.map_changed.connect(_mark_dirty)
	view.hover_changed.connect(func(t: String) -> void: status_label.text = t)
	view.token_placed.connect(_on_token_placed)
	view.move_blocked.connect(func() -> void:
		_toast("Taşımak için Taşıma Modu'nu aç (sol panel ya da K tuşu)."))
	view.placement_cancelled.connect(func() -> void:
		_set_tool(T.SELECT)
		_toast("Yerleştirme iptal edildi."))
	_build_ui()

	var timer := Timer.new()
	timer.wait_time = 90.0
	timer.autostart = true
	timer.timeout.connect(_autosave)
	add_child(timer)

	if FileAccess.file_exists(AUTOSAVE) and _load_campaign(AUTOSAVE):
		save_path = ""
		_toast("Son oturum otomatik kayıttan yüklendi.")
	else:
		_new_campaign()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_autosave()


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			toast_label.text = ""


# =================================================================== kampanya / harita gezinme

## start: 0 rastgele kıta, 1 boş okyanus, 2 boş kara, 3 boş parşömen
func _new_campaign(start := 0, cols := 120, rows := 80, scale := 10.0) -> void:
	campaign = Campaign.new()
	Portraits.photos = campaign.photos
	view.characters = campaign.characters
	editor.characters = campaign.characters
	var world := campaign.create_map(Defs.Kind.WORLD, "Dünya Haritası")
	world.scale = scale
	var fill: int = [Defs.T.SEA, Defs.T.SEA, Defs.T.GRASS, Defs.T.PARCHMENT][clampi(start, 0, 3)]
	world.setup(cols, rows, fill)
	if start == 0:
		MapGenerator.generate_terrain(world, randi(), true)
	save_path = ""
	current = null
	view._history.clear()
	enter_map(world.id)
	dirty = false
	_update_title()


func _load_campaign(path: String) -> bool:
	var c := Campaign.load_from(path)
	if c == null or c.maps.is_empty():
		_toast("Dosya açılamadı: " + path)
		return false
	campaign = c
	Portraits.photos = campaign.photos
	view.characters = campaign.characters
	editor.characters = campaign.characters
	current = null
	view._history.clear()
	enter_map(campaign.root_id)
	dirty = false
	_update_title()
	return true


func enter_map(id: String) -> void:
	if not campaign.maps.has(id):
		return
	if current:
		current.has_view = true
		current.view_pos = cam.position
		current.view_zoom = cam.zoom.x
	current = campaign.maps[id]
	view.set_map(current)
	if current.has_view:
		cam.position = current.view_pos
		cam.zoom = Vector2.ONE * current.view_zoom
	else:
		_fit()
	# başka haritaya geçince fırça vb. araçlar elde kalmasın
	if view.tool != T.SELECT and tool_grid != null:
		_set_tool(T.SELECT)
	_refresh_breadcrumb()
	_refresh_tree()
	_rebuild_tool_options()
	_refresh_inspector()
	_refresh_characters()
	_update_title()


func _go_up() -> void:
	if current and campaign.maps.has(current.parent_id):
		enter_map(current.parent_id)


func _fit() -> void:
	cam.fit_rect(Rect2(Vector2.ZERO, current.pixel_size()), 0.8)


func _on_request_enter(sym: Dictionary) -> void:
	var link := str(sym.get("link", ""))
	if link != "" and campaign.maps.has(link):
		enter_map(link)
		return
	var type := str(sym["type"])
	if Defs.enter_kind(type, current.kind) >= 0:
		# kendiliğinden harita üretme: sağ panelde seçenek sun
		_refresh_inspector()
		_toast("Bu yerin içi henüz yok — sağ panelden \"Kendim Çizeceğim\" ya da \"Otomatik Oluştur\" seç.")
	else:
		_toast("Bu yerin içine girilemez (doğa alanları ve iç mekanlar tek katmanlıdır).")


## Sembolün iç haritasını oluşturur. auto=false: boş (kullanıcı çizer), true: türe uygun otomatik
func _create_child(sym: Dictionary, auto: bool) -> void:
	var type := str(sym["type"])
	var kind := Defs.enter_kind(type, current.kind)
	if kind < 0:
		return
	var nm := str(sym.get("name", ""))
	if nm == "":
		nm = Defs.symbol_name(type)
	view.record()
	var m := campaign.create_map(kind, nm, current.id)
	var sz := PlaceGenerator.size_for(type, kind)
	m.scale = sz["scale"]
	m.setup(sz["cols"], sz["rows"], Defs.KIND_DEFAULTS[kind]["fill"])
	if auto:
		_toast("Oluşturuluyor...")
		PlaceGenerator.generate(m, type)
	else:
		PlaceGenerator.blank(m, type)
	sym["link"] = m.id
	_mark_dirty()
	_toast("%s: %s (%s)" % ["Otomatik oluşturuldu" if auto else "Boş harita hazır, çizmeye başla", nm, Defs.KIND_NAMES[kind].to_lower()])
	enter_map(m.id)


## Alt harita yoksa: boş / otomatik seçimi (düzenleme ve oyun modunda ortak)
func _enter_choice(box: VBoxContainer, s: Dictionary) -> void:
	var type := str(s["type"])
	var kind := Defs.enter_kind(type, current.kind)
	if kind < 0:
		var why := _small("Bu yerin içine girilemez. Orman, dağ gibi doğa alanlarının ve binaların içi tek katmandır; " +
				"çok katmanlı giriş sadece yerleşimlerde vardır (Dünya → Şehir → Meyhane).")
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(why)
		return
	var info := _small("Bu yerin içi henüz yok. İçine girince açılacak %s haritasını nasıl oluşturalım?" % Defs.KIND_NAMES[kind].to_lower())
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	box.add_child(_btn("Kendim Çizeceğim  (boş harita)", func() -> void: _create_child(s, false),
			"Türüne uygun boş zemin açılır; içini sen çizersin"))
	var ab := _btn("Otomatik Oluştur  >", func() -> void: _create_child(s, true),
			"Türüne uygun hazır iç harita: şehirde sokaklar ve dükkanlar, meyhanede masalar ve tezgâh, ormanda açıklıklar ve patikalar")
	ab.add_theme_color_override("font_color", Color("ffd27a"))
	box.add_child(ab)


func _mark_dirty() -> void:
	if not dirty:
		dirty = true
		_update_title()


func _update_title() -> void:
	if campaign == null:
		return
	var t := "FRP Harita Ustası — %s" % campaign.name
	if current:
		t += " / " + current.name
	if dirty:
		t += " *"
	get_window().title = t


# =================================================================== kaydet / aç / dışa aktar

func _save() -> void:
	if save_path == "":
		_show_file_dialog("save", FileDialog.FILE_MODE_SAVE_FILE, "*.frp ; FRP Kampanyası", campaign.name + ".frp")
	else:
		_write(save_path)


func _write(path: String) -> void:
	var err := campaign.save_to(path)
	if err == OK:
		save_path = path
		dirty = false
		_update_title()
		_toast("Kaydedildi: " + path)
	else:
		_toast("Kaydedilemedi! Hata kodu: %d" % err)


func _autosave() -> void:
	if campaign:
		campaign.save_to(AUTOSAVE)


func _show_file_dialog(purpose: String, mode: int, filter: String, default_name := "") -> void:
	_dialog_purpose = purpose
	file_dialog.file_mode = mode
	file_dialog.filters = PackedStringArray([filter])
	if default_name != "":
		file_dialog.current_file = default_name.validate_filename()
	file_dialog.popup_centered(Vector2i(900, 560))


func _on_file_selected(path: String) -> void:
	match _dialog_purpose:
		"save":
			if not path.ends_with(".frp"):
				path += ".frp"
			_write(path)
		"open":
			if _load_campaign(path):
				save_path = path
				_toast("Açıldı: " + path)
		"png":
			if not path.ends_with(".png"):
				path += ".png"
			_export_png(path)


## Haritanın tamamını (kameradan bağımsız) tam çözünürlükte PNG olarak kaydeder.
func _export_png(path: String) -> void:
	var size := current.pixel_size()
	var s := minf(3.0, 8192.0 / maxf(size.x, size.y))   # 3x çözünürlük: baskıya uygun
	var sv := SubViewport.new()
	sv.size = Vector2i(size * s)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var v := MapView.new()
	sv.add_child(v)
	v.scale = Vector2(s, s)
	v.show_grid = view.show_grid
	v.show_names = view.show_names
	v.play_mode = view.play_mode
	v.characters = view.characters
	v.export_mode = true
	v.hd = view.hd
	v.parchment = view.parchment
	v.set_map(current)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	var err := img.save_png(path)
	sv.queue_free()
	_toast(("PNG kaydedildi: " + path) if err == OK else "PNG kaydedilemedi!")


func _ask(text: String, cb: Callable) -> void:
	for c in confirm.confirmed.get_connections():
		confirm.confirmed.disconnect(c["callable"])
	confirm.dialog_text = text
	confirm.confirmed.connect(cb, CONNECT_ONE_SHOT)
	confirm.popup_centered(Vector2i(420, 140))


func _toast(text: String) -> void:
	if toast_label:
		toast_label.text = text
		_toast_time = 4.0


# =================================================================== kısayollar

## Esc her yerde çalışsın: arayüzde bir düğme / kaydırıcı odaktayken de (yazı kutusu hariç)
## elindeki aracı (fırça, sembol, yol, jeton...) bırakır.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	var f := get_viewport().gui_get_focus_owner()
	if f is LineEdit or f is TextEdit or f is SpinBox:
		return
	if dice_overlay and dice_overlay.visible:
		return
	if f and f.get_window() != get_window():
		return   # açık bir pencere / diyalog Esc'yi kendisi kullansın
	for w in [guide, editor, bestiary, new_dialog]:
		if w != null and w.visible:
			return
	if view.tool == T.SELECT and view.selected_kind == "":
		return
	if f:
		f.release_focus()
	_escape()
	get_viewport().set_input_as_handled()


func _escape() -> void:
	# Esc: yerleştirmeyi iptal et / elindeki aracı bırak (Seç'e dön) / seçimi kaldır
	if view.tool == T.TOKEN and view.token_char != "":
		view.cancel_placement()
	elif view.tool != T.SELECT:
		_set_tool(T.SELECT)
		_toast("Araç bırakıldı (Seç).")
	else:
		view.clear_selection()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode
	if event.ctrl_pressed or event.meta_pressed:
		match k:
			KEY_Z:
				if event.shift_pressed:
					view.redo()
				else:
					view.undo()
			KEY_Y: view.redo()
			KEY_S: _save()
			KEY_O: _show_file_dialog("open", FileDialog.FILE_MODE_OPEN_FILE, "*.frp ; FRP Kampanyası")
			_: return
		get_viewport().set_input_as_handled()
		return
	match k:
		KEY_TAB: _set_play(not view.play_mode)
		KEY_DELETE: view.delete_selected()
		KEY_BACKSPACE: _go_up()
		KEY_ESCAPE: _escape()
		KEY_K: _set_move_mode(not view.move_mode)
		KEY_HOME: _fit()
		KEY_D: _toggle_dice_tray()
		KEY_F1: guide.open()
		KEY_H:
			view.show_grid = not view.show_grid
			view.redraw()
		KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
			view.brush_radius = clampi(view.brush_radius + (1 if k == KEY_BRACKETRIGHT else -1), 1, 40)
			_rebuild_tool_options()
			view.redraw()
		_:
			for d in tool_defs:
				if d["key"] == k and (not view.play_mode or d.get("play", false)):
					_set_tool(d["tool"])
					break
			return
	get_viewport().set_input_as_handled()


func _set_move_mode(on: bool) -> void:
	view.move_mode = on
	move_btn.set_pressed_no_signal(on)
	move_btn.text = "Taşıma Modu (K): AÇIK" if on else "Taşıma Modu (K): Kapalı"
	move_btn.add_theme_color_override("font_color", Color("ffd27a") if on else Color("c8bfae"))
	move_btn.add_theme_color_override("font_pressed_color", Color("ffd27a"))
	_toast("Taşıma modu açık: sürükleyerek taşı." if on else "Taşıma modu kapalı: nesneler yerinden oynamaz.")


func _set_tool(t: int) -> void:
	view.set_tool(t)
	for b in tool_grid.get_children():
		b.set_pressed_no_signal(b.get_meta("tool") == t)
	_rebuild_tool_options()


func _set_play(on: bool) -> void:
	view.play_mode = on
	mode_button.set_pressed_no_signal(on)
	mode_button.text = "MASA MODU (Tab)" if on else "DÜZENLEME MODU (Tab)"
	view.update_fog_visibility()
	view.clear_selection()
	_rebuild_tool_buttons()
	if on and view.tool not in [T.SELECT, T.FOG, T.MEASURE, T.TOKEN]:
		_set_tool(T.SELECT)
	else:
		_set_tool(view.tool)
	_refresh_inspector()
	view.redraw()


# =================================================================== arayüz kurulumu

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = _make_theme()

	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 0)
	ui.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# --- üst çubuk
	var top := _panel(root)
	var bar := HBoxContainer.new()
	top.add_child(bar)
	bar.add_child(_btn("Yeni", func() -> void:
		if dirty:
			_ask("Kaydedilmemiş değişiklikler var. Yeni kampanya başlatılsın mı?", _open_new_dialog)
		else:
			_open_new_dialog(), "Yeni kampanya: boş harita, rastgele kıta, boyut seçimi"))
	bar.add_child(_btn("Aç", func() -> void: _show_file_dialog("open", FileDialog.FILE_MODE_OPEN_FILE, "*.frp ; FRP Kampanyası"), "Ctrl+O"))
	bar.add_child(_btn("Kaydet", _save, "Ctrl+S"))
	bar.add_child(_btn("Farklı Kaydet", func() -> void: _show_file_dialog("save", FileDialog.FILE_MODE_SAVE_FILE, "*.frp ; FRP Kampanyası", campaign.name + ".frp")))
	bar.add_child(_btn("PNG Dışa Aktar", func() -> void: _show_file_dialog("png", FileDialog.FILE_MODE_SAVE_FILE, "*.png ; PNG Resmi", current.name + ".png"), "Haritanın tamamını resim olarak kaydeder"))
	bar.add_child(VSeparator.new())
	bar.add_child(_btn("Geri Al", func() -> void: view.undo(), "Ctrl+Z"))
	bar.add_child(_btn("Yinele", func() -> void: view.redo(), "Ctrl+Y"))
	bar.add_child(VSeparator.new())
	bar.add_child(_toggle("Izgara", view.show_grid, func(on: bool) -> void:
		view.show_grid = on
		view.redraw(), "H"))
	bar.add_child(_toggle("İsimler", view.show_names, func(on: bool) -> void:
		view.show_names = on
		view.redraw()))
	bar.add_child(_toggle("HD Görünüm", view.hd, func(on: bool) -> void: view.hd = on,
			"Organik kıyılar, dalgalar, arazi dokuları ve yumuşak sınırlar. Kapatınca klasik kare hücreler."))
	var q := OptionButton.new()
	q.focus_mode = Control.FOCUS_NONE
	for t in ["Kalite: Yüksek", "Kalite: Dengeli", "Kalite: Hızlı"]:
		q.add_item(t)
	q.selected = 1
	q.tooltip_text = "Arazinin çizim çözünürlüğü. Takılma olursa Hızlı'yı seç; semboller ve yazılar her ayarda keskin kalır."
	q.item_selected.connect(func(i: int) -> void:
		view.terrain_scale = [1.0, 0.75, 0.5][i]
		_toast(["Yüksek kalite: arazi tam çözünürlükte.", "Dengeli: arazi %75 çözünürlükte.", "Hızlı: arazi yarı çözünürlükte (en akıcı)."][i]))
	bar.add_child(q)
	bar.add_child(_toggle("Parşömen", view.parchment, func(on: bool) -> void: view.parchment = on,
			"Eski kağıt harita görünümü"))
	bar.add_child(_btn("Sığdır", _fit, "Home"))
	bar.add_child(VSeparator.new())
	var dice_btn := _btn("Zarlar (D)", _toggle_dice_tray, "Zar tepsisini aç / kapat")
	dice_btn.add_theme_color_override("font_color", GOLD)
	bar.add_child(dice_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	mode_button = _toggle("DÜZENLEME MODU (Tab)", false, _set_play,
			"Masa modu: oyun sırasında kullanılır. Sembole tek tıkla girilir, sis tam kapalıdır, grup jetonu sürüklenir.")
	mode_button.custom_minimum_size.x = 210
	var info := _btn("Info", func() -> void: guide.open(), "Rehber: nasıl yapılır, kısayollar (F1)")
	info.add_theme_color_override("font_color", Color("8fd1ff"))
	info.add_theme_font_size_override("font_size", 16)
	info.custom_minimum_size.x = 64
	bar.add_child(info)
	bar.add_child(VSeparator.new())
	bar.add_child(mode_button)

	# --- konum çubuğu (breadcrumb)
	var crumb := _panel(root)
	breadcrumb = HBoxContainer.new()
	crumb.add_child(breadcrumb)

	# --- orta alan
	var mid := HBoxContainer.new()
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 0)
	root.add_child(mid)

	var left := _panel(mid)
	left.custom_minimum_size.x = 280
	var lscroll := ScrollContainer.new()
	lscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(lscroll)
	var lbox := VBoxContainer.new()
	lbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lscroll.add_child(lbox)
	lbox.add_child(_header("ARAÇLAR"))
	tool_grid = GridContainer.new()
	tool_grid.columns = 2
	lbox.add_child(tool_grid)
	move_btn = _toggle("Taşıma Modu (K): Kapalı", false, func(on: bool) -> void: _set_move_mode(on),
			"Açıkken semboller, nehirler, yollar ve yazılar sürüklenerek taşınır. Kapalıyken yanlışlıkla yerinden oynamaz.")
	lbox.add_child(move_btn)
	lbox.add_child(HSeparator.new())
	tool_options = VBoxContainer.new()
	lbox.add_child(tool_options)

	var center := Control.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(center)

	_build_dice_tray(center)

	var right := _panel(mid)
	right.custom_minimum_size.x = 320
	right_tabs = TabContainer.new()
	right.add_child(right_tabs)
	var rscroll := ScrollContainer.new()
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_tabs.add_child(rscroll)
	right_tabs.set_tab_title(0, "Özellikler")
	inspector = VBoxContainer.new()
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rscroll.add_child(inspector)

	_build_characters_tab()

	var tree_box := VBoxContainer.new()
	right_tabs.add_child(tree_box)
	right_tabs.set_tab_title(2, "Harita Ağacı")
	tree_box.add_child(_small("Kampanya adı"))
	campaign_name_edit = LineEdit.new()
	campaign_name_edit.text_changed.connect(func(t: String) -> void:
		campaign.name = t
		_mark_dirty()
		_update_title())
	tree_box.add_child(campaign_name_edit)
	map_tree = Tree.new()
	map_tree.hide_root = true
	map_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_tree.item_selected.connect(_on_tree_selected)
	tree_box.add_child(map_tree)
	tree_box.add_child(_small("Seçili haritaya bağlı, sembolsüz yeni bir harita ekle:"))
	var add_row := HBoxContainer.new()
	tree_box.add_child(add_row)
	var kind_opt := _kind_option(Defs.Kind.REGION)
	kind_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(kind_opt)
	add_row.add_child(_btn("+ Alt Harita", func() -> void:
		var m := campaign.create_map(kind_opt.selected, "Yeni " + Defs.KIND_NAMES[kind_opt.selected], current.id)
		PlaceGenerator.blank(m, "")
		_mark_dirty()
		enter_map(m.id)))

	# --- durum çubuğu
	var bottom := _panel(root)
	var sbar := HBoxContainer.new()
	bottom.add_child(sbar)
	status_label = Label.new()
	status_label.custom_minimum_size.x = 380
	sbar.add_child(status_label)
	toast_label = Label.new()
	toast_label.add_theme_color_override("font_color", GOLD)
	toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sbar.add_child(toast_label)
	hint_label = Label.new()
	hint_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	sbar.add_child(hint_label)

	# --- diyaloglar
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.file_selected.connect(_on_file_selected)
	ui.add_child(file_dialog)
	confirm = ConfirmationDialog.new()
	confirm.ok_button_text = "Evet"
	confirm.cancel_button_text = "Vazgeç"
	confirm.title = "Emin misin?"
	ui.add_child(confirm)

	_build_new_dialog()
	guide = GuideWindow.new()
	ui.add_child(guide)

	dice_overlay = DiceOverlay.new()
	ui.add_child(dice_overlay)
	dice_overlay.visible = false
	editor.rolled.connect(_log_roll)

	_rebuild_tool_buttons()
	_set_tool(T.SELECT)


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 14
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.11, 0.09, 0.96)
	sb.border_color = Color(0.42, 0.33, 0.2)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(6)
	th.set_stylebox("panel", "PanelContainer", sb)
	return th


func _rebuild_tool_buttons() -> void:
	_clear(tool_grid)
	var group := ButtonGroup.new()
	for d in tool_defs:
		if view.play_mode and not d.get("play", false):
			continue
		var name_text: String = d["name"]
		if view.play_mode and d["tool"] == T.SELECT:
			name_text = "Gez / Gir"
		var b := Button.new()
		b.text = "%s (%s)" % [name_text, OS.get_keycode_string(d["key"])]
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.set_meta("tool", d["tool"])
		b.button_pressed = d["tool"] == view.tool
		var t: int = d["tool"]
		b.pressed.connect(func() -> void: _set_tool(t))
		tool_grid.add_child(b)


# =================================================================== araç seçenekleri (sol panel)

func _rebuild_tool_options() -> void:
	if tool_options == null or current == null:
		return
	_clear(tool_options)
	var box := tool_options
	match view.tool:
		T.SELECT:
			if view.play_mode:
				_hint(box, "MASA MODU\n• Sembole tıkla: o yerin haritasına gir (şehir, zindan...)\n• Boş yeri sürükle: kaydır\n• Grup jetonunu sürükle: grubu taşı (sis varsa etrafı açılır)\n• Shift + sürükle: mesafe ölç\n• Backspace: üst haritaya dön")
			else:
				_hint(box, "• Tık: seç (sürükleyince harita kayar)\n• Taşımak için: Taşıma Modu (K) aç, sonra sürükle\n• Çift tık (sembol): içine gir / yoksa sağdan oluştur\n• Delete: seçileni sil\n• Boş yeri sürükle veya sağ tık: kaydır\n• Tekerlek: yakınlaştır\n• Shift + sürükle: mesafe ölç")
			hint_label.text = "Çift tık: sembole gir  •  Backspace: üst harita"
		T.TERRAIN:
			_brush_slider(box)
			_terrain_palette(box)
			hint_label.text = "[ ve ]: fırça boyutu"
		T.FILL:
			_terrain_palette(box)
			_hint(box, "Tıkladığın yerdeki aynı arazi tipine sahip bitişik alanı seçili araziyle doldurur.")
			hint_label.text = "Tık: doldur"
		T.REGION:
			_region_options(box)
			hint_label.text = "Sürükle: boya  •  Shift + tık: alanı doldur"
		T.PATH:
			_path_options(box)
			hint_label.text = "Sürükle: serbest çiz  •  Shift basılı: düz çizgi"
		T.SYMBOL:
			_symbol_options(box)
			hint_label.text = "Tık: sembol yerleştir"
		T.LABEL:
			_hint(box, "Haritaya tıkla: yazı ekle. Yazıyı sağdaki Özellikler panelinden düzenle (metin, boyut, renk). Deniz, dağ sırası, okyanus isimleri için ideal.")
			hint_label.text = "Tık: yazı ekle"
		T.FOG:
			_fog_options(box)
			hint_label.text = "Sürükle: sisi aç / kapat"
		T.MEASURE:
			_hint(box, "Sürükleyerek iki nokta arasını ölç. Haritanın ölçeği (1 hücre = ?) sağdaki harita özelliklerinden ayarlanır.\n\nkm ise yürüyüş/atlı gün sayısı, m/ft ise savaş turu sayısı gösterilir.")
			hint_label.text = "Sürükle: ölç"
		T.ERASER:
			_hint(box, "Sembol, yazı veya yol üstüne tıkla: siler.\nArazi silmek için Arazi fırçasıyla başka bir tip boya; bölge silmek için Krallık aracında '(Bölgeyi Sil)' seç.")
			hint_label.text = "Tık: nesneyi sil"
		T.PARTY:
			_hint(box, "Haritaya tıkla: oyuncu grubunun jetonunu oraya koy. Masa modunda jeton sürüklenebilir.")
			box.add_child(_btn("Grup Jetonunu Kaldır", func() -> void:
				view.record()
				current.party_pos = Vector2(-1, -1)
				view.redraw()))
			hint_label.text = "Tık: grubu yerleştir"
		T.TOKEN:
			_token_options(box)
			hint_label.text = "Tık: seçili karakteri koy  •  Jetonu sürükle: taşı"


func _brush_slider(box: Control) -> void:
	var lbl := _small("Fırça boyutu: %d" % view.brush_radius)
	box.add_child(lbl)
	var sl := HSlider.new()
	sl.min_value = 1
	sl.max_value = 40
	sl.value = view.brush_radius
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(func(v: float) -> void:
		view.brush_radius = int(v)
		lbl.text = "Fırça boyutu: %d" % int(v))
	box.add_child(sl)


func _terrain_palette(box: Control) -> void:
	box.add_child(_header("ARAZİ"))
	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	var group := ButtonGroup.new()
	for i in Defs.terrains.size():
		var b := Button.new()
		b.text = Defs.terrains[i]["name"]
		b.icon = Defs.swatch(Defs.terrains[i]["color"])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = i == view.brush_terrain
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size.x = 125
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: view.brush_terrain = i)
		grid.add_child(b)


func _region_options(box: Control) -> void:
	_brush_slider(box)
	var chk := CheckBox.new()
	chk.text = "Sadece karaya boya"
	chk.button_pressed = view.region_land_only
	chk.focus_mode = Control.FOCUS_NONE
	chk.toggled.connect(func(on: bool) -> void: view.region_land_only = on)
	box.add_child(chk)
	box.add_child(_header("KRALLIKLAR / BÖLGELER"))
	var group := ButtonGroup.new()
	var none := _btn("(Bölgeyi Sil)", func() -> void:
		view.brush_region = 0
		_rebuild_tool_options())
	none.toggle_mode = true
	none.button_group = group
	none.button_pressed = view.brush_region == 0
	box.add_child(none)
	for reg in current.regions:
		var rid := int(reg["id"])
		var b := _btn(str(reg["name"]), func() -> void:
			view.brush_region = rid
			_rebuild_tool_options())
		b.icon = Defs.swatch(reg["color"])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = view.brush_region == rid
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		box.add_child(b)
	box.add_child(_btn("+ Yeni Krallık / Bölge", func() -> void:
		var id := current.free_region_id()
		if id < 0:
			return
		view.record()
		var col: Color = Defs.region_palette[(id - 1) % Defs.region_palette.size()]
		current.regions.append({"id": id, "name": Defs.random_name() + " Krallığı", "color": col, "notes": ""})
		view.brush_region = id
		view.rebuild_regions()
		_rebuild_tool_options()))

	var reg := current.get_region(view.brush_region)
	if reg.is_empty():
		return
	box.add_child(HSeparator.new())
	box.add_child(_header("SEÇİLİ BÖLGE"))
	box.add_child(_small("Ad"))
	box.add_child(_line(str(reg["name"]), func(t: String) -> void:
		reg["name"] = t
		_mark_dirty()
		view.redraw()))
	box.add_child(_small("Renk"))
	var cp := ColorPickerButton.new()
	cp.color = reg["color"]
	cp.custom_minimum_size.y = 28
	cp.edit_alpha = false
	cp.color_changed.connect(func(c: Color) -> void:
		# sadece renk tablosu güncellenir (tüm harita yeniden hesaplanmaz): sürüklerken akıcı
		reg["color"] = c
		_mark_dirty()
		view.update_region_colors())
	# paneli, renk seçicinin kendi sinyali bitmeden silmek çökmeye yol açıyordu: bir sonraki kareye ertele
	cp.popup_closed.connect(_rebuild_tool_options.call_deferred)
	box.add_child(cp)
	box.add_child(_small("Notlar (yönetici, dinî inanç, ordu, ilişkiler...)"))
	box.add_child(_text_edit(str(reg.get("notes", "")), func(t: String) -> void:
		reg["notes"] = t
		_mark_dirty()))
	box.add_child(_btn("Bu Bölgeyi Sil", func() -> void:
		_ask("'%s' silinsin mi? Boyadığın alanlar da temizlenir." % reg["name"], func() -> void:
			view.record()
			for i in current.region.size():
				if current.region[i] == int(reg["id"]):
					current.region[i] = 0
			current.regions.erase(reg)
			view.brush_region = 0
			view.rebuild_regions()
			_rebuild_tool_options())))


func _path_options(box: Control) -> void:
	box.add_child(_header("ÇİZGİ TİPİ"))
	var group := ButtonGroup.new()
	for key in Defs.path_order:
		var def: Dictionary = Defs.path_types[key]
		var k: String = key
		var b := _btn(def["name"], func() -> void: view.path_type = k)
		b.icon = Defs.swatch(def["color"])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = view.path_type == key
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		box.add_child(b)
	_hint(box, "Basılı tutup sürükleyerek çiz; bırakınca çizgi yumuşatılır. Shift basılıyken düz çizgi çizer (surlar, köprüler).\n\nÇizdikten sonra Seç aracıyla tıklayıp isim (ör. 'Gümüş Nehir') ve kalınlık verebilirsin.")


func _symbol_options(box: Control) -> void:
	var lbl := _small("Sembol boyutu: %.1fx" % view.symbol_size)
	box.add_child(lbl)
	var sl := HSlider.new()
	sl.min_value = 0.4
	sl.max_value = 3.0
	sl.step = 0.1
	sl.value = view.symbol_size
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(func(v: float) -> void:
		view.symbol_size = v
		lbl.text = "Sembol boyutu: %.1fx" % v
		view.redraw())
	box.add_child(sl)
	var auto := CheckBox.new()
	auto.text = "Yerleşimlere rastgele isim ver"
	auto.button_pressed = view.auto_name
	auto.focus_mode = Control.FOCUS_NONE
	auto.toggled.connect(func(on: bool) -> void: view.auto_name = on)
	box.add_child(auto)

	var cats: Array = Defs.symbol_categories.duplicate()
	var first := ""
	match current.kind:
		Defs.Kind.CITY: first = "Şehir"
		Defs.Kind.DUNGEON: first = "Zindan / İç Mekan"
		Defs.Kind.BUILDING: first = "Mobilya"
		Defs.Kind.SITE: first = "Doğa"
	if first != "":
		cats.erase(first)
		cats.push_front(first)
	if current.kind == Defs.Kind.BUILDING:
		cats.erase("Zindan / İç Mekan")
		cats.insert(1, "Zindan / İç Mekan")
	var group := ButtonGroup.new()
	for cat in cats:
		box.add_child(_header(str(cat).to_upper()))
		var grid := GridContainer.new()
		grid.columns = 5
		box.add_child(grid)
		for type in Defs.symbols:
			if Defs.symbols[type]["cat"] != cat:
				continue
			var t: String = type
			var b := SymbolButton.new(t)
			b.button_group = group
			b.button_pressed = view.symbol_type == t
			b.pressed.connect(func() -> void: view.symbol_type = t)
			grid.add_child(b)
	_hint(box, "Altın ok işaretli semboller bir alt haritaya bağlıdır. Yerleşim, zindan, mağara gibi sembollere çift tıklayınca (masa modunda tek tık) otomatik yeni harita açılır.")


func _fog_options(box: Control) -> void:
	var chk := CheckBox.new()
	chk.text = "Bu haritada savaş sisi açık"
	chk.button_pressed = current.fog_enabled
	chk.focus_mode = Control.FOCUS_NONE
	chk.toggled.connect(func(on: bool) -> void:
		current.fog_enabled = on
		_mark_dirty()
		view.update_fog_visibility())
	box.add_child(chk)
	_brush_slider(box)
	var group := ButtonGroup.new()
	var reveal := _btn("Sisi Aç (göster)", func() -> void: view.fog_reveal = true)
	var hide := _btn("Sisi Kapat (gizle)", func() -> void: view.fog_reveal = false)
	for b in [reveal, hide]:
		b.toggle_mode = true
		b.button_group = group
		box.add_child(b)
	reveal.button_pressed = view.fog_reveal
	hide.button_pressed = not view.fog_reveal
	box.add_child(_btn("Tüm Haritayı Aç", func() -> void: view.fill_fog(true)))
	box.add_child(_btn("Tüm Haritayı Kapat", func() -> void: view.fill_fog(false)))
	_hint(box, "Düzenleme modunda sis yarı saydam görünür, masa modunda (oyuncuların gördüğü) tamamen kapalıdır. Grup jetonu hareket ettikçe etrafındaki sis kendiliğinden açılır.")


# =================================================================== özellikler paneli (sağ)

func _refresh_inspector() -> void:
	if not _insp_pending:
		_insp_pending = true
		_do_refresh_inspector.call_deferred()


func _do_refresh_inspector() -> void:
	_insp_pending = false
	if inspector == null or current == null:
		return
	_clear(inspector)
	match view.selected_kind:
		"symbol":
			if view.play_mode:
				_inspect_symbol_play(view.selected)
			else:
				_inspect_symbol(view.selected)
		"path": _inspect_path(view.selected)
		"label": _inspect_label(view.selected)
		"token": _inspect_token(view.selected)
		_: _inspect_map()
	right_tabs.current_tab = 0


func _inspect_map() -> void:
	var box := inspector
	box.add_child(_header("HARİTA: " + current.name.to_upper()))
	var stats := "%d sembol  •  %d yol  •  %d alt harita" % [current.symbols.size(), current.paths.size(), campaign.children_of(current.id).size()]
	box.add_child(_small(stats))
	box.add_child(_small("Ad"))
	box.add_child(_line(current.name, func(t: String) -> void:
		current.name = t
		_mark_dirty()
		_refresh_breadcrumb()
		_refresh_tree()
		_update_title()))
	box.add_child(_small("Harita türü"))
	var ko := _kind_option(current.kind)
	ko.item_selected.connect(func(i: int) -> void:
		current.kind = i
		_mark_dirty()
		_refresh_breadcrumb()
		_rebuild_tool_options())
	box.add_child(ko)

	box.add_child(_small("Ölçek: 1 hücre ="))
	var srow := HBoxContainer.new()
	box.add_child(srow)
	var sp := _spin(0.1, 10000, 0.1, current.scale, func(v: float) -> void:
		current.scale = v
		_mark_dirty()
		_refresh_breadcrumb())
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srow.add_child(sp)
	var units := ["km", "mil", "m", "ft"]
	var uo := OptionButton.new()
	for u in units:
		uo.add_item(u)
	uo.selected = maxi(0, units.find(current.unit))
	uo.item_selected.connect(func(i: int) -> void:
		current.unit = units[i]
		_mark_dirty()
		_refresh_breadcrumb())
	srow.add_child(uo)

	box.add_child(_small("Boyut (hücre): genişlik × yükseklik"))
	var zrow := HBoxContainer.new()
	box.add_child(zrow)
	var cs := _spin(10, 1000, 1, current.cols, func(_v: float) -> void: pass)
	var rs := _spin(10, 1000, 1, current.rows, func(_v: float) -> void: pass)
	zrow.add_child(cs)
	zrow.add_child(rs)
	var center_chk := _check("Ortadan genişlet / küçült", true)
	center_chk.tooltip_text = "Açık: harita her yönden eşit büyür. Kapalı: sağa ve aşağıya doğru büyür."
	zrow.add_child(_btn("Uygula", func() -> void:
		var nc := int(cs.value)
		var nr := int(rs.value)
		var ox := (nc - current.cols) / 2 if center_chk.button_pressed else 0
		var oy := (nr - current.rows) / 2 if center_chk.button_pressed else 0
		view.record()
		current.resize(nc, nr, Defs.KIND_DEFAULTS[current.kind]["fill"], ox, oy)
		view.rebuild_all()
		_fit()
		_refresh_breadcrumb()
		_refresh_inspector()))
	box.add_child(center_chk)
	var lim := _small("En fazla 1000×1000 hücre. Çok büyük haritalarda rastgele üretim birkaç saniye sürebilir.")
	lim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lim.custom_minimum_size.x = 260
	box.add_child(lim)

	var fog := CheckBox.new()
	fog.text = "Savaş sisi"
	fog.button_pressed = current.fog_enabled
	fog.toggled.connect(func(on: bool) -> void:
		current.fog_enabled = on
		_mark_dirty()
		view.update_fog_visibility())
	box.add_child(fog)

	box.add_child(_small("Harita notları (DM için)"))
	var notes := _text_edit(current.notes, func(t: String) -> void:
		current.notes = t
		_mark_dirty())
	notes.custom_minimum_size.y = 140
	box.add_child(notes)

	if view.play_mode:
		return

	box.add_child(HSeparator.new())
	if current.kind in [Defs.Kind.WORLD, Defs.Kind.REGION]:
		_terrain_gen(box)
	else:
		_place_regen(box)

	box.add_child(HSeparator.new())
	box.add_child(_header("ARAÇLAR"))
	box.add_child(_btn("Tümünü Seçili Araziyle Doldur", func() -> void:
		view.record()
		current.terrain.fill(view.brush_terrain)
		view.rebuild_all(), "Arazi fırçasında seçili olan tip"))
	box.add_child(_btn("Haritayı Tamamen Temizle", func() -> void:
		_ask("Bu haritadaki her şey silinecek (alt haritalar kalır). Emin misin?", func() -> void:
			view.record()
			current.setup(current.cols, current.rows, Defs.KIND_DEFAULTS[current.kind]["fill"])
			current.symbols.clear()
			current.paths.clear()
			current.labels.clear()
			current.regions.clear()
			current.party_pos = Vector2(-1, -1)
			view.rebuild_all()
			_rebuild_tool_options()
			_refresh_inspector())))
	if current.id != campaign.root_id:
		var del := _btn("Bu Haritayı Sil", func() -> void:
			_ask("'%s' ve tüm alt haritaları kalıcı olarak silinecek. Emin misin?" % current.name, func() -> void:
				var parent := current.parent_id
				campaign.delete_map(current.id)
				current = null
				_mark_dirty()
				enter_map(parent if campaign.maps.has(parent) else campaign.root_id)))
		del.add_theme_color_override("font_color", Color("ff8a7a"))
		box.add_child(del)



func _terrain_gen(box: VBoxContainer) -> void:
	box.add_child(_header("RASTGELE ARAZİ ÜRET"))
	var gr := HBoxContainer.new()
	box.add_child(gr)
	gr.add_child(_small("Tohum"))
	var seed_spin := _spin(0, 999999, 1, _gen_seed, func(v: float) -> void: _gen_seed = int(v))
	seed_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gr.add_child(seed_spin)
	gr.add_child(_btn("Zar", func() -> void: seed_spin.value = randi() % 1000000, "Rastgele tohum"))
	var island := _check("Kıta / ada (kenarlar deniz)", current.kind == Defs.Kind.WORLD)
	var rivers := _check("Nehirler ekle", true)
	var nature := _check("Dağ / orman sembolleri ekle", true)
	var has_towns := current.symbols.any(func(s): return str(s["type"]) in Defs.SETTLEMENTS)
	var towns := _check("Şehir / köy / liman / kale ekle", not has_towns)
	towns.tooltip_text = "Araziye uygun yerleşimler konur (içleri boş; tıklayınca kendin çizer ya da otomatik oluşturursun)"
	for c in [island, rivers, nature, towns]:
		box.add_child(c)
	box.add_child(_btn("Araziyi Üret", func() -> void:
		_ask("Arazi ve bölge boyaları yeniden oluşturulacak. Eski otomatik nehirler ve isimsiz dağ / orman sembolleri silinir; senin koyduğun semboller, yollar ve yazılar korunur. Devam?", func() -> void:
			view.record()
			if rivers.button_pressed:
				current.paths = current.paths.filter(func(p): return p["type"] != "river")
			if nature.button_pressed:
				current.symbols = current.symbols.filter(func(s): return not (str(s["type"]) in MapView.NATURE and str(s.get("name", "")) == "" and str(s.get("link", "")) == ""))
			MapGenerator.generate_terrain(current, _gen_seed, island.button_pressed, rivers.button_pressed, nature.button_pressed, towns.button_pressed)
			view.rebuild_all()
			_set_tool(T.SELECT)
			_refresh_inspector())))


## Bu haritaya açılan sembolün türü (üst haritada link'i bu haritayı gösteren sembol)
func _source_type(m: MapData) -> String:
	var p: MapData = campaign.maps.get(m.parent_id)
	if p != null:
		for s in p.symbols:
			if str(s.get("link", "")) == m.id:
				return str(s["type"])
	return ""


## Şehir / bina / zindan / yerel alan: türüne uygun yeniden oluşturma
func _place_regen(box: VBoxContainer) -> void:
	box.add_child(_header("OTOMATİK OLUŞTUR"))
	var type := _source_type(current)
	if type == "":
		box.add_child(_small("Bu harita bir sembole bağlı olmadığı için türü bilinmiyor."))
		return
	var tip := _small("Bu harita: %s. İçini türüne uygun olarak baştan oluşturabilirsin." % Defs.symbol_name(type))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	box.add_child(_btn("Yeniden Oluştur", func() -> void:
		_ask("Bu haritadaki arazi, semboller, yollar ve yazılar silinip yeniden oluşturulacak (Geri Al ile dönebilirsin). Devam?", func() -> void:
			view.record()
			var sz := PlaceGenerator.size_for(type, current.kind)
			current.setup(sz["cols"], sz["rows"], Defs.KIND_DEFAULTS[current.kind]["fill"])
			current.symbols.clear()
			current.paths.clear()
			current.labels.clear()
			current.regions.clear()
			PlaceGenerator.generate(current, type)
			_mark_dirty()
			view.rebuild_all()
			_fit()
			_set_tool(T.SELECT)
			_refresh_inspector())))

func _inspect_symbol(s: Dictionary) -> void:
	var box := inspector
	var type := str(s["type"])
	box.add_child(_header("SEMBOL: " + Defs.symbol_name(type).to_upper()))
	box.add_child(_small("Ad"))
	var nrow := HBoxContainer.new()
	box.add_child(nrow)
	var ne := _line(str(s.get("name", "")), func(t: String) -> void:
		s["name"] = t
		_mark_dirty()
		view.redraw())
	ne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(ne)
	nrow.add_child(_btn("Zar", func() -> void:
		ne.text = Defs.random_name()
		ne.text_changed.emit(ne.text), "Rastgele fantastik isim"))

	box.add_child(_small("Sembol tipi"))
	var to := OptionButton.new()
	var keys := Defs.symbols.keys()
	for k in keys:
		to.add_item("%s  (%s)" % [Defs.symbols[k]["name"], Defs.symbols[k]["cat"]])
	to.selected = keys.find(type)
	to.item_selected.connect(func(i: int) -> void:
		view.record()
		s["type"] = keys[i]
		view.redraw()
		_refresh_inspector())
	box.add_child(to)

	box.add_child(_small("Boyut"))
	var sl := HSlider.new()
	sl.min_value = 0.4
	sl.max_value = 4.0
	sl.step = 0.1
	sl.value = float(s.get("size", 1.0))
	sl.value_changed.connect(func(v: float) -> void:
		s["size"] = v
		_mark_dirty()
		view.redraw())
	box.add_child(sl)

	box.add_child(_small("Notlar (kim yaşar, ne olur, gizli bilgiler...)"))
	box.add_child(_text_edit(str(s.get("notes", "")), func(t: String) -> void:
		s["notes"] = t
		_mark_dirty()))

	box.add_child(HSeparator.new())
	box.add_child(_header("ALT HARİTA"))
	var link := str(s.get("link", ""))
	if link != "" and campaign.maps.has(link):
		var m: MapData = campaign.maps[link]
		box.add_child(_small("Bağlı harita: %s (%s)" % [m.name, Defs.KIND_NAMES[m.kind]]))
		box.add_child(_btn("Haritaya Gir  >", func() -> void: enter_map(link)))
		box.add_child(_btn("Bağlantıyı Kaldır", func() -> void:
			s["link"] = ""
			_mark_dirty()
			view.redraw()
			_refresh_inspector(), "Harita silinmez, Harita Ağacı'nda kalır"))
	else:
		_enter_choice(box, s)
		var others: Array = []
		for m in campaign.maps.values():
			if m.id != current.id:
				others.append(m)
		if not others.is_empty():
			box.add_child(_small("veya var olan bir haritaya bağla:"))
			var lrow := HBoxContainer.new()
			box.add_child(lrow)
			var mo := OptionButton.new()
			mo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mo.clip_text = true
			for m in others:
				mo.add_item(m.name)
			lrow.add_child(mo)
			lrow.add_child(_btn("Bağla", func() -> void:
				s["link"] = others[mo.selected].id
				_mark_dirty()
				view.redraw()
				_refresh_inspector()))

	box.add_child(HSeparator.new())
	var del := _btn("Sembolü Sil (Del)", func() -> void: view.delete_selected())
	del.add_theme_color_override("font_color", Color("ff8a7a"))
	box.add_child(del)


func _inspect_symbol_play(s: Dictionary) -> void:
	var box := inspector
	var nm := str(s.get("name", ""))
	box.add_child(_header((nm if nm != "" else Defs.symbol_name(str(s["type"]))).to_upper()))
	box.add_child(_small(Defs.symbol_name(str(s["type"]))))
	var notes := Label.new()
	notes.text = str(s.get("notes", "")) if str(s.get("notes", "")) != "" else "(not yok)"
	notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(notes)
	var link := str(s.get("link", ""))
	if link != "" and campaign.maps.has(link):
		box.add_child(_btn("Haritaya Gir  >", func() -> void: enter_map(link)))
	elif Defs.enter_kind(str(s["type"]), current.kind) >= 0:
		box.add_child(HSeparator.new())
		_enter_choice(box, s)


func _inspect_path(p: Dictionary) -> void:
	var box := inspector
	box.add_child(_header("ÇİZGİ: " + str(Defs.path_types.get(p["type"], {}).get("name", "")).to_upper()))
	box.add_child(_small("Ad"))
	box.add_child(_line(str(p.get("name", "")), func(t: String) -> void:
		p["name"] = t
		_mark_dirty()
		view.redraw()))
	box.add_child(_small("Tip"))
	var to := OptionButton.new()
	for k in Defs.path_order:
		to.add_item(Defs.path_types[k]["name"])
	to.selected = Defs.path_order.find(p["type"])
	to.item_selected.connect(func(i: int) -> void:
		view.record()
		p["type"] = Defs.path_order[i]
		view.redraw()
		_refresh_inspector())
	box.add_child(to)
	box.add_child(_small("Kalınlık"))
	var sl := HSlider.new()
	sl.min_value = 1
	sl.max_value = 24
	sl.step = 0.5
	sl.value = float(p.get("width", 3.0))
	sl.value_changed.connect(func(v: float) -> void:
		p["width"] = v
		_mark_dirty()
		view.redraw())
	box.add_child(sl)
	box.add_child(HSeparator.new())
	var del := _btn("Çizgiyi Sil (Del)", func() -> void: view.delete_selected())
	del.add_theme_color_override("font_color", Color("ff8a7a"))
	box.add_child(del)


func _inspect_label(l: Dictionary) -> void:
	var box := inspector
	box.add_child(_header("YAZI"))
	box.add_child(_small("Metin"))
	var le := _line(str(l["text"]), func(t: String) -> void:
		l["text"] = t
		_mark_dirty()
		view.redraw())
	box.add_child(le)
	le.grab_focus.call_deferred()
	le.select_all.call_deferred()
	box.add_child(_small("Yazı boyutu"))
	box.add_child(_spin(8, 160, 1, int(l.get("size", 22)), func(v: float) -> void:
		l["size"] = int(v)
		_mark_dirty()
		view.redraw()))
	box.add_child(_small("Yazı tipi"))
	var fo := OptionButton.new()
	fo.add_item("Başlık (Cinzel)")
	fo.add_item("Metin (Garamond)")
	fo.selected = 1 if str(l.get("font", "title")) == "text" else 0
	fo.item_selected.connect(func(i: int) -> void:
		l["font"] = "text" if i == 1 else "title"
		_mark_dirty()
		view.redraw())
	box.add_child(fo)
	box.add_child(_small("Renk"))
	var cp := ColorPickerButton.new()
	cp.color = l.get("color", Color.BLACK)
	cp.custom_minimum_size.y = 28
	cp.color_changed.connect(func(c: Color) -> void:
		l["color"] = c
		_mark_dirty()
		view.redraw())
	box.add_child(cp)
	box.add_child(HSeparator.new())
	var del := _btn("Yazıyı Sil (Del)", func() -> void: view.delete_selected())
	del.add_theme_color_override("font_color", Color("ff8a7a"))
	box.add_child(del)


# =================================================================== karakterler

func _build_characters_tab() -> void:
	var cbox := VBoxContainer.new()
	right_tabs.add_child(cbox)
	right_tabs.set_tab_title(1, "Karakterler")
	var row := HBoxContainer.new()
	cbox.add_child(row)
	row.add_child(_btn("+ Kahraman", func() -> void: _new_character("pc"), "Yeni oyuncu karakteri"))
	row.add_child(_btn("+ NPC", func() -> void: _new_character("npc"), "Yeni oyuncu olmayan karakter"))
	row.add_child(_btn("+ Yaratık", func() -> void: bestiary.open(), "Bestiyerden hayvan, canavar, ejderha..."))
	var frow := HBoxContainer.new()
	cbox.add_child(frow)
	var fo := OptionButton.new()
	var filters := {"all": "Hepsi", "pc": "Kahramanlar", "npc": "NPC'ler", "creature": "Yaratıklar", "here": "Bu haritada"}
	for k in filters:
		fo.add_item(filters[k])
	fo.item_selected.connect(func(i: int) -> void:
		char_filter = filters.keys()[i]
		_refresh_characters())
	frow.add_child(fo)
	char_search = LineEdit.new()
	char_search.placeholder_text = "Ara..."
	char_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	char_search.text_changed.connect(func(_t: String) -> void: _refresh_characters())
	frow.add_child(char_search)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cbox.add_child(sc)
	char_list = VBoxContainer.new()
	char_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(char_list)

	editor = CharacterEditor.new()
	ui.add_child(editor)
	editor.changed.connect(_on_character_changed)
	editor.place_requested.connect(func(id: String) -> void:
		editor.hide()
		_start_place(id))
	editor.duplicate_requested.connect(func(id: String) -> void:
		var copy: Dictionary = campaign.characters[id].duplicate(true)
		copy["name"] = str(copy["name"]) + " (kopya)"
		campaign.add_character(copy)
		_mark_dirty()
		_refresh_characters()
		editor.open(copy))
	editor.delete_requested.connect(_delete_character)
	bestiary = BestiaryWindow.new()
	ui.add_child(bestiary)
	bestiary.picked.connect(func(species: String) -> void:
		var ch := Lore.new_creature(species)
		var id := campaign.add_character(ch)
		_mark_dirty()
		_refresh_characters()
		_start_place(id))


## Kahraman, NPC ya da yaratık: onaydan sonra kampanyadan ve tüm haritalardan silinir
func _delete_character(id: String) -> void:
	if not campaign.characters.has(id):
		return
	_ask("'%s' silinsin mi? Haritalardaki jetonları da kaldırılır." % campaign.characters[id]["name"], func() -> void:
		if view.token_char == id:
			view.cancel_placement()
		campaign.remove_character(id)
		if editor.visible and editor.ch.get("id", "") == id:
			editor.hide()
		view.clear_selection()
		view.redraw()
		_mark_dirty()
		_refresh_characters()
		_refresh_inspector())


## Haritanın tam yolu: "Dünya Haritası > Başkent > Sarhoş Ejder Meyhanesi"
func _map_path(m: MapData) -> String:
	var parts: Array = []
	var cur: MapData = m
	var guard := 0
	while cur != null and guard < 32:
		parts.push_front(cur.name)
		cur = campaign.maps.get(cur.parent_id)
		guard += 1
	return " > ".join(PackedStringArray(parts))


var _goto_index := 0

## Karakterin jetonunun olduğu haritaya girer (iç içe haritalar dahil), kamerayı jetona götürür ve seçer.
## Yaratık gibi birden çok kopyası olanlarda her basışta sıradaki kopyaya gider.
func _goto_character(id: String) -> void:
	var spots: Array = []   # [harita, jeton]
	for m in campaign.locations_of(id):
		for t in m.tokens:
			if t.get("char", "") == id:
				spots.append([m, t])
	if spots.is_empty():
		_toast("Bu karakter hiçbir haritada değil.")
		return
	_goto_index = (_goto_index + 1) % spots.size() if spots.size() > 1 else 0
	var m: MapData = spots[_goto_index][0]
	var tok: Dictionary = spots[_goto_index][1]
	if view.tool == T.TOKEN:
		view.cancel_placement()
	if current != m:
		enter_map(m.id)
	cam.position = tok["pos"]
	cam.zoom = Vector2.ONE * maxf(cam.zoom.x, 1.2)
	view.select(tok, "token")
	_refresh_inspector()
	var ch: Dictionary = campaign.characters.get(id, {})
	var extra := "  (%d/%d)" % [_goto_index + 1, spots.size()] if spots.size() > 1 else ""
	_toast("%s → %s%s" % [ch.get("name", ""), _map_path(m), extra])


## Jetonları kaldırır: önce açık haritadan; burada yoksa bulunduğu tüm haritalardan
func _remove_from_map(id: String) -> void:
	if view.remove_tokens_of(id):
		_toast("Jeton bu haritadan kaldırıldı.")
	else:
		view.record()
		for m in campaign.locations_of(id):
			for i in range(m.tokens.size() - 1, -1, -1):
				if m.tokens[i].get("char", "") == id:
					m.tokens.remove_at(i)
		_toast("Jeton bulunduğu haritadan kaldırıldı.")
	if view.token_char == id:
		view.cancel_placement()
	_mark_dirty()
	_refresh_characters()


func _new_character(role: String) -> void:
	var races := Lore.races.keys()
	var pcs := []
	for k in Lore.classes:
		if Lore.classes[k].get("npc", false) == (role == "npc"):
			pcs.append(k)
	var race: String = "human" if randf() < 0.35 else races.pick_random()
	var ch := Lore.new_character(race, pcs.pick_random(), role)
	campaign.add_character(ch)
	_mark_dirty()
	_refresh_characters()
	editor.open(ch)


func _start_place(id: String) -> void:
	view.token_char = id
	_set_tool(T.TOKEN)
	var ch: Dictionary = campaign.characters.get(id, {})
	_toast("Haritaya tıklayarak yerleştir: " + str(ch.get("name", "")))


func _on_token_placed(id: String) -> void:
	var ch: Dictionary = campaign.characters.get(id, {})
	if ch.get("kind", "") != "creature":
		# kahraman/NPC aynı anda tek yerde bulunur
		for m in campaign.maps.values():
			if m == current:
				continue
			for i in range(m.tokens.size() - 1, -1, -1):
				if m.tokens[i].get("char", "") == id:
					m.tokens.remove_at(i)
	_mark_dirty()
	_refresh_characters()


func _on_character_changed(_id: String) -> void:
	_mark_dirty()
	view.redraw()
	_refresh_characters()
	if view.selected_kind == "token":
		_refresh_inspector()


func _open_editor(id: String) -> void:
	if campaign.characters.has(id):
		editor.open(campaign.characters[id])


func _refresh_characters() -> void:
	if not _chars_pending:
		_chars_pending = true
		_do_refresh_characters.call_deferred()


func _do_refresh_characters() -> void:
	_chars_pending = false
	if char_list == null or campaign == null:
		return
	_clear(char_list)
	var q := char_search.text.strip_edges().to_lower()
	var here := {}
	if current:
		for t in current.tokens:
			here[t.get("char", "")] = true
	var ids: Array = campaign.characters.keys()
	var order := {"pc": 0, "npc": 1, "creature": 2}
	ids.sort_custom(func(a, b):
		var ca: Dictionary = campaign.characters[a]
		var cb: Dictionary = campaign.characters[b]
		var oa: int = order.get(ca.get("role", "pc"), 3)
		var ob: int = order.get(cb.get("role", "pc"), 3)
		if oa != ob:
			return oa < ob
		return str(ca["name"]).naturalnocasecmp_to(str(cb["name"])) < 0)
	var shown := 0
	for id in ids:
		var ch: Dictionary = campaign.characters[id]
		match char_filter:
			"pc", "npc", "creature":
				if ch.get("role", "") != char_filter:
					continue
			"here":
				if not here.has(id):
					continue
		if q != "" and str(ch["name"]).to_lower().find(q) < 0 and Lore.describe(ch).to_lower().find(q) < 0:
			continue
		shown += 1
		var row := HBoxContainer.new()
		char_list.add_child(row)
		row.add_child(PortraitRect.new(ch["look"], 54, 256))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 0)
		row.add_child(v)
		var cid: String = id
		var nb := _btn(str(ch["name"]), func() -> void: _open_editor(cid), "Karakter kartını aç")
		nb.flat = true
		nb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nb.clip_text = true
		nb.add_theme_color_override("font_color", Lore.DISPOSITION_COLORS.get(ch.get("disposition", "neutral"), Color.WHITE).lightened(0.3))
		v.add_child(nb)
		v.add_child(_small(Lore.describe(ch)))
		var locs: Array = campaign.locations_of(cid)
		if not locs.is_empty():
			var names := []
			for m in locs:
				names.append(_map_path(m))
			var ll := _small("Konum: " + ", ".join(names))
			ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ll.custom_minimum_size.x = 120
			v.add_child(ll)
		var bcol := VBoxContainer.new()
		bcol.add_theme_constant_override("separation", 2)
		row.add_child(bcol)
		bcol.add_child(_btn("Koy", func() -> void: _start_place(cid), "Haritaya tıklayarak yerleştir (sağ tık / Esc: iptal)"))
		if not locs.is_empty():
			bcol.add_child(_btn("Konuma Git", func() -> void: _goto_character(cid),
					"Karakterin bulunduğu haritaya gir ve kamerayı ona götür (şehir, meyhane gibi iç haritalar dahil)"))
			var rb := _btn("Kaldır", func() -> void: _remove_from_map(cid), "Bu karakterin jetonunu haritadan kaldır (karakter silinmez)")
			rb.add_theme_color_override("font_color", Color("ff8a7a"))
			bcol.add_child(rb)
		var db := _btn("Sil", func() -> void: _delete_character(cid), "Karakteri / yaratığı / NPC'yi kampanyadan tamamen sil")
		db.add_theme_color_override("font_color", Color("ff5a4a"))
		bcol.add_child(db)
	if shown == 0:
		_hint(char_list, "Henüz karakter yok. Yukarıdaki düğmelerle kahraman, NPC ya da bestiyerden yaratık ekle.")


func _token_options(box: Control) -> void:
	_hint(box, "Bir karakter seç, sonra haritaya tıkla. Kahramanlar ve NPC'ler tek yerde bulunur (yeniden koyunca taşınır). Yaratıklardan istediğin kadar koyabilirsin.")
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(_btn("+ Kahraman", func() -> void: _new_character("pc")))
	row.add_child(_btn("+ Yaratık", func() -> void: bestiary.open()))
	var grid := GridContainer.new()
	grid.columns = 3
	box.add_child(grid)
	var group := ButtonGroup.new()
	for id in campaign.characters:
		var ch: Dictionary = campaign.characters[id]
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(82, 98)
		b.tooltip_text = "%s\n%s" % [ch["name"], Lore.describe(ch)]
		b.button_pressed = view.token_char == id
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(v)
		var pr := PortraitRect.new(ch["look"], 66, 256)
		pr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(pr)
		var l := Label.new()
		l.text = str(ch["name"])
		l.clip_text = true
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 11)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		var cid: String = id
		b.pressed.connect(func() -> void: view.token_char = cid)
		grid.add_child(b)


func _inspect_token(tok: Dictionary) -> void:
	var box := inspector
	var id := str(tok.get("char", ""))
	var ch: Dictionary = campaign.characters.get(id, {})
	if ch.is_empty():
		_inspect_map()
		return
	var creature: bool = ch.get("kind", "") == "creature"
	var nm := str(ch["name"]) + ((" " + str(tok.get("label", ""))) if str(tok.get("label", "")) != "" else "")
	box.add_child(_header(nm.to_upper()))
	var pr := PortraitRect.new(ch["look"], 150, 256)
	pr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(pr)
	box.add_child(_small(Lore.describe(ch) + "  •  " + Lore.ROLES.get(ch.get("role", ""), "")))
	var hp := int(tok.get("hp", 0)) if creature else int(ch.get("hp", 0))
	var hp_max := int(ch.get("hp_max", 1))
	var hpl := _header("CAN: %d / %d" % [hp, hp_max])
	hpl.add_theme_color_override("font_color", Color("4caf50") if hp > hp_max / 2 else (Color("e0b85c") if hp > hp_max / 4 else Color("ff8a7a")))
	box.add_child(hpl)
	var amount := _spin(1, 999, 1, 1, func(_v: float) -> void: pass)
	var change := func(delta: int) -> void:
		if creature:
			tok["hp"] = clampi(int(tok.get("hp", 0)) + delta, -99, hp_max)
		else:
			ch["hp"] = clampi(int(ch.get("hp", 0)) + delta, -99, hp_max)
		_mark_dirty()
		view.redraw()
		_refresh_inspector()
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(amount)
	var dmg := _btn("Hasar", func() -> void: change.call(-int(amount.value)))
	dmg.add_theme_color_override("font_color", Color("ff8a7a"))
	row.add_child(dmg)
	var heal := _btn("İyileştir", func() -> void: change.call(int(amount.value)))
	heal.add_theme_color_override("font_color", Color("8fd18f"))
	row.add_child(heal)
	row.add_child(_btn("Tam", func() -> void: change.call(hp_max - hp), "Canı doldur"))
	box.add_child(_small("Zırh Sınıfı: %d   •   Hız: %s m   •   İnisiyatif: %s" % [int(ch.get("ac", 10)), str(ch.get("speed", 9)), Lore.mod_text(Lore.total_stat(ch, "dex"))]))
	var stats := []
	for s in Lore.STATS:
		stats.append("%s %d (%s)" % [Lore.STAT_SHORT[s], Lore.total_stat(ch, s), Lore.mod_text(Lore.total_stat(ch, s))])
	var sl := _small("  ".join(stats))
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sl)
	if creature and str(ch.get("attacks", "")) != "":
		var al := Label.new()
		al.text = str(ch["attacks"])
		al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(al)
	var dopt := OptionButton.new()
	var dkeys := Lore.DISPOSITIONS.keys()
	for k in dkeys:
		dopt.add_item(Lore.DISPOSITIONS[k])
	dopt.selected = maxi(0, dkeys.find(ch.get("disposition", "neutral")))
	dopt.item_selected.connect(func(i: int) -> void:
		ch["disposition"] = dkeys[i]
		_mark_dirty()
		view.redraw())
	box.add_child(_small("Taraf"))
	box.add_child(dopt)
	if str(ch.get("notes", "")) != "":
		box.add_child(_small("Notlar"))
		var nl := Label.new()
		nl.text = str(ch["notes"])
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(nl)
	var eq := []
	Lore.ensure_inventory(ch)
	for k in ["weapon1", "weapon2"]:
		if not ch["equipment"][k].is_empty():
			eq.append(str(ch["equipment"][k].get("name", "")))
	if not eq.is_empty():
		box.add_child(_small("Silahlar: " + ", ".join(eq)))
	var rrow := HBoxContainer.new()
	box.add_child(rrow)
	rrow.add_child(_btn("d20 At", func() -> void: roll("1d20", str(ch["name"]))))
	rrow.add_child(_btn("İnisiyatif", func() -> void:
		var m := Lore.modifier(Lore.total_stat(ch, "dex"))
		roll("1d20%s" % (("+%d" % m) if m != 0 else ""), str(ch["name"]) + " — İnisiyatif")))
	box.add_child(HSeparator.new())
	box.add_child(_btn("Karakter Kartını Aç", func() -> void: _open_editor(id)))
	var del := _btn("Jetonu Haritadan Kaldır (Del)", func() -> void: view.delete_selected())
	del.add_theme_color_override("font_color", Color("ff8a7a"))
	box.add_child(del)


# =================================================================== yeni kampanya penceresi

func _build_new_dialog() -> void:
	new_dialog = ConfirmationDialog.new()
	new_dialog.title = "Yeni Kampanya"
	new_dialog.ok_button_text = "Oluştur"
	new_dialog.cancel_button_text = "Vazgeç"
	ui.add_child(new_dialog)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(460, 0)
	new_dialog.add_child(v)
	var h_17 := _header("NASIL BAŞLAYALIM?")
	h_17.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(h_17)
	nd_start = OptionButton.new()
	for t in START_TYPES:
		nd_start.add_item(t)
	nd_start.selected = 1
	v.add_child(nd_start)
	var tip := _small("Boş okyanus seçersen: sol panelde Arazi (B) aracıyla Çayır, Orman, Dağlık... seçip anakarayı fırçayla çiz. Büyük alanlar için fırçayı büyüt ( [ ve ] tuşları ) ya da Kova Dolgu (G) kullan.")
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(440, 64)
	v.add_child(tip)
	v.add_child(HSeparator.new())
	var h_13 := _header("HARİTA BOYUTU")
	h_13.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(h_13)
	nd_size = OptionButton.new()
	for p in SIZE_PRESETS:
		nd_size.add_item(p[0] if p[1] == 0 else "%s  (%d × %d hücre)" % [p[0], p[1], p[2]])
	nd_size.selected = 2
	v.add_child(nd_size)
	var row := HBoxContainer.new()
	v.add_child(row)
	row.add_child(_small("Genişlik"))
	nd_cols = _spin(40, 1000, 10, 320, func(_v: float) -> void: nd_size.selected = SIZE_PRESETS.size() - 1)
	row.add_child(nd_cols)
	row.add_child(_small("Yükseklik"))
	nd_rows = _spin(30, 1000, 10, 220, func(_v: float) -> void: nd_size.selected = SIZE_PRESETS.size() - 1)
	row.add_child(nd_rows)
	nd_size.item_selected.connect(func(i: int) -> void:
		if SIZE_PRESETS[i][1] > 0:
			nd_cols.set_value_no_signal(SIZE_PRESETS[i][1])
			nd_rows.set_value_no_signal(SIZE_PRESETS[i][2]))
	var srow := HBoxContainer.new()
	v.add_child(srow)
	srow.add_child(_small("Ölçek: 1 hücre ="))
	nd_scale = _spin(0.5, 1000, 0.5, 10, func(_v: float) -> void: pass)
	nd_scale.suffix = "km"
	nd_scale.custom_minimum_size.x = 120
	nd_cols.custom_minimum_size.x = 100
	nd_rows.custom_minimum_size.x = 100
	srow.add_child(nd_scale)
	var info := _small("")
	v.add_child(info)
	var upd := func(_x = null) -> void:
		info.text = "Harita genişliği: %d km × %d km" % [int(nd_cols.value * nd_scale.value), int(nd_rows.value * nd_scale.value)]
	nd_cols.value_changed.connect(upd)
	nd_rows.value_changed.connect(upd)
	nd_scale.value_changed.connect(upd)
	nd_size.item_selected.connect(upd)
	upd.call()
	new_dialog.confirmed.connect(func() -> void:
		_toast("Harita oluşturuluyor...")
		_new_campaign(nd_start.selected, int(nd_cols.value), int(nd_rows.value), nd_scale.value)
		if nd_start.selected == 1:
			view.brush_terrain = Defs.T.GRASS
			view.brush_radius = clampi(int(nd_cols.value) / 60, 3, 12)
			_set_tool(T.TERRAIN)
			_toast("Boş okyanus hazır. Arazi fırçasıyla anakaranı çiz!"))


func _open_new_dialog() -> void:
	new_dialog.size = Vector2i(540, 330)
	new_dialog.popup_centered(Vector2i(540, 330))


# =================================================================== zarlar

func _build_dice_tray(center: Control) -> void:
	dice_tray = PanelContainer.new()
	center.add_child(dice_tray)
	dice_tray.visible = false
	var v := VBoxContainer.new()
	dice_tray.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var dh := _header("ZAR AT")
	dh.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(dh)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(_btn("Kapat", _toggle_dice_tray, "D"))
	var dice_row := HBoxContainer.new()
	v.add_child(dice_row)
	for sides in Dice.TYPES:
		var b := DieButton.new(sides)
		var sd: int = sides
		b.pressed.connect(func() -> void: _roll_die(sd))
		dice_row.add_child(b)
	var opt := HBoxContainer.new()
	v.add_child(opt)
	opt.add_child(_small("Adet"))
	dice_count = _spin(1, 50, 1, 1, func(_v: float) -> void: pass)
	opt.add_child(dice_count)
	opt.add_child(_small("Bonus"))
	dice_mod = _spin(-50, 50, 1, 0, func(_v: float) -> void: pass)
	opt.add_child(dice_mod)
	var group := ButtonGroup.new()
	for a in [[-1, "Dezavantaj"], [0, "Normal"], [1, "Avantaj"]]:
		var b := _btn(a[1], func() -> void: pass, "Sadece tek d20 atışında geçerli: iki zar atılır, düşük/yüksek olan sayılır")
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = a[0] == 0
		var val: int = a[0]
		b.pressed.connect(func() -> void: dice_adv = val)
		opt.add_child(b)
	var who_row := HBoxContainer.new()
	v.add_child(who_row)
	who_row.add_child(_small("Atan"))
	dice_who = OptionButton.new()
	dice_who.custom_minimum_size.x = 150
	who_row.add_child(dice_who)
	dice_expr = LineEdit.new()
	dice_expr.placeholder_text = "Serbest: 2d6+3, 1d8+1d6, 4d6, d%"
	dice_expr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dice_expr.text_submitted.connect(func(t: String) -> void: roll(t, _who_name()))
	who_row.add_child(dice_expr)
	who_row.add_child(_btn("At", func() -> void: roll(dice_expr.text, _who_name())))
	dice_history = VBoxContainer.new()
	v.add_child(dice_history)
	dice_tray.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dice_tray.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dice_tray.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dice_tray.offset_bottom = -10


func _toggle_dice_tray() -> void:
	dice_tray.visible = not dice_tray.visible
	if dice_tray.visible:
		var cur := dice_who.selected
		dice_who.clear()
		dice_who.add_item("(Genel)")
		dice_who.set_item_metadata(0, "")
		for id in campaign.characters:
			dice_who.add_item(str(campaign.characters[id].get("name", "?")))
			dice_who.set_item_metadata(dice_who.item_count - 1, id)
		dice_who.selected = clampi(cur, 0, dice_who.item_count - 1)
		_refresh_roll_history()


func _who_name() -> String:
	if dice_who == null or dice_who.selected <= 0:
		return ""
	return dice_who.get_item_text(dice_who.selected)


func _roll_die(sides: int) -> void:
	# kutuya yazılıp henüz Enter'a basılmamış sayıyı da hemen kullan
	var n := _spin_now(dice_count)
	var m := _spin_now(dice_mod)
	var expr := "%dd%d" % [n, sides]
	if m != 0:
		expr += ("+%d" % m) if m > 0 else str(m)
	var who := _who_name()
	roll(expr, (who + " — " if who != "" else "") + expr.replace("1d", "d"), dice_adv if (sides == 20 and n == 1) else 0)


func roll(expr: String, label := "", adv := 0) -> void:
	var r := Dice.roll_expr(expr, adv)
	if not r.get("ok", false):
		_toast("Geçersiz zar ifadesi: " + expr + "  (örnek: 2d6+3)")
		return
	dice_overlay.show_roll(r, label)
	_log_roll(r, label)


func _log_roll(r: Dictionary, label: String) -> void:
	var time := Time.get_time_string_from_system().substr(0, 5)
	_roll_log.push_front({"time": time, "label": label, "total": r["total"], "text": r["text"], "nat": r.get("nat", 0)})
	if _roll_log.size() > 30:
		_roll_log.pop_back()
	_toast("Zar: %s = %d" % [label if label != "" else r["expr"], r["total"]])
	_refresh_roll_history()


func _refresh_roll_history() -> void:
	if dice_history == null:
		return
	_clear(dice_history)
	for i in mini(6, _roll_log.size()):
		var e: Dictionary = _roll_log[i]
		var l := Label.new()
		l.text = "%s   %s   = %d     %s" % [e["time"], e["label"] if e["label"] != "" else "Zar", e["total"], e["text"]]
		var col := Color(0.85, 0.8, 0.7)
		if e["nat"] == 20:
			col = Color("ffd700")
		elif e["nat"] == 1:
			col = Color("ff6a5a")
		l.add_theme_color_override("font_color", col if i == 0 else col.darkened(0.25))
		l.add_theme_font_size_override("font_size", 14 if i == 0 else 12)
		dice_history.add_child(l)


# =================================================================== gezinme çubuğu & ağaç

func _refresh_breadcrumb() -> void:
	_clear(breadcrumb)
	var up := _btn("<  Üst Harita", _go_up, "Backspace")
	up.disabled = not campaign.maps.has(current.parent_id)
	breadcrumb.add_child(up)
	breadcrumb.add_child(VSeparator.new())
	var chain := campaign.path_to(current.id)
	for i in chain.size():
		var m: MapData = chain[i]
		if i > 0:
			breadcrumb.add_child(_small(">"))
		var id := m.id
		var b := _btn(m.name if m.name != "" else "(adsız)", func() -> void: enter_map(id))
		b.flat = true
		if m == current:
			b.add_theme_color_override("font_color", GOLD)
			b.add_theme_color_override("font_hover_color", GOLD)
		breadcrumb.add_child(b)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	breadcrumb.add_child(spacer)
	breadcrumb.add_child(_small("%s haritası  •  %d×%d hücre  •  1 hücre = %s %s" % [
			Defs.KIND_NAMES[current.kind], current.cols, current.rows, str(snappedf(current.scale, 0.01)), current.unit]))
	campaign_name_edit.text = campaign.name


func _refresh_tree() -> void:
	_tree_building = true
	map_tree.clear()
	var root := map_tree.create_item()
	if campaign.maps.has(campaign.root_id):
		_add_tree_item(root, campaign.maps[campaign.root_id], 0)
	for m in campaign.maps.values():
		if m.id != campaign.root_id and not campaign.maps.has(m.parent_id):
			_add_tree_item(root, m, 0)
	_tree_building = false


func _add_tree_item(parent: TreeItem, m: MapData, depth: int) -> void:
	if depth > 32:
		return
	var it := map_tree.create_item(parent)
	it.set_text(0, "%s   [%s]" % [m.name, Defs.KIND_NAMES[m.kind]])
	it.set_metadata(0, m.id)
	if m == current:
		it.set_custom_color(0, GOLD)
		it.select(0)
	for ch in campaign.children_of(m.id):
		_add_tree_item(it, ch, depth + 1)


func _on_tree_selected() -> void:
	if _tree_building:
		return
	var it := map_tree.get_selected()
	if it and str(it.get_metadata(0)) != current.id:
		enter_map.call_deferred(str(it.get_metadata(0)))


# =================================================================== küçük UI yardımcıları

func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func _panel(parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	parent.add_child(p)
	return p


func _btn(text: String, cb: Callable, tip := "") -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


## SpinBox'ın o an kutuda yazan değeri (Enter'a basılmasa da). Geçersizse mevcut değer.
func _spin_now(sb: SpinBox) -> int:
	var t := sb.get_line_edit().text.strip_edges().replace("+", "")
	if t.is_valid_int():
		var v := clampi(t.to_int(), int(sb.min_value), int(sb.max_value))
		sb.set_value_no_signal(v)
		return v
	return int(sb.value)


func _toggle(text: String, on: bool, cb: Callable, tip := "") -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.toggle_mode = true
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_NONE
	b.toggled.connect(cb)
	return b


func _check(text: String, on: bool) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.button_pressed = on
	c.focus_mode = Control.FOCUS_NONE
	return c


func _header(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_font_size_override("font_size", 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	l.add_theme_font_size_override("font_size", 13)
	return l


func _hint(box: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 240
	l.add_theme_color_override("font_color", Color(0.75, 0.71, 0.62))
	l.add_theme_font_size_override("font_size", 13)
	box.add_child(l)


func _line(text: String, cb: Callable) -> LineEdit:
	var e := LineEdit.new()
	e.text = text
	e.text_changed.connect(cb)
	return e


func _text_edit(text: String, cb: Callable) -> TextEdit:
	var t := TextEdit.new()
	t.text = text
	t.custom_minimum_size.y = 110
	t.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	t.text_changed.connect(func() -> void: cb.call(t.text))
	return t


func _spin(lo: float, hi: float, step: float, value: float, cb: Callable) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.value_changed.connect(cb)
	return s


func _kind_option(selected: int) -> OptionButton:
	var o := OptionButton.new()
	for k in Defs.KIND_NAMES:
		o.add_item(k)
	o.selected = selected
	return o
