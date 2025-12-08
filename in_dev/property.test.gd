@tool
extends Node


@export var advanced_mode := false:
	set(v):
		advanced_mode = v
		notify_property_list_changed()

var _p_item_count := 0
var _p_items := []


# The default template for all items, each entry can have a optional value of is_advanced.
func get_item_template() -> Array[Dictionary]:
	return [
		{
			"name": "value",
			"type": TYPE_ARRAY,
		}
	]


func _get_property_list() -> Array[Dictionary]:
	var path := ""
	var props: Array[Dictionary] = []
	props.append({
		"name": "_item_count",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_ARRAY,
		"class_name": "Items," + path + "items/"
	})

	for j in _p_item_count:
		var joint_path = path + "items/" + str(j) + "/"
		for t in get_item_template():
			t["name"] = joint_path + t.get("name", "")
			props.append(t)

	return props


func _get(property: StringName) -> Variant:
	if property == "_item_count":
		return _p_item_count

	if property.begins_with("items/"):
		var index: int = int(property.get_slice("/", 1))
		var p: String = property.get_slice("/", 2)

		if p == "value":
			return _p_items[index].get(p, [])

		return _p_items[index].get_or_add(p, null)

	return null


func _set(property: StringName, value: Variant) -> bool:
	if property == "_item_count":
		_p_item_count = value
		if _p_item_count < _p_items.size() - 1:
			_p_items.resize(_p_item_count)
		else:
			var a := []
			a.resize(_p_item_count - _p_items.size())
			a.fill({})
			_p_items.append_array(a)
		notify_property_list_changed()
		return true

	if property.begins_with("items/"):
		var index: int = int(property.get_slice("/", 1))
		var p: String = property.get_slice("/", 2)

		if p == "value":
			_p_items[index][p] = value
			return true

	return false

# TODO: Use _set and _get properly, this is the blueprint to evertything later on.
