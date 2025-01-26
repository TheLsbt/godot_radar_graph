@tool
@icon("res://src/icon.svg")
extends Control
class_name RadarGraph

## A simple radar graph plugin that is animateable. Note, that using [Theme]'s is not possible due
## to a Godot Limitation.

# TODO: Godot Docs

# TODO: Github Guide

enum TitleLocation { TOP_LEFT, TOP_CENTER, TOP_RIGHT, CENTER_LEFT, CENTER_RIGHT,
	BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT, UNKNOWN }

const CleanDrawOrder: PackedStringArray = [
	"background", "background_outline", "graph", "graph_outline", "guides", "titles"
]

## Emitted when a title is clicked.
signal title_clicked(button: MouseButton, index: int)

## The abount of keys that will be displayed, also determines ammount of sides the graph will have.
## [br]A graph can not have less than 3 keys.
@export_range(3, 100, 1, "or_greater") var key_count := 3:
	set(value):
		key_count = value
		key_items.resize(key_count)
		notify_property_list_changed()
		_cache()
		queue_redraw()
## The radius of the graph
@export var radius := 0.0:
	set(value):
		radius = value
		_cache()
		queue_redraw()
## All information for the key items are stored here, use the [param set_item_] functions.
@export_storage var key_items: Array[Dictionary] = []:
	set(new_key_items):
		key_items = new_key_items

@export_group("Range")
# TODO: When min value or max value is changed also update item values (after a bit to stop editor lag)
## Minimum value. Range is clamped if an items value is less than [member min_value].
@export var min_value := 0.0:
	set(value):
		min_value = value
		if min_value > max_value:
			max_value = min_value
		_try_mass_value_update()
		queue_redraw()
## Maximum value. Range is clamped if an items value is greater than [member max_value].
@export var max_value := 100.0:
	set(value):
		max_value = value
		if max_value < min_value:
			min_value = max_value
		_try_mass_value_update()
		queue_redraw()
# TODO: When step is changed update all the item values  (after a bit to stop editor lag)
## If greater than 0, item_value will always be rounded to a multiple of this property's value.
## If [member rounded] is also [code]true[/code], value will first be rounded to a multiple of
## this property's value, then rounded to the nearest integer.
@export var step: float = 0.0:
	set(value):
		step = snappedf(value, 0.02)
		_try_mass_value_update()
		queue_redraw()
# TODO: When rounded is changed update all the item values  (after a bit to stop editor lag)
## If [code]true[/code], value will always be rounded to the nearest integer.
@export var rounded: bool = false:
	set(value):
		rounded = value
		_try_mass_value_update()
		queue_redraw()

@export_group("Display")
@export_subgroup("Font")
## The font that is displayed for each title.
@export var font: Font:
	set(value):
		font = value
		_cache()
		queue_redraw()
## The font size of each title.
@export var font_size: int = 16:
	set(value):
		font_size = value
		_cache()
		queue_redraw()
@export var font_color := Color.WHITE:
	set(value):
		font_color = value
		queue_redraw()
@export var font_outline_color := Color.BLACK:
	set(value):
		font_outline_color = value
		queue_redraw()
@export var font_outline_size := 0:
	set(value):
		font_outline_size = value
		queue_redraw()
## Scales the distance from the center of the graph, can be negative to decrese the distance.
@export var title_seperation: float = 8:
	set(value):
		title_seperation = value
		_cache()
		queue_redraw()

@export_subgroup("Graph")
## The color of the background (the full polygon).
@export var background_color: Color:
	set(value):
		background_color = value
		queue_redraw()
## The color of the outline that surrounds the background. See [member background_color] for more.
@export var background_outline_color: Color:
	set(value):
		background_outline_color = value
		queue_redraw()
## The width of the outline that surrounds the background. See [member background_outline_color]
## for more.
@export var background_outline_width := 0.0:
	set(value):
		background_outline_width = value
		queue_redraw()
## The color of the graph (the polygon that indicates the value of each item).
@export var graph_color: Color:
	set(value):
		graph_color = value
		queue_redraw()
## The color of the outline that surrounds the graph. See [member graph_color] for more.
@export var graph_outline_color: Color:
	set(value):
		graph_outline_color = value
		queue_redraw()
## The width of the outline that surrounds the graph. See [member graph_outline_color] for more.
@export var graph_outline_width := 0.0:
	set(value):
		graph_outline_width = value
		queue_redraw()

@export_subgroup("Guide")
## Determines the visibility of the guides. See [member guide_step] for more.
@export var show_guides := false:
	set(value):
		show_guides = value
		queue_redraw()
## The color of the guides.
@export var guide_color: Color:
	set(value):
		guide_color = value
		queue_redraw()
## The width of the guides.
@export var guide_width := 1.0:
	set(value):
		guide_width = value
		queue_redraw()
## If [member show_guides] is true and [member guide_step] if [code]greater[/code] than 0,
## shows the guide step every [member guide_step] units. Use [member guide_color] to
## customize the guide.
@export_range(0, 100, 1, "or_greater") var guide_step := 0.0:
	set(value):
		guide_step = value
		queue_redraw()

@export_group("Display")
## The draw order of the graph.
@export var draw_order: PackedStringArray = CleanDrawOrder:
	set(value):
		draw_order = value
		queue_redraw()

var _encompassing_rect: Rect2
var _title_rect_cache: Array[Rect2] = []
var _encompassing_offset := Vector2()
var radius_v2: Vector2:
	get:
		return Vector2(radius, radius)
@export_group("")


#region User
func get_item(index: int) -> Dictionary:
	if _out_of_boundsi_err(index, 0, key_items.size() - 1, "index: get_item"):
		return {}
	return key_items[index]


func set_item_value(index: int, value: float) -> void:
	if _out_of_boundsi_err(index, 0, key_items.size() - 1, "index: set_item_value"):
		return
	if rounded:
		key_items[index]["value"] = clampf(roundf(snappedf(value, step)), min_value, max_value)
	else:
		key_items[index]["value"] = clampf(snappedf(value, step), min_value, max_value)
	_cache()
	queue_redraw()


func get_item_value(index: int) -> float:
	if _out_of_boundsi_err(index, 0, key_items.size() - 1, "index: get_item_value"):
		return clampf(0, min_value, max_value)
	return key_items[index].get_or_add("value", clampf(0, min_value, max_value))


func set_item_title(index: int, title: String) -> void:
	if _out_of_boundsi_err(index, 0, key_items.size() - 1, "index: set_item_title"):
		return
	key_items[index]["title"] = title
	_cache()
	queue_redraw()


func get_item_title(index: int) -> String:
	if _out_of_boundsi_err(index, 0, key_items.size() - 1, "index: get_item_title"):
		return ""
	return key_items[index].get_or_add("title", "")


func set_item_tooltip(index: int, item_tooltip: String) -> void:
	if _out_of_boundsi_err(index, 0, key_items.size() - 1, "index: set_item_tooltip"):
		return
	key_items[index]["tooltip"] = item_tooltip


func get_item_tooltip(index: int) -> String:
	if _out_of_boundsi_err(index, 0, key_items.size() - 1, "index: get_item_tooltip"):
		return ""
	return key_items[index].get_or_add("tooltip", "")


func get_title_index(at_position: Vector2) -> int:
	for index in range(key_count):
		var rect := _title_rect_cache[index]
		if rect.has_point(at_position - _encompassing_offset):
			return index
	return -1

#endregion


#region Engine Interaction

# Mass updating is updating the values of each item, some precautions need to be made.
# Because of how the items are displayed the property list needs to be updated each time so while
# in the editor we need to wait before actually updating the editor.
const UPDATE_WAIT_TIME := 0.4
var _mass_update_timer: Timer


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_mass_update_timer = Timer.new()
		_mass_update_timer.wait_time = UPDATE_WAIT_TIME
		_mass_update_timer.one_shot = true
		_mass_update_timer.timeout.connect(_mass_update_values)
		add_child(_mass_update_timer)


func _exit_tree() -> void:
	if is_instance_valid(_mass_update_timer):
		_mass_update_timer.queue_free()


func _init() -> void:
	key_items.resize(key_count)


func _ready() -> void:
	_cache()
	queue_redraw()


func _get_tooltip(at_position: Vector2) -> String:
	var index := get_title_index(at_position)
	if index > -1:
		return get_item_tooltip(index)
	return ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_draw_radar_graph()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			var index := get_title_index(event.position)
			if index > -1:
				title_clicked.emit(event.button_index, index)


#endregion


#region Cache And Size

func _cache() -> void:
	if not is_node_ready():
		return

	_update_title_rect_cache()

	# Get the encompassing rect
	_encompassing_rect = Rect2()
	for rect in _title_rect_cache:
		_encompassing_rect = _encompassing_rect.merge(rect)
	_encompassing_rect = _encompassing_rect.merge(Rect2(Vector2.ZERO, radius_v2 * 2))

	_update_size()
	_encompassing_offset = position - _encompassing_rect.position


func _update_size() -> void:
	update_minimum_size()

	if (size - get_combined_minimum_size()).length_squared() > 0:
		size = get_combined_minimum_size()


func _update_title_rect_cache() -> void:
	_title_rect_cache.clear()

	var title_font := font
	if not is_instance_valid(font):
		title_font = ThemeDB.get_fallback_font()

	for index in range(key_count):
		var title: String = get_item_title(index)
		var title_size := title_font.get_multiline_string_size(
			title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var first_line_size := title_font.get_string_size(
			title.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_CENTER, title_size.x, font_size)

		var point_pos := _get_polygon_point(index)
		var direction := radius_v2.direction_to(point_pos)

		var font_pos := point_pos + Vector2(title_seperation, title_seperation) * direction

		var font_offset := Vector2.ZERO

		var location := _get_point_as_location(point_pos)
		match location:
			TitleLocation.TOP_LEFT:
				font_offset = Vector2(-title_size.x, -first_line_size.y)
			TitleLocation.TOP_CENTER:
				font_offset = Vector2(-title_size.x / 2, -first_line_size.y)
			TitleLocation.TOP_RIGHT:
				font_offset = Vector2(0, -first_line_size.y)
			TitleLocation.CENTER_LEFT:
				font_offset = Vector2(-title_size.x, (-title_size.y * 0.5) + first_line_size.y)
			TitleLocation.CENTER_RIGHT:
				font_offset = Vector2(0, (-title_size.y * 0.5) + first_line_size.y)
			TitleLocation.BOTTOM_LEFT:
				font_offset = Vector2(-title_size.x, first_line_size.y)
			TitleLocation.BOTTOM_CENTER:
				font_offset = Vector2(-title_size.x / 2, first_line_size.y)
			TitleLocation.BOTTOM_RIGHT:
				font_offset = Vector2(0, first_line_size.y)

		_title_rect_cache.append(
			Rect2(font_pos + font_offset - Vector2(0, first_line_size.y), title_size))


func _get_minimum_size() -> Vector2:
	return _encompassing_rect.size

#endregion


#region Property List Management

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

	return properties


func _get(property: StringName) -> Variant:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		match property.get_slice("/", 2):
			"value":
				return get_item_value(index)
			"title":
				return get_item_title(index)
			"tooltip":
				return get_item_tooltip(index)
	return


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("items/key_"):
		var index := property.get_slice("_", 1).to_int()

		match property.get_slice("/", 2):
			"value":
				set_item_value(index, value)
				return true
			"title":
				set_item_title(index, value)
				return true
			"tooltip":
				set_item_tooltip(index, value)
				return true
	return false


func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("items/key_"):
		var key := property.get_slice("/", 2)
		if key == "value" and get(property) != 0:
			return true
		elif key == "title" and get(property).length() > 0:
			return true
		elif key == "tooltip" and get(property):
			return true
	return false


func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("items/key_"):

		var key := property.get_slice("/", 2)
		match key:
			"value":
				return 0
			"title":
				return ""
			"tooltip":
				return ""
	return false

#endregion


#region Helper Functions

func _try_mass_value_update() -> void:
	if not Engine.is_editor_hint():
		_mass_update_values()
	elif _mass_update_timer:
		_mass_update_timer.start(UPDATE_WAIT_TIME)


func _mass_update_values() -> void:
	for index in range(key_count):
		set_item_value(index, get_item_value(index))

	if Engine.is_editor_hint():
		notify_property_list_changed()
		print_rich("[code]Radar Graph mass-value update[/code]")


func _get_polygon_point(index: int) -> Vector2:
	var angle := (PI * 2 * index / key_count) - PI * 0.5
	return radius_v2 + Vector2(cos(angle), sin(angle)) * radius_v2


## Converts a point into a [enum TitleLocation].
func _get_point_as_location(point: Vector2) -> TitleLocation:
	var center := radius_v2
	if point.x < center.x and point.y < center.y:
		return TitleLocation.TOP_LEFT
	elif point.x == center.x and point.y < center.y:
		return TitleLocation.TOP_CENTER
	elif point.x > center.x and point.y < center.y:
		return TitleLocation.TOP_RIGHT
	elif point.x < center.x and point.y == center.y:
		return TitleLocation.CENTER_LEFT
	elif point.x > center.x and point.y == center.y:
		return TitleLocation.CENTER_RIGHT
	elif point.x < center.x and point.y > center.y:
		return TitleLocation.BOTTOM_LEFT
	elif point.x == center.x and point.y > center.y:
		return TitleLocation.BOTTOM_CENTER
	elif point.x > center.x and point.y > center.y:
		return TitleLocation.BOTTOM_RIGHT
	return TitleLocation.UNKNOWN

#endregion


#region Draw Functions

func _draw_radar_graph() -> void:
	draw_set_transform(_encompassing_offset)
	for i in draw_order:
		var method := &"_draw_%s" % i
		if not has_method(method):
			printerr("No draw method found for ", i)
			continue
		call(method)
	draw_set_transform(Vector2.ZERO)


func _draw_background() -> void:
	var points := PackedVector2Array()
	for i in range(key_count):
		points.append(_get_polygon_point(i))

	draw_polygon(points, [background_color])


func _draw_background_outline() -> void:
	if background_outline_width == 0 or background_outline_color.a == 0:
		return

	var points := PackedVector2Array()

	for index in range(key_count):
		points.append(_get_polygon_point(index))

	points.append(points[0])

	draw_polyline(points, background_outline_color, background_outline_width)


func _draw_graph() -> void:
	var points := PackedVector2Array()

	for index in range(key_count):
		var value: float = get_item_value(index)
		var target := _get_polygon_point(index)
		points.append(radius_v2.lerp(target, value / max_value))

	draw_polygon(points, [graph_color])


func _draw_graph_outline() -> void:
	if graph_outline_width == 0 or graph_outline_color.a == 0:
		return

	var points := PackedVector2Array()

	for index in range(key_count):
		var value: float = get_item_value(index)
		var target := _get_polygon_point(index)
		points.append(radius_v2.lerp(target, value / max_value))

	points.append(points[0])

	draw_polyline(points, graph_outline_color, graph_outline_width)


func _draw_guides() -> void:
	if not show_guides or guide_step == 0:
		return
	var distance_covered := 0.0

	while distance_covered <= max_value:
		var p := distance_covered / max_value * radius
		var points := PackedVector2Array()
		for index in range(key_count):
			var target_angle := (PI * 2 * index / key_count) - PI * 0.5
			var target: Vector2 = radius_v2 + Vector2(cos(target_angle), sin(target_angle)) * p
			points.append(target)

		points.append(points[0])

		# TODO: Make guide antiailiased an option
		draw_polyline(points, guide_color, guide_width, false)

		distance_covered += guide_step


func _draw_titles() -> void:
	var title_font := font
	if not is_instance_valid(font):
		title_font = ThemeDB.get_fallback_font()

	for index in range(key_count):
		var title := get_item_title(index)
		var rect := _title_rect_cache[index]
		var first_line_size := title_font.get_string_size(
			title.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size)
		var font_position := rect.position + Vector2(0, first_line_size.y)
		if font_outline_size > 0 and font_outline_color.a > 0:
			draw_multiline_string_outline(
				title_font, font_position, title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x,
				font_size, -1, font_outline_size, font_outline_color
			)
		draw_multiline_string(
			title_font, font_position, title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size,
			-1, font_color)


#endregion


#region Error Handling

## Determines whether a int is out of a range of [member low] and [member high].
## A optional [member identifier] can be passed to better describe the error.
func _out_of_boundsi_err(value: int, low: int, high: int, identifier := "") -> bool:
	identifier = identifier if identifier.length() > 0 else "Value"
	if value < low or value > high:
		return true
	return false
#endregion
