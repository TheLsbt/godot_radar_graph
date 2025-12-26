@tool
extends VBoxContainer


const BarGraph := preload('uid://ybqd0uk8xfp4')
const LineGraph = preload('uid://bg4a56mduord1')

@onready var bar_graph: BarGraph = $Graphs/BarGraph
@onready var line_graph: LineGraph = $Graphs/LineGraph


func _ready() -> void:
	bar_graph.add_data("Dataset 1", [[10,300], [10, -20]], 0, Color.INDIAN_RED)
	bar_graph.add_data("Dataset 2", [[10,30], [0, -20]], 1, Color.CADET_BLUE)
	bar_graph.add_data("Dataset 3", [[10,30], [0, 300]], 1, Color.DARK_GOLDENROD)
	bar_graph.add_data("Dataset 4", [[10,30], [0, -20]], 1, Color.PINK)

	var datasets: Array[Dictionary] = [
		{"label": "Dataset 1", "values": [5, 10, 15], "color": Color.INDIAN_RED},
		{"label": "Dataset 2", "values": [60, 10.5, 20], "color": Color.CADET_BLUE},
		{"label": "Dataset 2", "values": [-5, -10, -32], "color": Color.MAROON}
	]
	line_graph.update_datasets_array(datasets)


func _on_randomize_pressed() -> void:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_EXPO)
	for dataset_ref in bar_graph.datasets.size():
		for c in bar_graph.index_count:
			var prev_value := bar_graph.get_value_range(dataset_ref, c)
			var next_value := [randf_range(bar_graph.min_value, bar_graph.max_value), randf_range(bar_graph.min_value, bar_graph.max_value)]
			tween.tween_method(
				func(value: Array):
					bar_graph.set_value(dataset_ref, c, value[0]),
				prev_value, next_value, 0.5)
