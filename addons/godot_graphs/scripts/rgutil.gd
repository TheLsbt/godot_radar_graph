extends RefCounted


static func range_to_px(value: float, min_value: float, max_value: float, px_begin: float, px_end: float) -> float:
	return remap(value, min_value, max_value, px_begin, px_end)
