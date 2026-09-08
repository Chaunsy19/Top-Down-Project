class_name ToolProfile
extends Resource

@export var capability_tags: Array[StringName] = []
@export_range(1, 100, 1) var tier := 1
@export_range(0.1, 20.0, 0.05) var work_speed_multiplier := 1.0
@export_range(1, 100000, 1) var maximum_durability := 100


func satisfies(required_tags: Array[StringName], minimum_tier: int) -> bool:
	if tier < minimum_tier:
		return false
	for required_tag in required_tags:
		if required_tag not in capability_tags:
			return false
	return true


func validate(owner_id: StringName) -> PackedStringArray:
	var errors := PackedStringArray()
	if capability_tags.is_empty():
		errors.append("Tool '%s' has no capability tags." % owner_id)
	if tier < 1:
		errors.append("Tool '%s' has an invalid tier." % owner_id)
	if work_speed_multiplier <= 0.0:
		errors.append("Tool '%s' has an invalid work speed multiplier." % owner_id)
	if maximum_durability < 1:
		errors.append("Tool '%s' has invalid maximum durability." % owner_id)
	return errors

