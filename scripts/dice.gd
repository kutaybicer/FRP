class_name Dice
extends RefCounted
## Zar ifadesi çözümleyici ve atıcı: "d20", "2d6+3", "1d8+1d6-1", "d%" (= d100), "4d6".
## adv: 1 = avantaj (2×d20, yüksek), -1 = dezavantaj (2×d20, düşük)

const TYPES := [4, 6, 8, 10, 12, 20, 100]
const COLORS := {4: Color("c0392b"), 6: Color("2e86c1"), 8: Color("27ae60"), 10: Color("8e44ad"),
		12: Color("d35400"), 20: Color("b7950b"), 100: Color("16a085")}


static func color_of(sides: int) -> Color:
	return COLORS.get(sides, Color("7f8c8d"))


static func roll_expr(expr: String, adv := 0) -> Dictionary:
	var s := expr.to_lower().replace(" ", "").replace("d%", "d100")
	if s == "":
		return {"ok": false}
	if not s.begins_with("+") and not s.begins_with("-"):
		s = "+" + s
	var re := RegEx.new()
	re.compile("([+-])(?:(\\d*)d(\\d+)|(\\d+))")
	var pos := 0
	var dice: Array = []
	var mod := 0
	var parts: Array = []
	var adv_used := false
	for m in re.search_all(s):
		if m.get_start() != pos:
			return {"ok": false}
		pos = m.get_end()
		var sg := -1 if m.get_string(1) == "-" else 1
		if m.get_string(3) != "":
			var count := 1 if m.get_string(2) == "" else m.get_string(2).to_int()
			var sides := m.get_string(3).to_int()
			if count < 1 or count > 100 or sides < 2 or sides > 1000:
				return {"ok": false}
			var vals := []
			if sides == 20 and count == 1 and adv != 0 and not adv_used:
				adv_used = true
				var a := randi_range(1, 20)
				var b := randi_range(1, 20)
				var keep := maxi(a, b) if adv > 0 else mini(a, b)
				var drop := b if keep == a else a
				dice.append({"sides": 20, "value": keep, "sign": sg, "dropped": false})
				dice.append({"sides": 20, "value": drop, "sign": sg, "dropped": true})
				vals = [keep]
				parts.append("%sd20(%d|%d)" % ["-" if sg < 0 else "+", a, b])
			else:
				for i in count:
					var v := randi_range(1, sides)
					vals.append(v)
					dice.append({"sides": sides, "value": v, "sign": sg, "dropped": false})
				var shown := ", ".join(PackedStringArray(vals.map(func(x): return str(x))))
				parts.append("%s%sd%d(%s)" % ["-" if sg < 0 else "+", "" if count == 1 else str(count), sides, shown])
		else:
			var n := m.get_string(4).to_int() * sg
			mod += n
			parts.append(("+%d" % n) if n >= 0 else str(n))
	if pos != s.length() or dice.is_empty() and parts.is_empty():
		return {"ok": false}
	var total := mod
	for d in dice:
		if not d["dropped"]:
			total += int(d["value"]) * int(d["sign"])
	var nat := 0
	for d in dice:
		if d["sides"] == 20 and not d["dropped"]:
			if d["value"] == 20:
				nat = 20
			elif d["value"] == 1:
				nat = 1
			break
	var txt := " ".join(PackedStringArray(parts)).replace(" +", " + ").replace(" -", " − ")
	if txt.begins_with("+"):
		txt = txt.substr(1)
	return {"ok": true, "total": total, "dice": dice, "mod": mod, "text": txt, "expr": expr, "nat": nat, "adv": adv}


## Zarın şekli (2B): d4 üçgen, d6 kare, d8 eşkenar dörtgen, d10/d100 uçurtma, d12 beşgen, d20 altıgen
static func shape(sides: int, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 6
	var rot := -PI / 2.0
	match sides:
		4:
			n = 3
		6:
			n = 4
			rot = -PI / 4.0
		8:
			n = 4
		10, 100:
			return PackedVector2Array([Vector2(0, -r), Vector2(r * 0.92, -r * 0.12), Vector2(0, r * 0.9), Vector2(-r * 0.92, -r * 0.12)])
		12:
			n = 5
		_:
			n = 6
			rot = 0.0
	for i in n:
		var a := rot + TAU * i / n
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


## Gölgeli, fasetli zar çizimi (ci üzerinde, merkez c, yarıçap r, dönme rot)
static func draw_die(ci: CanvasItem, sides: int, c: Vector2, r: float, rot: float, text: String, glow := Color(0, 0, 0, 0), dim := false) -> void:
	var col := color_of(sides)
	if dim:
		col = col.lerp(Color(0.3, 0.3, 0.3), 0.6)
	var pts := shape(sides, r)
	var xf := Transform2D(rot, c)
	var p2 := xf * pts
	if glow.a > 0:
		for i in 5:
			ci.draw_colored_polygon(Transform2D(rot, c) * _scaled(pts, 1.5 - i * 0.08), Color(glow, 0.08 + i * 0.05))
	ci.draw_colored_polygon(Transform2D(rot, c + Vector2(r * 0.08, r * 0.14)) * pts, Color(0, 0, 0, 0.35))
	ci.draw_colored_polygon(p2, col.darkened(0.35))
	ci.draw_colored_polygon(Transform2D(rot, c + Vector2(-r * 0.05, -r * 0.06)) * _scaled(pts, 0.86), col)
	ci.draw_colored_polygon(Transform2D(rot, c + Vector2(-r * 0.2, -r * 0.24)) * _scaled(pts, 0.42), Color(col.lightened(0.35), 0.55))
	# fasetler
	var inner := Transform2D(rot, c) * _scaled(pts, 0.55)
	for i in p2.size():
		ci.draw_line(p2[i], inner[i], Color(0, 0, 0, 0.25), maxf(1.0, r * 0.04), true)
	var closed := p2.duplicate()
	closed.append(p2[0])
	ci.draw_polyline(closed, Color("21180f"), maxf(1.5, r * 0.08), true)
	var ic := inner.duplicate()
	ic.append(inner[0])
	ci.draw_polyline(ic, Color(1, 1, 1, 0.18), maxf(1.0, r * 0.04), true)
	if text != "":
		var font: Font = Defs.font_title
		var fs := int(r * (0.78 if text.length() <= 2 else 0.56))
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := c + Vector2(-w * 0.5, fs * 0.36)
		if sides == 4:
			tp.y += r * 0.15
		ci.draw_string_outline(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(3, fs / 5), Color("21180f"))
		ci.draw_string(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


static func _scaled(pts: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := pts.duplicate()
	for i in out.size():
		out[i] *= k
	return out
