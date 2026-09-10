extends SceneTree

const DragHandleScript = preload("res://scripts/ui/draggable_window_handle.gd")
const CharacterUIScript = preload("res://scripts/ui/character_ui.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var world := main.get_node("FoundationTest")
	var player := world.get_node("Player") as PlayerController
	var needs := player.get_node("Needs")
	var inventory := player.get_node("Inventory") as InventoryComponent
	var ui_manager := root.get_node("UIManager")
	var hud := main.get_node("SurvivalHUD")
	var character_ui := main.get_node("CharacterUI") as CharacterUIScript
	var inventory_ui := main.get_node("InventoryUI")
	var crafting_ui := main.get_node("CraftingUI")
	var build_ui := main.get_node("BuildUI")

	var dock := hud.get_node("Dock") as Control
	_assert(dock.anchor_left == 1.0 and dock.anchor_top == 1.0, "The character dock should anchor to the bottom-right corner.")
	for button_name in ["InventoryButton", "HealthButton", "EquipmentButton", "HungerButton", "RestButton"]:
		var button := dock.find_child(button_name, true, false) as Button
		_assert(button != null and button.icon != null, "%s should exist and use its icon asset." % button_name)

	hud.health_button.pressed.emit()
	_assert(character_ui.is_health_open() and paused, "The health dock button should open its panel and pause safely.")
	hud.equipment_button.pressed.emit()
	_assert(character_ui.is_equipment_open() and ui_manager.get_open_modal_count() == 2, "Health and Equipment should be able to remain open independently.")
	character_ui.close_health()
	_assert(not character_ui.is_health_open() and character_ui.is_equipment_open() and paused, "Closing Health should leave Equipment open and retain the modal pause.")
	ui_manager.close_top_modal()
	_assert(not character_ui.is_equipment_open() and not paused, "Closing the final character panel should resume the world.")

	character_ui.open_health()
	var health_header := character_ui.health_panel.get_node("Margin/Layout/Header") as DragHandleScript
	_assert(health_header.get_script() == DragHandleScript, "Health should use the shared draggable title bar.")
	var original_position := character_ui.health_panel.position
	var drag_origin := character_ui.health_panel.global_position + Vector2(20.0, 15.0)
	health_header.begin_drag(drag_origin)
	health_header.drag_to(drag_origin + Vector2(75.0, 45.0))
	health_header.end_drag()
	_assert(character_ui.health_panel.position.distance_to(original_position) > 20.0, "Dragging a title bar should move its window.")
	character_ui.close_health()

	needs.hunger = needs.critical_threshold
	needs.fatigue = needs.critical_threshold
	hud._refresh()
	_assert(hud.hunger_button.visible and hud.rest_button.visible, "Ham and bed alerts should appear when hunger and rest are low.")
	hud.hunger_button.pressed.emit()
	_assert(inventory_ui.is_open(), "The low-hunger ham alert should open the inventory.")
	inventory_ui.close_inventory()

	var crate := world.find_child("SupplyCrate", true, false)
	_assert(crate != null, "The UI test requires the supply crate fixture.")
	if crate != null:
		inventory_ui.open_container(crate, player, inventory, crate.get("inventory"))
		_assert(_has_drag_handle(inventory_ui.player_panel) and _has_drag_handle(inventory_ui.container_panel), "Inventory and container panels should both have draggable title bars.")
		inventory_ui.close_container_panel()
		_assert(inventory_ui.is_open() and inventory_ui.player_panel.visible and not inventory_ui.container_panel.visible, "Closing the container should leave the player inventory open.")
		inventory_ui.close_player_panel()
		_assert(not inventory_ui.is_open() and not paused, "Closing the last inventory panel should close the inventory workspace.")

	crafting_ui.open_crafting(player)
	_assert(_has_drag_handle(crafting_ui.get_node("Overlay/Panel")), "Crafting should have a draggable title bar.")
	crafting_ui.get_node("Overlay/Panel/Margin/Layout/Header/CloseButton").pressed.emit()
	_assert(not crafting_ui.is_open(), "Crafting should close from its own close button.")

	build_ui.panel.visible = true
	_assert(_has_drag_handle(build_ui.panel), "The build palette should have a draggable title bar.")
	build_ui.get_node("Root/CatalogPanel/Margin/Layout/Header/CloseButton").pressed.emit()
	_assert(not build_ui.panel.visible, "The build palette should close from its own close button.")

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("UI WINDOWS TEST PASSED: draggable panels, independent closing, character dock, and need alerts are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _has_drag_handle(panel: Control) -> bool:
	var header := panel.get_node_or_null("Margin/Layout/Header")
	return header != null and header.get_script() == DragHandleScript


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
