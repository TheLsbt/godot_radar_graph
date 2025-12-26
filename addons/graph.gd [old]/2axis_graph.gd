@tool
extends Control


## This script is a intermediate, it handles the x and y scales as well as the view_rect used for
## most 2 axis graphs.

@export var index_count: int = 2

@export_group("Range")
@export var min_value: float = 0
@export var max_value: float = 100
@export var step: float = 10.0
@export var allow_dynamic_range := true
@export var dynamic_range_steps := 0.0

@export_group("Scales")
@export_subgroup("X Scale", "x_scale")
@export var x_scale_titles: PackedStringArray = []
@export var x_scale_font: Font
@export var x_scale_font_size: int = 16
@export var x_scale_tick_length := 8.0
@export var x_scale_tick_width := 2.0
@export var x_scale_tick_color := Color.WHITE
@export_subgroup("Y Scale", "y_scale")
@export var y_scale_font: Font
@export var y_scale_font_size: int = 16
@export var y_scale_tick_length := 8.0
@export var y_scale_tick_width := 2.0
@export var y_scale_tick_color := Color.WHITE
@export var y_scale_value_title_snap := 0.0

@export_group("Graph")
@export var graph_boarder := Color.WHITE
@export var graph_boarder_width := 2.0


var cache_dirty := false
var cache: Dictionary = {}

var default_font: Font = ThemeDB.fallback_font
var default_font_size: int = ThemeDB.fallback_font_size


## A dynamic min value sets how the graph is rendered, this method is called at the begining of a
## cache and thus needs to be deterministic and ready by cache time.
func get_dynamic_min_max_value() -> PackedFloat32Array:
	return [min_value, max_value]


## The order each layer is drawn. To override a specific layer create a function following [code]<layer_name>_drawer[/code]
func get_layers() -> PackedStringArray:
	return ["grid", "graph_boarder", "scales"]


## Returns the xscale ticks in view_rect space. Requires cache to be built.
func get_xscale_ticks() -> PackedFloat32Array:
	_check_cache()

	var ticks: PackedFloat32Array = []

	var view_rect: Rect2 = cache.get("view_rect", Rect2())
	var segment := view_rect.size.x / index_count

	for index in index_count + 1:
		ticks.append(segment * index)

	return ticks


## Returns the steps in value space.
func get_yscale_ticks() -> PackedFloat32Array:
	var ticks: PackedFloat32Array = []

	var dynamic_min_max := get_dynamic_min_max_value()
	var dynamic_min_value := dynamic_min_max[0]
	var dynamic_max_value := dynamic_min_max[1]

	var s := dynamic_min_value
	while s <= dynamic_max_value:
		ticks.append(s)
		s += step

	return ticks


func yscale_tick_to_title(value: float) -> String:
	return str(snappedf(value, y_scale_value_title_snap))


## Allowed to override, remember to use super() if you want to use higher level cache's.
func create_cache() -> void:
	cache.clear()

	var dynamic_min_max := get_dynamic_min_max_value()
	var dynamic_min_value := dynamic_min_max[0]
	var dynamic_max_value := dynamic_min_max[1]

	var font: Font = get_or_default("y_scale_font", default_font)
	var font_size: int = get_or_default("y_scale_font_size", default_font)

	var yscale_accumulated_height := 0.0

	# Cache the y scale first, information we get out of this includes the minimum height for the
	# yscale as well as the minimum width.
	var yscale_minimum := -Vector2.INF
	var yscale_ticks := get_yscale_ticks()
	for i in yscale_ticks.size():
		var value := yscale_ticks[i] + dynamic_min_value
		var title := yscale_tick_to_title(value)
		var title_size := font.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		yscale_minimum = yscale_minimum.max(title_size)
		yscale_accumulated_height += title_size.y

	cache["yscale.minimum_width"] = yscale_minimum.x
	var ysm_title := yscale_tick_to_title(yscale_ticks[0] + dynamic_min_value)
	var ysm_title_size := font.get_string_size(
		ysm_title.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var yscale_safe_margin := ysm_title_size.y / 2

	if x_scale_titles.size() == 0:
		printerr("Cannot cache x scale, cache may be incomplete.")
		return

	# This determines the length of each column along xscale
	var xscale_width := size.x - yscale_minimum.x
	var xscale_column_segment := xscale_width / index_count

	var xscale_minimum := -Vector2.INF

	font = get_or_default("x_scale_font", default_font)
	font_size = get_or_default("x_scale_font_size", default_font)

	for index in index_count:
		var title: String = x_scale_titles[wrapi(index, 0, x_scale_titles.size())]
		var title_size := font.get_multiline_string_size(
			title, HORIZONTAL_ALIGNMENT_CENTER, xscale_column_segment, font_size)
		xscale_minimum = xscale_minimum.max(title_size)

	var xscale_rect := Rect2(
		Vector2(yscale_minimum.x, (size.y - xscale_minimum.y) + yscale_safe_margin),
		Vector2(xscale_width, xscale_minimum.y)
	)
	cache["xscale_rect"] = xscale_rect

	#draw_rect(xscale_rect, Color.PALE_VIOLET_RED)
	var yscale_rect := Rect2(
		Vector2(0, yscale_safe_margin),
		Vector2(yscale_minimum.x, size.y - xscale_minimum.y)
	)
	cache["yscale_rect"] = yscale_rect


	var view_rect := Rect2(
		Vector2(yscale_rect.size.x + y_scale_tick_length, yscale_safe_margin),
		Vector2(
			size.x - yscale_rect.size.x - y_scale_tick_length, size.y - \
			maxf(xscale_minimum.y, x_scale_tick_length) - yscale_safe_margin
		)
	)
	cache["view_rect"] = view_rect

	var yscale_ticks_pos_cache := []
	# This cannot be calculated at the same time as the yscale becuase it requires the view rect.
	for value in get_yscale_ticks():
		var percent := remap((value - dynamic_min_value) / (dynamic_max_value - dynamic_min_value), 0, 1, 1, 0)
		var pos := Vector2(view_rect.position.x, (view_rect.size.y * percent) + yscale_safe_margin)
		yscale_ticks_pos_cache.append(pos)

	cache["yscale_ticks_pos_cache"] = yscale_ticks_pos_cache

	cache["yscale_minimum"] = yscale_minimum
	cache["yscale_accumulated_height"] = yscale_accumulated_height
	cache["yscale_safe_margin"] = yscale_safe_margin
	cache["xscale_minimum"] = xscale_minimum


func get_or_default(property: StringName, default: Variant = null) -> Variant:
	var value := get(property)
	if value == null:
		return default
	return value


## Default drawer for the grid.
func grid_drawer() -> void:
	_check_cache()
	var view_rect: Rect2 = cache["view_rect"]
	var xscale_ticks := get_xscale_ticks()
	var xscale_grid: PackedVector2Array = []
	for i in xscale_ticks.size():
		var x := xscale_ticks[i]
		var pos := Vector2(x + view_rect.position.x, view_rect.end.y)

		xscale_grid.append(pos)
		xscale_grid.append(Vector2(pos.x, view_rect.position.y))

	var yscale_grid: PackedVector2Array = []
	var yscale_ticks_pos_cache: Array = cache["yscale_ticks_pos_cache"]
	var yscale_ticks := get_yscale_ticks()
	for i in yscale_ticks.size():
		var pos: Vector2 = yscale_ticks_pos_cache[i]
		yscale_grid.append(pos)
		yscale_grid.append(Vector2(view_rect.end.x, pos.y))

	draw_multiline(xscale_grid, x_scale_tick_color, x_scale_tick_width)
	draw_multiline(yscale_grid, y_scale_tick_color, y_scale_tick_width)


func graph_boarder_drawer() -> void:
	_check_cache()
	var view_rect: Rect2 = cache["view_rect"]
	draw_rect(view_rect, graph_boarder, false, graph_boarder_width)


## Default drawer for both scales.
func scales_drawer() -> void:
	_check_cache()

	var dynamic_min_max := get_dynamic_min_max_value()
	var dynamic_min_value := dynamic_min_max[0]
	var dynamic_max_value := dynamic_min_max[1]

	var view_rect: Rect2 = cache["view_rect"]
	var xscale_ticks := get_xscale_ticks()

	var segment := view_rect.size.x / index_count

	var font: Font = get_or_default("x_scale_font", default_font)
	var font_size: int = get_or_default("x_scale_font_size", default_font_size)

	for i in xscale_ticks.size():
		var x := xscale_ticks[i]
		var pos := Vector2(x + view_rect.position.x, view_rect.end.y)

		if i == xscale_ticks.size() - 1:
			break

		font.draw_multiline_string(
			get_canvas_item(),
			pos + Vector2(0, font.get_ascent(font_size)),
			x_scale_titles[wrapi(i, 0, x_scale_titles.size())],
			HORIZONTAL_ALIGNMENT_CENTER,
			segment
		)

		draw_line(pos, pos + Vector2(0, x_scale_tick_length),x_scale_tick_color, x_scale_tick_width)

	font = get_or_default("y_scale_font", default_font)
	font_size = get_or_default("y_scale_font_size", default_font_size)

	var yscale_minimum_width: float = cache.get("yscale.minimum_width", -1)
	var yscale_ticks_pos_cache: Array = cache["yscale_ticks_pos_cache"]
	var yscale_ticks := get_yscale_ticks()

	for i in yscale_ticks.size():
		var value := yscale_ticks[i]
		var percent := remap(
			(value - dynamic_min_value) / (dynamic_max_value - dynamic_min_value), 0, 1, 1, 0)
		var pos: Vector2 = yscale_ticks_pos_cache[i]

		font.draw_multiline_string(
			get_canvas_item(),
			Vector2(0, pos.y + font.get_descent(font_size)),
			yscale_tick_to_title(value),
			HORIZONTAL_ALIGNMENT_RIGHT,
			yscale_minimum_width,
			font_size
		)

		draw_line(pos, pos - Vector2(y_scale_tick_length, 0), y_scale_tick_color, y_scale_tick_width)


# --- Private functions ---
func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		cache_dirty = true

	elif what == NOTIFICATION_DRAW:
		if not is_node_ready():
			return

		for layer in get_layers():
			var method_name := layer + "_drawer"
			if has_method(method_name):
				call(method_name)

	elif what == NOTIFICATION_RESIZED:
		cache_dirty = true
		queue_redraw()


## Checks if the cache is dirty, creates a cache if it is. Before acessing cache, remmeber to call
## this method.
func _check_cache() -> void:
	if not cache_dirty:
		return

	create_cache()
