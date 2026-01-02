@tool
extends Control

# TODO: Throw a error when the primary x axis (label) is not a Label type of scale for the Bar Graph.

enum ScalePrimaryType { NONE, PRIMARY_X, PRIMARY_Y }
enum Direction { HORIZONTAL=0, VERTICAL=1 }

const Scale = preload('uid://bbggwqqw868h0')
const Util = preload('uid://cwb6uwluafyoh')
const Data = preload('uid://culmu1s7oyvyh')

# When the graph is set to vertical the scales need to change accordingly, so the x scale would be "labels".
@export var direction := Direction.HORIZONTAL

@export var index_count := 5
@export var min_value := 0.0
@export var max_value := 100.0

@export var bar_width := 16.0
@export var bar_seperation := 5.0
@export var scale_seperation := 5.0

@export var allow_dynamic_min_max := false
@export var dynamic_min_max_snap := 0.0

var dataset_groups := {
	0: [
		{"color": Color.PINK, "values": [-20, 20, 30, 40, 50]},
		{"color": Color.BLUE, "values": [10, 20, 30, 40, [10, 30]]},
		{"color": Color.CORAL, "values": [[10, 40], 20, 30, 40, 30]},
		],
	1: [
		{"color": Color.YELLOW, "values": [10, 20, 30, 40, 50]}
		],
	2: [
		{"color": Color.AQUAMARINE, "values": [10, 20, 30, 40, 50]}
		]
}


var scales: Array[Scale] = []
var primary_x_scale: Scale = null
var primary_y_scale: Scale = null


func _init() -> void:
	add_scale(
		Scale.ScaleMode.LABEL, Scale.ScalePosition.BOTTOM, {"count": index_count, "labels": Data.get_months(index_count)},
		ScalePrimaryType.PRIMARY_X
	)
	add_scale(Scale.ScaleMode.VALUE, Scale.ScalePosition.LEFT, {}, ScalePrimaryType.PRIMARY_Y)

	# Testing
	add_scale(Scale.ScaleMode.LABEL, Scale.ScalePosition.LEFT, {"count": 5,"labels": Data.get_months(5)})
	add_scale(Scale.ScaleMode.VALUE, Scale.ScalePosition.BOTTOM, {"min_value": 0.0, "max_value": 100.0, "step": 10})

	add_scale(Scale.ScaleMode.LABEL, Scale.ScalePosition.TOP, {"count": 5,"labels": Data.get_months(5)})
	add_scale(Scale.ScaleMode.VALUE, Scale.ScalePosition.TOP, {"min_value": 0.0, "max_value": 10.0, "step": 1.0})

	add_scale(Scale.ScaleMode.LABEL, Scale.ScalePosition.RIGHT, {"count": 5,"labels": Data.get_months(5)})
	add_scale(Scale.ScaleMode.VALUE, Scale.ScalePosition.RIGHT, {"min_value": 0.0, "max_value": 10.0, "step": 1.0})


## Adds a scale to the graph. If [param primary_type] is set to something other than
## [enum Scale.PrimaryType.None] it will override the primary scale for that axis.
func add_scale(mode: Scale.ScaleMode, pos: Scale.ScalePosition, info := {}, primary_type := ScalePrimaryType.NONE) -> Scale:
	var _scale := Scale.new()
	match primary_type:
		ScalePrimaryType.PRIMARY_X:
			primary_x_scale = _scale
		ScalePrimaryType.PRIMARY_Y:
			primary_y_scale = _scale

	if not info.has("to_label_callback"):
		match mode:
			Scale.ScaleMode.VALUE:
				info["to_label_callback"] = Util.tick_to_value_label
			Scale.ScaleMode.LABEL:
				info["to_label_callback"] = Util.tick_to_title_label

	_scale.mode = mode
	_scale.position = pos
	_scale.info = info
	_scale.graph = self
	scales.append(_scale)
	return _scale


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

	var snap := [
		Util.snap_floorf(drange[0], maxf(1, dynamic_min_max_snap)),
		Util.snap_ceilf(drange[1], maxf(1, dynamic_min_max_snap))]

	return snap


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	scales_drawer()

	var axis := int(direction)
	var inv_axis := 1 - axis

	var dynamic_min_max := get_dynamic_min_max()

	# Calculate the primary scale (based on direction), required to be in a range of  0 - 1
	var primary_label_scale := primary_x_scale if direction == Direction.HORIZONTAL else primary_y_scale
	if primary_label_scale.mode != Scale.ScaleMode.LABEL and false: # TODO: Remove false (only debug)
		printerr(" The primary scale for the selected [direction] is not of the correct type (ScaleMode.LABEL)")
		return
	var axis_scale_ticks := primary_label_scale.get_ticks()

	var view_rect := Rect2(134, 87, 1231, 683)

	draw_rect(view_rect, Color.CADET_BLUE, false, 2)

	#var middle: float = (min_value + max_value) / 2
	var middle: float = 0.0

	var sorted_dataset_groups := dataset_groups.keys()
	sorted_dataset_groups.sort()

	# We subtract the bar seperation from this segment to counter the way each bars positions are calculated.
	var segment := view_rect.size[axis] / index_count - bar_seperation
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

				var lo_px_offset := lo_percent * view_rect.size[inv_axis]
				var hi_px_offset := hi_percent * view_rect.size[inv_axis]

				# FIXME: group is a int but is the groups id not the index in which the group is "made".
				var axis_px_offset: float =\
					axis_scale_ticks[index] * view_rect.size[axis] + half_segment - group_bar_width / 2.0 + (group * bar_width) + bar_seperation * group

				#var px_x_position: float =\
					#xscale_ticks[index] * size.x + half_segment - group_bar_width / 2.0 + (group * bar_width) + bar_seperation * group

				var rect: Rect2 = Rect2(0, 0, 0, 0)
				rect.position[axis] = axis_px_offset + view_rect.position[axis]
				rect.position[inv_axis] = hi_px_offset + view_rect.position[inv_axis]
				rect.size[axis] = bar_width
				rect.size[inv_axis] = lo_px_offset - hi_px_offset
				draw_rect(rect, color, true)


## Calculates the basic rect, this only takes account scales on the same size. Use [param far_end]
## to tell the calculator to offset the rect to the far end of this [Control] node.[br][br]
## Returns a [Dictionary] where the key [code]rects[/code] is an array of the calculated rects
## and [code]total[/code] is the total width or height depending on [param axis].
func _calculate_basic_rect(axis: Vector2.Axis, scales_ref: PackedInt32Array, far_end := false) -> Dictionary:
	var inv_axis: int = 1 - axis
	var offset: float = size[inv_axis] if far_end else 0.0

	var rects: Array[Rect2] = []
	# Could be the total width or height depending on the axis.
	var total := 0.0

	for i in scales_ref:
		var _scale: Scale = scales[i]
		var scale_min_size := _scale.get_minimum_size()

		var rect: Rect2
		rect.position[inv_axis] = offset + total + scale_seperation
		rect.size[inv_axis] = scale_min_size[inv_axis]
		rect.size[axis] = size[axis]
		rects.append(rect)

		total += scale_min_size[inv_axis] + scale_seperation

	return {"rects": rects, "total": total}



## Completes the rect transforms on [param rects] by taking into account the other scales.
## Where [param offset_a] and [param offsetc] aligns with [param axis] and [param offset_b] aligns
## with the opposite of [param axis].
func _complete_rect_transforms(rects: Array[Rect2], axis: Vector2.Axis, offset_a: float, offset_b: float, offset_c: float) -> void:
	var inv_axis: int = 1 - axis
	for i in rects.size():
		var rect := rects[i]
		rect.position[axis] += offset_a
		rect.position[inv_axis] -= offset_b
		rect.size[axis] -= offset_a + offset_c
		rects[i] = rect


func scales_drawer() -> void:
	var min_max := get_dynamic_min_max()
	primary_y_scale.info.merge({"min_value": min_max[0], "max_value": min_max[1], "step": 20.0}, true)

	var left: PackedInt32Array = []
	var top: PackedInt32Array = []
	var right: PackedInt32Array = []
	var bottom: PackedInt32Array = []

	for s in scales.size():
		var _scale: Scale = scales[s]
		match _scale.position:
			Scale.ScalePosition.LEFT:
				left.append(s)
			Scale.ScalePosition.TOP:
				top.append(s)
			Scale.ScalePosition.RIGHT:
				right.append(s)
			Scale.ScalePosition.BOTTOM:
				bottom.append(s)


	var l := _calculate_basic_rect(Vector2.AXIS_Y, left)
	var total_left_width: float = l.get("total", 0.0)
	var left_rects: Array[Rect2] = l.get("rects", [])

	var t := _calculate_basic_rect(Vector2.AXIS_X, top)
	var total_top_height: float = t.get("total", 0.0)
	var top_rects: Array[Rect2] = t.get("rects", [])

	var r := _calculate_basic_rect(Vector2.AXIS_Y, right, size.x)
	var total_right_width: float = r.get("total", 0.0)
	var right_rects: Array[Rect2] = r.get("rects", [])

	var b := _calculate_basic_rect(Vector2.AXIS_X, bottom, size.y)
	var total_bottom_height: float = b.get("total", 0.0)
	var bottom_rects: Array[Rect2] = b.get("rects", [])

	_complete_rect_transforms(left_rects, Vector2.AXIS_Y, total_top_height, scale_seperation, total_bottom_height)
	_complete_rect_transforms(top_rects, Vector2.AXIS_X, total_left_width, scale_seperation, total_right_width)
	_complete_rect_transforms(right_rects, Vector2.AXIS_Y, total_top_height, total_right_width, total_bottom_height)
	_complete_rect_transforms(bottom_rects, Vector2.AXIS_X, total_left_width, total_bottom_height, total_right_width)

	var view_rect := Rect2(
		total_left_width, total_top_height,
		size.x - (total_right_width + total_left_width), size.y - (total_bottom_height + total_top_height)
	)
	draw_rect(view_rect, Color.PINK, false, 2)

	# NOTE: Debug code to show the bounds of each scale.
	for i in left.size():
		var rect := left_rects[i]
		var _scale := scales[left[i]]
		draw_rect(rect, Color.LIGHT_GREEN.darkened(i / float(left.size())))
		_scale.draw(rect, self)

	for i in top_rects.size():
		var rect := top_rects[i]
		var _scale := scales[top[i]]
		draw_rect(rect, Color.DARK_RED.darkened(i / float(top.size())))
		_scale.draw(rect, self)

	for i in right_rects.size():
		var rect := right_rects[i]
		var _scale := scales[right[i]]
		draw_rect(rect, Color.DARK_GREEN.darkened(i / float(right.size())))
		_scale.draw(rect, self)

	for i in bottom.size():
		var rect := bottom_rects[i]
		var _scale := scales[bottom[i]]
		draw_rect(rect, Color.LIGHT_CORAL.darkened(i / float(bottom.size())))
		_scale.draw(rect, self)
