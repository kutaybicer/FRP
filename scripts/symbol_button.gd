class_name SymbolButton
extends Button
## Sembol paletindeki önizlemeli düğme.

var symbol_type := ""


func _init(t: String) -> void:
	symbol_type = t
	custom_minimum_size = Vector2(46, 46)
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	tooltip_text = Defs.symbol_name(t)


func _draw() -> void:
	SymbolPainter.draw_symbol(self, symbol_type, size / 2.0, minf(size.x, size.y) * 0.36)
