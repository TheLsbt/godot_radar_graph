@tool
extends "./2axis_graph.gd"

# Make styling default here and customizable in a dataset.

@export var index_count: int = 4

@export_group("Range")
@export var max_value: float = 100
@export var step_count: int = 5
@export_group("Bar")
@export var bar_seperation: float = 5.0
@export var bar_thickness: float = 30

var _default_font := ThemeDB.fallback_font
var _default_font_size := ThemeDB.fallback_font_size
var _datasets: Array[Dictionary] = []
var _config: Dictionary = {}


func add_data(data: Dictionary) -> void:
	_datasets.append(data)


func _callback_get_tick_value(value: float, tick: int, ticks: PackedFloat32Array) -> String:
	return str(value)


## Returns an array with two elements, where [0] is the x scale and [1] is the y scale's bounds.
func get_scales() -> Array[Rect2]:
	var yscale: Dictionary = _config.get("yscale", {})
	var font: Font = yscale.get("font", _default_font)
	var font_size: int = yscale.get("font_size", _default_font_size)

	# Calculate the y scale.
	var minimum := 0.0
	# First calculate the biggest text size, we are looking for the width. Height come in useful
	# for calculating this controls minimum_size
	for i in step_count + 1:
		var value := max_value / step_count * i
		var title := _callback_get_tick_value(value, -1, [])
		var title_size :=\
			font.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
		minimum = maxi(minimum, title_size.x)

	var yscale_size := Vector2(minimum, size.y)

	# Calculate the x scale first.
	minimum = 0.0

	var segment := (size.x - yscale_size.x) / index_count

	var xscale: Dictionary = _config.get("xscale", {})
	var titles: Array = xscale.get("title", [])
	if titles.size() == 0:
		printerr("Cannot calculate xscale bounds, no title.")
		return []

	font = xscale.get("font", _default_font)
	font_size = xscale.get("font_size", _default_font_size)
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

	var view_rect := get_view_rect()
	var segment := view_rect.size.y / step_count

	for index in step_count + 1:
		ticks.append(segment * index)

	return ticks



func _update() -> void:
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

	var min_value := 0.0
	var max_value := 100.0

	var segment := view_rect.size.x / index_count

	for index in index_count:
		var pos: float = ((segment * index) + (segment / 2) - (group_thickness / 2))\
			+ view_rect.position.x

		for group_index in groups_keys_sorted:
			var acc_range := [0.0, 0.0]
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

				var pxlow := remap(low / max_value, 0, 1, 1, 0) * view_rect.end.y
				var pxhigh := remap(high / max_value, 0, 1, 1, 0) * view_rect.end.y

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

	for x in get_xscale_ticks():
		draw_line(
			Vector2(x + view_rect.position.x, view_rect.end.y),
			Vector2(x + view_rect.position.x, view_rect.end.y + 8), Color.PALE_TURQUOISE, 2)
	for y in get_yscale_ticks():
		draw_line(Vector2(view_rect.position.x, y), Vector2(view_rect.position.x - 8, y), Color.PALE_TURQUOISE, 2)


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_update()
