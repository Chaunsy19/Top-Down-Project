class_name ItemCategoryCatalog
extends Resource

@export var categories: Array[Resource] = []


func get_category(category_id: StringName) -> Resource:
	for category in categories:
		if category != null and category.category_id == category_id:
			return category
	return null


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids := {}
	for category in categories:
		if category == null:
			errors.append("Item category catalog contains an empty entry.")
			continue
		errors.append_array(category.validate())
		if seen_ids.has(category.category_id):
			errors.append("Duplicate category_id '%s'." % category.category_id)
		seen_ids[category.category_id] = true
	return errors

