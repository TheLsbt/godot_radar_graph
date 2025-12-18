@tool
extends VBoxContainer


@onready var bar_graph: Control = $BarGraph



func _ready() -> void:
	bar_graph.add_data("Dataset 1", [[10,30], [10, -10]], 0, Color.INDIAN_RED)
	bar_graph.add_data("Dataset 2", [[10,30], [0, -20]], 1, Color.CADET_BLUE)
	bar_graph.add_data("Dataset 3", [[10,30], [0, -20]], 1, Color.DARK_GOLDENROD)
	bar_graph.add_data("Dataset 4", [[10,30], [0, -20]], 1, Color.PINK)
