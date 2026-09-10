extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	test_recipe_data()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var world := main.get_node("FoundationTest")
	var player := world.get_node("Player") as CharacterBody2D
	var inventory := player.get_node("Inventory")
	var equipment := player.get_node("Equipment")
	var crafting := player.get_node("Crafting")
	var tree := world.find_child("Tree", true, false)
	var campfire := world.find_child("Campfire", true, false)
	var crafting_ui := main.get_node("CraftingUI")
	var inventory_ui := main.get_node("InventoryUI")
	var registry := root.get_node("ContentRegistry")
	var ui_manager := root.get_node("UIManager")

	for item_id in [&"stick", &"stone", &"berries"]:
		inventory.add_item(registry.get_item(item_id), 10)

	var meal_recipe: Resource = registry.get_recipe(&"cooked_berry_meal")
	var no_workstation_tags: Array[StringName] = []
	if crafting.start_crafting(meal_recipe, no_workstation_tags):
		_failures.append("The campfire recipe started without its workstation.")
	elif not crafting.get_failure_reason(meal_recipe, no_workstation_tags).begins_with("Requires"):
		_failures.append("Missing-workstation failure was not clear.")

	var axe_recipe: Resource = registry.get_recipe(&"stone_axe")
	var sticks_before: int = inventory.get_item_quantity(&"stick")
	if not crafting.start_crafting(axe_recipe, no_workstation_tags):
		_failures.append("Stone axe hand crafting could not start with valid ingredients.")
	else:
		if inventory.get_item_quantity(&"stick") != sticks_before - 2:
			_failures.append("Crafting did not consume the recipe's stick ingredients.")
		crafting.advance_crafting(axe_recipe.crafting_time_seconds * 0.5)
		if inventory.find_first_item(&"stone_axe") >= 0:
			_failures.append("Stone axe completed before its crafting duration.")
		crafting.advance_crafting(axe_recipe.crafting_time_seconds * 0.5 + 0.01)

	var axe_slot: int = inventory.find_first_item(&"stone_axe")
	if axe_slot < 0:
		_failures.append("Completed stone axe was not placed in inventory.")
	elif not equipment.equip_from_inventory(inventory, axe_slot):
		_failures.append("Crafted stone axe could not be equipped.")
	else:
		var equipped_stack: Resource = equipment.get_hand_stack()
		if equipped_stack.current_durability != equipped_stack.item_definition.tool_profile.maximum_durability:
			_failures.append("Crafted tool did not begin at full durability.")
		equipped_stack.current_durability = 7
		if not equipment.unequip_to_inventory(inventory):
			_failures.append("Equipped tool could not return to inventory.")
		elif inventory.get_slot(inventory.find_first_item(&"stone_axe")).current_durability != 7:
			_failures.append("Tool durability was lost while unequipping.")
		elif not equipment.equip_from_inventory(inventory, inventory.find_first_item(&"stone_axe")):
			_failures.append("Unequipped tool could not be re-equipped.")
		equipped_stack = equipment.get_hand_stack()
		if not tree.has_required_tool(player):
			_failures.append("Equipped crafted axe did not enable tree harvesting.")
		equipped_stack.current_durability = 1
		player.global_position = tree.global_position + Vector2.RIGHT * 48.0
		if not tree.interact(player):
			_failures.append("Tree strike could not run with an equipped axe.")
		else:
			if equipment.get_hand_stack() != null:
				_failures.append("Zero-durability axe was not removed from equipment.")

	if not crafting.start_crafting(axe_recipe, no_workstation_tags):
		_failures.append("A replacement axe could not be crafted after breakage.")
	else:
		crafting.advance_crafting(axe_recipe.crafting_time_seconds + 0.01)
		if not equipment.equip_from_inventory(inventory, inventory.find_first_item(&"stone_axe")):
			_failures.append("Replacement axe could not be equipped.")

	var campfire_tags: Array[StringName] = campfire.definition.workstation_tags
	if not crafting.start_crafting(meal_recipe, campfire_tags):
		_failures.append("Campfire cooking could not start with valid berries.")
	else:
		crafting.advance_crafting(meal_recipe.crafting_time_seconds + 0.01)
		if inventory.get_item_quantity(&"cooked_berry_meal") != 1:
			_failures.append("Campfire recipe did not produce the cooked meal.")

	crafting_ui.open_crafting(player, no_workstation_tags, "HAND CRAFTING")
	if not crafting_ui.is_open() or paused or not ui_manager.has_open_modal():
		_failures.append("Crafting UI did not open without pausing.")
	var inventory_event := InputEventAction.new()
	inventory_event.action = &"inventory"
	inventory_event.pressed = true
	inventory_ui._unhandled_input(inventory_event)
	if inventory_ui.is_open() or ui_manager.get_open_modal_count() != 1:
		_failures.append("Inventory opened over an existing crafting modal.")
	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	main._unhandled_input(pause_event)
	if not paused:
		_failures.append("Explicit pause should work with a menu open.")
	ui_manager.close_top_modal()
	if crafting_ui.is_open() or not paused or ui_manager.has_open_modal():
		_failures.append("Escape-modal behavior did not close crafting cleanly.")
	main._unhandled_input(pause_event)
	campfire.interact(player)
	if not crafting_ui.is_open() or crafting_ui.context_label.text != "CAMPFIRE":
		_failures.append("Interacting with the campfire did not open its crafting context.")
	crafting_ui.close_crafting()

	main.queue_free()
	await process_frame
	finish()


func test_recipe_data() -> void:
	var registry := root.get_node_or_null("ContentRegistry")
	var errors: PackedStringArray = registry.validate_catalogs()
	for error in errors:
		_failures.append("Catalog validation: %s" % error)
	if registry.get_recipes().size() != 6:
		_failures.append("Recipe catalog should contain both tools, cooked food, and three armor recipes.")
	for recipe_id in [&"stone_axe", &"stone_pickaxe", &"cooked_berry_meal"]:
		if registry.get_recipe(recipe_id) == null:
			_failures.append("Recipe catalog is missing '%s'." % recipe_id)
	var meal: Resource = registry.get_recipe(&"cooked_berry_meal")
	if meal == null or &"campfire" not in meal.required_workstation_tags:
		_failures.append("Cooked food is not data-bound to the campfire workstation.")
	if registry.get_workstation(&"campfire") == null:
		_failures.append("Workstation catalog is missing the campfire.")


func finish() -> void:
	if _failures.is_empty():
		print("MILESTONE 5 TEST PASSED: recipes, workstation rules, timed crafting, equipment, durability, breakage, and replacement are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
