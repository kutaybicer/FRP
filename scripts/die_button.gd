class_name DieButton
extends Button
## Zar tepsisindeki zar düğmesi (zarın şeklini çizer).

var sides := 20


func _init(s: int) -> void:
	sides = s
	custom_minimum_size = Vector2(62, 70)
	focus_mode = Control.FOCUS_NONE
	tooltip_text = "d%d at" % s


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.42)
	Dice.draw_die(self, sides, c, minf(size.x, size.y) * 0.3, 0.0, "")
	var font: Font = Defs.font_title
	var t := "d%d" % sides if sides != 100 else "d%"
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, Vector2((size.x - w) * 0.5, size.y - 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f2ead7"))
