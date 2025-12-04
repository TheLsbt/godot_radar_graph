@tool
extends "../bases/base_graph.gd"


@export var outer_radius: float:
	set(v):
		outer_radius = v
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



## Converts a px gap to a given radius in px to a angular gap in radians
func px_to_radians(gap: float, radius: float) -> float:
	if radius <= 0 or gap <= 0:
		return 0

	var ratio := maxf(0, minf(1, gap / (2.0 * radius)))
	return 2.0 * asin(ratio)


# TODO: Make this a util, and return a dictionary containing more detailed data
func compute_wedges(values: PackedFloat32Array, center: Vector2) -> Array[PackedVector2Array]:
	if values.size() == 0:
		return []
	var total := Array(values).reduce(func(a, b): return a + b, 0)
	if total <= 0:
		printerr("Values cannot total to less than 0")
		return []

	var ref_radius := outer_radius if  is_zero_approx(inner_radius) else (outer_radius + inner_radius) / 2.0

	var s := px_to_radians(seperation, ref_radius)
	var total_seperation := 2.0 * PI - 1e-12
	print(s)

	if values.size() * s >= total_seperation:
		s = total_seperation / values.size()

	var remaining := 2.0 * PI - values.size() * s

	# Minimum wedge angle enforcment (unused)
	#var min_angle := deg_to_rad(maxf(0, min_angle_deg))

	# The start angle, currently hardcoded but could be exposed to allow for offseting the start
	const start_angle_deg := 0
	var angle := deg_to_rad(start_angle_deg)

	var results: Array[PackedVector2Array] = []
	for v in values:
		var theta: float = (v / total) * remaining

		# Minimum wedge angle enforcment (unused)
		#theta = deg_to_rad(maxf(0, min_angle_deg))

		var start = angle
		var end = angle + theta

		var outer_pts := sample_arc(center, outer_radius, start, end, 15)

		var polygon: PackedVector2Array = []
		if inner_radius > 0 and inner_radius < outer_radius:
			# NOTE: This polygon is ccw
			var inner_pts = sample_arc(center, inner_radius, end, start, 15)
			polygon = outer_pts + inner_pts
		else:
			polygon = outer_pts + PackedVector2Array([center])

		results.append(polygon)

		angle = end + s
	return results



#region Draw


func _rg_draw_pie() -> void:
	var wedges := compute_wedges([15, 20, 100], Vector2.ZERO)

	for w in wedges:
		draw_polygon(w, [Color(randf(), randf(), randf())])

		for p in w:
			draw_circle(p, 4, Color.MAGENTA)

	print(wedges)


#endregion


#region Private

func sample_arc(center: Vector2, radius: float, start: float, end: float, complexity: int) -> PackedVector2Array:
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
