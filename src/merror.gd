extends RefCounted


# A small script to cleanly handle errors, stripped down so that only required methods are here.


static func boundsi(value: int, low: int, high: int, ref := "") -> bool:
	if value < low or value > high:
		if ref == "":
			printerr("Value (%d) is out of bounds. (%d, %d)" % [value, low, high])
		else:
			printerr("'%s' (%d) is out of bounds. (%d, %d)" % [ref, value, low, high])
		return true
	return false
