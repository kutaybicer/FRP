class_name PortraitPainter
extends RefCounted
## Karakter ve yaratık portrelerini vektör olarak çizer (harici resim yok).
## Tasarım koordinatları: merkez (0,0), yarıçap 100, y aşağı doğru.
## look["body"]: "bust" (insansı büst, varsayılan) veya yaratık iskeleti
## (quad, bird, bat, fish, serpent, hydra, dragon, turtle, frog, octopus, crab, jelly,
##  spider, scorpion, insect, eye, mimic, slime, cube, treant, wisp, elemental, centaur).

const INK := Color("21180f")
const GOLD := Color("d9b44a")
const BONE := Color("e8dcc0")
const METAL := Color("9aa3ad")

static var _ci: CanvasItem
static var _clip := PackedVector2Array()
static var _center := Vector2.ZERO
static var _scale := 1.0
static var _ghost := false
static var L: Dictionary = {}
# büst geometrisi
static var _hy := -14.0
static var _rx := 31.0
static var _ry := 38.0
static var _jaw := 0.72
static var _hs := 1.0


static func draw(ci: CanvasItem, look: Dictionary, center: Vector2, radius: float, frame := true) -> void:
	_ci = ci
	L = look
	_center = center
	_scale = radius / 100.0
	_ghost = false
	_tf(Vector2.ZERO, 1.0)
	_background()
	_ghost = bool(look.get("ghost", false))
	match str(look.get("body", "bust")):
		"quad": _quad()
		"bird": _bird()
		"bat": _bat()
		"fish": _fish()
		"serpent": _serpent()
		"hydra": _hydra()
		"dragon": _dragon()
		"turtle": _turtle()
		"frog": _frog()
		"octopus": _octopus()
		"crab": _crab()
		"jelly": _jelly()
		"spider": _spider()
		"scorpion": _scorpion()
		"insect": _insect()
		"eye": _eye_monster()
		"mimic": _mimic()
		"slime": _slime()
		"cube": _cube()
		"treant": _treant()
		"wisp": _wisp()
		"elemental": _elemental()
		"centaur": _centaur()
		_: _bust()
	_ghost = false
	_tf(Vector2.ZERO, 1.0)
	if frame:
		_frame()
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Başka çizerlerin (eşya ikonları) yardımcıları kullanabilmesi için: kırpma yok, ölçek = radius/100
static func begin(ci: CanvasItem, center: Vector2, radius: float) -> void:
	_ci = ci
	L = {}
	_center = center
	_scale = radius / 100.0
	_ghost = false
	ci.draw_set_transform(center, 0.0, Vector2.ONE * _scale)
	_clip = _P([Vector2(-400, -400), Vector2(400, -400), Vector2(400, 400), Vector2(-400, 400)])


static func end() -> void:
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## İç dönüşüm: çizimi kaydır/ölçekle (kırpma çemberi de buna göre ayarlanır)
static func _tf(off: Vector2, k: float) -> void:
	_ci.draw_set_transform(_center + off * _scale, 0.0, Vector2.ONE * (_scale * k))
	_clip = _ell(-off / k, 97.0 / k, 97.0 / k, 0.0, 72)


# =================================================================== yardımcılar

static func _c(key: String, def := Color.WHITE) -> Color:
	var v = L.get(key, def)
	if v is Color:
		return v
	if v is String and v != "":
		return Color(v)
	return def


static func _tint(c: Color) -> Color:
	if _ghost:
		return Color(c.lerp(Color(0.8, 0.93, 1.0), 0.45), c.a * 0.55)
	return c


static func _P(arr: Array) -> PackedVector2Array:
	return PackedVector2Array(arr)


static func _fill(pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	for poly in Geometry2D.intersect_polygons(pts, _clip):
		if poly.size() >= 3:
			_ci.draw_colored_polygon(poly, _tint(col))


static func _stroke(pts: PackedVector2Array, w := 2.2, col := INK) -> void:
	if pts.size() < 3:
		return
	for poly in Geometry2D.intersect_polygons(pts, _clip):
		if poly.size() >= 3:
			var p2: PackedVector2Array = poly.duplicate()
			p2.append(poly[0])
			_ci.draw_polyline(p2, _tint(col), w, true)


static func _line(pts: PackedVector2Array, col: Color, w := 2.0) -> void:
	_line_raw(pts, _tint(col), w)


## Çerçeve dışına taşmasın diye çizgiler de kırpılır
static func _line_raw(pts: PackedVector2Array, col: Color, w: float) -> void:
	if pts.size() < 2:
		return
	for part in Geometry2D.intersect_polyline_with_polygon(pts, _clip):
		if part.size() >= 2:
			_ci.draw_polyline(part, col, w, true)


static func _arc(c: Vector2, r: float, a0: float, a1: float, n: int, col: Color, w := 1.0, _aa := true) -> void:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_line_raw(pts, col, w)


static func _dot(c: Vector2, r: float, col: Color) -> void:
	_fill(_ell(c, r, r, 0.0, 12 if r < 4.0 else 20), col)


static func _bbox(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


static func _xf(pts: PackedVector2Array, c: Vector2, k: float, off: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = c + (pts[i] - c) * k + off
	return out


static func _move(pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var out := pts.duplicate()
	for i in out.size():
		out[i] += off
	return out


static func _mirror(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	for i in out.size():
		out[i].x = -out[i].x
	return out


## Gölgeli dolgu: koyu taban + ışıklı iç + parlama + mürekkep çizgi
static func _shape(pts: PackedVector2Array, col: Color, shade := 1.0, w := 2.2) -> void:
	if pts.size() < 3:
		return
	if shade > 0.0:
		_fill(pts, col.darkened(0.32 * shade))
		var bb := _bbox(pts)
		var c := bb.get_center()
		_fill(_xf(pts, c, 0.9, Vector2(-bb.size.x * 0.04, -bb.size.y * 0.05)), col)
		if shade >= 1.0 and bb.size.length() > 24.0:
			var hc := c + Vector2(-bb.size.x * 0.17, -bb.size.y * 0.2)
			_fill(_xf(pts, hc, 0.42, Vector2.ZERO), Color(col.lightened(0.18), 0.45))
	else:
		_fill(pts, col)
	if w > 0.0:
		_stroke(pts, w)


static func _ell(c: Vector2, rx: float, ry: float, rot := 0.0, n := 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n)
	var cr := cos(rot)
	var sr := sin(rot)
	for i in n:
		var a := TAU * i / n
		var p := Vector2(cos(a) * rx, sin(a) * ry)
		pts[i] = c + Vector2(p.x * cr - p.y * sr, p.x * sr + p.y * cr)
	return pts


static func _smooth(ctrl: PackedVector2Array, it := 2) -> PackedVector2Array:
	var p := ctrl
	for _i in it:
		var out := PackedVector2Array()
		var n := p.size()
		for i in n:
			var a := p[i]
			var b := p[(i + 1) % n]
			out.append(a.lerp(b, 0.25))
			out.append(a.lerp(b, 0.75))
		p = out
	return p


static func _bez(a: Vector2, b: Vector2, c: Vector2, n := 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		pts.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
	return pts


static func _bez3(a: Vector2, b: Vector2, c: Vector2, d: Vector2, n := 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var ab := a.lerp(b, t)
		var bc := b.lerp(c, t)
		var cd := c.lerp(d, t)
		pts.append(ab.lerp(bc, t).lerp(bc.lerp(cd, t), t))
	return pts


## Bir çizgi boyunca incelen şerit çokgeni (kuyruk, bacak, boyun, boynuz, dokunaç)
static func _taper(path: PackedVector2Array, w0: float, w1: float) -> PackedVector2Array:
	var n := path.size()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n:
		var a := path[maxi(i - 1, 0)]
		var b := path[mini(i + 1, n - 1)]
		var t := (b - a).normalized()
		var nr := Vector2(-t.y, t.x)
		var w := lerpf(w0, w1, float(i) / maxf(n - 1, 1)) * 0.5
		left.append(path[i] + nr * w)
		right.append(path[i] - nr * w)
	right.reverse()
	return left + right


static func _tube(path: PackedVector2Array, w0: float, w1: float, col: Color, w := 2.0) -> void:
	var poly := _taper(path, w0, w1)
	_fill(poly, col.darkened(0.25))
	var inner := _taper(_move(path, Vector2(-0.6, -0.9)), w0 * 0.62, w1 * 0.62)
	_fill(inner, col)
	if w > 0.0:
		_stroke(poly, w)


static func _glow(c: Vector2, r: float, col: Color, steps := 5) -> void:
	for i in steps:
		var t := float(i) / steps
		var rr := r * (1.0 - t * 0.75)
		_fill(_ell(c, rr, rr, 0.0, 24), Color(col, 0.08 + t * 0.12))


static func _hash(i: float) -> float:
	return fposmod(sin(i * 127.1 + 311.7) * 43758.5453, 1.0)


static func _flame(base: Vector2, h: float, w: float, col: Color, col2: Color, lean := 0.0) -> void:
	var tip := base + Vector2(lean * h, -h)
	var pts := _bez(base + Vector2(-w, 0), base + Vector2(-w * 0.9, -h * 0.55), tip, 8)
	pts.append_array(_bez(tip, base + Vector2(w * 0.9, -h * 0.5), base + Vector2(w, 0), 8))
	_fill(pts, col)
	var inner := _xf(pts, base, 0.55, Vector2(0, -h * 0.05))
	_fill(inner, col2)


# =================================================================== arka plan ve çerçeve

static func _background() -> void:
	var bg := _c("bg", Color("4a5a6a"))
	for i in 12:
		var t := float(i) / 11.0
		_ci.draw_circle(Vector2(-12.0 * t, -16.0 * t), 100.0 - t * 62.0, bg.darkened(0.5).lerp(bg.lightened(0.22), t))


static func _frame() -> void:
	_ci.draw_arc(Vector2.ZERO, 97.5, 0, TAU, 96, INK, 5.0, true)
	_ci.draw_arc(Vector2.ZERO, 96.0, 0, TAU, 96, GOLD, 2.4, true)
	_ci.draw_arc(Vector2.ZERO, 99.0, 0, TAU, 96, Color(GOLD, 0.6), 1.2, true)


# =================================================================== İNSANSI BÜST

static func _bust() -> void:
	_hs = float(L.get("head_size", 1.0))
	var b := float(L.get("build", 1.0))
	_rx = 30.0 * _hs
	_ry = 37.0 * _hs
	_hy = -14.0
	_jaw = 0.72
	match str(L.get("head", "round")):
		"long":
			_rx *= 0.92
			_ry *= 1.07
			_jaw = 0.6
		"square":
			_rx *= 1.06
			_jaw = 0.92
		"broad":
			_rx *= 1.14
			_ry *= 0.97
			_jaw = 0.88
	var face := str(L.get("face", "human"))
	if face == "bull" or face == "ape":
		_rx *= 1.08
		_jaw = 0.95
	if bool(L.get("golem", false)):
		_jaw = 0.98
	var helm := str(L.get("helm", "none"))
	_back_layer(b, helm)
	_torso(b)
	_neck()
	_ears()
	_head()
	if helm != "full":
		_face(face)
		_marks()
	if helm in ["none", "crown", "circlet", "bandana"] or (helm == "wizard" and str(L.get("hair", "")) != "none"):
		_hair_front(helm)
	if helm != "full":
		_beard()
	_horns()
	_helm(helm)
	_front_items(b)


# ---------- arka katman: kanatlar, hale, uzun saç, kapüşon, silah

static func _back_layer(b: float, helm: String) -> void:
	var wings := str(L.get("wings", "none"))
	if wings != "none":
		for s: float in [-1.0, 1.0]:
			_wing(s, wings)
	if bool(L.get("halo", false)):
		var hc := Vector2(0, _hy - _ry * 0.35)
		_glow(hc, _rx * 2.1, Color("fff3b0"), 6)
		var ring := _ell(hc + Vector2(0, -_ry * 0.1), _rx * 1.45, _ry * 1.25)
		_line(ring + PackedVector2Array([ring[0]]), Color("f7dc6f"), 3.5)
	if bool(L.get("collar", false)):
		var col := _c("accent", Color("8a1a2a"))
		var pts := _P([Vector2(-_rx * 1.6, 50), Vector2(-_rx * 1.9, _hy - _ry * 0.3), Vector2(-_rx * 0.9, _hy + _ry * 0.4),
				Vector2(0, 40), Vector2(_rx * 0.9, _hy + _ry * 0.4), Vector2(_rx * 1.9, _hy - _ry * 0.3), Vector2(_rx * 1.6, 50)])
		_shape(pts, _c("cloth", Color("1a1418")), 0.6)
		_fill(_xf(pts, Vector2(0, 30), 0.82, Vector2(0, 4)), col.darkened(0.2))
	_back_item(b)
	if helm == "hood":
		var col := _c("cloth", Color("3a3a3a"))
		var pts := _smooth(_P([Vector2(0, _hy - _ry * 1.32), Vector2(_rx * 1.3, _hy - _ry * 0.9), Vector2(_rx * 1.55, _hy + _ry * 0.4),
				Vector2(_rx * 1.9, 60), Vector2(-_rx * 1.9, 60), Vector2(-_rx * 1.55, _hy + _ry * 0.4), Vector2(-_rx * 1.3, _hy - _ry * 0.9)]), 2)
		_shape(pts, col, 1.0)
		return
	if helm == "full":
		return
	var hair := str(L.get("hair", "short"))
	var hc := _c("hair_color", Color("4a3020"))
	match hair:
		"long", "braid":
			var pts := _smooth(_P([Vector2(0, _hy - _ry * 1.12), Vector2(_rx * 1.15, _hy - _ry * 0.7), Vector2(_rx * 1.3, _hy + _ry * 0.6),
					Vector2(_rx * 1.45, 72), Vector2(_rx * 0.4, 66), Vector2(-_rx * 0.4, 66), Vector2(-_rx * 1.45, 72),
					Vector2(-_rx * 1.3, _hy + _ry * 0.6), Vector2(-_rx * 1.15, _hy - _ry * 0.7)]), 2)
			if hair == "braid":
				pts = _smooth(_P([Vector2(0, _hy - _ry * 1.1), Vector2(_rx * 1.12, _hy - _ry * 0.6), Vector2(_rx * 1.15, _hy + _ry * 0.5),
						Vector2(_rx * 0.6, _hy + _ry * 0.8), Vector2(-_rx * 0.6, _hy + _ry * 0.8), Vector2(-_rx * 1.15, _hy + _ry * 0.5), Vector2(-_rx * 1.12, _hy - _ry * 0.6)]), 2)
			_shape(pts, hc, 0.7)
			_hair_strands(pts, hc)
		"ponytail":
			var tail := _bez3(Vector2(_rx * 0.5, _hy - _ry * 0.7), Vector2(_rx * 1.5, _hy - _ry * 0.6), Vector2(_rx * 1.4, _hy + _ry * 0.6), Vector2(_rx * 1.15, 40))
			_tube(tail, 16, 5, hc)
		"curly", "wild":
			var pts := PackedVector2Array()
			var n := 22
			for i in n:
				var a := TAU * i / n
				var r := 1.25 + 0.06 * sin(a * 7.0)
				if hair == "wild":
					r = 1.28 + (0.12 if i % 2 == 0 else 0.0)
				pts.append(Vector2(cos(a) * _rx * r, _hy - _ry * 0.12 + sin(a) * _ry * r * 0.95))
			if hair == "curly":
				pts = _smooth(pts, 1)
			_shape(pts, hc, 0.7)
		"mane":
			var pts := PackedVector2Array()
			for i in 28:
				var a := TAU * i / 28.0
				var r := 1.55 + (0.18 if i % 2 == 0 else 0.0)
				pts.append(Vector2(cos(a) * _rx * r, _hy + sin(a) * _ry * r * 0.92))
			_shape(pts, hc, 0.8)
		"snakes":
			for i in 7:
				var a := lerpf(-2.8, -0.35, i / 6.0)
				var base := Vector2(cos(a) * _rx * 0.8, _hy + sin(a) * _ry * 0.8)
				var tip := base + Vector2(cos(a) * 38, sin(a) * 30)
				var mid := base.lerp(tip, 0.5) + Vector2(sin(a * 3.0) * 12, 6)
				_tube(_bez(base, mid, tip, 10), 9, 5, hc)
				_shape(_ell(tip, 6, 4.5, a), hc.lightened(0.1), 0.4, 1.5)
				_dot(tip + Vector2(cos(a), sin(a)) * 2 + Vector2(0, -1.5), 1.2, Color("f1c40f"))
		"feathers":
			for i in 7:
				var a := lerpf(-2.6, -0.55, i / 6.0)
				var base := Vector2(cos(a) * _rx * 0.7, _hy + sin(a) * _ry * 0.7)
				var tip := base + Vector2(cos(a) * 34, sin(a) * 36 - 6)
				var mid := base.lerp(tip, 0.5)
				var nrm := (tip - base).normalized().orthogonal() * 7.0
				_shape(_P([base, mid + nrm, tip, mid - nrm]), hc.lightened(0.05 * (i % 2)), 0.5, 1.6)
	if str(L.get("horns", "none")) == "crest":
		var hcn := _c("horn_color", BONE)
		for i in 5:
			var a := lerpf(-2.5, -0.65, i / 4.0)
			var base := Vector2(cos(a) * _rx * 0.85, _hy + sin(a) * _ry * 0.85)
			var tip := base + Vector2(cos(a) * 30, sin(a) * 26 - 4)
			var nrm := (tip - base).normalized().orthogonal() * 7.0
			_shape(_P([base + nrm, tip, base - nrm]), hcn, 0.6, 1.6)


static func _hair_strands(pts: PackedVector2Array, hc: Color) -> void:
	var bb := _bbox(pts)
	for i in 7:
		var x := lerpf(bb.position.x + 8, bb.end.x - 8, i / 6.0)
		if absf(x) < _rx * 0.9:
			continue
		_line(_bez(Vector2(x * 0.9, _hy), Vector2(x * 1.05, 20), Vector2(x, bb.end.y - 6), 8), hc.darkened(0.3), 1.2)


static func _wing(s: float, kind: String) -> void:
	var root := Vector2(s * 30, 30)
	match kind:
		"feather":
			var col := _c("hair_color", Color("e8e0d0")).lightened(0.15)
			if L.get("face", "") == "bird":
				col = _c("skin", col)
			for i in 6:
				var a := lerpf(-1.9, -0.25, i / 5.0)
				var dir := Vector2(cos(a) * s, sin(a))
				var tip := root + dir * (95.0 - i * 6.0)
				var nrm := (tip - root).normalized().orthogonal() * (10.0 - i * 0.6)
				_shape(_P([root, root.lerp(tip, 0.45) + nrm, tip, root.lerp(tip, 0.55) - nrm * 0.6]), col.darkened(0.05 * i), 0.5, 1.6)
		"bat":
			var col := _c("skin", Color("5a2a2a")).darkened(0.25)
			var top := root + Vector2(s * 55, -95)
			var f1 := root + Vector2(s * 98, -40)
			var f2 := root + Vector2(s * 92, 12)
			var f3 := root + Vector2(s * 70, 40)
			var pts := _P([root, top, f1.lerp(top, 0.25) + Vector2(s * -6, 8), f1, f2.lerp(f1, 0.3) + Vector2(s * -10, 6), f2, f3.lerp(f2, 0.3) + Vector2(s * -10, 4), f3, root + Vector2(0, 30)])
			_shape(pts, col, 0.6)
			for f in [f1, f2, f3]:
				_line(_P([top, f]), INK, 2.0)
			_line(_P([root, top]), INK, 3.0)
		"fairy":
			var col := Color(0.75, 0.95, 1.0, 0.45)
			for k: float in [0.0, 1.0]:
				var c := root + Vector2(s * (45 - k * 8), -40 + k * 62)
				var e := _ell(c, 34 - k * 12, 20 - k * 6, s * (-0.6 + k * 0.9))
				_fill(e, col)
				_stroke(e, 1.4, Color(0.6, 0.8, 0.95, 0.9))


static func _back_item(b: float) -> void:
	var item := str(L.get("item", "none"))
	var acc := _c("accent", GOLD)
	var wood := Color("6b4a2a")
	match item:
		"sword", "greatsword":
			var big := 1.35 if item == "greatsword" else 1.0
			var hilt := Vector2(62, -40 - 12 * big)
			var dir := Vector2(-0.32, 1).normalized()
			var tip := hilt + dir * 150 * big
			var guard := hilt + dir * 18
			var blade := _P([guard + dir.orthogonal() * 5 * big, tip, guard - dir.orthogonal() * 5 * big])
			_shape(blade, Color("c8d0d8"), 0.5, 1.8)
			_line(_P([guard, tip.lerp(guard, 0.1)]), Color("eef2f6"), 1.2)
			_tube(_P([guard - dir.orthogonal() * 14 * big, guard + dir.orthogonal() * 14 * big]), 5, 5, acc)
			_tube(_P([hilt, guard]), 6, 6, Color("4a2a1a"))
			_shape(_ell(hilt - dir * 3, 5 * big, 5 * big), acc, 0.5, 1.6)
		"axe":
			var top := Vector2(70, -62)
			_tube(_P([Vector2(40, 110), top]), 7, 6, wood)
			var d := (top - Vector2(40, 110)).normalized()
			var c := top + d * -12
			var o := d.orthogonal()
			var blade := _P([c + o * 2 + d * 10, c + o * 30 + d * 22, c + o * 36, c + o * 30 - d * 22, c + o * 2 - d * 10])
			_shape(_smooth(blade, 1), Color("b8c0c8"), 0.6, 2.0)
			_shape(_P([c - o * 2 + d * 6, c - o * 14, c - o * 2 - d * 6]), Color("8a9098"), 0.4, 1.6)
		"hammer":
			var top := Vector2(66, -58)
			_tube(_P([Vector2(42, 110), top]), 7, 6, wood)
			var d := (top - Vector2(42, 110)).normalized()
			var o := d.orthogonal()
			var c := top - d * 8
			_shape(_P([c + o * 24 + d * 12, c + o * 24 - d * 12, c - o * 18 - d * 12, c - o * 18 + d * 12]), METAL, 0.7, 2.0)
			_line(_P([c + o * 10 + d * 12, c + o * 10 - d * 12]), acc, 2.0)
		"spear":
			var top := Vector2(80, -90)
			_tube(_P([Vector2(36, 115), top]), 5, 4, wood)
			var d := (top - Vector2(36, 115)).normalized()
			_shape(_P([top - d * 4 + d.orthogonal() * 6, top + d * 26, top - d * 4 - d.orthogonal() * 6, top - d * 10]), Color("c8d0d8"), 0.5, 1.6)
			_line(_P([top - d * 6 + d.orthogonal() * 4, top - d * 14]), Color("c0392b"), 2.5)
		"staff":
			var top := Vector2(76, -66)
			_tube(_bez(Vector2(66, 120), Vector2(80, 20), top, 10), 7, 6, wood)
			var crystal := _P([top + Vector2(0, -26), top + Vector2(9, -10), top + Vector2(0, 4), top + Vector2(-9, -10)])
			_glow(top + Vector2(0, -11), 30, acc.lightened(0.3))
			_shape(crystal, acc.lightened(0.2), 0.6, 1.8)
			_line(_bez(top + Vector2(-8, 4), top + Vector2(-12, -6), top + Vector2(-6, -14), 6), wood.darkened(0.2), 3)
			_line(_bez(top + Vector2(8, 4), top + Vector2(12, -6), top + Vector2(6, -14), 6), wood.darkened(0.2), 3)
		"bow":
			var arc := _bez(Vector2(-58, -78), Vector2(-112, 10), Vector2(-60, 108), 18)
			_tube(arc, 6, 6, Color("8a5a2b"))
			_line(_P([Vector2(-58, -78), Vector2(-60, 108)]), Color("e8e0d0"), 1.2)
			for i in 3:
				var x := 52.0 + i * 7
				_line(_P([Vector2(x, 40), Vector2(x + 14, -52)]), Color("6b4a2a"), 2.2)
				_fill(_P([Vector2(x + 14, -52), Vector2(x + 9, -40), Vector2(x + 19, -42)]), Color("e8e0d0"))
		"scythe":
			var top := Vector2(64, -72)
			_tube(_bez(Vector2(46, 118), Vector2(70, 20), top, 8), 6, 5, Color("3a2a1a"))
			var blade := _bez(top, top + Vector2(-50, -30), top + Vector2(-92, 14), 12)
			var inner := _bez(top + Vector2(-92, 14), top + Vector2(-50, -14), top + Vector2(0, 8), 12)
			_shape(blade + inner, Color("b8c0c8"), 0.5, 1.8)
		"lute":
			var body := _ell(Vector2(64, 50), 22, 30, -0.5)
			_tube(_P([Vector2(56, 30), Vector2(30, -62)]), 7, 6, Color("5e3b1f"))
			_shape(body, Color("b8783a"), 0.8, 2.0)
			_dot(Vector2(62, 44), 5, INK)
		"dagger":
			for s: float in [-1.0, 1.0]:
				var hilt := Vector2(s * 58, -30)
				var tip := hilt + Vector2(-s * 22, 70)
				var d := (tip - hilt).normalized()
				_shape(_P([hilt + d * 10 + d.orthogonal() * 3.5, tip, hilt + d * 10 - d.orthogonal() * 3.5]), Color("c8d0d8"), 0.4, 1.5)
				_tube(_P([hilt + d * 10 - d.orthogonal() * 8, hilt + d * 10 + d.orthogonal() * 8]), 3.5, 3.5, acc)
				_tube(_P([hilt - d * 4, hilt + d * 10]), 4.5, 4.5, Color("3a2a1a"))


# ---------- gövde ve kıyafet

static func _torso_pts(b: float) -> PackedVector2Array:
	var sy := 47.0
	return _smooth(_P([Vector2(-104 * b, 130), Vector2(-92 * b, 74), Vector2(-64 * b, sy), Vector2(-20, sy - 7),
			Vector2(20, sy - 7), Vector2(64 * b, sy), Vector2(92 * b, 74), Vector2(104 * b, 130)]), 2)


static func _torso(b: float) -> void:
	var outfit := str(L.get("outfit", "clothes"))
	var cloth := _c("cloth", Color("6b4a2a"))
	var acc := _c("accent", GOLD)
	var skin := _c("skin", Color("e0ac7e"))
	var pts := _torso_pts(b)
	if bool(L.get("feather_body", false)):
		_shape(pts, _c("hair_color", Color("5a3a22")), 1.0)
		for i in 14:
			var x := -70.0 + (i % 7) * 23.0 * b + (8.0 if i >= 7 else 0.0)
			var y := 62.0 + (i / 7) * 16.0
			_line(_bez(Vector2(x - 9, y), Vector2(x, y + 9), Vector2(x + 9, y), 6), _c("hair_color").darkened(0.35), 1.5)
		return
	match outfit:
		"none":
			_shape(pts, skin, 1.0)
			_line(_bez(Vector2(-30 * b, 66), Vector2(-14, 76), Vector2(-2, 68), 8), skin.darkened(0.3), 1.6)
			_line(_bez(Vector2(30 * b, 66), Vector2(14, 76), Vector2(2, 68), 8), skin.darkened(0.3), 1.6)
			if bool(L.get("fur", false)):
				_fur_strokes(pts, skin)
		"bones":
			_shape(pts, cloth.darkened(0.3), 0.5)
			var bone := _c("skin", BONE)
			_tube(_P([Vector2(0, 46), Vector2(0, 120)]), 7, 7, bone)
			for i in 4:
				var y := 60.0 + i * 13.0
				_line(_bez(Vector2(-4, y), Vector2(-38 * b, y - 6), Vector2(-46 * b, y + 10), 10), bone.darkened(0.25), 6.0)
				_line(_bez(Vector2(-4, y), Vector2(-38 * b, y - 6), Vector2(-46 * b, y + 10), 10), bone, 3.5)
				_line(_bez(Vector2(4, y), Vector2(38 * b, y - 6), Vector2(46 * b, y + 10), 10), bone.darkened(0.25), 6.0)
				_line(_bez(Vector2(4, y), Vector2(38 * b, y - 6), Vector2(46 * b, y + 10), 10), bone, 3.5)
			_shape(_ell(Vector2(-60 * b, 54), 16, 9, 0.25), bone, 0.5, 1.6)
			_shape(_ell(Vector2(60 * b, 54), 16, 9, -0.25), bone, 0.5, 1.6)
		"plate":
			_shape(pts, cloth, 1.0)
			var tab := _P([Vector2(-17, 58), Vector2(17, 58), Vector2(21, 130), Vector2(-21, 130)])
			_shape(tab, acc, 0.5, 1.8)
			_line(_P([Vector2(0, 44), Vector2(0, 58)]), cloth.lightened(0.3), 2.0)
			for s: float in [-1.0, 1.0]:
				var pc := Vector2(s * 60 * b, 56)
				var p1 := _ell(pc, 30 * b, 20, s * 0.28)
				_shape(p1, cloth.lightened(0.08), 1.0)
				_line(_bez(pc + Vector2(-s * 24 * b, 4), pc + Vector2(0, 14), pc + Vector2(s * 26 * b, 8), 8), cloth.darkened(0.35), 1.6)
				for k in 3:
					_dot(pc + Vector2(s * (k * 9 - 9) * b, -10 + k * 2), 1.6, cloth.lightened(0.45))
			var gorget := _P([Vector2(-26, 42), Vector2(26, 42), Vector2(22, 56), Vector2(-22, 56)])
			_shape(gorget, cloth.lightened(0.12), 0.6, 1.8)
		"chain":
			_shape(pts, cloth, 0.8)
			for row in 6:
				var y := 56.0 + row * 9.0
				for i in 16:
					var x := -90.0 + i * 12.0 + (6.0 if row % 2 == 1 else 0.0)
					if Geometry2D.is_point_in_polygon(Vector2(x, y), pts):
						_arc(Vector2(x, y), 4.0, 0.2, PI - 0.2, 6, _tint(cloth.darkened(0.35)), 1.1)
			var tab := _P([Vector2(-22, 52), Vector2(22, 52), Vector2(26, 130), Vector2(-26, 130)])
			_shape(tab, acc, 0.6, 1.8)
			_shape(_ell(Vector2(0, 86), 9, 9), GOLD, 0.5, 1.4)
		"leather":
			_shape(pts, cloth, 1.0)
			var strap := _P([Vector2(-54 * b, 50), Vector2(-40 * b, 46), Vector2(48 * b, 120), Vector2(32 * b, 126)])
			_shape(strap, cloth.darkened(0.35), 0.4, 1.6)
			_shape(_P([Vector2(-5, 82), Vector2(7, 82), Vector2(9, 93), Vector2(-3, 93)]), GOLD, 0.3, 1.4)
			for s: float in [-1.0, 1.0]:
				_shape(_ell(Vector2(s * 62 * b, 56), 24 * b, 13, s * 0.3), cloth.lightened(0.1), 0.8)
			_line(_P([Vector2(0, 42), Vector2(0, 74)]), cloth.darkened(0.4), 1.6)
			for k in 4:
				_line(_P([Vector2(-4, 48 + k * 7), Vector2(4, 51 + k * 7)]), acc, 1.4)
		"robe":
			_shape(pts, cloth, 1.0)
			var v := _P([Vector2(-24, 40), Vector2(24, 40), Vector2(0, 92)])
			_fill(v, cloth.darkened(0.45))
			_fill(_P([Vector2(-14, 40), Vector2(14, 40), Vector2(0, 74)]), acc.darkened(0.55))
			_line(_P([Vector2(-26, 40), Vector2(0, 94), Vector2(26, 40)]), acc, 4.0)
			_line(_P([Vector2(0, 94), Vector2(0, 130)]), acc, 4.0)
			for s: float in [-1.0, 1.0]:
				_line(_bez(Vector2(s * 64 * b, 50), Vector2(s * 76 * b, 90), Vector2(s * 70 * b, 130), 10), cloth.darkened(0.3), 1.6)
		"cloak":
			_shape(pts, cloth.lightened(0.15), 0.5)
			var inner := _P([Vector2(-26, 44), Vector2(26, 44), Vector2(34, 130), Vector2(-34, 130)])
			_shape(inner, _c("accent", Color("4a4a4a")).darkened(0.35), 0.4, 1.4)
			for s: float in [-1.0, 1.0]:
				var side := _smooth(_P([Vector2(s * 22, 40), Vector2(s * 70 * b, 46), Vector2(s * 104 * b, 130), Vector2(s * 30, 130)]), 1)
				_shape(side, cloth, 1.0)
			_shape(_ell(Vector2(0, 46), 7, 7), GOLD, 0.6, 1.6)
			_dot(Vector2(0, 46), 3, acc)
		"furs":
			_shape(pts, cloth, 1.0)
			var fur := PackedVector2Array()
			for i in 25:
				var t := i / 24.0
				var x := lerpf(-96 * b, 96 * b, t)
				var yb := 46.0 + absf(x) * 0.12
				fur.append(Vector2(x, yb - 16 - (absf(sin(t * 40.0)) * 3.0)))
			for i in range(24, -1, -1):
				var t := i / 24.0
				var x := lerpf(-96 * b, 96 * b, t)
				fur.append(Vector2(x, 46.0 + absf(x) * 0.18 + 12 + (7.0 if i % 2 == 0 else 0.0)))
			var fur_col := _c("accent", Color("d9cbb0"))
			if L.has("body"):
				fur_col = _c("fur_col", Color("d9cbb0"))
			_shape(fur, fur_col, 1.0)
			_fill(_P([Vector2(-26, 60), Vector2(26, 60), Vector2(18, 130), Vector2(-18, 130)]), skin.darkened(0.08))
			_line(_P([Vector2(-26, 60), Vector2(-18, 130)]), INK, 1.6)
			_line(_P([Vector2(26, 60), Vector2(18, 130)]), INK, 1.6)
		"noble":
			_shape(pts, cloth, 1.0)
			_fill(_P([Vector2(-20, 44), Vector2(20, 44), Vector2(12, 130), Vector2(-12, 130)]), cloth.darkened(0.3))
			for k in 5:
				_shape(_ell(Vector2(0, 58 + k * 13), 3.6, 3.6), acc, 0.4, 1.2)
			var sash := _P([Vector2(-60 * b, 52), Vector2(-46 * b, 48), Vector2(54 * b, 122), Vector2(38 * b, 128)])
			_shape(sash, acc.darkened(0.15), 0.5, 1.6)
			var col_pts := _P([Vector2(-30, 36), Vector2(-12, 46), Vector2(0, 40), Vector2(12, 46), Vector2(30, 36), Vector2(24, 52), Vector2(-24, 52)])
			_shape(col_pts, Color("f2ead7"), 0.4, 1.6)
		"monk":
			_shape(pts, cloth, 1.0)
			_line(_P([Vector2(-26, 44), Vector2(18, 110)]), cloth.darkened(0.4), 3.0)
			_line(_P([Vector2(26, 44), Vector2(-6, 92)]), cloth.darkened(0.4), 3.0)
			_shape(_P([Vector2(-70 * b, 104), Vector2(70 * b, 104), Vector2(72 * b, 116), Vector2(-72 * b, 116)]), acc, 0.5, 1.6)
			for k in 6:
				_dot(Vector2(-32 + k * 13, 40 + absf(k - 2.5) * 1.5), 3.4, Color("5e3b1f"))
		"rags":
			var torn := pts.duplicate()
			_shape(torn, cloth, 1.0)
			for i in 5:
				var x := -70.0 + i * 34.0
				_fill(_P([Vector2(x, 130), Vector2(x + 10, 102 + _hash(i) * 14), Vector2(x + 20, 130)]), cloth.darkened(0.45))
			_shape(_P([Vector2(-50, 76), Vector2(-30, 74), Vector2(-28, 92), Vector2(-48, 94)]), cloth.lightened(0.15), 0.3, 1.2)
			_line(_P([Vector2(-20, 46), Vector2(-6, 66), Vector2(6, 48)]), cloth.darkened(0.45), 1.6)
		_:
			_shape(pts, cloth, 1.0)
			var v := _P([Vector2(-16, 41), Vector2(16, 41), Vector2(0, 66)])
			_fill(v, skin.darkened(0.12))
			_line(_P([Vector2(-18, 40), Vector2(0, 68), Vector2(18, 40)]), cloth.darkened(0.45), 3.0)
			for k in 3:
				_line(_P([Vector2(-5, 52 + k * 5), Vector2(5, 52 + k * 5)]), acc, 1.2)
			for s: float in [-1.0, 1.0]:
				_line(_bez(Vector2(s * 50 * b, 52), Vector2(s * 56 * b, 80), Vector2(s * 52 * b, 120), 8), cloth.darkened(0.3), 1.4)


static func _fur_strokes(pts: PackedVector2Array, col: Color) -> void:
	for i in 26:
		var p := Vector2(-80 + _hash(i) * 160, 52 + _hash(i + 50) * 70)
		if Geometry2D.is_point_in_polygon(p, pts):
			_line(_P([p, p + Vector2(3, 7)]), col.darkened(0.3), 1.3)


static func _neck() -> void:
	var skin := _c("skin", Color("e0ac7e"))
	var w := 12.5 * _hs * (1.2 if float(L.get("build", 1.0)) > 1.2 else 1.0)
	var top := _hy + _ry * 0.55
	if str(L.get("face", "")) == "skull" or L.get("outfit", "") == "bones":
		_tube(_P([Vector2(0, top), Vector2(0, 48)]), 10, 10, _c("skin", BONE))
		for k in 3:
			_line(_P([Vector2(-5, top + 8 + k * 7), Vector2(5, top + 8 + k * 7)]), INK, 1.4)
		return
	var pts := _P([Vector2(-w, top), Vector2(w, top), Vector2(w * 1.15, 48), Vector2(-w * 1.15, 48)])
	_shape(pts, skin.darkened(0.12), 0.4, 2.0)
	_fill(_P([Vector2(-w, top), Vector2(w, top), Vector2(w * 0.9, top + 12), Vector2(-w * 0.9, top + 12)]), skin.darkened(0.3))
	if bool(L.get("bolts", false)):
		for s: float in [-1.0, 1.0]:
			_shape(_P([Vector2(s * w, top + 14), Vector2(s * (w + 12), top + 12), Vector2(s * (w + 12), top + 20), Vector2(s * w, top + 20)]), METAL, 0.5, 1.4)


# ---------- kulaklar

static func _ears() -> void:
	var ears := str(L.get("ears", "human"))
	var skin := _c("skin", Color("e0ac7e"))
	var ey := _hy + _ry * 0.02
	for s: float in [-1.0, 1.0]:
		var x := s * _rx * 0.92
		match ears:
			"human":
				var e := _ell(Vector2(s * _rx * 0.98, ey + 2), 6.5 * _hs, 10 * _hs)
				_shape(e, skin, 0.6, 2.0)
				_line(_bez(Vector2(s * _rx * 1.0, ey - 4), Vector2(s * _rx * 1.12, ey + 2), Vector2(s * _rx * 1.0, ey + 8), 6), skin.darkened(0.35), 1.4)
			"elf", "elf_long", "short_pointed":
				var reach := 26.0 if ears == "elf" else (38.0 if ears == "elf_long" else 13.0)
				var lift := 20.0 if ears == "elf" else (24.0 if ears == "elf_long" else 10.0)
				var pts := _P([Vector2(x, ey + 10), Vector2(x + s * reach, ey - lift), Vector2(x, ey - 7)])
				_shape(_smooth(pts, 1) if ears == "short_pointed" else pts, skin, 0.6, 2.0)
				_line(_P([Vector2(x + s * 3, ey + 5), Vector2(x + s * reach * 0.75, ey - lift * 0.75)]), skin.darkened(0.3), 1.4)
			"goblin":
				var pts := _P([Vector2(x, ey + 10), Vector2(x + s * 48, ey - 14), Vector2(x + s * 40, ey - 2), Vector2(x, ey - 10)])
				_shape(pts, skin, 0.7, 2.0)
				_fill(_P([Vector2(x + s * 4, ey + 3), Vector2(x + s * 38, ey - 10), Vector2(x + s * 4, ey - 4)]), skin.darkened(0.25).lerp(Color("d98880"), 0.3))
			"cat":
				var bx := s * _rx * 0.55
				var by := _hy - _ry * 0.72
				var pts := _P([Vector2(bx - s * 16, by + 8), Vector2(bx + s * 6, by - 28), Vector2(bx + s * 18, by + 6)])
				_shape(pts, skin, 0.6, 2.0)
				_fill(_xf(pts, bx * Vector2(1, 0) + Vector2(0, by), 0.55, Vector2(s * 2, 2)), Color("e8a0a0").lerp(skin, 0.4))
			"rabbit":
				var base := Vector2(s * _rx * 0.35, _hy - _ry * 0.8)
				var e := _ell(base + Vector2(s * 10, -40), 11, 36, s * 0.25)
				_shape(e, skin, 0.6, 2.0)
				_fill(_ell(base + Vector2(s * 10, -38), 5.5, 26, s * 0.25), Color("e8b0b0").lerp(skin, 0.3))
			"cow":
				var e := _ell(Vector2(x + s * 14, ey - 6), 17, 8, s * 0.35)
				_shape(e, skin, 0.6, 2.0)
				_fill(_ell(Vector2(x + s * 15, ey - 5), 10, 4, s * 0.35), skin.darkened(0.25).lerp(Color("d98880"), 0.3))
			"fin":
				var pts := _P([Vector2(x, ey + 12), Vector2(x + s * 30, ey - 16), Vector2(x + s * 22, ey + 2), Vector2(x + s * 28, ey + 14), Vector2(x, ey + 2)])
				_shape(pts, skin.lightened(0.1), 0.5, 1.8)
				for k in 3:
					_line(_P([Vector2(x + s * 2, ey + 4), Vector2(x + s * (16 + k * 5), ey - 10 + k * 9)]), skin.darkened(0.3), 1.2)


# ---------- kafa ve yüz

static func _head_pts(rx: float, ry: float, jaw: float, cy: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 44:
		var a := TAU * i / 44.0
		var x := cos(a) * rx
		var y := sin(a) * ry
		if y > 0:
			x *= lerpf(1.0, jaw, pow(y / ry, 1.5))
		pts.append(Vector2(x, y + cy))
	return pts


static func _head() -> void:
	var skin := _c("skin", Color("e0ac7e"))
	var pts := _head_pts(_rx, _ry, _jaw, _hy)
	_shape(pts, skin, 1.0, 2.4)
	var face := str(L.get("face", "human"))
	if face == "human" or face == "troll":
		for s: float in [-1.0, 1.0]:
			_dot(Vector2(s * _rx * 0.5, _hy + _ry * 0.32), 7.5 * _hs, Color(Color("e07a6a"), 0.12))
	if bool(L.get("fur", false)):
		for i in 10:
			var a := lerpf(0.4, PI - 0.4, i / 9.0)
			var p := Vector2(cos(a) * _rx * _jaw, _hy + sin(a) * _ry * 0.98)
			_line(_P([p, p + Vector2(cos(a) * 6, 5)]), skin.darkened(0.35), 1.5)
	if bool(L.get("mummy", false)):
		for i in 7:
			var y := _hy - _ry * 0.8 + i * _ry * 0.27
			_line(_P([Vector2(-_rx, y + 4), Vector2(_rx, y - 4)]), skin.darkened(0.3), 1.6)


static func _face(face: String) -> void:
	var skin := _c("skin", Color("e0ac7e"))
	var ey := _hy + _ry * 0.02
	var ex := _rx * 0.42
	var ny := _hy + _ry * 0.32
	var my := _hy + _ry * 0.58
	match face:
		"skull":
			_skull_face()
			return
		"reptile":
			var snout := _ell(Vector2(0, _hy + _ry * 0.42), _rx * 0.6, _ry * 0.4)
			_shape(snout, skin.lightened(0.1), 0.5, 1.8)
			for s: float in [-1.0, 1.0]:
				_shape(_ell(Vector2(s * 6, _hy + _ry * 0.22), 2.5, 1.6, s * 0.4), INK, 0.0, 0)
				_eye(Vector2(s * _rx * 0.56, ey - 4), s, "slit")
				_line(_P([Vector2(s * _rx * 0.36, ey - 13), Vector2(s * _rx * 0.78, ey - 9)]), skin.darkened(0.4), 3.0)
			_line(_bez(Vector2(-_rx * 0.5, my), Vector2(0, my + 6), Vector2(_rx * 0.5, my), 10), INK, 2.0)
			for k in 4:
				var tx := -_rx * 0.35 + k * _rx * 0.23
				_fill(_P([Vector2(tx - 2, my + 2.5), Vector2(tx + 2, my + 2.5), Vector2(tx, my + 7)]), Color("f4f0e0"))
			return
		"cat":
			for s: float in [-1.0, 1.0]:
				_eye(Vector2(s * ex, ey), s, "slit")
			var mz := _skin_light(skin)
			for s: float in [-1.0, 1.0]:
				_shape(_ell(Vector2(s * 6, ny + 9), 8.5, 6.5), mz, 0.0, 1.2)
				for k in 3:
					_line(_P([Vector2(s * 12, ny + 6 + k * 3), Vector2(s * 34, ny + k * 6 - 2)]), Color(INK, 0.6), 1.0)
			_shape(_P([Vector2(-5, ny + 1), Vector2(5, ny + 1), Vector2(0, ny + 6)]), Color("c0707a"), 0.0, 1.2)
			_line(_P([Vector2(0, ny + 6), Vector2(0, ny + 11)]), INK, 1.4)
			return
		"bird":
			for s: float in [-1.0, 1.0]:
				_eye(Vector2(s * _rx * 0.5, ey - 3), s, "bird")
			var bc := _c("beak_col", Color("e8b923"))
			var beak := _P([Vector2(-10, ny - 10), Vector2(10, ny - 10), Vector2(2, ny + 24), Vector2(-2, ny + 24)])
			_shape(_smooth(beak, 1), bc, 0.7, 2.0)
			_line(_P([Vector2(-9, ny + 2), Vector2(0, ny + 6), Vector2(9, ny + 2)]), bc.darkened(0.45), 1.5)
			return
		"bull":
			for s: float in [-1.0, 1.0]:
				_eye(Vector2(s * _rx * 0.55, ey - 6), s, "beast")
			var mz := _ell(Vector2(0, _hy + _ry * 0.55), _rx * 0.62, _ry * 0.36)
			_shape(mz, skin.lightened(0.18).lerp(Color("c89a8a"), 0.3), 0.6, 2.0)
			for s: float in [-1.0, 1.0]:
				_shape(_ell(Vector2(s * 9, _hy + _ry * 0.55), 4, 5.5, s * 0.3), INK, 0.0, 0)
			_arc(Vector2(0, _hy + _ry * 0.66), 7, 0.1, PI - 0.1, 12, _tint(GOLD), 2.5, true)
			_line(_P([Vector2(-_rx * 0.42, ey - 14), Vector2(-_rx * 0.15, ey - 9)]), skin.darkened(0.45), 3.5)
			_line(_P([Vector2(_rx * 0.42, ey - 14), Vector2(_rx * 0.15, ey - 9)]), skin.darkened(0.45), 3.5)
			return
		"wolf":
			for s: float in [-1.0, 1.0]:
				_eye(Vector2(s * ex, ey - 2), s, "beast")
			var snout := _P([Vector2(-_rx * 0.42, ey + 4), Vector2(_rx * 0.42, ey + 4), Vector2(_rx * 0.3, my + 10), Vector2(0, my + 14), Vector2(-_rx * 0.3, my + 10)])
			_shape(_smooth(snout, 1), skin.lightened(0.15), 0.6, 2.0)
			_shape(_ell(Vector2(0, ny + 2), 7, 5), INK, 0.0, 0)
			_line(_P([Vector2(-_rx * 0.25, my + 6), Vector2(0, my + 9), Vector2(_rx * 0.25, my + 6)]), INK, 1.6)
			for s: float in [-1.0, 1.0]:
				_fill(_P([Vector2(s * 6, my + 8), Vector2(s * 9, my + 8), Vector2(s * 7.5, my + 15)]), Color("f4f0e0"))
				_line(_P([Vector2(s * _rx * 0.2, ey - 10), Vector2(s * _rx * 0.6, ey - 13)]), skin.darkened(0.45), 3.0)
			return
		"ape":
			_shape(_ell(Vector2(0, _hy + _ry * 0.4), _rx * 0.62, _ry * 0.5), _c("skin").lightened(0.25), 0.5, 1.8)
			_shape(_ell(Vector2(0, ey - 9), _rx * 0.78, 7), skin.darkened(0.2), 0.3, 1.6)
			for s: float in [-1.0, 1.0]:
				_eye(Vector2(s * ex * 0.9, ey), s, "beast")
				_shape(_ell(Vector2(s * 5, ny + 2), 3, 2.2), INK, 0.0, 0)
			_line(_bez(Vector2(-14, my + 4), Vector2(0, my + 8), Vector2(14, my + 4), 8), INK, 1.8)
			return
	# insansı yüz
	if bool(L.get("cyclops", false)):
		_eye(Vector2(0, ey - 3), 1.0, "big")
	else:
		var style := "human"
		if bool(L.get("zombie", false)):
			style = "dead"
		for s: float in [-1.0, 1.0]:
			_eye(Vector2(s * ex, ey), s, style)
	if not bool(L.get("mummy", false)):
		_brows(ex, ey)
	_nose(ny)
	_mouth(my)


static func _skin_light(skin: Color) -> Color:
	return skin.lightened(0.3)


static func _eye(p: Vector2, s: float, style: String) -> void:
	var ec := _c("eye_color", Color("3b6ea5"))
	var es := 6.0 * _hs
	var glow := bool(L.get("glow_eyes", false))
	if style == "big":
		es *= 2.0
	if glow:
		_glow(p, es * 2.6, ec.lightened(0.3), 5)
	match style:
		"slit":
			var e := _ell(p, es * 1.05, es * 0.85, s * -0.15)
			_shape(e, ec.lightened(0.15), 0.0, 1.8)
			_fill(_ell(p, es * 0.2, es * 0.75), INK)
			_dot(p + Vector2(-es * 0.35, -es * 0.35), es * 0.18, Color.WHITE)
		"bird":
			_shape(_ell(p, es * 1.05, es * 1.05), Color("f4f0e0"), 0.0, 1.8)
			_dot(p, es * 0.8, ec)
			_dot(p, es * 0.45, INK)
			_dot(p + Vector2(-es * 0.3, -es * 0.3), es * 0.2, Color.WHITE)
		"beast":
			var e := _ell(p, es * 0.95, es * 0.62, s * 0.18)
			_shape(e, ec.lightened(0.1) if glow else Color("f2e8c8"), 0.0, 1.8)
			_dot(p, es * 0.42, INK if not glow else ec.lightened(0.4))
		"dead":
			var e := _ell(p, es, es * 0.6)
			_shape(e, Color("e8e8d0"), 0.0, 1.8)
			_dot(p, es * 0.4, Color("c8c8b0"))
		_:
			var e := _ell(p, es, es * 0.6)
			if glow:
				_shape(e, ec.lightened(0.45), 0.0, 1.6)
				_fill(_ell(p, es * 0.6, es * 0.4), Color(1, 1, 0.95))
			else:
				_fill(e, Color("f8f4ec"))
				_dot(p + Vector2(s * 0.3, 0.3), es * 0.55, ec)
				_dot(p + Vector2(s * 0.3, 0.3), es * 0.27, INK)
				_dot(p + Vector2(-es * 0.25, -es * 0.2), es * 0.17, Color.WHITE)
				_stroke(e, 1.4)
			_line(_bez(p + Vector2(-es * 1.1, 0.5), p + Vector2(0, -es * 0.95), p + Vector2(es * 1.1, 0.5), 8), INK, 2.0)


static func _brows(ex: float, ey: float) -> void:
	var hc := _c("hair_color", Color("4a3020")).darkened(0.15)
	if str(L.get("hair", "")) in ["flame", "snakes"] or hc.get_luminance() > 0.85:
		hc = _c("skin").darkened(0.35)
	var brow := float(L.get("brow", 0.0))
	var es := 6.0 * _hs
	for s: float in [-1.0, 1.0]:
		var inner := Vector2(s * (ex - es * 1.0), ey - es * 1.55 + brow * 7.0)
		var outer := Vector2(s * (ex + es * 1.25), ey - es * 1.8 - brow * 1.5)
		var mid := inner.lerp(outer, 0.5) + Vector2(0, -2.5 + brow * 2)
		_line(_bez(inner, mid, outer, 6), hc, 3.4 + brow * 1.4)


static func _nose(ny: float) -> void:
	var skin := _c("skin", Color("e0ac7e"))
	match str(L.get("nose", "normal")):
		"long":
			var pts := _P([Vector2(-5, ny - 14), Vector2(5, ny - 14), Vector2(7, ny + 6), Vector2(1, ny + 20), Vector2(-4, ny + 6)])
			_shape(_smooth(pts, 1), skin, 0.6, 1.8)
		"big":
			var pts := _ell(Vector2(0, ny + 1), 9 * _hs, 7 * _hs)
			_shape(pts, skin.darkened(0.04), 0.6, 1.6)
			for s: float in [-1.0, 1.0]:
				_dot(Vector2(s * 4, ny + 4), 1.8, skin.darkened(0.5))
		"small":
			_line(_bez(Vector2(1, ny - 6), Vector2(3, ny), Vector2(-1, ny + 2), 5), skin.darkened(0.4), 1.6)
		_:
			_line(_bez(Vector2(2, ny - 10), Vector2(5, ny - 1), Vector2(1, ny + 2), 6), skin.darkened(0.35), 1.8)
			_line(_bez(Vector2(-5, ny + 1), Vector2(0, ny + 4), Vector2(5, ny + 1), 6), skin.darkened(0.45), 1.6)


static func _mouth(my: float) -> void:
	var skin := _c("skin", Color("e0ac7e"))
	if str(L.get("mouth", "")) == "scream":
		_shape(_ell(Vector2(0, my + 4), 9, 13), Color("1a1418"), 0.0, 1.8)
		return
	var w := 10.0 * _hs
	_fill(_ell(Vector2(0, my + 2.5), w * 0.7, 2.6), skin.darkened(0.2).lerp(Color("b05050"), 0.25))
	_line(_bez(Vector2(-w, my), Vector2(0, my + 2.2), Vector2(w, my), 8), INK, 1.9)
	if bool(L.get("tusks", false)):
		for s: float in [-1.0, 1.0]:
			_shape(_P([Vector2(s * (w - 3), my + 3), Vector2(s * (w + 3), my + 3), Vector2(s * (w + 2), my - 11)]), Color("f2ead7"), 0.3, 1.4)
	if bool(L.get("fangs", false)):
		for s: float in [-1.0, 1.0]:
			_fill(_P([Vector2(s * 4, my + 1), Vector2(s * 7, my + 1), Vector2(s * 5.5, my + 7)]), Color.WHITE)


static func _skull_face() -> void:
	var bone := _c("skin", BONE)
	var ey := _hy + _ry * 0.02
	var glow := bool(L.get("glow_eyes", false))
	var ec := _c("eye_color", Color("48c9b0"))
	for s: float in [-1.0, 1.0]:
		var sock := _ell(Vector2(s * _rx * 0.4, ey), 9.5 * _hs, 8.5 * _hs, s * 0.2)
		_fill(sock, Color("140f0c"))
		if glow:
			_glow(Vector2(s * _rx * 0.4, ey + 1), 16, ec)
			_dot(Vector2(s * _rx * 0.4, ey + 1), 2.6, ec.lightened(0.5))
		_line(_bez(Vector2(s * _rx * 0.2, ey + 13), Vector2(s * _rx * 0.6, ey + 18), Vector2(s * _rx * 0.85, ey + 8), 6), bone.darkened(0.35), 1.6)
	_fill(_P([Vector2(-4, ey + 13), Vector2(4, ey + 13), Vector2(0, ey + 4)]), Color("140f0c"))
	var ty := _hy + _ry * 0.55
	var teeth := _P([Vector2(-13, ty), Vector2(13, ty), Vector2(11, ty + 9), Vector2(-11, ty + 9)])
	_shape(teeth, bone.lightened(0.1), 0.0, 1.4)
	for k in 5:
		var x := -9.0 + k * 4.5
		_line(_P([Vector2(x, ty), Vector2(x, ty + 9)]), INK, 1.0)
	_line(_P([Vector2(-13, ty + 4.5), Vector2(13, ty + 4.5)]), INK, 1.0)


static func _marks() -> void:
	var m := str(L.get("marks", "none"))
	var skin := _c("skin", Color("e0ac7e"))
	var mc := _c("mark_color", Color("2b2118"))
	var ey := _hy + _ry * 0.02
	match m:
		"freckles":
			for i in 14:
				var s := -1.0 if i % 2 == 0 else 1.0
				var p := Vector2(s * (_rx * 0.28 + _hash(i) * _rx * 0.35), ey + 9 + _hash(i + 20) * 10)
				_dot(p, 1.1, skin.darkened(0.35))
		"scales":
			for row in 3:
				for i in 6:
					var x := -_rx * 0.55 + i * _rx * 0.22 + (row % 2) * _rx * 0.11
					var y := _hy - _ry * 0.6 + row * 6.5
					_arc(Vector2(x, y), 3.2, 0.1, PI - 0.1, 6, _tint(skin.darkened(0.3)), 1.2)
			for s: float in [-1.0, 1.0]:
				for i in 4:
					_arc(Vector2(s * (_rx * 0.72 - i * 1.5), ey + 10 + i * 6), 3.0, 0.1, PI - 0.1, 6, _tint(skin.darkened(0.3)), 1.2)
		"stripes":
			for s: float in [-1.0, 1.0]:
				for i in 3:
					var y := ey + 4 + i * 7
					_tube(_P([Vector2(s * _rx * 0.98, y), Vector2(s * _rx * 0.65, y + 2)]), 4.0, 0.8, mc, 0)
				for i in 3:
					var x := s * (4 + i * 6)
					_tube(_P([Vector2(x, _hy - _ry * 0.92), Vector2(x * 0.9, _hy - _ry * 0.55)]), 3.8, 0.8, mc, 0)
		"spots":
			for i in 12:
				var p := Vector2((_hash(i) - 0.5) * _rx * 1.5, _hy - _ry * 0.6 + _hash(i + 9) * _ry * 1.2)
				if absf(p.y - ey) > 6:
					_dot(p, 2.0 + _hash(i + 3) * 2.0, mc.lerp(skin, 0.3))
		"tattoo":
			for s: float in [-1.0, 1.0]:
				_line(_P([Vector2(s * _rx * 0.25, _hy - _ry * 0.85), Vector2(s * _rx * 0.45, _hy - _ry * 0.5), Vector2(s * _rx * 0.3, _hy - _ry * 0.3)]), mc, 2.4)
				_line(_P([Vector2(s * _rx * 0.7, ey + 6), Vector2(s * _rx * 0.55, ey + 16), Vector2(s * _rx * 0.75, ey + 24)]), mc, 2.4)
			_line(_P([Vector2(0, _hy - _ry * 0.9), Vector2(0, _hy - _ry * 0.45)]), mc, 2.6)
		"warpaint":
			var band := _P([Vector2(-_rx * 0.95, ey - 4), Vector2(_rx * 0.95, ey - 4), Vector2(_rx * 0.9, ey + 7), Vector2(-_rx * 0.9, ey + 7)])
			_fill(band, Color(mc, 0.55))
			for i in 3:
				_line(_P([Vector2(-6 + i * 6, _hy + _ry * 0.68), Vector2(-6 + i * 6, _hy + _ry * 0.88)]), Color(mc, 0.8), 2.2)
			for s: float in [-1.0, 1.0]:
				_eye(Vector2(s * _rx * 0.42, ey), s, "human")
		"scar":
			var a := Vector2(_rx * 0.18, ey - 18)
			var b := Vector2(_rx * 0.68, ey + 16)
			_line(_P([a, b]), Color("c87870"), 2.6)
			for k in 4:
				var p := a.lerp(b, 0.2 + k * 0.2)
				_line(_P([p + Vector2(-3, 2), p + Vector2(3, -2)]), Color("a05050"), 1.2)
		"cracks":
			for s: float in [-1.0, 1.0]:
				_line(_P([Vector2(s * _rx * 0.85, ey - 18), Vector2(s * _rx * 0.6, ey - 8), Vector2(s * _rx * 0.72, ey + 4), Vector2(s * _rx * 0.5, ey + 16)]), mc, 2.0)
			_line(_P([Vector2(-4, _hy - _ry), Vector2(2, _hy - _ry * 0.75), Vector2(-3, _hy - _ry * 0.55)]), mc, 2.0)
		"stitches":
			var a := Vector2(-_rx * 0.8, _hy - _ry * 0.45)
			var b := Vector2(_rx * 0.6, _hy - _ry * 0.6)
			_line(_P([a, b]), Color("4a2a2a"), 1.8)
			for k in 7:
				var p := a.lerp(b, k / 6.0)
				_line(_P([p + Vector2(0, -4), p + Vector2(0, 4)]), Color("2b1a1a"), 1.4)
			var c := Vector2(_rx * 0.55, ey + 8)
			var d := Vector2(_rx * 0.4, ey + 28)
			_line(_P([c, d]), Color("4a2a2a"), 1.8)
			for k in 4:
				var p := c.lerp(d, k / 3.0)
				_line(_P([p + Vector2(-4, 0), p + Vector2(4, 0)]), Color("2b1a1a"), 1.4)


# ---------- ön saç, sakal, boynuz, başlık

static func _hair_front(helm: String) -> void:
	var hair := str(L.get("hair", "short"))
	var hc := _c("hair_color", Color("4a3020"))
	var top := _hy - _ry
	if helm in ["crown", "circlet", "bandana"] and hair in ["none"]:
		return
	match hair:
		"none", "snakes", "feathers":
			if hair == "snakes":
				for i in 3:
					var x := -14.0 + i * 14.0
					var base := Vector2(x, top + 8)
					_tube(_bez(base, base + Vector2(8, -10), base + Vector2(4, -22), 8), 8, 5, hc)
			return
		"mohawk":
			var pts := _P([Vector2(-7, _hy - _ry * 0.5), Vector2(-8, top - 2), Vector2(-4, top - 22), Vector2(0, top - 8),
					Vector2(4, top - 26), Vector2(7, top - 6), Vector2(8, _hy - _ry * 0.5)])
			_shape(pts, hc, 0.6, 1.8)
			return
		"flame":
			var c1 := hc
			var c2 := c1.lightened(0.5)
			_glow(Vector2(0, top), _rx * 1.6, c1, 5)
			for i in 7:
				var x := lerpf(-_rx * 0.85, _rx * 0.85, i / 6.0)
				var yb := _hy - sqrt(maxf(0.0, 1.0 - pow(x / _rx, 2))) * _ry * 0.9
				_flame(Vector2(x, yb + 6), 26 + 14 * sin(i * 1.7) + (10.0 if i == 3 else 0.0), 9, c1, c2, (x / _rx) * 0.35)
			return
	# başlık saçı (kepçe): üst yay + alın kenarı
	var pts := PackedVector2Array()
	var vol := 1.12 if hair in ["curly", "wild"] else 1.06
	for i in 17:
		var a := lerpf(PI * 1.02, PI * 1.98, i / 16.0)
		pts.append(Vector2(cos(a) * _rx * vol, _hy + sin(a) * _ry * vol))
	var temple := _hy - _ry * 0.12
	if hair in ["long", "braid"]:
		temple = _hy + _ry * 0.45
	pts.append(Vector2(_rx * 0.98, temple))
	pts.append(Vector2(_rx * 0.78, _hy - _ry * 0.32))
	var n := 6
	for i in n + 1:
		var t := float(i) / n
		var x := lerpf(_rx * 0.6, -_rx * 0.6, t)
		var dip := 7.0 if i % 2 == 1 else 0.0
		if hair == "wild":
			dip = 11.0 if i % 2 == 1 else -2.0
		pts.append(Vector2(x, _hy - _ry * 0.5 + dip + sin(t * PI) * 3.0))
	pts.append(Vector2(-_rx * 0.78, _hy - _ry * 0.32))
	pts.append(Vector2(-_rx * 0.98, temple))
	_shape(pts, hc, 0.8, 2.0)
	if hair == "curly":
		for i in 9:
			var a := lerpf(PI * 1.08, PI * 1.92, i / 8.0)
			_arc(Vector2(cos(a) * _rx * 0.85, _hy + sin(a) * _ry * 0.85), 5.0, 0.0, PI * 1.5, 8, _tint(hc.darkened(0.35)), 1.4)
	else:
		for i in 4:
			var x := -_rx * 0.45 + i * _rx * 0.3
			_line(_bez(Vector2(x * 0.6, top + 4), Vector2(x, top + 10), Vector2(x * 1.1, _hy - _ry * 0.48), 6), hc.darkened(0.3), 1.2)
	if hair == "bun":
		var bun := _ell(Vector2(0, top - 8), 13, 11)
		_shape(bun, hc, 0.8, 2.0)
	if hair == "braid":
		var s := -1.0
		var p := Vector2(s * _rx * 0.95, _hy + _ry * 0.4)
		for k in 6:
			_shape(_ell(p + Vector2(s * -k * 1.0, k * 11), 7, 7.5), hc.darkened(0.05 * (k % 2)), 0.5, 1.6)
		_shape(_ell(p + Vector2(s * -6, 68), 4, 3), _c("accent", GOLD), 0.3, 1.2)


static func _beard() -> void:
	var beard := str(L.get("beard", "none"))
	if beard == "none":
		return
	var hc := _c("hair_color", Color("4a3020"))
	var my := _hy + _ry * 0.58
	match beard:
		"stubble":
			var pts := _head_pts(_rx * 0.92, _ry * 0.95, _jaw, _hy)
			var lower := PackedVector2Array()
			for p in pts:
				if p.y > _hy + _ry * 0.2:
					lower.append(p)
			if lower.size() >= 3:
				lower.append(Vector2(-_rx * 0.4, _hy + _ry * 0.45))
				lower.append(Vector2(_rx * 0.4, _hy + _ry * 0.45))
				_fill(_smooth(lower, 1), Color(hc, 0.28))
			return
		"mustache":
			_mustache(my, hc)
			return
	var length := 0.95 if beard == "short" else 1.75
	var pts := PackedVector2Array()
	pts.append(Vector2(-_rx * 0.94, _hy + _ry * 0.05))
	for i in 9:
		var t := float(i) / 8.0
		var x := lerpf(-_rx * 0.9, _rx * 0.9, t)
		var y := _hy + _ry * (0.6 + length * sin(t * PI) * 0.62)
		if beard == "braided" and absf(t - 0.5) < 0.2:
			y += 8
		pts.append(Vector2(x * (1.0 - 0.15 * sin(t * PI)), y))
	pts.append(Vector2(_rx * 0.94, _hy + _ry * 0.05))
	pts.append(Vector2(_rx * 0.7, _hy + _ry * 0.5))
	pts.append(Vector2(_rx * 0.35, _hy + _ry * 0.45))
	pts.append(Vector2(-_rx * 0.35, _hy + _ry * 0.45))
	pts.append(Vector2(-_rx * 0.7, _hy + _ry * 0.5))
	_shape(pts, hc, 0.8, 2.0)
	for i in 5:
		var x := -_rx * 0.5 + i * _rx * 0.25
		_line(_bez(Vector2(x, my + 6), Vector2(x * 1.1, my + 16), Vector2(x * 0.8, _hy + _ry * (0.6 + length * 0.5)), 6), hc.darkened(0.3), 1.2)
	if beard == "braided":
		for k in 2:
			var y := _hy + _ry * (0.95 + length * 0.25) + k * 12
			_shape(_P([Vector2(-8, y), Vector2(8, y), Vector2(7, y + 5), Vector2(-7, y + 5)]), _c("accent", GOLD), 0.3, 1.2)
	_mustache(my, hc)
	_line(_bez(Vector2(-7, my + 2), Vector2(0, my + 4), Vector2(7, my + 2), 6), INK, 1.8)


static func _mustache(my: float, hc: Color) -> void:
	for s: float in [-1.0, 1.0]:
		var pts := _P([Vector2(0, my - 6), Vector2(s * 9, my - 7), Vector2(s * 17, my), Vector2(s * 15, my + 3), Vector2(s * 8, my - 2), Vector2(0, my - 2)])
		_shape(_smooth(pts, 1), hc, 0.5, 1.6)


static func _horns() -> void:
	var kind := str(L.get("horns", "none"))
	if kind == "none" or kind == "crest":
		return
	var hcol := _c("horn_color", BONE)
	for s: float in [-1.0, 1.0]:
		match kind:
			"ram":
				var a := Vector2(s * _rx * 0.42, _hy - _ry * 0.78)
				var path := _bez3(a, Vector2(s * _rx * 1.25, _hy - _ry * 1.45), Vector2(s * _rx * 1.65, _hy - _ry * 0.1), Vector2(s * _rx * 1.1, _hy - _ry * 0.15))
				_tube(path, 13, 4, hcol)
				for k in range(2, path.size() - 2, 3):
					var d := (path[k + 1] - path[k - 1]).normalized().orthogonal()
					_line(_P([path[k] + d * 5, path[k] - d * 5]), hcol.darkened(0.35), 1.2)
			"straight":
				var a := Vector2(s * _rx * 0.32, _hy - _ry * 0.8)
				_tube(_bez(a, Vector2(s * _rx * 0.7, _hy - _ry * 1.3), Vector2(s * _rx * 0.95, _hy - _ry * 1.75), 10), 11, 1.5, hcol)
			"small":
				var a := Vector2(s * _rx * 0.35, _hy - _ry * 0.82)
				_tube(_bez(a, Vector2(s * _rx * 0.45, _hy - _ry * 1.05), Vector2(s * _rx * 0.58, _hy - _ry * 1.18), 6), 8, 2, hcol)
			"bull":
				var a := Vector2(s * _rx * 0.85, _hy - _ry * 0.55)
				_tube(_bez3(a, Vector2(s * _rx * 1.6, _hy - _ry * 0.6), Vector2(s * _rx * 1.9, _hy - _ry * 0.9), Vector2(s * _rx * 1.75, _hy - _ry * 1.45)), 14, 2, hcol)
			"antlers":
				var a := Vector2(s * _rx * 0.4, _hy - _ry * 0.85)
				var tip := Vector2(s * _rx * 1.3, _hy - _ry * 1.75)
				var main := _bez(a, Vector2(s * _rx * 0.6, _hy - _ry * 1.5), tip, 10)
				_tube(main, 6, 3, Color("8a6a4a"))
				for k: int in [3, 6, 8]:
					var p: Vector2 = main[k]
					_tube(_P([p, p + Vector2(s * -6, -20 + k)]), 4, 1.5, Color("8a6a4a"))


static func _helm(helm: String) -> void:
	var metal := METAL
	if L.get("outfit", "") == "plate":
		metal = _c("cloth", METAL).lerp(METAL, 0.3)
	var acc := _c("accent", GOLD)
	var top := _hy - _ry
	match helm:
		"hood":
			var cloth := _c("cloth", Color("3a3a3a"))
			var outer := _head_pts(_rx * 1.28, _ry * 1.22, 1.0, _hy - 2)
			var inner := _head_pts(_rx * 0.98, _ry * 1.0, _jaw, _hy + 3)
			var rim := PackedVector2Array()
			for p in outer:
				if p.y < _hy + _ry * 0.5:
					rim.append(p)
			var inner_top := PackedVector2Array()
			for p in inner:
				if p.y < _hy + _ry * 0.5:
					inner_top.append(p)
			if rim.size() > 2 and inner_top.size() > 2:
				var clipped := Geometry2D.clip_polygons(_smooth(_order_poly(rim), 1), _order_poly(inner_top))
				for poly in clipped:
					if not Geometry2D.is_polygon_clockwise(poly) or clipped.size() == 1:
						_shape(poly, cloth, 0.8, 2.0)
			var shadow := _head_pts(_rx * 0.98, _ry * 0.5, 1.0, _hy - _ry * 0.4)
			_fill(shadow, Color(0, 0, 0, 0.35))
		"open", "horned":
			var cap := PackedVector2Array()
			for i in 19:
				var a := lerpf(PI, TAU, i / 18.0)
				cap.append(Vector2(cos(a) * _rx * 1.08, _hy - _ry * 0.2 + sin(a) * _ry * 0.92))
			_shape(cap, metal, 1.0, 2.2)
			_shape(_P([Vector2(-_rx * 1.1, _hy - _ry * 0.24), Vector2(_rx * 1.1, _hy - _ry * 0.24), Vector2(_rx * 1.08, _hy - _ry * 0.1), Vector2(-_rx * 1.08, _hy - _ry * 0.1)]), metal.darkened(0.15), 0.4, 1.8)
			_shape(_P([Vector2(-3.5, _hy - _ry * 0.15), Vector2(3.5, _hy - _ry * 0.15), Vector2(3, _hy + _ry * 0.28), Vector2(-3, _hy + _ry * 0.28)]), metal, 0.3, 1.6)
			for k in 5:
				_dot(Vector2(-_rx * 0.8 + k * _rx * 0.4, _hy - _ry * 0.17), 1.5, metal.lightened(0.4))
			if helm == "horned":
				for s: float in [-1.0, 1.0]:
					_tube(_bez3(Vector2(s * _rx * 0.9, _hy - _ry * 0.55), Vector2(s * _rx * 1.6, _hy - _ry * 0.7), Vector2(s * _rx * 1.7, _hy - _ry * 1.2), Vector2(s * _rx * 1.45, _hy - _ry * 1.6)), 12, 2, BONE)
		"full":
			var pts := _head_pts(_rx * 1.1, _ry * 1.06, 0.92, _hy)
			_shape(pts, metal, 1.0, 2.4)
			var slit := _P([Vector2(-_rx * 0.85, _hy - 4), Vector2(_rx * 0.85, _hy - 4), Vector2(_rx * 0.78, _hy + 4), Vector2(-_rx * 0.78, _hy + 4)])
			_fill(slit, Color("0e0b09"))
			if bool(L.get("glow_eyes", false)):
				var ec := _c("eye_color", Color("e74c3c"))
				for s: float in [-1.0, 1.0]:
					_glow(Vector2(s * _rx * 0.4, _hy), 12, ec)
					_dot(Vector2(s * _rx * 0.4, _hy), 2.4, ec.lightened(0.5))
			_line(_P([Vector2(0, top - 2), Vector2(0, _hy - 6)]), metal.lightened(0.35), 2.2)
			for row in 3:
				for k in 4:
					_dot(Vector2(-6 + k * 4 + (row % 2) * 2, _hy + _ry * 0.35 + row * 5), 1.3, Color("0e0b09"))
			var plume := _bez3(Vector2(0, top), Vector2(10, top - 22), Vector2(34, top - 18), Vector2(46, top + 8))
			_tube(plume, 10, 3, acc)
		"wizard":
			var cloth := _c("cloth", Color("2e4a8a"))
			var brim := _ell(Vector2(0, _hy - _ry * 0.62), _rx * 1.75, _ry * 0.26)
			_shape(brim, cloth.darkened(0.1), 0.6, 2.0)
			var cone := _P([Vector2(-_rx * 0.95, _hy - _ry * 0.62), Vector2(-_rx * 0.3, _hy - _ry * 1.5), Vector2(_rx * 0.35, _hy - _ry * 2.1),
					Vector2(_rx * 1.2, _hy - _ry * 1.85), Vector2(_rx * 0.4, _hy - _ry * 1.45), Vector2(_rx * 0.95, _hy - _ry * 0.62)])
			_shape(_smooth(cone, 1), cloth, 1.0, 2.0)
			_shape(_P([Vector2(-_rx * 0.95, _hy - _ry * 0.66), Vector2(_rx * 0.95, _hy - _ry * 0.66), Vector2(_rx * 0.88, _hy - _ry * 0.82), Vector2(-_rx * 0.88, _hy - _ry * 0.82)]), acc, 0.4, 1.6)
			_star(Vector2(-_rx * 0.1, _hy - _ry * 1.15), 5, acc)
		"crown":
			var y0 := _hy - _ry * 0.62
			var pts := PackedVector2Array([Vector2(-_rx * 0.9, y0 + 8), Vector2(_rx * 0.9, y0 + 8)])
			for i in 5:
				var x := lerpf(_rx * 0.9, -_rx * 0.9, i / 4.0)
				pts.append(Vector2(x, y0 - 16 if i % 2 == 0 else y0 - 4))
				if i < 4:
					pts.append(Vector2(lerpf(_rx * 0.9, -_rx * 0.9, (i + 0.5) / 4.0), y0 - 2))
			_shape(pts, GOLD, 1.0, 1.8)
			for i in 3:
				_dot(Vector2(-_rx * 0.45 + i * _rx * 0.45, y0 + 2), 2.4, [Color("c0392b"), Color("2e86c1"), Color("27ae60")][i])
		"circlet":
			var y0 := _hy - _ry * 0.42
			_line(_bez(Vector2(-_rx * 0.98, y0 + 4), Vector2(0, y0 - 6), Vector2(_rx * 0.98, y0 + 4), 12), INK, 4.0)
			_line(_bez(Vector2(-_rx * 0.98, y0 + 4), Vector2(0, y0 - 6), Vector2(_rx * 0.98, y0 + 4), 12), GOLD, 2.4)
			_shape(_P([Vector2(0, y0 - 8), Vector2(5, y0 - 1), Vector2(0, y0 + 5), Vector2(-5, y0 - 1)]), acc.lightened(0.2), 0.3, 1.4)
		"bandana":
			var cap := PackedVector2Array()
			for i in 17:
				var a := lerpf(PI * 1.02, PI * 1.98, i / 16.0)
				cap.append(Vector2(cos(a) * _rx * 1.05, _hy - _ry * 0.05 + sin(a) * _ry * 1.0))
			cap.append(Vector2(_rx * 1.0, _hy - _ry * 0.3))
			cap.append(Vector2(-_rx * 1.0, _hy - _ry * 0.3))
			var bc := _c("accent", Color("a83232"))
			_shape(cap, bc, 0.8, 2.0)
			_shape(_P([Vector2(_rx * 0.9, _hy - _ry * 0.4), Vector2(_rx * 1.4, _hy - _ry * 0.1), Vector2(_rx * 1.25, _hy + _ry * 0.05), Vector2(_rx * 0.95, _hy - _ry * 0.2)]), bc.darkened(0.1), 0.4, 1.6)
			for k in 3:
				_dot(Vector2(-_rx * 0.4 + k * _rx * 0.4, _hy - _ry * 0.7), 2.0, Color(1, 1, 1, 0.6))


static func _order_poly(pts: PackedVector2Array) -> PackedVector2Array:
	return pts


static func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	_fill(pts, col)


static func _front_items(b: float) -> void:
	var item := str(L.get("item", "none"))
	var acc := _c("accent", GOLD)
	match item:
		"orb":
			var c := Vector2(54, 76)
			_glow(c, 34, acc.lightened(0.2), 6)
			_shape(_ell(c, 15, 15), acc.lightened(0.15), 1.0, 2.0)
			_dot(c + Vector2(-5, -5), 4, Color(1, 1, 1, 0.8))
			_shape(_ell(Vector2(c.x, c.y + 18), 11, 5), Color("5a4030"), 0.4, 1.6)
		"book":
			var c := Vector2(-52, 82)
			var cover := _P([c + Vector2(-20, -16), c + Vector2(18, -22), c + Vector2(24, 14), c + Vector2(-14, 20)])
			_shape(cover, _c("cloth", Color("3a1a2a")).darkened(0.2), 0.6, 2.0)
			_glow(c, 28, acc, 4)
			_star(c + Vector2(2, -1), 7, acc)
		"holy":
			_line(_bez(Vector2(-16, 44), Vector2(0, 62), Vector2(16, 44), 10), GOLD.darkened(0.2), 1.4)
			var c := Vector2(0, 76)
			_line(_P([Vector2(0, 60), c]), GOLD.darkened(0.2), 1.4)
			for i in 8:
				var a := TAU * i / 8.0
				_line(_P([c + Vector2(cos(a), sin(a)) * 8, c + Vector2(cos(a), sin(a)) * 14]), GOLD, 2.4)
			_shape(_ell(c, 8, 8), GOLD, 0.6, 1.6)
		"shield":
			var c := Vector2(-62, 92)
			var sh := _ell(c, 34, 34)
			_shape(sh, _c("cloth", Color("6b4a2a")).darkened(0.1), 1.0, 2.4)
			_arc(c, 29, 0, TAU, 32, _tint(METAL), 4.0, true)
			_shape(_ell(c, 8, 8), METAL, 0.6, 1.6)
			_line(_P([c + Vector2(0, -28), c + Vector2(0, 28)]), acc, 4)
			_line(_P([c + Vector2(-28, 0), c + Vector2(28, 0)]), acc, 4)


# =================================================================== YARATIKLAR (yan görünüş)

static func _fit(minp: Vector2, maxp: Vector2, room := 168.0) -> void:
	var size := maxp - minp
	var k := minf(room / maxf(size.x, 1.0), room / maxf(size.y, 1.0))
	k = clampf(k, 0.35, 1.5)
	var c := (minp + maxp) * 0.5
	_tf(-c * k + Vector2(0, 6), k)


static func _ground(y: float, col := Color(0, 0, 0, 0.22)) -> void:
	_fill(_ell(Vector2(0, y + 2), 70, 7), col)


static func _creature_eye(p: Vector2, r: float) -> void:
	var ec := _c("eye", Color("1a1410"))
	if L.has("eye"):
		_glow(p, r * 3.0, ec)
		_dot(p, r * 1.1, ec.lightened(0.3))
		_dot(p, r * 0.45, Color(1, 1, 0.9))
	else:
		_dot(p, r, INK)
		_dot(p + Vector2(-r * 0.35, -r * 0.35), r * 0.35, Color(1, 1, 1, 0.9))


# ---------- dört ayaklılar

static func _quad(draw_head := true) -> void:
	var col := _c("col", Color("8a7a6a"))
	var col2 := _c("col2", col.lightened(0.3))
	var Lb := float(L.get("len", 1.0))
	var H := float(L.get("h", 1.0))
	var leg := float(L.get("leg", 1.0))
	var neck := float(L.get("neck", 0.5))
	var head := str(L.get("head", "canine"))
	var legs := str(L.get("legs", "normal"))
	var bx := -6.0
	var by := 4.0
	var rx := 40.0 * Lb
	var ry := 21.0 * H
	var thick := 1.0
	if legs == "thick":
		thick = 1.35
	elif legs == "pillar":
		thick = 1.6
	var ground := by + ry * 0.55 + 36.0 * leg
	if legs == "splay":
		ground = by + ry * 0.7 + 12.0
	var head_pos := Vector2(bx + rx * 0.92 + 12 + 18 * neck, by - ry * 0.35 - 8 - 30 * neck)
	if head in ["reptile"] or neck < 0.3:
		head_pos = Vector2(bx + rx * 1.05 + 10, by - ry * 0.15)
	if draw_head:
		var top := head_pos.y - 30.0
		if L.get("horns", "") == "antlers":
			top -= 30
		var minp := Vector2(bx - rx - 30, minf(top, by - ry - (60.0 if L.has("wings") else 6.0)))
		var maxp := Vector2(head_pos.x + 30 + 10 * float(L.get("snout", 1.0)), ground + 4)
		if L.get("tail", "") == "scorpion":
			minp.y = minf(minp.y, by - ry - 45)
		_fit(minp, maxp, 186)
	_ground(ground)
	var dark := col.darkened(0.25)
	var xf := bx + rx * 0.6
	var xb := bx - rx * 0.62
	var leg_xs := [xb, xf]
	if bool(L.get("legs6", false)):
		leg_xs = [xb, bx, xf]
	# uzak bacaklar
	for x: float in leg_xs:
		_leg(Vector2(x + 7, by + ry * 0.2), ground - 2, dark, thick, head, legs)
	# uzak kanat
	var wings := str(L.get("wings", "none"))
	if wings != "none":
		_qwing(Vector2(bx + rx * 0.2, by - ry * 0.6), wings, col, true)
	_qtail(Vector2(bx - rx * 0.9, by - ry * 0.25), col, col2, ground)
	# gövde
	var body := _ell(Vector2(bx, by), rx, ry)
	if bool(L.get("hump", false)):
		var humps := int(L.get("humps", 1))
		for i in humps:
			var hx := bx - rx * 0.1 + (i - (humps - 1) * 0.5) * rx * 0.55
			var hump := _ell(Vector2(hx, by - ry * 0.75), rx * 0.38, ry * 0.6)
			var merged := Geometry2D.merge_polygons(body, hump)
			if merged.size() > 0:
				body = merged[0]
	if bool(L.get("wool", false)):
		var bumps := body.duplicate()
		for i in 18:
			var a := TAU * i / 18.0
			var c := Vector2(bx + cos(a) * rx * 0.92, by + sin(a) * ry * 0.9)
			var m := Geometry2D.merge_polygons(bumps, _ell(c, 9, 9, 0.0, 12))
			if m.size() > 0:
				bumps = m[0]
		body = bumps
	_shape(body, col, 1.0, 2.4)
	_belly(body, by + ry * 0.3, col2)
	_pattern(body, bx, by, rx, ry, col)
	if bool(L.get("spikes", false)) or bool(L.get("bristle", false)):
		for i in 7:
			var t := i / 6.0
			var x := lerpf(bx - rx * 0.6, bx + rx * 0.55, t)
			var y := by - ry * sqrt(maxf(0.0, 1.0 - pow((x - bx) / rx, 2))) + 2
			_shape(_P([Vector2(x - 4, y), Vector2(x + 1, y - 10 - 4 * sin(t * PI)), Vector2(x + 5, y)]), dark.darkened(0.2), 0.0, 1.4)
	if bool(L.get("barding", false)):
		var bard := _P([Vector2(bx - rx * 0.7, by - ry * 0.7), Vector2(bx + rx * 0.7, by - ry * 0.75), Vector2(bx + rx * 0.75, by + ry * 0.75), Vector2(bx - rx * 0.75, by + ry * 0.7)])
		var clipped := Geometry2D.intersect_polygons(bard, body)
		for p in clipped:
			_shape(p, Color("8a2a2a"), 0.5, 1.6)
		_line(_P([Vector2(bx - rx * 0.75, by + ry * 0.55), Vector2(bx + rx * 0.75, by + ry * 0.55)]), GOLD, 2.5)
	# yakın bacaklar
	for x: float in leg_xs:
		_leg(Vector2(x, by + ry * 0.35), ground, col, thick, head, legs)
	if bool(L.get("fire", false)):
		for x: float in leg_xs:
			_flame(Vector2(x + 2, ground), 14, 6, Color("e67e22"), Color("f7dc6f"))
	if not draw_head:
		return
	# boyun
	var neck_base := Vector2(bx + rx * 0.72, by - ry * 0.3)
	var nw := 26.0 * H if head != "elephant" else 34.0
	if head not in ["reptile"] and neck >= 0.3:
		_tube(_bez(neck_base + Vector2(-6, 8), neck_base.lerp(head_pos, 0.5) + Vector2(-4, -2), head_pos + Vector2(-4, 6), 8), nw, nw * 0.62, col)
	if bool(L.get("mane", false)) and head == "equine":
		var mc := _c("mane_col", col.darkened(0.4))
		var mane := _bez(neck_base + Vector2(-14, -10), neck_base.lerp(head_pos, 0.5) + Vector2(-16, -14), head_pos + Vector2(-4, -12), 10)
		_tube(mane, 13, 7, mc)
	if bool(L.get("tentacles", false)):
		for s: float in [0.0, 1.0]:
			var a := neck_base + Vector2(-10 - s * 8, -6)
			var path := _bez3(a, a + Vector2(-20, -50), a + Vector2(30, -70), a + Vector2(40, -40 + s * 10))
			_tube(path, 7, 3, col.darkened(0.1))
			_shape(_ell(path[path.size() - 1], 6, 4), col2, 0.5, 1.4)
	if wings != "none":
		_qwing(Vector2(bx + rx * 0.15, by - ry * 0.7), wings, col, false)
	if L.get("extra_head", "") == "goat":
		_qhead(neck_base + Vector2(-26, -26), "goat", Color("8a7a6a"), Color("c8b8a0"), 0.8)
	var heads := int(L.get("heads", 1))
	if heads > 1:
		for i in range(heads - 1, 0, -1):
			var off := Vector2(-14.0 * i, -18.0 * i + 6.0 * (i % 2))
			_tube(_P([neck_base + Vector2(-4, -2), head_pos + off + Vector2(-4, 6)]), nw * 0.85, nw * 0.6, col.darkened(0.1 * i))
			_qhead(head_pos + off, head, col.darkened(0.12 * i), col2.darkened(0.12 * i), 0.9)
	_qhead(head_pos, head, col, col2, 1.0)
	if bool(L.get("collar", false)):
		_tube(_P([neck_base + Vector2(4, -14), neck_base + Vector2(14, 6)]), 7, 7, Color("a83232"))


static func _belly(body: PackedVector2Array, y: float, col2: Color) -> void:
	var lower := _P([Vector2(-300, y), Vector2(300, y), Vector2(300, 300), Vector2(-300, 300)])
	for p in Geometry2D.intersect_polygons(body, lower):
		_fill(p, Color(col2, 0.85))


static func _pattern(body: PackedVector2Array, bx: float, by: float, rx: float, ry: float, col: Color) -> void:
	match str(L.get("pattern", "none")):
		"stripes":
			for i in 7:
				var x := bx - rx * 0.75 + i * rx * 0.24
				var stripe := _P([Vector2(x - 2, by - ry * 1.2), Vector2(x + 3, by - ry * 1.2), Vector2(x + 8, by + ry * 0.4), Vector2(x + 4, by + ry * 0.45)])
				for p in Geometry2D.intersect_polygons(stripe, body):
					_fill(p, Color("1e1612"))
		"spots":
			for i in 22:
				var p := Vector2(bx + (_hash(i) - 0.5) * rx * 1.7, by + (_hash(i + 40) - 0.5) * ry * 1.5)
				if Geometry2D.is_point_in_polygon(p, body):
					_arc(p, 3.2, 0, TAU, 10, _tint(Color("2b2118")), 2.0, true)
		"patches":
			for i in 4:
				var c := Vector2(bx + (_hash(i + 3) - 0.5) * rx * 1.4, by + (_hash(i + 7) - 0.6) * ry)
				var blob := _ell(c, 10 + _hash(i) * 12, 8 + _hash(i + 1) * 8, _hash(i + 2) * 3.0, 14)
				for p in Geometry2D.intersect_polygons(blob, body):
					_fill(p, _c("col2", Color.BLACK))
		"dapple":
			for i in 16:
				var p := Vector2(bx + (_hash(i) - 0.5) * rx * 1.6, by + (_hash(i + 40) - 0.7) * ry * 1.2)
				if Geometry2D.is_point_in_polygon(p, body):
					_dot(p, 3.5, Color(col.lightened(0.3), 0.6))
	if bool(L.get("scales", false)):
		for row in 3:
			for i in 9:
				var p := Vector2(bx - rx * 0.7 + i * rx * 0.17 + (row % 2) * rx * 0.08, by - ry * 0.5 + row * 7)
				if Geometry2D.is_point_in_polygon(p, body):
					_arc(p, 3.5, 0.2, PI - 0.2, 6, _tint(col.darkened(0.3)), 1.2)


static func _leg(hip: Vector2, ground: float, col: Color, thick: float, head: String, legs: String) -> void:
	var foot := Vector2(hip.x + 2, ground)
	if legs == "splay":
		foot = Vector2(hip.x + 10, ground)
		_tube(_P([hip, Vector2(hip.x + 12, hip.y + 4), foot]), 11, 7, col)
		for k in 3:
			_line(_P([foot + Vector2(-2 + k * 4, 0), foot + Vector2(1 + k * 5, 2)]), INK, 1.4)
		return
	var knee := hip.lerp(foot, 0.5) + Vector2(3, 0)
	var w0 := 13.0 * thick
	var w1 := 7.0 * thick
	_tube(_P([hip, knee, foot + Vector2(0, -3)]), w0, w1, col)
	match head:
		"equine", "bovine", "deer", "goat", "rhino":
			_shape(_P([foot + Vector2(-w1 * 0.6, -6), foot + Vector2(w1 * 0.6, -6), foot + Vector2(w1 * 0.75, 1), foot + Vector2(-w1 * 0.7, 1)]), Color("2b2118"), 0.0, 1.4)
		"bird":
			for k in 3:
				_line(_P([foot + Vector2(0, -2), foot + Vector2(-5 + k * 5, 2)]), Color("c8a050"), 2.0)
		_:
			_shape(_ell(foot + Vector2(2, -1.5), w1 * 0.75, 3.5), col.darkened(0.1), 0.0, 1.6)


static func _qwing(root: Vector2, kind: String, col: Color, far: bool) -> void:
	var shade := 0.25 if far else 0.0
	var off := Vector2(-10, -4) if far else Vector2.ZERO
	match kind:
		"feather":
			var wc := _c("front_col", _c("col2", col)).lightened(0.1).darkened(shade)
			for i in 6:
				var a := lerpf(-1.75, -0.55, i / 5.0)
				var base := root + off
				var tip := base + Vector2(-cos(a), sin(a)) * (92.0 - i * 9.0)
				var nrm := (tip - base).normalized().orthogonal() * (10.0 - i)
				_shape(_P([base, base.lerp(tip, 0.45) + nrm, tip, base.lerp(tip, 0.6) - nrm * 0.5]), wc.darkened(i * 0.04), 0.4, 1.6)
		"bat":
			var wc := col.darkened(0.15 + shade)
			var top := root + off + Vector2(-10, -78)
			var f1 := root + off + Vector2(-70, -60)
			var f2 := root + off + Vector2(-80, -16)
			var f3 := root + off + Vector2(-48, 6)
			var pts := _P([root + off, top, f1, f1.lerp(f2, 0.5) + Vector2(10, 2), f2, f2.lerp(f3, 0.5) + Vector2(10, 0), f3, root + off + Vector2(-8, 6)])
			_shape(pts, wc, 0.5, 1.8)
			for f in [f1, f2, f3]:
				_line(_P([top, f]), INK, 1.8)
			_line(_P([root + off, top]), INK, 2.8)


static func _qtail(base: Vector2, col: Color, col2: Color, ground: float) -> void:
	match str(L.get("tail", "thin")):
		"bushy":
			var p := _bez3(base, base + Vector2(-22, 4), base + Vector2(-34, 26), base + Vector2(-26, 46))
			_tube(p, 16, 8, col)
			_shape(_ell(p[p.size() - 1], 6, 7), col2, 0.0, 1.4)
		"thin", "tuft":
			var p := _bez(base, base + Vector2(-20, 10), base + Vector2(-16, 44), 10)
			_tube(p, 5, 3, col)
			if L.get("tail", "") == "tuft":
				_shape(_ell(p[p.size() - 1] + Vector2(0, 4), 5, 8), col.darkened(0.4), 0.0, 1.4)
		"horse", "fire":
			var mc := _c("mane_col", col.darkened(0.4))
			if L.get("tail", "") == "fire":
				for k in 3:
					_flame(base + Vector2(-8 - k * 6, 30 + k * 8), 34, 7, Color("e67e22"), Color("f7dc6f"), -0.6)
				return
			var p := _bez3(base, base + Vector2(-16, -2), base + Vector2(-30, 24), base + Vector2(-22, 54))
			_tube(p, 14, 9, mc)
			for k in 3:
				_line(_bez(base + Vector2(-6, 4), base + Vector2(-22 - k * 3, 20), base + Vector2(-18 - k * 4, 50), 8), mc.darkened(0.3), 1.2)
		"long":
			var p := _bez3(base, base + Vector2(-26, 8), base + Vector2(-42, -6), base + Vector2(-38, -30))
			_tube(p, 7, 4, col)
		"short":
			_tube(_P([base, base + Vector2(-9, 4)]), 8, 5, col)
		"curl":
			var pts := PackedVector2Array()
			for i in 16:
				var a := i * 0.6
				pts.append(base + Vector2(-4 - cos(a) * (2 + i * 0.4), sin(a) * (2 + i * 0.4)))
			_line(pts, col.darkened(0.25), 3.0)
		"puff":
			_shape(_ell(base + Vector2(-2, 2), 8, 8), Color("f4f0e8"), 0.3, 1.6)
		"rat":
			_tube(_bez(base, base + Vector2(-30, 20), base + Vector2(-56, 10), 10), 4, 1.5, Color("d8a0a0"))
		"squirrel":
			var p := _bez3(base, base + Vector2(-26, 0), base + Vector2(-30, -40), base + Vector2(-6, -52))
			_tube(p, 18, 12, col)
		"reptile":
			var p := _bez3(base + Vector2(4, 6), base + Vector2(-30, 10), base + Vector2(-50, ground - base.y - 8), base + Vector2(-75, ground - base.y - 4))
			_tube(p, 18, 2, col)
		"scorpion":
			var segs := 6
			var prev := base
			for i in segs:
				var a := lerpf(PI * 0.95, PI * 2.25, float(i + 1) / segs)
				var p := base + Vector2(14, -10) + Vector2(cos(a) * 36, sin(a) * 40)
				_tube(_P([prev, p]), 11 - i, 10 - i, col.darkened(0.15))
				prev = p
			_shape(_P([prev, prev + Vector2(12, 4), prev + Vector2(18, 16), prev + Vector2(4, 8)]), Color("2b2118"), 0.0, 1.4)
		"snake":
			var p := _bez3(base, base + Vector2(-24, 6), base + Vector2(-34, -26), base + Vector2(-20, -40))
			_tube(p, 9, 6, Color("4a7a3a"))
			var h := p[p.size() - 1]
			_shape(_ell(h + Vector2(5, -2), 9, 6, -0.4), Color("4a7a3a"), 0.4, 1.6)
			_dot(h + Vector2(7, -5), 1.5, Color("f1c40f"))


## Dört ayaklı başı (pos = kafatası merkezi, sağa bakar)
static func _qhead(pos: Vector2, head: String, col: Color, col2: Color, k: float) -> void:
	var r := 14.0 * k
	var sn := float(L.get("snout", 1.0))
	var ears := str(L.get("ears", ""))
	if ears == "":
		ears = {"canine": "pointed", "feline": "feline", "equine": "small", "bovine": "side", "ursine": "round",
				"rodent": "round", "deer": "pointed", "goat": "side", "boar": "pointed", "rhino": "small"}.get(head, "none")
	if head == "feline" and bool(L.get("mane", false)):
		var mc := _c("mane_col", col.darkened(0.4))
		var mane := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			var rr := r * (2.0 + (0.3 if i % 2 == 0 else 0.0))
			mane.append(pos + Vector2(-r * 0.3, r * 0.2) + Vector2(cos(a) * rr * 0.9, sin(a) * rr))
		_shape(mane, mc, 0.8, 2.0)
	_qears(pos, r, ears, col, true)
	match head:
		"bird", "owl":
			var bc := _c("beak_col", Color("e8b923"))
			var hc := _c("front_col", col2) if head == "bird" else col2
			_shape(_ell(pos, r * 1.15, r * 1.05), hc, 1.0, 2.0)
			if head == "owl":
				_shape(_ell(pos + Vector2(4, 1), r * 0.85, r * 0.85), hc.lightened(0.2), 0.0, 1.4)
				_shape(_P([pos + Vector2(r * 0.7, -2), pos + Vector2(r * 1.3, 4), pos + Vector2(r * 0.7, 9)]), bc, 0.5, 1.6)
				_creature_eye(pos + Vector2(r * 0.4, -r * 0.3), 3.6)
				for s: float in [-1.0, 1.0]:
					_shape(_P([pos + Vector2(-r * 0.4 + s * 6, -r * 0.8), pos + Vector2(-r * 0.2 + s * 6, -r * 1.6), pos + Vector2(s * 6 + 2, -r * 0.8)]), col.darkened(0.2), 0.0, 1.4)
			else:
				var beak := _P([pos + Vector2(r * 0.6, -r * 0.45), pos + Vector2(r * 1.9, -r * 0.2), pos + Vector2(r * 2.0, r * 0.35), pos + Vector2(r * 1.7, r * 0.15), pos + Vector2(r * 0.65, r * 0.45)])
				_shape(_smooth(beak, 1), bc, 0.6, 1.8)
				_creature_eye(pos + Vector2(r * 0.25, -r * 0.3), 3.0)
				_line(_P([pos + Vector2(r * 0.25 - 6, -r * 0.3 - 4), pos + Vector2(r * 0.25 + 5, -r * 0.3 - 6)]), INK, 2.0)
			return
		"elephant":
			var big := r * 1.6
			_shape(_ell(pos + Vector2(-big * 0.5, 0), big * 0.75, big * 0.95, 0.2), col.darkened(0.12), 0.6, 2.0)
			_shape(_ell(pos, big, big * 0.85), col, 1.0, 2.2)
			var trunk := _bez3(pos + Vector2(big * 0.75, 0), pos + Vector2(big * 1.3, big * 0.4), pos + Vector2(big * 1.1, big * 1.6), pos + Vector2(big * 1.5, big * 1.9))
			_tube(trunk, big * 0.55, big * 0.25, col)
			if bool(L.get("tusks", false)):
				_tube(_bez(pos + Vector2(big * 0.5, big * 0.55), pos + Vector2(big * 1.2, big * 1.2), pos + Vector2(big * 1.7, big * 0.7), 10), 8, 3, BONE)
			_creature_eye(pos + Vector2(big * 0.3, -big * 0.15), 2.8)
			if bool(L.get("wool", false)):
				_fur_head(pos, big, col)
			return
	var sl := (6.0 + sn * 11.0) * k
	var sh := r * 0.62
	var snout := PackedVector2Array()
	var sc := pos + Vector2(r * 0.65 + sl * 0.5, r * 0.3)
	match head:
		"equine", "deer", "goat":
			sl = r * (1.9 if head == "equine" else 1.4)
			snout = _P([pos + Vector2(r * 0.2, -r * 0.7), pos + Vector2(r * 0.6 + sl, r * 0.15), pos + Vector2(r * 0.65 + sl, r * 0.75), pos + Vector2(r * 0.3 + sl * 0.7, r * 0.95), pos + Vector2(-r * 0.2, r * 0.75)])
			snout = _smooth(snout, 1)
			sc = pos + Vector2(r * 0.6 + sl, r * 0.45)
		"bovine":
			sl = r * 1.1
			snout = _P([pos + Vector2(0, -r * 0.6), pos + Vector2(r * 0.6 + sl, 0), pos + Vector2(r * 0.7 + sl, r * 1.0), pos + Vector2(r * 0.2, r * 1.1)])
			snout = _smooth(snout, 1)
			sc = pos + Vector2(r * 0.65 + sl, r * 0.55)
		"reptile":
			sl = r * 2.4 * sn
			snout = _P([pos + Vector2(-r * 0.2, -r * 0.6), pos + Vector2(r * 0.4 + sl, r * 0.0), pos + Vector2(r * 0.5 + sl, r * 0.5), pos + Vector2(-r * 0.2, r * 0.75)])
			sc = pos + Vector2(r * 0.4 + sl, r * 0.2)
		"rhino":
			sl = r * 1.6
			snout = _smooth(_P([pos + Vector2(0, -r * 0.6), pos + Vector2(r * 0.6 + sl, r * 0.0), pos + Vector2(r * 0.7 + sl, r * 0.9), pos + Vector2(0, r * 1.0)]), 1)
			sc = pos + Vector2(r * 0.6 + sl, r * 0.4)
		_:
			snout = _ell(sc, sl * 0.6 + r * 0.25, sh)
			if head == "boar":
				snout = _ell(sc, sl * 0.55 + r * 0.3, sh * 1.05)
	_shape(_ell(pos, r, r * 0.92), col, 1.0, 2.0)
	_shape(snout, col if head in ["equine", "reptile", "rhino", "bovine"] else col.lightened(0.06), 0.5, 2.0)
	if head == "feline" or head == "canine" or head == "rodent" or head == "ursine":
		_fill(_ell(sc + Vector2(0, sh * 0.35), sl * 0.45 + r * 0.2, sh * 0.5), Color(col2, 0.8))
	# burun, ağız, diş
	match head:
		"reptile":
			_line(_P([pos + Vector2(-r * 0.1, r * 0.45), sc + Vector2(r * 0.1, r * 0.2)]), INK, 1.8)
			for i in 6:
				var t := 0.2 + i * 0.13
				var p := (pos + Vector2(-r * 0.1, r * 0.45)).lerp(sc + Vector2(0, r * 0.2), t)
				_fill(_P([p + Vector2(-1.8, 0), p + Vector2(1.8, 0), p + Vector2(0, 4)]), Color("f4f0e0"))
			_dot(sc + Vector2(-2, -r * 0.25), 1.6, INK)
		"boar":
			_shape(_ell(sc + Vector2(sl * 0.55, 0), 4, 6), Color("d89090").lerp(col, 0.3), 0.0, 1.4)
			if bool(L.get("tusks", false)):
				_tube(_bez(sc + Vector2(0, sh * 0.6), sc + Vector2(6, sh * 0.2), sc + Vector2(4, -sh * 0.8), 6), 5, 1.5, BONE)
		"equine", "deer", "goat", "bovine", "rhino":
			_dot(sc + Vector2(-2, -1), 2.4, INK)
			_line(_P([sc + Vector2(-r * 0.5, sh * 0.85), sc + Vector2(0, sh * 0.7)]), INK, 1.4)
		_:
			_shape(_ell(sc + Vector2(sl * 0.42, -sh * 0.35), 4.5 * k, 3.5 * k), INK, 0.0, 0.0)
			_line(_P([sc + Vector2(sl * 0.4, sh * 0.15), sc + Vector2(-sl * 0.2, sh * 0.55), sc + Vector2(-sl * 0.6, sh * 0.35)]), INK, 1.5)
			if head == "feline":
				for i in 3:
					_line(_P([sc + Vector2(sl * 0.1, 0), sc + Vector2(sl * 0.1 + 18, -4 + i * 4)]), Color(INK, 0.5), 0.9)
			if bool(L.get("fire", false)) or L.has("eye"):
				_fill(_P([sc + Vector2(sl * 0.1, sh * 0.3), sc + Vector2(sl * 0.2, sh * 0.3), sc + Vector2(sl * 0.15, sh * 0.8)]), Color.WHITE)
	if bool(L.get("face_stripe", false)):
		_tube(_P([pos + Vector2(-r * 0.6, -r * 0.7), sc + Vector2(sl * 0.3, -sh * 0.5)]), 5, 3, Color("f2f0ea"), 0)
	if bool(L.get("beard", false)):
		_shape(_P([pos + Vector2(r * 0.5 + sl * 0.5, r * 0.9), pos + Vector2(r * 0.9 + sl * 0.5, r * 0.9), pos + Vector2(r * 0.6 + sl * 0.5, r * 2.0)]), col.lightened(0.15), 0.3, 1.4)
	_creature_eye(pos + Vector2(r * 0.25, -r * 0.25), 2.6 * k)
	_qears(pos, r, ears, col, false)
	_qhorns(pos, r, sc, sl, col)
	if bool(L.get("wool", false)):
		_fur_head(pos, r, col)


static func _fur_head(pos: Vector2, r: float, col: Color) -> void:
	for i in 7:
		var a := lerpf(PI * 1.1, PI * 1.9, i / 6.0)
		_shape(_ell(pos + Vector2(cos(a) * r * 0.9 - r * 0.2, sin(a) * r * 0.9), r * 0.32, r * 0.32, 0.0, 10), _c("col", col).lightened(0.05), 0.0, 1.2)


static func _qears(pos: Vector2, r: float, ears: String, col: Color, far: bool) -> void:
	var c := col.darkened(0.2) if far else col
	var off := Vector2(-6, -1) if far else Vector2.ZERO
	var b := pos + off
	match ears:
		"pointed", "big", "tufted", "feline":
			var h := r * (1.25 if ears == "big" else (0.8 if ears == "feline" else 1.0))
			var pts := _P([b + Vector2(-r * 0.55, -r * 0.55), b + Vector2(-r * 0.35, -r * 0.55 - h), b + Vector2(r * 0.05, -r * 0.75)])
			_shape(pts, c, 0.3, 1.6)
			if not far:
				_fill(_xf(pts, b + Vector2(-r * 0.3, -r * 0.8), 0.5, Vector2.ZERO), Color("c88a80").lerp(col, 0.4))
			if ears == "tufted":
				_line(_P([b + Vector2(-r * 0.35, -r * 0.55 - h), b + Vector2(-r * 0.3, -r * 0.55 - h - 9)]), INK, 1.6)
		"round":
			_shape(_ell(b + Vector2(-r * 0.35, -r * 0.85), r * 0.42, r * 0.42), c, 0.3, 1.6)
		"small":
			_shape(_P([b + Vector2(-r * 0.6, -r * 0.5), b + Vector2(-r * 0.5, -r * 1.35), b + Vector2(-r * 0.15, -r * 0.7)]), c, 0.3, 1.6)
		"long", "rabbit":
			var el := r * (2.6 if ears == "rabbit" else 1.7)
			_shape(_ell(b + Vector2(-r * 0.5, -r * 0.6 - el * 0.45), r * 0.3, el * 0.5, -0.25), c, 0.4, 1.6)
		"floppy":
			if not far:
				_shape(_ell(b + Vector2(-r * 0.45, r * 0.15), r * 0.35, r * 0.75, 0.3), col.darkened(0.15), 0.4, 1.6)
		"side":
			_shape(_ell(b + Vector2(-r * 0.75, -r * 0.35), r * 0.5, r * 0.22, -0.4), c, 0.3, 1.6)


static func _qhorns(pos: Vector2, r: float, sc: Vector2, sl: float, col: Color) -> void:
	var hc := _c("horn_col", BONE)
	match str(L.get("horns", "none")):
		"antlers":
			var base := pos + Vector2(-r * 0.2, -r * 0.8)
			var main := _bez(base, base + Vector2(-14, -26), base + Vector2(4, -52), 10)
			_tube(main, 5, 2.5, Color("8a6a4a"))
			for k: int in [3, 6, 8]:
				var p: Vector2 = main[k]
				_tube(_P([p, p + Vector2(10, -12)]), 3.5, 1.2, Color("8a6a4a"))
			var far := _move(main, Vector2(9, 2))
			_line(far, Color("6a4a2a"), 2.5)
		"bull":
			for s: float in [0.0, 1.0]:
				var b := pos + Vector2(-r * 0.1 + s * 5, -r * 0.7)
				_tube(_bez3(b, b + Vector2(-16, -2), b + Vector2(-16, -20), b + Vector2(2, -24)), 8, 2, hc.darkened(0.2 * (1.0 - s)))
		"small":
			_tube(_P([pos + Vector2(-r * 0.1, -r * 0.8), pos + Vector2(-r * 0.3, -r * 1.25)]), 5, 1.5, hc)
		"goat":
			_tube(_bez(pos + Vector2(0, -r * 0.8), pos + Vector2(-r * 0.3, -r * 1.8), pos + Vector2(-r * 1.3, -r * 1.5), 10), 7, 2, Color("6b5a4a"))
		"ram":
			var pts := PackedVector2Array()
			for i in 22:
				var a := -PI * 0.5 - i * 0.28
				var rr := r * (0.95 - i * 0.03)
				pts.append(pos + Vector2(-r * 0.25, -r * 0.1) + Vector2(cos(a), sin(a)) * rr)
			_tube(pts, 10, 4, Color("c8b898"))
		"unicorn":
			var b := pos + Vector2(r * 0.4, -r * 0.8)
			var tip := b + Vector2(18, -30)
			_shape(_P([b + Vector2(-4, 2), tip, b + Vector2(4, 2)]), Color("f4e8a8"), 0.5, 1.6)
			for k in 4:
				var p := b.lerp(tip, 0.2 + k * 0.18)
				_line(_P([p + Vector2(-3, 1), p + Vector2(2, -1)]), Color("c8a850"), 1.0)
			_glow(tip, 14, Color("f4e8ff"))
		"rhino":
			_shape(_P([sc + Vector2(-8, -r * 0.4), sc + Vector2(6, -r * 1.6), sc + Vector2(6, -r * 0.3)]), BONE, 0.4, 1.6)
			_shape(_P([sc + Vector2(-22, -r * 0.55), sc + Vector2(-14, -r * 1.1), sc + Vector2(-10, -r * 0.5)]), BONE, 0.4, 1.4)


# ---------- kuşlar

static func _bird() -> void:
	var col := _c("col", Color("6b4a2a"))
	var col2 := _c("col2", col.lightened(0.4))
	var bc := _c("col3", Color("e8b923"))
	var shape := str(L.get("shape", "perch"))
	var spread: bool = str(L.get("wing", "folded")) == "spread"
	var fire := bool(L.get("fire", false))
	if spread:
		_fit(Vector2(-95, -95), Vector2(95, 70), 186)
	else:
		_fit(Vector2(-60, -60), Vector2(60, 66), 170)
	if fire:
		_glow(Vector2(0, -6), 95, Color("f39c12"), 6)
	var water := shape == "water"
	if water:
		_fill(_P([Vector2(-120, 36), Vector2(120, 36), Vector2(120, 120), Vector2(-120, 120)]), Color("3a6ea5"))
		for i in 4:
			_line(_bez(Vector2(-100 + i * 55, 44 + i % 2 * 8), Vector2(-85 + i * 55, 38 + i % 2 * 8), Vector2(-70 + i * 55, 44 + i % 2 * 8), 6), Color(1, 1, 1, 0.5), 1.6)
	elif not spread and shape != "fowl":
		_tube(_P([Vector2(-80, 50), Vector2(80, 44)]), 8, 7, Color("5e3b1f"))
	var wcol := _c("wing_col", col)
	if spread:
		for s: float in [-1.0, 1.0]:
			var root := Vector2(s * 10, -8)
			for i in 7:
				var a := lerpf(-1.25, 0.25, i / 6.0)
				var dir := Vector2(cos(a) * s, sin(a))
				var tip := root + dir * (92.0 - absf(i - 2) * 6.0)
				var nrm := dir.orthogonal() * 9.0
				var fc := wcol.darkened(0.06 * i)
				if fire:
					fc = Color("e74c3c").lerp(Color("f7dc6f"), i / 7.0)
				_shape(_P([root, root.lerp(tip, 0.45) + nrm, tip, root.lerp(tip, 0.55) - nrm]), fc, 0.4, 1.6)
	# kuyruk
	var tail := str(L.get("tail", "fan"))
	var tail_base := Vector2(-22, 26) if not water else Vector2(-30, 24)
	match tail:
		"long", "phoenix":
			for k in 3:
				var p := _bez(tail_base, tail_base + Vector2(-20, 20 + k * 6), tail_base + Vector2(-34 + k * 8, 64), 8)
				_tube(p, 9, 3, (Color("f39c12") if fire else col.darkened(0.15)))
				if tail == "phoenix":
					_flame(p[p.size() - 1] + Vector2(0, 8), 18, 6, Color("e74c3c"), Color("f7dc6f"), -0.4)
		"rooster":
			for k in 4:
				var p := _bez(tail_base + Vector2(0, -8), tail_base + Vector2(-26, -40 + k * 8), tail_base + Vector2(-36 + k * 6, 10 + k * 6), 8)
				_tube(p, 7, 2, Color("1e4a3a").lerp(Color("2b2b30"), k / 3.0))
		_:
			_shape(_P([tail_base + Vector2(4, -6), tail_base + Vector2(-26, 22), tail_base + Vector2(-14, 30), tail_base + Vector2(8, 6)]), col.darkened(0.2), 0.4, 1.8)
	# bacaklar
	if not water:
		for s: float in [0.0, 1.0]:
			var hip := Vector2(-2 + s * 10, 30)
			var foot := Vector2(hip.x + 2, 48)
			_line(_P([hip, foot]), bc.darkened(0.2), 3.0)
			for k in 3:
				_line(_P([foot, foot + Vector2(-4 + k * 5, 4)]), bc.darkened(0.3), 2.0)
	# gövde
	var body: PackedVector2Array
	var head_c := Vector2(24, -26)
	var hr := 15.0
	match shape:
		"owl":
			body = _ell(Vector2(0, 8), 30, 38)
			head_c = Vector2(2, -34)
			hr = 26.0
		"fowl":
			body = _ell(Vector2(-4, 12), 36, 28, -0.1)
			head_c = Vector2(26, -24)
			hr = 12.0
		"water":
			body = _ell(Vector2(-6, 18), 40, 20)
			head_c = Vector2(30, -26) if L.get("neck", "") != "long" else Vector2(26, -52)
			hr = 12.0
		_:
			body = _ell(Vector2(0, 6), 26, 34, -0.45)
	_shape(body, col, 1.0, 2.2)
	var chest := _ell(Vector2(8, 10), 16, 26, -0.45) if shape not in ["owl", "water", "fowl"] else _ell(Vector2(4, 18), 22, 22)
	for p in Geometry2D.intersect_polygons(chest, body):
		_fill(p, Color(col2, 0.9))
	if L.get("pattern", "") == "bars":
		for i in 6:
			_line(_P([Vector2(0 + i, 4 + i * 6), Vector2(12 + i, 4 + i * 6)]), col.darkened(0.3), 1.6)
	if not spread:
		var wing := _P([Vector2(-14, -16), Vector2(16, -6), Vector2(14, 22), Vector2(-26, 40), Vector2(-30, 14)])
		if shape == "owl":
			wing = _P([Vector2(-26, -8), Vector2(-8, 0), Vector2(-10, 36), Vector2(-26, 42), Vector2(-34, 14)])
		if water:
			wing = _P([Vector2(-34, 8), Vector2(10, 4), Vector2(14, 20), Vector2(-40, 26)])
		_shape(_smooth(wing, 1), wcol.darkened(0.1), 0.6, 2.0)
		for k in 3:
			_line(_P([Vector2(-20 + k * 8, 18 + k * 2), Vector2(-28 + k * 8, 34)]), wcol.darkened(0.4), 1.2)
	if L.get("neck", "") == "long":
		_tube(_bez(Vector2(14, 6), Vector2(36, -16), head_c + Vector2(-2, 6), 10), 13, 9, col)
	elif shape == "water" or shape == "fowl":
		_tube(_P([Vector2(14, 4), head_c + Vector2(-4, 4)]), 16, 12, col)
	if bool(L.get("ruff", false)):
		_shape(_ell(head_c + Vector2(-8, 14), 16, 9), Color("f2ead7"), 0.4, 1.6)
	var hcol := _c("head_col", col)
	_shape(_ell(head_c, hr, hr * 0.95), hcol, 1.0, 2.0)
	if bool(L.get("comb", false)):
		_shape(_P([head_c + Vector2(-8, -hr * 0.7), head_c + Vector2(-4, -hr - 8), head_c + Vector2(0, -hr - 2), head_c + Vector2(4, -hr - 8), head_c + Vector2(8, -hr * 0.6)]), Color("d83a2a"), 0.3, 1.4)
		_shape(_ell(head_c + Vector2(hr * 0.6, hr * 0.9), 4, 6), Color("d83a2a"), 0.3, 1.4)
	if shape == "owl":
		for s: float in [-1.0, 1.0]:
			var ec := head_c + Vector2(s * 11, -2)
			_shape(_ell(ec, 11, 11), col2.lightened(0.2), 0.0, 1.4)
			_dot(ec, 7, _c("eye", Color("f39c12")))
			_dot(ec, 3.8, INK)
			_dot(ec + Vector2(-2, -2), 1.4, Color.WHITE)
			_shape(_P([head_c + Vector2(s * 12, -hr * 0.8), head_c + Vector2(s * 20, -hr - 10), head_c + Vector2(s * 4, -hr * 0.9)]), col.darkened(0.2), 0.3, 1.4)
		_shape(_P([head_c + Vector2(-4, 6), head_c + Vector2(4, 6), head_c + Vector2(0, 16)]), bc, 0.4, 1.4)
		return
	var bk := head_c + Vector2(hr * 0.75, 0)
	match str(L.get("beak", "short")):
		"hook":
			_shape(_P([bk + Vector2(-2, -6), bk + Vector2(14, -4), bk + Vector2(17, 6), bk + Vector2(11, 2), bk + Vector2(-2, 5)]), bc, 0.5, 1.6)
		"long":
			_shape(_P([bk + Vector2(-2, -5), bk + Vector2(24, 1), bk + Vector2(-2, 5)]), bc, 0.4, 1.6)
		"flat":
			_shape(_smooth(_P([bk + Vector2(-2, -4), bk + Vector2(16, -2), bk + Vector2(18, 3), bk + Vector2(-2, 5)]), 1), bc, 0.4, 1.6)
		"parrot":
			_shape(_P([bk + Vector2(-3, -7), bk + Vector2(10, -6), bk + Vector2(12, 8), bk + Vector2(4, 4), bk + Vector2(-3, 6)]), Color("2b2b30"), 0.3, 1.6)
		_:
			_shape(_P([bk + Vector2(-2, -4), bk + Vector2(9, 1), bk + Vector2(-2, 5)]), bc, 0.4, 1.6)
	_creature_eye(head_c + Vector2(hr * 0.2, -hr * 0.2), 2.6)
	if fire:
		for i in 5:
			_flame(head_c + Vector2(-hr * 0.6 + i * 5, -hr * 0.6), 14 + i * 2, 4, Color("e74c3c"), Color("f7dc6f"), -0.5)


static func _bat() -> void:
	var col := _c("col", Color("3a3030"))
	_fit(Vector2(-96, -60), Vector2(96, 60), 186)
	for s: float in [-1.0, 1.0]:
		var root := Vector2(s * 12, -8)
		var top := root + Vector2(s * 40, -46)
		var f := [root + Vector2(s * 92, -30), root + Vector2(s * 88, 14), root + Vector2(s * 58, 40)]
		var pts := _P([root, top, f[0], f[0].lerp(f[1], 0.5) + Vector2(-s * 10, 0), f[1], f[1].lerp(f[2], 0.5) + Vector2(-s * 10, -4), f[2], root + Vector2(0, 26)])
		_shape(pts, col.lightened(0.08), 0.6, 2.0)
		for p in f:
			_line(_P([top, p]), INK, 1.8)
		_line(_P([root, top]), INK, 3.0)
	_shape(_ell(Vector2(0, 8), 18, 26), col, 1.0, 2.2)
	_shape(_ell(Vector2(0, -22), 16, 14), col, 1.0, 2.0)
	for s: float in [-1.0, 1.0]:
		_shape(_P([Vector2(s * 6, -30), Vector2(s * 16, -54), Vector2(s * 16, -28)]), col, 0.4, 1.6)
		_creature_eye(Vector2(s * 6, -24), 2.4)
	_fill(_P([Vector2(-4, -14), Vector2(-1, -14), Vector2(-2.5, -9)]), Color.WHITE)
	_fill(_P([Vector2(4, -14), Vector2(1, -14), Vector2(2.5, -9)]), Color.WHITE)


# ---------- su canlıları

static func _water_bg() -> void:
	for i in 6:
		_dot(Vector2(-60 + _hash(i) * 120, -60 + _hash(i + 9) * 110), 2 + _hash(i + 3) * 3, Color(1, 1, 1, 0.25))


static func _fish() -> void:
	var col := _c("col", Color("e67e22"))
	var col2 := _c("col2", Color("f2ead7"))
	var shape := str(L.get("shape", "fish"))
	_water_bg()
	var lx := 70.0
	var ly := 28.0
	if shape == "whale":
		lx = 82
		ly = 36
	elif shape == "shark":
		lx = 78
		ly = 24
	var body := PackedVector2Array()
	for i in 30:
		var t := float(i) / 29.0
		var x := lerpf(-lx, lx, t)
		var y := -sin(t * PI) * ly * (1.0 + 0.25 * t if shape == "whale" else 1.0)
		body.append(Vector2(x, y))
	for i in 30:
		var t := 1.0 - float(i) / 29.0
		var x := lerpf(-lx, lx, t)
		body.append(Vector2(x, sin(t * PI) * ly * (0.8 if shape != "whale" else 0.9)))
	if shape == "whale":
		body = _smooth(_P([Vector2(-80, -6), Vector2(-30, -28), Vector2(40, -40), Vector2(84, -18), Vector2(84, 20), Vector2(40, 34), Vector2(-30, 22), Vector2(-80, 4)]), 2)
	elif shape == "dolphin":
		body = _smooth(_P([Vector2(-74, 0), Vector2(-20, -22), Vector2(40, -26), Vector2(66, -10), Vector2(92, -2), Vector2(66, 4), Vector2(40, 20), Vector2(-20, 16)]), 2)
	var tail := _P([Vector2(-lx + 6, 0), Vector2(-lx - 26, -26), Vector2(-lx - 18, 0), Vector2(-lx - 26, 26)])
	if shape in ["whale", "dolphin"]:
		tail = _P([Vector2(-72, 0), Vector2(-96, -22), Vector2(-88, 0), Vector2(-96, 18)])
	_shape(tail, col.darkened(0.1), 0.5, 2.0)
	var dorsal := _P([Vector2(-10, -ly + 4), Vector2(6, -ly - 22), Vector2(20, -ly + 2)])
	if shape == "fish":
		dorsal = _P([Vector2(-30, -ly + 6), Vector2(-10, -ly - 10), Vector2(20, -ly - 6), Vector2(30, -ly + 6)])
	if shape != "whale":
		_shape(dorsal, col.darkened(0.12), 0.5, 2.0)
	_shape(body, col, 1.0, 2.4)
	_belly(body, 4.0, col2)
	var head := Vector2(lx * 0.62, -ly * 0.2)
	_creature_eye(head + Vector2(0, -4), 3.2 if shape != "whale" else 2.6)
	_shape(_P([Vector2(10, 6), Vector2(-6, 26), Vector2(18, 12)]), col.darkened(0.15), 0.4, 1.6)
	match shape:
		"shark":
			_line(_bez(Vector2(lx * 0.4, 10), Vector2(lx * 0.7, 16), Vector2(lx * 0.92, 6), 8), INK, 2.0)
			for i in 6:
				var p := Vector2(lx * 0.45 + i * 6, 12 + i * 0.3)
				_fill(_P([p, p + Vector2(4, 0), p + Vector2(2, -5)]), Color.WHITE)
			for k in 4:
				_line(_P([Vector2(lx * 0.3 - k * 5, -8), Vector2(lx * 0.32 - k * 5, 6)]), INK, 1.2)
		"whale":
			_line(_bez(Vector2(40, 18), Vector2(65, 22), Vector2(84, 10), 8), INK, 2.0)
			for k in 3:
				_line(_P([Vector2(10 + k * 12, 24), Vector2(30 + k * 12, 28)]), col.darkened(0.3), 1.4)
			for k in 3:
				_line(_bez(Vector2(42, -40), Vector2(40 + (k - 1) * 12, -64), Vector2(40 + (k - 1) * 22, -58), 6), Color(0.85, 0.95, 1, 0.8), 2.0)
		_:
			_line(_bez(Vector2(lx * 0.4, -10), Vector2(lx * 0.35, 0), Vector2(lx * 0.4, 10), 6), col.darkened(0.3), 1.6)
			if shape == "fish":
				for i in 10:
					var p := Vector2(-40 + (i % 5) * 16, -8 + (i / 5) * 12)
					_arc(p, 5, -0.8, 0.8, 6, _tint(col.darkened(0.25)), 1.2)


static func _serpent() -> void:
	var col := _c("col", Color("4a7a3a"))
	var col2 := _c("col2", Color("c8c070"))
	var thick := float(L.get("thick", 1.0))
	var water := bool(L.get("water", false))
	if water:
		_fill(_P([Vector2(-120, 30), Vector2(120, 30), Vector2(120, 120), Vector2(-120, 120)]), Color("2a5a9a"))
	var path := PackedVector2Array()
	for i in 40:
		var t := float(i) / 39.0
		path.append(Vector2(lerpf(-80, 30, t), 30 + sin(t * TAU * 1.1 + 0.4) * 22 * (1.0 - t * 0.4) - t * 40))
	var head := Vector2(48, -32)
	path.append_array(_bez(path[path.size() - 1], Vector2(32, -40), head + Vector2(-8, 4), 8))
	if bool(L.get("hood", false)):
		_shape(_ell(head + Vector2(-10, 8), 20, 28, -0.2), col.darkened(0.1), 0.6, 2.0)
		_fill(_ell(head + Vector2(-8, 10), 12, 20, -0.2), col2)
	var taper := _taper(path, 4 * thick, 22 * thick)
	_shape(taper, col, 0.6, 2.4)
	_line(_move(path, Vector2(1, 4 * thick)), Color(col2, 0.7), 5 * thick)
	if L.get("pattern", "") in ["bands", "diamonds"]:
		for i in range(4, path.size() - 4, 5):
			var d := (path[i + 1] - path[i - 1]).normalized().orthogonal()
			var w := lerpf(2, 11, float(i) / path.size()) * thick
			if L.get("pattern", "") == "diamonds":
				_fill(_P([path[i] + d * w, path[i] + (path[i + 1] - path[i]).normalized() * 6, path[i] - d * w, path[i] - (path[i + 1] - path[i]).normalized() * 6]), col.darkened(0.4))
			else:
				_line(_P([path[i] + d * w, path[i] - d * w]), col.darkened(0.45), 3.5)
	if bool(L.get("fins", false)):
		for i in range(8, path.size() - 6, 4):
			var d := (path[i + 1] - path[i - 1]).normalized().orthogonal()
			var w := lerpf(2, 11, float(i) / path.size()) * thick
			_shape(_P([path[i] - d * w, path[i] - d * (w + 9) - (path[i + 1] - path[i - 1]).normalized() * 5, path[i - 2] - d * w]), col2.darkened(0.2), 0.0, 1.2)
	var hs := 1.0 * thick
	var hp := _P([head + Vector2(-14, -10) * hs, head + Vector2(10, -9) * hs, head + Vector2(22, 0) * hs, head + Vector2(10, 9) * hs, head + Vector2(-12, 10) * hs])
	_shape(_smooth(hp, 1), col, 1.0, 2.0)
	_creature_eye(head + Vector2(2, -4) * hs, 2.8)
	_line(_P([head + Vector2(22, 1) * hs, head + Vector2(34, 2) * hs]), Color("c0392b"), 2.0)
	_line(_P([head + Vector2(34, 2) * hs, head + Vector2(39, -2) * hs]), Color("c0392b"), 1.4)
	_line(_P([head + Vector2(34, 2) * hs, head + Vector2(39, 6) * hs]), Color("c0392b"), 1.4)
	if bool(L.get("horns", false)):
		_tube(_bez(head + Vector2(-6, -8) * hs, head + Vector2(-16, -24) * hs, head + Vector2(-30, -26) * hs, 6), 7, 1.5, BONE)
	if water:
		for i in 5:
			_line(_bez(Vector2(-100 + i * 45, 36), Vector2(-85 + i * 45, 28), Vector2(-70 + i * 45, 36), 6), Color(1, 1, 1, 0.6), 2.0)


static func _hydra() -> void:
	var col := _c("col", Color("3a6a4a"))
	var col2 := _c("col2", Color("a8c080"))
	var n := int(L.get("heads", 5))
	_ground(70)
	var body := _ell(Vector2(-6, 46), 54, 26)
	var heads := []
	for i in n:
		var a := lerpf(-2.6, -0.5, i / float(n - 1))
		heads.append(Vector2(-4, 40) + Vector2(cos(a) * 70, sin(a) * 78))
	for i in n:
		var h: Vector2 = heads[i]
		var base := Vector2(-20 + i * 10, 30)
		_tube(_bez(base, base.lerp(h, 0.5) + Vector2(sin(i * 2.0) * 16, 0), h + Vector2(-4, 6), 10), 16, 10, col.darkened(0.04 * (i % 2)))
	_shape(body, col, 1.0, 2.4)
	_belly(body, 52, col2)
	for leg: float in [-40.0, 26.0]:
		_tube(_P([Vector2(leg, 56), Vector2(leg + 4, 70)]), 16, 12, col)
	for i in n:
		var h: Vector2 = heads[i]
		var hp := _P([h + Vector2(-10, -8), h + Vector2(8, -7), h + Vector2(17, 1), h + Vector2(7, 8), h + Vector2(-9, 8)])
		_shape(_smooth(hp, 1), col.lightened(0.04 * (i % 2)), 1.0, 1.8)
		_creature_eye(h + Vector2(1, -3), 2.0)
		for k in 3:
			_fill(_P([h + Vector2(4 + k * 4, 5), h + Vector2(6 + k * 4, 5), h + Vector2(5 + k * 4, 9)]), Color.WHITE)


static func _dragon() -> void:
	var col := _c("col", Color("c0392b"))
	var col2 := _c("col2", Color("e8a050"))
	var young := bool(L.get("young", false))
	var wyvern := bool(L.get("wyvern", false))
	var horn := BONE.darkened(0.1)
	var ground := 64.0
	if young:
		_fit(Vector2(-112, -70), Vector2(90, 68), 184)
	else:
		_fit(Vector2(-126, -96), Vector2(104, 68), 190)
	_ground(ground)
	var bx := -14.0
	var by := 18.0
	var rx := 38.0 if not young else 30.0
	var ry := 22.0 if not young else 20.0
	# uzak kanat
	var wroot := Vector2(bx + 6, by - ry * 0.7)
	_dwing(wroot + Vector2(-12, -2), col.darkened(0.3), young, wyvern)
	# kuyruk
	var tail := _bez3(Vector2(bx - rx * 0.8, by), Vector2(bx - rx - 30, by + 30), Vector2(bx - rx - 20, ground - 2), Vector2(bx - rx - 56, ground - 22))
	_tube(tail, 20, 3, col)
	var tip := tail[tail.size() - 1]
	_shape(_P([tip + Vector2(6, 4), tip + Vector2(-8, -12), tip + Vector2(-14, 4), tip + Vector2(-4, 10)]), col.darkened(0.2), 0.3, 1.6)
	# uzak bacaklar
	if not wyvern:
		_dleg(Vector2(bx + rx * 0.55 + 6, by + 6), ground - 2, col.darkened(0.25))
	_dleg(Vector2(bx - rx * 0.5 + 6, by + 6), ground - 2, col.darkened(0.25))
	var body := _ell(Vector2(bx, by), rx, ry, -0.12)
	_shape(body, col, 1.0, 2.4)
	for i in 6:
		var x := bx - rx * 0.55 + i * rx * 0.24
		var plate := _P([Vector2(x - 6, by + 4), Vector2(x + 6, by + 4), Vector2(x + 6, by + 30), Vector2(x - 6, by + 30)])
		for p in Geometry2D.intersect_polygons(plate, body):
			_shape(p, col2, 0.0, 1.0)
	for i in 8:
		var t := i / 7.0
		var x := lerpf(bx - rx * 0.7, bx + rx * 0.5, t)
		var y := by - ry * 0.95 + 5 - 4 * t
		_shape(_P([Vector2(x - 4, y + 2), Vector2(x, y - 9), Vector2(x + 4, y + 2)]), horn.darkened(0.2), 0.0, 1.2)
	if not wyvern:
		_dleg(Vector2(bx + rx * 0.55, by + 10), ground, col)
	_dleg(Vector2(bx - rx * 0.5, by + 10), ground, col)
	# boyun ve baş
	var head := Vector2(bx + rx + 38, by - 62) if not young else Vector2(bx + rx + 26, by - 40)
	var neck := _bez3(Vector2(bx + rx * 0.7, by - 4), Vector2(bx + rx + 22, by - 8), Vector2(bx + rx + 4, head.y + 26), head + Vector2(-8, 6))
	_tube(neck, 22, 14, col)
	_line(_move(neck, Vector2(3, 5)), Color(col2, 0.8), 5)
	# yakın kanat
	_dwing(wroot, col.darkened(0.08), young, wyvern)
	var hp := _P([head + Vector2(-12, -12), head + Vector2(10, -11), head + Vector2(34, -2), head + Vector2(36, 6), head + Vector2(10, 12), head + Vector2(-12, 10)])
	_shape(_smooth(hp, 1), col, 1.0, 2.0)
	_line(_P([head + Vector2(4, 6), head + Vector2(35, 4)]), INK, 1.6)
	for k in 5:
		var p := head + Vector2(10 + k * 5, 5)
		_fill(_P([p, p + Vector2(3, 0), p + Vector2(1.5, 4)]), Color.WHITE)
	_dot(head + Vector2(31, -3), 1.5, INK)
	_creature_eye(head + Vector2(2, -4), 2.8)
	for s: float in [0.0, 1.0]:
		var hb := head + Vector2(-6 + s * 5, -8)
		_tube(_bez(hb, hb + Vector2(-14, -10), hb + Vector2(-28, -16 - s * 4), 8), 7, 1.5, horn.darkened(0.2 * (1.0 - s)))
	_shape(_P([head + Vector2(-10, 4), head + Vector2(-22, 12), head + Vector2(-8, 10)]), col.darkened(0.2), 0.0, 1.2)


static func _dwing(root: Vector2, col: Color, young: bool, wyvern: bool) -> void:
	var k := 0.7 if young else 1.0
	var top := root + Vector2(-6, -72) * k
	var f1 := root + Vector2(-62, -88) * k
	var f2 := root + Vector2(-96, -46) * k
	var f3 := root + Vector2(-80, 4) * k
	var pts := _P([root, top, f1, f1.lerp(f2, 0.5) + Vector2(10, 8), f2, f2.lerp(f3, 0.5) + Vector2(14, 0), f3, root + Vector2(-20, 10)])
	_shape(pts, col.lightened(0.1), 0.5, 2.0)
	for f in [f1, f2, f3]:
		_line(_P([top, f]), INK, 2.0)
	_line(_P([root, top]), INK, 3.5)
	_shape(_P([top + Vector2(-2, -2), top + Vector2(6, -10), top + Vector2(5, 2)]), BONE, 0.0, 1.2)
	if wyvern:
		_line(_P([root + Vector2(-20, 10), root + Vector2(-10, 40)]), INK, 3.0)


static func _dleg(hip: Vector2, ground: float, col: Color) -> void:
	var knee := hip + Vector2(10, (ground - hip.y) * 0.5)
	var foot := Vector2(hip.x + 2, ground)
	_tube(_P([hip, knee, foot + Vector2(0, -4)]), 18, 9, col)
	for k in 3:
		_line(_P([foot + Vector2(-4 + k * 5, -2), foot + Vector2(-1 + k * 6, 3)]), BONE.darkened(0.3), 2.2)


static func _turtle() -> void:
	var col := _c("col", Color("5a6b3a"))
	var col2 := _c("col2", Color("8a7a4a"))
	var dragon := bool(L.get("dragon", false))
	if dragon:
		_fill(_P([Vector2(-120, 40), Vector2(120, 40), Vector2(120, 120), Vector2(-120, 120)]), Color("2a5a9a"))
	else:
		_ground(52)
	for x: float in [-40.0, 30.0]:
		_tube(_P([Vector2(x, 26), Vector2(x + 6, 50)]), 16, 13, col2.darkened(0.2))
	var shell := PackedVector2Array()
	for i in 25:
		var t := float(i) / 24.0
		shell.append(Vector2(lerpf(-64, 56, t), 32 - sin(t * PI) * 58))
	shell.append(Vector2(52, 36))
	shell.append(Vector2(-60, 36))
	var neck := _bez(Vector2(40, 20), Vector2(58, 14), Vector2(70, 2), 8)
	_tube(neck, 18, 14, col2)
	_shape(_ell(Vector2(74, 0), 16 if not dragon else 20, 12), col2, 1.0, 2.0)
	_creature_eye(Vector2(78, -4), 2.6)
	_line(_P([Vector2(76, 6), Vector2(90, 3)]), INK, 1.6)
	if dragon:
		for k in 2:
			_tube(_bez(Vector2(66, -8 + k * 3), Vector2(56, -20), Vector2(44, -24 + k * 4), 6), 6, 1.5, BONE)
	_shape(shell, col, 1.0, 2.6)
	for i in 4:
		var x := -44.0 + i * 28
		var hexs := _ell(Vector2(x, 2 - absf(x + 4) * 0.1), 12, 12, 0.0, 6)
		_stroke(hexs, 1.6, col.darkened(0.45))
		if dragon:
			_shape(_P([Vector2(x - 5, -18 - absf(x) * 0.2), Vector2(x, -36 - absf(x) * 0.15 + 8), Vector2(x + 5, -18 - absf(x) * 0.2)]), BONE, 0.0, 1.2)
	_tube(_P([Vector2(-60, 34), Vector2(54, 34)]), 7, 7, col2)


static func _frog() -> void:
	var col := _c("col", Color("5a8a3a"))
	var col2 := _c("col2", Color("c8d890"))
	_ground(50)
	_tube(_P([Vector2(-30, 30), Vector2(-50, 40), Vector2(-24, 48)]), 18, 10, col.darkened(0.1))
	var body := _smooth(_P([Vector2(-44, 36), Vector2(-30, -8), Vector2(10, -20), Vector2(46, -6), Vector2(50, 22), Vector2(30, 44), Vector2(-20, 46)]), 2)
	_shape(body, col, 1.0, 2.4)
	_belly(body, 22, col2)
	for i in 6:
		_dot(Vector2(-24 + _hash(i) * 50, -6 + _hash(i + 4) * 20), 3 + _hash(i + 2) * 2, col.darkened(0.25))
	_tube(_P([Vector2(26, 24), Vector2(34, 46)]), 11, 8, col)
	for s: float in [0.0, 1.0]:
		var e := Vector2(18 + s * 20, -18 - s * 2)
		_shape(_ell(e, 11, 10), col, 0.6, 2.0)
		_dot(e + Vector2(2, -2), 6, Color("e8b923"))
		_dot(e + Vector2(2, -2), 3.4, INK)
	_line(_bez(Vector2(14, 10), Vector2(36, 18), Vector2(52, 6), 8), INK, 2.0)


static func _octopus() -> void:
	var col := _c("col", Color("c0603a"))
	var col2 := _c("col2", Color("e8a080"))
	var kraken := bool(L.get("kraken", false))
	_water_bg()
	var n := 8
	for i in n:
		var a := lerpf(0.2, PI - 0.2, i / float(n - 1))
		var base := Vector2(cos(a) * 26, 8 + sin(a) * 6)
		var mid := base + Vector2(cos(a) * 30, 34)
		var tip := mid + Vector2(cos(a) * 30 + sin(i * 1.7) * 20, 20 - sin(i * 2.3) * 24)
		var path := _bez3(base, mid, mid + Vector2(cos(a) * 20, 30), tip, 16)
		_tube(path, 16 if not kraken else 20, 2, col.darkened(0.05 * (i % 2)))
		for k in range(3, path.size() - 2, 3):
			_dot(path[k] + Vector2(0, 3), 2.0, col2)
	var mantle := _smooth(_P([Vector2(-34, 14), Vector2(-40, -26), Vector2(-20, -64), Vector2(20, -64), Vector2(40, -26), Vector2(34, 14)]), 2)
	_shape(mantle, col, 1.0, 2.6)
	for i in 5:
		_dot(Vector2(-20 + _hash(i) * 40, -50 + _hash(i + 5) * 40), 3 + _hash(i + 1) * 3, col.darkened(0.2))
	for s: float in [-1.0, 1.0]:
		var e := Vector2(s * 16, -2)
		_shape(_ell(e, 9, 7), Color("f2e8c8") if not kraken else Color("f1c40f"), 0.0, 1.8)
		_fill(_ell(e, 2.2, 5.5), INK)


static func _crab() -> void:
	var col := _c("col", Color("c0392b"))
	var col2 := _c("col2", Color("e8a080"))
	_ground(54)
	for s: float in [-1.0, 1.0]:
		for k in 3:
			var base := Vector2(s * 30, 16 + k * 6)
			_tube(_P([base, base + Vector2(s * 26, -12 + k * 6), base + Vector2(s * 40, 34)]), 7, 3, col.darkened(0.15))
		var arm := _P([Vector2(s * 28, 0), Vector2(s * 48, -24), Vector2(s * 40, -46)])
		_tube(arm, 11, 9, col)
		var claw := Vector2(s * 40, -54)
		_shape(_P([claw + Vector2(-s * 12, 10), claw + Vector2(-s * 14, -14), claw + Vector2(s * 2, -22), claw + Vector2(s * 10, -4), claw + Vector2(s * 2, 10)]), col, 1.0, 2.0)
		_shape(_P([claw + Vector2(s * 4, 2), claw + Vector2(s * 18, -10), claw + Vector2(s * 10, 8)]), col.darkened(0.1), 0.4, 1.6)
	var shell := _ell(Vector2(0, 14), 40, 26)
	_shape(shell, col, 1.0, 2.4)
	for s: float in [-1.0, 1.0]:
		_tube(_P([Vector2(s * 8, -6), Vector2(s * 10, -20)]), 4, 3, col)
		_dot(Vector2(s * 10, -22), 4, INK)
		_dot(Vector2(s * 9, -23), 1.4, Color.WHITE)
	_line(_bez(Vector2(-10, 22), Vector2(0, 26), Vector2(10, 22), 6), col.darkened(0.4), 1.6)


static func _jelly() -> void:
	var col := _c("col", Color("c39bd3"))
	var col2 := _c("col2", Color("e8daef"))
	_water_bg()
	for i in 7:
		var x := -26.0 + i * 9
		var path := PackedVector2Array()
		for k in 14:
			path.append(Vector2(x + sin(k * 0.7 + i) * 6, 8 + k * 6.5))
		_line(path, Color(col, 0.75), 2.2)
	var bell := PackedVector2Array()
	for i in 25:
		var t := float(i) / 24.0
		bell.append(Vector2(lerpf(-42, 42, t), 10 - sin(t * PI) * 56))
	for i in 9:
		var t := 1.0 - i / 8.0
		bell.append(Vector2(lerpf(-42, 42, t), 10 + (5.0 if i % 2 == 0 else 0.0)))
	_fill(bell, Color(col, 0.65))
	_stroke(bell, 2.0, col.darkened(0.4))
	_fill(_ell(Vector2(0, -16), 22, 18), Color(col2, 0.6))
	_fill(_ell(Vector2(-14, -30), 8, 5, -0.4), Color(1, 1, 1, 0.5))


# ---------- böcekler

static func _spider() -> void:
	var col := _c("col", Color("2b2420"))
	var col2 := _c("col2", Color("c0392b"))
	for s: float in [-1.0, 1.0]:
		for k in 4:
			var base := Vector2(s * 12, -2 + k * 6)
			var knee := base + Vector2(s * (40 + k * 4), -34 + k * 16)
			var foot := knee + Vector2(s * (22 - k * 2), 44 + k * 4)
			_tube(_P([base, knee, foot]), 7, 3, col.lightened(0.05 * k))
	var abdomen := _ell(Vector2(0, 30), 32, 34)
	_shape(abdomen, col, 1.0, 2.4)
	_fill(_P([Vector2(-8, 22), Vector2(8, 22), Vector2(0, 32), Vector2(8, 42), Vector2(-8, 42), Vector2(0, 32)]), col2)
	_shape(_ell(Vector2(0, -12), 20, 18), col.lightened(0.05), 1.0, 2.2)
	for p in [Vector2(-6, -20), Vector2(6, -20), Vector2(-10, -14), Vector2(10, -14), Vector2(-3, -12), Vector2(3, -12)]:
		_glow(p, 6, Color("e74c3c"), 3)
		_dot(p, 2.4, Color("e74c3c"))
	for s: float in [-1.0, 1.0]:
		_tube(_bez(Vector2(s * 5, -2), Vector2(s * 8, 8), Vector2(s * 3, 12), 6), 5, 2, col.lightened(0.15))


static func _scorpion() -> void:
	var col := _c("col", Color("2b2420"))
	_ground(50)
	for k in 4:
		var base := Vector2(-20 + k * 12, 26)
		_tube(_P([base, base + Vector2(-6, 10), base + Vector2(-14, 24)]), 5, 3, col.darkened(0.2))
	var prev := Vector2(-40, 18)
	for i in 7:
		var a := lerpf(PI * 0.98, PI * 2.15, float(i + 1) / 7.0)
		var p := Vector2(-30, -10) + Vector2(cos(a) * 40, sin(a) * 44)
		_tube(_P([prev, p]), 14 - i, 12 - i, col.lightened(0.04 * (i % 2)))
		prev = p
	_shape(_P([prev, prev + Vector2(14, 2), prev + Vector2(22, 16), prev + Vector2(6, 8)]), Color("6b2a1a"), 0.3, 1.6)
	for i in 5:
		_shape(_ell(Vector2(-30 + i * 14, 20), 10, 12), col, 0.8, 2.0)
	for s: float in [0.0, 1.0]:
		var arm := _P([Vector2(30, 18 - s * 4), Vector2(48, 10 - s * 12), Vector2(60, 2 - s * 14)])
		_tube(arm, 9, 7, col.darkened(0.15 * (1.0 - s)))
		var c := arm[2]
		_shape(_P([c, c + Vector2(20, -12), c + Vector2(26, 0), c + Vector2(14, 2), c + Vector2(20, 10)]), col.lightened(0.05), 0.6, 1.8)
	_dot(Vector2(36, 12), 2.2, Color("e74c3c"))


static func _insect() -> void:
	var col := _c("col", Color("1e4a3a"))
	var col2 := _c("col2", Color("2e8a6a"))
	var shape := str(L.get("shape", "beetle"))
	_ground(48)
	for k in 3:
		var base := Vector2(-16 + k * 16, 20)
		_tube(_P([base, base + Vector2(-8 + k * 4, 12), base + Vector2(-16 + k * 8, 28)]), 5, 2.5, INK.lightened(0.15))
	match shape:
		"bee":
			for s: float in [0.0, 1.0]:
				_fill(_ell(Vector2(-6 + s * 10, -26), 18, 30, -0.6 + s * 0.4), Color(0.85, 0.95, 1.0, 0.5))
				_stroke(_ell(Vector2(-6 + s * 10, -26), 18, 30, -0.6 + s * 0.4), 1.2, Color(0.5, 0.6, 0.7))
			var abd := _ell(Vector2(-26, 14), 28, 20, 0.2)
			_shape(abd, col, 1.0, 2.2)
			for i in 3:
				var stripe := _P([Vector2(-44 + i * 12, -20), Vector2(-38 + i * 12, -20), Vector2(-34 + i * 12, 40), Vector2(-40 + i * 12, 40)])
				for p in Geometry2D.intersect_polygons(stripe, abd):
					_fill(p, col2)
			_shape(_P([Vector2(-54, 16), Vector2(-66, 22), Vector2(-52, 22)]), INK, 0.0, 1.2)
			_shape(_ell(Vector2(8, 4), 16, 15), col2, 0.8, 2.0)
			_shape(_ell(Vector2(30, 0), 13, 12), col2, 0.8, 2.0)
			_dot(Vector2(36, -3), 5, INK)
		"ant":
			_shape(_ell(Vector2(-30, 16), 22, 17), col, 1.0, 2.0)
			_shape(_ell(Vector2(2, 10), 14, 10), col, 1.0, 2.0)
			_shape(_ell(Vector2(28, 0), 15, 13), col, 1.0, 2.0)
			_shape(_P([Vector2(40, 6), Vector2(52, 12), Vector2(40, 12)]), col2, 0.0, 1.4)
			_dot(Vector2(32, -4), 3, INK)
		"rust":
			_shape(_ell(Vector2(-8, 10), 40, 22), col, 1.0, 2.2)
			for i in 6:
				_line(_P([Vector2(-36 + i * 12, -6), Vector2(-32 + i * 12, 26)]), col2, 2.0)
			_tube(_bez(Vector2(-44, 6), Vector2(-64, 0), Vector2(-70, 24), 8), 10, 3, col)
			_shape(_ell(Vector2(34, 2), 14, 12), col, 1.0, 2.0)
			for s: float in [0.0, 1.0]:
				var ant := _bez(Vector2(38, -8), Vector2(50 + s * 8, -40), Vector2(70 + s * 6, -50), 10)
				_line(ant, col2, 2.2)
				for k in range(2, ant.size(), 2):
					_line(_P([ant[k], ant[k] + Vector2(6, 4)]), col2, 1.4)
			_dot(Vector2(40, -2), 3, INK)
		_:
			var shell := _smooth(_P([Vector2(-44, 22), Vector2(-40, -10), Vector2(-6, -28), Vector2(26, -14), Vector2(30, 22)]), 2)
			_shape(shell, col, 1.0, 2.4)
			_line(_P([Vector2(-8, -27), Vector2(-14, 22)]), INK, 1.8)
			_fill(_ell(Vector2(-18, -12), 10, 4, -0.4), Color(col2, 0.6))
			_shape(_ell(Vector2(34, 8), 13, 11), col.darkened(0.2), 0.8, 2.0)
			_tube(_bez(Vector2(42, 2), Vector2(54, -6), Vector2(56, -22), 6), 7, 2, col.darkened(0.2))
			_dot(Vector2(38, 4), 2.4, Color("e8b923"))
	for s: float in [0.0, 1.0]:
		if shape != "rust":
			_line(_bez(Vector2(36, -6), Vector2(46 + s * 6, -26), Vector2(56 + s * 8, -30), 8), INK, 1.6)


# ---------- canavarlar

static func _eye_monster() -> void:
	var col := _c("col", Color("8a4a6a"))
	var col2 := _c("col2", Color("c08aa0"))
	for i in 8:
		var a := lerpf(-2.7, -0.45, i / 7.0)
		var base := Vector2(cos(a) * 40, sin(a) * 40)
		var tip := base + Vector2(cos(a) * 26 + sin(i * 3.0) * 10, sin(a) * 30)
		_tube(_bez(base, base.lerp(tip, 0.5) + Vector2(sin(i * 2.0) * 8, 0), tip, 8), 7, 4, col.darkened(0.1))
		_shape(_ell(tip, 6.5, 6.5), Color("f4f0e0"), 0.0, 1.4)
		_dot(tip, 3, Color("c0392b"))
		_dot(tip, 1.4, INK)
	_shape(_ell(Vector2(0, 6), 48, 46), col, 1.0, 2.6)
	for i in 10:
		_dot(Vector2(-30 + _hash(i) * 60, -24 + _hash(i + 3) * 56), 2 + _hash(i + 7) * 3, col.darkened(0.2))
	_shape(_ell(Vector2(0, -6), 24, 18), Color("f4f0e0"), 0.0, 2.0)
	_dot(Vector2(0, -6), 13, col2.darkened(0.2))
	_dot(Vector2(0, -6), 7, INK)
	_dot(Vector2(-4, -10), 3, Color.WHITE)
	_line(_bez(Vector2(-26, -14), Vector2(0, -30), Vector2(26, -14), 8), INK, 3.0)
	var mouth := _P([Vector2(-26, 24), Vector2(26, 24), Vector2(18, 38), Vector2(-18, 38)])
	_shape(_smooth(mouth, 1), Color("2a0e14"), 0.0, 2.0)
	for k in 7:
		var x := -20.0 + k * 6.6
		_fill(_P([Vector2(x, 24), Vector2(x + 4, 24), Vector2(x + 2, 31)]), Color.WHITE)
		_fill(_P([Vector2(x + 2, 38), Vector2(x + 6, 38), Vector2(x + 4, 32)]), Color.WHITE)


static func _mimic() -> void:
	var col := _c("col", Color("8a5a33"))
	var gold := _c("col2", GOLD)
	_ground(50)
	var lid := _smooth(_P([Vector2(-48, -10), Vector2(-44, -54), Vector2(40, -66), Vector2(50, -24)]), 1)
	_shape(lid, col.darkened(0.1), 0.8, 2.4)
	_fill(_P([Vector2(-44, -12), Vector2(48, -24), Vector2(46, 4), Vector2(-46, 6)]), Color("4a0e18"))
	_tube(_bez(Vector2(-10, 0), Vector2(30, -6), Vector2(36, 30), 10), 14, 6, Color("c0506a"))
	for k in 9:
		var x := -40.0 + k * 10
		_fill(_P([Vector2(x, -12 - k * 1.3), Vector2(x + 6, -13 - k * 1.3), Vector2(x + 3, -2 - k * 1.3)]), Color("f4f0e0"))
		_fill(_P([Vector2(x, 6), Vector2(x + 6, 6), Vector2(x + 3, -4)]), Color("f4f0e0"))
	var box := _P([Vector2(-50, 4), Vector2(50, 4), Vector2(48, 48), Vector2(-48, 48)])
	_shape(box, col, 1.0, 2.4)
	for x: float in [-30.0, 30.0]:
		_shape(_P([Vector2(x - 4, 4), Vector2(x + 4, 4), Vector2(x + 4, 48), Vector2(x - 4, 48)]), gold.darkened(0.15), 0.3, 1.4)
	for k in 3:
		_line(_P([Vector2(-48, 18 + k * 10), Vector2(48, 18 + k * 10)]), col.darkened(0.35), 1.2)
	_shape(_P([Vector2(-6, 6), Vector2(6, 6), Vector2(6, 18), Vector2(-6, 18)]), gold, 0.4, 1.4)
	_dot(Vector2(-22, -36), 5, Color("f1c40f"))
	_dot(Vector2(-22, -36), 2, INK)


static func _slime() -> void:
	var col := _c("col", Color("6ab04c"))
	var col2 := _c("col2", Color("badc58"))
	_ground(50)
	var pts := PackedVector2Array()
	for i in 30:
		var t := float(i) / 29.0
		pts.append(Vector2(lerpf(-62, 62, t), 48 - sin(t * PI) * 82 + sin(t * 18.0) * 3))
	_fill(pts, Color(col, 0.78))
	_stroke(pts, 2.2, col.darkened(0.5))
	_tube(_bez(Vector2(-10, 30), Vector2(-2, 10), Vector2(12, 22), 6), 6, 4, Color(BONE, 0.7), 0)
	_dot(Vector2(16, 28), 6, Color(BONE, 0.7))
	for i in 7:
		_arc(Vector2(-30 + _hash(i) * 60, -10 + _hash(i + 9) * 40), 2 + _hash(i + 3) * 4, 0, TAU, 10, _tint(Color(col2, 0.8)), 1.4, true)
	_fill(_ell(Vector2(-22, -14), 14, 8, -0.5), Color(1, 1, 1, 0.45))
	for s: float in [-1.0, 1.0]:
		_dot(Vector2(s * 12, 4), 4.5, INK)
		_dot(Vector2(s * 12 - 1, 3), 1.5, Color.WHITE)


static func _cube() -> void:
	var col := _c("col", Color("48c9b0"))
	_ground(56)
	var front := _P([Vector2(-48, -30), Vector2(30, -30), Vector2(30, 54), Vector2(-48, 54)])
	var top := _P([Vector2(-48, -30), Vector2(-24, -54), Vector2(54, -54), Vector2(30, -30)])
	var side := _P([Vector2(30, -30), Vector2(54, -54), Vector2(54, 30), Vector2(30, 54)])
	_tube(_P([Vector2(-26, 6), Vector2(4, 14)]), 5, 5, BONE)
	_shape(_ell(Vector2(-6, -8), 9, 9), BONE, 0.3, 1.4)
	_dot(Vector2(-9, -9), 2, INK)
	_dot(Vector2(-3, -9), 2, INK)
	_tube(_P([Vector2(10, 40), Vector2(20, 10)]), 4, 2, METAL)
	_fill(front, Color(col, 0.55))
	_fill(side, Color(col.darkened(0.2), 0.55))
	_fill(top, Color(col.lightened(0.2), 0.55))
	for p in [front, side, top]:
		_stroke(p, 1.8, col.darkened(0.45))
	_fill(_ell(Vector2(-30, -16), 10, 5, -0.4), Color(1, 1, 1, 0.4))


static func _treant() -> void:
	var col := _c("col", Color("5a4030"))
	var leaf := _c("col2", Color("4a7a3a"))
	_ground(70)
	for i in 7:
		var c := Vector2(-50 + i * 17, -64 + absf(i - 3) * 8)
		_shape(_ell(c, 24, 20), leaf.darkened(0.05 * (i % 3)), 0.8, 1.8)
	for s: float in [-1.0, 1.0]:
		_tube(_bez3(Vector2(s * 20, -10), Vector2(s * 50, -10), Vector2(s * 70, 10), Vector2(s * 78, 34)), 16, 5, col.darkened(0.1))
		for k in 3:
			_line(_P([Vector2(s * 78, 34), Vector2(s * (76 + k * 6 - 6), 46)]), col.darkened(0.3), 3)
	var trunk := _P([Vector2(-26, 70), Vector2(-24, -30), Vector2(-14, -50), Vector2(14, -50), Vector2(24, -30), Vector2(28, 70), Vector2(12, 62), Vector2(0, 70), Vector2(-12, 62)])
	_shape(trunk, col, 1.0, 2.4)
	for i in 5:
		_line(_bez(Vector2(-18 + i * 9, -40), Vector2(-14 + i * 9, 10), Vector2(-20 + i * 10, 62), 8), col.darkened(0.35), 1.6)
	for s: float in [-1.0, 1.0]:
		_fill(_ell(Vector2(s * 9, -18), 6, 4), Color("140f0c"))
		_glow(Vector2(s * 9, -18), 10, Color("f1c40f"), 3)
		_dot(Vector2(s * 9, -18), 2, Color("f7dc6f"))
	_fill(_ell(Vector2(0, 6), 9, 6), Color("140f0c"))
	for i in 4:
		_shape(_ell(Vector2(-40 + _hash(i) * 80, -80 + _hash(i + 5) * 30), 8, 6), leaf.lightened(0.15), 0.0, 1.0)


static func _wisp() -> void:
	var col := _c("col", Color("aed6f1"))
	var col2 := _c("col2", Color("5dade2"))
	_glow(Vector2(0, 0), 80, col2, 8)
	_glow(Vector2(0, 0), 44, col, 6)
	_dot(Vector2(0, 0), 16, col.lightened(0.5))
	_dot(Vector2(0, 0), 8, Color.WHITE)
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		_dot(Vector2(cos(a), sin(a)) * (34 + _hash(i) * 20), 2.5, Color(col, 0.8))


static func _elemental() -> void:
	var col := _c("col", Color("e67e22"))
	var col2 := _c("col2", Color("f7dc6f"))
	var kind := str(L.get("kind", "fire"))
	match kind:
		"fire":
			_glow(Vector2(0, -6), 96, col, 6)
			for i in 9:
				var x := -48.0 + i * 12
				_flame(Vector2(x, 70), 90 + sin(i * 1.3) * 30 - absf(x) * 0.6, 16, col.lerp(Color("c0392b"), 0.3), col2, sin(i * 2.1) * 0.2)
			_flame(Vector2(0, 40), 110, 30, col, col2)
			for s: float in [-1.0, 1.0]:
				_dot(Vector2(s * 12, -26), 6, Color.WHITE)
				_dot(Vector2(s * 12, -26), 3, Color("f1c40f"))
		"water":
			var body := _smooth(_P([Vector2(-50, 70), Vector2(-46, 10), Vector2(-26, -50), Vector2(0, -74), Vector2(26, -50), Vector2(46, 10), Vector2(50, 70)]), 2)
			_fill(body, Color(col, 0.75))
			_stroke(body, 2.2, col.darkened(0.4))
			for i in 6:
				_line(_bez(Vector2(-40 + i * 14, 60), Vector2(-30 + i * 14, 20 - i * 4), Vector2(-24 + i * 12, -30 + i * 6), 10), Color(col2, 0.8), 2.0)
			for s: float in [-1.0, 1.0]:
				_tube(_bez(Vector2(s * 40, 0), Vector2(s * 76, 6), Vector2(s * 70, 40), 8), 16, 8, Color(col, 0.8), 0)
				_dot(Vector2(s * 12, -36), 5, Color.WHITE)
		"earth":
			var rocks := [[Vector2(0, -44), 22], [Vector2(0, 0), 34], [Vector2(-50, -6), 18], [Vector2(50, -6), 18], [Vector2(-56, 30), 16], [Vector2(56, 30), 16], [Vector2(-18, 52), 18], [Vector2(18, 52), 18]]
			for r in rocks:
				var c: Vector2 = r[0]
				var rr: float = r[1]
				var pts := PackedVector2Array()
				for i in 7:
					var a := TAU * i / 7.0
					pts.append(c + Vector2(cos(a), sin(a)) * rr * (0.82 + _hash(i + c.x) * 0.3))
				_shape(pts, col, 1.0, 2.2)
			for s: float in [-1.0, 1.0]:
				_glow(Vector2(s * 9, -46), 10, Color("f39c12"), 3)
				_dot(Vector2(s * 9, -46), 3, Color("f7dc6f"))
			_line(_P([Vector2(-20, -6), Vector2(-6, 6), Vector2(-12, 20)]), Color("f39c12"), 2.0)
		_:
			for i in 5:
				var pts := PackedVector2Array()
				for k in 40:
					var a := k * 0.32 + i * 1.2
					var rr := 70.0 - k * 1.5
					pts.append(Vector2(cos(a) * rr, -10 + sin(a) * rr * 0.45 + (k - 20) * 2.6))
				_line(pts, Color(col.lerp(col2, i / 5.0), 0.7), 4.0 - i * 0.5)
			for s: float in [-1.0, 1.0]:
				_dot(Vector2(s * 12, -40), 5, Color("2e86c1"))


static func _centaur() -> void:
	var orig := L
	L = orig.duplicate()
	L["len"] = 1.0
	L["leg"] = 1.1
	L["tail"] = "horse"
	L["mane_col"] = orig.get("hair_color", Color("3b2a1a"))
	L["head"] = "equine"
	_tf(Vector2(-16, 22), 0.78)
	_quad(false)
	L = orig.duplicate()
	if str(L.get("item", "none")) == "none":
		L["item"] = "bow"
	if str(L.get("outfit", "clothes")) == "clothes":
		L["outfit"] = "leather"
	_tf(Vector2(26, -16), 0.6)
	_bust()
	L = orig
