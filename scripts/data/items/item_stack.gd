class_name ItemStack
extends Resource

const ItemDefinitionScript = preload("res://scripts/data/items/item_definition.gd")

@export var item_definition: ItemDefinitionScript
@export_range(1, 9999, 1) var quantity := 1
@export var current_durability := -1


func is_valid() -> bool:
	return item_definition != null and quantity > 0


func initialize_runtime_state() -> void:
	if item_definition != null and item_definition.tool_profile != null:
		if current_durability < 0:
			current_durability = item_definition.tool_profile.maximum_durability
		current_durability = clampi(current_durability, 0, item_definition.tool_profile.maximum_durability)


func has_durability() -> bool:
	return item_definition != null and item_definition.tool_profile != null


func damage_durability(amount := 1) -> bool:
	if not has_durability() or amount <= 0:
		return false
	initialize_runtime_state()
	current_durability = maxi(current_durability - amount, 0)
	return current_durability <= 0


func duplicate_stack(amount := -1) -> ItemStack:
	var copy := ItemStack.new()
	copy.item_definition = item_definition
	copy.quantity = quantity if amount < 0 else mini(amount, quantity)
	copy.current_durability = current_durability
	copy.initialize_runtime_state()
	return copy
