@tool
extends Control

# TODO: Also adjust offset based on the other titles just in case

## The radius of the graph.
@export var radius := 60.0:
	set(value):
		radius = value
		queue_redraw()

var key_count := 10

@export var seperation := 8:
	set(value):
		seperation = value
		queue_redraw()
var antialiased: bool


#region Puplic
func get_item_title(index: int) -> String:
	return "line1\nline2\nline3"


func index_to_vector2(index: int, center := Vector2(radius, radius)) -> Vector2:
	# Offset the roation so the graph can start at the topmost point
	var angle := (PI * 2 * index / key_count) - PI * 0.5
	return center + Vector2(cos(angle), sin(angle)) * radius


func get_title_rect_at(at_position: Vector2) -> int:
	for index in _cached_title_rects.size():
		if _cached_title_rects[index].rect.has_point(at_position):
			return index
	return -1

#endregion


#region Private
# The vector 2 passed should be unprocessed and realitive to
# Vector2(radius, radius)
func _vector2_to_location(point: Vector2) -> TitleRectCache.Location:
	var center := Vector2(radius, radius)
	if point.x < center.x and point.y < center.y:
		return TitleRectCache.Location.TOP_LEFT
	elif point.x == center.x and point.y < center.y:
		return TitleRectCache.Location.TOP_CENTER
	elif point.x > center.x and point.y < center.y:
		return TitleRectCache.Location.TOP_RIGHT
	elif point.x < center.x and point.y == center.y:
		return TitleRectCache.Location.CENTER_LEFT
	elif point.x > center.x and point.y == center.y:
		return TitleRectCache.Location.CENTER_RIGHT
	elif point.x < center.x and point.y > center.y:
		return TitleRectCache.Location.BOTTOM_LEFT
	elif point.x == center.x and point.y > center.y:
		return TitleRectCache.Location.BOTTOM_CENTER
	elif point.x > center.x and point.y > center.y:
		return TitleRectCache.Location.BOTTOM_RIGHT
	return TitleRectCache.Location.UNKNOWN


func _get_tooltip(at_position: Vector2) -> String:
	var index := get_title_rect_at(at_position)
	if index > -1:
		return get_item_title(index)
	return ""


func _get_minimum_size() -> Vector2:
	return _computed_rect.size



#endregion


#region Compute

class TitleRectCache:
	enum Location { TOP_RIGHT, TOP_CENTER, TOP_LEFT, CENTER_LEFT, CENTER_RIGHT, BOTTOM_LEFT,
					BOTTOM_CENTER, BOTTOM_RIGHT, UNKNOWN }
	var location: Location
	var rect: Rect2
	var position: Vector2


var computed_center: Vector2
var _computed_rect: Rect2
var _cached_title_rects: Array[TitleRectCache] = []
# Needs to be called before queue_redraw
# Calculates values such as size, title rects, the center
func _precompute() -> void:
	_compute_title_rects()
	update_minimum_size()

	# Do this so that the size is always sticky to the minimum size
	size = get_combined_minimum_size()


func _compute_title_rects() -> void:
	_cached_title_rects.clear()
	_computed_rect = Rect2()

	# TODO Implement font export var
	var font: Font = null
	if not is_instance_valid(font):
		font = ThemeDB.get_fallback_font()
	var font_size := 16

	for index in range(key_count):
		var title := get_item_title(index)
		var title_size := font.get_multiline_string_size(
			title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
			)
		var title_first_line_size := font.get_string_size(
			title.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_LEFT, title_size.x,
			font_size
			)
		var one_line: bool = title.get_slice_count("\n") == 1

		# For this we can use a fake center (Vector2(radius, radius)
		var center := Vector2(radius, radius)
		var index_pos := index_to_vector2(index)
		var direction := center.direction_to(index_pos)

		var font_pos := index_pos + seperation * direction
		var font_offset := Vector2.ZERO

		var location := _vector2_to_location(index_pos)
		match location:
			TitleRectCache.Location.TOP_LEFT:
				if one_line:
					font_offset = Vector2(-title_size.x, 0)
				else:
					font_offset = Vector2(-title_size.x, -title_size.y + title_first_line_size.y)
			TitleRectCache.Location.TOP_CENTER:
				if one_line:
					font_offset = Vector2(-title_size.x / 2, 0)
				else:
					font_offset = Vector2(-title_size.x / 2, -title_size.y + title_first_line_size.y)
			TitleRectCache.Location.TOP_RIGHT:
				if not one_line:
					font_offset = Vector2(0, -title_size.y + title_first_line_size.y)
			TitleRectCache.Location.CENTER_LEFT:
				font_offset = Vector2(-title_size.x, (-title_size.y * 0.5) + title_first_line_size.y)
			TitleRectCache.Location.CENTER_RIGHT:
				font_offset = Vector2(0, (-title_size.y * 0.5) + title_first_line_size.y)
			TitleRectCache.Location.BOTTOM_LEFT:
				font_offset = Vector2(-title_size.x, title_first_line_size.y)
			TitleRectCache.Location.BOTTOM_CENTER:
				font_offset = Vector2(-title_size.x / 2, title_first_line_size.y)
			TitleRectCache.Location.BOTTOM_RIGHT:
				font_offset = Vector2(0, title_first_line_size.y)



		# Build the title rect cache
		var rect_cache := TitleRectCache.new()
		rect_cache.position = font_pos
		rect_cache.rect = Rect2(font_pos + font_offset - Vector2(0, title_first_line_size.y),
			title_size
			)

		_cached_title_rects.append(rect_cache)

		_computed_rect = _computed_rect.merge(rect_cache.rect)

	# Finally offset all the title rects
	# The encompassing rect will most likely have is position < -Vector2.ZERO
	# So we need to get the opposite of that
	# The sum of all the cache positions
	var cache_position_sum := Vector2.ZERO
	for c in _cached_title_rects:
		c.position += -_computed_rect.position
		c.rect.position += -_computed_rect.position

		cache_position_sum += c.position

	computed_center = cache_position_sum / key_count
	_computed_rect.position = Vector2.ZERO

#endregion


func _draw() -> void:
	_precompute()
	var font := ThemeDB.get_fallback_font()
	for index in _cached_title_rects.size():
		var c: TitleRectCache = _cached_title_rects[index]
		draw_circle(c.position, 4, Color.RED, true, -1, antialiased)
		draw_rect(c.rect, Color.PALE_VIOLET_RED, false, 2)
		#draw_multiline_string(font, c.rect.position, get_item_title(index),
		#HORIZONTAL_ALIGNMENT_CENTER, c.rect.size.x, 16
		#)
	draw_rect(_computed_rect, Color.PALE_VIOLET_RED, false, 2)

	draw_circle(computed_center, 4, Color.LIGHT_CYAN)
