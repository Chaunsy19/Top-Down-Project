extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
func run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame
	var player: PlayerController = get_first_node_in_group("player")
	var equipment := player.equipment
	var inventory := player.get_node("Inventory") as InventoryComponent
	var registry := root.get_node("ContentRegistry")
	for slot in EquipmentComponent.ARMOR_SLOTS:
		var item: Resource = registry.get_item(StringName("wood_armor_" + String(slot)))
		check(item != null and item.validate().is_empty(), "Valid armor content")
		inventory.add_item(registry.get_item(&"wood"), 8)
		var crafting := player.get_node("Crafting") as CraftingComponent
		var recipe: Resource = registry.get_recipe(item.item_id)
		check(crafting.start_crafting(recipe, []), "Armor hand crafting starts")
		crafting.advance_crafting(3.01)
		check(equipment.equip_armor_from_inventory(inventory, inventory.find_first_item(item.item_id), slot), "Equip " + String(slot))
	check(equipment.get_hand_stack() == null, "Armor does not occupy the hand")
	check(equipment.get_region_protection(&"left_arm") == 0.0, "Arms remain uncovered")
	for region in [&"head", &"torso", &"left_leg", &"right_leg"]:
		check(is_equal_approx(player.take_region_damage(region, 25.0, 8.0), 20.0), "Regional protection " + String(region))
	check(is_equal_approx(player.survival_needs.body_health.get_bleeding_rate(), 28.16), "Armor reduces new bleeding by 20 percent")
	var ui: CharacterUI = get_first_node_in_group("character_ui")
	ui.open_equipment()
	ui._refresh()
	check(ui._armor_choices.size() == 3 and not paused, "Three live armor controls")
	check(ui._armor_choices[&"head"].get_item_text(1).contains("20%"), "Equipped protection shown")
	ui.close_equipment()
	var tiny := InventoryComponent.new()
	tiny.slot_count = 1
	tiny.maximum_weight = 0.0
	root.add_child(tiny)
	tiny.add_item(registry.get_item(&"wood"), 1)
	check(not equipment.unequip_armor_to_inventory(tiny, &"head"), "Full inventory rejects unequip without loss")
	check(equipment.get_armor_stack(&"head") != null, "Rejected unequip retains armor")
	tiny.remove_from_slot(0, 1)
	var helmet: Resource = registry.get_item(&"wood_armor_head")
	tiny.add_item(helmet, 1)
	check(not equipment.equip_armor_from_inventory(tiny, 0, &"legs"), "Wrong slot rejected")
	check(equipment.equip_armor_from_inventory(tiny, 0, &"head"), "Full inventory supports armor swap")
	check(tiny.get_item_quantity(helmet.item_id) == 1, "Swap returns previous armor")
	tiny.remove_from_slot(0, 1)
	check(equipment.unequip_armor_to_inventory(tiny, &"head"), "Unequip returns item")
	check(equipment.get_region_protection(&"head") == 0.0, "Unequip removes protection")
	tiny.queue_free()
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("ARMOR SLOTS TEST PASSED")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
