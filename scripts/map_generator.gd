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
	var sources: Array = []
	var max_rivers := clampi(map.cols * map.rows / 1500, 6, 40)
	for i in 400 + max_rivers * 60:
		var c := rng.randi_range(2, map.cols - 3)
		var r := rng.randi_range(2, map.rows - 3)
		if heights[r * map.cols + c] > 0.64 and heights[r * map.cols + c] < 0.8:
			var ok := true
			for s in sources:
				if s.distance_to(Vector2(c, r)) < 14:
					ok = false
					break
			if ok:
				sources.append(Vector2(c, r))
		if sources.size() >= max_rivers:
			break
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	for s in sources:
		var cur := Vector2i(s)
		var pts := PackedVector2Array()
		var visited := {}
		var reached_water := false
		for step in 400 + maxi(map.cols, map.rows):
			pts.append((Vector2(cur) + Vector2(0.5, 0.5)) * Defs.CELL)
			visited[cur] = true
			if Defs.water_lookup[map.terrain[map.idx(cur.x, cur.y)]] == 1:
				reached_water = true
				break
			var best := cur
			var best_h := INF
			for d in dirs:
				var n: Vector2i = cur + d
				if not map.in_bounds(n.x, n.y) or visited.has(n):
					continue
				# biraz rastgelelik nehirleri daha doğal kıvırır
				var h := heights[map.idx(n.x, n.y)] + rng.randf() * 0.012
				if h < best_h:
					best_h = h
					best = n
			if best == cur:
				break
			if best_h > heights[map.idx(cur.x, cur.y)] + 0.02:
				# çukura düştü: küçük bir göl oluştur
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if map.in_bounds(cur.x + dx, cur.y + dy):
							map.terrain[map.idx(cur.x + dx, cur.y + dy)] = T.SHALLOW
				reached_water = true
				break
			cur = best
		if reached_water and pts.size() > 6:
			map.paths.append({"type": "river", "points": smooth(pts, 2), "name": Defs.random_name() + " Nehri", "width": 4.0})


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
