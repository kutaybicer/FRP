class_name Encounters
extends RefCounted
## Doğa alanlarına (orman, dağ, tepe, yanardağ) otomatik oluşturmada rastgele düşman.
## Ortama uygun gruplar: ormanda kurt sürüsü ya da ayı, dağda trol / dev, yanardağda ateş yaratıkları...
## Her grup gerçek bestiyer yaratıklarıdır: haritaya jeton olarak konur, canları ayrı ayrı ayarlanabilir.

const CHANCE := 0.20

# ağırlık, ad, [[tür, en az, en çok], ...]
const TABLES := {
	"forest": [
		[16, "Kurt Sürüsü", [["wolf", 3, 6]]],
		[6, "Dev Kurtlar", [["dire_wolf", 2, 3]]],
		[8, "Kara Ayı", [["black_bear", 1, 1]]],
		[6, "Boz Ayı", [["brown_bear", 1, 1]]],
		[7, "Yaban Domuzları", [["boar", 2, 4]]],
		[6, "Dev Örümcek Yuvası", [["giant_spider", 2, 4]]],
		[5, "Baykuşayı", [["owlbear", 1, 1]]],
		[8, "Haydut Pususu", [["bandit", 3, 5], ["bandit_captain", 1, 1]]],
		[7, "Goblin Akıncıları", [["goblin_m", 4, 7]]],
		[4, "Vargs ve Goblinler", [["worg", 2, 3], ["goblin_m", 2, 3]]],
		[3, "Kurtadam", [["werewolf", 1, 1]]],
		[3, "Panterler", [["panther", 1, 2]]],
		[2, "Gölge Panter", [["displacer", 1, 1]]],
		[2, "Öfkeli Ağaç Ata", [["treant", 1, 1]]],
		[2, "Orman Cadısı", [["hag", 1, 1]]],
	],
	"pine": [
		[14, "Kurt Sürüsü", [["wolf", 4, 7]]],
		[8, "Dev Kurtlar", [["dire_wolf", 2, 3]]],
		[10, "Boz Ayı", [["brown_bear", 1, 2]]],
		[6, "Vaşaklar", [["lynx", 1, 2]]],
		[5, "Vargs", [["worg", 2, 4]]],
		[6, "Haydutlar", [["bandit", 3, 5], ["bandit_captain", 1, 1]]],
		[4, "Baykuşayı", [["owlbear", 1, 1]]],
		[3, "Kurtadam Sürüsü", [["werewolf", 1, 2], ["wolf", 2, 3]]],
	],
	"mountain": [
		[12, "Trol", [["troll", 1, 2]]],
		[10, "Ogreler", [["ogre", 1, 3]]],
		[6, "Tepe Devi", [["hill_giant", 1, 1]]],
		[5, "Buz Devi", [["frost_giant", 1, 1]]],
		[8, "Boz Ayı", [["brown_bear", 1, 1]]],
		[7, "Harpi Sürüsü", [["harpy", 3, 5]]],
		[6, "Grifon Yuvası", [["griffon", 1, 2]]],
		[8, "Ork Savaş Grubu", [["orc_m", 3, 6], ["orc_shaman", 1, 1]]],
		[4, "Vivern", [["wyvern", 1, 1]]],
		[4, "Tepegöz", [["cyclops", 1, 1]]],
		[3, "Mantikor", [["manticore", 1, 1]]],
		[3, "Dev Kartallar", [["giant_eagle", 2, 3]]],
		[2, "Rok Kuşu", [["roc", 1, 1]]],
		[3, "Gargoyller", [["gargoyle", 2, 3]]],
	],
	"hills": [
		[12, "Kurt Sürüsü", [["wolf", 3, 5]]],
		[9, "Haydut Kampı", [["bandit", 3, 6], ["bandit_captain", 1, 1]]],
		[8, "Goblin Akıncıları", [["goblin_m", 4, 6]]],
		[8, "Hobgoblin Devriyesi", [["hobgoblin_m", 3, 5]]],
		[7, "Ork Akıncıları", [["orc_m", 3, 5]]],
		[6, "Ogre", [["ogre", 1, 2]]],
		[5, "Tepe Devi", [["hill_giant", 1, 1]]],
		[6, "Yaban Domuzları", [["boar", 2, 4]]],
		[4, "Sentor Avcılar", [["centaur_m", 2, 3]]],
		[3, "Mantikor", [["manticore", 1, 1]]],
		[3, "Kobold Tuzakçıları", [["kobold_m", 4, 8]]],
	],
	"volcano": [
		[12, "Ateş Elementalleri", [["fire_elemental", 1, 2]]],
		[10, "Cehennem Köpekleri", [["hellhound", 2, 4]]],
		[6, "Ateş Devi", [["fire_giant", 1, 1]]],
		[6, "Yavru Ejderha", [["wyrmling", 1, 1]]],
		[7, "Şeytancıklar", [["imp", 3, 5]]],
		[4, "Tarikatçılar ve İblis", [["cultist", 3, 4], ["demon", 1, 1]]],
		[4, "Vivern", [["wyvern", 1, 1]]],
		[3, "Kimera", [["chimera", 1, 1]]],
		[2, "Anka Kuşu", [["phoenix", 1, 1]]],
	],
}


static func has_table(type: String) -> bool:
	return TABLES.has(type)


## %20 şansla bir karşılaşma seçer; yoksa boş sözlük
static func roll(type: String, rng: RandomNumberGenerator, chance := CHANCE) -> Dictionary:
	if not TABLES.has(type) or rng.randf() >= chance:
		return {}
	var table: Array = TABLES[type]
	var total := 0
	for e in table:
		total += int(e[0])
	var pick := rng.randi_range(1, total)
	for e in table:
		pick -= int(e[0])
		if pick <= 0:
			var groups: Array = []
			for g in e[2]:
				if Lore.creatures.has(g[0]):
					groups.append([g[0], rng.randi_range(int(g[1]), int(g[2]))])
			return {"name": e[1], "groups": groups}
	return {}


## Karşılaşmayı haritaya koyar: her tür için bir karakter (yaratık), her birey için bir jeton.
## Dönen metin: "Kurt Sürüsü (5 Kurt)"
static func spawn(campaign: Campaign, map: MapData, enc: Dictionary, rng: RandomNumberGenerator) -> String:
	if enc.is_empty() or enc["groups"].is_empty():
		return ""
	var center := _spot(map, rng)
	var used: Array = []
	var parts: Array = []
	for g in enc["groups"]:
		var species: String = g[0]
		var n: int = g[1]
		var ch := Lore.new_creature(species)
		ch["disposition"] = "enemy"
		ch["spawned_on"] = map.id
		ch["notes"] = "Otomatik karşılaşma: %s." % enc["name"]
		var id := campaign.add_character(ch)
		for i in n:
			var p := _free_near(map, center, used, rng)
			used.append(p)
			map.tokens.append({"char": id, "pos": p * Defs.CELL, "hp": int(ch.get("hp_max", 1)),
					"label": str(i + 1) if n > 1 else ""})
		parts.append("%d %s" % [n, ch["name"]])
	return "%s (%s)" % [enc["name"], ", ".join(PackedStringArray(parts))]


## Bu haritaya otomatik konmuş eski karşılaşmaları temizler (yeniden oluştururken)
static func clear(campaign: Campaign, map: MapData) -> void:
	for id in campaign.characters.keys():
		var ch: Dictionary = campaign.characters[id]
		if str(ch.get("spawned_on", "")) == map.id:
			campaign.remove_character(id)


static func _walkable(map: MapData, c: int, r: int) -> bool:
	if not map.in_bounds(c, r):
		return false
	var t := map.terrain[map.idx(c, r)]
	return Defs.water_lookup[t] == 0 and not (t in [Defs.T.LAVA, Defs.T.WALL, Defs.T.VOID])


## Grubun toplanacağı yer: açıklık / patika gibi yürünebilir, kenarlardan uzak bir nokta
static func _spot(map: MapData, rng: RandomNumberGenerator) -> Vector2:
	var best := Vector2(map.cols, map.rows) * 0.5
	for i in 300:
		var c := rng.randi_range(int(map.cols * 0.15), int(map.cols * 0.85))
		var r := rng.randi_range(int(map.rows * 0.15), int(map.rows * 0.85))
		if not _walkable(map, c, r):
			continue
		var ok := true
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if not _walkable(map, c + dx, r + dy):
					ok = false
		var p := Vector2(c + 0.5, r + 0.5)
		# sembollerin (kamp, sunak...) tam üstüne gelmesin
		for s in map.symbols:
			if (s["pos"] / Defs.CELL).distance_to(p) < 3.0:
				ok = false
				break
		if ok:
			return p
	return best


static func _free_near(map: MapData, center: Vector2, used: Array, rng: RandomNumberGenerator) -> Vector2:
	for i in 60:
		var rad := 0.0 if used.is_empty() else rng.randf_range(2.8, 3.4 + used.size() * 0.5)
		var a := rng.randf() * TAU
		var p := center + Vector2(cos(a), sin(a)) * rad
		if not _walkable(map, int(p.x), int(p.y)):
			continue
		var ok := true
		for q: Vector2 in used:
			if q.distance_to(p) < 2.7:
				ok = false
				break
		if ok:
			return p
	return center + Vector2(used.size() * 1.6, 0)
