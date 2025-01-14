extends Node2D



func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var polygon = PolygonDrawer.make_polygon(Vector2.ZERO, 40, 6, 0)
	draw_polygon(polygon, [Color.RED])

	draw_circle(polygon[0], 4, Color.ORANGE)
