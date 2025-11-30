@abstract
@tool
extends Control

## The base for any graph you may need. No structure and just a backbone.

@export var draw_order := get_default_draw_order():
	set(v):
		draw_order = v
		queue_redraw()
@export var item_count: int = 0:
	set = _set_item_count
@export_storage var _items: Array[Dictionary] = []


var dirty: bool = false


@abstract func get_default_draw_order() -> PackedStringArray


#region Private
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_cache()
		for i in draw_order:
			var method := &"_rg_draw_%s" % i
			if has_method(method):
				call(method)


func _cache() -> void:
	pass


func _set_item_count(new_count: int) -> void:
	var _changed = false
	if new_count < item_count:
		_items.resize(new_count)
		_changed = true
	elif new_count > item_count:
		var a = []
		a.resize(new_count - item_count)
		# TODO: Make this data driven
		a.fill({"value": 0.0, "color": Color.BLACK, "title": ""})
		_items.append_array(a)
		_changed = true
	if _changed:
		notify_property_list_changed()
		dirty = true
		queue_redraw()
	item_count = new_count

#endregion


#region Custom Property Management
func _get_property_list() -> Array[Dictionary]:
	var formatter := func (property: Dictionary, item: int) -> Dictionary:
		property.merge({"name": "items/%d/%s" % [ item, property.get("name", "") ]}, true)
		return property

	var list: Array[Dictionary] = []
	for i in item_count:
		var properties = get_item_properties().map(formatter.bind(i))
		list.append_array(properties.duplicate(true))

	return list


## Override when dealing with items. See [method Object._get_property_list].
@abstract func get_item_properties() -> Array[Dictionary]


func _get(path: StringName) -> Variant:
	if not path.begins_with("items") or path.count("/") != 2:
		return null

	var item: int = int(path.get_slice("/", 1))
	var property: String = path.get_slice("/", 2)

	return item_get(item, property)


## Override when dealing with items. See [method Object._get].
@abstract func item_get(item: int, property: String) -> Variant


func _set(path: StringName, value: Variant) -> bool:
	if not path.begins_with("items") or path.count("/") != 2:
		return false

	var item: int = int(path.get_slice("/", 1))
	var property: String = path.get_slice("/", 2)

	return item_set(item, property, value)


## Override when dealing with items. See [method Object._set].
@abstract func item_set(item: int, property: String, value: Variant) -> bool


func _property_can_revert(path: StringName) -> bool:
	if path == &'draw_order':
		return draw_order != get_default_draw_order()

	if not path.begins_with("items") or path.count("/") != 2:
		return false

	var item: int = int(path.get_slice("/", 1))
	var property: String = path.get_slice("/", 2)

	return item_property_can_revert(item, property)


## Override when dealing with items. See [method Object.property_can_revert].
@abstract func item_property_can_revert(item: int, property: String) -> bool


func _property_get_revert(path: StringName) -> Variant:
	if path == &'draw_order':
		return get_default_draw_order()

	if not path.begins_with("items") or path.count("/") != 2:
		return false

	var item: int = int(path.get_slice("/", 1))
	var property: String = path.get_slice("/", 2)

	return item_property_get_revert(item, property)


## Override when dealing with items. See [method Object.property_get_revert].
func item_property_get_revert(item: int, property: String) -> Variant:
	return null

#endregion
