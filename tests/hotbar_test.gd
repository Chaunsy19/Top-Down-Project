extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_input_actions()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var player := main.get_node("FoundationTest/Player") as PlayerController
	var inventory := player.get_node("Inventory") as InventoryComponent
	var equipment := player.get_node("Equipment") as EquipmentComponent
	var hotbar := player.get_node("Hotbar") as HotbarComponent
	var hotbar_ui := main.get_node("HotbarUI") as HotbarUI
	var inventory_ui := main.get_node("InventoryUI")
	var registry := root.get_node("ContentRegistry")
	var axe: Resource = registry.get_item(&"stone_axe")
	var pickaxe: Resource = registry.get_item(&"stone_pickaxe")
	var berries: Resource = registry.get_item(&"berries")

	inventory.add_item(axe, 1)
	inventory.add_item(pickaxe, 1)
	inventory.add_item(berries, 1)
	_assert(hotbar.assign_from_inventory(0, inventory.find_first_item(&"stone_axe")), "A tool should assign to hotbar slot 1.")
	_assert(hotbar.assign_from_inventory(1, inventory.find_first_item(&"stone_pickaxe")), "A tool should assign to hotbar slot 2.")
	_assert(not hotbar.assign_from_inventory(2, inventory.find_first_item(&"berries")), "A non-tool consumable should not assign to the tool hotbar.")
	_assert(hotbar.get_assignment(0) == &"stone_axe", "Slot 1 should remember the axe item ID.")
	_assert(hotbar.get_assignment(1) == &"stone_pickaxe", "Slot 2 should remember the pickaxe item ID.")

	_assert(hotbar.select_slot(0), "Selecting slot 1 should equip its axe.")
	_assert(equipment.get_hand_stack().item_definition.item_id == &"stone_axe", "Slot 1 equipped the wrong item.")
	_assert(player.is_combat_ready, "A weapon-capable hotbar item should become combat ready.")
	_assert(hotbar.select_slot(1), "Selecting slot 2 should swap to its pickaxe.")
	_assert(equipment.get_hand_stack().item_definition.item_id == &"stone_pickaxe", "Slot 2 equipped the wrong item.")
	_assert(not player.is_combat_ready, "A tool-only hotbar item should remain in utility mode.")
	_assert(inventory.find_first_item(&"stone_axe") >= 0, "Switching tools should return the previous tool to inventory.")
	_assert(hotbar.select_slot(8), "Selecting an empty slot should unequip the current item.")
	_assert(equipment.get_hand_stack() == null, "An empty selected slot should leave the hand empty.")

	inventory_ui.open_player_inventory()
	var axe_inventory_slot := inventory.find_first_item(&"stone_axe")
	var drag_data := {
		"kind": &"inventory_stack",
		"inventory": inventory,
		"slot_index": axe_inventory_slot,
		"item_id": &"stone_axe",
	}
	var hotbar_slot := hotbar_ui._slots[2] as HotbarSlotUI
	_assert(hotbar_slot._can_drop_data(Vector2.ZERO, drag_data), "A player inventory tool should be accepted by a hotbar drop target.")
	hotbar_slot._drop_data(Vector2.ZERO, drag_data)
	_assert(hotbar.get_assignment(2) == &"stone_axe", "Inventory assignment should update the requested hotbar slot.")
	var berry_drag_data := drag_data.duplicate()
	berry_drag_data.slot_index = inventory.find_first_item(&"berries")
	berry_drag_data.item_id = &"berries"
	_assert(not hotbar_slot._can_drop_data(Vector2.ZERO, berry_drag_data), "A consumable should be rejected by a tool/weapon hotbar slot.")
	inventory_ui.close_inventory()
	_assert(hotbar.select_slot(2), "The reassigned axe should be selectable.")
	_assert(hotbar.select_slot(2), "Selecting the active occupied slot again should holster it.")
	_assert(hotbar.selected_slot == -1 and equipment.get_hand_stack() == null, "Hotbar toggle-off should leave the player's hands free.")

	_assert(hotbar_ui._slots.size() == 9, "The HUD should create exactly nine hotbar slots.")
	_assert(hotbar.get_assignment(0).is_empty(), "Reassigning an item should clear its previous duplicate shortcut.")
	_assert(hotbar.clear_slot(2), "An assigned hotbar slot should be clearable.")
	_assert(hotbar.get_assignment(2).is_empty(), "Clearing a slot should remove its assignment.")

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("HOTBAR TEST PASSED: key actions, drag assignment, category filtering, contextual readiness, toggle holstering, and nine-slot HUD are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_input_actions() -> void:
	for index in HotbarComponent.SLOT_ACTIONS.size():
		var action := HotbarComponent.SLOT_ACTIONS[index]
		_assert(InputMap.has_action(action), "Missing input action: %s" % action)
		var expected_key := KEY_1 + index
		var has_expected_key := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and (event.physical_keycode == expected_key or event.keycode == expected_key):
				has_expected_key = true
		_assert(has_expected_key, "%s should use number key %d." % [action, index + 1])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
