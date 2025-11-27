@tool
extends Control

# TODO: Add a way to pad the step (using a format) or round it
# TODO:

## This script is intented to be used as a base class for graphs with two primary axis.

@export_group('Style')
@export_subgroup("Y Axis")
## Draws the stylebox onto the axis.[br][br]
## At the momment the stylebox uses for the axis bars are for decrotive purposes and does not[br]
## affect the position and size of the axis.
@export var y_axis_style_box: StyleBox:
	set(val):
		if y_axis_style_box and y_axis_style_box.changed.is_connected(_on_axis_stylebox_changed):
			y_axis_style_box.changed.disconnect(_on_axis_stylebox_changed)
		y_axis_style_box = val
		if val:
			y_axis_style_box.changed.connect(_on_axis_stylebox_changed)
		queue_redraw()
@export_subgroup('X Axis')
## See [member y_axis_style_box].
@export var x_axis_style_box: StyleBox:
	set(val):
		if x_axis_style_box and x_axis_style_box.changed.is_connected(_on_axis_stylebox_changed):
			x_axis_style_box.changed.disconnect(_on_axis_stylebox_changed)
		x_axis_style_box = val
		if val:
			x_axis_style_box.changed.connect(_on_axis_stylebox_changed)
		queue_redraw()
@export_group('Grid')
@export var draw_grid := false
@export var grid_width := 1.0
@export var grid_color := Color.WHITE

var font := get_theme_font("font")

@export_group("Y Axis", "y_axis")
@export var y_axis_max_value: float:
	set(val):
		y_axis_max_value = val
		dirty = true
		queue_redraw()

@export_group('Items')
@export var item_width: float = 5.0
## Minimum spacing around the item
@export var seperation: float = 2.0
@export_group('')
@export var draw_order := PackedStringArray()
@export var step := 2.0

var dirty := true


func _on_axis_stylebox_changed() -> void:
	queue_redraw()


var items := [
		{
			"title": "My awesome\nitem 1",
			"value": 2,
			"color": Color.PINK,
		},
		{
			"title": "My awesome\nitem 2",
			"value": 5,
			"color": Color.PINK,
		},
		{
			"title": "My awesome\nitem 3",
			"value": 8,
			"color": Color.PINK,
		},
		{
			"title": "More...",
			"value": 1,
			"color": Color.PINK,
		}
	]


func _init() -> void:
	item_rect_changed.connect(func(): dirty = true; queue_redraw())


func _property_can_revert(property: StringName) -> bool:
	if property == &'draw_order':
		return draw_order != get_clean_draw_order()
	return false


func _property_get_revert(property: StringName) -> Variant:
	if property == &'draw_order':
		return get_clean_draw_order()
	return null


func get_clean_draw_order() -> PackedStringArray:
	return ['x_axis', 'x_axis_text', 'y_axis', 'y_axis_text', 'grid', 'view_rect', 'bars']


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		for i in draw_order:
			var method := &"_rg_draw_%s" % i
			if has_method(method):
				call(method)


func _rg_draw_view_rect() -> void:
	if draw_grid:
		var view_rect := get_view_rect()
		draw_rect(view_rect, grid_color, false, grid_width)


func _rg_draw_x_axis() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	if x_axis_style_box:
		x_axis_style_box.draw(canvas_item, x_axis)


func _rg_draw_x_axis_text() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	var total_items_width := items.size() * item_width
	var spacing = (view_rect.size.x - total_items_width) / (items.size() + 1)

	# Draw the titles along the x-axis
	for i in items.size():
		var title: String = items[i].title
		var x: float = spacing + i * (item_width + spacing)
		var pos = Vector2(x + y_axis.end.x, x_axis.position.y + font.get_ascent())
		font.draw_multiline_string(canvas_item, pos, title, HORIZONTAL_ALIGNMENT_CENTER, item_width)


func _rg_draw_y_axis() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	if y_axis_style_box:
		y_axis_style_box.draw(canvas_item, y_axis)


func _rg_draw_y_axis_text() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()
	for v in range(y_axis_max_value, -1, -step):
		var string_size := font.get_string_size(str(abs(y_axis_max_value - v)), HORIZONTAL_ALIGNMENT_CENTER)
		var val := (v / y_axis_max_value) * view_rect.size.y + font.get_descent()
		font.draw_string(canvas_item, Vector2(y_axis.position.x, val),
			str(abs(y_axis_max_value - v)), HORIZONTAL_ALIGNMENT_CENTER, y_axis.size.x)


func _rg_draw_bars() -> void:
	var view_rect := get_view_rect()

	var total_items_width := items.size() * item_width
	var spacing = (view_rect.size.x - total_items_width) / (items.size() + 1)

	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()
	var canvas_item := get_canvas_item()

	for i in items.size():
		var item: Dictionary = items[i]
		var title: String = item.title
		var value: float = item.value
		var color: Color = item.color

		var x: float = spacing + i * (item_width + spacing)
		var pos = Vector2(x + y_axis.end.x, x_axis.position.y + font.get_ascent())

		var percent := value / y_axis_max_value
		var rect := Rect2(Vector2(pos.x, 0), Vector2(item_width, size.y - _biggset_title_vector.y))
		rect.position.y = percent * view_rect.size.y

		# This is the actual bar
		var r := Rect2(
			Vector2(pos.x + item_width, get_view_rect().end.y),
			Vector2(-item_width, -percent * get_view_rect().size.y)
		).abs()
		draw_rect(r, color)


func _rg_draw_grid() -> void:
	var grid: PackedVector2Array = []
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	# Gather the horizontal grid lines
	for v in range(y_axis_max_value, -1, -step):
		var val := (v / y_axis_max_value) * view_rect.size.y
		grid.append_array([Vector2(y_axis.end.x, val), Vector2(x_axis.end.x, val)])

	# Gather the vertical grid lines
	var total_items_width := items.size() * item_width
	var spacing = (view_rect.size.x - total_items_width) / (items.size() + 1)

	for i in items.size():
		var x: float = spacing + i * (item_width + spacing)
		var center :=  (x + item_width / 2) + y_axis.end.x
		grid.append_array([Vector2(center, view_rect.position.y), Vector2(center, view_rect.end.y)])

	if draw_grid:
		draw_multiline(grid, grid_color, grid_width)


func get_line_size(text: String, line: int, width := -1) -> Vector2:
	var string := text.get_slice('\n', line)
	return font.get_string_size(string, 0, width)


var _item_metadata: Array[Dictionary] = []
var _biggset_title_vector := Vector2.ZERO

# Calculates all values needed. Call make_dirty() when changing properties.
func _cache() -> void:
	if not dirty:
		return

	# Calculate the rects of each titles
	for i in items:
		var title: String = i.title
		var title_size := font.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, item_width)
		var data := {
			'title_size': title_size
		}
		_biggset_title_vector = _biggset_title_vector.max(title_size)

	update_minimum_size()

	dirty = false


func get_y_axis_rect() -> Rect2:
	_cache()
	return Rect2(
		Vector2.ZERO,
		Vector2(font.get_string_size(str(y_axis_max_value)).x, size.y - _biggset_title_vector.y)
		)

func get_x_axis_rect() -> Rect2:
	_cache()
	var y_axis := get_y_axis_rect()
	return Rect2(
		Vector2(y_axis.end.x, size.y - _biggset_title_vector.y),
		Vector2(size.x - y_axis.end.x, _biggset_title_vector.y)
	)


func get_view_rect() -> Rect2:
	_cache()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()
	var rect := Rect2(
		Vector2(y_axis.end.x, 0), Vector2(size.x - y_axis.size.x, size.y - x_axis.size.y)
	)
	return rect


func _get_minimum_size() -> Vector2:
	_cache()
	var minimum_width := (items.size() * (item_width + seperation)) + get_y_axis_rect().size.x
	return Vector2(minimum_width, _biggset_title_vector.y)
