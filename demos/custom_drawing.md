# Before we begin
This script goes over how to add a shadow to the graph.

![FinalProduct](https://github.com/user-attachments/assets/883aea0d-435d-460f-a983-d94d7cf15057)

Property values used:
- key_count = 5
- min_value = 0
- max_value = 4
- background_color = #363d4a
- graph_color = #88b6dd
- show_guide = true
- guide_color = #0304044d
- guide_step = 1

# Creating the script and variables
Lets start with making a new script that extends ```RadarGraph```, and add a few export variables to control the color and offset of the shadow.
```gdscript
@tool
extends RadarGraph

## Controls the color of the shadow.
@export var shadow_color := Color.BLACK:
	set(value):
		shadow_color = value
		queue_redraw()

## Controls the offset of the shadow.
@export var shadow_offset := Vector2.ZERO:
	set(value):
	shadow_offset = value
	queue_redraw()
```

# Overriding the _rg_draw_background function
This function needs to first draw our shadow and then draw the original backkground.

```gdscript
@tool
extends RadarGraph
aph

## Controls the color of the shadow.
@export var shadow_color := Color.BLACK:
	set(value):
		shadow_color = value
		queue_redraw()

## Controls the offset of the shadow.
@export var shadow_offset := Vector2.ZERO:
	set(value):
		shadow_offset = value
		queue_redraw()


func _rg_draw_background() -> void:
	# Create the shadows polygon.
	var points := PackedVector2Array()
	for i in range(key_count):
		points.append(_get_polygon_point(i) + shadow_offset)

	draw_polygon(points, [shadow_color])

	# Draw the original background.
	super._rg_draw_background()
```
