class_name RecipeDefinition
extends Resource

@export var recipe_id: StringName
@export var display_name := "Recipe"
@export_multiline var description := ""
@export var category: StringName = &"crafting"
@export var ingredients: Array[Resource] = []
@export var output_item: Resource
@export_range(1, 9999, 1) var output_quantity := 1
@export_range(0.05, 120.0, 0.05) var crafting_time_seconds := 1.0
@export var required_workstation_tags: Array[StringName] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if recipe_id.is_empty():
		errors.append("A recipe is missing recipe_id.")
	if display_name.strip_edges().is_empty():
		errors.append("Recipe '%s' is missing display_name." % recipe_id)
	if ingredients.is_empty():
		errors.append("Recipe '%s' has no ingredients." % recipe_id)
	for ingredient in ingredients:
		if ingredient == null:
			errors.append("Recipe '%s' has an empty ingredient entry." % recipe_id)
		else:
			errors.append_array(ingredient.validate(recipe_id))
	if output_item == null:
		errors.append("Recipe '%s' has no output item." % recipe_id)
	if output_quantity < 1 or crafting_time_seconds <= 0.0:
		errors.append("Recipe '%s' has invalid output quantity or crafting time." % recipe_id)
	return errors


func workstation_requirements_met(available_tags: Array[StringName]) -> bool:
	for required_tag in required_workstation_tags:
		if required_tag not in available_tags:
			return false
	return true
