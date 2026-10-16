extends Node
## Global tanımlar (autoload: Defs)
## Arazi tipleri, semboller, yol tipleri, harita türleri ve isim üreteci burada.

const CELL := 16            # bir hücrenin piksel boyu
const SYMBOL_BASE := 18.0   # sembol yarıçapı (boyut çarpanı 1.0 iken)
const TOKEN_BASE := 15.0    # orta boy karakter jetonunun yarıçapı

enum Kind { WORLD, REGION, CITY, DUNGEON, BUILDING, SITE }
const KIND_NAMES := ["Dünya", "Bölge", "Şehir", "Zindan", "Yapı / İç Mekan", "Yerel Alan"]

# Arazi indeksleri (kayıt dosyaları bu sıraya bağlıdır, sadece sona ekleyin)
enum T { DEEP, SEA, SHALLOW, SAND, GRASS, PLAINS, FOREST, SWAMP, DESERT, HILLS,
		MOUNTAIN, SNOW, LAVA, DIRT, COBBLE, STONE_FLOOR, WOOD_FLOOR, WALL, VOID, PARCHMENT,
		ROOF_RED, ROOF_SLATE, FIELD }

var terrains: Array = [
	{"name": "Derin Deniz", "color": Color("1b3a6b"), "water": true},
	{"name": "Deniz", "color": Color("2a5a9a"), "water": true},
	{"name": "Sığ Su / Göl", "color": Color("4a86c0"), "water": true},
	{"name": "Kumsal", "color": Color("e3d39b"), "water": false},
	{"name": "Çayır", "color": Color("8fbf5a"), "water": false},
	{"name": "Ova / Bozkır", "color": Color("c2c77a"), "water": false},
	{"name": "Orman", "color": Color("3f7a3a"), "water": false},
	{"name": "Bataklık", "color": Color("5d6b45"), "water": false},
	{"name": "Çöl", "color": Color("e2c27a"), "water": false},
	{"name": "Tepelik", "color": Color("a08b5b"), "water": false},
	{"name": "Dağlık", "color": Color("7d7468"), "water": false},
	{"name": "Kar / Buzul", "color": Color("eef1f5"), "water": false},
	{"name": "Lav", "color": Color("c0392b"), "water": false},
	{"name": "Toprak Yol", "color": Color("9c7a52"), "water": false},
	{"name": "Kaldırım", "color": Color("a3a09a"), "water": false},
	{"name": "Taş Zemin", "color": Color("6e6a66"), "water": false},
	{"name": "Ahşap Zemin", "color": Color("8b5a2b"), "water": false},
	{"name": "Duvar", "color": Color("3a3633"), "water": false},
	{"name": "Boşluk / Kaya", "color": Color("161412"), "water": false},
	{"name": "Parşömen", "color": Color("e8dcb8"), "water": false},
	{"name": "Çatı (Kiremit)", "color": Color("a9503a"), "water": false},
	{"name": "Çatı (Arduvaz)", "color": Color("5b6470"), "water": false},
	{"name": "Tarla", "color": Color("b9a659"), "water": false},
]
var water_lookup := PackedByteArray()
# Shader doku stili (terrain.gdshader içindeki land_detail ile eşleşir)
# 0 düz, 1 orman, 2 dağ/tepe, 3 kum, 4 kar, 5 taş döşeme, 6 ahşap, 7 duvar, 8 kaya boşluk, 9 bataklık, 10 lav, 11 çayır,
# 12 çatı kiremidi, 13 tarla sıraları
var terrain_styles: Array = [0, 0, 0, 3, 11, 11, 1, 9, 3, 2, 2, 4, 10, 0, 5, 5, 6, 7, 8, 0, 12, 12, 13]
var terrain_palette: ImageTexture

var font_title: Font   # bölge isimleri, harita yazıları (Cinzel)
var font_text: Font    # sembol isimleri (EB Garamond)

const KIND_DEFAULTS := {
	Kind.WORLD: {"cols": 120, "rows": 80, "fill": T.SEA, "scale": 10.0, "unit": "km"},
	Kind.REGION: {"cols": 100, "rows": 70, "fill": T.GRASS, "scale": 2.0, "unit": "km"},
	Kind.CITY: {"cols": 80, "rows": 60, "fill": T.GRASS, "scale": 5.0, "unit": "m"},
	Kind.DUNGEON: {"cols": 60, "rows": 45, "fill": T.VOID, "scale": 1.5, "unit": "m"},
	Kind.BUILDING: {"cols": 40, "rows": 30, "fill": T.VOID, "scale": 1.5, "unit": "m"},
	Kind.SITE: {"cols": 100, "rows": 70, "fill": T.GRASS, "scale": 5.0, "unit": "m"},
}

# Giriş kuralları: hangi haritada hangi sembolün içine girilebilir?
# Dünya/Bölge: yerleşimler, yapılar, doğa alanları, zindanlar. Şehir: sadece binalar.
# Bina, zindan ve yerel alan haritaları son katmandır (içlerinden başka yere girilmez).
const SETTLEMENTS := ["capital", "city", "town", "village", "port"]
const STRUCTURES := ["castle", "fort", "tower", "temple"]
const CITY_BUILDINGS := ["house", "noble", "tavern", "inn", "shop", "blacksmith", "guard", "temple", "tower", "castle"]
const WILDS := ["forest", "pine", "mountain", "hills", "volcano"]
const UNDERGROUND := ["dungeon", "cave", "ruins"]

# Semboller: child = tıklanınca açılacak alt haritanın türü (-1 = otomatik alt harita yok)
var symbol_categories: Array = ["Yerleşim", "Doğa", "Özel Yerler", "Şehir", "Zindan / İç Mekan", "Mobilya"]
var symbols: Dictionary = {
	"capital": {"name": "Başkent", "cat": "Yerleşim", "child": Kind.CITY},
	"city": {"name": "Şehir", "cat": "Yerleşim", "child": Kind.CITY},
	"town": {"name": "Kasaba", "cat": "Yerleşim", "child": Kind.CITY},
	"village": {"name": "Köy", "cat": "Yerleşim", "child": Kind.CITY},
	"castle": {"name": "Kale", "cat": "Yerleşim", "child": Kind.BUILDING},
	"fort": {"name": "Karakol", "cat": "Yerleşim", "child": Kind.BUILDING},
	"port": {"name": "Liman", "cat": "Yerleşim", "child": Kind.CITY},
	"camp": {"name": "Kamp", "cat": "Yerleşim", "child": -1},
	"mountain": {"name": "Dağ", "cat": "Doğa", "child": -1},
	"hills": {"name": "Tepeler", "cat": "Doğa", "child": -1},
	"volcano": {"name": "Yanardağ", "cat": "Doğa", "child": Kind.DUNGEON},
	"forest": {"name": "Orman", "cat": "Doğa", "child": Kind.REGION},
	"pine": {"name": "Çam Ormanı", "cat": "Doğa", "child": Kind.REGION},
	"tree": {"name": "Ağaç", "cat": "Doğa", "child": -1},
	"dungeon": {"name": "Zindan", "cat": "Özel Yerler", "child": Kind.DUNGEON},
	"cave": {"name": "Mağara", "cat": "Özel Yerler", "child": Kind.DUNGEON},
	"ruins": {"name": "Harabe", "cat": "Özel Yerler", "child": Kind.DUNGEON},
	"tower": {"name": "Kule", "cat": "Özel Yerler", "child": Kind.BUILDING},
	"temple": {"name": "Tapınak", "cat": "Özel Yerler", "child": Kind.BUILDING},
	"shrine": {"name": "Sunak / Anıt", "cat": "Özel Yerler", "child": -1},
	"portal": {"name": "Portal", "cat": "Özel Yerler", "child": Kind.REGION},
	"battle": {"name": "Savaş Alanı", "cat": "Özel Yerler", "child": -1},
	"treasure": {"name": "Hazine", "cat": "Özel Yerler", "child": -1},
	"danger": {"name": "Tehlike", "cat": "Özel Yerler", "child": -1},
	"bridge": {"name": "Köprü", "cat": "Özel Yerler", "child": -1},
	"poi": {"name": "Önemli Nokta", "cat": "Özel Yerler", "child": -1},
	"house": {"name": "Ev", "cat": "Şehir", "child": Kind.BUILDING},
	"noble": {"name": "Konak", "cat": "Şehir", "child": Kind.BUILDING},
	"tavern": {"name": "Meyhane", "cat": "Şehir", "child": Kind.BUILDING},
	"inn": {"name": "Han", "cat": "Şehir", "child": Kind.BUILDING},
	"shop": {"name": "Dükkan", "cat": "Şehir", "child": Kind.BUILDING},
	"blacksmith": {"name": "Demirci", "cat": "Şehir", "child": Kind.BUILDING},
	"market": {"name": "Pazar", "cat": "Şehir", "child": -1},
	"gate": {"name": "Kapı", "cat": "Şehir", "child": -1},
	"well": {"name": "Kuyu", "cat": "Şehir", "child": Kind.DUNGEON},
	"guard": {"name": "Muhafız", "cat": "Şehir", "child": Kind.BUILDING},
	"statue": {"name": "Heykel", "cat": "Şehir", "child": -1},
	"door": {"name": "Kapı (iç)", "cat": "Zindan / İç Mekan", "child": -1},
	"stairs_up": {"name": "Yukarı Merdiven", "cat": "Zindan / İç Mekan", "child": Kind.BUILDING},
	"stairs_down": {"name": "Aşağı Merdiven", "cat": "Zindan / İç Mekan", "child": Kind.DUNGEON},
	"trap": {"name": "Tuzak", "cat": "Zindan / İç Mekan", "child": -1},
	"chest": {"name": "Sandık", "cat": "Zindan / İç Mekan", "child": -1},
	"altar": {"name": "Sunak", "cat": "Zindan / İç Mekan", "child": -1},
	"pillar": {"name": "Sütun", "cat": "Zindan / İç Mekan", "child": -1},
	"npc": {"name": "NPC", "cat": "Zindan / İç Mekan", "child": -1},
	"monster": {"name": "Canavar", "cat": "Zindan / İç Mekan", "child": -1},
	"table": {"name": "Masa", "cat": "Mobilya", "child": -1},
	"chair": {"name": "Sandalye", "cat": "Mobilya", "child": -1},
	"bench": {"name": "Sıra / Bank", "cat": "Mobilya", "child": -1},
	"bed": {"name": "Yatak", "cat": "Mobilya", "child": -1},
	"barrel": {"name": "Fıçı", "cat": "Mobilya", "child": -1},
	"crate": {"name": "Kasa", "cat": "Mobilya", "child": -1},
	"counter": {"name": "Tezgâh", "cat": "Mobilya", "child": -1},
	"fireplace": {"name": "Ocak / Şömine", "cat": "Mobilya", "child": -1},
	"bookshelf": {"name": "Raf / Kitaplık", "cat": "Mobilya", "child": -1},
	"rug": {"name": "Halı", "cat": "Mobilya", "child": -1},
	"throne": {"name": "Taht", "cat": "Mobilya", "child": -1},
	"banner": {"name": "Sancak", "cat": "Mobilya", "child": -1},
	"cauldron": {"name": "Kazan", "cat": "Mobilya", "child": -1},
	"weapon_rack": {"name": "Silah Rafı", "cat": "Mobilya", "child": -1},
	"plant": {"name": "Saksı Bitki", "cat": "Mobilya", "child": -1},
}

var path_order: Array = ["river", "stream", "road", "trail", "wall", "border"]
var path_types: Dictionary = {
	"river": {"name": "Nehir", "color": Color("3d7cc9"), "width": 5.0, "style": "river", "smooth": true},
	"stream": {"name": "Dere", "color": Color("4a8bd4"), "width": 2.5, "style": "river", "smooth": true},
	"road": {"name": "Yol", "color": Color("7a5230"), "width": 3.0, "style": "dash", "smooth": true},
	"trail": {"name": "Patika", "color": Color("6b4a2a"), "width": 2.0, "style": "dot", "smooth": true},
	"wall": {"name": "Sur / Duvar", "color": Color("5b5650"), "width": 7.0, "style": "wall", "smooth": false},
	"border": {"name": "Sınır Çizgisi", "color": Color("8b1e1e"), "width": 2.5, "style": "dash", "smooth": true},
}

var region_palette: Array = [
	Color("e6c229"), Color("c0392b"), Color("2e86de"), Color("27ae60"), Color("8e44ad"),
	Color("e67e22"), Color("16a085"), Color("d35400"), Color("7f8c8d"), Color("f368e0"),
]

const SYL_START := ["ar", "bel", "dor", "el", "fen", "gal", "hal", "ir", "kar", "lor", "mor",
		"nar", "or", "ral", "sar", "tor", "ul", "var", "zel", "ka", "the", "mi", "an", "ost", "vel",
		"ash", "bra", "cael", "dra", "eld", "gor", "is", "kel", "mal", "ny", "qu", "ry", "sil", "ty"]
const SYL_MID := ["a", "e", "i", "o", "an", "en", "ir", "or", "ul", "ar", "ae", "il"]
const SYL_END := ["dor", "heim", "gard", "ia", "ion", "mar", "oth", "wyn", "ra", "stan", "kale",
		"han", "grad", "ford", "mere", "vale", "rim", "ros", "thas", "nor", "dun", "fell", "ast"]


func _ready() -> void:
	water_lookup.resize(256)
	for i in terrains.size():
		water_lookup[i] = 1 if terrains[i]["water"] else 0
	var img := Image.create(256, 2, false, Image.FORMAT_RGBA8)
	for i in terrains.size():
		img.set_pixel(i, 0, terrains[i]["color"])
		img.set_pixel(i, 1, Color8(255 if terrains[i]["water"] else 0, terrain_styles[i], 0))
	terrain_palette = ImageTexture.create_from_image(img)
	font_title = _load_font("res://fonts/Cinzel.ttf", 700)
	font_text = _load_font("res://fonts/EBGaramond.ttf", 600)


## MSDF font: yakınlaştırınca bulanıklaşmaz, kenar çizgisi de keskin kalır.
func _load_font(path: String, weight: int) -> Font:
	var f := load(path) as FontFile
	if f == null:
		return ThemeDB.fallback_font
	f.multichannel_signed_distance_field = true
	f.msdf_pixel_range = 14
	f.msdf_size = 64
	var v := FontVariation.new()
	v.base_font = f
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return v


## Bu harita türündeyken bu sembolün içine girilirse açılacak harita türü (-1: girilemez)
func enter_kind(type: String, map_kind: int) -> int:
	match map_kind:
		Kind.WORLD, Kind.REGION:
			if type in SETTLEMENTS:
				return Kind.CITY
			if type in STRUCTURES:
				return Kind.BUILDING
			if type in WILDS:
				return Kind.SITE
			if type in UNDERGROUND:
				return Kind.DUNGEON
		Kind.CITY:
			if type in CITY_BUILDINGS:
				return Kind.BUILDING
			if type in ["dungeon", "well"]:
				return Kind.DUNGEON
	return -1


func is_enterable(type: String, map_kind := Kind.WORLD) -> bool:
	return enter_kind(type, map_kind) >= 0


func symbol_name(type: String) -> String:
	return symbols[type]["name"] if symbols.has(type) else type


func random_name() -> String:
	var n: String = SYL_START.pick_random()
	if randf() < 0.5:
		n += SYL_MID.pick_random()
	n += SYL_END.pick_random()
	return n.substr(0, 1).to_upper() + n.substr(1)


func swatch(color: Color, size := 16) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.08, 0.06))
	img.fill_rect(Rect2i(1, 1, size - 2, size - 2), color)
	return ImageTexture.create_from_image(img)
