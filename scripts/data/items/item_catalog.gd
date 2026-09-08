class_name ItemCatalog
extends Resource

@export var items: Array[Resource] = []


func get_item(item_id: StringName) -> Resource:
	for item in items:
		if item != null and item.item_id == item_id:
			return item
	return null


func get_items_in_category(category_id: StringName) -> Array[Resource]:
	var matches: Array[Resource] = []
	for item in items:
		if item != null and item.has_category(category_id):
			matches.append(item)
	return matches


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids := {}
	for item in items:
		if item == null:
			errors.append("Item catalog contains an empty entry.")
			continue
		errors.append_array(item.validate())
		if seen_ids.has(item.item_id):
			errors.append("Duplicate item_id '%s'." % item.item_id)
		seen_ids[item.item_id] = true
	return errors

