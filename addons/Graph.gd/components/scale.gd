extends RefCounted

enum ScalePosition { LEFT, TOP, RIGHT, BOTTOM }
enum ScaleMode { VALUE, LABEL }


var position: ScalePosition
var mode: ScaleMode
var include_end := false

var info: Dictionary = {}


func get_minimum_size(_available_space: Vector2) -> Vector2:
	return Vector2.ZERO


## Returns the ticks based on a 0 - 1 scale based in [member info].
func get_ticks() -> PackedFloat32Array:
	var ticks: PackedFloat32Array = []
	match mode:
		ScaleMode.LABEL:
			var labels: Array = info.get("labels", [])
			var count: int = info.get("count", 0)

			for i in range(count):
				ticks.append(i / float(count))

			if include_end:
				ticks.append(1)

	return ticks


func draw(available_space: Vector2, graph: Control) -> void:
	pass
