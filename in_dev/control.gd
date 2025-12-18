@tool
extends "res://addons/graph.gd/bar_graph.gd"




func _init() -> void:
	add_data("Dataset 1", [[10,30], [10, -10]], 0, Color.INDIAN_RED)
	add_data("Dataset 2", [[10,30], [0, -20]], 1, Color.CADET_BLUE)
	add_data("Dataset 3", [[10,30], [0, -20]], 1, Color.DARK_GOLDENROD)
	add_data("Dataset 4", [[10,30], [0, -20]], 1, Color.PINK)
