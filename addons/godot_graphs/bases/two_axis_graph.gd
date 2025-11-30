@tool
extends "./base_graph.gd"

# NOTE: This could be moved into base_graph.gd
const FIXME_TIME := 0.2

var _fixme_timer := Timer.new()

# TODO: Make a styling system similar to themes becuase the normal way is shite
# TODO: When step and round is changed make all the values reflect that
# TODO: Add a way to pad the step (using a format) or round it
# TODO: Add a colorblind mode by implementing a tilling pattern across the bar
# TODO: Implement all the callbacks on each property

## This script is intented to be used as a base class for graphs with two primary axis.

@export_group("Range")
@export_range(0, 100, 1, 'or_less', 'or_greater') var min_value: float = 0.0:
	set(v):
		min_value = minf(v, max_value)
		_try_fix_values()
		queue_redraw()
@export_range(0, 100, 1, 'or_less', 'or_greater') var max_value := 100.0:
	set(v):
		max_value = maxf(v, min_value)
		_try_fix_values()
		queue_redraw()
## Snapped according to the folowing code: [codeblock]clampf(snappedf(value, step), min_value, max_value)[/codeblock]
## See [member Range.step] for more.
@export var step := 10.0:
	set(v):
		step = v
		_try_fix_values()
		queue_redraw()
@export var cosmetic_step := 5.0:
	set(v):
		cosmetic_step = v
		_try_fix_values()
		queue_redraw()
@export var rounded := false:
	set(v):
		rounded = v
		_try_fix_values()
		queue_redraw()

@export_group('Style')
@export_subgroup("Y Axis", "y_axis")
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

@export_subgroup('X Axis', "x_axis")
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
@export var draw_grid := false:
	set(v):
		draw_grid = v
		queue_redraw()
@export var grid_width := 1.0:
	set(v):
		grid_width = v
		queue_redraw()
@export var grid_color := Color.WHITE:
	set(v):
		grid_color = v
		queue_redraw()


func _on_axis_stylebox_changed() -> void:
	queue_redraw()


func _ready() -> void:
	_fixme_timer.autostart = false
	_fixme_timer.one_shot = true
	_fixme_timer.wait_time = FIXME_TIME
	add_child(_fixme_timer, false, Node.INTERNAL_MODE_BACK)
	_fixme_timer.timeout.connect(try_fix_values)


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

## Implement
func get_y_axis_rect() -> Rect2:
	return Rect2()


func get_x_axis_rect() -> Rect2:
	return Rect2()


func get_view_rect() -> Rect2:
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



func _try_fix_values() -> void:
	if _fixme_timer.is_inside_tree():
		_fixme_timer.start()

## [b][color=LIGHT_GREEN](Should Override)[/color][/b]
## This is called when the script determines values should be fixed.
func try_fix_values() -> void:
	pass
