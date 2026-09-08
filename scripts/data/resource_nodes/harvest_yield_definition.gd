class_name HarvestYieldDefinition
extends Resource

const ItemDefinitionScript = preload("res://scripts/data/items/item_definition.gd")

@export var item_definition: ItemDefinitionScript
@export_range(1, 999, 1) var minimum_quantity := 1
@export_range(1, 999, 1) var maximum_quantity := 1


func roll_quantity(random_number_generator: RandomNumberGenerator) -> int:
	return random_number_generator.randi_range(minimum_quantity, maximum_quantity)


func validate(owner_id: StringName) -> PackedStringArray:
	var errors := PackedStringArray()
	if item_definition == null:
		errors.append("Resource node '%s' contains a yield without an item." % owner_id)
	if minimum_quantity < 1 or maximum_quantity < minimum_quantity:
		errors.append("Resource node '%s' contains an invalid yield range." % owner_id)
	return errors

