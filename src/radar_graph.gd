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

# TODO: Cache the rects of each title

# TODO: Tooltips for the titles

# TODO: Make the minimum rect also encompas the titles


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
		queue_redraw()
@export var font_size: int = 16:
	set(v):
		font_size = v
		queue_redraw()
@export var title_seperation: float = 8:
	set(v):
		title_seperation = v
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
		queue_redraw()
@export var radius: float = 0.0:
	set(new_radius):
		radius = new_radius
		update_minimum_size()
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_draw_background()
		_draw_graph()
		_draw_graph_outline()
		_draw_guides()
		_draw_titles()


func _get_minimum_size() -> Vector2:
	return Vector2(radius, radius) * 2


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
	return


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		match property.get_slice("/", 2):
			"value":
				set_item_value(index, value)
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
				queue_redraw()
				key_items[index]["title"] = value
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
	var center := size / 2
	var angle := (PI * 2 * index / key_count) - PI * 0.5
	return center + Vector2(cos(angle), sin(angle)) * radius


func _draw_background() -> void:
	var center := size / 2
	var points := PackedVector2Array()
	for i in range(key_count):
		points.append(_get_polygon_point(i))

	draw_polygon(points, [background_color])


func _draw_graph() -> void:
	var center := size / 2
	var points := PackedVector2Array()

	for index in key_items.size():
		var value: float = get(&"items/key_%d/value" % index)
		var target := _get_polygon_point(index)
		points.append(center.lerp(target, value / max_value))

	draw_polygon(points, _get_custom_colors())


func _draw_graph_outline() -> void:
	if graph_outline_width == 0 or graph_outline_color.a == 0:
		return

	var center := size / 2
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
	var center := size / 2

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


enum Location {
	UNKNOWN,
	TOP_LEFT, TOP_CENTER, TOP_RIGHT,
	CENTER_LEFT, CENTER_RIGHT,
	BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT
	}


func _get_point_as_location(point: Vector2) -> Location:
	var center := size / 2

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
	var center := size / 2
	for index in range(key_count):
		var pos := _get_polygon_point(index)

		var value := snappedf(get_item_value(index), step)
		var title := get_item_title(index).format({"value": value})
		var title_and_value := title

		var title_size := font.get_multiline_string_size(title_and_value, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

		var dir := center.direction_to(pos)
		# This position is a little bit outside of the background
		var font_pos := pos + Vector2(title_seperation, title_seperation) * dir
		var font_offset := Vector2.ZERO

		var title_rect := Rect2()
		var line_height = font.get_string_size(title_and_value.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_CENTER, title_size.x, font_size).y

		var location := _get_point_as_location(pos)
		match location:
			Location.TOP_LEFT:
				font_offset = Vector2(-title_size.x, -line_height)
			Location.TOP_CENTER:
				font_offset = Vector2(-title_size.x / 2, -line_height)
			Location.TOP_RIGHT:
				font_offset = Vector2(0, -line_height)
			Location.CENTER_LEFT:
				font_offset = Vector2(-title_size.x, (-title_size.y * 0.5) + line_height)
			Location.CENTER_RIGHT:
				font_offset = Vector2(0, (-title_size.y * 0.5) + line_height)
			Location.BOTTOM_LEFT:
				font_offset = Vector2(-title_size.x, line_height)
			Location.BOTTOM_CENTER:
				font_offset = Vector2(-title_size.x / 2, line_height)
			Location.BOTTOM_RIGHT:
				font_offset = Vector2(0, line_height)


		#draw_circle(font_pos, 4, Color.RED)
		#draw_rect(Rect2(font_pos + font_offset - Vector2(0, line_height), title_size), Color.WHITE, false, 2)

		draw_multiline_string(font, font_pos + font_offset, title_and_value, HORIZONTAL_ALIGNMENT_CENTER, title_size.x, font_size)
