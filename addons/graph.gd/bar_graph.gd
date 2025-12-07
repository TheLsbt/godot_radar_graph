@tool
extends "./2axis_graph.gd"

# TODO: Make this calculated automatically based on the data passes into the script.
@export_group("Group")
@export var group_seperation: float = 20.0
@export_group("Bar")
@export var bar_seperation: float = 5.0
@export var bar_thickness: float = 30

var _datasets: Array[Dictionary] = []


func add_data(data: Dictionary) -> void:
	_datasets.append(data)


func _update() -> void:
	var view_rect := Rect2(Vector2.ZERO, size)

	var groups: Dictionary[int, Array] = {}
	for dataset in _datasets:
		groups.get_or_add(dataset.get("group", -1), []).append(dataset)

	var groups_keys_sorted := groups.keys()
	groups_keys_sorted.sort()

	"""
	There is a issue where the graph where when groups are calculated the accumulated values use
	the biggest one even when they are in a different index. The best idea is to swap indexs and
	groups so we loop through each group first and then step through the index.
	SO: sorted groups -> group -> loop each index
	"""

	# First calculate the groups first
	var group_thickness := group_seperation + (bar_thickness * groups.size())

	var index_count: int = 3
	var min_value := 0.0
	var max_value := 100.0

	var total_items_width := index_count * group_thickness
	var spacing = (view_rect.size.x - total_items_width) / (index_count + 1)


	for index in index_count:
		var pos: float = spacing + index * (group_thickness + spacing)

		for group_index in groups_keys_sorted:
			#var accumulated: Dictionary = {}
			var accumulated := 0.0
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

				match typeof(value):
					TYPE_FLOAT, TYPE_INT:
						low = accumulated
						high = low + value
						next = value
					TYPE_ARRAY:
						# Skip becuase the value isnt valid, might be a good idea to throw a
						# printerr.
						if value.size() == 0:
							continue
						elif value.size() == 1:
							low = accumulated
							high = low + value[0]
							next = value[0]
						else:
							low = accumulated + value[0]
							high = low + value[1]
							next = value[0] + value[1]
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

				accumulated += next


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_update()
