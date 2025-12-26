extends RefCounted


static func snap_ceilf(value: float, step: float) -> float:
	return ceilf(value / step) * step


static func snap_floorf(value: float, step: float) -> float:
	return floorf(value / step) * step
