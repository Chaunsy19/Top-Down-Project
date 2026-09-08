extends SceneTree


func _initialize() -> void:
	call_deferred("open_preview")


func open_preview() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player := main.get_node("FoundationTest/Player")
	var inventory := player.get_node("Inventory")
	var registry := root.get_node("ContentRegistry")
	for item_id in [&"stick", &"stone", &"berries"]:
		inventory.add_item(registry.get_item(item_id), 10)
	var campfire := main.get_node("FoundationTest/Campfire")
	main.get_node("CraftingUI").open_crafting(player, campfire.definition.workstation_tags, "Campfire")
