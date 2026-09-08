extends SceneTree

const InventoryComponentScript = preload("res://scripts/inventory/inventory_component.gd")
const InventoryUIScript = preload("res://scripts/inventory/inventory_ui.gd")
const InventoryContainerScript = preload("res://scripts/world/inventory_container.gd")
const PlayerInteractorScript = preload("res://scripts/interaction/player_interactor.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	await test_inventory_operations()
	await test_scene_item_lifecycle()
	finish()


func test_inventory_operations() -> void:
	var registry := root.get_node_or_null("ContentRegistry")
	if registry == null:
		_failures.append("ContentRegistry was unavailable for inventory tests.")
		return
	var wood: Resource = registry.get_item(&"wood")
	var stone: Resource = registry.get_item(&"stone")
	var source := InventoryComponentScript.new()
	source.slot_count = 3
	source.maximum_weight = 1000.0
	root.add_child(source)
	await process_frame

	if source.add_item(wood, 100) != 0:
		_failures.append("Inventory failed to accept a valid 100-unit wood addition.")
	if source.get_slot(0).quantity != 75 or source.get_slot(1).quantity != 25:
		_failures.append("Wood did not obey its data-defined stack limit.")
	if not source.split_stack(0):
		_failures.append("Inventory could not split a valid stack.")
	elif source.get_slot(0).quantity != 38 or source.get_slot(2).quantity != 37:
		_failures.append("Stack split did not preserve the expected quantities.")
	if not source.move_or_merge(2, 1):
		_failures.append("Inventory could not merge matching stacks.")
	elif source.get_slot(1).quantity != 62 or source.get_slot(2) != null:
		_failures.append("Stack merge produced an incorrect result.")

	var target := InventoryComponentScript.new()
	target.slot_count = 2
	target.maximum_weight = 1000.0
	root.add_child(target)
	await process_frame
	if source.transfer_to(target, 1, 20) != 20:
		_failures.append("Inventory-to-inventory transfer moved the wrong quantity.")
	elif target.get_slot(0).quantity != 20 or source.get_slot(1).quantity != 42:
		_failures.append("Inventory transfer did not preserve source and target quantities.")

	var weight_limited := InventoryComponentScript.new()
	weight_limited.slot_count = 4
	weight_limited.maximum_weight = 1.0
	root.add_child(weight_limited)
	await process_frame
	var remainder := weight_limited.add_item(stone, 10)
	if remainder != 9 or weight_limited.get_slot(0).quantity != 1:
		_failures.append("Inventory weight capacity did not limit item addition correctly.")

	source.queue_free()
	target.queue_free()
	weight_limited.queue_free()
	await process_frame


func test_scene_item_lifecycle() -> void:
	var packed_main := load("res://scenes/main.tscn") as PackedScene
	if packed_main == null:
		_failures.append("Main scene could not be loaded for inventory integration.")
		return
	var main := packed_main.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var world := main.get_node_or_null("FoundationTest")
	var player := world.get_node_or_null("Player") as CharacterBody2D if world else null
	var player_inventory := world.get_node_or_null("Player/Inventory") as InventoryComponentScript if world else null
	var interactor := world.get_node_or_null("Player/InteractionRange") as PlayerInteractorScript if world else null
	var crate := world.get_node_or_null("SupplyCrate") as InventoryContainerScript if world else null
	var inventory_ui := main.get_node_or_null("InventoryUI") as InventoryUIScript
	if player == null or player_inventory == null or interactor == null or crate == null or inventory_ui == null:
		_failures.append("Milestone 4 integration nodes are incomplete.")
		main.queue_free()
		return

	var axe_slot := crate.inventory.find_first_item(&"stone_axe")
	if axe_slot < 0 or crate.inventory.transfer_to(player_inventory, axe_slot) != 1:
		_failures.append("Stone axe could not transfer from the crate to the player.")
		main.queue_free()
		return
	var player_axe_slot := player_inventory.find_first_item(&"stone_axe")
	if player_axe_slot < 0:
		_failures.append("Transferred stone axe was not present in player inventory.")

	inventory_ui.open_container(crate, player, player_inventory, crate.inventory)
	if not inventory_ui.is_open() or not paused:
		_failures.append("Opening a container did not show and safely pause the inventory UI.")
	if inventory_ui.player_panel.columns != 6 or inventory_ui.container_panel.columns != 4:
		_failures.append("Player/container slot grids do not match the intended 6/4-column layout.")
	if not inventory_ui.player_panel.currency_footer.visible:
		_failures.append("Player inventory currency reservation footer is missing.")
	if inventory_ui.container_panel.currency_footer.visible:
		_failures.append("Container incorrectly displays the player currency footer.")
	inventory_ui.close_inventory()
	if paused:
		_failures.append("Closing inventory did not resume a world paused by the UI.")

	if not inventory_ui.drop_player_stack(player_axe_slot):
		_failures.append("Player could not drop the stone axe into the world.")
		main.queue_free()
		return
	if player_inventory.find_first_item(&"stone_axe") >= 0:
		_failures.append("Dropped stone axe remained in player inventory.")
	await physics_frame
	await physics_frame
	interactor.refresh_target()
	var dropped_axe := interactor.get_current_target()
	if dropped_axe == null or dropped_axe.get_debug_state() != "1× Stone Axe":
		_failures.append("Dropped stone axe was not a nearby typed world item.")
	elif not interactor.try_interact():
		_failures.append("Dropped stone axe could not be picked up.")
	await process_frame
	if player_inventory.find_first_item(&"stone_axe") < 0:
		_failures.append("Picked-up stone axe did not return to player inventory.")

	main.queue_free()
	await process_frame


func finish() -> void:
	if _failures.is_empty():
		print("MILESTONE 4 TEST PASSED: stacking, splitting, merging, capacity, transfer, UI, drop, and pickup are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

