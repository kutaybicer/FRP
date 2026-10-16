class_name DiceOverlay
extends Control
## Zar atma animasyonu: zarlar aşağıdan fırlar, dönerek zıplar, yerine oturur, sonra toplam gösterilir.
## Doğal 20 altın, doğal 1 kırmızı parlar. Birkaç saniye sonra kendiliğinden kaybolur (tıklayınca hemen).

const TUMBLE := 0.95
const STAGGER := 0.07
const HOLD := 3.6
const MAX_SHOWN := 12

var _dice: Array = []
var _result: Dictionary = {}
var _label := ""
var _t := 0.0
var _active := false
var _flicker := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_roll(result: Dictionary, label := "") -> void:
	_result = result
	_label = label
	_dice.clear()
	var list: Array = result.get("dice", [])
	var n := mini(list.size(), MAX_SHOWN)
	var r := clampf(size.y * 0.075, 26.0, 52.0)
	var gap := r * 2.4
	var start_x := size.x * 0.5 - gap * (n - 1) * 0.5
	for i in n:
		var d: Dictionary = list[i]
		_dice.append({
			"sides": d["sides"], "value": d["value"], "dropped": d.get("dropped", false),
			"from": Vector2(size.x * 0.5 + randf_range(-size.x * 0.3, size.x * 0.3), size.y + r * 2),
			"to": Vector2(start_x + i * gap, size.y * 0.42),
			"spin": randf_range(4.0, 9.0) * (1 if randf() < 0.5 else -1),
			"shown": randi_range(1, d["sides"]), "r": r, "delay": i * STAGGER,
		})
	_t = 0.0
	_active = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_flicker += delta
	if _flicker > 0.055:
		_flicker = 0.0
		for d in _dice:
			if _t - d["delay"] < TUMBLE:
				d["shown"] = randi_range(1, d["sides"])
	var end := TUMBLE + STAGGER * _dice.size() + HOLD
	if _t > end:
		_active = false
		visible = false
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_active = false
		visible = false


func _settled() -> bool:
	return _dice.is_empty() or _t > TUMBLE + STAGGER * (_dice.size() - 1)


func _draw() -> void:
	if not _active:
		return
	var settled := _settled()
	var fade := 1.0
	var end := TUMBLE + STAGGER * _dice.size() + HOLD
	if _t > end - 0.5:
		fade = clampf((end - _t) / 0.5, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35 * fade * minf(_t * 4.0, 1.0)))
	for d in _dice:
		var k := clampf((_t - d["delay"]) / TUMBLE, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		var p: Vector2 = d["from"].lerp(d["to"], e)
		p.y -= absf(sin(k * PI * 2.5)) * (1.0 - k) * d["r"] * 4.0
		var rot: float = d["spin"] * pow(1.0 - k, 2.0)
		var pop := 1.0 + 0.25 * maxf(0.0, 1.0 - absf(k - 0.98) * 12.0)
		var landed := k >= 1.0
		var txt := str(d["value"] if landed else d["shown"])
		var glow := Color(0, 0, 0, 0)
		if landed and d["sides"] == 20 and not d["dropped"]:
			if d["value"] == 20:
				glow = Color("ffd700")
			elif d["value"] == 1:
				glow = Color("ff3030")
		Dice.draw_die(self, d["sides"], p, d["r"] * pop, rot, txt, glow, landed and d["dropped"])
		if landed and d["dropped"]:
			draw_line(p + Vector2(-d["r"], -d["r"]) * 0.7, p + Vector2(d["r"], d["r"]) * 0.7, Color(1, 0.3, 0.3, 0.8), 3.0, true)
	if settled:
		_draw_total(fade)


func _draw_total(fade: float) -> void:
	var font: Font = Defs.font_title
	var total := str(_result.get("total", 0))
	var fs := int(clampf(size.y * 0.12, 48.0, 110.0))
	var w := font.get_string_size(total, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var y := size.y * 0.42 + clampf(size.y * 0.075, 26.0, 52.0) * 1.9 + fs * 0.8
	var col := Color("f2ead7")
	var nat := int(_result.get("nat", 0))
	var tag := ""
	if nat == 20:
		col = Color("ffd700")
		tag = "KRİTİK BAŞARI!"
	elif nat == 1:
		col = Color("ff5a4a")
		tag = "KRİTİK BAŞARISIZLIK!"
	var small: Font = Defs.font_text
	var lines := []
	if tag != "":
		lines.append(tag)
	if _label != "":
		lines.append(_label)
	var adv := int(_result.get("adv", 0))
	lines.append(str(_result.get("text", "")) + ("   (avantaj)" if adv > 0 else ("   (dezavantaj)" if adv < 0 else "")))
	var pw := maxf(w, 260.0)
	for l in lines:
		pw = maxf(pw, small.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x)
	var plate := Rect2(size.x * 0.5 - pw * 0.5 - 30, y - fs * 0.95, pw + 60, fs * 0.95 + 26 + lines.size() * 24 + 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.06, 0.88 * fade)
	sb.border_color = Color(col, fade)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	draw_style_box(sb, plate)
	draw_string(font, Vector2(size.x * 0.5 - w * 0.5 + 3, y + 4), total, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.6 * fade))
	draw_string(font, Vector2(size.x * 0.5 - w * 0.5, y), total, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col, fade))
	var ly := y + 26
	for l in lines:
		var lw := small.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(small, Vector2(size.x * 0.5 - lw * 0.5, ly), l, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(col if l == tag else Color("d8ccb0"), fade))
		ly += 24
