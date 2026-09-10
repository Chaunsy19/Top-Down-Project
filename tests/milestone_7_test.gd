extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame
	var world := main.get_node("FoundationTest") as GridWorld
	var player := world.get_node("Player") as PlayerController
	var inventory := player.get_node("Inventory") as InventoryComponent
	var system := main.get_node("BuildingSystem")
	var registry := root.get_node("ContentRegistry")
	_assert(registry.building_catalog != null and registry.get_buildings().size() == 6, "The data-driven catalog should expose all six starter buildables.")
	inventory.add_item(registry.get_item(&"wood"), 60)
	inventory.add_item(registry.get_item(&"stone"), 10)
	var cells := _find_open_cells(world, 6)
	_assert(cells.size() == 6, "The test map needs six open build cells.")
	if cells.size() < 6:
		_finish(main)
		return

	var wood_before := inventory.get_item_quantity(&"wood")
	var floor := await _build(system, world, player, registry.get_building(&"wood_floor"), cells[0])
	_assert(floor != null and floor.definition.behavior == "floor", "Wood floor construction did not complete.")
	_assert(inventory.get_item_quantity(&"wood") == wood_before - 2, "Floor placement should deduct its data-defined cost.")
	_assert(world.is_cell_walkable(cells[0]), "A completed floor should remain walkable.")
	_assert(not system.can_place_at_cell(registry.get_building(&"wood_floor"), cells[0]).is_empty(), "A built tile should prevent duplicate placement.")

	var wall := await _build(system, world, player, registry.get_building(&"wood_wall"), cells[1])
	_assert(wall != null and not world.is_cell_walkable(cells[1]), "A completed wall should block its grid cell.")
	_assert(wall.health.maximum_health == 200.0, "Wood buildings should begin with 200 health.")
	_assert(wall.take_damage(60.0, &"tool", [&"stone"]) == 0.0, "Stone tool damage should not affect a wood building.")
	_assert(wall.take_damage(30.0, &"tool", [&"wood"]) == 30.0, "Wood tool damage should affect a wood building.")
	_assert(wall.take_damage(12.0, &"melee") == 12.0, "Melee damage should affect a building regardless of material type.")
	var health_before_attacks: float = wall.health.current_health
	inventory.add_item(registry.get_item(&"stone_pickaxe"), 1)
	inventory.add_item(registry.get_item(&"stone_axe"), 1)
	var hotbar := player.get_node("Hotbar") as HotbarComponent
	hotbar.assign_from_inventory(0, inventory.find_first_item(&"stone_pickaxe"))
	hotbar.assign_from_inventory(1, inventory.find_first_item(&"stone_axe"))
	hotbar.select_slot(0)
	player.perform_melee_attack_at(wall.global_position)
	_assert(wall.health.current_health == health_before_attacks - 12.0, "A pickaxe should fall back to melee damage against wood.")
	hotbar.select_slot(1)
	player.perform_melee_attack_at(wall.global_position)
	_assert(wall.health.current_health == health_before_attacks - 42.0, "An axe should use tool damage against a wood building.")
	hotbar.select_slot(1)
	player.global_position = world.to_global(world.cell_to_world(cells[1] + Vector2i.RIGHT))
	await physics_frame
	_assert(player.test_move(player.global_transform, Vector2.LEFT * world.grid_size), "A completed wall should physically collide with the player.")
	var door := await _build(system, world, player, registry.get_building(&"wood_door"), cells[2])
	_assert(door != null and not world.is_cell_walkable(cells[2]), "A closed door should block movement.")
	door.interact(player)
	_assert(door.is_open and world.is_cell_walkable(cells[2]), "Opening a door should release grid occupancy.")
	door.interact(player)
	_assert(not door.is_open and not world.is_cell_walkable(cells[2]), "Closing a door should restore grid occupancy.")

	var storage := await _build(system, world, player, registry.get_building(&"storage_chest"), cells[3])
	_assert(storage != null and storage.inventory.slot_count == 20, "Built storage should expose its configured inventory.")
	storage.interact(player)
	var inventory_ui := main.get_node("InventoryUI")
	_assert(inventory_ui.is_open(), "Built storage should open the container inventory UI.")
	inventory_ui.close_inventory()

	var campfire := await _build(system, world, player, registry.get_building(&"campfire"), cells[4])
	_assert(campfire != null and campfire.soft_light.enabled, "Built campfire should provide its soft light.")
	_assert(&"cooking" in campfire.definition.workstation_definition.workstation_tags, "Built campfire should retain cooking capabilities.")
	var sleeping_spot := await _build(system, world, player, registry.get_building(&"sleeping_spot"), cells[5])
	sleeping_spot.interact(player)
	_assert(player.survival_needs.is_resting, "Built sleeping spot should toggle player rest.")
	player.survival_needs.set_resting(false)
	_finish(main)


func _build(system: Node, world: GridWorld, player: PlayerController, definition: Resource, cell: Vector2i) -> Node:
	system.begin_placement(definition)
	var site: Node = system.place_selected_at_cell(cell)
	_assert(site != null, "%s site could not be placed: %s" % [definition.display_name, system.placement_reason])
	if site == null:
		return null
	player.global_position = world.to_global(world.cell_to_world(cell + Vector2i.RIGHT))
	await physics_frame
	site.interact(player)
	site.continue_hold_interaction(player, definition.construction_time + 0.01)
	await physics_frame
	await physics_frame
	for structure in get_nodes_in_group("built_structure"):
		if structure.definition == definition and world.world_to_cell(structure.global_position) == cell:
			return structure
	return null


func _find_open_cells(world: GridWorld, count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(1, world.grid_dimensions.y - 1):
		for x in range(1, world.grid_dimensions.x - 1):
			var cell := Vector2i(x, y)
			if world.is_cell_walkable(cell):
				result.append(cell)
				if result.size() == count:
					return result
	return result


func _finish(main: Node) -> void:
	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("MILESTONE 7 TEST PASSED: catalog, costs, preview validation, construction, collision, door, storage, campfire, and sleeping behavior are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
