class_name RecipeIngredient
extends Resource

@export var item_definition: Resource
@export_range(1, 9999, 1) var quantity := 1


func validate(recipe_id: StringName) -> PackedStringArray:
	var errors := PackedStringArray()
	if item_definition == null:
		errors.append("Recipe '%s' has an ingredient without an item." % recipe_id)
	if quantity < 1:
		errors.append("Recipe '%s' has an invalid ingredient quantity." % recipe_id)
	return errors
