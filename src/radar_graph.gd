@tool
extends Control
class_name RadarGraph

## A simple radar graph plugin that is animateable. Note, that using [Theme]'s is not possible due
## to a Godot Limitation.

# TODO: When min_value, max_value, rounded or step is changed it updates all the existing values to
# match them

# TODO: Draw the outline for the background

# TODO: Add a layer adjustment system, an array of String's that can be reorganised to adjust the
# way the graph is rendered

# TODO: Godot Docs

# TODO: Github Guide

enum Location {
	UNKNOWN,
	TOP_LEFT, TOP_CENTER, TOP_RIGHT,
	CENTER_LEFT, CENTER_RIGHT,
	BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT
	}

@export_group("Range")
@export var min_value := 0.0:
	set(new_min_value):
		min_value = new_min_value
		if min_value > max_value:
			max_value = min_value
@export var max_value := 100.0:
	set(new_max_value):
		max_value = new_max_value
		if min_value > max_value:
			min_value = max_value
@export var step: float = 0.0:
	set(new_step):
		step = snappedf(new_step, 0.02)
@export var rounded: bool = false:
	set(new_rounded):
		rounded = new_rounded
		queue_redraw()

@export_group("Styling")
@export_subgroup("Font")
@export var font: Font:
	set(v):
		font = v
		_cache()
		queue_redraw()
@export var font_size: int = 16:
	set(v):
		font_size = v
		_cache()
		queue_redraw()
@export var title_seperation: float = 8:
	set(v):
		title_seperation = v
		_cache()
		queue_redraw()

@export_subgroup("Graph")
@export var background_color: Color
@export var outline_color: Color
@export var graph_color: Color
@export var graph_outline_color: Color
@export var graph_outline_width := 0.0

@export_group("")
@export_range(0, 1, 1, "or_greater") var key_count := 0:
	set(new_key_count):
		key_count = new_key_count
		key_items.resize(key_count)
		notify_property_list_changed()
		_cache()
		queue_redraw()
@export var radius: float = 0.0:
	set(new_radius):
		radius = new_radius
		_cache()
		if (size - _get_minimum_size()).length_squared() > 0:
			size = get_combined_minimum_size()
		queue_redraw()

@export_storage var key_items: Array[Dictionary] = []:
	set(new_key_items):
		key_items = new_key_items

@export_group("Guide")
@export var show_guides := false:
	set(value):
		show_guides = value
		queue_redraw()
@export var guide_color: Color
## If [member show_guides] is true and [member guide_step] if greater than 0, shows the guide step
## every [member guide_step] units. Use [member guide_color] to customize the guide.
@export var guide_step := 0.0:
	set(value):
		guide_step = value
		queue_redraw()

@export var guide_width := 1.0:
	set(value):
		guide_width = value
		queue_redraw()
@export_group("")

var _encompassing_rect: Rect2
var _title_rect_cache: Array[Rect2] = []
var _render_shift := Vector2()


const Merror = preload("res://src/merror.gd")


# Functions for users

func get_item(index: int) -> Dictionary:
	if Merror.boundsi(index, 0, key_items.size() - 1, "index"):
		return {}
	return key_items[index]


func set_item_value(index: int, value: float) -> void:
	if Merror.boundsi(index, 0, key_items.size() - 1, "index"):
		return
	if rounded:
		key_items[index]["value"] = clampf(roundf(snappedf(value, step)), min_value, max_value)
	else:
		key_items[index]["value"] = clampf(snappedf(value, step), min_value, max_value)


func get_item_value(index: int) -> float:
	if Merror.boundsi(index, 0, key_items.size() - 1, "index"):
		return clampf(0, min_value, max_value)
	return key_items[index].get_or_add("value", clampf(0, min_value, max_value))


func set_item_title(index: int, title: String) -> void:
	if Merror.boundsi(index, 0, key_items.size() - 1, "index"):
		return
	key_items[index]["title"] = title


func get_item_title(index: int) -> String:
	if Merror.boundsi(index, 0, key_items.size() - 1, "index"):
		return ""
	return key_items[index].get_or_add("title", "")


func set_item_tooltip(index: int, item_tooltip: String) -> void:
	if Merror.boundsi(index, 0, key_items.size() - 1, "index"):
		return
	key_items[index]["tooltip"] = item_tooltip


func get_item_tooltip(index: int) -> String:
	if Merror.boundsi(index, 0, key_items.size() - 1, "index"):
		return ""
	return key_items[index].get_or_add("tooltip", "")




func _get_shifted_center() -> Vector2:
	return Vector2(radius, radius)


func _init() -> void:
	_cache()


func _get_tooltip(at_position: Vector2) -> String:
	for index in range(key_count):
		var rect := _title_rect_cache[index]
		if rect.has_point(at_position - _render_shift):
			return get_item_tooltip(index)
	return ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		draw_set_transform(_render_shift)
		_draw_background()
		_draw_graph()
		_draw_graph_outline()
		_draw_guides()
		_draw_titles()

		# NOTE: Debug to view the title rect cache
		for rect in _title_rect_cache:
			draw_rect(rect, Color.WHITE, false, 2)

		draw_rect(_encompassing_rect, Color.HOT_PINK, false, 2)

		draw_circle(_get_shifted_center(), 4, Color.HOT_PINK)


func _get_minimum_size() -> Vector2:
	return _encompassing_rect.size


func _cache() -> void:
	_update_title_rect_cache()

	# Get the encompassing rect
	_encompassing_rect = Rect2()
	for rect in _title_rect_cache:
		_encompassing_rect = _encompassing_rect.merge(rect)
	_render_shift = position - _encompassing_rect.position

	update_minimum_size()


func _update_title_rect_cache() -> void:
	_title_rect_cache.clear()
	var center := _get_shifted_center()

	for index in range(key_count):
		# Get the subsitute variables
		var subsitutes := {
			"value": get_item_value(index)
		}
		var title: String = get_item_title(index).format(subsitutes, "{_}")
		var title_size := font.get_multiline_string_size(title, 0, -1, font_size)
		var first_line_size := font.get_string_size(
			title.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_CENTER, title_size.x, font_size)

		var point_pos := _get_polygon_point(index)
		var direction := center.direction_to(point_pos)

		var font_pos := point_pos + Vector2(title_seperation, title_seperation) * direction

		var font_offset := Vector2.ZERO

		var location := _get_point_as_location(point_pos)
		match location:
			Location.TOP_LEFT:
				font_offset = Vector2(-title_size.x, -first_line_size.y)
			Location.TOP_CENTER:
				font_offset = Vector2(-title_size.x / 2, -first_line_size.y)
			Location.TOP_RIGHT:
				font_offset = Vector2(0, -first_line_size.y)
			Location.CENTER_LEFT:
				font_offset = Vector2(-title_size.x, (-title_size.y * 0.5) + first_line_size.y)
			Location.CENTER_RIGHT:
				font_offset = Vector2(0, (-title_size.y * 0.5) + first_line_size.y)
			Location.BOTTOM_LEFT:
				font_offset = Vector2(-title_size.x, first_line_size.y)
			Location.BOTTOM_CENTER:
				font_offset = Vector2(-title_size.x / 2, first_line_size.y)
			Location.BOTTOM_RIGHT:
				font_offset = Vector2(0, first_line_size.y)

		_title_rect_cache.append(
			Rect2(font_pos + font_offset - Vector2(0, first_line_size.y), title_size))




func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	for i in range(key_count):
		properties.append({
			"name": "items/key_%d/value" % i,
			"type": TYPE_FLOAT,
		})
		properties.append({
			"name": "items/key_%d/title" % i,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT,
		})
		properties.append({
			"name": "items/key_%d/tooltip" % i,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT,
		})
		properties.append({
			"name": "items/key_%d/use_custom_color" % i,
			"type": TYPE_BOOL,
		})
		if key_items[i].get("use_custom_color", false):
			properties.append({
				"name": "items/key_%d/custom_color" % i,
				"type": TYPE_COLOR,
			})

	return properties


func _get(property: StringName) -> Variant:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		match property.get_slice("/", 2):
			"value":
				return key_items[index].get_or_add("value", min_value)
			"use_custom_color":
				return key_items[index].get_or_add("use_custom_color", false)
			"custom_color":
				return key_items[index].get_or_add("custom_color", Color.BLACK)
			"title":
				return key_items[index].get_or_add("title", "")
			"tooltip":
				return key_items[index].get_or_add("tooltip", "")
	return


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		match property.get_slice("/", 2):
			"value":
				set_item_value(index, value)
				_cache()
				queue_redraw()
				return true
			"use_custom_color":
				key_items[index]["use_custom_color"] = value
				notify_property_list_changed()
				queue_redraw()
				return true
			"custom_color":
				key_items[index]["custom_color"] = value
				queue_redraw()
				return true
			"title":
				key_items[index]["title"] = value
				_cache()
				queue_redraw()
				return true
			"tooltip":
				key_items[index]["tooltip"] = value
				return true
	return false


func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		if property == &"items/key_%d/value" % index and get(property) != 0:
			return true
		elif property == &"items/key_%d/title" % index and get(property).length() > 0:
			return true
		elif property == &"items/key_%d/use_custom_color" % index and get(property):
			return true
		elif property == &"items/key_%d/custom_color" % index and get(property) != Color.BLACK:
			return true
		elif property == &"items/key_%d/tooltip" % index and get(property).length() > 0:
			return true
	return false


func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		if property == &"items/key_%d/value" % index:
			return 0
		elif property == &"items/key_%d/title" % index:
			return ""
		elif property == &"items/key_%d/use_custom_color" % index:
			return false
		elif property == &"items/key_%d/custom_color" % index:
			return Color.BLACK
		elif property == &"items/key_%d/tooltip" % index:
			return ""

	return false


func _get_custom_colors() -> PackedColorArray:
	var colors := PackedColorArray()
	for index in range(key_count):
		if get(&"items/key_%d/use_custom_color" % index):
			colors.append(get(&"items/key_%d/custom_color" % index))
		else:
			colors.append(graph_color)
	return colors


# Drawing


func _get_polygon_point(index: int) -> Vector2:
	var center := _get_shifted_center()
	var angle := (PI * 2 * index / key_count) - PI * 0.5
	return center + Vector2(cos(angle), sin(angle)) * radius


func _draw_background() -> void:
	var center := _get_shifted_center()
	var points := PackedVector2Array()
	for i in range(key_count):
		points.append(_get_polygon_point(i))

	draw_polygon(points, [background_color])


func _draw_graph() -> void:
	var center := _get_shifted_center()
	var points := PackedVector2Array()

	for index in key_items.size():
		var value: float = get(&"items/key_%d/value" % index)
		var target := _get_polygon_point(index)
		points.append(center.lerp(target, value / max_value))

	draw_polygon(points, _get_custom_colors())


func _draw_graph_outline() -> void:
	if graph_outline_width == 0 or graph_outline_color.a == 0:
		return

	var center := _get_shifted_center()
	var points := PackedVector2Array()

	for index in key_items.size():
		var value: float = get(&"items/key_%d/value" % index)
		var target := _get_polygon_point(index)
		points.append(center.lerp(target, value / max_value))

	points.append(points[0])

	draw_polyline(points, graph_outline_color)


func _draw_guides() -> void:
	if not show_guides or guide_step == 0:
		return
	var distance_covered := 0.0
	var center := _get_shifted_center()

	while distance_covered <= max_value:
		var percent := distance_covered / max_value * radius
		var points := PackedVector2Array()
		for index in range(key_count):
			var target_angle := (PI * 2 * index / key_count) - PI * 0.5
			var target: Vector2 = center + Vector2(cos(target_angle), sin(target_angle)) * percent
			points.append(target)

		points.append(points[0])

		# TODO: Make guide antiailiased an option
		draw_polyline(points, guide_color, guide_width, false)

		distance_covered += guide_step


func _get_point_as_location(point: Vector2) -> Location:
	var center := _get_shifted_center()
	if point.x < center.x and point.y < center.y:
		return Location.TOP_LEFT
	elif point.x == center.x and point.y < center.y:
		return Location.TOP_CENTER
	elif point.x > center.x and point.y < center.y:
		return Location.TOP_RIGHT
	elif point.x < center.x and point.y == center.y:
		return Location.CENTER_LEFT
	elif point.x > center.x and point.y == center.y:
		return Location.CENTER_RIGHT
	elif point.x < center.x and point.y > center.y:
		return Location.BOTTOM_LEFT
	elif point.x == center.x and point.y > center.y:
		return Location.BOTTOM_CENTER
	elif point.x > center.x and point.y > center.y:
		return Location.BOTTOM_RIGHT
	return Location.UNKNOWN


func _draw_titles() -> void:
	var center := _get_shifted_center()
	for index in range(key_count):
		var subsitutes := {
			"value": get_item_value(index)
		}
		var title := get_item_title(index).format(subsitutes)
		var rect := _title_rect_cache[index]
		var first_line_size := font.get_string_size(
			title.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size)
		var font_position := rect.position + Vector2(0, first_line_size.y)
		draw_multiline_string(
			font, font_position, title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size)
