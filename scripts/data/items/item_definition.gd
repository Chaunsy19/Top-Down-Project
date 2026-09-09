class_name ItemDefinition
extends Resource

@export var item_id: StringName
@export var display_name := "Item"
@export_multiline var description := ""
@export var categories: Array[StringName] = []
@export_range(1, 9999, 1) var stack_limit := 50
@export_range(0.0, 1000.0, 0.01) var weight := 0.1
@export_range(0.0, 100.0, 0.5) var nutrition := 0.0
@export var world_color := Color.WHITE
@export var icon: Texture2D
@export var tool_profile: Resource


func has_category(category_id: StringName) -> bool:
	return category_id in categories


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_id.is_empty():
		errors.append("Item definition is missing item_id.")
	if display_name.strip_edges().is_empty():
		errors.append("Item '%s' is missing display_name." % item_id)
	if categories.is_empty():
		errors.append("Item '%s' has no categories." % item_id)
	if stack_limit < 1:
		errors.append("Item '%s' has an invalid stack_limit." % item_id)
	if has_category(&"tool") and tool_profile == null:
		errors.append("Tool item '%s' is missing a tool profile." % item_id)
	if tool_profile != null and stack_limit != 1:
		errors.append("Durable tool item '%s' must have a stack limit of one." % item_id)
	if tool_profile != null:
		errors.append_array(tool_profile.validate(item_id))
	return errors
