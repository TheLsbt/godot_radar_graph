@tool
extends RadarGraph

## Controls the color of the shadow.
@export var shadow_color := Color.BLACK:
	set(value):
		shadow_color = value
		queue_redraw()

## Controls the offset of the shadow.
@export var shadow_offset := Vector2.ZERO:
	set(value):
		shadow_offset = value
		queue_redraw()


func _rg_draw_background() -> void:
	# Create the shadows polygon.
	var points := PackedVector2Array()
	for i in range(key_count):
		points.append(_get_polygon_point(i) + shadow_offset)

	draw_polygon(points, [shadow_color])

	# Draw the original background.
	super._rg_draw_background()
