@tool
extends "../bases/two_axis_graph.gd"

const RGUtil := preload("../scripts/rgutil.gd")

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
## Minimum spacing around the item
@export var x_axis_seperation: float = 2.0:
	set(v):
		x_axis_seperation = v
		dirty = true
		queue_redraw()

var _item_metadata: Array[Dictionary] = []
var _biggset_title_vector := Vector2.ZERO
var _title_size_cache: PackedVector2Array = []


func get_default_draw_order() -> PackedStringArray:
	return ["x_axis", "x_axis_text", "y_axis", "y_axis_text", "view_rect", "grid", "points"]


func get_item_properties() -> Array[Dictionary]:
	return [{
		"name": "title",
		"type": TYPE_STRING,
	},
	{
		"name": "value",
		"type": TYPE_FLOAT,
	}]


func item_get(item: int, property: String) -> Variant:
	return _items[item].get(property, null)


func item_set(item: int, property: String, value: Variant) -> bool:
	_items[item][property] = value
	dirty = true
	queue_redraw()
	return true


func item_property_can_revert(item: int, property: String) -> bool:
	return false


func item_property_get_revert(item: int, property: String) -> Variant:
	return null


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
	var total_items_width := _items.size() * _biggset_title_vector.x
	var spacing = (view_rect.size.x - total_items_width) / (_items.size() + 1)

	for i in _items.size():
		var x: float = spacing + i * (_biggset_title_vector.x + spacing)
		var center :=  (x + _biggset_title_vector.x / 2) + y_axis.end.x
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


func _cache() -> void:
	if not dirty:
		return

	_title_size_cache.clear()

	# Calculate the rects of each titles
	for i in _items:
		var title: String = i.title
		var title_size := x_axis_font.get_multiline_string_size(title,
			HORIZONTAL_ALIGNMENT_CENTER, -1, x_axis_font_size)
		_biggset_title_vector = _biggset_title_vector.max(title_size)
		_title_size_cache.append(title_size)

	update_minimum_size()

	dirty = false


#region Drawing

func _rg_draw_y_axis_text() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()
	var v := max_value
	while v >= min_value:
		var val = (v / max_value) * view_rect.size.y + y_axis_font.get_descent(y_axis_font_size)
		var display_value := str(abs(max_value - v) + min_value)
		var string_size := y_axis_font.get_string_size(display_value,
			HORIZONTAL_ALIGNMENT_CENTER, y_axis.size.x, y_axis_font_size)
		y_axis_font.draw_string(canvas_item, Vector2(y_axis.position.x, val),
			display_value, HORIZONTAL_ALIGNMENT_CENTER, y_axis.size.x, y_axis_font_size)
		v -= cosmetic_step


func _rg_draw_x_axis_text() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	var total_items_width := _items.size() * _biggset_title_vector.x
	var spacing = (view_rect.size.x - total_items_width) / (_items.size() + 1)

	# Draw the titles along the x-axis
	for i in _items.size():
		var title: String = _items[i].title
		var title_size := _title_size_cache[i]
		var x: float = get_x_axis_steps()[i] - title_size.x / 2
		var y: float = view_rect.end.y + x_axis_font.get_ascent(x_axis_font_size)
		var pos := Vector2(x, y)
		draw_rect(Rect2(pos, title_size), Color.MAROON, false, 2)
		x_axis_font.draw_multiline_string(canvas_item, pos, title, HORIZONTAL_ALIGNMENT_CENTER,
			title_size.x, x_axis_font_size)


func _rg_draw_points() -> void:
	var view_rect := get_view_rect()
	var xaxis := get_x_axis_steps()

	for i in _items.size():
		var item := _items[i]
		var y := remap(
			item.value, min_value, max_value, view_rect.end.y, view_rect.position.y)
		draw_circle(Vector2(xaxis[i], y), 8, Color.PINK, true)

#endregion


#region Godot

func _get_minimum_size() -> Vector2:
	_cache()
	var x: float = Array(_title_size_cache).reduce(func(acc, vec): return acc + vec.x, 0)
	x += get_y_axis_rect().size.x + (x_axis_seperation * item_count / 2)
	return Vector2(x, 0)
#endregion
