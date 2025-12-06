@tool
extends Control

enum ScaleLocation { LEFT, RIGHT, TOP, BOTTOM }

var _dirty_cache := false


"""
grid: {
	thickness: float
	color: Color
}
as_index: {
	scale_as_index: bool <only one scale can be used as the index>
	count: int
}
range: Array[float]
stacked: bool
"""
func add_scale(title: String, location: ScaleLocation, config: Dictionary) -> void:
	pass


# TODO: Move this into a higher function like a graph.gd
func update() -> void:
	_update()


# Override.
func _update() -> void:
	pass
