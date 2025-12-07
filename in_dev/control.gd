@tool
extends "res://addons/graph.gd/bar_graph.gd"




func _init() -> void:
	add_scale("a", ScaleLocation.BOTTOM, {"as_index": {"count": 7}})
	add_data({
		"label": "Dataset 1",
		"values": [10, 30, [30, 50]],
		"group": 0,
		"background_color": Color.INDIAN_RED
	})
	add_data({
		"label": "Dataset 2",
		"values": [30, [30, 40], 30],
		"group": 1,
		"background_color": Color.CADET_BLUE
	})
	add_data({
		"label": "Dataset 3",
		"values": [10, [5, 10], 100],
		"group": 1,
		"background_color": Color.DARK_ORANGE
	})
	add_data({
		"label": "Dataset 4",
		"values": [[20, 30], 20, 20],
		"group": 1,
		"background_color": Color.PINK
	})
