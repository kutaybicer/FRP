extends Node
## Portre önbelleği (autoload: Portraits)
## Portreler SubViewport'larda shader ile bir kez çizilir, ImageTexture olarak saklanır.
## Harita jetonları ve listeler bu dokuları kullanır: hızlı ve her yakınlaştırmada pürüzsüz.

signal texture_ready(key: String)

const POOL := 4
const MAX_CACHE := 600

var _cache := {}
var _order: Array = []
var _queue: Array = []
var _queued := {}
var _vps: Array = []
var _canvases: Array = []
var _jobs: Array = []
var _busy := false
## Kampanyanın fotoğrafları (id -> PNG baytları). Campaign.photos ile aynı sözlük.
var photos: Dictionary = {}


func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/portrait.gdshader")
	for i in POOL:
		var vp := SubViewport.new()
		vp.size = Vector2i(256, 256)
		vp.transparent_bg = true
		vp.disable_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(vp)
		var c := Node2D.new()
		c.material = mat
		c.draw.connect(_draw_canvas.bind(i))
		vp.add_child(c)
		_vps.append(vp)
		_canvases.append(c)
		_jobs.append({})


static func key_of(look: Dictionary, size := 256) -> String:
	return "%d_%d" % [hash(var_to_str(look)), size]


func cached(key: String) -> Texture2D:
	return _cache.get(key, null)


## Önbellekte varsa dokuyu döndürür; yoksa sıraya koyar ve null döner (hazır olunca texture_ready).
func get_texture(look: Dictionary, size := 256) -> Texture2D:
	return request(key_of(look, size), look, size)


func request(key: String, look: Dictionary, size := 256) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var pid := str(look.get("photo", ""))
	if pid != "" and photos.has(pid):
		# yüklenen fotoğraf: boyanmış portre yerine, aynı altın çerçeveli yuvarlak içinde
		var tex := _photo_texture(photos[pid], size)
		if tex:
			_cache[key] = tex
			_order.append(key)
			return tex
	if not _queued.has(key):
		_queued[key] = true
		_queue.append({"key": key, "look": look.duplicate(true), "size": size})
	return null


func _process(_delta: float) -> void:
	if not _busy and not _queue.is_empty():
		_render_batch()


func _render_batch() -> void:
	_busy = true
	var n := mini(POOL, _queue.size())
	for i in n:
		var job: Dictionary = _queue.pop_front()
		_jobs[i] = job
		var vp: SubViewport = _vps[i]
		vp.size = Vector2i(job["size"], job["size"])
		_canvases[i].queue_redraw()
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	for i in n:
		var job: Dictionary = _jobs[i]
		var vp: SubViewport = _vps[i]
		var img := vp.get_texture().get_image()
		img.generate_mipmaps()
		var key: String = job["key"]
		_cache[key] = ImageTexture.create_from_image(img)
		_order.append(key)
		_queued.erase(key)
		_jobs[i] = {}
		texture_ready.emit(key)
	while _order.size() > MAX_CACHE:
		_cache.erase(_order.pop_front())
	_busy = false


## Kare fotoğrafı yuvarlak çerçeveye yerleştirir (kenarlar yumuşak, altın halka)
func _photo_texture(png: PackedByteArray, size: int) -> ImageTexture:
	var src := Image.new()
	if src.load_png_from_buffer(png) != OK:
		return null
	src.convert(Image.FORMAT_RGBA8)
	src.resize(size, size, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	var r_out := size * 0.5 - 1.0
	var ring := maxf(3.0, size * 0.035)
	var r_in := r_out - ring
	var gold := Color("c9a24a")
	var gold_d := Color("6b4f1d")
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > r_out + 0.5:
				continue
			var col: Color
			if d < r_in:
				col = src.get_pixel(x, y)
				col.a = 1.0
				# çerçeveye yakın hafif gölge
				col = col.darkened(clampf((d - (r_in - ring * 1.5)) / (ring * 1.5), 0.0, 1.0) * 0.35)
				if d > r_in - 0.5:
					col = col.lerp(gold_d, d - (r_in - 0.5))
			else:
				var t := (d - r_in) / ring
				col = gold_d.lerp(gold, 1.0 - absf(t - 0.45) * 2.0)
				col.a = clampf(r_out + 0.5 - d, 0.0, 1.0)
			out.set_pixel(x, y, col)
	out.generate_mipmaps()
	return ImageTexture.create_from_image(out)


## Seçilen resim dosyasını ortadan kare kırpar, küçültür ve PNG baytı olarak verir
static func photo_from_file(path: String, size := 512) -> PackedByteArray:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return PackedByteArray()
	var s := mini(img.get_width(), img.get_height())
	img = img.get_region(Rect2i((img.get_width() - s) / 2, (img.get_height() - s) / 2, s, s))
	img.convert(Image.FORMAT_RGBA8)
	if s != size:
		img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return img.save_png_to_buffer()


func _draw_canvas(i: int) -> void:
	var job: Dictionary = _jobs[i]
	if job.is_empty():
		return
	var s := float(job["size"])
	PortraitPainter.draw(_canvases[i], job["look"], Vector2(s, s) * 0.5, s * 0.5 - 1.0, true)
