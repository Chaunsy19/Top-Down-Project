class_name RecipeCatalog
extends Resource

@export var recipes: Array[Resource] = []


func get_recipe(recipe_id: StringName) -> Resource:
	for recipe in recipes:
		if recipe != null and recipe.recipe_id == recipe_id:
			return recipe
	return null


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids := {}
	for recipe in recipes:
		if recipe == null:
			errors.append("Recipe catalog contains an empty entry.")
			continue
		errors.append_array(recipe.validate())
		if seen_ids.has(recipe.recipe_id):
			errors.append("Duplicate recipe_id '%s'." % recipe.recipe_id)
		seen_ids[recipe.recipe_id] = true
	return errors
