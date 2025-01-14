@tool
extends Control
class_name RadarGraph

@export_group("colors")
@export var background_color: Color
@export var outline_color: Color

@export_group("")
@export_range(0, 1, 1, "or_greater") var key_count := 0:
	set(new_key_count):
		key_count = new_key_count
		queue_redraw()

@export var titles: Array[String] = []
@export var values: Array[float] = []:
	set(new_values):
		if new_values.size() > key_count:
			printerr("The size of this array cannot be greater than key_count")
			return
		values = new_values
		queue_redraw()
@export var radius: float = 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		var points := make_polygon(size / 2)
		draw_polygon(points, [background_color])


func _get_minimum_size() -> Vector2:
	return Vector2(radius, radius) * 2


## Returns a polygon based on [param offset], [member key_count] and [member radius].
func make_polygon(offset: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(key_count):
		var angle := (PI * 2 * i / key_count) - PI * 0.5
		var point = offset + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	return points
