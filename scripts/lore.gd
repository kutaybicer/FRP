extends Node
## Karakter dünyası verileri (autoload: Lore)
## Irklar, sınıflar, yönelimler, boyutlar ve yaratık kataloğu (bestiyer).
## Görünüm ("look") sözlüğü PortraitPainter tarafından çizilir.

const STATS := ["str", "dex", "con", "int", "wis", "cha"]
const STAT_NAMES := {"str": "Güç", "dex": "Çeviklik", "con": "Dayanıklılık", "int": "Zeka", "wis": "Bilgelik", "cha": "Karizma"}
const STAT_SHORT := {"str": "GÜÇ", "dex": "ÇEV", "con": "DAY", "int": "ZEK", "wis": "BİL", "cha": "KAR"}

const ALIGNMENTS := ["Kanuni İyi", "Tarafsız İyi", "Kaotik İyi", "Kanuni Tarafsız", "Tam Tarafsız",
		"Kaotik Tarafsız", "Kanuni Kötü", "Tarafsız Kötü", "Kaotik Kötü"]

const ROLES := {"pc": "Oyuncu Karakteri", "npc": "NPC", "creature": "Yaratık"}
const DISPOSITIONS := {"ally": "Dost", "neutral": "Tarafsız", "enemy": "Düşman"}
const DISPOSITION_COLORS := {"ally": Color("4caf50"), "neutral": Color("e0b85c"), "enemy": Color("d84a3a")}

const SIZE_ORDER := ["tiny", "small", "medium", "large", "huge", "gargantuan"]
const SIZES := {
	"tiny": {"name": "Minik", "token": 0.6},
	"small": {"name": "Küçük", "token": 0.85},
	"medium": {"name": "Orta", "token": 1.0},
	"large": {"name": "Büyük", "token": 1.5},
	"huge": {"name": "Devasa", "token": 2.1},
	"gargantuan": {"name": "Dev", "token": 2.8},
}

# Seçilebilir görünüm parçaları (editördeki açılır listeler)
const LOOK_OPTIONS := {
	"head": {"round": "Yuvarlak", "long": "Uzun", "square": "Köşeli", "broad": "Geniş"},
	"face": {"human": "İnsansı", "reptile": "Sürüngen", "cat": "Kedi", "bird": "Kuş", "bull": "Boğa", "wolf": "Kurt", "skull": "Kafatası", "troll": "Trol"},
	"ears": {"human": "Normal", "elf": "Sivri (Elf)", "elf_long": "Uzun Sivri", "short_pointed": "Hafif Sivri", "goblin": "Yarasa Kulak", "cat": "Kedi", "rabbit": "Tavşan", "cow": "Sarkık", "fin": "Yüzgeç", "none": "Yok"},
	"hair": {"none": "Kel", "short": "Kısa", "long": "Uzun", "braid": "Örgülü", "ponytail": "At Kuyruğu", "bun": "Topuz", "mohawk": "Mohikan", "wild": "Dağınık", "curly": "Kıvırcık", "flame": "Alev", "snakes": "Yılanlar", "feathers": "Tüyler", "mane": "Yele"},
	"beard": {"none": "Yok", "stubble": "Kirli Sakal", "mustache": "Bıyık", "short": "Kısa Sakal", "long": "Uzun Sakal", "braided": "Örgülü Sakal"},
	"horns": {"none": "Yok", "ram": "Koç (Kıvrık)", "straight": "Düz", "small": "Küçük", "bull": "Boğa", "antlers": "Geyik", "crest": "Diken Taç"},
	"marks": {"none": "Yok", "freckles": "Çil", "scales": "Pul", "stripes": "Çizgi", "spots": "Benek", "tattoo": "Dövme", "warpaint": "Savaş Boyası", "scar": "Yara İzi", "cracks": "Çatlak", "stitches": "Dikiş"},
	"helm": {"none": "Yok", "hood": "Kapüşon", "open": "Açık Miğfer", "full": "Kapalı Miğfer", "horned": "Boynuzlu Miğfer", "wizard": "Büyücü Şapkası", "crown": "Taç", "circlet": "Alın Bandı", "bandana": "Bandana"},
	"outfit": {"clothes": "Gündelik", "plate": "Plaka Zırh", "chain": "Zincir Zırh", "leather": "Deri Zırh", "robe": "Cübbe", "cloak": "Pelerin", "furs": "Kürk", "noble": "Soylu Kıyafet", "monk": "Keşiş Giysisi", "rags": "Paçavra", "bones": "Kemik", "none": "Çıplak"},
	"item": {"none": "Yok", "sword": "Kılıç", "greatsword": "Büyük Kılıç", "axe": "Balta", "hammer": "Savaş Çekici", "spear": "Mızrak", "bow": "Yay", "dagger": "Hançerler", "staff": "Asa", "orb": "Büyü Küresi", "book": "Büyü Kitabı", "holy": "Kutsal Sembol", "lute": "Lavta", "shield": "Kalkan", "scythe": "Tırpan"},
	"wings": {"none": "Yok", "feather": "Tüylü", "bat": "Yarasa", "fairy": "Peri"},
}

var base_look := {
	"head": "round", "face": "human", "ears": "human", "hair": "short", "beard": "none",
	"horns": "none", "marks": "none", "helm": "none", "outfit": "clothes", "item": "none", "wings": "none",
	"tusks": false, "glow_eyes": false, "halo": false, "ghost": false,
	"nose": "normal", "brow": 0.0, "build": 1.0, "head_size": 1.0,
	"skin": Color("e0ac7e"), "hair_color": Color("4a3020"), "eye_color": Color("3b6ea5"),
	"cloth": Color("6b4a2a"), "accent": Color("c9a24a"), "bg": Color("4a5a6a"),
	"mark_color": Color("2b2118"), "horn_color": Color("e8dcc0"),
}

# =============================================================== IRKLAR

const HUMAN_SKINS := ["f6d7c3", "f1c9a5", "e0ac7e", "c68642", "a0662f", "8d5524", "5c3a21"]
const NATURAL_HAIR := ["1a1410", "3b2a1a", "5a3a22", "8a5a2b", "b8862e", "d9b46a", "a33b1e", "d7d0c4"]

var races: Dictionary = {
	"human": {"name": "İnsan", "bonus": {"str": 1, "dex": 1, "con": 1, "int": 1, "wis": 1, "cha": 1},
		"desc": "Her diyara yayılmış, kısa ömürlü ama hırslı halk. Her işe uyum sağlar.",
		"look": {}, "skins": HUMAN_SKINS, "hairs": NATURAL_HAIR,
		"styles": ["short", "long", "ponytail", "braid", "curly", "bun", "none"], "beards": ["none", "none", "stubble", "short", "long", "mustache"],
		"names": [["Ar", "Bran", "Ced", "Dar", "Ed", "Gar", "Hal", "Ker", "Leo", "Mar", "Ros", "Sel", "Tom", "Vik", "Ela", "Mira", "Sena"], ["an", "ric", "win", "ton", "mund", "ard", "ia", "en", "us", "a", "ella", "ius"]]},
	"high_elf": {"name": "Yüksek Elf", "bonus": {"dex": 2, "int": 1}, "speed": 9,
		"desc": "Kadim büyü geleneğinin zarif ve uzun ömürlü bekçileri.",
		"look": {"ears": "elf_long", "head": "long", "nose": "small"}, "skins": ["f6dcc4", "efd2b5", "e8c39e", "f4e4d4"],
		"hairs": ["f2e6b8", "e8e0d0", "d9b46a", "2a2a3a", "c0c8d8"], "eyes": ["2e86c1", "48c9b0", "8e44ad", "d4ac0d"],
		"styles": ["long", "braid", "ponytail", "long"], "beards": ["none"],
		"names": [["Ae", "Cael", "Ela", "Fae", "Gal", "Ith", "Lae", "Syl", "Thal", "Ny", "Ar"], ["riel", "thas", "lith", "wyn", "ndil", "ndra", "lion", "ressa", "mir", "iel"]]},
	"wood_elf": {"name": "Orman Elfi", "bonus": {"dex": 2, "wis": 1}, "speed": 10.5,
		"desc": "Kadim ormanlarda yaşayan, okçuluğu ve sessizliğiyle bilinen elfler.",
		"look": {"ears": "elf", "head": "long", "nose": "small"}, "skins": ["d7a77a", "c08a5c", "e0b48c", "a8784e"],
		"hairs": ["5a3a22", "8a5a2b", "a33b1e", "2e4a2a", "d9b46a"], "eyes": ["229954", "7d8c3a", "8a5a2b"],
		"styles": ["long", "braid", "ponytail", "wild"], "beards": ["none"],
		"names": [["Ad", "Bry", "Ely", "Fen", "Ira", "Lir", "Nae", "Sae", "Tir"], ["ran", "wen", "dil", "aris", "eth", "lyn", "iel", "orn"]]},
	"dark_elf": {"name": "Kara Elf", "bonus": {"dex": 2, "cha": 1}, "speed": 9,
		"desc": "Yeraltı şehirlerinde yaşayan, ışığa hassas, entrikacı elfler.",
		"look": {"ears": "elf_long", "head": "long", "nose": "small", "brow": 0.3}, "skins": ["6e6a85", "5a5470", "4b4a63", "7d7894", "3e3a52"],
		"hairs": ["f4f4f4", "e0e0f0", "c8c8d8"], "eyes": ["c0392b", "e74c3c", "d4ac0d", "a569bd"],
		"styles": ["long", "ponytail", "braid", "mohawk"], "beards": ["none"],
		"names": [["Dri", "Ilv", "Mal", "Quen", "Zak", "Vie", "Shi", "Jhal"], ["zzt", "naer", "ice", "thra", "nafein", "ira", "ndra", "lyn"]]},
	"half_elf": {"name": "Yarı-Elf", "bonus": {"cha": 2, "dex": 1}, "desc": "İki dünya arasında kalmış, diplomat ruhlu gezginler.",
		"look": {"ears": "short_pointed"}, "skins": HUMAN_SKINS, "hairs": NATURAL_HAIR,
		"styles": ["long", "short", "ponytail", "braid"], "beards": ["none", "none", "stubble"],
		"names": [["Ae", "Bran", "Ela", "Gar", "Ny", "Ser", "Tav"], ["ric", "wyn", "lith", "en", "ara", "iel"]]},
	"dwarf": {"name": "Cüce", "bonus": {"con": 2, "str": 1}, "speed": 7.5,
		"desc": "Dağların derinliklerinde demir döven, inatçı ve sadık halk.",
		"look": {"head": "broad", "build": 1.25, "nose": "big", "brow": 0.35}, "skins": ["e9b896", "d49a74", "b97a57", "f1c9a5"],
		"hairs": ["a33b1e", "5a3a22", "1a1410", "8a8a8a", "d7d0c4", "b8862e"], "eyes": ["5a3a22", "3b6ea5", "6b6b6b"],
		"styles": ["short", "braid", "none", "bun"], "beards": ["long", "braided", "braided", "long"],
		"names": [["Bal", "Dur", "Gim", "Thor", "Bru", "Dag", "Kil", "Ras", "Hel"], ["in", "dek", "grim", "ak", "nar", "ga", "dis", "rak", "ra"]]},
	"halfling": {"name": "Buçukluk", "bonus": {"dex": 2, "cha": 1}, "speed": 7.5, "size": "small",
		"desc": "Küçük boylu, keyfine düşkün ama şansı yaver giden neşeli halk.",
		"look": {"build": 0.85, "head_size": 1.05, "ears": "short_pointed"}, "skins": ["f1c9a5", "e0ac7e", "c68642"],
		"hairs": ["5a3a22", "8a5a2b", "b8862e", "3b2a1a"], "styles": ["curly", "curly", "short", "long"], "beards": ["none"],
		"names": [["Bil", "Fro", "Mer", "Pip", "Ros", "Sam", "Lil", "Cora"], ["bo", "do", "ry", "pin", "ie", "wise", "lie", "fer"]]},
	"gnome": {"name": "Gnom", "bonus": {"int": 2, "con": 1}, "speed": 7.5, "size": "small",
		"desc": "Meraklı mucitler ve yaramaz illüzyonistler.",
		"look": {"build": 0.8, "head_size": 1.1, "ears": "short_pointed", "nose": "big"}, "skins": ["f6d7c3", "f1c9a5", "e0ac7e"],
		"hairs": ["f4f4f4", "e67e22", "ec7063", "48c9b0", "f4d03f"], "eyes": ["2e86c1", "8e44ad", "229954"],
		"styles": ["wild", "wild", "bun", "short"], "beards": ["none", "long", "mustache"],
		"names": [["Fizz", "Bim", "Nack", "Zook", "Tink", "Orla", "Wren"], ["wick", "ble", "le", "dle", "ka", "nottle", "fiz"]]},
	"half_orc": {"name": "Yarı-Ork", "bonus": {"str": 2, "con": 1},
		"desc": "Ork gücü ile insan iradesini taşıyan, çoğu zaman dışlanmış savaşçılar.",
		"look": {"tusks": true, "brow": 0.35, "build": 1.15, "head": "square"}, "skins": ["9fb38a", "8aa07a", "a7a985", "7e8c6a", "b5a88a"],
		"hairs": ["1a1410", "3b2a1a", "5a3a22"], "styles": ["mohawk", "short", "ponytail", "none"], "beards": ["none", "stubble"],
		"names": [["Gro", "Dench", "Hol", "Kru", "Sha", "Vol", "Ugr"], ["sk", "ag", "g", "usk", "tha", "en", "ra"]]},
	"orc": {"name": "Ork", "bonus": {"str": 2, "con": 1},
		"desc": "Klan onurunu her şeyin üstünde tutan, savaş meraklısı halk.",
		"look": {"tusks": true, "brow": 0.5, "build": 1.25, "head": "broad", "ears": "short_pointed", "nose": "big"},
		"skins": ["6f8f4e", "5d7a3f", "7a8f5a", "8a9a6b", "5e6b4c"], "hairs": ["1a1410", "3b2a1a"],
		"styles": ["mohawk", "none", "ponytail", "braid"], "beards": ["none", "none", "stubble"],
		"names": [["Gor", "Thr", "Mug", "Gul", "Bra", "Zug", "Grom"], ["ak", "ash", "grub", "nak", "mash", "ug", "rok"]]},
	"goblin": {"name": "Goblin", "bonus": {"dex": 2, "con": 1}, "size": "small",
		"desc": "Küçük, kurnaz ve çoğu zaman sinsi. Kalabalık olunca tehlikeli.",
		"look": {"ears": "goblin", "nose": "long", "build": 0.75, "head_size": 1.1, "head": "broad", "brow": 0.3},
		"skins": ["7c9a3a", "8fae4a", "6b8a35", "a3a845"], "hairs": ["1a1410", "3b2a1a"], "eyes": ["d4ac0d", "c0392b", "e67e22"],
		"styles": ["none", "wild", "none"], "beards": ["none"],
		"names": [["Sni", "Grik", "Nob", "Ziz", "Krag", "Rik"], ["k", "tch", "bit", "zle", "nik", "ret"]]},
	"hobgoblin": {"name": "Hobgoblin", "bonus": {"con": 2, "int": 1},
		"desc": "Disiplinli ordular kuran, askerî düzene tutkun goblinsiler.",
		"look": {"ears": "short_pointed", "nose": "big", "brow": 0.45, "head": "square"},
		"skins": ["c0662f", "b85a2a", "a84f27", "d0743a"], "hairs": ["1a1410", "3b2a1a"], "eyes": ["d4ac0d", "e67e22"],
		"styles": ["ponytail", "short", "none"], "beards": ["none"],
		"names": [["Kru", "Vor", "Mak", "Dra", "Kel"], ["gan", "rok", "thul", "ka", "esh"]]},
	"kobold": {"name": "Kobold", "bonus": {"dex": 2}, "size": "small",
		"desc": "Ejderhalara tapan küçük sürüngenler. Tuzak ustası.",
		"look": {"face": "reptile", "ears": "none", "marks": "scales", "build": 0.75, "horns": "small"},
		"skins": ["b5562b", "8a4b2b", "6b6b6b", "a58b3c", "5d6d7e"], "hairs": ["1a1410"], "eyes": ["d4ac0d", "e67e22"],
		"styles": ["none"], "beards": ["none"],
		"names": [["Kib", "Mee", "Snek", "Pok", "Yip"], ["ik", "pa", "ka", "sik", "lo"]]},
	"tiefling": {"name": "Şeytansoyu", "bonus": {"cha": 2, "int": 1},
		"desc": "Damarlarında cehennem kanı taşıyan, boynuzlu ve kuyruklu soy.",
		"look": {"horns": "ram", "ears": "short_pointed", "glow_eyes": false, "horn_color": Color("3a2a2a")},
		"skins": ["c0392b", "a83232", "7d3c98", "d98880", "8e44ad", "b03a5a"], "hairs": ["1a1410", "3b1a3a", "6c3483", "922b21"],
		"eyes": ["d4ac0d", "f5f5f5", "e74c3c"], "styles": ["long", "short", "ponytail", "wild"], "beards": ["none", "none", "short"],
		"names": [["Az", "Ka", "Mor", "Zar", "Ny", "Lev", "Dam"], ["azel", "riel", "thos", "akos", "ia", "eth", "ira"]]},
	"dragonborn": {"name": "Ejderdoğan", "bonus": {"str": 2, "cha": 1},
		"desc": "Ejderha atalarının nefesini taşıyan, onurlu pullu savaşçılar.",
		"look": {"face": "reptile", "ears": "none", "horns": "crest", "marks": "scales", "head": "long", "build": 1.2, "horn_color": Color("d8c8a0")},
		"skins": ["b03a2e", "2e86c1", "229954", "b7950b", "95a5a6", "34495e", "ca6f1e", "a04000"], "hairs": ["1a1410"], "eyes": ["d4ac0d", "e67e22", "c0392b"],
		"styles": ["none"], "beards": ["none"],
		"names": [["Arj", "Bal", "Kri", "Med", "Nad", "Rho", "Sor"], ["han", "asar", "v", "rash", "arr", "gar", "a"]]},
	"aasimar": {"name": "Göksoylu", "bonus": {"cha": 2, "wis": 1},
		"desc": "Göksel varlıkların soyundan gelen, ışık saçan koruyucular.",
		"look": {"halo": true, "glow_eyes": true, "eye_color": Color("f7dc6f")}, "skins": ["f6e3c8", "e8c9a4", "c9a27e", "a0785a"],
		"hairs": ["f2e6b8", "f4f4f4", "d9b46a", "a33b1e"], "eyes": ["f7dc6f", "aed6f1"], "styles": ["long", "short", "braid"], "beards": ["none", "short"],
		"names": [["Ael", "Lum", "Ser", "Ori", "Cel"], ["iel", "ara", "aphine", "on", "estia"]]},
	"goliath": {"name": "Dağ Devi Soyu", "bonus": {"str": 2, "con": 1}, "size": "medium",
		"desc": "Karlı zirvelerde yaşayan, devlerle akraba iri yarı halk.",
		"look": {"hair": "none", "marks": "tattoo", "build": 1.35, "head": "square", "brow": 0.3, "mark_color": Color("2c3e50")},
		"skins": ["9a9fa5", "8b9096", "a9a39b", "7f8c8d"], "hairs": ["1a1410"], "styles": ["none", "none", "short"], "beards": ["none"],
		"names": [["Aug", "Gae", "Kav", "Ilik", "Thal", "Vau"], ["ath", "al", "ak", "aga", "ai", "nu"]]},
	"feline": {"name": "Kedi Halkı", "bonus": {"dex": 2, "cha": 1}, "speed": 9,
		"desc": "Meraklı, çevik ve gezgin kedi insanlar.",
		"look": {"face": "cat", "ears": "cat", "marks": "stripes", "hair": "none", "mark_color": Color("3b2a1a")},
		"skins": ["d9a05b", "b97a3a", "e8d3b0", "6b6b6b", "c48a3a", "f2f0ea", "3a3a3a"], "hairs": ["3b2a1a"], "eyes": ["229954", "d4ac0d", "2e86c1"],
		"styles": ["none", "mane"], "beards": ["none"],
		"names": [["Five", "Cloud", "Jade", "Sun", "Sha", "Mew", "Rin"], [" Bulut", " Gölge", "ko", "rr", "mi", "a"]]},
	"lizardfolk": {"name": "Kertenkele Halkı", "bonus": {"con": 2, "wis": 1},
		"desc": "Bataklıkların soğukkanlı, pratik avcıları.",
		"look": {"face": "reptile", "ears": "none", "horns": "crest", "marks": "scales", "horn_color": Color("c0392b")},
		"skins": ["5e8c4a", "4a7a5a", "7a8f3a", "3f6b5b", "6b8e23"], "hairs": ["1a1410"], "eyes": ["d4ac0d", "e67e22"], "styles": ["none"], "beards": ["none"],
		"names": [["Hiss", "Sak", "Tha", "Ssi", "Kro"], ["ka", "ss", "rak", "ith", "tar"]]},
	"birdfolk": {"name": "Kuş Halkı", "bonus": {"dex": 2, "wis": 1},
		"desc": "Yüksek kayalıklarda yaşayan, kanatlı gökyüzü halkı.",
		"look": {"face": "bird", "ears": "none", "hair": "feathers", "wings": "feather"},
		"skins": ["8b5a2b", "3b3b3b", "c0392b", "2e86c1", "d4ac0d", "f2f0ea"], "hairs": ["5a3a22", "1a1410", "f2f0ea", "c0392b"], "eyes": ["d4ac0d", "1a1410"],
		"styles": ["feathers"], "beards": ["none"],
		"names": [["Ki", "Ree", "Aer", "Sky", "Tor"], ["ree", "kaa", "wyn", "ak", "lia"]]},
	"minotaur": {"name": "Minotor", "bonus": {"str": 2, "con": 1}, "size": "medium",
		"desc": "Boğa başlı, labirentlerin efendisi güçlü savaşçılar.",
		"look": {"face": "bull", "ears": "cow", "horns": "bull", "hair": "none", "build": 1.35, "head": "broad", "brow": 0.4},
		"skins": ["6e4b3a", "4a3428", "8b6b4a", "2b2420", "a08060"], "hairs": ["1a1410"], "eyes": ["1a1410", "c0392b"], "styles": ["none", "mane"], "beards": ["none"],
		"names": [["Ast", "Mor", "Bo", "Ter", "Kra"], ["erion", "gath", "rus", "ok", "ul"]]},
	"centaur": {"name": "Sentor", "bonus": {"str": 2, "wis": 1}, "speed": 12,
		"desc": "Belden aşağısı at olan, bozkırların özgür avcıları.",
		"look": {"ears": "short_pointed", "build": 1.15}, "skins": HUMAN_SKINS, "hairs": NATURAL_HAIR,
		"styles": ["long", "braid", "wild", "ponytail"], "beards": ["none", "long", "short"],
		"names": [["Chi", "Fir", "Nes", "Hyl", "Pho"], ["ron", "enze", "sus", "onome", "lus"]]},
	"firbolg": {"name": "Orman Devi Soyu", "bonus": {"wis": 2, "str": 1},
		"desc": "Ormanların utangaç ve iri koruyucuları.",
		"look": {"ears": "cow", "nose": "big", "build": 1.3, "head": "broad"}, "skins": ["8fa3b8", "9bb0a5", "a7b3c4", "b0a0c8"],
		"hairs": ["a33b1e", "5a3a22", "d7d0c4", "8a5a2b"], "styles": ["braid", "long", "wild"], "beards": ["long", "braided", "none"],
		"names": [["Bor", "Fal", "Mos", "Ol", "Thu"], ["um", "wen", "ra", "dok", "il"]]},
	"genasi": {"name": "Elementsoyu", "bonus": {"con": 2, "int": 1},
		"desc": "Element güçlerini kanında taşıyan; ateş, su, toprak ya da hava soyundan.",
		"look": {"hair": "flame", "glow_eyes": true, "marks": "cracks", "mark_color": Color("f39c12")},
		"skins": ["d35400", "c0392b", "2e86c1", "48c9b0", "8d6e63", "aed6f1"], "hairs": ["f39c12", "5dade2", "f4f4f4", "6d4c41"], "eyes": ["f7dc6f", "aed6f1"],
		"styles": ["flame", "wild", "long", "none"], "beards": ["none"],
		"names": [["Ign", "Aqu", "Ter", "Zeph", "Pyr", "Mar"], ["is", "a", "ra", "yr", "os", "ina"]]},
	"merfolk": {"name": "Deniz Halkı", "bonus": {"str": 1, "con": 1, "cha": 1},
		"desc": "Okyanus derinliklerinin muhafızları, yüzgeç kulaklı soylu halk.",
		"look": {"ears": "fin", "marks": "scales"}, "skins": ["5dade2", "48c9b0", "76d7c4", "85c1e9", "a9cce3"],
		"hairs": ["1f618d", "117a65", "f4f4f4", "2c3e50"], "eyes": ["f4f4f4", "1abc9c"], "styles": ["long", "wild", "braid"], "beards": ["none"],
		"names": [["Cor", "Mar", "Nep", "Thal", "Ond"], ["alis", "ina", "tun", "assa", "ine"]]},
	"harengon": {"name": "Tavşan Halkı", "bonus": {"dex": 2, "wis": 1}, "size": "small",
		"desc": "Hızlı refleksli, şanslı ve huzursuz gezginler.",
		"look": {"face": "cat", "ears": "rabbit", "hair": "none", "build": 0.85}, "skins": ["e8dcc8", "c8a882", "8b6b4a", "f2f2f2", "9a9a9a"],
		"hairs": ["3b2a1a"], "eyes": ["5a3a22", "1a1410", "c0392b"], "styles": ["none"], "beards": ["none"],
		"names": [["Hop", "Clo", "Bun", "Pip", "Ash"], ["per", "ver", "ny", "kin", "ley"]]},
}

# =============================================================== SINIFLAR

var classes: Dictionary = {
	"fighter": {"name": "Savaşçı", "hd": 10, "ac": 16, "prim": ["str", "con"], "outfit": "plate", "item": "sword",
		"cloth": ["8a9199", "6b7682"], "accent": ["c0392b", "2e86c1", "c9a24a"], "bg": "4a5a6a", "helms": ["none", "none", "open"]},
	"barbarian": {"name": "Barbar", "hd": 12, "ac": 13, "prim": ["str", "con"], "outfit": "furs", "item": "axe",
		"cloth": ["7a5230", "5e3b1f"], "accent": ["d9cbb0", "8a8a8a"], "bg": "6a4a3a", "helms": ["none", "none", "horned"]},
	"paladin": {"name": "Paladin", "hd": 10, "ac": 18, "prim": ["str", "cha"], "outfit": "plate", "item": "hammer",
		"cloth": ["d8d8d8", "b8c0c8"], "accent": ["e8c25a", "f4f4f4"], "bg": "6a6a4a", "helms": ["none", "open", "full"]},
	"ranger": {"name": "Korucu", "hd": 10, "ac": 14, "prim": ["dex", "wis"], "outfit": "leather", "item": "bow",
		"cloth": ["4a6b3a", "5e4a2a"], "accent": ["8a5a2b", "2e4a2a"], "bg": "3a5a3a", "helms": ["none", "hood", "hood"]},
	"rogue": {"name": "Hırsız", "hd": 8, "ac": 14, "prim": ["dex", "int"], "outfit": "leather", "item": "dagger",
		"cloth": ["2b2b30", "3a2a2a"], "accent": ["6b2a2a", "4a4a5a"], "bg": "2a2a3a", "helms": ["hood", "hood", "none", "bandana"]},
	"wizard": {"name": "Büyücü", "hd": 6, "ac": 12, "prim": ["int", "con"], "outfit": "robe", "item": "staff",
		"cloth": ["2e4a8a", "4a2e6b", "6b2e2e"], "accent": ["e8c25a", "d8d8d8"], "bg": "2e3a5a", "helms": ["none", "wizard", "wizard"]},
	"sorcerer": {"name": "Sihirbaz", "hd": 6, "ac": 12, "prim": ["cha", "con"], "outfit": "robe", "item": "orb",
		"cloth": ["8a2e4a", "2e6b6b", "6b2e8a"], "accent": ["e8c25a", "48c9b0"], "bg": "4a2e5a", "helms": ["none", "circlet"]},
	"warlock": {"name": "Ahitli", "hd": 8, "ac": 13, "prim": ["cha", "con"], "outfit": "cloak", "item": "book",
		"cloth": ["2a1a2a", "1a1a2a"], "accent": ["8e44ad", "27ae60"], "bg": "2a1a3a", "helms": ["none", "hood"]},
	"cleric": {"name": "Rahip", "hd": 8, "ac": 16, "prim": ["wis", "con"], "outfit": "chain", "item": "holy",
		"cloth": ["f2ead7", "d8d0c0"], "accent": ["e8c25a", "c0392b"], "bg": "6a5a3a", "helms": ["none", "none", "circlet"]},
	"druid": {"name": "Druid", "hd": 8, "ac": 13, "prim": ["wis", "con"], "outfit": "robe", "item": "staff",
		"cloth": ["3a5a2a", "5a4a2a"], "accent": ["8fbf5a", "a0785a"], "bg": "2e4a2a", "helms": ["none", "circlet", "hood"]},
	"bard": {"name": "Ozan", "hd": 8, "ac": 13, "prim": ["cha", "dex"], "outfit": "noble", "item": "lute",
		"cloth": ["a83232", "2e6b8a", "8a6b2e"], "accent": ["e8c25a", "f2ead7"], "bg": "5a2e3a", "helms": ["none", "none", "bandana"]},
	"monk": {"name": "Keşiş", "hd": 8, "ac": 15, "prim": ["dex", "wis"], "outfit": "monk", "item": "none",
		"cloth": ["e67e22", "c0392b", "d4ac0d"], "accent": ["5e3b1f", "2b2118"], "bg": "6a4a2a", "helms": ["none"]},
	"artificer": {"name": "Mucit", "hd": 8, "ac": 15, "prim": ["int", "con"], "outfit": "leather", "item": "hammer",
		"cloth": ["6b4a2a", "4a4a4a"], "accent": ["c9a24a", "b87333"], "bg": "4a3a2a", "helms": ["none", "bandana"]},
	"commoner": {"name": "Köylü", "hd": 6, "ac": 10, "prim": ["con", "wis"], "outfit": "clothes", "item": "none", "npc": true,
		"cloth": ["8a7a5a", "6b5a4a", "7a6a4a"], "accent": ["5e3b1f"], "bg": "5a5040", "helms": ["none", "none", "bandana"]},
	"merchant": {"name": "Tüccar", "hd": 6, "ac": 10, "prim": ["cha", "int"], "outfit": "noble", "item": "none", "npc": true,
		"cloth": ["6b2e4a", "2e4a6b", "4a6b2e"], "accent": ["e8c25a"], "bg": "5a4a2a", "helms": ["none"]},
	"noble": {"name": "Soylu", "hd": 8, "ac": 12, "prim": ["cha", "int"], "outfit": "noble", "item": "none", "npc": true,
		"cloth": ["5a1a2a", "1a2a5a", "2a2a2a"], "accent": ["e8c25a", "d8d8d8"], "bg": "4a2a3a", "helms": ["crown", "circlet", "none"]},
	"guard": {"name": "Muhafız", "hd": 10, "ac": 16, "prim": ["str", "con"], "outfit": "chain", "item": "spear", "npc": true,
		"cloth": ["8a9199"], "accent": ["c0392b", "2e86c1"], "bg": "4a4a4a", "helms": ["open", "open", "none"]},
}

# =============================================================== YARATIKLAR
# Her kayıt: [ad, kategori, boyut, tehlike, can, zırh, hız(m), [güç,çev,day,zek,bil,kar], saldırılar, çizim]

const CREATURE_CATS := ["Hayvanlar", "Kuşlar", "Deniz Canlıları", "Böcekler ve Sürüngenler", "Ejderhalar", "Fantastik Yaratıklar", "Canavarlar", "Ölümsüzler", "Elementaller ve Yapılar", "İnsansılar"]

var creatures: Dictionary = {}

func _def_creatures() -> void:
	var A := "Hayvanlar"
	var B := "Kuşlar"
	var S := "Deniz Canlıları"
	var R := "Böcekler ve Sürüngenler"
	var D := "Ejderhalar"
	var F := "Fantastik Yaratıklar"
	var M := "Canavarlar"
	var U := "Ölümsüzler"
	var E := "Elementaller ve Yapılar"
	var H := "İnsansılar"
	# --- Hayvanlar
	_c("wolf", "Kurt", A, "medium", "1/4", 11, 13, 12, [12, 15, 12, 3, 12, 6], "Isırık: +4, 2d4+2 delici; hedef yere düşebilir. Sürü taktiği.",
		{"body": "quad", "head": "canine", "col": "7d7d80", "col2": "c8c4bc", "tail": "bushy"})
	_c("dire_wolf", "Dev Kurt", A, "large", "1", 37, 14, 15, [17, 15, 15, 3, 12, 7], "Isırık: +5, 2d6+3 delici; yere düşürme.",
		{"body": "quad", "head": "canine", "col": "3f3f45", "col2": "7a7a80", "tail": "bushy", "len": 1.1, "eye": "d4ac0d"})
	_c("fox", "Tilki", A, "tiny", "0", 3, 13, 12, [3, 16, 11, 3, 12, 6], "Isırık: +5, 1 delici.",
		{"body": "quad", "head": "canine", "col": "d35400", "col2": "f2ead7", "tail": "bushy", "leg": 0.8, "ears": "big"})
	_c("dog", "Köpek", A, "small", "1/8", 5, 12, 12, [13, 14, 12, 3, 12, 7], "Isırık: +3, 1d6+1 delici.",
		{"body": "quad", "head": "canine", "col": "a0785a", "col2": "e8dcc8", "tail": "thin", "ears": "floppy"})
	_c("mastiff", "Savaş Köpeği", A, "medium", "1/8", 5, 12, 12, [13, 14, 12, 3, 12, 7], "Isırık: +3, 1d6+1; yere düşürme.",
		{"body": "quad", "head": "canine", "col": "4a3a2a", "col2": "8a6a4a", "tail": "thin", "ears": "floppy", "len": 1.05, "collar": true})
	_c("black_bear", "Kara Ayı", A, "medium", "1/2", 19, 11, 12, [15, 10, 14, 2, 12, 7], "Çoklu saldırı: Isırık 1d6+2, Pençe 2d4+2.",
		{"body": "quad", "head": "ursine", "col": "2b2420", "col2": "5a4a3a", "tail": "short", "legs": "thick", "len": 1.0, "h": 1.2})
	_c("brown_bear", "Boz Ayı", A, "large", "1", 34, 11, 12, [19, 10, 16, 2, 13, 7], "Isırık 1d8+4, Pençe 2d6+4.",
		{"body": "quad", "head": "ursine", "col": "6b4a2a", "col2": "8a6a4a", "tail": "short", "legs": "thick", "h": 1.25, "hump": true})
	_c("polar_bear", "Kutup Ayısı", A, "large", "2", 42, 12, 12, [20, 10, 16, 2, 13, 7], "Isırık 1d8+5, Pençe 2d6+5.",
		{"body": "quad", "head": "ursine", "col": "eeeae0", "col2": "d0ccc0", "tail": "short", "legs": "thick", "h": 1.2})
	_c("deer", "Geyik", A, "medium", "0", 4, 13, 15, [11, 16, 11, 2, 14, 5], "Isırık: +2, 1d4 delici.",
		{"body": "quad", "head": "deer", "col": "a0703a", "col2": "e8d8b8", "tail": "short", "horns": "antlers", "leg": 1.2, "neck": 0.8, "spots": false})
	_c("elk", "Kızıl Geyik", A, "large", "1/4", 13, 10, 15, [16, 10, 12, 2, 10, 6], "Toslama 1d6+3, Toynak 2d4+3.",
		{"body": "quad", "head": "deer", "col": "7a4a2a", "col2": "c8a882", "tail": "short", "horns": "antlers", "leg": 1.2, "neck": 0.8, "len": 1.1})
	_c("horse", "At", A, "large", "1/4", 13, 10, 18, [16, 10, 12, 2, 11, 7], "Toynak: +5, 2d4+3 ezici.",
		{"body": "quad", "head": "equine", "col": "7a4a2a", "col2": "6a3a1a", "tail": "horse", "mane": true, "leg": 1.25, "neck": 0.9})
	_c("warhorse", "Savaş Atı", A, "large", "1/2", 19, 11, 18, [18, 12, 13, 2, 12, 7], "Toynak 2d6+4; çiğneme hücumu.",
		{"body": "quad", "head": "equine", "col": "2b2420", "col2": "1a1410", "tail": "horse", "mane": true, "leg": 1.25, "neck": 0.9, "barding": true})
	_c("pony", "Midilli", A, "medium", "1/8", 11, 10, 12, [15, 10, 13, 2, 11, 7], "Toynak: +4, 2d4+2.",
		{"body": "quad", "head": "equine", "col": "c8a882", "col2": "f2ead7", "tail": "horse", "mane": true, "leg": 0.9, "neck": 0.7})
	_c("donkey", "Eşek", A, "medium", "1/8", 11, 10, 12, [14, 10, 13, 2, 10, 5], "Toynak: +4, 1d4+2.",
		{"body": "quad", "head": "equine", "col": "8a8580", "col2": "d8d4cc", "tail": "tuft", "ears": "long", "leg": 0.95, "neck": 0.6})
	_c("cow", "İnek", A, "large", "1/4", 15, 10, 9, [18, 9, 14, 2, 10, 4], "Toslama: +6, 1d6+4.",
		{"body": "quad", "head": "bovine", "col": "f2f0ea", "col2": "2b2420", "tail": "tuft", "horns": "small", "pattern": "patches", "h": 1.15})
	_c("bull", "Boğa", A, "large", "1/4", 15, 10, 12, [18, 9, 14, 2, 10, 4], "Toslama 1d6+4; hücum.",
		{"body": "quad", "head": "bovine", "col": "3a2a20", "col2": "5a4030", "tail": "tuft", "horns": "bull", "h": 1.2, "hump": true})
	_c("goat", "Keçi", A, "medium", "0", 4, 10, 12, [12, 10, 11, 2, 10, 5], "Toslama: +3, 1d4+1.",
		{"body": "quad", "head": "goat", "col": "d8d0c0", "col2": "a09080", "tail": "short", "horns": "goat", "beard": true, "len": 0.85})
	_c("sheep", "Koyun", A, "medium", "0", 4, 10, 9, [11, 10, 11, 2, 10, 5], "Toslama: +2, 1d4.",
		{"body": "quad", "head": "goat", "col": "f2ede0", "col2": "2b2420", "tail": "short", "wool": true, "len": 0.9, "leg": 0.75})
	_c("ram", "Koç", A, "medium", "1/8", 11, 10, 12, [14, 10, 12, 2, 10, 5], "Toslama 1d6+2; yere düşürme.",
		{"body": "quad", "head": "goat", "col": "e8e0d0", "col2": "4a3a2a", "tail": "short", "wool": true, "horns": "ram", "len": 0.9, "leg": 0.8})
	_c("pig", "Domuz", A, "medium", "0", 6, 10, 12, [12, 9, 12, 2, 9, 4], "Toslama: +3, 1d4+1.",
		{"body": "quad", "head": "boar", "col": "f0b8b0", "col2": "e09a90", "tail": "curl", "leg": 0.6, "h": 1.1, "ears": "floppy"})
	_c("boar", "Yaban Domuzu", A, "medium", "1/4", 11, 11, 12, [13, 11, 12, 2, 9, 5], "Diş: +3, 1d6+1; hücum.",
		{"body": "quad", "head": "boar", "col": "4a3a30", "col2": "6b5a4a", "tail": "thin", "leg": 0.65, "h": 1.15, "tusks": true, "hump": true, "bristle": true})
	_c("cat", "Kedi", A, "tiny", "0", 2, 12, 12, [3, 15, 10, 3, 12, 7], "Pençe: +0, 1 kesici.",
		{"body": "quad", "head": "feline", "col": "e67e22", "col2": "f2ead7", "tail": "long", "pattern": "stripes", "len": 0.85})
	_c("lion", "Aslan", A, "large", "1", 26, 12, 15, [17, 15, 13, 3, 12, 8], "Isırık 1d8+3, Pençe 1d6+3; atılma.",
		{"body": "quad", "head": "feline", "col": "c8a050", "col2": "e8d0a0", "tail": "tuft", "mane": true, "mane_col": "7a4a1a", "len": 1.05})
	_c("tiger", "Kaplan", A, "large", "1", 37, 12, 12, [17, 15, 14, 3, 12, 8], "Isırık 1d10+3, Pençe 1d8+3; atılma.",
		{"body": "quad", "head": "feline", "col": "e67e22", "col2": "f2ead7", "tail": "long", "pattern": "stripes", "len": 1.1})
	_c("panther", "Panter", A, "medium", "1/4", 13, 12, 15, [14, 15, 10, 3, 14, 7], "Isırık 1d6+2, Pençe 1d4+2; atılma.",
		{"body": "quad", "head": "feline", "col": "1e1e24", "col2": "2b2b33", "tail": "long", "eye": "d4ac0d", "len": 1.05})
	_c("leopard", "Leopar", A, "medium", "1/4", 13, 12, 15, [14, 15, 10, 3, 14, 7], "Isırık 1d6+2, Pençe 1d4+2.",
		{"body": "quad", "head": "feline", "col": "d9a85a", "col2": "f2e6c8", "tail": "long", "pattern": "spots"})
	_c("lynx", "Vaşak", A, "small", "1/8", 7, 12, 12, [10, 16, 11, 3, 13, 6], "Pençe: +5, 1d4+3.",
		{"body": "quad", "head": "feline", "col": "b89a70", "col2": "e8dcc8", "tail": "short", "ears": "tufted", "pattern": "spots"})
	_c("rabbit", "Tavşan", A, "tiny", "0", 1, 13, 15, [2, 16, 9, 2, 12, 5], "Kaçar. Saldırmaz.",
		{"body": "quad", "head": "rodent", "col": "a08060", "col2": "f2ead7", "tail": "puff", "ears": "rabbit", "leg": 0.7, "len": 0.8})
	_c("rat", "Sıçan", A, "tiny", "0", 1, 10, 6, [2, 11, 9, 2, 10, 4], "Isırık: +0, 1 delici.",
		{"body": "quad", "head": "rodent", "col": "6b6560", "col2": "a09a90", "tail": "rat", "leg": 0.5, "len": 0.9, "ears": "round"})
	_c("giant_rat", "Dev Sıçan", A, "small", "1/8", 7, 12, 9, [7, 15, 11, 2, 10, 4], "Isırık: +4, 1d4+2. Sürü taktiği.",
		{"body": "quad", "head": "rodent", "col": "4a4440", "col2": "7a7068", "tail": "rat", "leg": 0.55, "ears": "round", "eye": "c0392b"})
	_c("squirrel", "Sincap", A, "tiny", "0", 1, 13, 9, [2, 16, 9, 2, 12, 4], "Isırık: 1 delici.",
		{"body": "quad", "head": "rodent", "col": "b85a2a", "col2": "f2ead7", "tail": "squirrel", "leg": 0.6, "len": 0.75})
	_c("badger", "Porsuk", A, "tiny", "0", 3, 10, 6, [4, 11, 12, 2, 12, 5], "Isırık: +2, 1 delici.",
		{"body": "quad", "head": "canine", "col": "6b6b6b", "col2": "2b2b2b", "tail": "short", "leg": 0.5, "snout": 0.7, "ears": "round", "face_stripe": true})
	_c("camel", "Deve", A, "large", "1/8", 15, 9, 15, [16, 8, 14, 2, 8, 5], "Isırık: +5, 1d4.",
		{"body": "quad", "head": "equine", "col": "c8a070", "col2": "e0c8a0", "tail": "tuft", "hump": true, "humps": 2, "leg": 1.3, "neck": 1.0, "ears": "small"})
	_c("elephant", "Fil", A, "huge", "4", 76, 12, 12, [22, 9, 17, 3, 11, 6], "Diş 3d8+6, Çiğneme 3d10+6.",
		{"body": "quad", "head": "elephant", "col": "8a8a90", "col2": "707078", "tail": "thin", "legs": "pillar", "h": 1.35, "tusks": true})
	_c("mammoth", "Mamut", A, "huge", "6", 126, 13, 12, [24, 9, 21, 3, 11, 6], "Diş 4d8+7, Çiğneme 4d10+7.",
		{"body": "quad", "head": "elephant", "col": "6b4a2a", "col2": "4a3220", "tail": "thin", "legs": "pillar", "h": 1.4, "tusks": true, "wool": true, "hump": true})
	_c("rhino", "Gergedan", A, "large", "2", 45, 11, 12, [21, 8, 15, 2, 12, 6], "Boynuz: +7, 2d8+5; hücum.",
		{"body": "quad", "head": "rhino", "col": "8a8580", "col2": "6b6560", "tail": "thin", "legs": "pillar", "horns": "rhino", "h": 1.15})
	_c("ape", "Goril", A, "medium", "1/2", 19, 12, 9, [16, 14, 14, 6, 12, 7], "Yumruk x2: +5, 1d6+3.",
		{"body": "bust", "face": "ape", "ears": "human", "hair": "none", "skin": "3a3530", "outfit": "none", "build": 1.3, "fur": true, "bg": "3a4a2a"})
	# --- Kuşlar
	_c("eagle", "Kartal", B, "small", "0", 3, 12, 3, [6, 15, 10, 2, 14, 7], "Pençe: +4, 1d4+2. Keskin göz.",
		{"body": "bird", "col": "5a3a20", "col2": "f2f0ea", "col3": "e8b923", "beak": "hook", "head_col": "f2f0ea", "wing": "spread"})
	_c("giant_eagle", "Dev Kartal", B, "large", "1", 26, 13, 24, [16, 17, 13, 8, 14, 10], "Gaga 1d6+3, Pençe 2d6+3.",
		{"body": "bird", "col": "6b4a2a", "col2": "c8a070", "col3": "e8b923", "beak": "hook", "head_col": "f2ead7", "wing": "spread"})
	_c("hawk", "Şahin", B, "tiny", "0", 1, 13, 18, [5, 16, 8, 2, 14, 6], "Pençe: +5, 1 kesici.",
		{"body": "bird", "col": "8a6040", "col2": "e8d8c0", "col3": "e8b923", "beak": "hook", "pattern": "bars"})
	_c("owl", "Baykuş", B, "tiny", "0", 1, 11, 18, [3, 13, 8, 2, 12, 7], "Pençe: +3, 1 kesici. Sessiz uçuş.",
		{"body": "bird", "shape": "owl", "col": "8a6a4a", "col2": "d8c8a8", "col3": "4a3a2a", "beak": "short", "eye": "f39c12"})
	_c("raven", "Kuzgun", B, "tiny", "0", 1, 12, 15, [2, 14, 8, 2, 12, 6], "Gaga: +4, 1 delici. Taklit.",
		{"body": "bird", "col": "1e1e28", "col2": "2b2b38", "col3": "2b2b30", "beak": "long", "sheen": true})
	_c("crow", "Karga", B, "tiny", "0", 1, 12, 15, [2, 14, 8, 2, 12, 6], "Gaga: +4, 1 delici.",
		{"body": "bird", "col": "2b2b30", "col2": "6b6b70", "col3": "2b2b30", "beak": "long"})
	_c("parrot", "Papağan", B, "tiny", "0", 1, 12, 15, [2, 14, 8, 3, 12, 8], "Gaga: 1 delici. Konuşur.",
		{"body": "bird", "col": "27ae60", "col2": "f1c40f", "col3": "2b2b30", "beak": "parrot", "head_col": "c0392b", "tail": "long", "wing_col": "2e86c1"})
	_c("chicken", "Tavuk", B, "tiny", "0", 1, 10, 6, [2, 10, 9, 1, 9, 3], "Gaga: 1 delici.",
		{"body": "bird", "shape": "fowl", "col": "f2ead7", "col2": "e8dcc8", "col3": "e8b923", "beak": "short", "comb": true})
	_c("rooster", "Horoz", B, "tiny", "0", 1, 10, 6, [3, 10, 9, 1, 9, 5], "Gaga ve mahmuz: 1 delici.",
		{"body": "bird", "shape": "fowl", "col": "b85a2a", "col2": "2b2b30", "col3": "e8b923", "beak": "short", "comb": true, "tail": "rooster", "head_col": "e67e22"})
	_c("duck", "Ördek", B, "tiny", "0", 1, 10, 6, [2, 10, 9, 1, 9, 4], "Gaga: 1 ezici.",
		{"body": "bird", "shape": "water", "col": "8a7a60", "col2": "c8b898", "col3": "e8a020", "beak": "flat", "head_col": "1e7a4a"})
	_c("swan", "Kuğu", B, "small", "0", 3, 11, 6, [5, 11, 10, 2, 10, 6], "Kanat darbesi: 1d4.",
		{"body": "bird", "shape": "water", "col": "f8f8f8", "col2": "e8e8e8", "col3": "e67e22", "beak": "flat", "neck": "long"})
	_c("vulture", "Akbaba", B, "medium", "0", 5, 10, 15, [7, 10, 13, 2, 12, 4], "Gaga: +2, 2d4 delici.",
		{"body": "bird", "col": "3a3028", "col2": "5a4a3a", "col3": "c8b8a0", "beak": "hook", "head_col": "e0a0a0", "ruff": true})
	_c("bat", "Yarasa", B, "tiny", "0", 1, 12, 9, [2, 15, 8, 2, 12, 4], "Isırık: +0, 1 delici. Ekolokasyon.",
		{"body": "bat", "col": "3a3030", "col2": "5a4a48"})
	_c("giant_bat", "Dev Yarasa", B, "large", "1/4", 22, 13, 18, [15, 16, 11, 2, 12, 6], "Isırık: +4, 1d6+2.",
		{"body": "bat", "col": "2b2424", "col2": "4a3a38", "eye": "c0392b"})
	# --- Deniz canlıları
	_c("fish", "Balık", S, "tiny", "0", 1, 13, 12, [2, 16, 9, 1, 7, 2], "Su altında nefes alır.",
		{"body": "fish", "shape": "fish", "col": "e67e22", "col2": "f2ead7"})
	_c("shark", "Köpekbalığı", S, "large", "2", 45, 12, 12, [18, 13, 15, 1, 10, 4], "Isırık: +6, 2d8+4. Kan çılgınlığı.",
		{"body": "fish", "shape": "shark", "col": "6b7a8a", "col2": "e8ecf0"})
	_c("whale", "Balina", S, "gargantuan", "8", 90, 12, 18, [26, 8, 20, 3, 12, 5], "Kuyruk 4d10+8; yutma.",
		{"body": "fish", "shape": "whale", "col": "3a4a6a", "col2": "c8d0d8"})
	_c("dolphin", "Yunus", S, "medium", "1/8", 11, 12, 18, [14, 13, 13, 6, 12, 7], "Toslama: +4, 1d6+2.",
		{"body": "fish", "shape": "dolphin", "col": "7a8a9a", "col2": "e8ecf0"})
	_c("eel", "Yılan Balığı", S, "medium", "1/2", 22, 12, 9, [16, 12, 13, 1, 10, 3], "Isırık 1d8+3; elektrik şoku.",
		{"body": "serpent", "col": "4a5a3a", "col2": "c8c070", "fins": true, "water": true})
	_c("octopus", "Ahtapot", S, "small", "0", 3, 12, 9, [4, 15, 11, 3, 10, 4], "Dokunaç: +4, 1 ezici; mürekkep bulutu.",
		{"body": "octopus", "col": "c0603a", "col2": "e8a080"})
	_c("crab", "Yengeç", S, "tiny", "0", 2, 11, 6, [2, 11, 10, 1, 8, 2], "Kıskaç: +0, 1 ezici.",
		{"body": "crab", "col": "c0392b", "col2": "e8a080"})
	_c("giant_crab", "Dev Yengeç", S, "medium", "1/8", 13, 15, 9, [13, 15, 11, 1, 9, 3], "Kıskaç: +3, 1d6+1; yakalar.",
		{"body": "crab", "col": "8a3a2a", "col2": "c87050"})
	_c("jellyfish", "Denizanası", S, "small", "0", 3, 10, 3, [3, 10, 10, 1, 6, 1], "Dokunaç: zehir 1d6.",
		{"body": "jelly", "col": "c39bd3", "col2": "e8daef"})
	# --- Böcekler ve sürüngenler
	_c("giant_spider", "Dev Örümcek", R, "large", "1", 26, 14, 9, [14, 16, 12, 2, 11, 4], "Isırık 1d8+3 + 2d8 zehir; ağ.",
		{"body": "spider", "col": "2b2420", "col2": "c0392b"})
	_c("spider", "Örümcek", R, "tiny", "0", 1, 12, 6, [2, 14, 8, 1, 10, 2], "Isırık: 1 + zehir.",
		{"body": "spider", "col": "4a3a2a", "col2": "8a6a4a"})
	_c("scorpion", "Dev Akrep", R, "large", "3", 52, 15, 12, [15, 13, 15, 1, 9, 3], "Kıskaç x2 1d8+2, İğne 1d10+2 + 4d10 zehir.",
		{"body": "scorpion", "col": "2b2420", "col2": "6b4a2a"})
	_c("beetle", "Dev Böcek", R, "small", "0", 4, 13, 9, [8, 10, 12, 1, 7, 3], "Isırık: +1, 1d6 delici.",
		{"body": "insect", "shape": "beetle", "col": "1e4a3a", "col2": "2e8a6a"})
	_c("giant_bee", "Dev Arı", R, "small", "1/4", 9, 13, 12, [6, 15, 10, 1, 10, 3], "İğne: +4, 1d4 + zehir.",
		{"body": "insect", "shape": "bee", "col": "f1c40f", "col2": "1e1e1e"})
	_c("giant_ant", "Dev Karınca", R, "medium", "1/4", 13, 13, 9, [12, 13, 12, 1, 8, 2], "Isırık: +3, 1d6+1.",
		{"body": "insect", "shape": "ant", "col": "8a2a1a", "col2": "4a1a10"})
	_c("snake", "Yılan", R, "tiny", "1/8", 2, 13, 9, [2, 16, 11, 1, 10, 3], "Isırık: +5, 1 + 2d4 zehir.",
		{"body": "serpent", "col": "4a7a3a", "col2": "c8c070", "pattern": "bands"})
	_c("cobra", "Kobra", R, "small", "1/4", 5, 13, 9, [4, 16, 11, 1, 10, 3], "Isırık: +5, 1d4 + 3d6 zehir.",
		{"body": "serpent", "col": "8a6a2a", "col2": "e8d8a0", "hood": true})
	_c("python", "Dev Yılan", R, "huge", "2", 60, 12, 9, [19, 14, 12, 1, 10, 3], "Isırık 2d6+4, Sarılma 2d8+4; ezme.",
		{"body": "serpent", "col": "6b5a2a", "col2": "c8a050", "pattern": "diamonds", "thick": 1.4})
	_c("crocodile", "Timsah", R, "large", "1/2", 19, 12, 6, [15, 10, 13, 2, 10, 5], "Isırık: +4, 1d10+2; yakalar.",
		{"body": "quad", "head": "reptile", "col": "4a5a3a", "col2": "8a8a5a", "tail": "reptile", "leg": 0.4, "len": 1.25, "h": 0.65, "legs": "splay", "scales": true})
	_c("lizard", "Kertenkele", R, "tiny", "0", 2, 10, 6, [2, 11, 10, 1, 8, 3], "Isırık: 1 delici.",
		{"body": "quad", "head": "reptile", "col": "6b8e23", "col2": "c8d080", "tail": "reptile", "leg": 0.45, "h": 0.6, "legs": "splay", "snout": 0.7})
	_c("giant_lizard", "Dev Kertenkele", R, "large", "1/4", 19, 12, 9, [15, 12, 13, 2, 10, 5], "Isırık: +4, 1d8+2.",
		{"body": "quad", "head": "reptile", "col": "8a6a3a", "col2": "c8b080", "tail": "reptile", "leg": 0.5, "h": 0.7, "legs": "splay", "frill": true})
	_c("turtle", "Dev Kaplumbağa", R, "large", "1", 45, 17, 6, [16, 8, 16, 2, 10, 4], "Isırık: +5, 2d6+3. Kabuğuna çekilir.",
		{"body": "turtle", "col": "5a6b3a", "col2": "8a7a4a"})
	_c("frog", "Dev Kurbağa", R, "medium", "1/4", 18, 11, 9, [12, 13, 11, 2, 10, 3], "Isırık 1d6+1; dil ile yakalar, yutar.",
		{"body": "frog", "col": "5a8a3a", "col2": "c8d890"})
	# --- Ejderhalar
	var dragons := [["red", "Kızıl Ejderha", "c0392b", "e8a050", "Ateş nefesi (90 hasar), ısırık, pençe, kuyruk."],
		["blue", "Mavi Ejderha", "2e6bb0", "a0c8e8", "Yıldırım nefesi, ısırık, pençe, kuyruk."],
		["green", "Yeşil Ejderha", "2e7a3a", "a8c870", "Zehirli gaz nefesi, ısırık, pençe."],
		["black", "Kara Ejderha", "1e1e24", "4a5a3a", "Asit nefesi, ısırık, pençe, kuyruk."],
		["white", "Ak Ejderha", "e8eef4", "a8c8e0", "Buz nefesi, ısırık, pençe."],
		["gold", "Altın Ejderha", "d4a420", "f4e0a0", "Ateş ve zayıflatma nefesi; şekil değiştirir."],
		["silver", "Gümüş Ejderha", "aab4bc", "e8ecf0", "Soğuk ve felç nefesi; şekil değiştirir."],
		["bronze", "Bronz Ejderha", "a0682a", "d8a870", "Yıldırım ve itme nefesi."],
		["copper", "Bakır Ejderha", "b86a3a", "48a090", "Asit ve yavaşlatma nefesi."]]
	for d in dragons:
		_c("dragon_" + d[0], d[1], D, "gargantuan", "17", 256, 19, 12, [27, 10, 25, 16, 13, 21], d[4],
			{"body": "dragon", "col": d[2], "col2": d[3]})
	_c("wyrmling", "Yavru Ejderha", D, "medium", "4", 75, 17, 9, [19, 10, 17, 12, 11, 15], "Isırık 1d10+4; nefes 7d6.",
		{"body": "dragon", "col": "c0392b", "col2": "e8a050", "young": true})
	_c("wyvern", "Vivern", D, "large", "6", 110, 13, 6, [19, 10, 16, 5, 12, 6], "Isırık 2d6+4, İğne 2d6+4 + 7d6 zehir.",
		{"body": "dragon", "col": "5a6b3a", "col2": "a8a070", "wyvern": true})
	_c("dragon_turtle", "Ejder Kaplumbağa", D, "gargantuan", "17", 341, 20, 6, [25, 10, 20, 10, 12, 12], "Buhar nefesi, ısırık, pençe, kuyruk.",
		{"body": "turtle", "col": "2e6b5a", "col2": "4a8a6a", "dragon": true})
	# --- Fantastik yaratıklar
	_c("griffon", "Grifon", F, "large", "2", 59, 12, 9, [18, 15, 16, 2, 13, 8], "Gaga 1d8+4, Pençe 2d6+4.",
		{"body": "quad", "head": "bird", "col": "c8a050", "col2": "f2ead7", "front_col": "8a6040", "tail": "tuft", "wings": "feather", "beak_col": "e8b923"})
	_c("hippogriff", "Hipogrif", F, "large", "1", 19, 11, 12, [17, 13, 13, 2, 12, 8], "Gaga 1d10+3, Pençe 2d6+3.",
		{"body": "quad", "head": "bird", "col": "8a6a4a", "col2": "c8b090", "front_col": "d8d0c0", "tail": "horse", "wings": "feather", "leg": 1.2})
	_c("pegasus", "Pegasus", F, "large", "2", 59, 12, 18, [18, 15, 16, 10, 15, 13], "Toynak: +6, 2d6+4.",
		{"body": "quad", "head": "equine", "col": "f4f4f8", "col2": "d8e0f0", "tail": "horse", "mane": true, "mane_col": "d8e8f8", "wings": "feather", "leg": 1.2, "neck": 0.9})
	_c("unicorn", "Tekboynuz", F, "large", "5", 67, 12, 15, [18, 14, 15, 11, 17, 16], "Boynuz 1d8+4 + şifa ve ışınlanma büyüsü.",
		{"body": "quad", "head": "equine", "col": "f8f8fc", "col2": "e8e8f4", "tail": "horse", "mane": true, "mane_col": "c39bd3", "horns": "unicorn", "leg": 1.2, "neck": 0.9})
	_c("nightmare", "Kâbus Atı", F, "large", "3", 68, 13, 18, [18, 15, 16, 10, 13, 15], "Toynak 2d8+4 + 2d6 ateş; ruhlar arası yolculuk.",
		{"body": "quad", "head": "equine", "col": "1a1418", "col2": "2b2024", "tail": "fire", "mane": true, "mane_col": "e67e22", "fire": true, "leg": 1.2, "neck": 0.9, "eye": "e74c3c"})
	_c("manticore", "Mantikor", F, "large", "3", 68, 14, 9, [17, 16, 17, 7, 12, 8], "Isırık, pençe veya 3 zehirli diken atışı.",
		{"body": "quad", "head": "feline", "col": "b8783a", "col2": "e0b880", "tail": "scorpion", "mane": true, "mane_col": "6b3a1a", "wings": "bat", "human_face": true})
	_c("chimera", "Kimera", F, "large", "6", 114, 14, 9, [19, 11, 19, 3, 14, 10], "Isırık, boynuz, pençe; ateş nefesi.",
		{"body": "quad", "head": "feline", "col": "b88a40", "col2": "e0c080", "tail": "snake", "mane": true, "mane_col": "7a4a1a", "wings": "bat", "extra_head": "goat"})
	_c("basilisk", "Basilisk", F, "medium", "3", 52, 15, 6, [16, 8, 15, 2, 8, 7], "Isırık 2d6+3 + 2d6 zehir. Bakışı taşa çevirir.",
		{"body": "quad", "head": "reptile", "col": "4a6a4a", "col2": "8a9a6a", "tail": "reptile", "leg": 0.45, "h": 0.75, "legs": "splay", "legs6": true, "eye": "f1c40f", "spikes": true})
	_c("hydra", "Hidra", F, "huge", "8", 172, 15, 9, [20, 12, 20, 2, 10, 7], "5 baş, her biri ısırık 1d10+5. Kesilen baş ikiye çıkar.",
		{"body": "hydra", "col": "3a6a4a", "col2": "a8c080", "heads": 5})
	_c("kraken", "Kraken", F, "gargantuan", "23", 472, 18, 18, [30, 11, 25, 22, 18, 20], "Dokunaç x3 3d6+10, ısırık 3d8+10; yutma, fırtına.",
		{"body": "octopus", "col": "6a2a3a", "col2": "c06070", "kraken": true})
	_c("sea_serpent", "Deniz Yılanı", F, "gargantuan", "12", 247, 16, 18, [26, 12, 24, 4, 12, 8], "Isırık 4d10+8, sarılma; gemileri batırır.",
		{"body": "serpent", "col": "1e5a6a", "col2": "70b8b0", "fins": true, "water": true, "thick": 1.6, "horns": true})
	_c("phoenix", "Anka Kuşu", F, "gargantuan", "16", 175, 18, 36, [19, 26, 25, 2, 21, 18], "Gaga, pençe + ateş; küllerinden doğar.",
		{"body": "bird", "col": "e74c3c", "col2": "f39c12", "col3": "f7dc6f", "beak": "hook", "wing": "spread", "fire": true, "tail": "phoenix"})
	_c("roc", "Dev Rok Kuşu", F, "gargantuan", "11", 248, 15, 36, [28, 10, 20, 3, 10, 9], "Gaga 4d8+9, Pençe 4d6+9; kaldırıp taşır.",
		{"body": "bird", "col": "6b4a2a", "col2": "a08060", "col3": "e8b923", "beak": "hook", "wing": "spread"})
	_c("owlbear", "Baykuşayı", F, "large", "3", 59, 13, 12, [20, 12, 17, 3, 12, 7], "Gaga 1d10+5, Pençe 2d8+5.",
		{"body": "quad", "head": "owl", "col": "6b4a2a", "col2": "c8a878", "tail": "short", "legs": "thick", "h": 1.25, "beak_col": "e8c060"})
	_c("cerberus", "Kerberos", F, "large", "5", 85, 15, 15, [18, 14, 16, 6, 13, 6], "3 ısırık 1d8+4 + ateş; ateş nefesi.",
		{"body": "quad", "head": "canine", "col": "2b2020", "col2": "5a3a30", "tail": "snake", "heads": 3, "eye": "e74c3c", "fire": true})
	_c("hellhound", "Cehennem Köpeği", F, "medium", "3", 45, 15, 15, [17, 12, 14, 6, 13, 6], "Isırık 1d8+3 + 2d6 ateş; ateş nefesi.",
		{"body": "quad", "head": "canine", "col": "3a1a1a", "col2": "6a2a1a", "tail": "fire", "eye": "f39c12", "fire": true, "spikes": true})
	_c("worg", "Varg", F, "large", "1/2", 26, 13, 15, [16, 13, 13, 7, 11, 8], "Isırık 2d6+3; yere düşürme. Konuşur.",
		{"body": "quad", "head": "canine", "col": "2b2b30", "col2": "4a4a50", "tail": "bushy", "len": 1.1, "eye": "e74c3c", "spikes": true})
	_c("displacer", "Gölge Panter", F, "large", "3", 85, 13, 12, [18, 15, 16, 6, 12, 8], "2 dokunaç 1d6+4 + 1d6. Yerini yanıltır.",
		{"body": "quad", "head": "feline", "col": "2b2b45", "col2": "4a4a6a", "tail": "long", "tentacles": true, "eye": "48c9b0", "len": 1.1})
	_c("fairy", "Peri", F, "tiny", "1/4", 3, 15, 9, [3, 18, 8, 14, 12, 16], "Peri büyüleri: uyku, görünmezlik, illüzyon.",
		{"body": "bust", "ears": "elf", "wings": "fairy", "skin": "f6e3d8", "hair": "long", "hair_color": "f5b7b1", "outfit": "clothes", "cloth": "a9dfbf", "accent": "f9e79f", "glow_eyes": false, "eye_color": "8e44ad", "bg": "2e5a4a", "head_size": 1.05, "build": 0.8})
	_c("harpy", "Harpi", F, "medium", "1", 38, 11, 6, [12, 13, 12, 7, 10, 13], "Pençe 2d4+1; büyüleyici şarkı.",
		{"body": "bust", "ears": "short_pointed", "wings": "feather", "skin": "c8a882", "hair": "wild", "hair_color": "3b2a1a", "outfit": "none", "feather_body": true, "brow": 0.3, "bg": "4a4a3a"})
	_c("medusa", "Medusa", F, "medium", "6", 127, 15, 9, [10, 15, 16, 12, 13, 15], "Yılan saçı 4d6 zehir; bakışı taşa çevirir.",
		{"body": "bust", "skin": "8aa07a", "hair": "snakes", "hair_color": "3a6a3a", "marks": "scales", "eye_color": "f1c40f", "glow_eyes": true, "outfit": "robe", "cloth": "5a4a2a", "accent": "c9a24a", "bg": "3a4a3a"})
	_c("centaur_m", "Sentor Avcı", F, "large", "2", 45, 12, 15, [18, 14, 14, 9, 13, 11], "Mızrak 1d10+4, Yay 2d6+2.",
		{"body": "centaur", "col": "7a4a2a", "col2": "5a3a1a", "skin": "c68642", "hair": "long", "hair_color": "3b2a1a"})
	_c("minotaur_m", "Minotor (Canavar)", F, "large", "3", 76, 14, 12, [18, 11, 16, 6, 16, 9], "Balta 2d12+4, Boynuz 2d8+4; hücum.",
		{"body": "bust", "face": "bull", "ears": "cow", "horns": "bull", "hair": "none", "skin": "4a3428", "outfit": "furs", "cloth": "5e3b1f", "item": "axe", "build": 1.4, "head": "broad", "eye_color": "c0392b", "brow": 0.5, "bg": "5a3a2a"})
	# --- Canavarlar
	_c("troll", "Trol", M, "large", "5", 84, 15, 9, [18, 13, 20, 7, 9, 7], "Isırık 1d6+4, Pençe x2 2d6+4. Yenilenir (ateş ve asit hariç).",
		{"body": "bust", "face": "troll", "ears": "goblin", "nose": "long", "skin": "5a7a5a", "hair": "wild", "hair_color": "2b3a2b", "tusks": true, "outfit": "rags", "cloth": "5a4a3a", "build": 1.35, "head": "long", "brow": 0.6, "bg": "3a4a3a"})
	_c("ogre", "Ogre", M, "large", "2", 59, 11, 12, [19, 8, 16, 5, 7, 7], "Dev sopa: +6, 2d8+4.",
		{"body": "bust", "skin": "a08a6a", "hair": "none", "head": "broad", "nose": "big", "tusks": true, "outfit": "furs", "cloth": "6b4a2a", "build": 1.5, "brow": 0.5, "head_size": 0.9, "bg": "5a4a3a"})
	_c("hill_giant", "Tepe Devi", M, "huge", "5", 105, 13, 12, [21, 8, 19, 5, 9, 6], "Sopa x2 3d8+5, kaya fırlatma 3d10+5.",
		{"body": "bust", "skin": "c8a070", "hair": "wild", "hair_color": "5a3a22", "beard": "long", "head": "broad", "nose": "big", "outfit": "furs", "cloth": "7a5230", "build": 1.5, "brow": 0.4, "bg": "4a5a3a"})
	_c("frost_giant", "Buz Devi", M, "huge", "8", 138, 15, 12, [23, 9, 21, 9, 10, 12], "Balta x2 3d12+6, kaya 4d10+6.",
		{"body": "bust", "skin": "a8c8e0", "hair": "braid", "hair_color": "f4f4f4", "beard": "braided", "head": "square", "outfit": "furs", "cloth": "d8d8d8", "helm": "horned", "item": "axe", "build": 1.5, "brow": 0.4, "bg": "4a5a6a"})
	_c("fire_giant", "Ateş Devi", M, "huge", "9", 162, 18, 9, [25, 9, 23, 10, 14, 13], "Büyük kılıç x2 6d6+7, kaya 4d10+7.",
		{"body": "bust", "skin": "3a3030", "hair": "flame", "hair_color": "e67e22", "beard": "braided", "head": "square", "outfit": "plate", "cloth": "4a3a30", "accent": "c0392b", "item": "greatsword", "build": 1.5, "eye_color": "f39c12", "glow_eyes": true, "bg": "5a2a1a"})
	_c("cyclops", "Tepegöz", M, "huge", "6", 138, 14, 9, [22, 11, 20, 8, 6, 10], "Sopa x2 3d8+6, kaya 4d10+6.",
		{"body": "bust", "skin": "b8a080", "hair": "none", "head": "broad", "cyclops": true, "outfit": "furs", "cloth": "6b4a2a", "build": 1.45, "bg": "4a4a3a"})
	_c("hag", "Cadı", M, "medium", "3", 82, 17, 9, [18, 12, 16, 13, 14, 14], "Pençe 2d8+4; illüzyon, lanet.",
		{"body": "bust", "skin": "7a9a6a", "nose": "long", "hair": "wild", "hair_color": "c8c8c0", "outfit": "rags", "cloth": "3a3a2a", "helm": "wizard", "accent": "2b2b2b", "marks": "spots", "mark_color": "4a5a3a", "brow": 0.4, "bg": "2a3a2a"})
	_c("werewolf", "Kurtadam", M, "medium", "3", 58, 12, 12, [15, 13, 14, 10, 11, 10], "Isırık 1d8+2 (lanet bulaştırır), Pençe 2d4+2.",
		{"body": "bust", "face": "wolf", "ears": "cat", "hair": "mane", "hair_color": "4a4040", "skin": "6b6060", "outfit": "rags", "cloth": "5a4a3a", "fur": true, "eye_color": "f1c40f", "glow_eyes": true, "build": 1.3, "bg": "2a2a3a"})
	_c("demon", "İblis", M, "large", "8", 136, 16, 12, [20, 15, 18, 11, 12, 16], "Pençe ve kuyruk; ateş, korku aurası.",
		{"body": "bust", "skin": "8a1a1a", "horns": "straight", "horn_color": "2b2020", "hair": "none", "ears": "elf", "tusks": true, "wings": "bat", "outfit": "none", "build": 1.35, "eye_color": "f39c12", "glow_eyes": true, "brow": 0.6, "bg": "3a1a1a"})
	_c("imp", "Şeytancık", M, "tiny", "1", 10, 13, 6, [6, 17, 13, 11, 12, 14], "İğne 1d4+3 + 3d6 zehir; görünmezlik.",
		{"body": "bust", "skin": "c0392b", "horns": "small", "horn_color": "2b2020", "hair": "none", "ears": "goblin", "wings": "bat", "outfit": "none", "build": 0.75, "head_size": 1.1, "eye_color": "f1c40f", "glow_eyes": true, "brow": 0.4, "bg": "4a2020"})
	_c("gargoyle", "Gargoyl", M, "medium", "2", 52, 15, 9, [15, 11, 16, 6, 11, 7], "Isırık, pençe; taş kılığında gizlenir.",
		{"body": "bust", "skin": "8a8a8a", "horns": "straight", "horn_color": "6a6a6a", "hair": "none", "ears": "goblin", "wings": "bat", "outfit": "none", "marks": "cracks", "mark_color": "4a4a4a", "tusks": true, "brow": 0.6, "bg": "3a3a40"})
	_c("eye_tyrant", "Uçan Göz", M, "large", "13", 180, 18, 6, [10, 14, 18, 17, 15, 17], "Göz ışınları (10 farklı etki), büyü karşıtı bakış.",
		{"body": "eye", "col": "8a4a6a", "col2": "c08aa0"})
	_c("mimic", "Taklitçi", M, "medium", "2", 58, 12, 3, [17, 12, 15, 5, 13, 8], "Isırık 1d8+3 + 1d8 asit; yapıştırır. Sandık kılığında.",
		{"body": "mimic", "col": "8a5a33", "col2": "c9a24a"})
	_c("slime", "Balçık", M, "large", "2", 84, 8, 3, [14, 3, 20, 1, 6, 1], "Dokunaç 1d6+2 + 3d6 asit; silahları eritir.",
		{"body": "slime", "col": "6ab04c", "col2": "badc58"})
	_c("cube", "Jelatin Küp", M, "large", "2", 84, 6, 4.5, [14, 3, 20, 1, 6, 1], "İçine çeker: 3d6 asit.",
		{"body": "cube", "col": "48c9b0", "col2": "a3e4d7"})
	_c("rust_monster", "Pas Canavarı", M, "medium", "1/2", 27, 14, 12, [13, 12, 13, 2, 13, 6], "Isırık 1d8+1; antenleri metali paslandırır.",
		{"body": "insect", "shape": "rust", "col": "b8683a", "col2": "6b3a1a"})
	_c("treant", "Ağaç Ata", M, "huge", "9", 138, 16, 9, [23, 8, 21, 12, 16, 12], "Dal x2 3d6+6; ağaçları canlandırır.",
		{"body": "treant", "col": "5a4030", "col2": "4a7a3a"})
	_c("will_o_wisp", "Bataklık Işığı", M, "tiny", "2", 22, 19, 15, [1, 28, 10, 13, 14, 11], "Şok 2d8 yıldırım; görünmez olur.",
		{"body": "wisp", "col": "aed6f1", "col2": "5dade2"})
	# --- Ölümsüzler
	_c("skeleton", "İskelet", U, "medium", "1/4", 13, 13, 9, [10, 14, 15, 6, 8, 5], "Kılıç 1d6+2, Yay 1d6+2.",
		{"body": "bust", "face": "skull", "ears": "none", "hair": "none", "skin": "e8e0c8", "outfit": "bones", "item": "sword", "cloth": "3a3a3a", "eye_color": "48c9b0", "bg": "2a2a2a"})
	_c("zombie", "Zombi", U, "medium", "1/4", 22, 8, 6, [13, 6, 16, 3, 6, 5], "Yumruk 1d6+1. Ölümsüz direnci.",
		{"body": "bust", "skin": "8a9a7a", "hair": "wild", "hair_color": "3a3a2a", "marks": "stitches", "outfit": "rags", "cloth": "5a5040", "eye_color": "e8e8c8", "zombie": true, "bg": "2a3a2a"})
	_c("ghoul", "Gulyabani", U, "medium", "1", 22, 12, 9, [13, 15, 10, 7, 10, 6], "Pençe 2d4+2 (felç), Isırık 2d6+2.",
		{"body": "bust", "skin": "a0a090", "hair": "none", "ears": "elf", "tusks": true, "outfit": "rags", "cloth": "4a4040", "eye_color": "f1c40f", "glow_eyes": true, "head": "long", "zombie": true, "brow": 0.5, "bg": "2a2a28"})
	_c("ghost", "Hayalet", U, "medium", "4", 45, 11, 12, [7, 13, 10, 10, 12, 17], "Yaşlandıran dokunuş 4d6; ele geçirme.",
		{"body": "bust", "ghost": true, "skin": "c8d8e8", "hair": "long", "hair_color": "e8f0f8", "outfit": "robe", "cloth": "a8b8c8", "eye_color": "f4f4f4", "glow_eyes": true, "bg": "1a2a3a"})
	_c("wraith", "Ruh Emici", U, "medium", "5", 67, 13, 0, [6, 16, 16, 12, 14, 15], "Can emme 4d8+3; gölge yaratır.",
		{"body": "bust", "face": "skull", "ghost": true, "skin": "4a4a5a", "helm": "hood", "outfit": "cloak", "cloth": "1a1a24", "eye_color": "e74c3c", "glow_eyes": true, "bg": "14141e"})
	_c("banshee", "Ağıtçı Ruh", U, "medium", "4", 58, 12, 0, [1, 14, 10, 12, 11, 17], "Ölüm çığlığı; korkunç yüz.",
		{"body": "bust", "ghost": true, "skin": "d8e8e0", "hair": "wild", "hair_color": "f0f8f4", "outfit": "rags", "cloth": "c8d8d0", "eye_color": "f4f4f4", "glow_eyes": true, "mouth": "scream", "bg": "1a2a24"})
	_c("vampire", "Vampir", U, "medium", "13", 144, 16, 9, [18, 18, 18, 17, 15, 18], "Isırık 1d6+4 + 3d6 can emme; büyüleme, yarasaya dönüşme.",
		{"body": "bust", "skin": "e8e0e4", "hair": "long", "hair_color": "1a1410", "ears": "short_pointed", "outfit": "noble", "cloth": "1a1418", "accent": "8a1a2a", "fangs": true, "eye_color": "c0392b", "glow_eyes": true, "collar": true, "bg": "2a1418"})
	_c("lich", "Lich", U, "medium", "21", 135, 17, 9, [11, 16, 16, 20, 14, 16], "Felç dokunuşu 3d6; 9. seviye büyüler, filakter.",
		{"body": "bust", "face": "skull", "skin": "c8c0a8", "helm": "crown", "outfit": "robe", "cloth": "2a1a3a", "accent": "8e44ad", "item": "staff", "eye_color": "48c9b0", "glow_eyes": true, "bg": "1a1a2a"})
	_c("mummy", "Mumya", U, "medium", "3", 58, 11, 6, [16, 8, 15, 6, 10, 12], "Çürük yumruk 2d6+3 + lanet; korku bakışı.",
		{"body": "bust", "skin": "c8b890", "hair": "none", "mummy": true, "outfit": "rags", "cloth": "b8a880", "eye_color": "f1c40f", "glow_eyes": true, "bg": "3a3020"})
	_c("death_knight", "Ölüm Şövalyesi", U, "medium", "17", 180, 20, 9, [20, 11, 20, 12, 16, 18], "Kılıç x3 1d8+5 + 4d8 nekrotik; cehennem ateşi küresi.",
		{"body": "bust", "helm": "full", "outfit": "plate", "cloth": "2b2b30", "accent": "6b1a1a", "item": "greatsword", "eye_color": "e74c3c", "glow_eyes": true, "build": 1.25, "bg": "1a1418"})
	# --- Elementaller ve yapılar
	_c("fire_elemental", "Ateş Elementali", E, "large", "5", 102, 13, 15, [10, 17, 16, 6, 10, 7], "Dokunuş x2 2d6+3 ateş; tutuşturur.",
		{"body": "elemental", "kind": "fire", "col": "e67e22", "col2": "f7dc6f"})
	_c("water_elemental", "Su Elementali", E, "large", "5", 114, 14, 9, [18, 14, 18, 5, 10, 8], "Darbe x2 2d8+4; girdap.",
		{"body": "elemental", "kind": "water", "col": "2e86c1", "col2": "aed6f1"})
	_c("earth_elemental", "Toprak Elementali", E, "large", "5", 126, 17, 9, [20, 8, 20, 5, 10, 5], "Darbe x2 2d8+5; toprakta yüzer.",
		{"body": "elemental", "kind": "earth", "col": "8d6e63", "col2": "bcaaa4"})
	_c("air_elemental", "Hava Elementali", E, "large", "5", 90, 15, 27, [14, 20, 14, 6, 10, 6], "Darbe x2 2d8+5; kasırga.",
		{"body": "elemental", "kind": "air", "col": "d6eaf8", "col2": "f4f6f7"})
	_c("stone_golem", "Taş Golem", E, "large", "10", 178, 17, 9, [22, 9, 20, 3, 11, 1], "Yumruk x2 3d8+6; yavaşlatma.",
		{"body": "bust", "skin": "8a8580", "hair": "none", "ears": "none", "golem": true, "marks": "cracks", "mark_color": "4a4440", "outfit": "none", "eye_color": "48c9b0", "glow_eyes": true, "build": 1.45, "head": "square", "head_size": 0.85, "bg": "3a3a3a"})
	_c("iron_golem", "Demir Golem", E, "large", "16", 210, 20, 9, [24, 9, 20, 3, 11, 1], "Kılıç 3d10+7, yumruk; zehirli gaz.",
		{"body": "bust", "helm": "full", "skin": "5a5a60", "outfit": "plate", "cloth": "5a5a60", "accent": "7a6a50", "eye_color": "f39c12", "glow_eyes": true, "build": 1.5, "bg": "2a2a2a"})
	_c("flesh_golem", "Et Golemi", E, "medium", "5", 93, 9, 9, [19, 9, 18, 6, 10, 5], "Yumruk x2 2d8+4; yıldırımla güçlenir.",
		{"body": "bust", "skin": "b0a090", "hair": "wild", "hair_color": "2b2b2b", "marks": "stitches", "outfit": "rags", "cloth": "4a4040", "build": 1.4, "head": "square", "zombie": true, "bolts": true, "bg": "2a3030"})
	_c("animated_armor", "Canlı Zırh", E, "medium", "1", 33, 18, 7.5, [14, 11, 13, 1, 3, 1], "Darbe x2 1d6+2.",
		{"body": "bust", "helm": "full", "outfit": "plate", "cloth": "7a7a80", "accent": "4a4a50", "item": "sword", "empty": true, "bg": "2a2a30"})
	# --- İnsansılar (düşman / NPC şablonları)
	_c("goblin_m", "Goblin Akıncı", H, "small", "1/4", 7, 15, 9, [8, 14, 10, 10, 8, 8], "Pala 1d6+2, kısa yay 1d6+2. Kaçma ustası.",
		{"race": "goblin", "class": "rogue"})
	_c("orc_m", "Ork Savaşçı", H, "medium", "1/2", 15, 13, 9, [16, 12, 16, 7, 11, 10], "Büyük balta 1d12+3; saldırgan.",
		{"race": "orc", "class": "barbarian"})
	_c("orc_shaman", "Ork Şaman", H, "medium", "2", 45, 12, 9, [15, 12, 14, 10, 14, 12], "Asa 1d6+2; ateş ve lanet büyüleri.",
		{"race": "orc", "class": "druid", "look": {"marks": "warpaint", "mark_color": Color("e8e0d0")}})
	_c("hobgoblin_m", "Hobgoblin Asker", H, "medium", "1/2", 11, 18, 9, [13, 12, 12, 10, 10, 9], "Uzun kılıç 1d10+1; askerî avantaj.",
		{"race": "hobgoblin", "class": "fighter"})
	_c("kobold_m", "Kobold Tuzakçı", H, "small", "1/8", 5, 12, 9, [7, 15, 9, 8, 7, 8], "Hançer 1d4+2; sapan. Sürü taktiği.",
		{"race": "kobold", "class": "rogue"})
	_c("bandit", "Haydut", H, "medium", "1/8", 11, 12, 9, [11, 12, 12, 10, 10, 10], "Pala 1d6+1, arbalet 1d8+1.",
		{"race": "human", "class": "rogue", "look": {"helm": "bandana", "beard": "stubble"}})
	_c("bandit_captain", "Haydut Reisi", H, "medium", "2", 65, 15, 9, [15, 16, 14, 14, 11, 14], "Pala x2 1d6+3, hançer 1d4+3; savuşturma.",
		{"race": "human", "class": "fighter", "look": {"outfit": "leather", "beard": "short", "marks": "scar"}})
	_c("cultist", "Tarikatçı", H, "medium", "1/8", 9, 12, 9, [11, 12, 10, 10, 11, 10], "Kurban hançeri 1d4+1.",
		{"race": "human", "class": "warlock", "look": {"helm": "hood", "cloth": Color("5a1a1a")}})
	_c("guard_m", "Şehir Muhafızı", H, "medium", "1/8", 11, 16, 9, [13, 12, 12, 10, 11, 10], "Mızrak 1d6+1.",
		{"race": "human", "class": "guard"})
	_c("knight", "Şövalye", H, "medium", "3", 52, 18, 9, [16, 11, 14, 11, 11, 15], "Büyük kılıç x2 2d6+3; liderlik.",
		{"race": "human", "class": "paladin", "look": {"helm": "full"}})
	_c("mage", "Büyücü (NPC)", H, "medium", "6", 40, 12, 9, [9, 14, 11, 17, 12, 11], "Ateş topu, buz fırtınası, ışınlanma.",
		{"race": "human", "class": "wizard", "look": {"beard": "long", "hair_color": Color("d7d0c4")}})
	_c("priest", "Rahip (NPC)", H, "medium", "2", 27, 13, 7.5, [10, 10, 12, 13, 16, 13], "Gürz 1d6; şifa ve kutsal ateş büyüleri.",
		{"race": "human", "class": "cleric"})
	_c("assassin", "Suikastçı", H, "medium", "8", 78, 15, 9, [11, 16, 14, 13, 11, 10], "Kısa kılıç x2 1d6+3 + 7d6 zehir; sinsi saldırı.",
		{"race": "dark_elf", "class": "rogue", "look": {"helm": "hood", "cloth": Color("1a1a1a")}})
	_c("pirate", "Korsan", H, "medium", "1/2", 22, 13, 9, [12, 14, 12, 10, 10, 12], "Pala 1d6+2, tabanca/tatar yayı.",
		{"race": "human", "class": "rogue", "look": {"helm": "bandana", "beard": "short", "cloth": Color("8a2a2a"), "marks": "scar"}})


func _c(id: String, cname: String, cat: String, size: String, cr: String, hp: int, ac: int, speed: float,
		st: Array, attacks: String, art: Dictionary) -> void:
	creatures[id] = {"name": cname, "cat": cat, "size": size, "cr": cr, "hp": hp, "ac": ac, "speed": speed,
		"stats": st, "attacks": attacks, "art": art}


func _ready() -> void:
	_def_creatures()


# =============================================================== yardımcılar

static func modifier(score: int) -> int:
	return floori((score - 10) / 2.0)


static func mod_text(score: int) -> String:
	var m := modifier(score)
	return ("+%d" % m) if m >= 0 else str(m)


static func proficiency(level: int) -> int:
	return 2 + floori((maxi(level, 1) - 1) / 4.0)


static func roll_4d6() -> int:
	var r: Array = [randi_range(1, 6), randi_range(1, 6), randi_range(1, 6), randi_range(1, 6)]
	r.sort()
	return r[1] + r[2] + r[3]


func race_name(id: String) -> String:
	return races[id]["name"] if races.has(id) else id


func class_name_of(id: String) -> String:
	return classes[id]["name"] if classes.has(id) else id


func random_name(race_id: String) -> String:
	var r: Dictionary = races.get(race_id, races["human"])
	var parts: Array = r["names"]
	return str(parts[0].pick_random()) + str(parts[1].pick_random())


static func _c2(v) -> Color:
	return v if v is Color else Color(str(v))


## Irk + sınıfa göre rastgele bir görünüm üretir.
func random_look(race_id: String, class_id: String) -> Dictionary:
	var L := base_look.duplicate(true)
	var r: Dictionary = races.get(race_id, races["human"])
	var c: Dictionary = classes.get(class_id, classes["fighter"])
	for k in r["look"]:
		L[k] = r["look"][k]
	L["skin"] = _c2(r["skins"].pick_random())
	L["hair_color"] = _c2(r["hairs"].pick_random())
	if r.has("eyes"):
		L["eye_color"] = _c2(r["eyes"].pick_random())
	else:
		L["eye_color"] = _c2(["3b6ea5", "5a3a22", "229954", "6b6b6b", "8a6a2a"].pick_random())
	if not r["look"].has("hair"):
		L["hair"] = r["styles"].pick_random()
	L["beard"] = r["beards"].pick_random()
	L["outfit"] = c["outfit"]
	L["item"] = c["item"]
	L["cloth"] = _c2(c["cloth"].pick_random())
	L["accent"] = _c2(c["accent"].pick_random())
	L["bg"] = _c2(c["bg"])
	if not r["look"].has("helm"):
		L["helm"] = c["helms"].pick_random()
	if L["marks"] == "none" and randf() < 0.15:
		L["marks"] = ["freckles", "scar"].pick_random()
	return L


func new_character(race_id := "human", class_id := "fighter", role := "pc") -> Dictionary:
	var stats := {}
	for s in STATS:
		stats[s] = 10
	var ch := {
		"id": "", "kind": "character", "role": role, "name": random_name(race_id),
		"race": race_id, "class": class_id, "species": "", "level": 1, "xp": 0,
		"stats": stats, "hp": 10, "hp_max": 10, "ac": 10, "speed": 9.0,
		"alignment": "Tam Tarafsız", "disposition": "ally" if role == "pc" else "neutral",
		"size": "medium", "player": "", "background": "", "personality": "", "notes": "", "gold": 0,
		"attacks": "", "cr": "", "look": random_look(race_id, class_id),
	}
	apply_standard_array(ch)
	return ch


## Standart dizi: sınıfın ana yeteneklerine en yüksek puanlar
func apply_standard_array(ch: Dictionary) -> void:
	var arr := [15, 14, 13, 12, 10, 8]
	var c: Dictionary = classes.get(ch["class"], classes["fighter"])
	var order: Array = c["prim"].duplicate()
	for s in ["con", "dex", "wis", "str", "cha", "int"]:
		if s not in order:
			order.append(s)
	var stats := {}
	for i in 6:
		stats[order[i]] = arr[i]
	ch["stats"] = stats
	recalc(ch)


func roll_stats(ch: Dictionary) -> void:
	for s in STATS:
		ch["stats"][s] = roll_4d6()
	recalc(ch)


## Irk bonusu dahil yetenek puanı
func total_stat(ch: Dictionary, s: String) -> int:
	var v := int(ch["stats"].get(s, 10))
	if ch.get("kind", "") == "character" and races.has(ch.get("race", "")):
		v += int(races[ch["race"]]["bonus"].get(s, 0))
	return v


## Can, zırh, hız ve boyutu ırk/sınıf/seviyeye göre yeniden hesaplar.
func recalc(ch: Dictionary) -> void:
	if ch.get("kind", "") != "character":
		return
	var c: Dictionary = classes.get(ch["class"], classes["fighter"])
	var r: Dictionary = races.get(ch["race"], races["human"])
	var con := modifier(total_stat(ch, "con"))
	var hd := int(c["hd"])
	var lvl := maxi(1, int(ch["level"]))
	var hp := hd + con + (lvl - 1) * (hd / 2 + 1 + con)
	ch["hp_max"] = maxi(1, hp)
	ch["hp"] = ch["hp_max"]
	var dex := modifier(total_stat(ch, "dex"))
	var base_ac := int(c["ac"])
	match c["outfit"]:
		"plate", "chain": ch["ac"] = base_ac
		"leather": ch["ac"] = base_ac + mini(dex, 3)
		"monk": ch["ac"] = 10 + dex + modifier(total_stat(ch, "wis"))
		_: ch["ac"] = base_ac + dex - 2
	ch["speed"] = float(r.get("speed", 9))
	ch["size"] = str(r.get("size", "medium"))


func new_creature(species: String) -> Dictionary:
	var d: Dictionary = creatures[species]
	var stats := {}
	for i in 6:
		stats[STATS[i]] = int(d["stats"][i])
	var art: Dictionary = d["art"]
	var look := {}
	if art.has("race"):
		# İnsansı düşmanlar: ırk + sınıf görünümü
		look = random_look(art["race"], art.get("class", "fighter"))
		for k in art.get("look", {}):
			look[k] = art["look"][k]
	elif art.get("body", "") == "bust" or art.get("body", "") == "centaur":
		look = base_look.duplicate(true)
		for k in art:
			look[k] = _c2(art[k]) if (k in ["skin", "hair_color", "eye_color", "cloth", "accent", "bg", "mark_color", "horn_color"]) else art[k]
	else:
		look = art.duplicate(true)
	return {
		"id": "", "kind": "creature", "role": "creature", "name": d["name"], "species": species,
		"race": art.get("race", ""), "class": art.get("class", ""), "level": 1, "xp": 0, "stats": stats,
		"hp": d["hp"], "hp_max": d["hp"], "ac": d["ac"], "speed": d["speed"],
		"alignment": "Tam Tarafsız", "disposition": "enemy", "size": d["size"], "player": "",
		"background": "", "personality": "", "notes": "", "gold": 0, "attacks": d["attacks"], "cr": d["cr"],
		"look": look,
	}


func describe(ch: Dictionary) -> String:
	if ch.get("kind", "") == "creature":
		return "%s • Tehlike %s" % [SIZES.get(ch.get("size", "medium"), {}).get("name", ""), ch.get("cr", "?")]
	return "%s %s • Sv %d" % [race_name(ch.get("race", "")), class_name_of(ch.get("class", "")), int(ch.get("level", 1))]
