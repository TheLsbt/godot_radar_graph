@tool
extends "../bases/base_graph.gd"


@export var out_radius: float:
	set(v):
		out_radius = v
		queue_redraw()
@export var inner_radius: float:
	set(v):
		inner_radius = v
		queue_redraw()
@export var seperation: float = 2.0:
	set(v):
		seperation = v
		queue_redraw()



func get_default_draw_order() -> PackedStringArray:
	return ["pie"]


func get_item_properties() -> Array[Dictionary]:
	return []


func item_get(item: int, property: String) -> Variant:
	return null


func item_set(item: int, property: String, value: Variant) -> bool:
	return false


func item_property_can_revert(item: int, property: String) -> bool:
	return false


func item_property_get_revert(item: int, property: String) -> Variant:
	return false



#region Draw

func _rg_draw_pie() -> void:
	var _dummy := [{
		"value": 10
	},{
		"value": 30
	}
	]

	var empty_space := seperation * _dummy.size()



	var total_value := _dummy.reduce(func(a, e): return a + e.value, 0)
	print(total_value)
	var current := 0.0
	var _sep := seperation / .25
	print(seperation > PI / inner_radius * 10)
	for i in _dummy.size():
		var value: float = _dummy[i].value
		var mapped := remap(value, 0, total_value, 0,360)

		var outter := _get_arc(Vector2.ZERO, out_radius, deg_to_rad(current + (_sep / out_radius * 0.5)), deg_to_rad((current + mapped) - (_sep / out_radius * 0.5)), 15)
		var inner := _get_arc(
			Vector2.ZERO, inner_radius, deg_to_rad((current + mapped) - (_sep / inner_radius * 0.5)), deg_to_rad(current + (_sep / inner_radius * 0.5)), 15)
		#inner.reverse()
		outter.append_array(inner)
		draw_polygon(outter, [Color(randf(), randf(), randf())])
		current = mapped# + (seperation / inner_radius)

#endregion


#region Private

func _get_arc(center: Vector2, radius: float, start: float, end: float, complexity: int) -> PackedVector2Array:
	var points := PackedVector2Array()

	var arc_step = (end - start) / (complexity - 1)

	for i in range(complexity):
		var angle = start + arc_step * i
		var x = center.x + radius * cos(angle)
		var y = center.y + radius * sin(angle)
		points.append(Vector2(x, y))

	return points

#endregion
