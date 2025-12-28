extends RefCounted


static func snap_ceilf(value: float, step: float) -> float:
	return ceilf(value / step) * step


static func snap_floorf(value: float, step: float) -> float:
	return floorf(value / step) * step


## The default callback for value scales.[br]
## [param info] requires, "min_value" (float), "max_value" (float).
static func tick_to_value_label(tick_index: int, ticks: PackedFloat32Array, info: Dictionary) -> String:
	var min_value: float = info.get("min_value", 0.0)
	var max_value: float = info.get("max_value", 100.0)
	var tick: float = ticks[tick_index]
	var value: float = denormalize_value(tick, min_value, max_value)
	value = snappedf(value, 0.1)

	return str(value)


static func tick_to_title_label(tick_index: int, ticks: PackedFloat32Array, info: Dictionary) -> String:
	var labels: Array = info.get("labels", [])
	if labels.size() == 0:
		return ""
	return labels[wrapi(tick_index, 0, labels.size())]


## Converts a value ([param v]) into a range from 0 to 1.
static func normalize_value(v: float, vmin: float, vmax: float) -> float:
	if vmax == vmin:
		return 0.0
	return (v - vmin) / (vmax - vmin)


## Converts a value ([param v]) from a range to its actual representation.
static func denormalize_value(v: float, vmin: float, vmax: float) -> float:
	return v * (vmax - vmin) + vmin


const MONTHS_SHORT: PackedStringArray =\
	["Jan", "Feb", "Mar", "Apr", "May", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]


static func get_months_short(count: int) -> PackedStringArray:
	return MONTHS_SHORT.slice(0, count)
