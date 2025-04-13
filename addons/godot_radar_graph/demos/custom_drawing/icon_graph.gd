@tool
extends RadarGraph

# This scripts shows how you can customize the drawing besides using draw_order


@export var background_shadow_color: Color:
	set(value):
		background_shadow_color = value
		queue_redraw()
@export var background_shadow_offset: Vector2:
	set(value):
		background_shadow_offset = value
		queue_redraw()
@export var intersecting_color: Color:
	set(value):
		intersecting_color = value
		queue_redraw()


func _rg_draw_background() -> void:
	var points := PackedVector2Array()
	for i in range(key_count):
		points.append(_get_polygon_point(i) + background_shadow_offset)

	draw_polygon(points, [background_shadow_color])

	super._rg_draw_background()
#
#
func _rg_draw_graph() -> void:
	super._rg_draw_graph()

	if guide_step == 0 or not show_guides:
		return

	# Get the background polygon
	var background_polygon := PackedVector2Array()
	for index in range(key_count):
		var value: float = get_item_value(index)
		var target := _get_polygon_point(index)
		background_polygon.append(radius_v2.lerp(target, value / max_value))

	# Similar to getting the guides
	var distance_covered := 0.0
	while distance_covered <= max_value:
		var guide_polyline := PackedVector2Array()
		var p := distance_covered / max_value * radius

		for index in range(key_count):
			var angle := (PI * 2 * index / key_count) - PI * 0.5
			var point :=  radius_v2 + Vector2(cos(angle), sin(angle)) * p
			guide_polyline.append(point)
		guide_polyline.append(guide_polyline[0])

		var intersection := Geometry2D.intersect_polyline_with_polygon(
			guide_polyline, background_polygon
		)

		for intersect in intersection:
			draw_polyline(intersect, intersecting_color, guide_width, false)

		distance_covered += guide_step
