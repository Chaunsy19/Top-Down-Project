class_name BuildCost
extends Resource

@export var item_definition: Resource
@export_range(1, 999, 1) var quantity := 1


func validate(owner_id: StringName) -> PackedStringArray:
	var errors := PackedStringArray()
	if item_definition == null:
		errors.append("Building '%s' has a cost with no item." % owner_id)
	if quantity < 1:
		errors.append("Building '%s' has a non-positive cost." % owner_id)
	return errors
