@tool
extends Node2D


var default_font := ThemeDB.fallback_font
var default_font_size := ThemeDB.fallback_font_size


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var text := "January\n(Month)"
	var string_size := default_font.get_multiline_string_size(
		text, HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size
	)
	var ascent := default_font.get_ascent(default_font_size)
	draw_multiline_string(
		default_font, Vector2(0, ascent), text, HORIZONTAL_ALIGNMENT_LEFT, string_size.x, default_font_size)
	draw_line(Vector2(0, 0), Vector2(0, string_size.y), Color.AQUA, 2.0)
