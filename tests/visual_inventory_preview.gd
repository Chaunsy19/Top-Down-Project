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
	var inventory_ui := main.get_node("InventoryUI")
	inventory_ui.open_container(crate, player, player.get_node("Inventory"), crate.get_node("Inventory"))
