class_name PortraitRect
extends TextureRect
## Önbellekten portre gösteren kutu. Doku hazır olunca kendini günceller.

var look: Dictionary = {}
var res := 256
var _key := ""


func _init(l: Dictionary = {}, px := 64, r := 256) -> void:
	res = r
	custom_minimum_size = Vector2(px, px)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	look = l


func _ready() -> void:
	Portraits.texture_ready.connect(_on_texture_ready)
	refresh()


func set_look(l: Dictionary) -> void:
	look = l
	refresh()


func refresh() -> void:
	if look.is_empty():
		return
	_key = Portraits.key_of(look, res)
	var t := Portraits.request(_key, look, res)
	if t:
		texture = t


func _on_texture_ready(k: String) -> void:
	if k == _key:
		texture = Portraits.cached(k)
