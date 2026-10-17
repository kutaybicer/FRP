class_name Campaign
extends RefCounted
## Kampanya = iç içe haritalar ağacı. Dünya -> Şehir -> Meyhane -> Mahzen ...

const FILE_VERSION := 1

var name := "Yeni Kampanya"
var maps: Dictionary = {}   # id -> MapData
var root_id := ""
var characters: Dictionary = {}   # id -> karakter sözlüğü (Lore.new_character / new_creature)
var photos: Dictionary = {}       # fotoğraf id -> PNG baytları (karakter görünümünde look["photo"] = id)


static func make_id() -> String:
	return "m%x%04x" % [int(Time.get_unix_time_from_system() * 1000.0), randi() % 65536]


func create_map(kind: int, map_name: String, parent_id := "") -> MapData:
	var m := MapData.new()
	m.id = make_id()
	while maps.has(m.id):
		m.id = make_id()
	m.name = map_name
	m.kind = kind
	m.parent_id = parent_id
	var d: Dictionary = Defs.KIND_DEFAULTS[kind]
	m.scale = d["scale"]
	m.unit = d["unit"]
	m.setup(d["cols"], d["rows"], d["fill"])
	maps[m.id] = m
	if root_id == "":
		root_id = m.id
	return m


func add_character(ch: Dictionary) -> String:
	var id := "c" + make_id().substr(1)
	while characters.has(id):
		id = "c" + make_id().substr(1)
	ch["id"] = id
	characters[id] = ch
	return id


## Karakteri ve tüm haritalardaki jetonlarını siler.
func remove_character(id: String) -> void:
	characters.erase(id)
	for m in maps.values():
		for i in range(m.tokens.size() - 1, -1, -1):
			if m.tokens[i].get("char", "") == id:
				m.tokens.remove_at(i)


## Karakterin bulunduğu haritalar (isimleri)
func locations_of(id: String) -> Array:
	var out: Array = []
	for m in maps.values():
		for t in m.tokens:
			if t.get("char", "") == id:
				out.append(m)
				break
	return out


func children_of(map_id: String) -> Array:
	var out: Array = []
	for m in maps.values():
		if m.parent_id == map_id and m.id != map_id:
			out.append(m)
	out.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	return out


## Haritayı ve tüm alt haritalarını siler, ona bağlı sembollerin bağlantısını koparır.
func delete_map(map_id: String) -> void:
	if map_id == root_id or not maps.has(map_id):
		return
	for child in children_of(map_id):
		delete_map(child.id)
	maps.erase(map_id)
	for m in maps.values():
		for s in m.symbols:
			if s.get("link", "") == map_id:
				s["link"] = ""


func path_to(map_id: String) -> Array:
	var chain: Array = []
	var guard := 0
	var cur := map_id
	while cur != "" and maps.has(cur) and guard < 64:
		chain.push_front(maps[cur])
		cur = maps[cur].parent_id
		guard += 1
	return chain


func to_dict() -> Dictionary:
	var md := {}
	for k in maps:
		md[k] = maps[k].to_dict()
	# sadece kullanılan fotoğraflar kaydedilir
	var used := {}
	for ch in characters.values():
		var pid := str(ch.get("look", {}).get("photo", ""))
		if pid != "" and photos.has(pid):
			used[pid] = photos[pid]
	return {"version": FILE_VERSION, "name": name, "root_id": root_id, "maps": md, "characters": characters.duplicate(true), "photos": used}


func save_to(path: String) -> Error:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_var(to_dict(), false)
	f.close()
	return OK


static func load_from(path: String) -> Campaign:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data = f.get_var(false)
	f.close()
	if typeof(data) != TYPE_DICTIONARY or not data.has("maps"):
		return null
	var c := Campaign.new()
	c.name = str(data.get("name", "Kampanya"))
	c.root_id = str(data.get("root_id", ""))
	for k in data["maps"]:
		var m := MapData.new()
		m.from_dict(data["maps"][k])
		c.maps[m.id] = m
	c.characters = (data.get("characters", {}) as Dictionary).duplicate(true)
	var ph = data.get("photos", {})
	if typeof(ph) == TYPE_DICTIONARY:
		c.photos = ph
	if not c.maps.has(c.root_id) and not c.maps.is_empty():
		c.root_id = c.maps.keys()[0]
	return c
