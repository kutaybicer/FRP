class_name ItemPainter
extends RefCounted
## Eşya ikonları (portrelerle aynı gölgeli mürekkep stili). Tasarım kutusu -100..100.
## tint: ana malzeme rengini değiştirir (ör. elf kılıcı mavi çelik, iksir yeşil).

const W := 6.0
const STEEL := Color("c8d0d8")
const IRON := Color("8a929c")
const WOOD := Color("7a4a2a")
const LEATHER := Color("8a5a33")
const DARK_LEATHER := Color("4a2e1a")
const GOLD := Color("d9b44a")
const PAPER := Color("eadcb4")
const INK := Color("21180f")


static func draw(ci: CanvasItem, icon: String, center: Vector2, radius: float, tint = null, alpha := 1.0) -> void:
	PortraitPainter.begin(ci, center, radius)
	if alpha < 1.0:
		PortraitPainter._ghost = false
	var t: Color = tint if tint is Color else Color(0, 0, 0, 0)
	match icon:
		"longsword": _sword(t, Vector2(-30, 30), Vector2(72, -72), 9.0, 1.0)
		"shortsword": _sword(t, Vector2(-12, 12), Vector2(56, -56), 11.0, 0.85)
		"greatsword": _sword(t, Vector2(-38, 38), Vector2(84, -84), 12.0, 1.3)
		"dagger": _sword(t, Vector2(0, 0), Vector2(52, -52), 10.0, 0.7)
		"axe": _axe(t, false)
		"greataxe": _axe(t, true)
		"hammer": _hammer(t)
		"mace": _mace(t)
		"spear": _spear(t, false)
		"halberd": _spear(t, true)
		"scythe": _scythe(t)
		"whip": _whip(t)
		"bow": _bow(t)
		"crossbow": _crossbow(t)
		"sling": _sling(t)
		"staff": _staff(t)
		"wand": _wand(t)
		"orb": _orb(t)
		"shield": _shield(t)
		"helmet": _helmet(t)
		"shoulders": _shoulders(t)
		"chest": _chest(t)
		"gloves": _gloves(t)
		"legs": _legs(t)
		"boots": _boots(t)
		"potion": _potion(t)
		"scroll": _scroll(t)
		"book": _book(t)
		"ring": _ring(t)
		"amulet": _amulet(t)
		"gem": _gem(t)
		"pouch": _pouch(t)
		"key": _key(t)
		"food": _food(t)
		"torch": _torch(t)
		"rope": _rope(t)
		"arrows": _arrows(t)
		"tools": _tools(t)
		"instrument": _instrument(t)
		"map": _map(t)
		"rock": _rock(t)
		_: _custom(t)
	PortraitPainter.end()


# ------------------------------------------------------------- kısa yollar

static func _c(t: Color, def: Color) -> Color:
	return t if t.a > 0.0 else def


static func _S(pts: PackedVector2Array, col: Color, shade := 1.0) -> void:
	PortraitPainter._shape(pts, col, shade, W)


static func _T(path: PackedVector2Array, w0: float, w1: float, col: Color) -> void:
	PortraitPainter._tube(path, w0, w1, col, W * 0.8)


static func _L(pts: PackedVector2Array, col: Color, w := 4.0) -> void:
	PortraitPainter._line(pts, col, w)


static func _P(a: Array) -> PackedVector2Array:
	return PackedVector2Array(a)


static func _E(c: Vector2, rx: float, ry: float, rot := 0.0) -> PackedVector2Array:
	return PortraitPainter._ell(c, rx, ry, rot, 28)


static func _B(a: Vector2, b: Vector2, c: Vector2, n := 14) -> PackedVector2Array:
	return PortraitPainter._bez(a, b, c, n)


static func _glow(c: Vector2, r: float, col: Color) -> void:
	PortraitPainter._glow(c, r, col, 6)


static func _dot(c: Vector2, r: float, col: Color) -> void:
	PortraitPainter._dot(c, r, col)


# ------------------------------------------------------------- silahlar

static func _sword(t: Color, base: Vector2, tip: Vector2, w: float, k: float) -> void:
	var metal := _c(t, STEEL)
	var d := (tip - base).normalized()
	var o := d.orthogonal()
	var blade := _P([base + o * w, tip - d * w * 1.8 + o * w * 0.85, tip, tip - d * w * 1.8 - o * w * 0.85, base - o * w])
	_S(blade, metal, 0.8)
	_L(_P([base + d * 6, tip - d * w * 2.4]), metal.darkened(0.3), 3.0)
	_L(_P([base + d * 6 + o * 3, tip - d * w * 2.6 + o * 2]), Color(1, 1, 1, 0.6), 2.0)
	_T(_P([base + o * 24 * k, base - o * 24 * k]), 11 * k, 11 * k, GOLD)
	var grip_end := base - d * 32 * k
	_T(_P([base, grip_end]), 11 * k, 11 * k, DARK_LEATHER)
	for i in 3:
		var p := base.lerp(grip_end, 0.2 + i * 0.28)
		_L(_P([p + o * 5 * k, p - o * 5 * k]), LEATHER, 2.5)
	_S(_E(grip_end - d * 6 * k, 10 * k, 10 * k), GOLD, 0.6)


static func _haft(a: Vector2, b: Vector2, w := 12.0) -> void:
	_T(_P([a, b]), w, w * 0.85, WOOD)
	var d := (b - a).normalized()
	var o := d.orthogonal()
	for i in 3:
		var p := a.lerp(b, 0.12 + i * 0.06)
		_L(_P([p + o * w * 0.5, p - o * w * 0.5]), DARK_LEATHER, 3.0)


static func _axe(t: Color, double: bool) -> void:
	var a := Vector2(-58, 74)
	var b := Vector2(42, -62)
	_haft(a, b)
	var d := (b - a).normalized()
	var o := d.orthogonal()
	var c := b - d * 16
	var metal := _c(t, STEEL)
	var s := 1.35 if double else 1.0
	for side in ([1.0, -1.0] if double else [1.0]):
		var sg: float = side
		var blade := _P([c + o * 6 * sg + d * 16, c + o * 40 * s * sg + d * 34 * s, c + o * 54 * s * sg, c + o * 40 * s * sg - d * 34 * s, c + o * 6 * sg - d * 16])
		_S(PortraitPainter._smooth(blade, 1), metal, 1.0)
		_L(PortraitPainter._bez(c + o * 44 * s * sg + d * 26 * s, c + o * 52 * s * sg, c + o * 44 * s * sg - d * 26 * s, 8), Color(1, 1, 1, 0.55), 2.5)
	if not double:
		_S(_P([c - o * 6 + d * 8, c - o * 26, c - o * 6 - d * 8]), IRON, 0.6)
	_S(_E(c, 10, 10), IRON, 0.5)


static func _hammer(t: Color) -> void:
	var a := Vector2(-54, 70)
	var b := Vector2(36, -56)
	_haft(a, b)
	var d := (b - a).normalized()
	var o := d.orthogonal()
	var c := b - d * 6
	var metal := _c(t, IRON)
	var head := _P([c + o * 46 + d * 22, c + o * 46 - d * 22, c - o * 36 - d * 22, c - o * 36 + d * 22])
	_S(head, metal, 1.0)
	_S(_P([c + o * 46 + d * 26, c + o * 58 + d * 26, c + o * 58 - d * 26, c + o * 46 - d * 26]), metal.lightened(0.15), 0.6)
	_L(_P([c + o * 10 + d * 22, c + o * 10 - d * 22]), GOLD, 4.0)


static func _mace(t: Color) -> void:
	var a := Vector2(-50, 64)
	var b := Vector2(26, -36)
	_haft(a, b, 11)
	var c := b + (b - a).normalized() * 6
	var metal := _c(t, IRON)
	for i in 8:
		var ang := TAU * i / 8.0
		var dir := Vector2(cos(ang), sin(ang))
		_S(_P([c + dir * 18 + dir.orthogonal() * 10, c + dir * 46, c + dir * 18 - dir.orthogonal() * 10]), metal.darkened(0.05), 0.6)
	_S(_E(c, 28, 28), metal, 1.0)
	_dot(c + Vector2(-8, -8), 6, Color(1, 1, 1, 0.5))


static func _spear(t: Color, halberd: bool) -> void:
	var a := Vector2(-78, 78)
	var b := Vector2(54, -54)
	_T(_P([a, b]), 9, 8, WOOD)
	var d := (b - a).normalized()
	var o := d.orthogonal()
	var metal := _c(t, STEEL)
	_S(_P([b - d * 4 + o * 11, b + d * 34, b - d * 4 - o * 11, b - d * 18]), metal, 0.8)
	if halberd:
		var c := b - d * 22
		_S(PortraitPainter._smooth(_P([c + o * 4 + d * 12, c + o * 30 + d * 22, c + o * 40, c + o * 30 - d * 24, c + o * 4 - d * 14]), 1), metal, 1.0)
		_S(_P([c - o * 4 + d * 6, c - o * 24 - d * 6, c - o * 4 - d * 6]), metal.darkened(0.1), 0.5)
	else:
		_L(_P([b - d * 20 + o * 6, b - d * 30 + o * 12]), Color("b03a2e"), 4.0)
		_L(_P([b - d * 20 - o * 6, b - d * 32 - o * 10]), Color("b03a2e"), 4.0)


static func _scythe(t: Color) -> void:
	var a := Vector2(-40, 84)
	var b := Vector2(20, -64)
	_T(_P([a, b]), 10, 9, Color("3a2a1a"))
	var metal := _c(t, STEEL)
	var outer := _B(b, b + Vector2(-50, -32), b + Vector2(-96, 10), 14)
	var inner := _B(b + Vector2(-96, 10), b + Vector2(-52, -12), b + Vector2(0, 12), 14)
	_S(outer + inner, metal, 0.8)
	_T(_P([a.lerp(b, 0.55) + Vector2(-2, 0), a.lerp(b, 0.55) + Vector2(18, 4)]), 7, 6, WOOD)


static func _whip(t: Color) -> void:
	var col := _c(t, LEATHER)
	var path := PackedVector2Array()
	for i in 40:
		var k := float(i) / 39.0
		var ang := k * TAU * 1.4
		path.append(Vector2(-20 + cos(ang) * (44 - k * 26), 10 + sin(ang) * (34 - k * 18) - k * 20))
	_T(path, 9, 2, col)
	_T(_P([Vector2(20, 14), Vector2(62, 60)]), 13, 13, DARK_LEATHER)
	_S(_E(Vector2(66, 64), 8, 8), GOLD, 0.5)


static func _bow(t: Color) -> void:
	var col := _c(t, WOOD)
	var top := Vector2(-40, -84)
	var bot := Vector2(-40, 84)
	var limb := _B(top, Vector2(70, 0), bot, 24)
	_T(limb, 12, 12, col)
	_L(_P([top, bot]), Color("eee6d4"), 2.5)
	_T(_P([Vector2(14, -12), Vector2(16, 12)]), 15, 15, DARK_LEATHER)
	_L(_P([Vector2(-70, 6), Vector2(70, -4)]), Color("6b4a2a"), 4.0)
	_S(_P([Vector2(70, -4), Vector2(56, -11), Vector2(58, 4)]), STEEL, 0.4)
	_S(_P([Vector2(-70, 6), Vector2(-84, -6), Vector2(-76, 6), Vector2(-84, 16)]), Color("e8e0d0"), 0.4)


static func _crossbow(t: Color) -> void:
	var col := _c(t, WOOD)
	_T(_P([Vector2(-72, 56), Vector2(44, -30)]), 20, 14, col)
	var c := Vector2(30, -20)
	var d := Vector2(116, -86).normalized()
	var o := d.orthogonal()
	var prod := _B(c + o * 60 - d * 14, c + d * 30, c - o * 60 - d * 14, 16)
	_T(prod, 10, 10, IRON)
	_L(_P([prod[0], c - d * 6, prod[prod.size() - 1]]), Color("eee6d4"), 2.0)
	_L(_P([c - d * 40, c + d * 26]), Color("6b4a2a"), 4.0)
	_S(_P([Vector2(-40, 40), Vector2(-26, 54), Vector2(-34, 66)]), IRON, 0.4)


static func _sling(t: Color) -> void:
	var col := _c(t, LEATHER)
	_L(_B(Vector2(-60, -60), Vector2(-40, 20), Vector2(0, 40)), DARK_LEATHER, 4.0)
	_L(_B(Vector2(60, -60), Vector2(40, 20), Vector2(0, 40)), DARK_LEATHER, 4.0)
	_S(_E(Vector2(0, 42), 26, 16), col, 1.0)
	_S(_E(Vector2(0, 30), 12, 12), Color("8a8580"), 0.8)


static func _staff(t: Color) -> void:
	var a := Vector2(-64, 84)
	var b := Vector2(42, -48)
	_T(PortraitPainter._bez(a, Vector2(-6, 10), b, 10), 13, 11, WOOD)
	for i in 3:
		_S(_E(a.lerp(b, 0.25 + i * 0.25), 8, 6, -0.8), WOOD.darkened(0.2), 0.3)
	var c := b + Vector2(12, -18)
	var col := _c(t, Color("6fd3ff"))
	_glow(c, 46, col)
	_T(PortraitPainter._bez(b + Vector2(-14, 4), b + Vector2(-20, -24), c + Vector2(-4, -26), 8), 7, 3, WOOD.darkened(0.15))
	_T(PortraitPainter._bez(b + Vector2(10, 6), b + Vector2(30, -6), c + Vector2(18, -18), 8), 7, 3, WOOD.darkened(0.15))
	_S(_P([c + Vector2(0, -26), c + Vector2(15, 0), c + Vector2(0, 22), c + Vector2(-15, 0)]), col, 0.8)
	_L(_P([c + Vector2(0, -26), c + Vector2(0, 22)]), Color(1, 1, 1, 0.45), 2.0)


static func _wand(t: Color) -> void:
	var a := Vector2(-52, 52)
	var b := Vector2(38, -38)
	_T(_P([a, b]), 10, 6, Color("4a2e1a"))
	_T(_P([a, a.lerp(b, 0.3)]), 12, 11, GOLD)
	var col := _c(t, Color("f7dc6f"))
	_glow(b + Vector2(8, -8), 40, col)
	PortraitPainter._star(b + Vector2(8, -8), 20, col)
	PortraitPainter._star(b + Vector2(8, -8), 9, Color(1, 1, 1, 0.9))
	_dot(Vector2(56, 8), 4, col)
	_dot(Vector2(10, -66), 3, col)


static func _orb(t: Color) -> void:
	var col := _c(t, Color("a569bd"))
	_S(_P([Vector2(-34, 54), Vector2(34, 54), Vector2(24, 76), Vector2(-24, 76)]), GOLD, 0.6)
	_S(_P([Vector2(-20, 40), Vector2(20, 40), Vector2(30, 56), Vector2(-30, 56)]), GOLD.darkened(0.15), 0.5)
	_glow(Vector2(0, -8), 80, col)
	_S(_E(Vector2(0, -8), 46, 46), col, 1.0)
	_L(PortraitPainter._bez(Vector2(-26, -10), Vector2(0, -36), Vector2(26, -6), 10), Color(1, 1, 1, 0.5), 3.0)
	_dot(Vector2(-16, -26), 9, Color(1, 1, 1, 0.75))


static func _shield(t: Color) -> void:
	var col := _c(t, Color("8a2a2a"))
	var pts := PortraitPainter._smooth(_P([Vector2(-62, -70), Vector2(62, -70), Vector2(62, 0), Vector2(30, 56), Vector2(0, 80), Vector2(-30, 56), Vector2(-62, 0)]), 1)
	_S(pts, IRON, 1.0)
	var inner := PortraitPainter._xf(pts, Vector2(0, 0), 0.82, Vector2(0, -2))
	_S(inner, col, 1.0)
	_T(_P([Vector2(0, -60), Vector2(0, 70)]), 12, 8, GOLD)
	_T(_P([Vector2(-52, -14), Vector2(52, -14)]), 12, 12, GOLD)
	_S(_E(Vector2(0, -14), 14, 14), IRON, 0.8)


# ------------------------------------------------------------- zırhlar

static func _helmet(t: Color) -> void:
	var metal := _c(t, STEEL)
	var dome := PackedVector2Array()
	for i in 25:
		var a := lerpf(PI, TAU, i / 24.0)
		dome.append(Vector2(cos(a) * 62, 10 + sin(a) * 72))
	dome.append_array(_P([Vector2(62, 10), Vector2(58, 64), Vector2(30, 76), Vector2(24, 18), Vector2(-24, 18), Vector2(-30, 76), Vector2(-58, 64), Vector2(-62, 10)]))
	_S(dome, metal, 1.0)
	_S(_P([Vector2(-8, 8), Vector2(8, 8), Vector2(6, 54), Vector2(-6, 54)]), metal.darkened(0.1), 0.6)
	_T(_P([Vector2(-62, 6), Vector2(62, 6)]), 10, 10, metal.darkened(0.15))
	for x in [-48.0, -24.0, 24.0, 48.0]:
		_dot(Vector2(x, 6), 3.4, metal.lightened(0.4))
	_T(PortraitPainter._bez3(Vector2(0, -62), Vector2(16, -96), Vector2(56, -90), Vector2(70, -56)), 18, 6, Color("b03a2e"))
	_L(_P([Vector2(0, -60), Vector2(0, -4)]), metal.lightened(0.3), 3.0)


static func _shoulders(t: Color) -> void:
	var metal := _c(t, STEEL)
	for s in [-1.0, 1.0]:
		for k in 3:
			var c := Vector2(s * (38 + k * 6), -18 + k * 22)
			var plate := _B(c + Vector2(-s * 34, 10), c + Vector2(s * 4, -40), c + Vector2(s * 40, 14), 12)
			plate.append(c + Vector2(s * 36, 24))
			plate.append(c + Vector2(-s * 30, 18))
			_S(plate, metal.darkened(0.06 * k), 0.8)
		_dot(Vector2(s * 40, -34), 4, GOLD)
	_T(_P([Vector2(-30, -44), Vector2(30, -44)]), 8, 8, DARK_LEATHER)


static func _chest(t: Color) -> void:
	var metal := _c(t, STEEL)
	var body := PortraitPainter._smooth(_P([Vector2(-70, -62), Vector2(-30, -74), Vector2(0, -56), Vector2(30, -74), Vector2(70, -62),
			Vector2(58, -10), Vector2(46, 64), Vector2(0, 80), Vector2(-46, 64), Vector2(-58, -10)]), 1)
	_S(body, metal, 1.0)
	_L(_P([Vector2(0, -54), Vector2(0, 74)]), metal.lightened(0.35), 3.0)
	_L(PortraitPainter._bez(Vector2(-46, -6), Vector2(0, 14), Vector2(46, -6), 10), metal.darkened(0.3), 3.0)
	_T(_P([Vector2(-50, 50), Vector2(50, 50)]), 14, 14, DARK_LEATHER)
	_S(_P([Vector2(-10, 42), Vector2(10, 42), Vector2(10, 58), Vector2(-10, 58)]), GOLD, 0.4)
	for s in [-1.0, 1.0]:
		_S(_E(Vector2(s * 62, -58), 20, 14, s * 0.3), metal.lightened(0.08), 0.7)


static func _gloves(t: Color) -> void:
	var col := _c(t, LEATHER)
	var cuff := _P([Vector2(-40, 30), Vector2(30, 30), Vector2(40, 84), Vector2(-46, 84)])
	_S(cuff, col.darkened(0.15), 0.8)
	var palm := PortraitPainter._smooth(_P([Vector2(-40, 34), Vector2(-44, -20), Vector2(34, -24), Vector2(36, 34)]), 1)
	for i in 4:
		var x := -34.0 + i * 20.0
		_T(_P([Vector2(x, -10), Vector2(x - 2, -60 - (8 if i == 1 or i == 2 else 0))]), 17, 14, col)
	_T(PortraitPainter._bez(Vector2(28, 10), Vector2(54, -2), Vector2(62, -32), 8), 18, 14, col)
	_S(palm, col, 1.0)
	_L(_P([Vector2(-40, 30), Vector2(36, 30)]), GOLD, 4.0)


static func _legs(t: Color) -> void:
	var col := _c(t, STEEL)
	_T(_P([Vector2(-50, -60), Vector2(50, -60)]), 18, 18, DARK_LEATHER)
	for s in [-1.0, 1.0]:
		var hip := Vector2(s * 26, -52)
		var knee := Vector2(s * 30, 8)
		var ankle := Vector2(s * 28, 72)
		_T(_P([hip, knee, ankle]), 40, 28, col)
		_S(_E(knee, 18, 14), col.lightened(0.12), 0.8)
	_S(_P([Vector2(-8, -52), Vector2(8, -52), Vector2(6, -40), Vector2(-6, -40)]), GOLD, 0.4)


static func _boots(t: Color) -> void:
	var col := _c(t, LEATHER)
	for k in 2:
		var o := Vector2(-22 + k * 30, -6 + k * 10)
		var c := col.darkened(0.18 * (1 - k))
		var boot := _P([o + Vector2(-26, -64), o + Vector2(12, -64), o + Vector2(14, 20), o + Vector2(52, 34), o + Vector2(54, 56), o + Vector2(-28, 56)])
		_S(PortraitPainter._smooth(boot, 1), c, 1.0)
		_S(_P([o + Vector2(-30, -70), o + Vector2(16, -70), o + Vector2(14, -54), o + Vector2(-28, -54)]), c.darkened(0.25), 0.5)
		_T(_P([o + Vector2(-30, 56), o + Vector2(56, 56)]), 8, 8, DARK_LEATHER.darkened(0.3))
		for i in 3:
			_L(_P([o + Vector2(-20, -40 + i * 16), o + Vector2(6, -36 + i * 16)]), c.darkened(0.35), 2.5)


# ------------------------------------------------------------- diğer

static func _potion(t: Color) -> void:
	var liquid := _c(t, Color("d23c3c"))
	var body := _E(Vector2(0, 26), 50, 50)
	_S(body, Color(0.85, 0.92, 0.98, 0.55), 0.2)
	var fill := Geometry2D.intersect_polygons(body, _P([Vector2(-60, 14), Vector2(60, 4), Vector2(60, 90), Vector2(-60, 90)]))
	for p in fill:
		PortraitPainter._fill(p, liquid)
		PortraitPainter._fill(PortraitPainter._xf(p, Vector2(0, 40), 0.75, Vector2(-6, -4)), liquid.lightened(0.18))
	_S(_P([Vector2(-14, -40), Vector2(14, -40), Vector2(14, -20), Vector2(-14, -20)]), Color(0.85, 0.92, 0.98, 0.6), 0.2)
	_S(_P([Vector2(-17, -66), Vector2(17, -66), Vector2(14, -40), Vector2(-14, -40)]), Color("a07850"), 0.6)
	PortraitPainter._stroke(body, W)
	_L(PortraitPainter._bez(Vector2(-34, 6), Vector2(-40, 30), Vector2(-28, 54), 8), Color(1, 1, 1, 0.6), 5.0)
	for i in 3:
		_dot(Vector2(-8 + i * 12, 40 - i * 8), 3 + i, Color(1, 1, 1, 0.45))


static func _scroll(t: Color) -> void:
	var paper := _c(t, PAPER)
	_S(_P([Vector2(-46, -60), Vector2(46, -60), Vector2(46, 60), Vector2(-46, 60)]), paper, 0.6)
	for i in 6:
		_L(_P([Vector2(-32, -38 + i * 14), Vector2(32 - (i % 3) * 8, -38 + i * 14)]), Color(INK, 0.5), 2.5)
	for y in [-62.0, 62.0]:
		_T(_P([Vector2(-58, y), Vector2(58, y)]), 22, 22, paper.darkened(0.12))
		_S(_E(Vector2(-60, y), 6, 11), WOOD, 0.4)
		_S(_E(Vector2(60, y), 6, 11), WOOD, 0.4)
	_S(_E(Vector2(30, 40), 14, 14), Color("b03a2e"), 0.8)
	_T(_P([Vector2(30, 52), Vector2(24, 80)]), 7, 4, Color("b03a2e"))


static func _book(t: Color) -> void:
	var cover := _c(t, Color("6b2a3a"))
	_S(_P([Vector2(-50, -62), Vector2(56, -66), Vector2(60, 64), Vector2(-46, 68)]), PAPER.darkened(0.1), 0.4)
	_S(_P([Vector2(-58, -70), Vector2(48, -74), Vector2(52, 58), Vector2(-54, 62)]), cover, 1.0)
	_T(_P([Vector2(-50, -70), Vector2(-46, 60)]), 12, 12, cover.darkened(0.3))
	_S(_E(Vector2(4, -8), 22, 22), GOLD, 0.6)
	PortraitPainter._star(Vector2(4, -8), 13, cover.darkened(0.2))
	_S(_P([Vector2(46, -12), Vector2(62, -12), Vector2(62, 6), Vector2(46, 6)]), GOLD, 0.5)


static func _ring(t: Color) -> void:
	var metal := _c(t, GOLD)
	var outer := _E(Vector2(0, 14), 52, 46)
	var inner := _E(Vector2(0, 16), 36, 30)
	for p in Geometry2D.clip_polygons(outer, inner):
		if not Geometry2D.is_polygon_clockwise(p):
			_S(p, metal, 0.8)
	PortraitPainter._stroke(inner, W)
	_S(_P([Vector2(-18, -30), Vector2(18, -30), Vector2(12, -18), Vector2(-12, -18)]), metal.darkened(0.1), 0.5)
	_S(_P([Vector2(0, -66), Vector2(22, -46), Vector2(0, -28), Vector2(-22, -46)]), Color("2e86c1"), 1.0)
	_dot(Vector2(-6, -50), 4, Color(1, 1, 1, 0.8))


static func _amulet(t: Color) -> void:
	var gem := _c(t, Color("27ae60"))
	_L(PortraitPainter._bez(Vector2(-62, -76), Vector2(0, 20), Vector2(62, -76), 20), GOLD.darkened(0.2), 4.0)
	_S(_E(Vector2(0, 22), 34, 40), GOLD, 1.0)
	_S(_E(Vector2(0, 22), 22, 28), gem, 1.0)
	_dot(Vector2(-7, 10), 6, Color(1, 1, 1, 0.7))


static func _gem(t: Color) -> void:
	var col := _c(t, Color("c0392b"))
	var top := _P([Vector2(-44, -18), Vector2(-24, -48), Vector2(24, -48), Vector2(44, -18)])
	var bottom := _P([Vector2(-44, -18), Vector2(44, -18), Vector2(0, 62)])
	_glow(Vector2(0, 0), 70, col)
	_S(bottom, col, 0.8)
	_S(top, col.lightened(0.2), 0.6)
	_L(_P([Vector2(-24, -48), Vector2(-14, -18), Vector2(0, 62), Vector2(14, -18), Vector2(24, -48)]), col.darkened(0.35), 2.5)
	_L(_P([Vector2(-14, -18), Vector2(0, -48), Vector2(14, -18)]), col.darkened(0.35), 2.5)
	_dot(Vector2(-12, -34), 5, Color(1, 1, 1, 0.8))


static func _pouch(t: Color) -> void:
	var col := _c(t, LEATHER)
	var bag := PortraitPainter._smooth(_P([Vector2(-20, -36), Vector2(20, -36), Vector2(56, 10), Vector2(50, 66), Vector2(-50, 66), Vector2(-56, 10)]), 2)
	_S(bag, col, 1.0)
	_S(_P([Vector2(-26, -56), Vector2(26, -56), Vector2(18, -36), Vector2(-18, -36)]), col.darkened(0.1), 0.6)
	_T(_P([Vector2(-26, -38), Vector2(26, -38)]), 8, 8, Color("c8a050"))
	for p in [Vector2(-52, 70), Vector2(-30, 76), Vector2(54, 72)]:
		_S(_E(p, 14, 8), GOLD, 0.6)
	_S(_E(Vector2(0, 18), 14, 14), GOLD, 0.6)


static func _key(t: Color) -> void:
	var metal := _c(t, GOLD)
	var bow := _E(Vector2(-36, -36), 28, 28)
	_S(bow, metal, 0.8)
	PortraitPainter._fill(_E(Vector2(-36, -36), 13, 13), Color(0, 0, 0, 0.0))
	PortraitPainter._stroke(_E(Vector2(-36, -36), 13, 13), W)
	_T(_P([Vector2(-18, -18), Vector2(56, 56)]), 13, 13, metal)
	_S(_P([Vector2(40, 40), Vector2(52, 28), Vector2(64, 40), Vector2(52, 52)]), metal, 0.5)
	_S(_P([Vector2(26, 26), Vector2(36, 16), Vector2(46, 26), Vector2(36, 36)]), metal, 0.5)


static func _food(t: Color) -> void:
	var col := _c(t, Color("c8883a"))
	var loaf := _E(Vector2(-6, 14), 62, 38, -0.15)
	_S(loaf, col, 1.0)
	for i in 3:
		_L(_P([Vector2(-36 + i * 24, -6 + i * -2), Vector2(-24 + i * 24, 20 - i * 3)]), col.darkened(0.35), 4.0)
	_S(_E(Vector2(46, -40), 24, 24), Color("c0392b"), 1.0)
	_L(_P([Vector2(46, -62), Vector2(50, -76)]), WOOD, 4.0)
	_S(_E(Vector2(60, -74), 10, 5, -0.4), Color("27ae60"), 0.4)


static func _torch(t: Color) -> void:
	var flame := _c(t, Color("f39c12"))
	_T(_P([Vector2(-30, 84), Vector2(14, -20)]), 14, 16, WOOD)
	_S(_P([Vector2(0, -36), Vector2(30, -26), Vector2(20, 0), Vector2(-6, -8)]), Color("d8c8a0"), 0.6)
	_glow(Vector2(18, -54), 70, flame)
	PortraitPainter._flame(Vector2(14, -26), 70, 26, flame.lerp(Color("c0392b"), 0.3), Color("f7dc6f"), 0.1)


static func _rope(t: Color) -> void:
	var col := _c(t, Color("c8a870"))
	for i in 4:
		var r := 58.0 - i * 13.0
		var e := _E(Vector2(0, 10 + i * 3), r, r * 0.55)
		e.append(e[0])
		_L(e, col.darkened(0.45), 15.0)
		_L(e, col, 10.0)
	_T(PortraitPainter._bez(Vector2(40, 0), Vector2(70, -40), Vector2(40, -70), 10), 11, 11, col)


static func _arrows(t: Color) -> void:
	var col := _c(t, Color("6b4a2a"))
	for i in 3:
		var a := Vector2(-60 + i * 18, 60)
		var b := Vector2(44 + i * 10, -64 + i * 4)
		_L(_P([a, b]), col.darkened(0.3), 6.0)
		_L(_P([a, b]), col, 3.5)
		var d := (b - a).normalized()
		_S(_P([b + d * 18, b + d.orthogonal() * 8, b - d.orthogonal() * 8]), STEEL, 0.4)
		_S(_P([a + d * 4, a - d * 14 + d.orthogonal() * 10, a + d * 18]), Color("e8e0d0"), 0.3)
		_S(_P([a + d * 4, a - d * 14 - d.orthogonal() * 10, a + d * 18]), Color("c0392b"), 0.3)


static func _tools(t: Color) -> void:
	var metal := _c(t, IRON)
	_T(_P([Vector2(-60, 60), Vector2(40, -40)]), 9, 8, WOOD)
	_S(_P([Vector2(26, -60), Vector2(64, -22), Vector2(54, -12), Vector2(16, -50)]), metal, 0.8)
	_T(_P([Vector2(60, 60), Vector2(-30, -30)]), 8, 6, metal)
	_S(_P([Vector2(-30, -30), Vector2(-56, -40), Vector2(-40, -56)]), metal.lightened(0.1), 0.5)
	_S(_E(Vector2(64, 64), 10, 10), GOLD, 0.5)


static func _instrument(t: Color) -> void:
	var col := _c(t, Color("b8783a"))
	_T(_P([Vector2(10, -6), Vector2(62, -74)]), 14, 12, Color("5e3b1f"))
	_S(_E(Vector2(-14, 26), 46, 54, -0.6), col, 1.0)
	_S(_E(Vector2(-6, 14), 12, 12), INK, 0.0)
	for i in 4:
		_L(_P([Vector2(-34 + i * 4, 52 - i * 2), Vector2(58 + i * 3, -70 + i * 2)]), Color(1, 1, 1, 0.6), 1.5)
	_S(_P([Vector2(56, -84), Vector2(76, -78), Vector2(66, -62), Vector2(52, -70)]), Color("4a2e1a"), 0.4)


static func _map(t: Color) -> void:
	var paper := _c(t, PAPER)
	var panels := [[-64, -22], [-22, 20], [20, 62]]
	for i in 3:
		var x0: float = panels[i][0]
		var x1: float = panels[i][1]
		var dy := 6.0 if i % 2 == 1 else -6.0
		_S(_P([Vector2(x0, -54 + dy), Vector2(x1, -54 - dy), Vector2(x1, 58 - dy), Vector2(x0, 58 + dy)]), paper.darkened(0.06 * i), 0.4)
	_L(PortraitPainter._bez(Vector2(-50, 30), Vector2(-10, -40), Vector2(36, 14), 12), Color("b03a2e"), 3.0)
	_L(_P([Vector2(30, 4), Vector2(46, 22)]), Color("b03a2e"), 5.0)
	_L(_P([Vector2(46, 4), Vector2(30, 22)]), Color("b03a2e"), 5.0)


static func _rock(t: Color) -> void:
	var col := _c(t, Color("8a8580"))
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * i / 9.0
		pts.append(Vector2(cos(a) * (52 + 12 * sin(i * 2.3)), 10 + sin(a) * (40 + 8 * cos(i * 1.7))))
	_S(pts, col, 1.0)
	_L(_P([Vector2(-20, -10), Vector2(0, 6), Vector2(16, -4)]), col.darkened(0.35), 3.0)
	_dot(Vector2(24, 26), 4, col.darkened(0.3))


static func _custom(t: Color) -> void:
	var col := _c(t, Color("b8a080"))
	var bundle := PortraitPainter._smooth(_P([Vector2(-58, 0), Vector2(-40, -44), Vector2(0, -30), Vector2(40, -44), Vector2(58, 0), Vector2(40, 60), Vector2(-40, 60)]), 2)
	_S(bundle, col, 1.0)
	_T(_P([Vector2(-20, -40), Vector2(20, -40)]), 9, 9, Color("6b4a2a"))
	var font := Defs.font_title
	var ci := PortraitPainter._ci
	ci.draw_string(font, Vector2(-17, 40), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 76, INK)
