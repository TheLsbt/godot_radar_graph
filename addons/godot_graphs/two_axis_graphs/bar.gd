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


func set_item_title(item: int, title: String) -> void:
	if item < 0 or item > items.size():
		return
	items[item].title = title
	dirty = true
	queue_redraw()


func set_item_value(item: int, value: float) -> float:
	if item < 0 or item > items.size():
		return value
	items[item].value = clampf(snappedf(value, step), min_value, max_value)
	if rounded:
		items[item].value = roundf(items[item].value)
	queue_redraw()
	return items[item].value


func set_item_bar_color(item: int, color: Color) -> void:
	if item < 0 or item > items.size():
		printerr("Out of bounds, cannot set color for item: ", item)
		return
	items[item]["color"] = color
	queue_redraw()


func get_item_properties() -> Array[Dictionary]:
	return [{
			"name": "title",
			"type": TYPE_STRING,
		},
		{
			"name": "value",
			"type": TYPE_FLOAT
		},
		{
			"name": "color",
			"type": TYPE_COLOR
		}]


func item_get(item: int, property: String) -> Variant:
	if item < 0 or item > items.size() or not property in items[item]:
		return null

	return items[item].get(property, null)


func item_set(item: int, property: String, value: Variant) -> bool:
	if item < 0 or item > items.size() or not property in items[item]:
		return false

	match property:
		"value":
			set_item_value(item, value)
			return true
		"title":
			set_item_title(item, value)
			return true
		"color":
			set_item_bar_color(item, value)
			return true
	return false


func item_property_can_revert(item: int, property: String) -> bool:
	if item < 0 or item > items.size() or not property in items[item]:
		return false

	var current := get("items/%d/%s" % [ item, property ])
	match property:
		"title": return current != ""
		"value": return is_equal_approx(current, min_value)
		"color": return current != Color.BLACK

	return false


func item_property_get_revert(item: int, property: String) -> Variant:
	if item < 0 or item > items.size() or not property in items[item]:
		return null

	match property:
		"title": return ""
		"value": return min_value
		"color": return Color.BLACK

	return null
