extends RefCounted


static func snap_ceilf(value: float, step: float) -> float:
	return ceilf(value / step) * step


static func snap_floorf(value: float, step: float) -> float:
	return floorf(value / step) * step


## The default callback for value scales.[br]
## [param info] requires, "min_value" (float), "max_value" (float).
static func tick_to_value_label(tick_index: int, ticks: PackedFloat32Array, info: Dictionary) -> String:
	return ""


static func tick_to_title_label(tick_index: int, ticks: PackedFloat32Array, info: Dictionary) -> String:
	return ""
