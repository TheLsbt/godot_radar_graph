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


	# First calculate the groups first
	var group_thickness := group_seperation + (bar_thickness * groups.size())

	var index_count: int = 3
	var min_value := 0.0
	var max_value := 100.0

	var total_items_width := index_count * group_thickness
	var spacing = (view_rect.size.x - total_items_width) / (index_count + 1)


	for i in index_count:
		var pos: float = spacing + i * (group_thickness + spacing)

		for d in groups_keys_sorted:
			var accumulated_value := 0.0
			for g in groups[d].size():
				var group: Dictionary = groups[d][g]

				# Skip becuase there is no value available for the current index
				if i >= group["values"].size():
					continue

				var value = group["values"][i]

				var range_begin: float = 0.0
				var range_end: float = 0.0

				var value_type = typeof(value)
				if value_type == TYPE_ARRAY:
					range_begin = accumulated_value + value[0]
					range_end = range_begin + value[1]
				elif value_type == TYPE_FLOAT or value_type == TYPE_INT:
					range_begin = accumulated_value
					range_end = accumulated_value + value

				#print(type_string(typeof(value)))

				var map_begin = remap(range_begin / max_value, 0, 1, 1, 0) * view_rect.end.y
				var map_end = remap(range_end / max_value, 0, 1, 1, 0) * view_rect.end.y


				var color: Color = group.background_color
				draw_circle(
					Vector2(pos + (bar_seperation + bar_thickness) * d, map_begin),
					4, color
					)
				draw_circle(
					Vector2(pos + (bar_seperation + bar_thickness) * d, map_end),
					4, Color(color, 0.5)
					)

				var bar := Rect2(
					Vector2(pos + (bar_seperation + bar_thickness) * d, map_end),
					Vector2(bar_thickness, map_begin - map_end)
				)
				draw_rect(bar, Color(color, 0.5))


				#var bar := Rect2(
				#Vector2(pos + (bar_seperation + bar_thickness) * (d - 1), view_rect.position.y),
				#Vector2(
					#bar_thickness,
					#remap((min_value + range_end) / max_value, 0, 1, 1, 0) * view_rect.end.y)
				#)
#
				#bar.position.y =\
					#remap((min_value + (range_begin  - range_end)) / max_value, 0, 1, 1, 0) * view_rect.end.y



				accumulated_value += range_end
				# TODO: Make accumulated value also a range with a upper and lower.
				"""
				If the range_begin is less than the lower range we move the lower range down
				Otherwise we move the upper up.
				"""



	# Calculate the bounding box for each direction
	pass


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_update()
