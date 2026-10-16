class_name MapView
extends Node2D
## Haritayı çizer ve harita üzerindeki tüm araç etkileşimlerini yönetir.
## Katman sırası: arazi -> bölge rengi -> nesneler (kıyı, sınır, yol, sembol, yazı) -> sis -> üst katman (seçim, ölçüm, grup)

signal selection_changed
signal request_enter(symbol: Dictionary)
signal map_changed
signal hover_changed(text: String)

enum Tool { SELECT, TERRAIN, FILL, REGION, PATH, SYMBOL, LABEL, FOG, MEASURE, ERASER, PARTY }

const CELL := Defs.CELL
const PARTY_RADIUS := 15.0
const PARTY_SIGHT := 5   # grubun çevresinde açılan sis (hücre)
const HISTORY_LIMIT := 60

var map: MapData
var cam: CameraRig
var tool: int = Tool.SELECT
var play_mode := false

# araç ayarları
var brush_terrain := 4
var brush_radius := 2
var brush_region := 0
var region_land_only := true
var fog_reveal := true
var path_type := "river"
var symbol_type := "city"
var symbol_size := 1.0
var auto_name := false
var show_grid := false
var show_names := true
## HD: shader ile organik kıyılar, dokular, yumuşak sınırlar. Kapalıysa klasik kare hücreler.
var hd := true:
	set(v):
		hd = v
		_apply_shader_params()
		redraw()
## Parşömen: eski harita görünümü (sepya, kağıt dokusu, kenar karartma)
var parchment := false:
	set(v):
		parchment = v
		_apply_shader_params()

# seçim
var selected: Dictionary = {}
var selected_kind := ""   # "symbol" | "path" | "label" | ""

# iç durum
var _terrain_img: Image
var _terrain_tex: ImageTexture
var _region_img: Image
var _region_tex: ImageTexture
var _mask_img: Image
var _mask_tex: ImageTexture
var _region_pal_img: Image
var _region_pal_tex: ImageTexture
var _terrain_mat: ShaderMaterial
var _region_mat: ShaderMaterial
var _fog_img: Image
var _fog_tex: ImageTexture
var _terrain_sprite: Sprite2D
var _region_sprite: Sprite2D
var _fog_sprite: Sprite2D
var _objects: Node2D
var _top: Node2D
var _font: Font        # arayüz ipuçları
var _font_title: Font  # bölge isimleri, yazılar
var _font_text: Font   # sembol / yol isimleri

var _coast_lines := PackedVector2Array()
var _region_info := {}    # rid -> {"sum": Vector2, "count": int}
var _region_colors := {}  # rid -> Color

var _history := {}        # map_id -> {"undo": [], "redo": []}
var _stroke := false
var _last_cell := Vector2i(-9999, -9999)
var _path_pts := PackedVector2Array()
var _drag_obj := false
var _drag_recorded := false
var _drag_last := Vector2.ZERO
var _drag_party := false
var _left_pan := false
var _measure_a := Vector2.INF
var _measure_b := Vector2.INF
var _measuring := false
var _mouse := Vector2.ZERO
var _hover: Dictionary = {}
var _hover_cell := Vector2i(-1, -1)
var export_mode := false   # PNG dışa aktarırken araç ipuçlarını gizle


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_font_title = Defs.font_title
	_font_text = Defs.font_text
	_terrain_sprite = _make_sprite(TEXTURE_FILTER_NEAREST)
	_terrain_mat = ShaderMaterial.new()
	_terrain_mat.shader = preload("res://shaders/terrain.gdshader")
	_terrain_sprite.material = _terrain_mat
	_region_sprite = _make_sprite(TEXTURE_FILTER_NEAREST)
	_region_mat = ShaderMaterial.new()
	_region_mat.shader = preload("res://shaders/region.gdshader")
	_region_sprite.material = _region_mat
	_objects = Node2D.new()
	add_child(_objects)
	_objects.draw.connect(_draw_objects)
	_fog_sprite = _make_sprite(TEXTURE_FILTER_LINEAR)
	_top = Node2D.new()
	add_child(_top)
	_top.draw.connect(_draw_top)


func _make_sprite(filter: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.scale = Vector2(CELL, CELL)
	s.texture_filter = filter
	add_child(s)
	return s


# =================================================================== harita yükleme / yeniden oluşturma

func set_map(m: MapData) -> void:
	map = m
	_path_pts = PackedVector2Array()
	_measure_a = Vector2.INF
	_stroke = false
	_drag_obj = false
	clear_selection()
	rebuild_all()


func rebuild_all() -> void:
	if map == null:
		return
	_terrain_img = Image.create(map.cols, map.rows, false, Image.FORMAT_R8)
	_mask_img = Image.create(map.cols, map.rows, false, Image.FORMAT_R8)
	_region_img = Image.create(map.cols, map.rows, false, Image.FORMAT_R8)
	_fog_img = Image.create(map.cols, map.rows, false, Image.FORMAT_RGBA8)
	_rebuild_region_colors()
	for r in map.rows:
		for c in map.cols:
			_set_terrain_px(c, r)
			_set_region_px(c, r)
			_set_fog_px(c, r)
	_terrain_tex = ImageTexture.create_from_image(_terrain_img)
	_mask_tex = ImageTexture.create_from_image(_mask_img)
	_region_tex = ImageTexture.create_from_image(_region_img)
	_fog_tex = ImageTexture.create_from_image(_fog_img)
	_terrain_sprite.texture = _terrain_tex
	_region_sprite.texture = _region_tex
	_fog_sprite.texture = _fog_tex
	_recompute_coast()
	_recompute_borders()
	_apply_shader_params()
	update_fog_visibility()
	redraw()


func _apply_shader_params() -> void:
	if map == null or _terrain_tex == null:
		return
	# Zindan ve binalarda duvarlar düz kalsın diye bükme kapalı
	var warp := 1.0
	match map.kind:
		Defs.Kind.CITY: warp = 0.3
		Defs.Kind.DUNGEON, Defs.Kind.BUILDING: warp = 0.0
	for mat in [_terrain_mat, _region_mat]:
		mat.set_shader_parameter("map_cells", Vector2(map.cols, map.rows))
		mat.set_shader_parameter("warp_strength", warp)
		mat.set_shader_parameter("terrain_idx", _terrain_tex)
		mat.set_shader_parameter("water_mask", _mask_tex)
		mat.set_shader_parameter("palette", Defs.terrain_palette)
		mat.set_shader_parameter("fancy", hd)
	_terrain_mat.set_shader_parameter("parchment", parchment)
	_region_mat.set_shader_parameter("region_idx", _region_tex)
	_region_mat.set_shader_parameter("region_pal", _region_pal_tex)


func rebuild_regions() -> void:
	_rebuild_region_colors()
	for r in map.rows:
		for c in map.cols:
			_set_region_px(c, r)
	_region_tex.update(_region_img)
	_region_pal_tex.update(_region_pal_img)
	_recompute_borders()
	redraw()


func update_fog_visibility() -> void:
	_fog_sprite.visible = map != null and map.fog_enabled
	_fog_sprite.modulate.a = 1.0 if play_mode else 0.5


func redraw() -> void:
	_objects.queue_redraw()
	_top.queue_redraw()


func _rebuild_region_colors() -> void:
	_region_colors.clear()
	if _region_pal_img == null:
		_region_pal_img = Image.create(256, 1, false, Image.FORMAT_RGBA8)
		_region_pal_tex = ImageTexture.create_from_image(_region_pal_img)
	_region_pal_img.fill(Color(0, 0, 0, 0))
	for reg in map.regions:
		var rid := int(reg["id"])
		_region_colors[rid] = reg["color"]
		if rid > 0 and rid < 256:
			_region_pal_img.set_pixel(rid, 0, reg["color"])


func _set_terrain_px(c: int, r: int) -> void:
	var t := map.terrain[map.idx(c, r)]
	_terrain_img.set_pixel(c, r, Color8(t, 0, 0))
	_mask_img.set_pixel(c, r, Color8(255 * Defs.water_lookup[t], 0, 0))


func _set_region_px(c: int, r: int) -> void:
	var rid := map.region[map.idx(c, r)]
	_region_img.set_pixel(c, r, Color8(rid if _region_colors.has(rid) else 0, 0, 0))


func _set_fog_px(c: int, r: int) -> void:
	var open := map.fog[map.idx(c, r)] == 1
	_fog_img.set_pixel(c, r, Color(0, 0, 0, 0) if open else Color(0.07, 0.06, 0.05, 1.0))


func _recompute_coast() -> void:
	var pts := PackedVector2Array()
	var w := Defs.water_lookup
	var t := map.terrain
	for r in map.rows:
		for c in map.cols:
			var a := w[t[r * map.cols + c]]
			if c + 1 < map.cols and w[t[r * map.cols + c + 1]] != a:
				pts.append(Vector2((c + 1) * CELL, r * CELL))
				pts.append(Vector2((c + 1) * CELL, (r + 1) * CELL))
			if r + 1 < map.rows and w[t[(r + 1) * map.cols + c]] != a:
				pts.append(Vector2(c * CELL, (r + 1) * CELL))
				pts.append(Vector2((c + 1) * CELL, (r + 1) * CELL))
	_coast_lines = pts


## Sınır çizgilerini artık shader çiziyor; burada sadece bölge isimlerinin konumu hesaplanır.
func _recompute_borders() -> void:
	_region_info.clear()
	var g := map.region
	for r in map.rows:
		for c in map.cols:
			var a := g[r * map.cols + c]
			if a != 0:
				if not _region_info.has(a):
					_region_info[a] = {"sum": Vector2.ZERO, "count": 0}
				_region_info[a]["sum"] += Vector2(c + 0.5, r + 0.5)
				_region_info[a]["count"] += 1


# =================================================================== geri al / yinele

func _hist() -> Dictionary:
	if not _history.has(map.id):
		_history[map.id] = {"undo": [], "redo": []}
	return _history[map.id]


## Değişiklikten ÖNCE çağrılır.
func record() -> void:
	var h := _hist()
	h["undo"].append(map.to_dict())
	if h["undo"].size() > HISTORY_LIMIT:
		h["undo"].pop_front()
	h["redo"].clear()
	map_changed.emit()


func undo() -> void:
	var h := _hist()
	if h["undo"].is_empty():
		return
	h["redo"].append(map.to_dict())
	map.from_dict(h["undo"].pop_back())
	clear_selection()
	rebuild_all()
	map_changed.emit()


func redo() -> void:
	var h := _hist()
	if h["redo"].is_empty():
		return
	h["undo"].append(map.to_dict())
	map.from_dict(h["redo"].pop_back())
	clear_selection()
	rebuild_all()
	map_changed.emit()


# =================================================================== seçim

func select(obj: Dictionary, kind: String) -> void:
	selected = obj
	selected_kind = kind
	selection_changed.emit()
	redraw()


func clear_selection() -> void:
	if selected_kind == "" and selected.is_empty():
		return
	selected = {}
	selected_kind = ""
	selection_changed.emit()
	redraw()


func delete_selected() -> void:
	if selected_kind == "":
		return
	record()
	_remove_object(selected, selected_kind)
	clear_selection()


func _remove_object(obj: Dictionary, kind: String) -> void:
	match kind:
		"symbol": map.symbols.erase(obj)
		"path": map.paths.erase(obj)
		"label": map.labels.erase(obj)
	redraw()


func set_tool(t: int) -> void:
	tool = t
	_path_pts = PackedVector2Array()
	if t != Tool.MEASURE:
		_measure_a = Vector2.INF
	redraw()


# =================================================================== girdi

func _zoom() -> float:
	return cam.zoom.x if cam else 1.0


func _cell_at(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


func _unhandled_input(event: InputEvent) -> void:
	if map == null:
		return
	if event is InputEventMouseMotion:
		_mouse = get_global_mouse_position()
		_on_motion(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse = get_global_mouse_position()
		get_viewport().gui_release_focus()
		if event.pressed:
			_on_press(event)
		else:
			_on_release()


func _on_press(event: InputEventMouseButton) -> void:
	var p := _mouse
	# Shift + sürükle her araçta ölçer
	if event.shift_pressed and tool != Tool.PATH and tool != Tool.REGION:
		_start_measure(p)
		return
	if play_mode and tool == Tool.SELECT:
		_play_press(p)
		return
	match tool:
		Tool.SELECT:
			_select_press(p, event.double_click)
		Tool.TERRAIN, Tool.FOG:
			record()
			_stroke = true
			_last_cell = Vector2i(-9999, -9999)
			_paint_to(p)
		Tool.REGION:
			record()
			if event.shift_pressed:
				_flood_region(_cell_at(p))
			else:
				_stroke = true
				_last_cell = Vector2i(-9999, -9999)
				_paint_to(p)
		Tool.FILL:
			var c := _cell_at(p)
			if map.in_bounds(c.x, c.y):
				record()
				_flood_terrain(c)
		Tool.PATH:
			_path_pts = PackedVector2Array([p])
			_stroke = true
		Tool.SYMBOL:
			record()
			var s := {"type": symbol_type, "pos": p, "name": _default_symbol_name(symbol_type),
					"notes": "", "size": symbol_size, "link": ""}
			map.symbols.append(s)
			select(s, "symbol")
		Tool.LABEL:
			record()
			var l := {"text": "Yeni Yazı", "pos": p, "size": 22, "color": Color("2b2118")}
			map.labels.append(l)
			select(l, "label")
		Tool.MEASURE:
			_start_measure(p)
		Tool.ERASER:
			var hit := _hit_any(p)
			if not hit.is_empty():
				record()
				_remove_object(hit["obj"], hit["kind"])
				if hit["obj"] == selected:
					clear_selection()
		Tool.PARTY:
			record()
			map.party_pos = p
			_reveal_around_party()
			redraw()


func _default_symbol_name(type: String) -> String:
	var cat := str(Defs.symbols.get(type, {}).get("cat", ""))
	if cat == "Doğa":
		return ""
	if auto_name and cat == "Yerleşim":
		return Defs.random_name()
	return Defs.symbol_name(type)


func _on_release() -> void:
	if _measuring:
		_measuring = false
	if _stroke and tool == Tool.PATH:
		_finish_path()
	_stroke = false
	_drag_obj = false
	_left_pan = false
	if _drag_party:
		_drag_party = false
		_reveal_around_party()
	redraw()


func _on_motion(event: InputEventMouseMotion) -> void:
	var p := _mouse
	var left := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not left and (_stroke or _drag_obj or _left_pan or _drag_party or _measuring):
		_on_release()   # bırakma olayı bir panelin üstünde kaybolduysa
	if _measuring:
		_measure_b = p
	elif _left_pan:
		cam.pan_screen(event.relative)
	elif _drag_party:
		map.party_pos = p
		map_changed.emit()
	elif _drag_obj:
		if not _drag_recorded:
			record()
			_drag_recorded = true
		_move_object(selected, selected_kind, p - _drag_last)
		_drag_last = p
	elif _stroke:
		if tool == Tool.PATH:
			var straight := Input.is_key_pressed(KEY_SHIFT)
			if straight:
				_path_pts = PackedVector2Array([_path_pts[0], p])
			elif _path_pts[_path_pts.size() - 1].distance_to(p) > 6.0 / _zoom():
				_path_pts.append(p)
		else:
			_paint_to(p)
	_update_hover(p)
	_top.queue_redraw()


func _update_hover(p: Vector2) -> void:
	var h := _hit_symbol(p)
	if h != _hover:
		_hover = h
		var shape := Input.CURSOR_POINTING_HAND if (not h.is_empty() and _can_enter(h)) else Input.CURSOR_ARROW
		Input.set_default_cursor_shape(shape)
	var c := _cell_at(p)
	if c != _hover_cell:
		_hover_cell = c
		hover_changed.emit(_describe_cell(c))


func _describe_cell(c: Vector2i) -> String:
	if not map.in_bounds(c.x, c.y):
		return ""
	var t := map.terrain[map.idx(c.x, c.y)]
	var txt := "Hücre %d, %d  •  %s" % [c.x, c.y, Defs.terrains[t]["name"] if t < Defs.terrains.size() else "?"]
	var rid := map.region[map.idx(c.x, c.y)]
	if rid != 0:
		var reg := map.get_region(rid)
		if not reg.is_empty():
			txt += "  •  " + str(reg["name"])
	return txt


func _can_enter(s: Dictionary) -> bool:
	return str(s.get("link", "")) != "" or Defs.is_enterable(str(s["type"]))


# ---------- seç / taşı

func _select_press(p: Vector2, double: bool) -> void:
	var hit := _hit_any(p)
	if hit.is_empty():
		clear_selection()
		_left_pan = true
		return
	if double and hit["kind"] == "symbol":
		_drag_obj = false
		request_enter.emit(hit["obj"])
		return
	select(hit["obj"], hit["kind"])
	_drag_obj = true
	_drag_recorded = false
	_drag_last = p


func _play_press(p: Vector2) -> void:
	if map.party_pos.x >= 0 and p.distance_to(map.party_pos) < PARTY_RADIUS * 1.2:
		record()
		_drag_party = true
		return
	var s := _hit_symbol(p)
	if not s.is_empty():
		select(s, "symbol")
		if _can_enter(s):
			request_enter.emit(s)
		return
	clear_selection()
	_left_pan = true


func _move_object(obj: Dictionary, kind: String, delta: Vector2) -> void:
	match kind:
		"symbol", "label":
			obj["pos"] += delta
		"path":
			var pts: PackedVector2Array = obj["points"]
			for i in pts.size():
				pts[i] += delta
			obj["points"] = pts
	redraw()


# ---------- isabet testleri

func _hit_symbol(p: Vector2) -> Dictionary:
	if map == null:
		return {}
	for i in range(map.symbols.size() - 1, -1, -1):
		var s: Dictionary = map.symbols[i]
		var r := Defs.SYMBOL_BASE * float(s.get("size", 1.0))
		if p.distance_to(s["pos"]) <= r:
			return s
	return {}


func _hit_label(p: Vector2) -> Dictionary:
	for i in range(map.labels.size() - 1, -1, -1):
		var l: Dictionary = map.labels[i]
		if _label_rect(l).has_point(p):
			return l
	return {}


func _hit_path(p: Vector2) -> Dictionary:
	var tol := 7.0 / _zoom()
	for i in range(map.paths.size() - 1, -1, -1):
		var path: Dictionary = map.paths[i]
		var pts: PackedVector2Array = path["points"]
		var w := float(path.get("width", 3.0)) * 0.5 + tol
		for j in pts.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(p, pts[j], pts[j + 1])
			if q.distance_to(p) <= w:
				return path
	return {}


func _hit_any(p: Vector2) -> Dictionary:
	var s := _hit_symbol(p)
	if not s.is_empty():
		return {"obj": s, "kind": "symbol"}
	var l := _hit_label(p)
	if not l.is_empty():
		return {"obj": l, "kind": "label"}
	var pa := _hit_path(p)
	if not pa.is_empty():
		return {"obj": pa, "kind": "path"}
	return {}


func _label_font(l: Dictionary) -> Font:
	return _font_text if str(l.get("font", "title")) == "text" else _font_title


func _label_rect(l: Dictionary) -> Rect2:
	var size := int(l.get("size", 22))
	var w := _label_font(l).get_string_size(str(l["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos: Vector2 = l["pos"]
	return Rect2(pos.x - w / 2.0, pos.y - size * 0.75, w, size * 1.1)


# ---------- fırça boyama

func _paint_to(p: Vector2) -> void:
	var c := _cell_at(p)
	if c == _last_cell:
		return
	if _last_cell.x == -9999:
		_stamp(c)
	else:
		var steps := maxi(absi(c.x - _last_cell.x), absi(c.y - _last_cell.y))
		for i in range(1, steps + 1):
			var q := Vector2(_last_cell).lerp(Vector2(c), float(i) / steps)
			_stamp(Vector2i(roundi(q.x), roundi(q.y)))
	_last_cell = c
	match tool:
		Tool.TERRAIN:
			_terrain_tex.update(_terrain_img)
			_mask_tex.update(_mask_img)
			_recompute_coast()
		Tool.REGION:
			_region_tex.update(_region_img)
			_recompute_borders()
		Tool.FOG:
			_fog_tex.update(_fog_img)
	_objects.queue_redraw()


func _stamp(center: Vector2i) -> void:
	var r := brush_radius - 1
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r + r:
				continue
			var c := center.x + dx
			var rr := center.y + dy
			if not map.in_bounds(c, rr):
				continue
			var i := map.idx(c, rr)
			match tool:
				Tool.TERRAIN:
					map.terrain[i] = brush_terrain
					_set_terrain_px(c, rr)
				Tool.REGION:
					if region_land_only and brush_region != 0 and Defs.water_lookup[map.terrain[i]] == 1:
						continue
					map.region[i] = brush_region
					_set_region_px(c, rr)
				Tool.FOG:
					map.fog[i] = 1 if fog_reveal else 0
					_set_fog_px(c, rr)


func _flood(start: Vector2i, layer: PackedByteArray, value: int, land_only: bool) -> PackedByteArray:
	var target := layer[map.idx(start.x, start.y)]
	if target == value:
		return layer
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if not map.in_bounds(c.x, c.y):
			continue
		var i := map.idx(c.x, c.y)
		if layer[i] != target:
			continue
		if land_only and Defs.water_lookup[map.terrain[i]] == 1:
			continue
		layer[i] = value
		stack.append(Vector2i(c.x + 1, c.y))
		stack.append(Vector2i(c.x - 1, c.y))
		stack.append(Vector2i(c.x, c.y + 1))
		stack.append(Vector2i(c.x, c.y - 1))
	return layer


func _flood_terrain(c: Vector2i) -> void:
	map.terrain = _flood(c, map.terrain, brush_terrain, false)
	rebuild_all()


func _flood_region(c: Vector2i) -> void:
	if not map.in_bounds(c.x, c.y):
		return
	map.region = _flood(c, map.region, brush_region, region_land_only and brush_region != 0)
	rebuild_regions()


func fill_fog(open: bool) -> void:
	record()
	map.fog.fill(1 if open else 0)
	rebuild_all()


func _reveal_around_party() -> void:
	if not map.fog_enabled or map.party_pos.x < 0:
		return
	var c := _cell_at(map.party_pos)
	for dy in range(-PARTY_SIGHT, PARTY_SIGHT + 1):
		for dx in range(-PARTY_SIGHT, PARTY_SIGHT + 1):
			if dx * dx + dy * dy > PARTY_SIGHT * PARTY_SIGHT + 1:
				continue
			if map.in_bounds(c.x + dx, c.y + dy):
				map.fog[map.idx(c.x + dx, c.y + dy)] = 1
				_set_fog_px(c.x + dx, c.y + dy)
	_fog_tex.update(_fog_img)


# ---------- yol çizimi

func _finish_path() -> void:
	if _path_pts.size() >= 2 and _path_pts[0].distance_to(_path_pts[_path_pts.size() - 1]) > 4.0:
		var def: Dictionary = Defs.path_types[path_type]
		var pts := _path_pts
		if def["smooth"] and pts.size() > 2:
			pts = MapGenerator.smooth(pts, 2)
		record()
		map.paths.append({"type": path_type, "points": pts, "name": "", "width": def["width"]})
	_path_pts = PackedVector2Array()
	redraw()


# ---------- ölçüm

func _start_measure(p: Vector2) -> void:
	_measure_a = p
	_measure_b = p
	_measuring = true


func measure_text(a: Vector2, b: Vector2) -> String:
	var cells := a.distance_to(b) / CELL
	var dist := cells * map.scale
	var txt := "%.1f %s" % [dist, map.unit]
	match map.unit:
		"km":
			txt += "  •  yaya ~%.1f gün, atlı ~%.1f gün" % [dist / 30.0, dist / 60.0]
		"mil", "mile":
			txt += "  •  yaya ~%.1f gün" % (dist / 24.0)
		"m":
			txt += "  •  ~%d tur (9 m/tur)" % ceili(dist / 9.0)
		"ft":
			txt += "  •  ~%d tur (30 ft/tur)" % ceili(dist / 30.0)
	return txt


# =================================================================== çizim

func _text(ci: CanvasItem, pos: Vector2, text: String, size: int, color: Color,
		outline := Color(0.96, 0.92, 0.8, 0.85), outline_size := 5, font: Font = null) -> void:
	if font == null:
		font = _font_text
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := Vector2(pos.x - w / 2.0, pos.y + size * 0.35)
	if outline_size > 0:
		ci.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline_size, outline)
	ci.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_objects() -> void:
	if map == null:
		return
	var ci := _objects
	if not hd and _coast_lines.size() > 0:
		ci.draw_multiline(_coast_lines, Color(0.16, 0.12, 0.08, 0.7), 1.5)
	if show_grid:
		_draw_grid(ci)
	for path in map.paths:
		_draw_path(ci, path)
	_draw_region_names(ci)
	for s in map.symbols:
		var r := Defs.SYMBOL_BASE * float(s.get("size", 1.0))
		SymbolPainter.draw_symbol(ci, str(s["type"]), s["pos"], r)
		if str(s.get("link", "")) != "":
			# alt haritası olan sembolleri işaretle
			var b: Vector2 = s["pos"] + Vector2(r * 0.8, -r * 0.8)
			ci.draw_circle(b, 4.5, Color("f2d16b"))
			ci.draw_arc(b, 4.5, 0, TAU, 12, SymbolPainter.INK, 1.2, true)
			ci.draw_line(b + Vector2(-1.5, -2.2), b + Vector2(1.8, 0), SymbolPainter.INK, 1.3)
			ci.draw_line(b + Vector2(1.8, 0), b + Vector2(-1.5, 2.2), SymbolPainter.INK, 1.3)
		var nm := str(s.get("name", ""))
		if show_names and nm != "":
			_text(ci, s["pos"] + Vector2(0, r + 9), nm, 15, SymbolPainter.INK)
	for l in map.labels:
		_text(ci, l["pos"], str(l["text"]), int(l.get("size", 22)), l.get("color", Color.BLACK),
				Color(0.96, 0.92, 0.8, 0.7), 6, _label_font(l))


func _draw_grid(ci: CanvasItem) -> void:
	var pts := PackedVector2Array()
	var size := map.pixel_size()
	for c in range(1, map.cols):
		pts.append(Vector2(c * CELL, 0))
		pts.append(Vector2(c * CELL, size.y))
	for r in range(1, map.rows):
		pts.append(Vector2(0, r * CELL))
		pts.append(Vector2(size.x, r * CELL))
	ci.draw_multiline(pts, Color(0, 0, 0, 0.15), 1.0)


func _draw_region_names(ci: CanvasItem) -> void:
	for reg in map.regions:
		var rid := int(reg["id"])
		if not _region_info.has(rid):
			continue
		var info: Dictionary = _region_info[rid]
		var size := int(clampf(sqrt(float(info["count"])) * 1.4, 14.0, 60.0))
		var center: Vector2 = info["sum"] / float(info["count"]) * CELL - Vector2(0, size * 1.2)
		var col: Color = reg["color"]
		_text(ci, center, _spaced(str(reg["name"]).to_upper()), size,
				Color(col.darkened(0.55), 0.85), Color(0.96, 0.92, 0.8, 0.6), maxi(4, size / 5), _font_title)


func _spaced(t: String) -> String:
	var out := ""
	for i in t.length():
		out += t[i] + (" " if i < t.length() - 1 else "")
	return out


func _draw_path(ci: CanvasItem, path: Dictionary) -> void:
	var pts: PackedVector2Array = path["points"]
	if pts.size() < 2:
		return
	var type := str(path["type"])
	var def: Dictionary = Defs.path_types.get(type, Defs.path_types["road"])
	var col: Color = def["color"]
	var w := float(path.get("width", def["width"]))
	match def["style"]:
		"river":
			ci.draw_polyline(pts, col.darkened(0.35), w + 2.0, true)
			ci.draw_polyline(pts, col, w, true)
		"wall":
			ci.draw_polyline(pts, SymbolPainter.INK, w + 2.0, true)
			ci.draw_polyline(pts, col, w, true)
			_dash(ci, pts, col.lightened(0.25), w * 0.35, 4.0, 6.0)
		"dash":
			_dash(ci, pts, col, w, 10.0, 6.0)
		"dot":
			_dots(ci, pts, col, w * 0.6, 7.0)
		_:
			ci.draw_polyline(pts, col, w, true)
	var nm := str(path.get("name", ""))
	if show_names and nm != "" and pts.size() >= 2:
		var mid := pts.size() / 2
		_text(ci, pts[mid] + Vector2(0, -w - 7), nm, 14, col.darkened(0.5))


## Tüm çizgi boyunca kesintisiz kesik çizgi (segmentlere göre değil, toplam uzunluğa göre)
func _dash(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, dash: float, gap: float) -> void:
	var period := dash + gap
	var acc := 0.0
	var segs := PackedVector2Array()
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len <= 0.0:
			continue
		var t := 0.0
		while t < seg_len:
			var phase := fmod(acc + t, period)
			if phase < dash:
				var e := minf(seg_len, t + (dash - phase))
				segs.append(a.lerp(b, t / seg_len))
				segs.append(a.lerp(b, e / seg_len))
				t = e
			else:
				t += period - phase
		acc += seg_len
	if segs.size() > 0:
		ci.draw_multiline(segs, col, w)


func _dots(ci: CanvasItem, pts: PackedVector2Array, col: Color, r: float, spacing: float) -> void:
	var carry := 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg_len := a.distance_to(b)
		var t := carry
		while t < seg_len:
			ci.draw_circle(a.lerp(b, t / seg_len), r, col)
			t += spacing
		carry = t - seg_len


func _draw_top() -> void:
	if map == null:
		return
	var ci := _top
	var z := _zoom()
	var size := map.pixel_size()
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0.17, 0.13, 0.09), false, 3.0 / z)

	if map.party_pos.x >= 0:
		SymbolPainter.draw_party(ci, map.party_pos, PARTY_RADIUS)
	if export_mode:
		return

	# seçim vurgusu
	match selected_kind:
		"symbol":
			var r := Defs.SYMBOL_BASE * float(selected.get("size", 1.0)) + 4.0
			ci.draw_arc(selected["pos"], r, 0, TAU, 40, Color("ffcc33"), 2.5 / z, true)
		"label":
			ci.draw_rect(_label_rect(selected).grow(3), Color("ffcc33"), false, 2.0 / z)
		"path":
			ci.draw_polyline(selected["points"], Color(1, 0.8, 0.2, 0.45), float(selected.get("width", 3.0)) + 8.0, true)

	# çizilmekte olan yol
	if _path_pts.size() >= 2:
		var def: Dictionary = Defs.path_types[path_type]
		ci.draw_polyline(_path_pts, def["color"], def["width"], true)

	# fırça imleci
	if not play_mode and tool in [Tool.TERRAIN, Tool.REGION, Tool.FOG]:
		var c := _cell_at(_mouse)
		var center := (Vector2(c) + Vector2(0.5, 0.5)) * CELL
		ci.draw_arc(center, (brush_radius - 0.5) * CELL, 0, TAU, 40, Color(1, 1, 1, 0.8), 1.5 / z, true)
		ci.draw_arc(center, (brush_radius - 0.5) * CELL + 1.5 / z, 0, TAU, 40, Color(0, 0, 0, 0.6), 1.0 / z, true)
	elif not play_mode and tool == Tool.SYMBOL:
		ci.draw_arc(_mouse, Defs.SYMBOL_BASE * symbol_size, 0, TAU, 32, Color(1, 1, 1, 0.6), 1.5 / z, true)

	# ölçüm cetveli
	if _measure_a != Vector2.INF and _measure_a.distance_to(_measure_b) > 1.0:
		ci.draw_line(_measure_a, _measure_b, Color(0, 0, 0, 0.6), 5.0 / z, true)
		ci.draw_line(_measure_a, _measure_b, Color("ffe08a"), 2.5 / z, true)
		ci.draw_circle(_measure_a, 4.0 / z, Color("ffe08a"))
		ci.draw_circle(_measure_b, 4.0 / z, Color("ffe08a"))
		_draw_tooltip(ci, _measure_b + Vector2(12, 18) / z, measure_text(_measure_a, _measure_b), z)

	# üzerine gelinen sembol için ipucu
	if not _hover.is_empty() and not _drag_obj:
		var nm := str(_hover.get("name", ""))
		var t := nm if nm != "" else Defs.symbol_name(str(_hover["type"]))
		if _can_enter(_hover):
			t += "   [" + ("tıkla: gir" if play_mode else "çift tık: gir") + "]"
		_draw_tooltip(ci, _mouse + Vector2(14, -14) / z, t, z)


func _draw_tooltip(ci: CanvasItem, pos: Vector2, text: String, z: float) -> void:
	var fs := 14
	var sz := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	ci.draw_set_transform(pos, 0.0, Vector2.ONE / z)
	var rect := Rect2(Vector2(-6, -sz.y + 2), sz + Vector2(12, 8))
	ci.draw_rect(rect, Color(0.1, 0.08, 0.06, 0.9), true)
	ci.draw_rect(rect, Color("c9a86a"), false, 1.0)
	ci.draw_string(_font, Vector2(0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f2ead7"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
