@tool
extends EditorPlugin

const custom_script := preload("radar_graph.gd")
const icon := preload("radar_graph_icon.svg")


func _enter_tree() -> void:
	add_custom_type("RadarGraph", "Control", custom_script, icon)


func _exit_tree() -> void:
	remove_custom_type("RadarGraph")
