class_name ItemCategoryDefinition
extends Resource

@export var category_id: StringName
@export var display_name := "Category"
@export_multiline var description := ""


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if category_id.is_empty():
		errors.append("Item category is missing category_id.")
	if display_name.strip_edges().is_empty():
		errors.append("Item category '%s' is missing display_name." % category_id)
	return errors

