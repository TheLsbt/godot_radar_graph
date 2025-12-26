@tool
extends "2axis_graph.gd"


@export_group("Point & Line")
@export var point_size := 8
@export var line_width := 2


var datasets: Array[Dictionary] = []

var _dynamic_min_value := 0.0
var _dynamic_max_value := 0.0


## Each dataset requires a "label", "values" (only [enum Variant.TypesTYPE_FLOAT]
## and [enum Variant.Types.TYPE_INT] are valid elements), "color".
## [codeblock]
## [{
## "label": "My awesome label",
## "values": [0, 5.0, 2.1],
## "color": Color.RED,
## }]
## [/codeblock]
func update_datasets_array(updated: Array[Dictionary]) -> void:
	for i in updated:
		if i.has("label") and not typeof(i["label"]) == TYPE_STRING:
			return
		# TODO: Maybe also check the element of each type?
		if i.has("values") and not typeof(i["values"]) == TYPE_ARRAY:
			return
		if i.has("color") and not typeof(i["color"]) == TYPE_COLOR:
			return

	datasets = updated
	cache_dirty = true
	queue_redraw()


func update_graph_dict(updated: Dictionary) -> void:
	pass


func get_layers() -> PackedStringArray:
	return super() + PackedStringArray(["line", "points"])


func create_cache() -> void:
	super()

	print(get_dynamic_min_max_value())

	var view_rect: Rect2 = cache["view_rect"]
	# [{"points": PackedVector2Array, "color": Color()}]
	var lines: Array[Dictionary] = []

	# Calculate the positions of the points
	var segment := view_rect.size.x / index_count

	for dataset in datasets:
		var color: Color = dataset["color"]
		var points: PackedVector2Array = []

		for index in index_count:
			var pos: float = ((segment * index) + (segment / 2)) + view_rect.position.x

			if index >= dataset["values"].size():
				continue

			var value: float = dataset["values"][index]

			var pxvalue := remap((value - _dynamic_min_value) / (_dynamic_max_value - _dynamic_min_value), 0, 1, 1, 0) * view_rect.size.y
			pxvalue += view_rect.position.y

			points.append(Vector2(pos, pxvalue))

		lines.append({"points": points, "color": color})

	cache["lines"] = lines



func line_drawer() -> void:
	_check_cache()
	var lines: Array[Dictionary] = cache["lines"]

	for line: Dictionary in lines:
		var points: PackedVector2Array = line.points
		var color: Color = line.color

		draw_polyline(points, color, line_width)


func points_drawer() -> void:
	_check_cache()
	var lines: Array[Dictionary] = cache["lines"]

	for line: Dictionary in lines:
		var points: PackedVector2Array = line.points
		var color: Color = line.color

		for p in points:
			draw_circle(p, point_size, color, true)


func get_dynamic_min_max_value() -> PackedFloat32Array:
	_dynamic_min_value = min_value
	_dynamic_max_value = max_value

	for dataset: Dictionary in datasets:
		for value in dataset["values"]:
			_dynamic_min_value = minf(_dynamic_min_value, value)
			_dynamic_max_value = maxf(_dynamic_max_value, value)

	return [snappedf(_dynamic_min_value, dynamic_range_steps),
			snappedf(_dynamic_max_value, -dynamic_range_steps)
			]
