class_name MapData
extends RefCounted
## Tek bir haritanın tüm verisi. Hücre katmanları (arazi, bölge, sis) + nesneler.
##
## Nesneler sade Dictionary olarak tutulur (kaydetme / geri alma kolay olsun diye):
##   sembol: {type, pos: Vector2, name, notes, size, link: String(harita id)}
##   yol:    {type, points: PackedVector2Array, name, width}
##   yazı:   {text, pos: Vector2, size: int, color: Color}
##   bölge:  {id: int(1..255), name, color: Color, notes}

var id := ""
var name := "Yeni Harita"
var kind := 0
var cols := 120
var rows := 80
var scale := 10.0       # bir hücre kaç birim
var unit := "km"
var parent_id := ""
var notes := ""
var terrain := PackedByteArray()
var region := PackedByteArray()
var fog := PackedByteArray()      # 1 = açık (görülmüş)
var fog_enabled := false
var regions: Array = []
var paths: Array = []
var symbols: Array = []
var labels: Array = []
var tokens: Array = []    # {char: karakter id, pos: Vector2, hp: int (yaratıklar için), label: String}
var party_pos := Vector2(-1, -1)

# kayda girmeyen görünüm durumu
var has_view := false
var view_pos := Vector2.ZERO
var view_zoom := 1.0


func setup(p_cols: int, p_rows: int, fill: int) -> void:
	cols = p_cols
	rows = p_rows
	var n := cols * rows
	terrain.resize(n)
	terrain.fill(fill)
	region.resize(n)
	region.fill(0)
	fog.resize(n)
	fog.fill(0)


func idx(c: int, r: int) -> int:
	return r * cols + c


func in_bounds(c: int, r: int) -> bool:
	return c >= 0 and r >= 0 and c < cols and r < rows


func pixel_size() -> Vector2:
	return Vector2(cols, rows) * Defs.CELL


func get_region(rid: int) -> Dictionary:
	for r in regions:
		if int(r["id"]) == rid:
			return r
	return {}


func free_region_id() -> int:
	var used := {}
	for r in regions:
		used[int(r["id"])] = true
	for i in range(1, 256):
		if not used.has(i):
			return i
	return -1


func resize(new_cols: int, new_rows: int, fill: int) -> void:
	var t := PackedByteArray()
	var rg := PackedByteArray()
	var f := PackedByteArray()
	var n := new_cols * new_rows
	t.resize(n)
	t.fill(fill)
	rg.resize(n)
	rg.fill(0)
	f.resize(n)
	f.fill(0)
	for r in mini(rows, new_rows):
		for c in mini(cols, new_cols):
			var o := r * cols + c
			var d := r * new_cols + c
			t[d] = terrain[o]
			rg[d] = region[o]
			f[d] = fog[o]
	cols = new_cols
	rows = new_rows
	terrain = t
	region = rg
	fog = f


func to_dict() -> Dictionary:
	return {
		"id": id, "name": name, "kind": kind, "cols": cols, "rows": rows,
		"scale": scale, "unit": unit, "parent_id": parent_id, "notes": notes,
		"terrain": terrain.duplicate(), "region": region.duplicate(), "fog": fog.duplicate(),
		"fog_enabled": fog_enabled,
		"regions": regions.duplicate(true), "paths": paths.duplicate(true),
		"symbols": symbols.duplicate(true), "labels": labels.duplicate(true), "tokens": tokens.duplicate(true),
		"party_pos": party_pos,
	}


func from_dict(d: Dictionary) -> void:
	id = str(d.get("id", id))
	name = str(d.get("name", "Harita"))
	kind = int(d.get("kind", 0))
	cols = int(d.get("cols", 120))
	rows = int(d.get("rows", 80))
	scale = float(d.get("scale", 10.0))
	unit = str(d.get("unit", "km"))
	parent_id = str(d.get("parent_id", ""))
	notes = str(d.get("notes", ""))
	terrain = (d.get("terrain", PackedByteArray()) as PackedByteArray).duplicate()
	region = (d.get("region", PackedByteArray()) as PackedByteArray).duplicate()
	fog = (d.get("fog", PackedByteArray()) as PackedByteArray).duplicate()
	var n := cols * rows
	if terrain.size() != n:
		terrain.resize(n)
	if region.size() != n:
		region.resize(n)
	if fog.size() != n:
		fog.resize(n)
	fog_enabled = bool(d.get("fog_enabled", false))
	regions = (d.get("regions", []) as Array).duplicate(true)
	paths = (d.get("paths", []) as Array).duplicate(true)
	symbols = (d.get("symbols", []) as Array).duplicate(true)
	labels = (d.get("labels", []) as Array).duplicate(true)
	tokens = (d.get("tokens", []) as Array).duplicate(true)
	party_pos = d.get("party_pos", Vector2(-1, -1))
