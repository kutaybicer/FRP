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


func _draw_canvas(i: int) -> void:
	var job: Dictionary = _jobs[i]
	if job.is_empty():
		return
	var s := float(job["size"])
	PortraitPainter.draw(_canvases[i], job["look"], Vector2(s, s) * 0.5, s * 0.5 - 1.0, true)
