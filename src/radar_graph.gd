@tool
extends Control
class_name RadarGraph

@export_group("Colors")
@export var background_color: Color
@export var outline_color: Color
@export var graph_color: Color
@export var guide_color: Color


@export_group("")
@export_range(0, 1, 1, "or_greater") var key_count := 0:
	set(new_key_count):
		key_count = new_key_count
		key_items.resize(key_count)
		notify_property_list_changed()
		queue_redraw()

var key_items: Array[Dictionary] = []:
	set(new_key_items):
		key_items = new_key_items

@export var min_value := 0.0
@export var max_value := 100.0
@export var show_guides := false:
	set(value):
		show_guides = value
		queue_redraw()
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

@export var radius: float = 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_draw_background()
		_draw_graph()
		_draw_guides()


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
	return


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		match property.get_slice("/", 2):
			"value":
				key_items[index]["value"] = clampf(value, min_value, max_value)
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
	return false


func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		if property == &"items/key_%d/value" % index and get(property) != 0:
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

func _draw_background() -> void:
	var center := size / 2
	var points := PackedVector2Array()
	for i in range(key_count):
		var angle := (PI * 2 * i / key_count) - PI * 0.5
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)

	draw_polygon(points, [background_color])


func _draw_graph() -> void:
	var center := size / 2
	var points := PackedVector2Array()

	for index in key_items.size():
		var value: float = get(&"items/key_%d/value" % index)
		var target_angle := (PI * 2 * index / key_count) - PI * 0.5
		var target: Vector2 = center + Vector2(cos(target_angle), sin(target_angle)) * radius

		points.append(center.lerp(target, value / max_value))

	draw_polygon(points, _get_custom_colors())


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
