class_name CameraRig
extends Camera2D
## Sağ/orta tuşla sürükle = kaydır, tekerlek = yakınlaştır (imlecin olduğu yere).

const MIN_ZOOM := 0.1
const MAX_ZOOM := 8.0

var _panning := false


func _ready() -> void:
	make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT:
				_panning = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					zoom_at(1.15, get_global_mouse_position())
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					zoom_at(1.0 / 1.15, get_global_mouse_position())
	elif event is InputEventMouseMotion and _panning:
		pan_screen(event.relative)
	elif event is InputEventMagnifyGesture:
		zoom_at(event.factor, get_global_mouse_position())
	elif event is InputEventPanGesture:
		pan_screen(-event.delta * 20.0)


func pan_screen(relative: Vector2) -> void:
	position -= relative / zoom.x


func zoom_at(factor: float, world_point: Vector2) -> void:
	var old := zoom.x
	var nz := clampf(old * factor, MIN_ZOOM, MAX_ZOOM)
	position = world_point - (world_point - position) * old / nz
	zoom = Vector2(nz, nz)


func fit_rect(rect: Rect2, margin := 0.9) -> void:
	var vs := get_viewport_rect().size
	var z := minf(vs.x / maxf(rect.size.x, 1.0), vs.y / maxf(rect.size.y, 1.0)) * margin
	z = clampf(z, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(z, z)
	position = rect.get_center()
