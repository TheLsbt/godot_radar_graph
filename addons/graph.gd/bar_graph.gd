@tool
extends "./2axis_graph.gd"

# Make styling default here and customizable in a dataset.

@export_group("Bar")
@export var bar_seperation: float = 5.0
@export var bar_thickness: float = 30

var _datasets: Array[Dictionary] = []


func add_data(data: Dictionary) -> void:
	_datasets.append(data)


func _update() -> void:
	var full_rect := Rect2(Vector2.ZERO, size)
	# Calculate the time (x) scale
	var xscale := Rect2(Vector2(0, full_rect.end.y - 20), Vector2(full_rect.end.x, 20))
	draw_rect(xscale, Color(Color.PALE_VIOLET_RED, 0.5))

	# TODO: Calculate the grid line

	var view_rect := Rect2(Vector2.ZERO, Vector2(full_rect.size.x, full_rect.size.y - 20))

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

	var index_count: int = 3
	var min_value := 0.0
	var max_value := 100.0

	var segment := view_rect.size.x / index_count


	for index in index_count:
		var pos: float = (segment * index) + (segment / 2) - (group_thickness / 2)

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


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_update()
