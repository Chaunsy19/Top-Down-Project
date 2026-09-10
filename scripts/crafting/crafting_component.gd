class_name CraftingComponent
extends Node

signal crafting_started(recipe: Resource)
signal crafting_progressed(recipe: Resource, ratio: float)
signal crafting_completed(recipe: Resource)
signal crafting_failed(recipe: Resource, reason: String)

var active_recipe: Resource
var elapsed_time := 0.0
var _inventory: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("crafting_component")
	_inventory = get_parent().get_node_or_null("Inventory")


func _process(delta: float) -> void:
	if get_tree().paused:
		var crafting_ui := get_tree().get_first_node_in_group("crafting_ui")
		if crafting_ui == null or not crafting_ui.is_open():
			return
	advance_crafting(delta)


func is_crafting() -> bool:
	return active_recipe != null


func get_progress_ratio() -> float:
	if active_recipe == null:
		return 0.0
	return clampf(elapsed_time / active_recipe.crafting_time_seconds, 0.0, 1.0)


func get_failure_reason(recipe: Resource, workstation_tags: Array[StringName]) -> String:
	if recipe == null:
		return "Invalid recipe."
	if is_crafting():
		return "Already crafting %s." % active_recipe.display_name
	if _inventory == null:
		return "Inventory is unavailable."
	if not recipe.workstation_requirements_met(workstation_tags):
		return "Requires: %s" % _format_tags(recipe.required_workstation_tags)
	for ingredient in recipe.ingredients:
		var owned: int = _inventory.get_item_quantity(ingredient.item_definition.item_id)
		if owned < ingredient.quantity:
			return "Need %d× %s (have %d)." % [ingredient.quantity, ingredient.item_definition.display_name, owned]
	var removals := {}
	for ingredient in recipe.ingredients:
		var item_id: StringName = ingredient.item_definition.item_id
		removals[item_id] = int(removals.get(item_id, 0)) + ingredient.quantity
	if _inventory.get_addable_quantity_after_removals(recipe.output_item, removals) < recipe.output_quantity:
		return "Not enough inventory capacity for the result."
	return ""


func start_crafting(recipe: Resource, workstation_tags: Array[StringName]) -> bool:
	var reason := get_failure_reason(recipe, workstation_tags)
	if not reason.is_empty():
		crafting_failed.emit(recipe, reason)
		return false
	for ingredient in recipe.ingredients:
		if _inventory.remove_item(ingredient.item_definition.item_id, ingredient.quantity) > 0:
			crafting_failed.emit(recipe, "Ingredients changed before crafting could start.")
			return false
	active_recipe = recipe
	elapsed_time = 0.0
	crafting_started.emit(recipe)
	crafting_progressed.emit(recipe, 0.0)
	return true


func advance_crafting(delta: float) -> void:
	if active_recipe == null or delta <= 0.0:
		return
	var actor := get_parent()
	var efficiency: float = actor.get_action_multiplier() if actor.has_method("get_action_multiplier") else 1.0
	elapsed_time += delta * efficiency
	crafting_progressed.emit(active_recipe, get_progress_ratio())
	if elapsed_time < active_recipe.crafting_time_seconds:
		return
	var completed_recipe := active_recipe
	active_recipe = null
	elapsed_time = 0.0
	var remainder: int = _inventory.add_item(completed_recipe.output_item, completed_recipe.output_quantity)
	if remainder > 0:
		crafting_failed.emit(completed_recipe, "Crafted item could not fit in inventory.")
		return
	crafting_completed.emit(completed_recipe)


func _format_tags(tags: Array[StringName]) -> String:
	var names := PackedStringArray()
	for tag in tags:
		names.append(String(tag).replace("_", " ").capitalize())
	return ", ".join(names)
