@tool
extends "./2axis_graph.gd"

# TODO: Make styling default here and customizable in a dataset.
# FIXME: Dynamic min_max is not using the accumulated value (I think, am too tired to debug)


@export_group("Bar")
@export var bar_seperation: float = 5.0
@export var bar_thickness: float = 30


var groups: Dictionary[int, PackedInt32Array] = {}
var datasets: Array[Dictionary] = []

var _dynamic_min_value := 0.0
var _dynamic_max_value := 0.0



func _init() -> void:
	cache_dirty = true
	groups.clear()


func _get_tooltip(at_position: Vector2) -> String:
	_check_cache()

	for b in cache["bars"]:
		var rect: Rect2 = b.rect
		if rect.has_point(at_position):
			var dataset_ref: int = b.dataset_ref
			var dataset: Dictionary = datasets[dataset_ref]
			var value: float = b.value

			return str(dataset.label, ": ", value)

	return ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		cache_dirty = true
	elif what == NOTIFICATION_DRAW:
		if not is_node_ready():
			return

		for layer in get_layers():
			var method_name := layer + "_drawer"
			if has_method(method_name):
				call(method_name)
	elif what == NOTIFICATION_RESIZED:
		cache_dirty = true
		queue_redraw()


## Add a dataset, [param values] can be an array of floats, ints or array (containing at least 2 floats or ints).
## [codeblock]
## values = [1, 2.3, [1.0, 5]] # ✅ Every value is valid.
## values = [true, 2.3, [8]] # ❎ Contains unsupported values such as a bool and only on element in a range.
## [/codeblock]
func add_data(label: String, values: Array, group: int, bar_color: Color) -> void:
	var dataset: Dictionary = {
		"label": label,
		"values": values,
		"group": group,
		"bar_color": bar_color
	}
	datasets.append(dataset)
	groups.get_or_add(group, PackedInt32Array()).append(datasets.size() - 1)
	cache_dirty = true
	queue_redraw()


## Sets the value of a specific dataset
func set_value(dataset_ref: int, value_index: int, value) -> void:
	var dataset: Dictionary = datasets[dataset_ref]
	var values: Array = dataset["values"]
	if values.size() - 1 <= value_index:
		values.resize(value_index + 1)
	values[value_index] = value
	dataset["values"] = values
	cache_dirty = true
	queue_redraw()


## Returns an array or float or int.
## Returns (min_value + max_value / 2) when [param value_index] is not valid.
func get_value(dataset_ref: int, value_index: int):
	var dataset: Dictionary = datasets[dataset_ref]
	var values: Array = dataset["values"]
	if value_index >= values.size() :
		return (min_value + max_value) / 2
	return values[value_index]


## See [method get_value]. This method returns the 2nd index if the value is a range.
func get_value_single(dataset_ref: int, value_index: int) -> float:
	var value = get_value(dataset_ref, value_index)

	match typeof(value):
		TYPE_ARRAY:
			if value.size() == 0:
				return (min_value + max_value) / 2
			elif value.size() == 1:
				return value[0]
			elif value.size() > 1:
				return value[1]
		TYPE_FLOAT or TYPE_INT:
			return value

	return (min_value + max_value) / 2



func get_dynamic_min_max_value() -> PackedFloat32Array:
	_dynamic_min_value = min_value
	_dynamic_max_value = max_value

	return [min_value, max_value]

	var groups_keys_sorted := groups.keys()
	groups_keys_sorted.sort()

	for index in index_count:
		for group_index in groups_keys_sorted:

			var acc_range: PackedFloat32Array = [0, 0]
			for dataset_ref: int in groups[group_index]:
				var dataset: Dictionary = datasets[dataset_ref]
				if index >= dataset["values"].size():
					continue

				var value = dataset["values"][index]

				# FIXME: Note, low and high should prob. be the average of min_value and max_value.
				# The begining value, this would be closest to 0
				var low := (min_value + max_value) / 2
				# The ending value, this would be furthest from 0
				var high := low
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
						printerr("Error calculating dynamic min max, invalid type for the value.")

				if next_hi:
					acc_range[1] += next
				else:
					acc_range[0] += next

			print(acc_range)

			_dynamic_min_value = min(_dynamic_min_value, acc_range[0])
			_dynamic_max_value = max(_dynamic_max_value, acc_range[1])

	return [_dynamic_min_value, _dynamic_max_value]


func create_cache() -> void:
	super()

	get_dynamic_min_max_value()

	var groups_keys_sorted := groups.keys()
	groups_keys_sorted.sort()
	cache["groups_keys_sorted"] = groups_keys_sorted

	# First calculate the groups first
	var group_thickness := bar_seperation + (bar_thickness * groups.size())
	cache["group_thickness"] = group_thickness

	var view_rect: Rect2 = cache["view_rect"]
	var yscale_minimum: Vector2 = cache["yscale_minimum"]
	var yscale_accumulated_height: float = cache["yscale_accumulated_height"]
	var yscale_safe_margin: float = cache["yscale_safe_margin"]
	var xscale_minimum: Vector2 = cache["xscale_minimum"]

	var cached_minimum_size := Vector2.ZERO
	cached_minimum_size.x = yscale_minimum.x + (group_thickness * index_count) + y_scale_tick_length
	cached_minimum_size.y = yscale_accumulated_height + yscale_safe_margin + maxf(xscale_minimum.y, x_scale_tick_length)

	cache["control.minimum_size"] = cached_minimum_size
	update_minimum_size()

	# Calculating the bars should come last at least 90% of the time.
	# They require alot of information (although could be scaled to a 0 - 1 value thus not needing view_rect).

	var median := (min_value + max_value) / 2

	var bars: Array[Dictionary] = []
	var segment := view_rect.size.x / index_count

	for index in index_count:
		var pos: float = ((segment * index) + (segment / 2) - (group_thickness / 2)) \
			+ view_rect.position.x

		for group_index in groups_keys_sorted:
			var acc_range: PackedFloat32Array = [0, 0]
			for dataset_ref: int in groups[group_index]:
				var dataset: Dictionary = datasets[dataset_ref]
				if index >= dataset["values"].size():
					continue

				var value = dataset["values"][index]
				var background_color: Color = Color(dataset.bar_color, 0.5)

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
							if value[1] >= median:
								low = acc_range[1] + value[0]
								high = acc_range[1] + value[1]
								next_hi = true
							else:
								low = acc_range[0] + value[0]
								high = acc_range[0] + value[1]
							next = value[1]
					_:
						printerr("Invalid type for the value")

				var pxlow := remap((low - _dynamic_min_value) / (_dynamic_max_value - _dynamic_min_value), 0, 1, 1, 0) * view_rect.size.y
				var pxhigh := remap((high - _dynamic_min_value) / (_dynamic_max_value - _dynamic_min_value), 0, 1, 1, 0) * view_rect.size.y

				var bar_rect := Rect2(
					Vector2(pos + (bar_seperation + bar_thickness) * group_index, pxhigh + view_rect.position.y),
					Vector2(bar_thickness, (pxlow - pxhigh))
					)

				bars.append({
					"rect": bar_rect.abs(),
					"dataset_ref": dataset_ref,
					"value": next
				})

				if next_hi:
					acc_range[1] += next
				else:
					acc_range[0] += next

	cache["bars"] = bars


	cache_dirty = false



func _get_minimum_size() -> Vector2:
	_check_cache()
	return cache["control.minimum_size"]


## The order each layer is drawn. To override a specific layer create a function following [code]<layer_name>_drawer[/code]
func get_layers() -> PackedStringArray:
	return ["grid", "graph_boarder", "bars", "scales"]


## Default drawer for the grid.
func grid_drawer() -> void:
	_check_cache()
	var view_rect: Rect2 = cache["view_rect"]
	var xscale_ticks := get_xscale_ticks()
	var xscale_grid: PackedVector2Array = []
	for i in xscale_ticks.size():
		var x := xscale_ticks[i]
		var pos := Vector2(x + view_rect.position.x, view_rect.end.y)

		xscale_grid.append(pos)
		xscale_grid.append(Vector2(pos.x, view_rect.position.y))

	var yscale_grid: PackedVector2Array = []
	var yscale_ticks_pos_cache: Array = cache["yscale_ticks_pos_cache"]
	var yscale_ticks := get_yscale_ticks()
	for i in yscale_ticks.size():
		var pos: Vector2 = yscale_ticks_pos_cache[i]
		yscale_grid.append(pos)
		yscale_grid.append(Vector2(view_rect.end.x, pos.y))

	draw_multiline(xscale_grid, x_scale_tick_color, x_scale_tick_width)
	draw_multiline(yscale_grid, y_scale_tick_color, y_scale_tick_width)


func graph_boarder_drawer() -> void:
	_check_cache()
	var view_rect: Rect2 = cache["view_rect"]
	draw_rect(view_rect, graph_boarder, false, graph_boarder_width)


## Default drawer for both scales.
func scales_drawer() -> void:
	_check_cache()
	var view_rect: Rect2 = cache["view_rect"]
	var xscale_ticks := get_xscale_ticks()

	var segment := view_rect.size.x / index_count

	var font: Font = get_or_default("x_scale_font", default_font)
	var font_size: int = get_or_default("x_scale_font_size", default_font_size)

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

	font = get_or_default("y_scale_font", default_font)
	font_size = get_or_default("y_scale_font_size", default_font_size)

	var yscale_minimum_width: float = cache.get("yscale.minimum_width", -1)
	var yscale_ticks_pos_cache: Array = cache["yscale_ticks_pos_cache"]
	var yscale_ticks := get_yscale_ticks()

	for i in yscale_ticks.size():
		var value := yscale_ticks[i] + _dynamic_min_value
		var percent := remap((value) / (_dynamic_max_value - _dynamic_min_value), 0, 1, 1, 0)
		var pos: Vector2 = yscale_ticks_pos_cache[i]

		font.draw_multiline_string(
			get_canvas_item(),
			Vector2(0, pos.y + font.get_descent(font_size)),
			yscale_tick_to_title(value),
			HORIZONTAL_ALIGNMENT_RIGHT,
			yscale_minimum_width,
			font_size
		)

		draw_line(pos, pos - Vector2(y_scale_tick_length, 0), y_scale_tick_color, y_scale_tick_width)


## Default drawer for all the bars.
func bars_drawer() -> void:
	_check_cache()
	var bars: Array[Dictionary] = cache["bars"]
	for b in bars:
		var rect: Rect2 = b.rect
		var dataset_ref: int = b.dataset_ref
		var bar_color: Color = datasets[dataset_ref].bar_color
		draw_rect(rect, bar_color, true)
