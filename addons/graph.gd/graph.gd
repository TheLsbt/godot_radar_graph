@tool
extends Control


var datasets: Array[Dictionary] = []
var properties: Dictionary = {}


func _get_property_list() -> Array[Dictionary]:
	# Add the datasets.
	var list: Array[Dictionary] = []
	list.append({
		"name": "_dataset_count",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_ARRAY,
		"class_name": "Datasets,datasets/"
		})

	for i: int in get("_dataset_count"):
		var path := "datasets/"

		for p: Dictionary in get_dataset_properties(i):
			p.name = path + p.name
			list.append(p)

	return list


func _get(property: StringName) -> Variant:
	match property:
		&"_dataset_count": return properties.get("_dataset_count", 0)

	if property.begins_with("dataset"):
		var dataset_index: int = property.get_slice("/", 0).to_int()
		var dataset_property: String = property.get_slice("/", 1)
		return get_dataset_property(dataset_index, dataset_property)

	return null


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"_dataset_count":
			properties[property] = value
			datasets.resize(value)
			notify_property_list_changed()
			return true

	if property.begins_with("dataset"):
		var dataset_index: int = property.get_slice("/", 0).to_int()
		var dataset_property: String = property.get_slice("/", 1)
		return set_dataset_property(dataset_index, dataset_property, value)

	return false


## See [method Object.get_property_list]. These are a sort of blank placeholder for a dataset.
## When added to the property list each "name" is prefixed by "datasets/<dataset_index>/".
func get_dataset_properties(dataset_index: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = []

	list.append({
		"name": "%d/values" %dataset_index,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_MULTILINE_TEXT
	})
	list.append({
		"name": "%d/bar_color" %dataset_index,
		"type": TYPE_COLOR
	})


	return list


func get_dataset_property(dataset_index: int, property: StringName, default = null) -> Variant:
	if dataset_index < 0 or dataset_index >= datasets.size():
		printerr("Cannot get property '%s' on dataset '%d', becuase it is out of bounds."\
			 %[property, dataset_index])
		return default

	var dataset: Dictionary = datasets[dataset_index]

	match property:
		&"values": return dataset.get("values", "")
		&"bar_color": return dataset.get("bar_color", Color.BLACK)

	return null



func set_dataset_property(dataset_index: int, property: StringName, value: Variant) -> bool:
	if dataset_index < 0 or dataset_index >= datasets.size():
		printerr("Cannot set property '%s' on dataset '%d', becuase it is out of bounds." \
			%[property, dataset_index])
		return false
	datasets[dataset_index][property] = value
	print(property)
	return true
