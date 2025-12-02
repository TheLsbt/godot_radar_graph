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
	# TODO: Figure out a way to check when she seperation in px is > than the inner radius than px
	for i in _dummy.size():
		var value: float = _dummy[i].value
		var mapped := remap(value, 0, total_value, 0,360)

		var start_outter := deg_to_rad(current + (_sep / out_radius * 0.5))
		var end_outter := deg_to_rad((current + mapped) - (_sep / out_radius * 0.5))
		var mid_outter := lerpf(start_outter, end_outter, 0.5)

		draw_circle(get_circle_point(Vector2.ZERO, mid_outter, out_radius), 8, Color.MAROON)

		var start_inner := deg_to_rad(current + (_sep / inner_radius * 0.5))
		var end_inner := deg_to_rad((current + mapped) - (_sep / inner_radius * 0.5))
		var mid_inner := lerpf(start_outter, end_outter, 0.5)


		var outter := _get_arc(Vector2.ZERO, out_radius, start_outter, end_outter, 15)
		var inner := _get_arc(
			Vector2.ZERO, inner_radius, end_inner, start_inner, 15)

		if is_zero_approx(inner_radius):
			var a := Vector2.ZERO + Vector2.ZERO.direction_to(
				get_circle_point(Vector2.ZERO, mid_outter, out_radius)) * _sep
			outter.append(a)
		else:
			outter.append_array(inner)

		#inner.reverse()
		draw_polygon(outter, [Color(randf(), randf(), randf())])
		current = mapped# + (seperation / inner_radius)

#endregion


#region Private

func _get_arc(center: Vector2, radius: float, start: float, end: float, complexity: int) -> PackedVector2Array:
	var points := PackedVector2Array()

	var arc_step = (end - start) / (complexity - 1)

	for i in range(complexity):
		var angle = start + arc_step * i

		points.append(get_circle_point(center, angle, radius))

	return points


func get_circle_point(center: Vector2, angle: float, radius: float) -> Vector2:
	var x = center.x + radius * cos(angle)
	var y = center.y + radius * sin(angle)
	return Vector2(x, y)

#endregion
