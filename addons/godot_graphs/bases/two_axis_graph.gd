@tool
extends "./base_graph.gd"


# TODO: When step and round is changed make all the values reflect that
# TODO: Add a way to pad the step (using a format) or round it
# TODO: Add a colorblind mode by implementing a tilling pattern across the bar
# TODO: Implement all the callbacks on each property

## This script is intented to be used as a base class for graphs with two primary axis.

@export_group("Range")
@export_range(0, 100, 1, 'or_less', 'or_greater') var min_value: float = 0.0
@export_range(0, 100, 1, 'or_less', 'or_greater') var max_value := 100.0
## Snapped according to the folowing code: [codeblock]clampf(snappedf(value, step), min_value, max_value)[/codeblock]
## See [member Range.step] for more.
@export var step := 10.0
@export var cosmetic_step := 5.0
@export var rounded := false

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
	set(val):
		y_axis_font_size = val
		dirty = true
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
@export var item_width: float = 5.0:
	set(v):
		item_width = v
		dirty = true
		queue_redraw()
		update_minimum_size()
## Minimum spacing around the item
@export var seperation: float = 2.0:
	set(v):
		seperation = v
		dirty = true
		queue_redraw()
		update_minimum_size()

@export_group('Grid')
@export var draw_grid := false
@export var grid_width := 1.0
@export var grid_color := Color.WHITE


func _on_axis_stylebox_changed() -> void:
	queue_redraw()


func _init() -> void:
	item_rect_changed.connect(func(): dirty = true; queue_redraw())


func get_default_draw_order() -> PackedStringArray:
	return ["x_axis", "y_axis", "view_rect", "grid"]


func _rg_draw_x_axis() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	if x_axis_style_box:
		x_axis_style_box.draw(canvas_item, x_axis)


func _rg_draw_y_axis() -> void:
	var canvas_item := get_canvas_item()
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	if y_axis_style_box:
		y_axis_style_box.draw(canvas_item, y_axis)


func _rg_draw_view_rect() -> void:
	if draw_grid:
		var view_rect := get_view_rect()
		draw_rect(view_rect, grid_color, false, grid_width)


func _rg_draw_grid() -> void:
	if not draw_grid:
		return

	var grid: PackedVector2Array = []
	var view_rect := get_view_rect()
	var x_axis := get_x_axis_rect()
	var y_axis := get_y_axis_rect()

	var x_steps := get_x_axis_steps()
	var y_steps := get_y_axis_steps()

	for i in y_steps:
		grid.append_array([Vector2(y_axis.end.x, i), Vector2(x_axis.end.x, i)])
	for i in x_steps:
		grid.append_array([Vector2(i, view_rect.position.y), Vector2(i, view_rect.end.y)])

	if grid.size() > 1:
		draw_multiline(grid, grid_color, grid_width)


var _item_metadata: Array[Dictionary] = []
var _biggset_title_vector := Vector2.ZERO

# Calculates all values needed. Call make_dirty() when changing properties.
func _cache() -> void:
	if not dirty:
		return

	# Calculate the rects of each titles
	for i in _items:
		var title: String = i.title
		var title_size := x_axis_font.get_multiline_string_size(title,
			HORIZONTAL_ALIGNMENT_CENTER, item_width, x_axis_font_size)
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
		Vector2(y_axis_font.get_string_size(
			str(max_value), HORIZONTAL_ALIGNMENT_CENTER, -1, y_axis_font_size).x,
			size.y - _biggset_title_vector.y)
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


## [b][color=LIGHT_GREEN](Should Override)[/color][/b]
## Gets the steps for the x axis, this should only return floats of the "x" component.
func get_x_axis_steps() -> PackedFloat32Array:
	return []


## [b][color=LIGHT_GREEN](Should Override)[/color][/b]
## Gets the steps for the y axis, this should only return floats of the "y" component.
func get_y_axis_steps() -> PackedFloat32Array:
	return []


func _get_minimum_size() -> Vector2:
	_cache()
	var minimum_width := (_items.size() * (item_width + seperation)) + get_y_axis_rect().size.x
	return Vector2(minimum_width, _biggset_title_vector.y)
