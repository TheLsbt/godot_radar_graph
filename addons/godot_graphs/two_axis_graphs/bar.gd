@tool
extends './two_axis_graph.gd'


## Gets the steps for the x axis, this should only return floats of the "x" component.
func get_x_axis_steps() -> PackedFloat32Array:
	_cache()
	var view_rect := get_view_rect()
	var y_axis := get_y_axis_rect()
	var steps: PackedFloat32Array = []
	var total_items_width := items.size() * item_width
	var spacing = (view_rect.size.x - total_items_width) / (items.size() + 1)

	for i in items.size():
		var x: float = spacing + i * (item_width + spacing)
		var center :=  (x + item_width / 2) + y_axis.end.x
		steps.append(center)
	return steps


## Gets the steps for the y axis, this should only return floats of the "y" component.
func get_y_axis_steps() -> PackedFloat32Array:
	_cache()
	var view_rect := get_view_rect()
	var steps: PackedFloat32Array = []
	var v := max_value
	while v > min_value:
		steps.append((v / max_value) * view_rect.size.y)
		v -= cosmetic_step
	return steps


func get_item_template() -> Dictionary[String, Dictionary]:
	return {
			"title": {
				"default": "",
				"type": TYPE_STRING,
				"dirty_when_set": true,
				"redraw_when_set": true
			},
			"color": {
				"default": Color.BLACK,
				"type": TYPE_COLOR,
				"redraw_when_set": true
			},
			"value": {
				"default": 0.0,
				"type": TYPE_FLOAT,
				"redraw_when_set": true,
				"func": func(i: int, v: Variant): return set_item_value(i, v)
			}
	}
