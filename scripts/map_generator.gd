class_name MapGenerator
extends RefCounted
## Rastgele arazi üretimi ve yeni alt haritalar için başlangıç içerikleri.

const T := Defs.T


## Gürültü tabanlı kıta / bölge üretir. island=true ise kenarlar denize döner.
static func generate_terrain(map: MapData, seed_value: int, island := true, add_rivers := true, add_symbols := true, add_settlements := true) -> void:
	var elev := FastNoiseLite.new()
	elev.seed = seed_value
	elev.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	elev.frequency = 2.6 / float(maxi(map.cols, map.rows))
	elev.fractal_octaves = 5
	var moist := FastNoiseLite.new()
	moist.seed = seed_value + 1337
	moist.frequency = 3.5 / float(maxi(map.cols, map.rows))
	moist.fractal_octaves = 3

	var heights := PackedFloat32Array()
	heights.resize(map.cols * map.rows)
	for r in map.rows:
		for c in map.cols:
			var e := elev.get_noise_2d(c, r) * 0.5 + 0.5
			if island:
				var nx := (float(c) / map.cols - 0.5) * 2.0
				var ny := (float(r) / map.rows - 0.5) * 2.0
				var d := Vector2(nx, ny).length() / 1.2
				e = e + 0.18 - pow(d, 2.2) * 0.62
			else:
				e = e * 0.8 + 0.2
			heights[r * map.cols + c] = e
			var m := moist.get_noise_2d(c, r) * 0.5 + 0.5
			map.terrain[r * map.cols + c] = _biome(e, m)
	map.region.fill(0)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	if add_rivers:
		_rivers(map, heights, rng)
	if add_settlements:
		_settlements(map, rng)
	if add_symbols:
		_nature_symbols(map, rng)


static func _biome(e: float, m: float) -> int:
	if e < 0.30: return T.DEEP
	if e < 0.40: return T.SEA
	if e < 0.44: return T.SHALLOW
	if e < 0.46: return T.SAND
	if e > 0.80: return T.SNOW
	if e > 0.70: return T.MOUNTAIN
	if e > 0.63: return T.HILLS
	if m < 0.30: return T.DESERT if e < 0.58 else T.PLAINS
	if m < 0.45: return T.PLAINS
	if m < 0.60: return T.GRASS
	if m < 0.72: return T.FOREST
	return T.SWAMP if e < 0.52 else T.FOREST


static func _rivers(map: MapData, heights: PackedFloat32Array, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	var flow := _flow_field(map, heights, rng)
	var sources: Array = []
	var max_rivers := clampi(W * H / 2500, 4, 28)
	var min_gap := clampf(maxf(W, H) / 8.0, 18.0, 45.0)
	for i in 400 + max_rivers * 60:
		var c := rng.randi_range(2, W - 3)
		var r := rng.randi_range(2, H - 3)
		var h := heights[r * W + c]
		if h > 0.64 and h < 0.8:
			var ok := true
			for s in sources:
				if s.distance_to(Vector2(c, r)) < min_gap:
					ok = false
					break
			if ok:
				sources.append(Vector2(c, r))
		if sources.size() >= max_rivers:
			break
	# yüksekten başlayanlar önce: kollar sonradan gelip ana nehre katılır
	sources.sort_custom(func(a, b): return heights[int(a.y) * W + int(a.x)] > heights[int(b.y) * W + int(b.x)])
	var occupied := PackedByteArray()
	occupied.resize(W * H)
	for s in sources:
		var cur := int(s.y) * W + int(s.x)
		if occupied[cur] == 1:
			continue
		var cells := PackedInt32Array()
		var ends := false
		for step in W * H:
			cells.append(cur)
			if Defs.water_lookup[map.terrain[cur]] == 1:
				ends = true
				break
			if occupied[cur] == 1:
				ends = true   # başka bir nehre katıldı
				break
			var nxt := flow[cur]
			if nxt < 0:
				ends = true   # harita kenarından akıp gidiyor
				break
			cur = nxt
		if not ends or cells.size() < 10:
			continue
		for k in cells:
			occupied[k] = 1
		# hücre merdivenini seyrelt, sonra yumuşat: akıcı kıvrımlar
		var pts := PackedVector2Array()
		for i in cells.size():
			if i % 3 == 0 or i == cells.size() - 1:
				var k := cells[i]
				pts.append((Vector2(k % W, k / W) + Vector2(0.5, 0.5)) * Defs.CELL)
		map.paths.append({"type": "river", "points": smooth(pts, 3), "name": Defs.random_name() + " Nehri", "width": 4.0})


## Priority-flood: her kara hücresi için suya (ya da harita kenarına) giden tek bir akış yönü.
## Sonuç bir ağaçtır: nehirler döngü yapmaz, kesişmez; buluşan kollar birleşir.
static func _flow_field(map: MapData, heights: PackedFloat32Array, rng: RandomNumberGenerator) -> PackedInt32Array:
	var W := map.cols
	var H := map.rows
	var n := W * H
	var flow := PackedInt32Array()
	flow.resize(n)
	flow.fill(-1)
	var done := PackedByteArray()
	done.resize(n)
	const LEVELS := 512
	var buckets: Array = []
	for i in LEVELS:
		buckets.append(PackedInt32Array())
	var lvl := func(h: float) -> int: return clampi(int(h * LEVELS), 0, LEVELS - 1)
	# tohumlar: tüm su hücreleri ve harita kenarı
	for r in H:
		for c in W:
			var k := r * W + c
			if Defs.water_lookup[map.terrain[k]] == 1 or c == 0 or r == 0 or c == W - 1 or r == H - 1:
				done[k] = 1
				buckets[lvl.call(heights[k])].append(k)
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	var cur_l := 0
	while cur_l < LEVELS:
		var b: PackedInt32Array = buckets[cur_l]
		if b.is_empty():
			cur_l += 1
			continue
		buckets[cur_l] = PackedInt32Array()
		var head := 0
		while head < b.size():
			var k := b[head]
			head += 1
			var c := k % W
			var r := k / W
			var order := dirs.duplicate()
			order.shuffle()   # düz alanlarda hafif doğal kıvrım
			for d: Vector2i in order:
				var nc := c + d.x
				var nr := r + d.y
				if nc < 0 or nr < 0 or nc >= W or nr >= H:
					continue
				var nk := nr * W + nc
				if done[nk] == 1:
					continue
				done[nk] = 1
				flow[nk] = k
				var nl := maxi(cur_l, lvl.call(heights[nk]))
				if nl == cur_l:
					b.append(nk)
				else:
					buckets[nl].append(nk)
	return flow


## Araziye uygun yerleşimler: başkent, şehirler, kasabalar, köyler, limanlar, kaleler.
## Sadece semboller konur; içleri boştur (tıklayınca "kendim çizeceğim / otomatik" seçilir).
static func _settlements(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	# nehir hücreleri (yakınında yerleşim olur)
	var river := PackedByteArray()
	river.resize(W * H)
	for p in map.paths:
		if p["type"] != "river":
			continue
		for pt: Vector2 in p["points"]:
			var c := int(pt.x / Defs.CELL)
			var r := int(pt.y / Defs.CELL)
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if map.in_bounds(c + dx, r + dy):
						river[(r + dy) * W + c + dx] = 1
	var land := 0
	for k in W * H:
		if Defs.water_lookup[map.terrain[k]] == 0:
			land += 1
	if land < 200:
		return
	var sea_near := func(c: int, r: int, rad: int) -> bool:
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				if map.in_bounds(c + dx, r + dy) and map.terrain[map.idx(c + dx, r + dy)] in [T.SEA, T.DEEP]:
					return true
		return false
	var score := func(c: int, r: int) -> float:
		var t := map.terrain[r * W + c]
		var s := 0.0
		match t:
			T.GRASS: s = 1.0
			T.PLAINS: s = 0.9
			T.FOREST: s = 0.45
			T.HILLS: s = 0.5
			T.DESERT: s = 0.25
			T.SAND: s = 0.2
			_: return -1.0
		if river[r * W + c] == 1:
			s += 0.6
		return s + rng.randf() * 0.35
	# aday hücreler
	var cands: Array = []
	for i in mini(land * 2, 30000):
		var c := rng.randi_range(2, W - 3)
		var r := rng.randi_range(2, H - 3)
		var sc: float = score.call(c, r)
		if sc > 0:
			cands.append([sc, c, r])
	cands.sort_custom(func(a, b): return a[0] > b[0])
	var placed: Array = []   # [Vector2 hücre, aralık]
	for s in map.symbols:
		if str(s["type"]) in Defs.SETTLEMENTS or str(s["type"]) in ["castle", "fort"]:
			placed.append([s["pos"] / Defs.CELL, 8.0])
	var kk := sqrt(land / 4000.0)
	var plan := [
		["capital", 1, 18.0, 1.5],
		["city", clampi(int(land / 5000.0), 1, 8), 16.0, 1.25],
		["port", clampi(int(land / 3500.0), 1, 10), 12.0, 1.1],
		["town", clampi(int(land / 2200.0), 2, 16), 11.0, 1.05],
		["castle", clampi(int(land / 6000.0), 1, 6), 12.0, 1.05],
		["fort", clampi(int(land / 7000.0), 0, 6), 10.0, 0.95],
		["village", clampi(int(land / 1000.0), 3, 40), 7.0, 0.85],
	]
	var center := Vector2(W, H) * 0.5
	for entry in plan:
		var type: String = entry[0]
		var count: int = entry[1]
		var gap: float = entry[2] * clampf(kk, 0.7, 1.6)
		var list := cands
		if type == "capital":
			# merkeze yakın, verimli bir yer
			list = cands.slice(0, maxi(cands.size() / 6, 1))
			list.sort_custom(func(a, b): return Vector2(a[1], a[2]).distance_to(center) < Vector2(b[1], b[2]).distance_to(center))
		elif type in ["castle", "fort"]:
			list = cands.filter(func(a): return map.terrain[a[2] * W + a[1]] in [T.HILLS, T.PLAINS, T.GRASS])
			list.shuffle()
		var n := 0
		for a in list:
			if n >= count:
				break
			var c: int = a[1]
			var r: int = a[2]
			var t := map.terrain[r * W + c]
			if type == "port":
				if not sea_near.call(c, r, 2):
					continue
			elif t == T.SAND or (type in ["capital", "city"] and t == T.DESERT):
				continue
			var p := Vector2(c + 0.5, r + 0.5)
			var ok := true
			for q in placed:
				if q[0].distance_to(p) < maxf(gap, q[1]) * 0.85:
					ok = false
					break
			if not ok:
				continue
			placed.append([p, gap])
			var nm := Defs.random_name()
			if type == "castle":
				nm += " Kalesi"
			elif type == "fort":
				nm += " Karakolu"
			map.symbols.append({"type": type, "pos": p * Defs.CELL, "name": nm, "notes": "", "size": entry[3], "link": ""})
			n += 1


static func _nature_symbols(map: MapData, rng: RandomNumberGenerator) -> void:
	var placed := {}
	# yerleşimlerin üstüne dağ / orman sembolü binmesin
	for s in map.symbols:
		var sp: Vector2 = s["pos"]
		var key0 := Vector2i(floori(sp.x / 128.0), floori(sp.y / 128.0))
		if not placed.has(key0):
			placed[key0] = []
		placed[key0].append(sp)
	for i in maxi(2500, map.cols * map.rows / 4):
		var c := rng.randi_range(1, map.cols - 2)
		var r := rng.randi_range(1, map.rows - 2)
		var t := map.terrain[map.idx(c, r)]
		var type := ""
		var min_d := 0.0
		# seyrek yerleşim: dağlık ve ormanlık alanlar sembolle dolup taşmasın
		if (t == T.MOUNTAIN or t == T.SNOW) and rng.randf() < 0.12:
			type = "mountain"
			min_d = 175.0
		elif t == T.HILLS and rng.randf() < 0.08:
			type = "hills"
			min_d = 110.0
		elif t == T.FOREST and rng.randf() < 0.06:
			type = "forest"
			min_d = 125.0
		if type == "":
			continue
		var pos := (Vector2(c, r) + Vector2(rng.randf(), rng.randf())) * Defs.CELL
		# yakındaki semboller için ızgara kovası (büyük haritalarda hızlı)
		var key := Vector2i(floori(pos.x / 128.0), floori(pos.y / 128.0))
		var ok := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for p in placed.get(key + Vector2i(dx, dy), []):
					if p.distance_to(pos) < min_d:
						ok = false
		if ok:
			if not placed.has(key):
				placed[key] = []
			placed[key].append(pos)
			var sz := rng.randf_range(1.1, 1.5) if type == "mountain" else 1.1
			map.symbols.append({"type": type, "pos": pos, "name": "", "notes": "", "size": sz, "link": ""})
	# üstteki semboller önde dursun diye y'ye göre sırala
	map.symbols.sort_custom(func(a, b): return a["pos"].y < b["pos"].y)


## Chaikin köşe yumuşatma
static func smooth(pts: PackedVector2Array, iterations := 2) -> PackedVector2Array:
	var p := pts
	for _i in iterations:
		if p.size() < 3:
			return p
		var out := PackedVector2Array()
		out.append(p[0])
		for i in p.size() - 1:
			out.append(p[i].lerp(p[i + 1], 0.25))
			out.append(p[i].lerp(p[i + 1], 0.75))
		out.append(p[p.size() - 1])
		p = out
	return p


static func _fill_rect(map: MapData, rect: Rect2i, t: int) -> void:
	for r in range(rect.position.y, rect.end.y):
		for c in range(rect.position.x, rect.end.x):
			if map.in_bounds(c, r):
				map.terrain[map.idx(c, r)] = t


static func _sym(map: MapData, type: String, cell: Vector2, sym_name := "", size := 1.0) -> Dictionary:
	var s := {"type": type, "pos": cell * Defs.CELL, "name": sym_name, "notes": "", "size": size, "link": ""}
	map.symbols.append(s)
	return s


## Yeni açılan alt haritaya boş kalmasın diye başlangıç düzeni koyar.
static func starter_content(map: MapData) -> void:
	var cx := map.cols / 2
	var cy := map.rows / 2
	match map.kind:
		Defs.Kind.WORLD:
			generate_terrain(map, randi(), true)
		Defs.Kind.REGION:
			generate_terrain(map, randi(), false)
		Defs.Kind.CITY:
			# ana caddeler
			_fill_rect(map, Rect2i(0, cy - 1, map.cols, 3), T.COBBLE)
			_fill_rect(map, Rect2i(cx - 1, 0, 3, map.rows), T.COBBLE)
			_fill_rect(map, Rect2i(cx - 5, cy - 4, 11, 9), T.COBBLE)
			# sur
			var radius := minf(map.cols, map.rows) * 0.42 * Defs.CELL
			var center := Vector2(cx + 0.5, cy + 0.5) * Defs.CELL
			var wall := PackedVector2Array()
			for i in 41:
				var a := TAU * i / 40.0
				wall.append(center + Vector2(cos(a), sin(a)) * radius)
			map.paths.append({"type": "wall", "points": wall, "name": "", "width": 7.0})
			_sym(map, "gate", (center + Vector2(radius, 0)) / Defs.CELL, "Doğu Kapısı")
			_sym(map, "gate", (center - Vector2(radius, 0)) / Defs.CELL, "Batı Kapısı")
			_sym(map, "gate", (center + Vector2(0, radius)) / Defs.CELL, "Güney Kapısı")
			_sym(map, "gate", (center - Vector2(0, radius)) / Defs.CELL, "Kuzey Kapısı")
			_sym(map, "market", Vector2(cx + 0.5, cy + 0.5), "Çarşı Meydanı", 1.3)
		Defs.Kind.DUNGEON:
			_fill_rect(map, Rect2i(cx - 5, cy - 4, 10, 8), T.STONE_FLOOR)
			_fill_rect(map, Rect2i(cx + 5, cy - 1, 12, 2), T.STONE_FLOOR)
			_sym(map, "stairs_up", Vector2(cx - 3, cy - 2), "Giriş")
		Defs.Kind.BUILDING:
			var room := Rect2i(cx - 12, cy - 8, 24, 16)
			_fill_rect(map, room, T.WALL)
			_fill_rect(map, room.grow(-1), T.WOOD_FLOOR)
			_sym(map, "door", Vector2(cx + 0.5, room.end.y - 0.5), "Giriş Kapısı")
