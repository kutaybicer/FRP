class_name SymbolPainter
extends RefCounted
## Tüm semboller kodla çizilir (harici resim gerekmez).
## Her sembol -16..16 kutusunda tasarlanır, draw_set_transform ile ölçeklenir.

const INK := Color("2b2118")
const STONE := Color("d4cab2")
const STONE_D := Color("a99f88")
const ROOF := Color("a8432f")
const WOOD := Color("8a5a33")
const WOOD_D := Color("5e3b1f")
const GOLD := Color("e8b923")
const GREEN := Color("3f7d3a")
const GREEN_L := Color("5f9e4a")
const ROCK := Color("8a7d6b")
const ROCK_D := Color("62584b")
const SNOW := Color("f4f6f8")
const BLACK := Color("1a1512")
const WATER := Color("4a86c0")
const PAPER := Color(0.96, 0.92, 0.8, 0.9)
const RED := Color("b03a2e")


static func draw_symbol(ci: CanvasItem, type: String, pos: Vector2, radius: float) -> void:
	ci.draw_set_transform(pos, 0.0, Vector2.ONE * (radius / 16.0))
	match type:
		"capital": _capital(ci)
		"city": _city(ci)
		"town": _town(ci)
		"village": _house(ci, -7, 8, 14, 9, STONE, ROOF)
		"castle": _castle(ci)
		"fort": _fort(ci)
		"port": _port(ci)
		"camp": _camp(ci)
		"mountain": _mountain(ci)
		"hills": _hills(ci)
		"volcano": _volcano(ci)
		"forest": _forest(ci)
		"pine": _pine(ci)
		"tree": _tree(ci, Vector2(0, 2), 9.0)
		"dungeon": _dungeon(ci)
		"cave": _cave(ci)
		"ruins": _ruins(ci)
		"tower": _tower_icon(ci)
		"temple": _temple(ci)
		"shrine": _shrine(ci)
		"portal": _portal(ci)
		"battle": _battle(ci)
		"treasure", "chest": _chest(ci)
		"danger": _skull(ci)
		"bridge": _bridge(ci)
		"house": _house(ci, -9, 10, 18, 12, STONE, ROOF)
		"noble": _noble(ci)
		"tavern": _tavern(ci)
		"inn": _inn(ci)
		"shop": _shop(ci)
		"blacksmith": _anvil(ci)
		"market": _market(ci)
		"gate": _gate(ci)
		"well": _well(ci)
		"guard": _shield(ci)
		"statue": _statue(ci)
		"door": _door(ci)
		"stairs_up": _stairs(ci, true)
		"stairs_down": _stairs(ci, false)
		"trap": _trap(ci)
		"altar": _altar(ci)
		"pillar": _pillar(ci)
		"npc": _person(ci, Color("3b6ea5"))
		"monster": _monster(ci)
		_: _pin(ci)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- yardımcılar

static func _poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, w := 1.5) -> void:
	ci.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, INK, w, true)


static func _rect(ci: CanvasItem, r: Rect2, fill: Color, w := 1.5) -> void:
	ci.draw_rect(r, fill, true)
	ci.draw_rect(r, INK, false, w)


static func _disc(ci: CanvasItem, c: Vector2, r: float, fill: Color, w := 1.5) -> void:
	ci.draw_circle(c, r, fill)
	ci.draw_arc(c, r, 0.0, TAU, 28, INK, w, true)


static func _ellipse_pts(c: Vector2, rx: float, ry: float, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _star(ci: CanvasItem, c: Vector2, ro: float, ri: float, fill: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var r := ro if i % 2 == 0 else ri
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_poly(ci, pts, fill, 1.0)


static func _house(ci: CanvasItem, x: float, y: float, w: float, h: float, wall: Color, roof: Color) -> void:
	_rect(ci, Rect2(x, y - h, w, h), wall)
	_poly(ci, PackedVector2Array([Vector2(x - 2, y - h), Vector2(x + w / 2.0, y - h - h * 0.75), Vector2(x + w + 2, y - h)]), roof)
	ci.draw_rect(Rect2(x + w / 2.0 - 1.5, y - 5, 3, 5), INK)


static func _tower(ci: CanvasItem, x: float, y: float, w: float, h: float, wall: Color) -> void:
	_rect(ci, Rect2(x, y - h, w, h), wall)
	var mw := w / 5.0
	for i in 3:
		_rect(ci, Rect2(x + i * 2 * mw, y - h - 3, mw, 3), wall, 1.0)


static func _mound(ci: CanvasItem, cx: float, base: float, w: float, h: float, fill: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		pts.append(Vector2(cx - w / 2.0 + w * t, base - sin(t * PI) * h))
	_poly(ci, pts, fill)


static func _tree(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_line(c + Vector2(0, r * 0.4), c + Vector2(0, r * 1.3), WOOD_D, 2.5)
	_disc(ci, c, r, GREEN)
	ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, GREEN_L)


static func _bg(ci: CanvasItem) -> void:
	ci.draw_circle(Vector2.ZERO, 16, PAPER)
	ci.draw_arc(Vector2.ZERO, 16, 0, TAU, 32, INK, 1.2, true)


# ---------------------------------------------------------------- yerleşim

static func _capital(ci: CanvasItem) -> void:
	_bg(ci)
	_tower(ci, -12, 9, 6, 12, STONE)
	_tower(ci, 6, 9, 6, 12, STONE)
	_tower(ci, -4, 9, 8, 16, STONE)
	ci.draw_rect(Rect2(-1.5, 4, 3, 5), INK)
	_star(ci, Vector2(0, -12), 5, 2.2, GOLD)


static func _city(ci: CanvasItem) -> void:
	_house(ci, -6, 2, 12, 8, STONE, ROOF)
	_rect(ci, Rect2(-12, 1, 24, 9), STONE_D)
	_tower(ci, -14, 10, 6, 15, STONE)
	_tower(ci, 8, 10, 6, 15, STONE)
	ci.draw_rect(Rect2(-2, 5, 4, 5), INK)


static func _town(ci: CanvasItem) -> void:
	_house(ci, 1, 10, 11, 10, STONE, ROOF)
	_house(ci, -12, 10, 10, 8, STONE, Color("7a4a35"))


static func _castle(ci: CanvasItem) -> void:
	ci.draw_line(Vector2(0, -8), Vector2(0, -16), INK, 1.5)
	_poly(ci, PackedVector2Array([Vector2(0, -16), Vector2(8, -13.5), Vector2(0, -11)]), RED, 1.0)
	_tower(ci, -7, 10, 14, 15, STONE_D)
	_tower(ci, -14, 10, 7, 18, STONE)
	_tower(ci, 7, 10, 7, 18, STONE)
	var arch := _ellipse_pts(Vector2(0, 6), 3, 4, 16)
	ci.draw_colored_polygon(arch, INK)
	ci.draw_rect(Rect2(-3, 6, 6, 4), INK)


static func _fort(ci: CanvasItem) -> void:
	for i in 7:
		var x := -14.0 + i * 4.0
		_poly(ci, PackedVector2Array([Vector2(x, 10), Vector2(x, -3), Vector2(x + 2, -7), Vector2(x + 4, -3), Vector2(x + 4, 10)]), WOOD, 1.0)
	ci.draw_line(Vector2(-14, 2), Vector2(14, 2), WOOD_D, 1.5)


static func _port(ci: CanvasItem) -> void:
	ci.draw_circle(Vector2.ZERO, 16, Color(0.75, 0.86, 0.95, 0.9))
	ci.draw_arc(Vector2.ZERO, 16, 0, TAU, 32, INK, 1.2, true)
	ci.draw_arc(Vector2(0, -9), 3, 0, TAU, 16, INK, 2.0, true)
	ci.draw_line(Vector2(0, -6), Vector2(0, 11), INK, 2.2)
	ci.draw_line(Vector2(-6, -2), Vector2(6, -2), INK, 2.2)
	ci.draw_arc(Vector2(0, 1), 10, 0.35, PI - 0.35, 16, INK, 2.2, true)


static func _camp(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-13, 10), Vector2(0, -11), Vector2(13, 10)]), Color("d8c08f"))
	_poly(ci, PackedVector2Array([Vector2(-4, 10), Vector2(0, 0), Vector2(4, 10)]), WOOD_D, 1.0)
	ci.draw_line(Vector2(0, -11), Vector2(0, -15), INK, 1.5)


# ---------------------------------------------------------------- doğa

static func _mountain(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(0, 11), Vector2(8, -6), Vector2(16, 11)]), ROCK_D)
	_poly(ci, PackedVector2Array([Vector2(-15, 12), Vector2(-2, -13), Vector2(11, 12)]), ROCK)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-2, -13), Vector2(11, 12), Vector2(2, 12), Vector2(1, 0)]), ROCK_D)
	_poly(ci, PackedVector2Array([Vector2(-2, -13), Vector2(-6.5, -4.5), Vector2(-3.5, -6), Vector2(-1, -3.5), Vector2(1.8, -7.5)]), SNOW, 1.0)


static func _hills(ci: CanvasItem) -> void:
	_mound(ci, 5, 11, 20, 11, Color("8f7a50"))
	_mound(ci, -5, 12, 22, 14, Color("a08b5b"))


static func _volcano(ci: CanvasItem) -> void:
	ci.draw_circle(Vector2(-2, -12), 3.5, Color(0.5, 0.5, 0.5, 0.7))
	ci.draw_circle(Vector2(3, -15), 2.5, Color(0.5, 0.5, 0.5, 0.6))
	_poly(ci, PackedVector2Array([Vector2(-15, 12), Vector2(-4, -7), Vector2(4, -7), Vector2(15, 12)]), Color("5a4636"))
	_poly(ci, PackedVector2Array([Vector2(-4, -7), Vector2(4, -7), Vector2(2, -1), Vector2(0, 4), Vector2(-2, -2)]), Color("e0531f"), 1.0)


static func _forest(ci: CanvasItem) -> void:
	_tree(ci, Vector2(0, -4), 7)
	_tree(ci, Vector2(-7, 2), 7)
	_tree(ci, Vector2(7, 2), 7)


static func _pine(ci: CanvasItem) -> void:
	for x in [-7.0, 7.0, 0.0]:
		var y := 4.0 if x != 0.0 else 0.0
		ci.draw_line(Vector2(x, y + 6), Vector2(x, y + 10), WOOD_D, 2.0)
		_poly(ci, PackedVector2Array([Vector2(x - 6, y + 6), Vector2(x, y - 12), Vector2(x + 6, y + 6)]), Color("2f5d34"))


# ---------------------------------------------------------------- özel yerler

static func _dungeon(ci: CanvasItem) -> void:
	_mound(ci, 0, 12, 32, 22, ROCK)
	ci.draw_colored_polygon(_ellipse_pts(Vector2(0, 2), 6, 7, 20), BLACK)
	ci.draw_rect(Rect2(-6, 2, 12, 10), BLACK)
	for x in [-3.0, 0.0, 3.0]:
		ci.draw_line(Vector2(x, -4), Vector2(x, 12), Color("8a7a50"), 1.0)
	ci.draw_line(Vector2(-6, 6), Vector2(6, 6), Color("8a7a50"), 1.0)


static func _cave(ci: CanvasItem) -> void:
	_mound(ci, 0, 12, 32, 20, ROCK)
	var pts := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		pts.append(Vector2(-7 + 14 * t, 12 - sin(t * PI) * 12))
	ci.draw_colored_polygon(pts, BLACK)


static func _ruins(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-12, 10), Vector2(-12, -8), Vector2(-9, -11), Vector2(-7, -6), Vector2(-7, 10)]), STONE)
	_poly(ci, PackedVector2Array([Vector2(-3, 10), Vector2(-3, -2), Vector2(0, 0), Vector2(2, -3), Vector2(2, 10)]), STONE)
	_poly(ci, PackedVector2Array([Vector2(6, 10), Vector2(6, -12), Vector2(9, -9), Vector2(11, -13), Vector2(11, 10)]), STONE)
	_rect(ci, Rect2(-15, 10, 30, 3), STONE_D, 1.0)


static func _tower_icon(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-5, -6, 10, 18), STONE)
	_poly(ci, PackedVector2Array([Vector2(-8, -6), Vector2(0, -16), Vector2(8, -6)]), Color("4b5ea8"))
	ci.draw_rect(Rect2(-1.5, -2, 3, 4), INK)
	ci.draw_rect(Rect2(-2, 7, 4, 5), INK)


static func _temple(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-14, -5), Vector2(0, -14), Vector2(14, -5)]), STONE)
	_rect(ci, Rect2(-13, -5, 26, 3), STONE_D, 1.0)
	for i in 4:
		_rect(ci, Rect2(-11 + i * 6.5, -2, 3, 10), STONE, 1.0)
	_rect(ci, Rect2(-15, 8, 30, 4), STONE_D, 1.0)


static func _shrine(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-4, 10), Vector2(-3, -9), Vector2(0, -14), Vector2(3, -9), Vector2(4, 10)]), STONE)
	_rect(ci, Rect2(-8, 10, 16, 3), STONE_D, 1.0)
	ci.draw_circle(Vector2(0, -4), 1.8, GOLD)


static func _portal(ci: CanvasItem) -> void:
	_poly(ci, _ellipse_pts(Vector2.ZERO, 10, 15), Color("6a3fa0"))
	ci.draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 6, 10), Color("b98ef0"))
	ci.draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 2.5, 4.5), Color("f2e8ff"))


static func _battle(ci: CanvasItem) -> void:
	for s in [1.0, -1.0]:
		var a := Vector2(-11 * s, -11)
		var b := Vector2(9 * s, 9)
		ci.draw_line(a, b, INK, 4.5)
		ci.draw_line(a, b, Color("d9dde2"), 2.5)
		var dir := (b - a).normalized()
		var n := Vector2(-dir.y, dir.x)
		ci.draw_line(b - dir * 3 + n * 5, b - dir * 3 - n * 5, WOOD_D, 3.0)
		ci.draw_line(b, b + dir * 4, WOOD_D, 3.0)


static func _chest(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-12, -1, 24, 12), WOOD)
	var lid := PackedVector2Array([Vector2(-12, -1)])
	for i in 9:
		var t := float(i) / 8.0
		lid.append(Vector2(-12 + 24 * t, -1 - sin(t * PI) * 7))
	lid.append(Vector2(12, -1))
	_poly(ci, lid, WOOD_D)
	ci.draw_line(Vector2(-12, 3), Vector2(12, 3), GOLD, 2.0)
	_rect(ci, Rect2(-2.5, 0, 5, 6), GOLD, 1.0)


static func _skull(ci: CanvasItem) -> void:
	_disc(ci, Vector2(0, -3), 11, Color("ece4d0"))
	_rect(ci, Rect2(-6, 5, 12, 7), Color("ece4d0"))
	ci.draw_circle(Vector2(-4.5, -3), 3.2, BLACK)
	ci.draw_circle(Vector2(4.5, -3), 3.2, BLACK)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, 1), Vector2(-1.8, 4), Vector2(1.8, 4)]), BLACK)
	for x in [-3.0, 0.0, 3.0]:
		ci.draw_line(Vector2(x, 7), Vector2(x, 12), INK, 1.0)


static func _bridge(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(-16, 2, 32, 10), Color(WATER, 0.7))
	var arc := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		arc.append(Vector2(-15 + 30 * t, 2 - sin(t * PI) * 8))
	ci.draw_polyline(arc, INK, 6.0, true)
	ci.draw_polyline(arc, WOOD, 4.0, true)
	ci.draw_line(Vector2(-12, 4), Vector2(-12, 12), INK, 2.0)
	ci.draw_line(Vector2(12, 4), Vector2(12, 12), INK, 2.0)


static func _pin(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-6, -4), Vector2(0, 14), Vector2(6, -4)]), RED)
	_disc(ci, Vector2(0, -6), 8, RED)
	ci.draw_circle(Vector2(0, -6), 3, Color.WHITE)


# ---------------------------------------------------------------- şehir

static func _noble(ci: CanvasItem) -> void:
	_house(ci, -13, 11, 26, 13, Color("e6dcc2"), Color("3d5a8a"))
	for x in [-9.0, 6.0]:
		ci.draw_rect(Rect2(x, 1, 3, 4), INK)
	ci.draw_line(Vector2(0, -8), Vector2(0, -16), INK, 1.5)
	_poly(ci, PackedVector2Array([Vector2(0, -16), Vector2(7, -14), Vector2(0, -12)]), GOLD, 1.0)


static func _tavern(ci: CanvasItem) -> void:
	_house(ci, -12, 11, 18, 12, Color("c9a26b"), WOOD_D)
	ci.draw_line(Vector2(6, -6), Vector2(14, -6), INK, 1.5)
	_rect(ci, Rect2(8, -5, 6, 7), GOLD, 1.0)
	ci.draw_arc(Vector2(14, -1.5), 2, -PI / 2, PI / 2, 8, INK, 1.2)
	ci.draw_rect(Rect2(8, -6, 6, 2), Color.WHITE)


static func _inn(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-11, -6, 22, 18), Color("d8c3a0"))
	_poly(ci, PackedVector2Array([Vector2(-13, -6), Vector2(0, -15), Vector2(13, -6)]), ROOF)
	for y in [-3.0, 3.0]:
		for x in [-8.0, -2.0, 5.0]:
			ci.draw_rect(Rect2(x, y, 3, 3), Color("f5d76e"))
	ci.draw_rect(Rect2(-1.5, 8, 3, 4), INK)


static func _shop(ci: CanvasItem) -> void:
	_house(ci, -12, 11, 18, 12, STONE, Color("2f7a5a"))
	ci.draw_line(Vector2(6, -6), Vector2(14, -6), INK, 1.5)
	_disc(ci, Vector2(11, -1), 4, GOLD, 1.0)


static func _anvil(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-14, -6), Vector2(10, -6), Vector2(14, -3), Vector2(6, -1), Vector2(4, 4),
			Vector2(9, 9), Vector2(-9, 9), Vector2(-4, 4), Vector2(-6, -1), Vector2(-12, -3)]), Color("4a4e55"))
	ci.draw_line(Vector2(-6, -12), Vector2(4, -9), WOOD_D, 2.5)
	ci.draw_circle(Vector2(8, -13), 2, Color("ff9a3c"))


static func _market(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-12, 2, 24, 9), WOOD)
	ci.draw_line(Vector2(-12, -6), Vector2(-12, 2), INK, 1.5)
	ci.draw_line(Vector2(12, -6), Vector2(12, 2), INK, 1.5)
	for i in 4:
		var x := -14.0 + i * 7.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, -10), Vector2(x + 7, -10), Vector2(x + 7, -4), Vector2(x, -4)]),
				RED if i % 2 == 0 else Color("f2ead7"))
	ci.draw_rect(Rect2(-14, -10, 28, 6), INK, false, 1.2)
	for x in [-7.0, 0.0, 7.0]:
		ci.draw_circle(Vector2(x, 1), 2.2, Color("e07b39"))


static func _gate(ci: CanvasItem) -> void:
	_tower(ci, -15, 12, 8, 20, STONE)
	_tower(ci, 7, 12, 8, 20, STONE)
	_rect(ci, Rect2(-7, -4, 14, 16), STONE_D)
	ci.draw_colored_polygon(_ellipse_pts(Vector2(0, 3), 4.5, 5, 16), BLACK)
	ci.draw_rect(Rect2(-4.5, 3, 9, 9), BLACK)


static func _well(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-12, -6), Vector2(0, -14), Vector2(12, -6)]), ROOF)
	ci.draw_line(Vector2(-9, -6), Vector2(-9, 4), WOOD_D, 2.0)
	ci.draw_line(Vector2(9, -6), Vector2(9, 4), WOOD_D, 2.0)
	ci.draw_line(Vector2(0, -6), Vector2(0, 0), INK, 1.0)
	_rect(ci, Rect2(-11, 3, 22, 9), STONE)
	ci.draw_line(Vector2(-11, 7), Vector2(11, 7), STONE_D, 1.0)


static func _shield(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-11, -12), Vector2(11, -12), Vector2(11, 0), Vector2(0, 14), Vector2(-11, 0)]), Color("2e5c9e"))
	ci.draw_line(Vector2(0, -12), Vector2(0, 13), GOLD, 2.0)
	ci.draw_line(Vector2(-11, -3), Vector2(11, -3), GOLD, 2.0)


static func _statue(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-8, 6, 16, 7), STONE_D)
	_rect(ci, Rect2(-3.5, -6, 7, 12), STONE, 1.0)
	_disc(ci, Vector2(0, -10), 4, STONE, 1.0)
	ci.draw_line(Vector2(3.5, -4), Vector2(9, -12), INK, 1.5)


# ---------------------------------------------------------------- zindan / iç mekan

static func _door(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-9, -13, 18, 26), WOOD)
	for x in [-4.0, 0.0, 4.0]:
		ci.draw_line(Vector2(x, -13), Vector2(x, 13), WOOD_D, 1.0)
	ci.draw_circle(Vector2(5.5, 1), 1.6, GOLD)


static func _stairs(ci: CanvasItem, up: bool) -> void:
	_rect(ci, Rect2(-12, -12, 24, 24), STONE_D)
	for i in 5:
		ci.draw_line(Vector2(-12, -12 + i * 5.0), Vector2(12, -12 + i * 5.0), INK, 1.0)
	var tip := Vector2(0, -9) if up else Vector2(0, 9)
	var base := Vector2(0, 7) if up else Vector2(0, -7)
	var d := 4.0 if up else -4.0
	ci.draw_line(base, tip, Color.WHITE, 3.0)
	ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -2 if up else 2), tip + Vector2(-5, d), tip + Vector2(5, d)]), Color.WHITE)


static func _trap(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-13, 4, 26, 8), Color("3a332c"))
	for i in 5:
		var x := -12.0 + i * 5.0
		_poly(ci, PackedVector2Array([Vector2(x, 4), Vector2(x + 2, -8), Vector2(x + 4, 4)]), Color("c9ccd1"), 1.0)
	ci.draw_line(Vector2(-12, -14), Vector2(12, 14), Color(RED, 0.8), 2.0)
	ci.draw_line(Vector2(12, -14), Vector2(-12, 14), Color(RED, 0.8), 2.0)


static func _altar(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-13, -2, 26, 14), STONE)
	_rect(ci, Rect2(-15, -5, 30, 4), STONE_D, 1.0)
	for x in [-8.0, 8.0]:
		ci.draw_rect(Rect2(x - 1.5, -11, 3, 6), Color("f2ead7"))
		ci.draw_circle(Vector2(x, -13), 2, Color("ffb238"))


static func _pillar(ci: CanvasItem) -> void:
	_rect(ci, Rect2(-10, 9, 20, 4), STONE_D, 1.0)
	_rect(ci, Rect2(-10, -13, 20, 4), STONE_D, 1.0)
	_rect(ci, Rect2(-6, -9, 12, 18), STONE, 1.0)
	ci.draw_line(Vector2(-2, -9), Vector2(-2, 9), STONE_D, 1.0)
	ci.draw_line(Vector2(2, -9), Vector2(2, 9), STONE_D, 1.0)


static func _person(ci: CanvasItem, color: Color) -> void:
	_poly(ci, PackedVector2Array([Vector2(-10, 13), Vector2(-8, 0), Vector2(-3, -3), Vector2(3, -3), Vector2(8, 0), Vector2(10, 13)]), color)
	_disc(ci, Vector2(0, -9), 6, Color("f0c9a0"))


static func _monster(ci: CanvasItem) -> void:
	_poly(ci, PackedVector2Array([Vector2(-9, -6), Vector2(-14, -16), Vector2(-4, -10)]), Color("e8e0c8"), 1.0)
	_poly(ci, PackedVector2Array([Vector2(9, -6), Vector2(14, -16), Vector2(4, -10)]), Color("e8e0c8"), 1.0)
	_disc(ci, Vector2(0, 1), 12, Color("7a1f1f"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-8, -2), Vector2(-2, 0), Vector2(-7, 2)]), Color("ffd43b"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(8, -2), Vector2(2, 0), Vector2(7, 2)]), Color("ffd43b"))
	for x in [-5.0, -1.0, 3.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, 6), Vector2(x + 2, 10), Vector2(x + 4, 6)]), Color.WHITE)


## Masa modundaki oyuncu grubu jetonu
static func draw_party(ci: CanvasItem, pos: Vector2, radius: float) -> void:
	ci.draw_set_transform(pos, 0.0, Vector2.ONE * (radius / 16.0))
	ci.draw_circle(Vector2(0, 2), 15, Color(0, 0, 0, 0.35))
	_disc(ci, Vector2.ZERO, 14, Color("f2d16b"), 2.5)
	ci.draw_arc(Vector2.ZERO, 10.5, 0, TAU, 28, Color("8a6d1c"), 1.5, true)
	ci.draw_line(Vector2(-2, 8), Vector2(-2, -10), INK, 2.0)
	_poly(ci, PackedVector2Array([Vector2(-2, -10), Vector2(9, -6), Vector2(-2, -2)]), RED, 1.2)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
