extends RefCounted
class_name PolygonDrawer



static func make_polygon(offset: Vector2, radius: float, key_count: int, rotation: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for i in range(key_count):
		var angle := (PI * 2 * i / key_count) + rotation - PI * .5
		var point = offset + Vector2(cos(angle), sin(angle)) * radius
		polygon.append(point)
	return polygon
