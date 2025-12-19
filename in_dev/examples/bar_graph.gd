@tool
extends VBoxContainer


const BarGraph := preload('uid://ybqd0uk8xfp4')

@onready var bar_graph: BarGraph = $BarGraph


func _ready() -> void:
	bar_graph.add_data("Dataset 1", [[10,30], [10, -10]], 0, Color.INDIAN_RED)
	bar_graph.add_data("Dataset 2", [[10,30], [0, -20]], 1, Color.CADET_BLUE)
	bar_graph.add_data("Dataset 3", [[10,30], [0, -20]], 1, Color.DARK_GOLDENROD)
	bar_graph.add_data("Dataset 4", [[10,30], [0, -20]], 1, Color.PINK)


func _on_randomize_pressed() -> void:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_EXPO)
	for dataset_ref in bar_graph.datasets.size():
		for c in bar_graph.index_count:
			var prev_value := bar_graph.get_value_single(dataset_ref, c)
			var next_value := randf_range(bar_graph.min_value, bar_graph.max_value)
			tween.tween_method(
				func(value: float):
					bar_graph.set_value(dataset_ref, c, value),
				prev_value, next_value, 0.5)
