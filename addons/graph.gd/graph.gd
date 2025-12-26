@tool
extends Control

const Scale = preload('uid://bbggwqqw868h0')

@export var index_count := 5
@export var min_value := 0.0
@export var max_value := 100.0

@export var bar_width := 16.0
@export var bar_seperation := 5.0

@export var allow_dynamic_min_max := false

var dataset_groups := {
	0: [
		{"color": Color.PINK, "values": [10, 20, 30, 40, 50]},
		{"color": Color.BLUE, "values": [10, 20, 30, 40, [10, 30]]},
		{"color": Color.CORAL, "values": [[0, 40], 20, 30, 40, 30]},
		],
	1: [
		{"color": Color.YELLOW, "values": [10, 20, 30, 40, 50]}
		],
	2: [
		{"color": Color.AQUAMARINE, "values": [10, 20, 30, 40, 50]}
		]
}


var primary_x_scale: Scale = null


func _init() -> void:
	primary_x_scale = Scale.new()
	primary_x_scale.mode = Scale.ScaleMode.LABEL
	primary_x_scale.info = {"count": index_count, "labels": ["a", "b"]}


## Returns an array with two elements, where index 0 is the `dynamic min value` and and
## `dynamic max value`.
func get_dynamic_min_max() -> PackedFloat32Array:
	var drange: PackedFloat32Array = [min_value, max_value]

	if not allow_dynamic_min_max:
		return drange

	var middle: float = 0.0

	#var middle: float = (min_value + max_value) / 2

	var sorted_dataset_groups := dataset_groups.keys()
	sorted_dataset_groups.sort()

	var group_bar_width := dataset_groups.keys().size() * bar_width + bar_seperation

	for group in sorted_dataset_groups:
		for index in index_count:
			var accumulated := [middle, middle]
			for dataset in dataset_groups[group]:
				var values: Array = dataset["values"]

				if index >= values.size():
					break

				var value = values[index]
				var color: Color = dataset["color"]

				# lo and hi just determine the rect, it is up to use to order them correctly, if not
				# the bars may be able to draw ontop of one another.
				# hi determines the top of it and lo the bottom.

				var hi: float
				var lo: float

				# Flatten the array if there is only one element.
				if typeof(value) == TYPE_ARRAY and value.size() == 1:
					value = value[0]

				match typeof(value):
					TYPE_ARRAY:
						# If there is only one element in the value we continue and skip this index.
						if value.size() == 0:
							break
						# We can asume there is more than one element left becuase we flatten the array if
						# there is one element.
						else:
							# eg. [10, -20]
							if value[0] > value[1]:
								hi = accumulated[1] + value[0]
								lo = accumulated[1] + value[1]
								accumulated[1] += value[1]
							# eg. [8, 15]
							else:
								hi = accumulated[0] + value[1]
								lo = accumulated[0] + value[0]
								accumulated[0] += value[1]

					TYPE_FLOAT, TYPE_INT:
						if value < accumulated[1]:
							hi = accumulated[1]
							lo = hi + value

							accumulated[1] += value
						else:
							hi = accumulated[0] + value
							lo = accumulated[0]

							accumulated[0] += value


				drange[0] = minf(accumulated[1], drange[0])
				drange[1] = maxf(accumulated[0], drange[1])

	return drange


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var dynamic_min_max := get_dynamic_min_max()

	# Calculate the primary x scale, required to be in a range of  0 - 1
	var xscale_ticks := primary_x_scale.get_ticks()


	#var middle: float = (min_value + max_value) / 2
	var middle: float = 0.0

	var sorted_dataset_groups := dataset_groups.keys()
	sorted_dataset_groups.sort()

	var segment := size.x / index_count
	var half_segment := segment / 2

	var group_bar_width := dataset_groups.keys().size() * bar_width + bar_seperation

	for group in sorted_dataset_groups:
		for index in index_count:
			var accumulated := [middle, middle]
			for dataset in dataset_groups[group]:
				var values: Array = dataset["values"]

				if index >= values.size():
					break

				var value = values[index]
				var color: Color = dataset["color"]

				# lo and hi just determine the rect, it is up to use to order them correctly, if not
				# the bars may be able to draw ontop of one another.
				# hi determines the top of it and lo the bottom.

				var hi: float
				var lo: float

				# Flatten the array if there is only one element.
				if typeof(value) == TYPE_ARRAY and value.size() == 1:
					value = value[0]

				match typeof(value):
					TYPE_ARRAY:
						# If there is only one element in the value we continue and skip this index.
						if value.size() == 0:
							break
						# We can asume there is more than one element left becuase we flatten the array if
						# there is one element.
						else:
							# eg. [10, -20]
							if value[0] > value[1]:
								hi = accumulated[1] + value[0]
								lo = accumulated[1] + value[1]
								accumulated[1] += value[1]
							# eg. [8, 15]
							else:
								hi = accumulated[0] + value[1]
								lo = accumulated[0] + value[0]
								accumulated[0] += value[1]

							# I want to calculate where the hi neededs to be maybe checking
							# if value[1] < accumulated[1]:
							# The above if checks if the

					TYPE_FLOAT, TYPE_INT:
						if value < accumulated[1]:
							hi = accumulated[1]
							lo = hi + value

							accumulated[1] += value
						else:
							hi = accumulated[0] + value
							lo = accumulated[0]

							accumulated[0] += value


				var lo_percent := remap((lo - dynamic_min_max[0]) / (dynamic_min_max[1] - dynamic_min_max[0]), 0.0, 1.0, 1.0, 0.0)
				var hi_percent := remap((hi - dynamic_min_max[0]) / (dynamic_min_max[1] - dynamic_min_max[0]), 0.0, 1.0, 1.0, 0.0)

				var lo_px_offset := lo_percent * size.y
				var hi_px_offset := hi_percent * size.y

				var px_x_position: float =\
					xscale_ticks[index] * size.x + half_segment - group_bar_width / 2.0 + (group * bar_width) + bar_seperation * group

				var rect := Rect2(
					Vector2(px_x_position, hi_px_offset),
					Vector2(bar_width, lo_px_offset - hi_px_offset)
				)

				draw_rect(rect, color, true)
