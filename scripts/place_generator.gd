class_name PlaceGenerator
extends RefCounted
## Bir yerin İÇ haritasını mantıklı biçimde üretir.
## Şehir → sokaklar, meydan, çatılar, meyhaneler, dükkanlar, surlar.
## Meyhane → tezgâh, fıçılar, masalar, ocak.  Orman → açıklıklar, patika, dere, kamp.
## Her harita tek katmandır: içindeki semboller (bina hariç) yeni haritaya açılmaz.

const T := Defs.T
const C := 16.0   # Defs.CELL

const TAVERN_NAMES := ["Sarhoş Ejder", "Altın Kupa", "Kırık Kalkan", "Uyuyan Dev", "Paslı Çapa",
		"Gülen Domuz", "Yaşlı Kurt", "Kızıl Fener", "Köpüklü Testi", "Gümüş Nal", "Üç Fıçı",
		"Kara Kedi", "Dans Eden Ayı", "Yarım Ay", "Mavi Baykuş", "Tek Gözlü Korsan"]
const INN_NAMES := ["Yolcu Hanı", "Kervan Hanı", "Huzur Hanı", "Kuzey Yıldızı Hanı", "Taş Köprü Hanı",
		"Gezgin Konağı", "Son Durak Hanı", "Kral Yolu Hanı"]
const SHOP_NAMES := ["Baharatçı", "Kumaşçı", "Simyacı", "Fırın", "Kasap", "Okçu", "Zırhçı",
		"Eczacı", "Kitapçı", "Kuyumcu", "Tüccar", "Çömlekçi", "Terzi", "Deri Ustası", "Büyü Dükkanı"]
const TEMPLE_NAMES := ["Işık Tapınağı", "Ay Tapınağı", "Savaş Tanrısı Tapınağı", "Hasat Tapınağı",
		"Denizlerin Efendisi Tapınağı", "Ölüler Mabedi"]
const NOBLE_NAMES := ["Valinin Konağı", "Lord Konağı", "Tüccar Loncası", "Kontes Konağı", "Bilgeler Meclisi"]
const GUARD_NAMES := ["Muhafız Karakolu", "Kışla", "Nöbet Evi", "Zindan Kapısı Karakolu"]


## Sembol türüne göre iç harita boyutu ve ölçeği
static func size_for(type: String, kind: int) -> Dictionary:
	var d := {
		"capital": [120, 90, 5.0], "city": [100, 75, 5.0], "town": [80, 60, 4.0], "village": [60, 45, 4.0],
		"port": [90, 70, 5.0],
		"tavern": [34, 24, 1.5], "inn": [36, 28, 1.5], "house": [20, 16, 1.5], "shop": [22, 16, 1.5],
		"blacksmith": [24, 18, 1.5], "temple": [36, 28, 1.5], "noble": [40, 30, 1.5], "guard": [28, 20, 1.5],
		"castle": [50, 40, 2.0], "tower": [26, 26, 1.5], "fort": [40, 32, 2.0],
		"dungeon": [70, 50, 1.5], "cave": [70, 50, 1.5], "ruins": [60, 45, 1.5], "well": [44, 32, 1.5],
		"forest": [100, 70, 5.0], "pine": [100, 70, 5.0], "mountain": [100, 70, 10.0],
		"hills": [100, 70, 6.0], "volcano": [90, 70, 10.0],
	}
	if d.has(type):
		return {"cols": d[type][0], "rows": d[type][1], "scale": d[type][2]}
	var k: Dictionary = Defs.KIND_DEFAULTS[kind]
	return {"cols": k["cols"], "rows": k["rows"], "scale": k["scale"]}


## Kullanıcının kendisinin çizeceği boş harita: türüne uygun zemin + küçük bir başlangıç ipucu
static func blank(map: MapData, type: String) -> void:
	match map.kind:
		Defs.Kind.BUILDING:
			var room := Rect2i(2, 2, map.cols - 4, map.rows - 4)
			_room(map, room, T.STONE_FLOOR if type in ["temple", "castle", "tower", "fort", "guard", "blacksmith"] else T.WOOD_FLOOR)
			_door(map, Vector2i(map.cols / 2, room.end.y - 1), "Giriş")
		Defs.Kind.DUNGEON:
			_room(map, Rect2i(map.cols / 2 - 5, map.rows / 2 - 4, 10, 8), T.STONE_FLOOR)
			_sym(map, "stairs_up", Vector2(map.cols / 2 - 2.5, map.rows / 2 - 1.5), "Giriş")
		Defs.Kind.SITE:
			map.terrain.fill(T.FOREST if type in ["forest", "pine"] else (T.MOUNTAIN if type in ["mountain", "volcano"] else T.GRASS))


## Otomatik, türe uygun iç harita
static func generate(map: MapData, type: String, seed_value := -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	match type:
		"capital", "city", "town", "village", "port":
			_city(map, type, rng)
		"tavern": _tavern(map, rng)
		"inn": _inn(map, rng)
		"house": _house(map, rng)
		"shop": _shop(map, rng)
		"blacksmith": _smithy(map, rng)
		"temple": _temple(map, rng)
		"noble": _noble(map, rng)
		"guard": _guardhouse(map, rng)
		"castle": _castle(map, rng)
		"tower": _tower(map, rng)
		"fort": _fort(map, rng)
		"dungeon", "well": _dungeon(map, rng, type == "well")
		"cave": _cave(map, rng)
		"ruins": _ruins(map, rng)
		"forest", "pine": _forest(map, rng, type == "pine")
		"mountain": _mountain(map, rng)
		"hills": _hills(map, rng)
		"volcano": _volcano(map, rng)
		_:
			blank(map, type)
	map.symbols.sort_custom(func(a, b): return a["pos"].y < b["pos"].y)


# ======================================================================= yardımcılar

static func _fill(map: MapData, rect: Rect2i, t: int) -> void:
	for r in range(maxi(rect.position.y, 0), mini(rect.end.y, map.rows)):
		for c in range(maxi(rect.position.x, 0), mini(rect.end.x, map.cols)):
			map.terrain[r * map.cols + c] = t


static func _tget(map: MapData, c: int, r: int) -> int:
	if c < 0 or r < 0 or c >= map.cols or r >= map.rows:
		return -1
	return map.terrain[r * map.cols + c]


static func _tset(map: MapData, c: int, r: int, t: int) -> void:
	if c >= 0 and r >= 0 and c < map.cols and r < map.rows:
		map.terrain[r * map.cols + c] = t


## Duvarlı oda: kenarlar duvar, içi zemin
static func _room(map: MapData, rect: Rect2i, floor_t: int) -> void:
	_fill(map, rect, T.WALL)
	_fill(map, rect.grow(-1), floor_t)


## Duvarda kapı aç (zemin, komşu zeminden alınır) + kapı sembolü
static func _door(map: MapData, cell: Vector2i, door_name := "") -> void:
	var f := T.WOOD_FLOOR
	for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var t := _tget(map, cell.x + d.x, cell.y + d.y)
		if t in [T.WOOD_FLOOR, T.STONE_FLOOR, T.DIRT, T.COBBLE]:
			f = t
			break
	_tset(map, cell.x, cell.y, f)
	_sym(map, "door", Vector2(cell) + Vector2(0.5, 0.5), door_name, 0.7)


static func _sym(map: MapData, type: String, cell: Vector2, sym_name := "", size := 1.0) -> Dictionary:
	var s := {"type": type, "pos": cell * C, "name": sym_name, "notes": "", "size": size, "link": ""}
	map.symbols.append(s)
	return s


static func _label(map: MapData, text: String, cell: Vector2, size := 13) -> void:
	map.labels.append({"text": text, "pos": cell * C, "size": size, "color": Color("3b2a1a")})


static func _path(map: MapData, type: String, cells: Array, smooth := true) -> void:
	var pts := PackedVector2Array()
	for p in cells:
		pts.append(p * C)
	if smooth:
		pts = MapGenerator.smooth(pts, 2)
	map.paths.append({"type": type, "points": pts, "name": "", "width": Defs.path_types[type]["width"]})


## Masa + etrafında sandalyeler
static func _table_set(map: MapData, c: Vector2, rng: RandomNumberGenerator, chairs := 4, long := false) -> void:
	_sym(map, "table", c, "", 1.4 if long else 0.85)
	var dx := 2.4 if long else 1.5
	var spots := [Vector2(-dx, 0), Vector2(dx, 0), Vector2(0, -1.2), Vector2(0, 1.2)]
	if long:
		spots = [Vector2(-1.2, -1.3), Vector2(0, -1.3), Vector2(1.2, -1.3), Vector2(-1.2, 1.3), Vector2(0, 1.3), Vector2(1.2, 1.3), Vector2(-dx, 0), Vector2(dx, 0)]
	spots.shuffle()
	for i in mini(chairs, spots.size()):
		_sym(map, "chair", c + spots[i] + Vector2(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1)), "", 0.5)


## Basit oda içi yerleşim: dikdörtgenin iç kenarı boyunca eşyalar
static func _along_wall(map: MapData, rect: Rect2i, side: String, types: Array, size := 0.7) -> void:
	var inner := rect.grow(-1)
	var n := types.size()
	for i in n:
		var k := (i + 0.5) / n
		var p := Vector2.ZERO
		match side:
			"top": p = Vector2(inner.position.x + inner.size.x * k, inner.position.y + 0.8)
			"bottom": p = Vector2(inner.position.x + inner.size.x * k, inner.end.y - 0.8)
			"left": p = Vector2(inner.position.x + 0.8, inner.position.y + inner.size.y * k)
			"right": p = Vector2(inner.end.x - 0.8, inner.position.y + inner.size.y * k)
		_sym(map, types[i], p, "", size)


static func _center(r: Rect2i) -> Vector2:
	return Vector2(r.position) + Vector2(r.size) * 0.5


## Boş (VOID) hücrelerden zemine komşu olanları duvara çevirir
static func _walls_around(map: MapData, floors: Array) -> void:
	var out := map.terrain.duplicate()
	for r in map.rows:
		for c in map.cols:
			if map.terrain[r * map.cols + c] != T.VOID:
				continue
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if _tget(map, c + dx, r + dy) in floors:
						out[r * map.cols + c] = T.WALL
	map.terrain = out


# ======================================================================= şehir / kasaba / köy

static func _city(map: MapData, type: String, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	var village := type == "village"
	var port := type == "port"
	var walled := type in ["capital", "city", "town"]
	map.terrain.fill(T.GRASS)
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.06

	var cx := W / 2
	var cy := H / 2
	var shore := H
	if port:
		# güneyde deniz, kıyı dalgalı
		shore = int(H * 0.72)
		cy = int(H * 0.42)
		for c in W:
			var s := shore + int(noise.get_noise_1d(c * 0.7) * 3.0)
			for r in range(s, H):
				_tset(map, c, r, T.SHALLOW if r < s + 3 else (T.SEA if r < s + 9 else T.DEEP))
			_tset(map, c, s - 1, T.SAND)
			_tset(map, c, s - 2, T.SAND)
	var rx := W * (0.30 if village else (0.36 if type == "town" else 0.42))
	var ry := H * (0.30 if village else (0.36 if type == "town" else 0.40))
	if port:
		ry = minf(ry, (shore - 3 - cy) * 1.0)
		rx = W * 0.42
	var inside := func(c: float, r: float) -> bool:
		var e := pow((c - cx) / rx, 2) + pow((r - cy) / ry, 2)
		return e < 1.0 + noise.get_noise_2d(c, r) * (0.25 if village else 0.06)

	# --- tarlalar ve korular (sur dışı)
	if true:
		for i in (14 if village else 8):
			var fw := rng.randi_range(5, 11)
			var fh := rng.randi_range(4, 8)
			var fx := rng.randi_range(1, W - fw - 1)
			var fy := rng.randi_range(1, H - fh - 1)
			var ok := true
			for p in [Vector2(fx, fy), Vector2(fx + fw, fy), Vector2(fx, fy + fh), Vector2(fx + fw, fy + fh), Vector2(fx + fw / 2.0, fy + fh / 2.0)]:
				if inside.call(p.x, p.y) or _tget(map, int(p.x), int(p.y)) != T.GRASS:
					ok = false
			if ok:
				_fill(map, Rect2i(fx, fy, fw, fh), T.FIELD)

	# --- ana caddeler
	var street := T.DIRT if village else T.COBBLE
	var main_w := 1 if village else (3 if type == "capital" else 2)
	var road_end := shore - 2 if port else H
	_fill(map, Rect2i(0, cy - main_w / 2, W, main_w), street)
	_fill(map, Rect2i(cx - main_w / 2, 0, main_w, road_end), street)
	if port:
		# limana inen cadde + iskeleler
		for k in [-1, 1]:
			var px: int = cx + k * int(W * 0.18)
			_fill(map, Rect2i(px, cy, 2, shore - cy), street)
		for i in 4:
			var px := int(W * (0.15 + i * 0.23))
			_fill(map, Rect2i(px, shore - 2, 2, 9), T.WOOD_FLOOR)
			_sym(map, "poi", Vector2(px + 1, shore + 6), "İskele %d" % (i + 1), 0.7)
		_fill(map, Rect2i(int(W * 0.1), shore - 2, int(W * 0.8), 2), T.WOOD_FLOOR)
		_sym(map, "tower", Vector2(W - 6, shore - 4), "Deniz Feneri", 1.1)
	# yan sokaklar (sur içi)
	if not village:
		var gx := 11 if type == "capital" else 12
		var gy := 9
		var x := cx % gx
		while x < W:
			if absi(x - cx) > 3:
				var w := 1
				for r in H:
					if inside.call(x, r) and _tget(map, x, r) in [T.GRASS, T.FIELD]:
						_fill(map, Rect2i(x + rng.randi_range(0, 0), r, w, 1), street if rng.randf() < 0.85 else T.DIRT)
			x += gx + rng.randi_range(-1, 1)
		var y := cy % gy
		while y < H:
			if absi(y - cy) > 3:
				for c in W:
					if inside.call(c, y) and _tget(map, c, y) in [T.GRASS, T.FIELD]:
						_tset(map, c, y, street if rng.randf() < 0.85 else T.DIRT)
			y += gy + rng.randi_range(-1, 1)
	else:
		# köy: kıvrımlı toprak patikalar
		for i in 3:
			var a := rng.randf() * TAU
			var p := Vector2(cx, cy)
			for s in 40:
				a += rng.randf_range(-0.35, 0.35)
				p += Vector2(cos(a), sin(a))
				_tset(map, int(p.x), int(p.y), T.DIRT)

	# --- meydan
	var plaza := Rect2i(cx - (4 if village else 6), cy - (3 if village else 5), 9 if village else 13, 7 if village else 11)
	_fill(map, plaza, T.GRASS if village else T.COBBLE)
	if village:
		_fill(map, plaza.grow(-1), T.GRASS)

	# --- binalar (çatılar): sokağa yakın dikdörtgenler
	var buildings: Array = []
	var tries := W * H / (3 if village else 1)
	for i in tries:
		var bw := rng.randi_range(2, 4) if village else rng.randi_range(3, 6)
		var bh := rng.randi_range(2, 3) if village else rng.randi_range(2, 4)
		var bx := rng.randi_range(1, W - bw - 1)
		var by := rng.randi_range(1, H - bh - 1)
		var rect := Rect2i(bx, by, bw, bh)
		if not inside.call(bx + bw * 0.5, by + bh * 0.5):
			continue
		if village and rng.randf() < 0.7:
			continue
		if not _free_for_building(map, rect, village):
			continue
		if not _near(map, rect.grow(1 if not village else 2), [T.COBBLE, T.DIRT]):
			continue
		var roof := T.ROOF_RED if rng.randf() < (0.75 if village else 0.6) else T.ROOF_SLATE
		_fill(map, rect, roof)
		buildings.append(rect)
	# sur içinde kalan boşluklar: avlu / ara sokak
	if not village:
		for r in H:
			for c in W:
				if map.terrain[r * map.cols + c] == T.GRASS and inside.call(c, r) and noise.get_noise_2d(c * 2.0, r * 2.0) > -0.05:
					map.terrain[r * map.cols + c] = T.DIRT

	# --- surlar ve kapılar
	if walled:
		var pts := []
		for i in 73:
			var a := TAU * i / 72.0
			pts.append(Vector2(cx + 0.5 + cos(a) * (rx + 1.5), cy + 0.5 + sin(a) * (ry + 1.5)))
		_path(map, "wall", pts, false)
		for g in [Vector2(rx + 1.5, 0), Vector2(-rx - 1.5, 0), Vector2(0, ry + 1.5), Vector2(0, -ry - 1.5)]:
			var gp: Vector2 = Vector2(cx + 0.5, cy + 0.5) + g
			var nm := "Doğu Kapısı" if g.x > 0 else ("Batı Kapısı" if g.x < 0 else ("Güney Kapısı" if g.y > 0 else "Kuzey Kapısı"))
			_sym(map, "gate", gp, nm, 1.0)
		for i in 8:
			var a := TAU * (i + 0.5) / 8.0
			_sym(map, "tower", Vector2(cx + 0.5 + cos(a) * (rx + 1.5), cy + 0.5 + sin(a) * (ry + 1.5)), "", 0.7)

	# --- başkentte kale bölgesi (kuzeyde)
	if type == "capital":
		var kr := Rect2i(cx - 9, cy - int(ry * 0.85), 18, 12)
		_fill(map, kr.grow(1), T.COBBLE)
		_fill(map, kr, T.STONE_FLOOR)
		_fill(map, Rect2i(kr.position.x + 4, kr.position.y + 2, 10, 6), T.ROOF_SLATE)
		var kp := []
		for p in [kr.position, Vector2i(kr.end.x, kr.position.y), kr.end, Vector2i(kr.position.x, kr.end.y), kr.position]:
			kp.append(Vector2(p))
		_path(map, "wall", kp, false)
		_sym(map, "castle", _center(kr), "Kral Sarayı", 1.6)
		_fill(map, Rect2i(cx - 1, kr.end.y, 3, cy - kr.end.y), T.COBBLE)
		var keep: Array = []
		for b: Rect2i in buildings:
			if not b.intersects(kr.grow(1)):
				keep.append(b)
		buildings = keep

	# --- meydan: çarşı, kuyu, heykel
	if village:
		_sym(map, "well", _center(plaza), "Köy Kuyusu", 0.9)
		_sym(map, "tree", _center(plaza) + Vector2(-2.5, -1.5), "", 1.0)
	else:
		_sym(map, "market", _center(plaza) + Vector2(-2.5, 0), "Çarşı Meydanı", 1.3)
		_sym(map, "well", _center(plaza) + Vector2(3, -2), "Kuyu", 0.8)
		if type in ["capital", "city"]:
			_sym(map, "statue", _center(plaza) + Vector2(3, 2), "Kahraman Heykeli", 0.9)

	# --- özel binalar: türüne göre adet
	var plan: Dictionary = {
		"capital": {"temple": 2, "tavern": 3, "inn": 2, "shop": 5, "blacksmith": 2, "guard": 3, "noble": 3, "house": 4},
		"city": {"temple": 1, "tavern": 2, "inn": 2, "shop": 4, "blacksmith": 1, "guard": 2, "noble": 2, "house": 3},
		"town": {"temple": 1, "tavern": 1, "inn": 1, "shop": 2, "blacksmith": 1, "guard": 1, "house": 3},
		"village": {"temple": 1, "tavern": 1, "blacksmith": 1, "house": 4},
		"port": {"temple": 1, "tavern": 3, "inn": 1, "shop": 3, "blacksmith": 1, "guard": 1, "noble": 1, "house": 3},
	}[type]
	buildings.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.get_area() > b.get_area())
	var big: Array = buildings.slice(0, buildings.size() / 3)
	var rest: Array = buildings.slice(buildings.size() / 3)
	big.shuffle()
	rest.shuffle()
	var used_names := {}
	for bt in ["temple", "noble", "inn", "tavern", "guard", "blacksmith", "shop", "house"]:
		for i in int(plan.get(bt, 0)):
			var pool: Array = big if bt in ["temple", "noble", "inn"] else rest
			if pool.is_empty():
				pool = big if pool == rest else rest
			if pool.is_empty():
				break
			var rect: Rect2i = pool.pop_back()
			var nm := _building_name(bt, rng, used_names)
			var sz := clampf(sqrt(rect.get_area()) / 4.0, 0.75, 1.2)
			_sym(map, bt, _center(rect), nm, sz)

	# --- ağaçlar: dışarıda seyrek, bahçelerde birkaç
	var placed: Array = []
	for i in W * H / 18:
		var c := rng.randi_range(1, W - 2)
		var r := rng.randi_range(1, H - 2)
		if _tget(map, c, r) != T.GRASS:
			continue
		if not village and inside.call(c, r):
			continue
		var p := Vector2(c + rng.randf(), r + rng.randf())
		var ok := true
		for q: Vector2 in placed:
			if q.distance_to(p) < 3.5:
				ok = false
				break
		if ok and noise.get_noise_2d(c * 1.5 + 50, r * 1.5) > 0.0:
			placed.append(p)
			_sym(map, "tree", p, "", rng.randf_range(0.7, 1.0))


static func _free_for_building(map: MapData, rect: Rect2i, village: bool) -> bool:
	var g := rect.grow(1)
	for r in range(g.position.y, g.end.y):
		for c in range(g.position.x, g.end.x):
			var t := _tget(map, c, r)
			var edge := r < rect.position.y or r >= rect.end.y or c < rect.position.x or c >= rect.end.x
			if t in [T.ROOF_RED, T.ROOF_SLATE, -1]:
				return false
			if not edge and t != T.GRASS:
				return false
			if village and t == T.FIELD:
				return false
	return true


static func _near(map: MapData, rect: Rect2i, types: Array) -> bool:
	for r in range(rect.position.y, rect.end.y):
		for c in range(rect.position.x, rect.end.x):
			if _tget(map, c, r) in types:
				return true
	return false


static func _building_name(bt: String, rng: RandomNumberGenerator, used: Dictionary) -> String:
	var list: Array = []
	var fmt := "%s"
	match bt:
		"tavern":
			list = TAVERN_NAMES
			fmt = "%s Meyhanesi"
		"inn": list = INN_NAMES
		"shop": list = SHOP_NAMES
		"temple": list = TEMPLE_NAMES
		"noble": list = NOBLE_NAMES
		"guard": list = GUARD_NAMES
		"blacksmith": return ["Demirci", "Usta Demirci", "Örs ve Çekiç", "Kara Örs Demirhanesi"][rng.randi() % 4]
		_: return ""
	for i in 12:
		var n: String = fmt % list[rng.randi() % list.size()]
		if not used.has(n):
			used[n] = true
			return n
	return fmt % list[rng.randi() % list.size()]


# ======================================================================= bina içleri

static func _tavern(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	var outer := Rect2i(1, 1, W - 2, H - 2)
	_room(map, outer, T.WOOD_FLOOR)
	# mutfak (sağ üst) ve kiler (sol üst)
	var kitchen := Rect2i(W - 12, 1, 11, 9)
	_room(map, kitchen, T.STONE_FLOOR)
	_door(map, Vector2i(kitchen.position.x + 3, kitchen.end.y - 1))
	_label(map, "Mutfak", Vector2(kitchen.position.x + 5.5, 3.2))
	_sym(map, "fireplace", Vector2(kitchen.end.x - 3, 2.8), "Ocak", 0.9)
	_sym(map, "cauldron", Vector2(kitchen.end.x - 3, 5.5), "", 0.6)
	_sym(map, "table", Vector2(kitchen.position.x + 4, 5.5), "", 0.7)
	_sym(map, "barrel", Vector2(kitchen.position.x + 2, 2.8), "", 0.5)
	var cellar := Rect2i(1, 1, 9, 8)
	_room(map, cellar, T.WOOD_FLOOR)
	_door(map, Vector2i(cellar.end.x - 1, 5))
	_label(map, "Kiler", Vector2(5, 3.2))
	for i in 5:
		_sym(map, "barrel", Vector2(3 + (i % 3) * 2.0, 5 + (i / 3) * 2.0), "", 0.55)
	_sym(map, "crate", Vector2(8, 7), "", 0.5)
	# bar tezgâhı
	var bx0 := cellar.end.x + 2
	var bx1 := kitchen.position.x - 1
	var by := 6.0
	var n := int((bx1 - bx0) / 2.2)
	for i in n:
		_sym(map, "counter", Vector2(bx0 + 1.1 + i * 2.2, by), "", 0.75)
	_sym(map, "npc", Vector2((bx0 + bx1) * 0.5, 3.8), "Meyhaneci", 0.75)
	for i in maxi(n - 1, 1):
		_sym(map, "barrel", Vector2(bx0 + 1.5 + i * 2.4, 2.5), "", 0.5)
	for i in n:
		_sym(map, "chair", Vector2(bx0 + 1.1 + i * 2.2, by + 1.5), "", 0.45)
	# masalar
	var ty := 11.5
	while ty < H - 4:
		var tx := 5.5
		while tx < W - 5:
			if not (tx > W - 8 and ty > H - 7):
				_table_set(map, Vector2(tx + rng.randf_range(-0.4, 0.4), ty + rng.randf_range(-0.3, 0.3)), rng, rng.randi_range(2, 4))
			tx += 6.0
		ty += 4.5
	# şömine, merdiven, giriş
	_sym(map, "fireplace", Vector2(2.6, H * 0.62), "Şömine", 0.9)
	_sym(map, "rug", Vector2(5.2, H * 0.62), "", 0.8)
	_sym(map, "stairs_up", Vector2(W - 4, H - 4), "Üst Kat (Odalar)", 0.8)
	_sym(map, "banner", Vector2(W * 0.5, 9.5), "", 0.6)
	_door(map, Vector2i(W / 2, H - 2), "Giriş")
	for p in [Vector2(2.8, H - 3.2), Vector2(W - 7.5, H - 3.2)]:
		_sym(map, "plant", p, "", 0.5)
	for i in rng.randi_range(2, 4):
		_sym(map, "npc", Vector2(rng.randf_range(4, W - 6), rng.randf_range(12, H - 4)), "Müşteri", 0.6)


static func _inn(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	_room(map, Rect2i(1, 1, W - 2, H - 2), T.WOOD_FLOOR)
	# üstte konuk odaları
	var rooms := 4
	var rw := (W - 2) / rooms
	for i in rooms:
		var r := Rect2i(1 + i * rw, 1, rw + (1 if i < rooms - 1 else W - 2 - rw * rooms + 1), 10)
		_room(map, r, T.WOOD_FLOOR)
		_door(map, Vector2i(r.position.x + r.size.x / 2, r.end.y - 1))
		_label(map, "Oda %d" % (i + 1), Vector2(r.position.x + r.size.x * 0.5, 2.6), 11)
		_sym(map, "bed", Vector2(r.position.x + 2.2, 5.0), "", 0.7)
		if rng.randf() < 0.5:
			_sym(map, "bed", Vector2(r.position.x + 4.4, 5.0), "", 0.7)
		_sym(map, "chest", Vector2(r.end.x - 2.0, 3.0), "", 0.5)
		_sym(map, "chair", Vector2(r.end.x - 2.2, 6.6), "", 0.45)
	# lobi ve yemek salonu
	_sym(map, "counter", Vector2(W - 7, H - 7), "", 0.8)
	_sym(map, "counter", Vector2(W - 4.8, H - 7), "", 0.8)
	_sym(map, "npc", Vector2(W - 6, H - 9), "Hancı", 0.75)
	_sym(map, "bookshelf", Vector2(W - 6, 12.2), "Anahtarlar", 0.7)
	for i in 2:
		for j in 2:
			_table_set(map, Vector2(5.5 + i * 7.0, 14 + j * 5.0), rng, rng.randi_range(2, 4))
	_sym(map, "fireplace", Vector2(2.6, 15.5), "Şömine", 0.9)
	_sym(map, "rug", Vector2(W * 0.5 + 3, H - 5), "", 1.0)
	_sym(map, "stairs_up", Vector2(W - 3.5, 13.5), "Üst Kat", 0.8)
	_sym(map, "barrel", Vector2(2.7, H - 3.5), "", 0.5)
	_sym(map, "barrel", Vector2(4.2, H - 3.2), "", 0.5)
	_door(map, Vector2i(W / 2, H - 2), "Giriş")


static func _house(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	_room(map, Rect2i(1, 1, W - 2, H - 2), T.WOOD_FLOOR)
	var bed := Rect2i(W - 8, 1, 7, H - 2)
	_room(map, bed, T.WOOD_FLOOR)
	_door(map, Vector2i(bed.position.x, H / 2 + 2))
	_label(map, "Yatak Odası", Vector2(bed.position.x + 3.5, 2.8), 11)
	_sym(map, "bed", Vector2(bed.position.x + 3.5, 5.5), "", 0.8)
	_sym(map, "chest", Vector2(bed.position.x + 3.5, H - 3.5), "", 0.55)
	_sym(map, "rug", Vector2(bed.position.x + 3.5, 9.5), "", 0.6)
	_sym(map, "fireplace", Vector2(4.5, 2.6), "Ocak", 0.8)
	_sym(map, "cauldron", Vector2(4.5, 4.8), "", 0.5)
	_table_set(map, Vector2(6.5, H * 0.58), rng, 3)
	_sym(map, "barrel", Vector2(2.6, H - 3), "", 0.5)
	_sym(map, "bookshelf", Vector2(W - 11, 2.4), "", 0.55)
	_door(map, Vector2i(5, H - 2), "Giriş")


static func _shop(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	_room(map, Rect2i(1, 1, W - 2, H - 2), T.WOOD_FLOOR)
	var store := Rect2i(1, 1, W - 2, 6)
	_room(map, store, T.WOOD_FLOOR)
	_door(map, Vector2i(W - 4, store.end.y - 1))
	_label(map, "Depo", Vector2(4, 2.8), 11)
	for i in 6:
		_sym(map, "crate" if i % 2 == 0 else "barrel", Vector2(3 + i * 2.2, 4), "", 0.5)
	for i in 4:
		_sym(map, "counter", Vector2(5 + i * 2.2, 9.6), "", 0.75)
	_sym(map, "npc", Vector2(13, 7.4), "Dükkan Sahibi", 0.7)
	_sym(map, "chest", Vector2(4, 7.6), "", 0.5)
	_along_wall(map, Rect2i(1, 6, W - 2, H - 7), "left", ["bookshelf", "bookshelf"], 0.6)
	_along_wall(map, Rect2i(1, 6, W - 2, H - 7), "right", ["bookshelf", "crate", "bookshelf"], 0.6)
	_sym(map, "rug", Vector2(W * 0.5, H - 4), "", 0.6)
	_sym(map, "plant", Vector2(W - 4, H - 3.5), "", 0.5)
	_door(map, Vector2i(W / 2, H - 2), "Giriş")
	if rng.randf() < 0.5:
		_sym(map, "npc", Vector2(W * 0.5 + 2, H - 5), "Müşteri", 0.6)


static func _smithy(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	_room(map, Rect2i(1, 1, W - 2, H - 2), T.STONE_FLOOR)
	_sym(map, "fireplace", Vector2(W * 0.5, 2.8), "Ocak (Körük)", 1.2)
	_sym(map, "pillar", Vector2(W * 0.5, 6.5), "Örs", 0.55)
	_sym(map, "cauldron", Vector2(W * 0.5 + 3.5, 5.5), "Su Teknesi", 0.6)
	_sym(map, "npc", Vector2(W * 0.5 - 1.8, 7.5), "Demirci", 0.75)
	_along_wall(map, Rect2i(1, 1, W - 2, H - 2), "left", ["weapon_rack", "weapon_rack", "crate"], 0.7)
	_along_wall(map, Rect2i(1, 1, W - 2, H - 2), "right", ["crate", "barrel", "chest"], 0.6)
	for i in 3:
		_sym(map, "counter", Vector2(W * 0.5 - 2.2 + i * 2.2, H - 5.5), "", 0.75)
	_sym(map, "table", Vector2(5, H - 4), "", 0.7)
	_door(map, Vector2i(W / 2, H - 2), "Giriş")
	if rng.randf() < 0.6:
		_sym(map, "npc", Vector2(W * 0.5 + 3, 8), "Çırak", 0.6)


static func _temple(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	_room(map, Rect2i(1, 1, W - 2, H - 2), T.STONE_FLOOR)
	var left := Rect2i(1, 1, 8, 9)
	var right := Rect2i(W - 9, 1, 8, 9)
	_room(map, left, T.WOOD_FLOOR)
	_room(map, right, T.STONE_FLOOR)
	_door(map, Vector2i(left.end.x - 1, 7))
	_door(map, Vector2i(right.position.x, 7))
	_label(map, "Rahip Odası", Vector2(5, 2.8), 11)
	_sym(map, "bed", Vector2(3.5, 5.5), "", 0.65)
	_sym(map, "bookshelf", Vector2(6.5, 2.5), "", 0.55)
	_label(map, "Hazine", Vector2(W - 5, 2.8), 11)
	_sym(map, "chest", Vector2(W - 5, 5.5), "", 0.6)
	_sym(map, "chest", Vector2(W - 3, 5.5), "", 0.5)
	# sütunlar, sıralar, sunak
	for i in 5:
		var y := 6.0 + i * 4.0
		_sym(map, "pillar", Vector2(W * 0.5 - 6, y), "", 0.6)
		_sym(map, "pillar", Vector2(W * 0.5 + 6, y), "", 0.6)
	for i in 4:
		var y := 12.0 + i * 3.0
		_sym(map, "bench", Vector2(W * 0.5 - 3, y), "", 0.6)
		_sym(map, "bench", Vector2(W * 0.5 + 3, y), "", 0.6)
	for i in 6:
		_sym(map, "rug", Vector2(W * 0.5, 5.5 + i * 3.4), "", 0.55)
	_sym(map, "altar", Vector2(W * 0.5, 3.5), "Ana Sunak", 1.1)
	_sym(map, "npc", Vector2(W * 0.5 + 2.5, 6.5), "Başrahip", 0.7)
	_sym(map, "statue", Vector2(W * 0.5 - 4, 3.2), "", 0.7)
	_sym(map, "statue", Vector2(W * 0.5 + 4, 3.2), "", 0.7)
	for x in [3.0, W - 3.0]:
		for y in [13.0, 19.0]:
			_sym(map, "banner", Vector2(x, y), "", 0.6)
	_door(map, Vector2i(W / 2, H - 2), "Büyük Kapı")
	if rng.randf() < 0.5:
		_sym(map, "npc", Vector2(W * 0.5 - 3, 15.5), "Hacı", 0.55)


static func _noble(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	_room(map, Rect2i(1, 1, W - 2, H - 2), T.WOOD_FLOOR)
	var hall := Rect2i(W / 2 - 6, 1, 12, H - 2)
	var dining := Rect2i(1, 1, W / 2 - 5, H / 2)
	var library := Rect2i(1, H / 2, W / 2 - 5, H / 2 - 1)
	var bedroom := Rect2i(W / 2 + 5, 1, W / 2 - 6, H / 2)
	var kitchen := Rect2i(W / 2 + 5, H / 2, W / 2 - 6, H / 2 - 1)
	for r: Rect2i in [dining, library, bedroom, kitchen]:
		_room(map, r, T.WOOD_FLOOR)
	_fill(map, kitchen.grow(-1), T.STONE_FLOOR)
	_door(map, Vector2i(dining.end.x - 1, dining.end.y - 4))
	_door(map, Vector2i(library.end.x - 1, library.position.y + 4))
	_door(map, Vector2i(bedroom.position.x, bedroom.end.y - 4))
	_door(map, Vector2i(kitchen.position.x, kitchen.position.y + 4))
	# giriş salonu
	for i in 5:
		_sym(map, "rug", Vector2(W * 0.5, 7 + i * 4.5), "", 0.75)
	_sym(map, "stairs_up", Vector2(W * 0.5, 3), "Üst Kat", 0.9)
	for y in [8.0, 16.0]:
		_sym(map, "pillar", Vector2(hall.position.x + 2, y), "", 0.5)
		_sym(map, "pillar", Vector2(hall.end.x - 2, y), "", 0.5)
		_sym(map, "plant", Vector2(hall.position.x + 2, y + 3), "", 0.5)
	_sym(map, "npc", Vector2(W * 0.5 + 2, H - 5), "Uşak", 0.6)
	# yemek odası
	_label(map, "Yemek Salonu", Vector2(_center(dining).x, 2.8), 11)
	_table_set(map, _center(dining), rng, 8, true)
	_sym(map, "fireplace", Vector2(2.6, _center(dining).y), "", 0.8)
	# kütüphane
	_label(map, "Kütüphane", Vector2(_center(library).x, library.position.y + 1.8), 11)
	_along_wall(map, library, "bottom", ["bookshelf", "bookshelf", "bookshelf"], 0.7)
	_along_wall(map, library, "left", ["bookshelf", "bookshelf"], 0.7)
	_table_set(map, _center(library), rng, 2)
	# yatak odası
	_label(map, "Yatak Odası", Vector2(_center(bedroom).x, 2.8), 11)
	_sym(map, "bed", _center(bedroom) + Vector2(1.5, -1), "", 1.0)
	_sym(map, "rug", _center(bedroom) + Vector2(1.5, 2.5), "", 0.8)
	_sym(map, "chest", Vector2(bedroom.end.x - 2.5, bedroom.end.y - 2.5), "Mücevher Sandığı", 0.55)
	_sym(map, "bookshelf", Vector2(bedroom.position.x + 3, 2.5), "", 0.55)
	# mutfak
	_label(map, "Mutfak", Vector2(_center(kitchen).x, kitchen.position.y + 1.8), 11)
	_sym(map, "fireplace", Vector2(kitchen.end.x - 2.6, _center(kitchen).y), "", 0.8)
	_sym(map, "cauldron", Vector2(kitchen.end.x - 5, _center(kitchen).y), "", 0.55)
	_sym(map, "table", _center(kitchen) + Vector2(-2, 0), "", 0.8)
	_along_wall(map, kitchen, "bottom", ["barrel", "barrel", "crate"], 0.5)
	_door(map, Vector2i(W / 2, H - 2), "Ana Kapı")


static func _guardhouse(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	_room(map, Rect2i(1, 1, W - 2, H - 2), T.STONE_FLOOR)
	# koğuş
	var barracks := Rect2i(1, 1, W / 2, H - 2)
	_room(map, barracks, T.WOOD_FLOOR)
	_door(map, Vector2i(barracks.end.x - 1, H - 5))
	_label(map, "Koğuş", Vector2(_center(barracks).x, 2.8), 11)
	for i in 4:
		_sym(map, "bed", Vector2(3.2, 5 + i * 3.4), "", 0.6)
		_sym(map, "chest", Vector2(5.3, 5 + i * 3.4), "", 0.4)
	_sym(map, "weapon_rack", Vector2(barracks.end.x - 2.5, 4), "", 0.7)
	# hücreler
	for i in 3:
		var cell := Rect2i(W / 2 + i * 4, 1, 5, 6)
		_room(map, cell, T.STONE_FLOOR)
		_door(map, Vector2i(cell.position.x + 2, cell.end.y - 1))
		_sym(map, "danger" if i == 1 else "bed", _center(cell) - Vector2(0, 0.5), "", 0.45)
	_label(map, "Hücreler", Vector2(W * 0.75, 8.2), 11)
	# yüzbaşı masası
	_table_set(map, Vector2(W * 0.72, H - 6), rng, 3)
	_sym(map, "npc", Vector2(W * 0.72, H - 8.5), "Nöbetçi Çavuş", 0.7)
	_sym(map, "weapon_rack", Vector2(W - 3, H - 6), "", 0.7)
	_sym(map, "banner", Vector2(W - 3, 9.5), "", 0.6)
	_door(map, Vector2i(W * 3 / 4, H - 2), "Giriş")


static func _castle(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	map.terrain.fill(T.GRASS)
	var outer := Rect2i(3, 3, W - 6, H - 6)
	_fill(map, outer, T.WALL)
	_fill(map, outer.grow(-2), T.DIRT)  # avlu
	# köşe kuleleri
	for p in [outer.position, Vector2i(outer.end.x - 1, outer.position.y), Vector2i(outer.position.x, outer.end.y - 1), outer.end - Vector2i(1, 1)]:
		_circle(map, Vector2(p) + Vector2(0.5, 0.5), 3.2, T.WALL)
		_circle(map, Vector2(p) + Vector2(0.5, 0.5), 1.8, T.STONE_FLOOR)
		_sym(map, "tower", Vector2(p) + Vector2(0.5, 0.5), "", 0.7)
	# iç kale (taht salonu)
	var keep := Rect2i(W / 2 - 10, 6, 20, 18)
	_room(map, keep, T.STONE_FLOOR)
	_label(map, "Taht Salonu", Vector2(W * 0.5, 8), 12)
	_sym(map, "throne", Vector2(W * 0.5, 9.5), "Taht", 1.1)
	for i in 4:
		_sym(map, "rug", Vector2(W * 0.5, 12 + i * 3.0), "", 0.7)
	for i in 3:
		var y := 12.0 + i * 4.0
		_sym(map, "pillar", Vector2(W * 0.5 - 5, y), "", 0.55)
		_sym(map, "pillar", Vector2(W * 0.5 + 5, y), "", 0.55)
		_sym(map, "banner", Vector2(keep.position.x + 1.8, y), "", 0.55)
		_sym(map, "banner", Vector2(keep.end.x - 1.8, y), "", 0.55)
	_sym(map, "npc", Vector2(W * 0.5 + 2.5, 10.5), "Kraliyet Muhafızı", 0.6)
	_door(map, Vector2i(W / 2, keep.end.y - 1), "Salon Kapısı")
	# kışla (sol) ve cephanelik (sağ)
	var barracks := Rect2i(6, 6, keep.position.x - 5, 14)
	_room(map, barracks, T.WOOD_FLOOR)
	_door(map, Vector2i(barracks.position.x + 6, barracks.end.y - 1))
	_label(map, "Kışla", Vector2(_center(barracks).x, 7.8), 11)
	for i in 3:
		_sym(map, "bed", Vector2(barracks.position.x + 2.5, 10 + i * 3.2), "", 0.55)
		_sym(map, "bed", Vector2(barracks.end.x - 2.5, 10 + i * 3.2), "", 0.55)
	var armory := Rect2i(keep.end.x - 1, 6, W - 5 - keep.end.x, 10)
	_room(map, armory, T.STONE_FLOOR)
	_door(map, Vector2i(armory.position.x + 6, armory.end.y - 1))
	_label(map, "Cephanelik", Vector2(_center(armory).x, 7.8), 11)
	_along_wall(map, armory, "top", ["weapon_rack", "weapon_rack", "weapon_rack"], 0.65)
	_sym(map, "chest", _center(armory) + Vector2(-2, 1.5), "", 0.5)
	_sym(map, "chest", _center(armory) + Vector2(2, 1.5), "", 0.5)
	# mutfak / şapel
	var kitchen := Rect2i(6, H - 16, 12, 10)
	_room(map, kitchen, T.STONE_FLOOR)
	_door(map, Vector2i(kitchen.end.x - 1, kitchen.position.y + 5))
	_label(map, "Mutfak", Vector2(_center(kitchen).x, kitchen.position.y + 1.8), 11)
	_sym(map, "fireplace", Vector2(_center(kitchen).x, kitchen.end.y - 2.4), "", 0.9)
	_table_set(map, _center(kitchen), rng, 2, true)
	var chapel := Rect2i(W - 18, H - 16, 12, 10)
	_room(map, chapel, T.STONE_FLOOR)
	_door(map, Vector2i(chapel.position.x, chapel.position.y + 5))
	_label(map, "Şapel", Vector2(_center(chapel).x, chapel.position.y + 1.8), 11)
	_sym(map, "altar", _center(chapel) + Vector2(0, -1), "", 0.8)
	_sym(map, "bench", _center(chapel) + Vector2(0, 2), "", 0.5)
	# avlu: kuyu, at arabası, ana kapı
	_sym(map, "well", Vector2(W * 0.5 - 6, H - 10), "Kuyu", 0.7)
	_sym(map, "crate", Vector2(W * 0.5 + 6, H - 9), "", 0.5)
	_sym(map, "barrel", Vector2(W * 0.5 + 7.5, H - 8), "", 0.5)
	_fill(map, Rect2i(W / 2 - 1, outer.end.y - 2, 3, 2), T.COBBLE)
	_sym(map, "gate", Vector2(W * 0.5 + 0.5, outer.end.y - 1), "Kale Kapısı", 1.0)
	_fill(map, Rect2i(W / 2 - 1, keep.end.y, 3, outer.end.y - keep.end.y - 2), T.COBBLE)


static func _circle(map: MapData, c: Vector2, rad: float, t: int) -> void:
	for r in range(int(c.y - rad - 1), int(c.y + rad + 2)):
		for x in range(int(c.x - rad - 1), int(c.x + rad + 2)):
			if Vector2(x + 0.5, r + 0.5).distance_to(c) <= rad:
				_tset(map, x, r, t)


static func _tower(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	var c := Vector2(W * 0.5, H * 0.5)
	var rad := minf(W, H) * 0.44
	_circle(map, c, rad, T.WALL)
	_circle(map, c, rad - 1.6, T.STONE_FLOOR)
	_sym(map, "stairs_up", c + Vector2(rad - 4, -2), "Üst Kat", 0.8)
	_sym(map, "stairs_down", c + Vector2(rad - 4, 2), "Mahzen", 0.7)
	_sym(map, "rug", c, "", 1.0)
	_sym(map, "table", c + Vector2(-2, -1), "Çalışma Masası", 0.8)
	_sym(map, "chair", c + Vector2(-2, 0.5), "", 0.45)
	_sym(map, "cauldron", c + Vector2(-1, 4.5), "", 0.7)
	for i in 5:
		var a := PI * 0.7 + i * 0.32
		_sym(map, "bookshelf", c + Vector2(cos(a), sin(a)) * (rad - 2.8), "", 0.6)
	_sym(map, "bed", c + Vector2(2, -6), "", 0.65)
	_sym(map, "chest", c + Vector2(4.5, -5), "", 0.5)
	_sym(map, "npc", c + Vector2(1, 1.5), "Büyücü", 0.7)
	_door(map, Vector2i(int(c.x), int(c.y + rad - 0.8)), "Giriş")
	if rng.randf() < 0.5:
		_sym(map, "plant", c + Vector2(-5, -5), "", 0.5)


static func _fort(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	map.terrain.fill(T.GRASS)
	var outer := Rect2i(3, 3, W - 6, H - 6)
	_fill(map, outer, T.WALL)
	_fill(map, outer.grow(-1), T.DIRT)
	for p in [outer.position, Vector2i(outer.end.x - 1, outer.position.y), Vector2i(outer.position.x, outer.end.y - 1), outer.end - Vector2i(1, 1)]:
		_circle(map, Vector2(p) + Vector2(0.5, 0.5), 2.5, T.WALL)
		_sym(map, "tower", Vector2(p) + Vector2(0.5, 0.5), "", 0.6)
	var hall := Rect2i(6, 6, 14, 10)
	_room(map, hall, T.WOOD_FLOOR)
	_door(map, Vector2i(hall.position.x + 7, hall.end.y - 1))
	_label(map, "Koğuş", Vector2(_center(hall).x, 7.8), 11)
	for i in 3:
		_sym(map, "bed", Vector2(8.5 + i * 4.5, 10), "", 0.55)
	_table_set(map, Vector2(_center(hall).x, 13), rng, 3, true)
	var cmd := Rect2i(W - 16, 6, 10, 9)
	_room(map, cmd, T.WOOD_FLOOR)
	_door(map, Vector2i(cmd.position.x + 5, cmd.end.y - 1))
	_label(map, "Komutan", Vector2(_center(cmd).x, 7.8), 11)
	_sym(map, "table", _center(cmd), "Harita Masası", 0.8)
	_sym(map, "chest", Vector2(cmd.end.x - 2.5, cmd.position.y + 2.5), "", 0.5)
	_sym(map, "banner", Vector2(cmd.position.x + 2, cmd.position.y + 2.5), "", 0.55)
	_sym(map, "weapon_rack", Vector2(W * 0.5, H - 9), "", 0.7)
	_sym(map, "weapon_rack", Vector2(W * 0.5 + 3, H - 9), "", 0.7)
	_sym(map, "camp", Vector2(9, H - 9), "Ateş", 0.7)
	_sym(map, "crate", Vector2(W - 9, H - 8), "", 0.5)
	_sym(map, "barrel", Vector2(W - 7.5, H - 9), "", 0.5)
	_fill(map, Rect2i(W / 2 - 1, outer.end.y - 1, 3, 1), T.DIRT)
	_sym(map, "gate", Vector2(W * 0.5 + 0.5, outer.end.y - 0.5), "Karakol Kapısı", 0.9)


# ======================================================================= zindan / mağara / harabe

static func _dungeon(map: MapData, rng: RandomNumberGenerator, sewer := false) -> void:
	var W := map.cols
	var H := map.rows
	map.terrain.fill(T.VOID)
	var rooms: Array = []
	for i in 200:
		if rooms.size() >= (6 if sewer else 11):
			break
		var rw := rng.randi_range(6, 13)
		var rh := rng.randi_range(5, 9)
		var r := Rect2i(rng.randi_range(2, W - rw - 2), rng.randi_range(2, H - rh - 2), rw, rh)
		var ok := true
		for o: Rect2i in rooms:
			if o.grow(2).intersects(r):
				ok = false
				break
		if ok:
			rooms.append(r)
	rooms.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.position.x < b.position.x)
	var floor_t := T.STONE_FLOOR
	for r: Rect2i in rooms:
		_fill(map, r, floor_t)
	# koridorlar: sırayla bağla + birkaç ek döngü
	var links: Array = []
	for i in rooms.size() - 1:
		links.append([i, i + 1])
	for i in 2:
		links.append([rng.randi() % rooms.size(), rng.randi() % rooms.size()])
	var corridor_cells: Array = []
	for l in links:
		var a := Vector2i(_center(rooms[l[0]]))
		var b := Vector2i(_center(rooms[l[1]]))
		var mid := Vector2i(b.x, a.y) if rng.randf() < 0.5 else Vector2i(a.x, b.y)
		for seg in [[a, mid], [mid, b]]:
			var p: Vector2i = seg[0]
			var q: Vector2i = seg[1]
			var step := Vector2i(signi(q.x - p.x), signi(q.y - p.y))
			while true:
				if _tget(map, p.x, p.y) == T.VOID:
					_tset(map, p.x, p.y, T.SHALLOW if sewer else floor_t)
					corridor_cells.append(p)
				if p == q:
					break
				p += step
	_walls_around(map, [floor_t, T.SHALLOW])
	# kapılar: oda kenarına değen koridor hücreleri
	var doors: Array = []
	for r: Rect2i in rooms:
		for cc: Vector2i in corridor_cells:
			if not r.grow(1).has_point(cc) or r.has_point(cc) or rng.randf() > 0.6 or doors.size() >= 14:
				continue
			# koridorun odaya girdiği tek hücre: köşe değil, yakınında başka kapı yok
			var corner := (cc.x < r.position.x or cc.x >= r.end.x) and (cc.y < r.position.y or cc.y >= r.end.y)
			var near := false
			for d: Vector2i in doors:
				if d.distance_to(cc) < 4:
					near = true
			if not corner and not near:
				doors.append(cc)
				_sym(map, "door", Vector2(cc) + Vector2(0.5, 0.5), "", 0.6)
	# içerik
	var first: Rect2i = rooms[0]
	var last: Rect2i = rooms[rooms.size() - 1]
	_sym(map, "stairs_up", _center(first), "Giriş (Kuyu)" if sewer else "Giriş", 0.8)
	_sym(map, "stairs_down", _center(last) + Vector2(last.size.x * 0.3, -last.size.y * 0.25), "Daha Derine", 0.7)
	_sym(map, "treasure", _center(last) + Vector2(-last.size.x * 0.3, -last.size.y * 0.25), "Hazine", 0.8)
	_sym(map, "monster", _center(last) + Vector2(0, last.size.y * 0.2), "Zindan Bekçisi", 0.9)
	for i in range(1, rooms.size() - 1):
		var r: Rect2i = rooms[i]
		var c := _center(r)
		match rng.randi() % 6:
			0:
				_sym(map, "monster", c, "", 0.7)
				_sym(map, "monster", c + Vector2(2, 1), "", 0.6)
			1:
				_sym(map, "chest", c, "", 0.55)
				_sym(map, "trap", c + Vector2(-1.5, 0), "", 0.5)
			2:
				_sym(map, "altar", c, "Kara Sunak", 0.8)
				_sym(map, "pillar", c + Vector2(-2.5, -1.5), "", 0.45)
				_sym(map, "pillar", c + Vector2(2.5, -1.5), "", 0.45)
			3:
				for k in 4:
					_sym(map, "pillar", c + Vector2(-2.5 + (k % 2) * 5, -1.5 + (k / 2) * 3), "", 0.45)
				_sym(map, "monster", c, "", 0.7)
			4:
				_sym(map, "barrel", c + Vector2(-1, -1), "", 0.5)
				_sym(map, "crate", c + Vector2(1, -1), "", 0.5)
				_sym(map, "crate", c + Vector2(0, 1), "", 0.45)
			5:
				_sym(map, "bed", c, "", 0.5)
				_sym(map, "npc", c + Vector2(2, 0), "Esir", 0.55)
	for i in mini(4, corridor_cells.size() / 12):
		var cc: Vector2i = corridor_cells[rng.randi() % corridor_cells.size()]
		_sym(map, "trap", Vector2(cc) + Vector2(0.5, 0.5), "", 0.5)


static func _cave(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	var grid := PackedByteArray()
	grid.resize(W * H)
	for r in H:
		for c in W:
			var edge := c < 2 or r < 2 or c >= W - 2 or r >= H - 2
			grid[r * W + c] = 1 if edge or rng.randf() < 0.46 else 0
	for it in 5:
		var nxt := grid.duplicate()
		for r in range(1, H - 1):
			for c in range(1, W - 1):
				var n := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						n += grid[(r + dy) * W + c + dx]
				nxt[r * W + c] = 1 if n >= 5 else 0
		grid = nxt
	# en büyük bağlı alanı bul (merkeze yakın)
	var start := Vector2i(W / 2, H / 2)
	var best := -1
	for i in 400:
		var p := Vector2i(rng.randi_range(2, W - 3), rng.randi_range(2, H - 3))
		if grid[p.y * W + p.x] == 0:
			var d := p.distance_squared_to(Vector2i(W / 2, H / 2))
			if best < 0 or d < best:
				best = d
				start = p
	var seen := PackedByteArray()
	seen.resize(W * H)
	var stack: Array = [start]
	seen[start.y * W + start.x] = 1
	var cells: Array = []
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		cells.append(p)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if q.x >= 0 and q.y >= 0 and q.x < W and q.y < H and grid[q.y * W + q.x] == 0 and seen[q.y * W + q.x] == 0:
				seen[q.y * W + q.x] = 1
				stack.append(q)
	map.terrain.fill(T.VOID)
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.08
	for p: Vector2i in cells:
		var w := noise.get_noise_2d(p.x, p.y)
		map.terrain[p.y * W + p.x] = T.SHALLOW if w > 0.42 else T.DIRT
	_walls_around(map, [T.DIRT, T.SHALLOW])
	if cells.is_empty():
		return
	# giriş: en soldaki hücre
	var entry: Vector2i = cells[0]
	var deep: Vector2i = cells[0]
	for p: Vector2i in cells:
		if p.x < entry.x:
			entry = p
		if p.x > deep.x:
			deep = p
	_sym(map, "stairs_up", Vector2(entry) + Vector2(0.5, 0.5), "Mağara Ağzı", 0.8)
	_sym(map, "treasure", Vector2(deep) + Vector2(0.5, 0.5), "Gizli Hazine", 0.8)
	_sym(map, "monster", Vector2(deep) + Vector2(-2, 1), "Mağara Canavarı", 1.0)
	var placed: Array = [entry, deep]
	var kinds := ["monster", "monster", "chest", "trap", "plant", "plant", "camp", "danger", "crate"]
	var names := {"camp": "Terk Edilmiş Kamp", "plant": "", "danger": "Çökük Tavan"}
	for k in kinds:
		for t in 30:
			var p: Vector2i = cells[rng.randi() % cells.size()]
			var ok := map.terrain[p.y * W + p.x] == T.DIRT
			for q: Vector2i in placed:
				if q.distance_to(p) < 8:
					ok = false
			if ok:
				placed.append(p)
				_sym(map, k, Vector2(p) + Vector2(0.5, 0.5), names.get(k, ""), 0.6 if k == "plant" else 0.75)
				break


static func _ruins(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	map.terrain.fill(T.GRASS)
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.07
	for r in H:
		for c in W:
			if noise.get_noise_2d(c, r) > 0.35:
				map.terrain[r * W + c] = T.FOREST
	var rooms: Array = []
	var core := Rect2i(W / 2 - 14, H / 2 - 10, 28, 20)
	for i in 60:
		if rooms.size() >= 6:
			break
		var rw := rng.randi_range(6, 11)
		var rh := rng.randi_range(5, 8)
		var r := Rect2i(rng.randi_range(core.position.x, core.end.x - rw), rng.randi_range(core.position.y, core.end.y - rh), rw, rh)
		var ok := true
		for o: Rect2i in rooms:
			if o.intersects(r.grow(-1)):
				ok = false
		if ok:
			rooms.append(r)
	for r: Rect2i in rooms:
		_room(map, r, T.STONE_FLOOR)
	# yıkıntı: duvarların bir kısmı çökmüş, zemin yer yer otlanmış
	for r in H:
		for c in W:
			var t := map.terrain[r * W + c]
			if t == T.WALL and rng.randf() < 0.3:
				map.terrain[r * W + c] = T.DIRT
			elif t == T.STONE_FLOOR and rng.randf() < 0.12:
				map.terrain[r * W + c] = T.GRASS
	_path(map, "trail", [Vector2(0, H * 0.6), Vector2(W * 0.25, H * 0.55), Vector2(W * 0.5 - 14, H * 0.5)])
	var big: Rect2i = rooms[0]
	for r: Rect2i in rooms:
		if r.get_area() > big.get_area():
			big = r
	_sym(map, "stairs_down", _center(big), "Yeraltı Girişi", 0.8)
	_sym(map, "statue", _center(big) + Vector2(-2.5, -1.5), "Kırık Heykel", 0.7)
	for r: Rect2i in rooms:
		if r == big:
			continue
		var c := _center(r)
		match rng.randi() % 4:
			0: _sym(map, "pillar", c, "", 0.55)
			1: _sym(map, "chest", c, "", 0.5)
			2: _sym(map, "monster", c, "", 0.7)
			3: _sym(map, "altar", c, "Eski Sunak", 0.7)
	for i in 14:
		var p := Vector2(rng.randf_range(2, W - 2), rng.randf_range(2, H - 2))
		if _tget(map, int(p.x), int(p.y)) in [T.GRASS, T.FOREST]:
			_sym(map, "tree", p, "", rng.randf_range(0.7, 1.0))
	_sym(map, "danger", Vector2(W * 0.5 + 10, H * 0.5 + 8), "Çökme Tehlikesi", 0.6)


# ======================================================================= doğa alanları

## Ağaçları belirli aralıkla serpiştir
static func _scatter(map: MapData, rng: RandomNumberGenerator, type: String, on: Array, count: int, min_d: float, size_range := Vector2(0.7, 1.0)) -> void:
	var placed: Dictionary = {}
	for i in count * 6:
		if count <= 0:
			break
		var p := Vector2(rng.randf_range(1, map.cols - 1), rng.randf_range(1, map.rows - 1))
		if not _tget(map, int(p.x), int(p.y)) in on:
			continue
		var key := Vector2i(int(p.x / 8), int(p.y / 8))
		var ok := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for q: Vector2 in placed.get(key + Vector2i(dx, dy), []):
					if q.distance_to(p) < min_d:
						ok = false
		if ok:
			if not placed.has(key):
				placed[key] = []
			placed[key].append(p)
			_sym(map, type, p, "", rng.randf_range(size_range.x, size_range.y))
			count -= 1


## Kıvrımlı çizgi (hücre koordinatlarında)
static func _wiggle(a: Vector2, b: Vector2, rng: RandomNumberGenerator, amp: float, n := 8) -> Array:
	var pts: Array = [a]
	var nrm := (b - a).orthogonal().normalized()
	for i in range(1, n):
		var k := float(i) / n
		pts.append(a.lerp(b, k) + nrm * rng.randf_range(-amp, amp))
	pts.append(b)
	return pts


static func _carve_line(map: MapData, pts: Array, rad: float, t: int, only: Array = []) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(a.distance_to(b) * 2) + 1
		for s in steps + 1:
			var p := a.lerp(b, float(s) / steps)
			for r in range(int(p.y - rad), int(p.y + rad) + 1):
				for c in range(int(p.x - rad), int(p.x + rad) + 1):
					if Vector2(c + 0.5, r + 0.5).distance_to(p) <= rad and (only.is_empty() or _tget(map, c, r) in only):
						_tset(map, c, r, t)


static func _forest(map: MapData, rng: RandomNumberGenerator, pine: bool) -> void:
	var W := map.cols
	var H := map.rows
	map.terrain.fill(T.FOREST)
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.05
	# açıklıklar
	var clearings: Array = []
	for i in rng.randi_range(3, 5):
		var c := Vector2(rng.randf_range(W * 0.15, W * 0.85), rng.randf_range(H * 0.15, H * 0.85))
		var rad := rng.randf_range(4, 8)
		clearings.append(c)
		for r in range(int(c.y - rad - 2), int(c.y + rad + 3)):
			for x in range(int(c.x - rad - 2), int(c.x + rad + 3)):
				var d := Vector2(x, r).distance_to(c) + noise.get_noise_2d(x * 3.0, r * 3.0) * 3.0
				if d < rad:
					_tset(map, x, r, T.GRASS)
	clearings.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	# bataklık / göl
	var lake := Vector2(rng.randf_range(W * 0.2, W * 0.8), rng.randf_range(H * 0.2, H * 0.8))
	for r in H:
		for x in W:
			var d := Vector2(x, r).distance_to(lake) + noise.get_noise_2d(x * 2.0 + 99, r * 2.0) * 3.0
			if d < 3.5:
				_tset(map, x, r, T.SHALLOW)
			elif d < 5.0 and not pine:
				_tset(map, x, r, T.SWAMP)
	# dere: kuzeyden göle, gölden güneye
	var top := Vector2(rng.randf_range(W * 0.2, W * 0.8), 0)
	var bot := Vector2(rng.randf_range(W * 0.2, W * 0.8), H)
	var stream1 := _wiggle(top, lake, rng, 4.0, 6)
	var stream2 := _wiggle(lake, bot, rng, 4.0, 6)
	_path(map, "stream", stream1)
	_path(map, "stream", stream2)
	# patika: batıdan doğuya açıklıklardan geçerek
	var trail: Array = [Vector2(0, rng.randf_range(H * 0.3, H * 0.7))]
	for c: Vector2 in clearings:
		trail.append(c)
	trail.append(Vector2(W, rng.randf_range(H * 0.3, H * 0.7)))
	var tp: Array = []
	for i in trail.size() - 1:
		var seg := _wiggle(trail[i], trail[i + 1], rng, 2.0, 4)
		if i > 0:
			seg.pop_front()
		tp.append_array(seg)
	_carve_line(map, tp, 0.9, T.DIRT, [T.FOREST, T.GRASS, T.SWAMP])
	_path(map, "trail", tp)
	# patika dereyi nerede kesiyor? köprü
	var cross := _intersect(tp, stream1 + stream2)
	if cross != Vector2.INF:
		_sym(map, "bridge", cross, "Kütük Köprü", 0.8)
	# ağaçlar (seyrek: zemin zaten orman dokusunda)
	_scatter(map, rng, "tree", [T.FOREST], W * H / 45, 3.2, Vector2(0.75, 1.15))
	_scatter(map, rng, "tree", [T.GRASS], W * H / 600, 4.0)
	# yer işaretleri
	var feats := [["camp", "Avcı Kampı"], ["shrine", "Eski Druid Sunağı" if not pine else "Taş Halka"],
			["ruins", "Yıkık Kulübe"], ["danger", "Kurt İni"], ["treasure", "Gömülü Sandık"], ["npc", "Ormancı"],
			["cave", "Ayı Mağarası"]]
	feats.shuffle()
	for i in mini(clearings.size(), feats.size()):
		var c: Vector2 = clearings[i]
		_sym(map, feats[i][0], c + Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5)), feats[i][1], 0.9)
	for i in range(clearings.size(), mini(clearings.size() + 2, feats.size())):
		_sym(map, feats[i][0], Vector2(rng.randf_range(5, W - 5), rng.randf_range(5, H - 5)), feats[i][1], 0.8)
	_sym(map, "poi", Vector2(1.5, tp[0].y), "Orman Girişi", 0.7)


static func _intersect(a: Array, b: Array) -> Vector2:
	for i in a.size() - 1:
		for j in b.size() - 1:
			var hit = Geometry2D.segment_intersects_segment(a[i], a[i + 1], b[j], b[j + 1])
			if hit != null:
				return hit
	return Vector2.INF


static func _mountain(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	# kuzeye doğru yükselen arazi
	var heights := PackedFloat32Array()
	heights.resize(W * H)
	for r in H:
		for c in W:
			var e := noise.get_noise_2d(c, r) * 0.5 + 0.5 + (1.0 - float(r) / H) * 0.5 - 0.12
			heights[r * W + c] = e
			var t := T.GRASS
			if e > 0.78: t = T.SNOW
			elif e > 0.6: t = T.MOUNTAIN
			elif e > 0.45: t = T.HILLS
			elif e > 0.3: t = T.PLAINS
			map.terrain[r * W + c] = t
	# geçit patikası (güneyden kuzeye zikzak)
	var tp: Array = []
	var x := rng.randf_range(W * 0.3, W * 0.7)
	for i in 9:
		tp.append(Vector2(clampf(x + (8.0 if i % 2 == 0 else -8.0) + rng.randf_range(-3, 3), 2, W - 2), H - i * H / 8.0))
	_carve_line(map, tp, 0.7, T.DIRT, [T.GRASS, T.PLAINS, T.HILLS, T.MOUNTAIN])
	_path(map, "trail", tp)
	# eriyen kardan inen dere
	var spring := Vector2(rng.randf_range(W * 0.1, W * 0.4), H * 0.15)
	_path(map, "stream", _wiggle(spring, Vector2(rng.randf_range(0, W * 0.3), H), rng, 5.0, 8))
	var lake := Vector2(rng.randf_range(W * 0.55, W * 0.85), H * 0.3)
	for r in H:
		for c in W:
			if Vector2(c, r).distance_to(lake) + noise.get_noise_2d(c * 4.0, r * 4.0) * 2.0 < 3.0:
				_tset(map, c, r, T.SHALLOW)
	# kayalar ve çam ağaçları
	_scatter(map, rng, "tree", [T.GRASS, T.HILLS], W * H / 140, 3.5)
	_scatter(map, rng, "pillar", [T.MOUNTAIN], W * H / 500, 6.0, Vector2(0.4, 0.6))
	_sym(map, "camp", tp[2] + Vector2(3, 0), "Konaklama Yeri", 0.8)
	_sym(map, "cave", tp[5] + Vector2(-4, 0), "Mağara Ağzı", 0.9)
	_sym(map, "shrine", tp[8] + Vector2(2, 2), "Zirve Sunağı", 0.8)
	_sym(map, "danger", tp[6] + Vector2(4, 1), "Heyelan", 0.7)
	_sym(map, "bridge", tp[3], "Halat Köprü", 0.7)
	_sym(map, "monster", Vector2(lake.x + 6, lake.y + 4), "Dağ Trolü", 0.9)
	_label(map, "Geçit", tp[4] + Vector2(4, 0), 16)


static func _hills(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.045
	for r in H:
		for c in W:
			var e := noise.get_noise_2d(c, r)
			var t := T.GRASS
			if e > 0.35: t = T.HILLS
			elif e < -0.3: t = T.PLAINS
			map.terrain[r * W + c] = t
	var tp := _wiggle(Vector2(0, H * 0.5), Vector2(W, H * 0.45), rng, 8.0, 10)
	_carve_line(map, tp, 0.7, T.DIRT, [T.GRASS, T.PLAINS, T.HILLS])
	_path(map, "trail", tp)
	_path(map, "stream", _wiggle(Vector2(W * 0.3, 0), Vector2(W * 0.6, H), rng, 6.0, 8))
	for i in 3:
		var c := Vector2(rng.randf_range(5, W - 15), rng.randf_range(5, H - 10))
		if _tget(map, int(c.x), int(c.y)) != T.HILLS:
			_fill(map, Rect2i(int(c.x), int(c.y), rng.randi_range(6, 10), rng.randi_range(4, 7)), T.FIELD)
	_scatter(map, rng, "tree", [T.GRASS, T.PLAINS], W * H / 170, 4.0)
	var top := Vector2(W * 0.5, H * 0.5)
	var best := -9.0
	for i in 200:
		var p := Vector2(rng.randf_range(5, W - 5), rng.randf_range(5, H - 5))
		var e := noise.get_noise_2d(p.x, p.y)
		if e > best:
			best = e
			top = p
	for i in 6:
		var a := TAU * i / 6.0
		_sym(map, "pillar", top + Vector2(cos(a), sin(a)) * 2.5, "", 0.5)
	_sym(map, "shrine", top, "Dikili Taşlar", 0.8)
	_sym(map, "camp", tp[3] + Vector2(0, 3) if tp[3].distance_to(top) > 8 else tp[3] + Vector2(0, -6), "Çoban Kampı", 0.8)
	_sym(map, "ruins", tp[7] + Vector2(2, -4), "Eski Gözetleme Kulesi", 0.8)
	_sym(map, "npc", tp[5] + Vector2(-1, 2), "Çoban", 0.6)


static func _volcano(map: MapData, rng: RandomNumberGenerator) -> void:
	var W := map.cols
	var H := map.rows
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.06
	var c := Vector2(W * 0.5, H * 0.42)
	for r in H:
		for x in W:
			var d := Vector2(x, r).distance_to(c) / (minf(W, H) * 0.5) + noise.get_noise_2d(x, r) * 0.12
			var t := T.DIRT
			if d < 0.12: t = T.LAVA
			elif d < 0.2: t = T.MOUNTAIN
			elif d < 0.55: t = T.MOUNTAIN if noise.get_noise_2d(x * 2.0, r * 2.0) > -0.2 else T.DIRT
			elif d > 0.9: t = T.PLAINS
			map.terrain[r * W + x] = t
	# lav akıntıları
	for i in 3:
		var a := PI * 0.5 + rng.randf_range(-1.2, 1.2)
		var end := c + Vector2(cos(a), sin(a)) * minf(W, H) * 0.55
		_carve_line(map, _wiggle(c, end, rng, 3.0, 8), 0.8, T.LAVA)
	var tp := _wiggle(Vector2(W * 0.2, H), c + Vector2(-6, 6), rng, 4.0, 8)
	_carve_line(map, tp, 0.6, T.DIRT, [T.MOUNTAIN, T.PLAINS])
	_path(map, "trail", tp)
	_sym(map, "shrine", c + Vector2(-8, 6), "Ateş Sunağı", 0.8)
	_sym(map, "danger", c + Vector2(5, 7), "Zehirli Gaz", 0.8)
	_sym(map, "cave", c + Vector2(9, -2), "Lav Tüneli", 0.8)
	_sym(map, "monster", c + Vector2(0, -6), "Ateş Elementali", 1.0)
	_sym(map, "camp", tp[2], "Cüce Madenci Kampı", 0.8)
	_label(map, "Krater", c + Vector2(0, -3), 18)
