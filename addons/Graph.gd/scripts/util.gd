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


## If [param value] is a callable and then the return from the call is returned, otherwise
## [param value] is returned as normal.
func variant_or_call(value) -> Variant:
	if typeof(value) == TYPE_CALLABLE:
		return value.call()
	return value
