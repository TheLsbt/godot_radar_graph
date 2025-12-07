@tool
extends Node


var p_joint_count := 0


func _get_property_list() -> Array[Dictionary]:
	var path := ""
	var props: Array[Dictionary] = []
	props.append({
		"name": "joint_count",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_ARRAY,
		"class_name": "Joints," + path + "joints/"
	})

	for j in 5:
		var joint_path = "joints/" + str(j) + "/"
		props.append({
			"name": joint_path + "value",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT

		})
		props.append({
			"name": joint_path + "color",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT

		})

	#for (uint32_t j = 0; j < settings[i]->joints.size(); j++) {
			#String joint_path = path + "joints/" + itos(j) + "/";
			#props.push_back(PropertyInfo(Variant::STRING, joint_path + "bone_name", PROPERTY_HINT_ENUM_SUGGESTION, enum_hint, PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY));
			#props.push_back(PropertyInfo(Variant::INT, joint_path + "bone", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR | PROPERTY_USAGE_READ_ONLY));
			#props.push_back(PropertyInfo(Variant::FLOAT, joint_path + "twist_amount", PROPERTY_HINT_RANGE, "0,1,0.001,or_greater,or_less"));
		#}

	return props
	#, "Joints," + path + "joints/,static,const"));


func _get(property: StringName) -> Variant:
	if property == "joint_count":
		return p_joint_count
	elif property.ends_with("value"):
		return property
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property == "joint_count":
		p_joint_count = value
		print(property, " : ", value)
		notify_property_list_changed()
		return true
	print(property, " > ", value)

	return false
