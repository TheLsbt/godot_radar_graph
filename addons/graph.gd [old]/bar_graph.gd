@tool
extends "2axis_graph.gd"

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


## See [method get_value]. This method returns a range even if the value is a single float / int.
func get_value_range(dataset_ref: int, value_index: int) -> Array:
	var value = get_value(dataset_ref, value_index)

	var median := (min_value + max_value) / 2

	match typeof(value):
		TYPE_ARRAY:
			# FIXME: Should prob. print a err
			if value.size() == 0:
				return [median, median]
			elif value.size() == 1:
				return [median, value]
			else:
				return value
		TYPE_FLOAT or TYPE_INT:
			return [median, value]

	# FIXME: An error should prob go here too.
	return [median, median]



func get_dynamic_min_max_value() -> PackedFloat32Array:
	_dynamic_min_value = min_value
	_dynamic_max_value = max_value

	if not allow_dynamic_range:
		return [min_value, max_value]

	var groups_keys_sorted := groups.keys()
	groups_keys_sorted.sort()

	var median := (min_value + max_value) / 2

	for index in index_count:
		for group_index in groups_keys_sorted:
			var acc_range: PackedFloat32Array = [0, 0]
			for dataset_ref: int in groups[group_index]:
				var dataset: Dictionary = datasets[dataset_ref]
				if index >= dataset["values"].size():
					continue

				var value = dataset["values"][index]

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
						if value > median:
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
							# We can safely assume the array range has more than one element becuase
							# we flatten the array if there is only one element.
							if value[1] > median:
								low = acc_range[1] + value[0]
								high = acc_range[1] + value[1]
								next_hi = true
							else:
								low = acc_range[0] + value[0]
								high = acc_range[0] + value[1]
							next = value[1]
					_:
						printerr("Invalid type for the value")

				if next_hi:
					acc_range[1] += next
				else:
					acc_range[0] += next

			_dynamic_min_value = minf(_dynamic_min_value, acc_range[0])
			_dynamic_max_value = maxf(_dynamic_max_value, acc_range[1])

	#return [_dynamic_min_value, _dynamic_max_value]
	#print("> ", snappedf(_dynamic_min_value, -dynamic_range_steps), ", ", snappedf(_dynamic_max_value, dynamic_range_steps))
	return [snappedf(_dynamic_min_value, -dynamic_range_steps), snappedf(_dynamic_max_value, dynamic_range_steps)]


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
						if value > median:
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
							# We can safely assume the array range has more than one element becuase
							# we flatten the array if there is only one elemtn.2
							if value[1] > median:
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
				draw_string(
					default_font,
					Vector2(pos + (bar_seperation + bar_thickness) * group_index, pxlow + view_rect.position.y),
					str(pxlow), 0, -1, 16, background_color)
				draw_string_outline(
					default_font,
					Vector2(pos + (bar_seperation + bar_thickness) * group_index, pxlow + view_rect.position.y),
					str(pxlow), 0, -1, 16, 1, Color.BLACK)

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


func _get_minimum_size() -> Vector2:
	_check_cache()
	return cache["control.minimum_size"]


## The order each layer is drawn. To override a specific layer create a function following [code]<layer_name>_drawer[/code]
func get_layers() -> PackedStringArray:
	return ["grid", "graph_boarder", "bars", "scales"]


## Default drawer for all the bars.
func bars_drawer() -> void:
	_check_cache()
	var bars: Array[Dictionary] = cache["bars"]
	for b in bars:
		var rect: Rect2 = b.rect
		var dataset_ref: int = b.dataset_ref
		var bar_color: Color = datasets[dataset_ref].bar_color
		draw_rect(rect, bar_color, true)
