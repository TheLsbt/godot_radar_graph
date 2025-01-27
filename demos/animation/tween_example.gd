extends VBoxContainer

const ANIMATION_DURATION := 0.4

@onready var radar_graph: RadarGraph = $RadarGraph


func _on_button_pressed() -> void:
	var tween := create_tween().set_parallel()

	for i in range(radar_graph.key_count):
		var rand := randf_range(radar_graph.min_value, radar_graph.max_value)
		tween.tween_property(
			radar_graph, "items/key_%d/value" %i, rand, ANIMATION_DURATION)
		print(rand)
