class_name MapGenerator
extends RefCounted
## Rastgele arazi üretimi ve yeni alt haritalar için başlangıç içerikleri.

const T := Defs.T


## Gürültü tabanlı kıta / bölge üretir. island=true ise kenarlar denize döner.
static func generate_terrain(map: MapData, seed_value: int, island := true, add_rivers := true, add_symbols := true) -> void:
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


static func _nature_symbols(map: MapData, rng: RandomNumberGenerator) -> void:
	var placed := {}
	for i in maxi(2500, map.cols * map.rows / 4):
		var c := rng.randi_range(1, map.cols - 2)
		var r := rng.randi_range(1, map.rows - 2)
		var t := map.terrain[map.idx(c, r)]
		var type := ""
		var min_d := 0.0
		# seyrek yerleşim: dağlık ve ormanlık alanlar sembolle dolup taşmasın
		if (t == T.MOUNTAIN or t == T.SNOW) and rng.randf() < 0.45:
			type = "mountain"
			min_d = 80.0
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
