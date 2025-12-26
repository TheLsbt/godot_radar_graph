extends RefCounted

enum ScalePosition { LEFT, TOP, RIGHT, BOTTOM }
enum ScaleMode { VALUE, LABEL }

var default_font := ThemeDB.fallback_font
var default_font_size := ThemeDB.fallback_font_size

var position: ScalePosition
var mode: ScaleMode

var info: Dictionary = {}


func get_minimum_size(_available_space: Vector2) -> Vector2:
	return Vector2.ZERO


## Returns the ticks based on a 0 - 1 scale based in [member info].
func get_ticks() -> PackedFloat32Array:
	var ticks: PackedFloat32Array = []
	match mode:
		ScaleMode.LABEL:
			var count: int = info.get("count", 0)

			for i in range(count):
				ticks.append(i / float(count))

			if info.get("include_end"):
				ticks.append(1)

	return ticks


func draw(rect: Rect2, graph: Control) -> void:
	var tick_length := 8.0
	var ticks := get_ticks()
	var title_mode: String = info.get("title_draw_mode", "segment")
	var visual_last_tick: bool = info.get("visual_last_tick", false)

	var segment: float = ticks[0]
	if ticks.size() > 1:
		segment = ticks[1] - ticks[0]

	var px_segment := segment * rect.size.x

	var title := "abc"
	var font_ascent := default_font.get_ascent(default_font_size)

	match position:
		ScalePosition.BOTTOM:
			var dir := Vector2.DOWN
			for t in ticks:
				var pos := Vector2(rect.size.x * t + rect.position.x, rect.position.y)
				graph.draw_line(pos, pos + dir * tick_length, Color.LIGHT_CYAN, 2)

				var label_offset := Vector2(0, font_ascent)

				if title_mode == "tick":
					label_offset = Vector2(-px_segment / 2.0, font_ascent) + dir * tick_length

				default_font.draw_multiline_string(
					graph.get_canvas_item(), pos + label_offset, title, HORIZONTAL_ALIGNMENT_CENTER, px_segment
				)

			if visual_last_tick:
				graph.draw_circle(
					Vector2(rect.size.x + rect.position.x, rect.end.y),
					4, Color(Color.AQUAMARINE, 0.5))
