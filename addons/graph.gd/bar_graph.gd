@tool
extends "./2axis_graph.gd"

# TODO: Make styling default here and customizable in a dataset.

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
@export var x_scale_tick_length := 8.0
@export var x_scale_tick_width := 2.0
@export var x_scale_tick_color := Color.WHITE
@export_subgroup("Y Scale", "y_scale")
@export var y_scale_font: Font
@export var y_scale_font_size: int = 16
@export var y_scale_tick_length := 8.0
@export var y_scale_tick_width := 2.0
@export var y_scale_tick_color := Color.WHITE
@export_group("Graph")
@export var graph_boarder := Color.WHITE
@export var graph_boarder_width := 2.0


var _default_font := ThemeDB.fallback_font
var _default_font_size := ThemeDB.fallback_font_size
var _datasets: Array[Dictionary] = []

var _cache: Dictionary = {}
var _is_dirty := true

# TODO: Streamline overriding.
"""
Callbacks:
	_get_ticks_callback() - for the scales
	_get_tick_value_callback(value, tick: int, ticks: Array) - for the yscale
"""

func _ready() -> void:
	_is_dirty = true


func add_data(data: Dictionary) -> void:
	_datasets.append(data)


func _callback_get_tick_value(value: float) -> String:
	return str(snappedf(value, 0.01))


func _do_cache() -> void:
	if not _is_dirty:
		return

	_cache.clear()

	# Cache the groups.
	# Sort the groups so that they can be iterated over and stacked easier.
	# NOTE: Groups currently copy the entire dataset but only storing the values and maybe
	# 		the background_color would be more optimal.
	var groups: Dictionary[int, Array] = {}
	for dataset in _datasets:
		groups.get_or_add(dataset.get("group", -1), []).append(dataset)
	_cache["groups"] = groups

	var groups_keys_sorted := groups.keys()
	groups_keys_sorted.sort()
	_cache["groups_keys_sorted"] = groups_keys_sorted

	# First calculate the groups first
	var group_thickness := bar_seperation + (bar_thickness * groups.size())
	_cache["group_thickness"] = group_thickness

	var font: Font = get_or_default("y_scale_font", _default_font)
	var font_size: int = get_or_default("y_scale_font_size", _default_font_size)

	var yscale_accumulated_height := 0.0

	# Cache the y scale first, information we get out of this includes the minimum height for the
	# yscale as well as the minimum width.
	var yscale_minimum := -Vector2.INF
	var yscale_ticks := get_yscale_ticks()
	for i in yscale_ticks.size():
		var value := yscale_ticks[i] + min_value
		var title := _callback_get_tick_value(value)
		var title_size := font.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		yscale_minimum = yscale_minimum.max(title_size)
		yscale_accumulated_height += title_size.y

	_cache["yscale.minimum_width"] = yscale_minimum.x
	var ysm_title := _callback_get_tick_value(yscale_ticks[0] + min_value)
	var ysm_title_size := font.get_string_size(
		ysm_title.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var yscale_safe_margin := ysm_title_size.y / 2

	if x_scale_titles.size() == 0:
		printerr("Cannot cache x scale, cache may be incomplete.")
		return

	# This determines the length of each column along xscale
	var xscale_width := size.x - yscale_minimum.x
	var xscale_column_segment := xscale_width / index_count

	var xscale_minimum := -Vector2.INF

	font = get_or_default("x_scale_font", _default_font)
	font_size = get_or_default("x_scale_font_size", _default_font_size)

	for index in index_count:
		var title: String = x_scale_titles[wrapi(index, 0, x_scale_titles.size())]
		var title_size := font.get_multiline_string_size(
			title, HORIZONTAL_ALIGNMENT_CENTER, xscale_column_segment, font_size)
		xscale_minimum = xscale_minimum.max(title_size)

	var xscale_rect := Rect2(
		Vector2(yscale_minimum.x, (size.y - xscale_minimum.y) + yscale_safe_margin),
		Vector2(xscale_width, xscale_minimum.y)
	)
	_cache["xscale_rect"] = xscale_rect

	#draw_rect(xscale_rect, Color.PALE_VIOLET_RED)
	var yscale_rect := Rect2(
		Vector2(0, yscale_safe_margin),
		Vector2(yscale_minimum.x, size.y - xscale_minimum.y)
	)
	_cache["yscale_rect"] = yscale_rect


	var view_rect := Rect2(
		Vector2(yscale_rect.size.x + y_scale_tick_length, yscale_safe_margin), Vector2(size.x - yscale_rect.size.x - y_scale_tick_length, size.y - maxf(xscale_minimum.y, x_scale_tick_length) - yscale_safe_margin),
	)
	_cache["view_rect"] = view_rect

	var yscale_ticks_pos_cache := []
	# This cannot be calculated at the same time as the yscale becuase it requires the view rect.
	for value in get_yscale_ticks():
		var percent := remap((value) / (max_value - min_value), 0, 1, 1, 0)
		var pos := Vector2(view_rect.position.x, view_rect.size.y * percent + yscale_safe_margin)
		yscale_ticks_pos_cache.append(pos)

	_cache["yscale_ticks_pos_cache"] = yscale_ticks_pos_cache

	var cached_minimum_size := Vector2.ZERO
	cached_minimum_size.x = yscale_minimum.x + (group_thickness * index_count) + y_scale_tick_length
	cached_minimum_size.y = yscale_accumulated_height + yscale_safe_margin + maxf(xscale_minimum.y, x_scale_tick_length)

	_cache["control.minimum_size"] = cached_minimum_size
	update_minimum_size()

	_is_dirty = false


func get_xscale_ticks() -> PackedFloat32Array:
	var ticks: PackedFloat32Array = []

	var view_rect: Rect2 = _cache["view_rect"]
	var segment := view_rect.size.x / index_count

	for index in index_count + 1:
		ticks.append(segment * index)

	return ticks


## Returns the steps in value space.
func get_yscale_ticks() -> PackedFloat32Array:
	var ticks: PackedFloat32Array = []

	var segment := (max_value - min_value) / step_count

	for index in step_count + 1:
		ticks.append(segment * index)

	return ticks


func _update() -> void:
	for layer in get_layers():
		var method_name := layer + "_drawer"
		if has_method(method_name):
			call(method_name)


func get_or_default(property: StringName, default: Variant = null) -> Variant:
	var value := get(property)
	if value == null:
		return default
	return value


func _process(delta: float) -> void:
	_is_dirty = true
	queue_redraw()


func _draw() -> void:
	_update()


func _get_minimum_size() -> Vector2:
	_do_cache()
	return _cache["control.minimum_size"]


## The order each layer is drawn. To override a specific layer create a function following [code]<layer_name>_drawer[/code]
func get_layers() -> PackedStringArray:
	return ["grid", "graph_boarder", "bars", "scales"]


## Default drawer for the grid.
func grid_drawer() -> void:
	_do_cache()
	var view_rect: Rect2 = _cache["view_rect"]
	var xscale_ticks := get_xscale_ticks()
	var xscale_grid: PackedVector2Array = []
	for i in xscale_ticks.size():
		var x := xscale_ticks[i]
		var pos := Vector2(x + view_rect.position.x, view_rect.end.y)

		xscale_grid.append(pos)
		xscale_grid.append(Vector2(pos.x, view_rect.position.y))

	var yscale_grid: PackedVector2Array = []
	var yscale_ticks_pos_cache: Array = _cache["yscale_ticks_pos_cache"]
	var yscale_ticks := get_yscale_ticks()
	for i in yscale_ticks.size():
		var pos: Vector2 = yscale_ticks_pos_cache[i]
		yscale_grid.append(pos)
		yscale_grid.append(Vector2(view_rect.end.x, pos.y))

	draw_multiline(xscale_grid, x_scale_tick_color, x_scale_tick_width)
	draw_multiline(yscale_grid, y_scale_tick_color, y_scale_tick_width)


func graph_boarder_drawer() -> void:
	_do_cache()
	var view_rect: Rect2 = _cache["view_rect"]
	draw_rect(view_rect, graph_boarder, false, graph_boarder_width)


## Default drawer for both scales.
func scales_drawer() -> void:
	_do_cache()
	var view_rect: Rect2 = _cache["view_rect"]
	var xscale_ticks := get_xscale_ticks()

	var segment := view_rect.size.x / index_count

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

		draw_line(pos, pos + Vector2(0, x_scale_tick_length),x_scale_tick_color, x_scale_tick_width)

	font = get_or_default("y_scale_font", _default_font)
	font_size = get_or_default("y_scale_font_size", _default_font_size)

	var yscale_minimum_width: float = _cache.get("yscale.minimum_width", -1)
	var yscale_ticks_pos_cache: Array = _cache["yscale_ticks_pos_cache"]
	var yscale_ticks := get_yscale_ticks()

	for i in yscale_ticks.size():
		var value := yscale_ticks[i] + min_value
		var percent := remap((value) / (max_value - min_value), 0, 1, 1, 0)
		var pos: Vector2 = yscale_ticks_pos_cache[i]

		font.draw_multiline_string(
			get_canvas_item(),
			Vector2(0, pos.y + font.get_descent(font_size)),
			_callback_get_tick_value(value),
			HORIZONTAL_ALIGNMENT_RIGHT,
			yscale_minimum_width,
			font_size
		)

		draw_line(pos, pos - Vector2(y_scale_tick_length, 0), y_scale_tick_color, y_scale_tick_width)


## Default drawer for all the bars.
func bars_drawer() -> void:
	_do_cache()

	var view_rect: Rect2 = _cache["view_rect"]

	var groups: Dictionary[int, Array] = _cache["groups"]
	var groups_keys_sorted: Array = _cache["groups_keys_sorted"]
	var group_thickness: float = _cache["group_thickness"]

	var segment := view_rect.size.x / index_count

	for index in index_count:
		var pos: float = ((segment * index) + (segment / 2) - (group_thickness / 2)) \
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

				var pxlow := remap((low - min_value) / (max_value - min_value), 0, 1, 1, 0) * view_rect.size.y
				var pxhigh := remap((high - min_value) / (max_value - min_value), 0, 1, 1, 0) * view_rect.size.y

				var bar := Rect2(
					Vector2(pos + (bar_seperation + bar_thickness) * group_index, pxhigh + view_rect.position.y),
					Vector2(bar_thickness, (pxlow - pxhigh))
					)
				draw_rect(
					bar, background_color
				)

				if next_hi:
					acc_range[1] += next
				else:
					acc_range[0] += next
