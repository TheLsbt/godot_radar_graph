extends RefCounted

const Util = preload('uid://cwb6uwluafyoh')

enum ScalePosition { LEFT, TOP, RIGHT, BOTTOM }
enum ScaleMode { VALUE, LABEL }
enum TitleMode {
	## When the scale is set to default, the title's are drawn next to the ticks.
	DEFAULT,
	## When drawing is inline, the titles are drawn inline to maximize space. It keeps the integrity
	## of the text by keeping it up right.
	INLINE
	 }

var default_font := ThemeDB.fallback_font
var default_font_size := ThemeDB.fallback_font_size

var position: ScalePosition
var mode: ScaleMode

var tick_length := 8.0
var title_mode := TitleMode.INLINE

var info: Dictionary = {}
var graph: Control = null


func get_minimum_size() -> Vector2:
	var minimum_size := Vector2.ZERO
	var ticks := get_ticks()
	match position:
		ScalePosition.LEFT:
			for i in ticks.size():
				var t: float = ticks[i]

				var callback: Callable = info.get("to_label_callback", null)

				var label := Util.tick_to_value_label(i, ticks, info)
				if mode == ScaleMode.LABEL:
					label = Util.tick_to_title_label(i, ticks, info)

				var string_size := default_font.get_string_size(label)

				minimum_size.x = maxf(minimum_size.x, string_size.x)
				minimum_size.y += string_size.y

			if title_mode == TitleMode.DEFAULT:
				minimum_size.x += tick_length

		ScalePosition.BOTTOM:
			for t in ticks:
				var string_size := default_font.get_multiline_string_size(
					"abc", HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size)
				minimum_size.y = string_size.y

				if title_mode == TitleMode.DEFAULT:
					minimum_size.y += tick_length


	return minimum_size


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

		ScaleMode.VALUE:
			var step: float = info.get("step", 0)
			var min_value: float = info.get("min_value", 0)
			var max_value: float = info.get("max_value", 100)
			var v: float = min_value

			while v <= float(max_value):
				ticks.append(Util.normalize_value(v, min_value, max_value))
				v += step

	return ticks


func draw(rect: Rect2, graph: Control) -> void:
	var ticks := get_ticks()
	var visual_last_tick: bool = info.get("visual_last_tick", false)

	var segment: float
	if ticks.size() > 1:
		segment = ticks[1] - ticks[0]
	elif ticks.size() == 1:
		ticks[0]

	var px_segment := segment * rect.size.x

	var title := "abc"
	var font_ascent := default_font.get_ascent(default_font_size)

	var direction := position_to_direction(position)


	match position:
		ScalePosition.LEFT:
			#print(ticks)
			for i in ticks.size():
				var t: float = ticks[i]

				var percent := remap(t, 0, 1, 1, 0)
				var pos := Vector2(rect.end.x, rect.size.y * percent + rect.position.y)

				var label := Util.tick_to_value_label(i, ticks, info)
				if mode == ScaleMode.LABEL:
					label = Util.tick_to_title_label(i, ticks, info)


				var font_width := default_font.get_multiline_string_size(label).x
				var label_offset := Vector2(-font_width, 0)
				if title_mode == TitleMode.DEFAULT:
					label_offset += Vector2(-tick_length, default_font.get_descent())

				default_font.draw_multiline_string(
					graph.get_canvas_item(), pos + label_offset, label, HORIZONTAL_ALIGNMENT_RIGHT
				)

				graph.draw_line(pos, pos + direction * tick_length, Color.LIGHT_CYAN, 2)


		ScalePosition.BOTTOM:
			for t in ticks:
				var pos := Vector2(rect.size.x * t + rect.position.x, rect.position.y)
				graph.draw_line(pos, pos + direction * tick_length, Color.LIGHT_CYAN, 2)

				var label_offset := Vector2(0, font_ascent)

				if title_mode == TitleMode.DEFAULT:
					label_offset = Vector2(-px_segment / 2.0, font_ascent) + direction * tick_length

				default_font.draw_multiline_string(
					graph.get_canvas_item(), pos + label_offset, title, HORIZONTAL_ALIGNMENT_CENTER, px_segment
				)

			if visual_last_tick:
				graph.draw_circle(
					Vector2(rect.size.x + rect.position.x, rect.end.y),
					4, Color(Color.AQUAMARINE, 0.5))


func position_to_direction(p: ScalePosition) -> Vector2:
	match p:
		ScalePosition.LEFT:
			return Vector2.LEFT
		ScalePosition.TOP:
			return Vector2.UP
		ScalePosition.RIGHT:
			return Vector2.RIGHT
		ScalePosition.BOTTOM:
			return Vector2.DOWN
	return Vector2.ZERO
