@tool
extends "../bases/two_axis_graph.gd"


@export_group("Style")
@export_subgroup("Y Axis", "y_axis")
@export var y_axis_font: Font:
	set(val):
		y_axis_font = val
		dirty = true
		queue_redraw()
	get:
		if not y_axis_font:
			return ThemeDB.fallback_font
		return y_axis_font
@export var y_axis_font_size := 16:
	set(v):
		y_axis_font_size = v
		dirty = true
		queue_redraw()

@export_subgroup("X Axis", "x_axis")
@export var x_axis_font: Font:
	set(val):
		x_axis_font = val
		dirty = true
		queue_redraw()
	get:
		if not x_axis_font:
			return ThemeDB.fallback_font
		return x_axis_font
@export var x_axis_font_size := 16:
	set(val):
		x_axis_font_size = val
		dirty = true
		queue_redraw()
@export var x_axis_item_width: float = 5.0:
	set(v):
		x_axis_item_width = v
		dirty = true
		queue_redraw()
## Minimum spacing around the item
@export var x_axis_seperation: float = 2.0:
	set(v):
		x_axis_seperation = v
		dirty = true
		queue_redraw()


func get_default_draw_order() -> PackedStringArray:
	return ["x_axis", "x_axis_text", "y_axis", "y_axis_text", "view_rect", "grid", "bars"]


func try_fix_values() -> void:
	min_value = minf(min_value, max_value)
	max_value = maxf(min_value, max_value)

	for item in _items.size():
		set_item_value(item, _items[item].get("value", 0.0))
	notify_property_list_changed()


func _rg_draw_x_axis_text() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	var total_items_width := _items.size() * x_axis_item_width
	var spacing = (view_rect.size.x - total_items_width) / (_items.size() + 1)

	# Draw the titles along the x-axis
	for i in _items.size():
		var title: String = _items[i].title
		var x: float = spacing + i * (x_axis_item_width + spacing)
		var pos = Vector2(x + y_axis.end.x, x_axis.position.y + x_axis_font.get_ascent(x_axis_font_size))
		x_axis_font.draw_multiline_string(canvas_item, pos, title, HORIZONTAL_ALIGNMENT_CENTER,
			x_axis_item_width, x_axis_font_size)


func _rg_draw_y_axis_text() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()
	var v := max_value
	while v > min_value:
		var val = (v / max_value) * view_rect.size.y + y_axis_font.get_descent(y_axis_font_size)
		var display_value := str(abs(max_value - v) + min_value)
		var string_size := y_axis_font.get_string_size(display_value,
			HORIZONTAL_ALIGNMENT_CENTER, y_axis.size.x, y_axis_font_size)
		y_axis_font.draw_string(canvas_item, Vector2(y_axis.position.x, val),
			display_value, HORIZONTAL_ALIGNMENT_CENTER, y_axis.size.x, y_axis_font_size)
		v -= cosmetic_step


func _rg_draw_bars() -> void:
	var view_rect := get_view_rect()

	var total_items_width := _items.size() * x_axis_item_width
	var spacing = (view_rect.size.x - total_items_width) / (_items.size() + 1)

	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()
	var canvas_item := get_canvas_item()

	for i in _items.size():
		var item: Dictionary = _items[i]
		var title: String = item.title
		var value: float = item.value
		var color: Color = item.color

		var x: float = spacing + i * (x_axis_item_width + spacing)
		var pos = Vector2(x + y_axis.end.x, x_axis.position.y + x_axis_font.get_ascent())

		var percent := (value - min_value) / max_value

		var rect := Rect2(Vector2(pos.x, 0), Vector2(
			x_axis_item_width, size.y - _biggset_title_vector.y))
		rect.position.y = percent * view_rect.size.y

		# This is the actual bar
		var r := Rect2(
			Vector2(pos.x + x_axis_item_width, view_rect.end.y),
			Vector2(-x_axis_item_width, -percent * view_rect.size.y)
		).abs()
		draw_rect(r, color)


func get_y_axis_rect() -> Rect2:
	_cache()
	return Rect2(
		Vector2.ZERO,
		Vector2(y_axis_font.get_string_size(
			str(max_value), HORIZONTAL_ALIGNMENT_CENTER, -1, y_axis_font_size).x,
			size.y - _biggset_title_vector.y)
		)


func get_x_axis_rect() -> Rect2:
	var y_axis := get_y_axis_rect()
	return Rect2(
		Vector2(y_axis.end.x, size.y - _biggset_title_vector.y),
		Vector2(size.x - y_axis.end.x, _biggset_title_vector.y)
	)


## Gets the steps for the x axis, this should only return floats of the "x" component.
func get_x_axis_steps() -> PackedFloat32Array:
	_cache()
	var view_rect := get_view_rect()
	var y_axis := get_y_axis_rect()
	var steps: PackedFloat32Array = []
	var total_items_width := _items.size() * x_axis_item_width
	var spacing = (view_rect.size.x - total_items_width) / (_items.size() + 1)

	for i in _items.size():
		var x: float = spacing + i * (x_axis_item_width + spacing)
		var center :=  (x + x_axis_item_width / 2) + y_axis.end.x
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
	if item < 0 or item > _items.size():
		return
	_items[item].title = title
	dirty = true
	queue_redraw()


func set_item_value(item: int, value: float) -> float:
	if item < 0 or item > _items.size():
		return value
	_items[item].value = clampf(snappedf(value, step), min_value, max_value)
	if rounded:
		_items[item].value = roundf(_items[item].value)
	queue_redraw()
	return _items[item].value


func set_item_bar_color(item: int, color: Color) -> void:
	if item < 0 or item > _items.size():
		printerr("Out of bounds, cannot set color for item: ", item)
		return
	_items[item]["color"] = color
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
	if item < 0 or item > _items.size() or not property in _items[item]:
		return null

	return _items[item].get(property, null)


func item_set(item: int, property: String, value: Variant) -> bool:
	if item < 0 or item > _items.size() or not property in _items[item]:
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
	if item < 0 or item > _items.size() or not property in _items[item]:
		return false

	var current := get("items/%d/%s" % [ item, property ])
	match property:
		"title": return current != ""
		"value": return is_equal_approx(current, min_value)
		"color": return current != Color.BLACK

	return false


func item_property_get_revert(item: int, property: String) -> Variant:
	if item < 0 or item > _items.size() or not property in _items[item]:
		return null

	match property:
		"title": return ""
		"value": return min_value
		"color": return Color.BLACK

	return null


func _cache() -> void:
	if not dirty:
		return

	# Calculate the rects of each titles
	for i in _items:
		var title: String = i.title
		var title_size := x_axis_font.get_multiline_string_size(title,
			HORIZONTAL_ALIGNMENT_CENTER, x_axis_item_width, x_axis_font_size)
		var data := {
			'title_size': title_size
		}
		_biggset_title_vector = _biggset_title_vector.max(title_size)

	update_minimum_size()

	dirty = false


func _get_minimum_size() -> Vector2:
	_cache()
	# NOTE: This causes seperation to applied on both sides of the bar
	var minimum_width := (_items.size() * (x_axis_item_width + x_axis_seperation)) +\
		get_y_axis_rect().size.x
	return Vector2(minimum_width, _biggset_title_vector.y)
