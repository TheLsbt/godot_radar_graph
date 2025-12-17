@tool
extends "./2axis_graph.gd"

# Make styling default here and customizable in a dataset.

# TODO: Pad the top of the graph to accomodate the y scale becuase it is half a font too tall.

@export var index_count: int = 4

@export_group("Range")
@export var min_value: float = 0
@export var max_value: float = 100
@export var step_count: int = 5
@export_group("Bar")
@export var bar_seperation: float = 5.0
@export var bar_thickness: float = 30
@export_group("Scales")
@export_subgroup("X Scale", "x_scale")
@export var x_scale_titles: PackedStringArray = []
@export var x_scale_font: Font
@export var x_scale_font_size: int = 16
@export_subgroup("Y Scale", "y_scale")
@export var y_scale_font: Font
@export var y_scale_font_size: int = 16


var _default_font := ThemeDB.fallback_font
var _default_font_size := ThemeDB.fallback_font_size
var _datasets: Array[Dictionary] = []

var _cache: Dictionary = {}
var _is_dirty := true


func add_data(data: Dictionary) -> void:
	_datasets.append(data)


func _callback_get_tick_value(value: float) -> String:
	return str(snappedf(value, 0.2))


func _do_cache() -> void:
	if not _is_dirty:
		return

	_cache.clear()

	var font: Font = get_or_default("y_scale_font", _default_font)
	var font_size: int = get_or_default("y_scale_font_size", _default_font_size)

	var yscale_accumulated_height := 0.0

	# Cache the y scale first
	var yscale_minimum := -Vector2.INF
	var yscale_ticks := get_yscale_ticks()
	for i in yscale_ticks.size():
		var value := yscale_ticks[i] + min_value
		var title := _callback_get_tick_value(value)
		var title_size := font.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		yscale_minimum = yscale_minimum.max(title_size)
		yscale_accumulated_height += title_size.y

	_cache["yscale.minimum_width"] = yscale_minimum.y

	_cache["control.minimum_size"] = Vector2(yscale_minimum.x, yscale_accumulated_height)
	update_minimum_size()

	_is_dirty = false

## Returns an array with two elements, where [0] is the x scale and [1] is the y scale's bounds.
func get_scales() -> Array[Rect2]:
	var font: Font = get_or_default("y_scale_font", _default_font)
	var font_size: int = get_or_default("y_scale_font_size", _default_font_size)


	# Calculate the y scale.
	var minimum := 0.0
	# First calculate the biggest text size, we are looking for the width. Height come in useful
	# for calculating this controls minimum_size
	for i in step_count + 1:
		var value := max_value / step_count * i
		var title := _callback_get_tick_value(value)
		var title_size :=\
			font.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
		minimum = maxi(minimum, title_size.x)

	_cache["yscale.minimum_width"] = minimum
	var yscale_size := Vector2(minimum, size.y)

	# Calculate the x scale next.
	minimum = 0.0

	var segment := (size.x - yscale_size.x) / index_count

	var titles: Array = x_scale_titles
	if titles.size() == 0:
		printerr("Cannot calculate xscale bounds, no title.")
		return []

	font = get_or_default("x_scale_font", _default_font)
	font_size = get_or_default("x_scale_font", _default_font_size)
	for index in index_count:
		var title: String = titles[wrapi(index, 0, titles.size())]
		var title_size :=\
			font.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, segment, font_size)
		minimum = maxi(minimum, title_size.y)

	var xscale_size := Vector2(size.x, minimum)

	var xscale_rect := Rect2(
		Vector2(yscale_size.x, size.y - xscale_size.y), Vector2(size.x - yscale_size.x, xscale_size.y)
	)
	#draw_rect(xscale_rect, Color.PALE_VIOLET_RED)
	var yscale_rect := Rect2(
		Vector2.ZERO, Vector2(yscale_size.x, size.y - xscale_size.y)
	)
	#draw_rect(yscale_rect, Color.LIME_GREEN)
	return [xscale_rect, yscale_rect]


func get_view_rect() -> Rect2:
	var scales := get_scales()
	var rect := Rect2(
		Vector2(scales[1].size.x, 0), Vector2(size.x - scales[1].size.x, size.y - scales[0].size.y),
	)
	return rect


func get_xscale_ticks() -> PackedFloat32Array:
	var ticks: PackedFloat32Array = []

	var view_rect := get_view_rect()
	var segment := view_rect.size.x / index_count

	for index in index_count + 1:
		ticks.append(segment * index)

	return ticks


func get_yscale_ticks() -> PackedFloat32Array:
	var ticks: PackedFloat32Array = []

	var segment := (max_value - min_value) / step_count

	for index in step_count + 1:
		ticks.append(segment * index)

	return ticks



func _update() -> void:
	_do_cache()
	# TODO: Calculate the grid line

	var view_rect := get_view_rect()
	draw_rect(view_rect, Color.MAGENTA, false, 3)

	# Sort the groups so that they can be iterated over and stacked easier.
	# NOTE: Groups currently copy the entire dataset but only storing the values and maybe
	# 		the background_color would be more optimal.
	var groups: Dictionary[int, Array] = {}
	for dataset in _datasets:
		groups.get_or_add(dataset.get("group", -1), []).append(dataset)

	var groups_keys_sorted := groups.keys()
	groups_keys_sorted.sort()

	# First calculate the groups first
	var group_thickness := bar_seperation + (bar_thickness * groups.size())

	var segment := view_rect.size.x / index_count

	for index in index_count:
		var pos: float = ((segment * index) + (segment / 2) - (group_thickness / 2))\
			+ view_rect.position.x

		for group_index in groups_keys_sorted:
			var acc_range: PackedFloat32Array = [0, 0]
			for dataset in groups[group_index]:
				if index >= dataset["values"].size():
					continue

				var value = dataset["values"][index]
				var background_color: Color = dataset.background_color

				# The begining value, this would be closest to 0
				var low := 0.0
				# The ending value, this would be furthest from 0
				var high := 0.0
				# The next value to be added to accumulated
				var next := 0.0
				var next_hi := false

				if typeof(value) == TYPE_ARRAY and value.size() == 1:
					value = value[0]

				match typeof(value):
					TYPE_FLOAT, TYPE_INT:
						if value >= 0:
							low = acc_range[1]
							next_hi = true
						else:
							low = acc_range[0]

						high = low + value
						next = value
					TYPE_ARRAY:
						# Skip becuase the value isnt valid, might be a good idea to throw a
						# printerr.
						if value.size() == 0:
							continue
						else:
							if value[0] >= 0:
								low = acc_range[1] + value[0]
								high = acc_range[1] + value[1]
								next_hi = true
							else:
								low = acc_range[0] + value[0]
								high = acc_range[0] + value[1]
							next = value[1]
					_:
						printerr("Invalid type for the value")

				var pxlow := remap((low - min_value) / (max_value - min_value), 0, 1, 1, 0) * view_rect.end.y
				var pxhigh := remap((high - min_value) / (max_value - min_value), 0, 1, 1, 0) * view_rect.end.y

				var bar := Rect2(
					Vector2(pos + (bar_seperation + bar_thickness) * group_index, pxhigh),
					Vector2(bar_thickness, pxlow - pxhigh)
					)
				draw_rect(
					bar, background_color
				)

				if next_hi:
					acc_range[1] += next
				else:
					acc_range[0] += next

	var xscale_ticks := get_xscale_ticks()

	var font: Font = get_or_default("x_scale_font", _default_font)
	var font_size: int = get_or_default("x_scale_font_size", _default_font_size)

	for i in xscale_ticks.size():
		var x := xscale_ticks[i]
		var pos := Vector2(x + view_rect.position.x, view_rect.end.y)

		if i == xscale_ticks.size() - 1:
			break

		font.draw_multiline_string(
			get_canvas_item(),
			pos + Vector2(0, font.get_ascent(font_size)),
			x_scale_titles[wrapi(i, 0, x_scale_titles.size())],
			HORIZONTAL_ALIGNMENT_CENTER,
			segment
		)

		draw_line(pos, pos + Vector2(0, 8), Color.PALE_TURQUOISE, 2)

	font = get_or_default("y_scale_font", _default_font)
	font_size = get_or_default("y_scale_font_size", _default_font_size)

	var yscale_minimum_width: float = _cache.get("yscale.minimum_width", -1)
	for value in get_yscale_ticks():
		var percent := remap((value) / (max_value - min_value), 0, 1, 1, 0)
		var pos := Vector2(view_rect.position.x, view_rect.size.y * percent)

		font.draw_multiline_string(
			get_canvas_item(),
			Vector2(0, view_rect.size.y * percent + font.get_descent(font_size)),
			_callback_get_tick_value(value + min_value),
			HORIZONTAL_ALIGNMENT_LEFT,
			yscale_minimum_width,
			font_size
		)

		draw_line(pos, pos - Vector2(8, 0), Color.PALE_TURQUOISE, 2)


func get_or_default(property: StringName, default: Variant = null) -> Variant:
	var value := get(property)
	if value == null:
		return default
	return value


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_update()


func _get_minimum_size() -> Vector2:
	_do_cache()
	return _cache["control.minimum_size"]
