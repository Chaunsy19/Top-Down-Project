extends SceneTree


func _initialize() -> void:
	call_deferred("open_preview")


func open_preview() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var world := main.get_node("FoundationTest")
	var player := world.get_node("Player")
	var crate := world.get_node("SupplyCrate")
	var inventory := player.get_node("Inventory")
	var axe_slot: int = crate.get_node("Inventory").find_first_item(&"stone_axe")
	crate.get_node("Inventory").transfer_to(inventory, axe_slot)
	player.get_node("Equipment").equip_from_inventory(inventory, inventory.find_first_item(&"stone_axe"))
	var inventory_ui := main.get_node("InventoryUI")
	inventory_ui.open_container(crate, player, inventory, crate.get_node("Inventory"))
