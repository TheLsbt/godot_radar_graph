extends RefCounted

# TODO (LSBT) use paths, eg. group/subgroup/property to store information, when making animation it will be helpful.

## A utility script that provides useful placeholders for commonly used data in graphs.

const MONTHS: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August",\
	"September", "October", "November", "December"]


## If [param short] is [code]true[/code] all months are returned abbreviated.
static func get_months(count: int, short := false) -> Array[String]:
	count = maxi(1, mini(count, MONTHS.size()))
	var months: Array[String] = MONTHS.slice(0, count)
	if not short:
		return months
	return  months.map(func(e: String): return e.substr(0, 3))
