class_name ItemStack
extends Resource

const ItemDefinitionScript = preload("res://scripts/data/items/item_definition.gd")

@export var item_definition: ItemDefinitionScript
@export_range(1, 9999, 1) var quantity := 1


func is_valid() -> bool:
	return item_definition != null and quantity > 0
