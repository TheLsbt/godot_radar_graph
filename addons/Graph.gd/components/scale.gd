extends RefCounted

# TODO: Make ScaleMode.VALUE render labels ontop of the ticks and ScaleMode.LABEL render them in the segment.
# TODO: Make a way for the labels on the sides to know where they are so their alignent is correct

const Util = preload('uid://cwb6uwluafyoh')

enum ScalePosition { LEFT, TOP, RIGHT, BOTTOM }
enum ScaleMode { VALUE, LABEL }

var default_font := ThemeDB.fallback_font
var default_font_size := ThemeDB.fallback_font_size

var position: ScalePosition
var mode: ScaleMode

var tick_length := 8.0
var tick_width := 2

var info: Dictionary = {}
var graph: Control = null


func update(with: Dictionary) -> void:
	info = info.merged(with, true)


func get_minimum_size() -> Vector2:
	var minimum_size := Vector2.ZERO
	var ticks := get_ticks()

	var index := 0 if position in [ScalePosition.LEFT, ScalePosition.RIGHT] else 1
	var inv_index := 1 - index

	for i in ticks.size():
		var t: float = ticks[i]

		var callback: Callable = info.get("to_label_callback", null)
		var label := callback.call(i, ticks, info)

		var string_size := default_font.get_multiline_string_size(
			label, HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size)

		# Calculates the minimum size for the scale regardless of the position.

		minimum_size[index] = maxf(minimum_size[index], string_size[index])
		minimum_size[inv_index] += string_size[inv_index]

	if _is_label_inline_with_ticks() or not position in [ScalePosition.TOP, ScalePosition.BOTTOM]:
		minimum_size[index] += tick_length


	return minimum_size


func _is_label_inline_with_ticks() -> bool:
	return true if mode == ScaleMode.VALUE else false


## Returns the ticks based on a 0 - 1 scale based in [member info].
func get_ticks() -> PackedFloat32Array:
	var ticks: PackedFloat32Array = []
	var label_inline_with_ticks := _is_label_inline_with_ticks()
	match mode:
		ScaleMode.LABEL:
			var count: int = info.get("count", 0)

			if label_inline_with_ticks:
				for i in range(count - 1):
					ticks.append(i / float(count - 1))
				ticks.append(1.0)
			else:
				for i in range(count):
					ticks.append(i / float(count))


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
	# Make this a option in info.
	var label_inline_with_ticks := _is_label_inline_with_ticks()

	var ticks := get_ticks()
	var visual_last_tick: bool = info.get("visual_last_tick", false)

	var segment: float
	if ticks.size() > 1:
		segment = ticks[1] - ticks[0]
	elif ticks.size() == 1:
		ticks[0]


	var font_ascent := default_font.get_ascent(default_font_size)
	var font_descent := default_font.get_descent(default_font_size)

	var direction := position_to_direction(position)


	match position:
		ScalePosition.LEFT, ScalePosition.RIGHT:
			var px_segment := segment * rect.size.y

			# Draw the ticks on the end (visual only), ticks on the sides are inverted so we use
			# position.y becuase end.y is technically 0.
			if not is_equal_approx(ticks[-1], 1.0):
				var x := rect.end.x if position == ScalePosition.LEFT else rect.position.x
				_draw_tick(Vector2(x, rect.position.y), direction)

			for i in ticks.size():
				var t: float = remap(ticks[i], 0, 1, 1, 0)
				var pos: Vector2

				if position == ScalePosition.LEFT:
					pos = Vector2(rect.end.x, rect.size.y * t + rect.position.y)
				elif position == ScalePosition.RIGHT:
					pos = Vector2(rect.position.x, rect.size.y * t + rect.position.y)

				var to_label_callback: Callable = info.get("to_label_callback", null)
				var label := to_label_callback.call(i, ticks, info)

				# The size of the label (in px) offset to begin at the topleft.
				var string_size := default_font.get_multiline_string_size(
					label, HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size)

				var half_string_height := string_size.y / 2.0

				var label_offset: Vector2
				if position == ScalePosition.LEFT:
					if label_inline_with_ticks:
						label_offset.x = -(string_size.x + tick_length)
						# This doesnt feel right, but when getting the strings size it it like 4x the
						# size its supposed to be.
						label_offset.y = font_ascent - string_size.y / 2
					else:
						label_offset.x = -(string_size.x + tick_length)
						label_offset.y = font_ascent - (string_size.y - px_segment) / 2 - px_segment

				elif position == ScalePosition.RIGHT:
					if label_inline_with_ticks:
						label_offset.x = tick_length
						label_offset.y = font_ascent - string_size.y / 2
					else:
						label_offset.x = tick_length
						label_offset.y = font_ascent - (string_size.y - px_segment) / 2 - px_segment

				default_font.draw_multiline_string(
					graph.get_canvas_item(), pos + label_offset, label, HORIZONTAL_ALIGNMENT_RIGHT
				)
				_draw_tick(pos, direction)


		ScalePosition.TOP, ScalePosition.BOTTOM:
			var px_segment := segment * rect.size.x

			# Draw the ticks on the end (visual only).
			if not is_equal_approx(ticks[-1], 1.0):
				var y := rect.end.y if position == ScalePosition.TOP else rect.position.y
				_draw_tick(Vector2(rect.end.x, y), direction)

			for i in ticks.size():
				var t: float = ticks[i]
				var pos: Vector2

				if position == ScalePosition.TOP:
					pos = Vector2(rect.size.x * t + rect.position.x, rect.end.y)
				elif position == ScalePosition.BOTTOM:
					pos = Vector2(rect.size.x * t + rect.position.x, rect.position.y)

				var to_label_callback: Callable = info.get("to_label_callback", null)
				var label := to_label_callback.call(i, ticks, info)

				# The size of the label (in px) offset to begin at the topleft.
				var string_size := default_font.get_multiline_string_size(
					label, 0, -1, default_font_size)

				var label_offset: Vector2
				if position == ScalePosition.TOP:
					if label_inline_with_ticks:
						label_offset.x = -px_segment / 2
						label_offset.y = font_ascent - string_size.y - tick_length
					else:
						label_offset.y = font_ascent - string_size.y
				elif position == ScalePosition.BOTTOM:
					if label_inline_with_ticks:
						label_offset = Vector2(-px_segment / 2.0, font_ascent) + direction * tick_length
					else:
						label_offset = Vector2(0, font_ascent)

				default_font.draw_multiline_string(
					graph.get_canvas_item(), pos + label_offset, label,
					HORIZONTAL_ALIGNMENT_CENTER, px_segment, default_font_size
				)
				_draw_tick(pos, direction)

	# Draw the line that shows how wide the scale is.
	match position:
		ScalePosition.LEFT:
			graph.draw_line(
				Vector2(rect.end.x, rect.position.y - tick_width / 2),
				Vector2(rect.end.x, rect.end.y + tick_width / 2), Color.AQUAMARINE, tick_width)
		ScalePosition.TOP:
			graph.draw_line(
				Vector2(rect.position.x - tick_width / 2, rect.end.y),
				Vector2(rect.end.x + tick_width / 2, rect.end.y), Color.AQUAMARINE, tick_width)
		ScalePosition.RIGHT:
			graph.draw_line(
				Vector2(rect.position.x, rect.position.y - tick_width / 2),
				Vector2(rect.position.x, rect.end.y + tick_width / 2), Color.AQUAMARINE, tick_width)
		ScalePosition.BOTTOM:
			graph.draw_line(
				Vector2(rect.position.x - tick_width / 2, rect.position.y),
				Vector2(rect.end.x + tick_width / 2, rect.position.y), Color.AQUAMARINE, tick_width)


func _draw_tick(at: Vector2, direction: Vector2) -> void:
	graph.draw_line(at, at + direction * tick_length, Color.LIGHT_CYAN, tick_width)


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
