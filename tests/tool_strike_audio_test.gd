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
	var sound := player.get_node("ToolStrikeAudio") as ToolStrikeAudio
	sound.set_process(false)
	var inventory := player.get_node("Inventory") as InventoryComponent
	var pick: Resource = root.get_node("ContentRegistry").get_item(&"stone_pickaxe")
	inventory.add_item(pick, 1)
	player.equipment.equip_from_inventory(inventory, inventory.find_first_item(&"stone_pickaxe"))
	var stack := player.equipment.get_hand_stack()
	check(not sound.try_play_strike([&"wood"], stack), "Wood does not trigger stone strike")
	var rock: Node
	for node in get_nodes_in_group("damageable"):
		if node.get_script() == load("res://scripts/world/resource_node.gd") and &"stone" in node.definition.damage_material_tags:
			rock = node
			break
	check(rock != null, "Stone fixture exists")
	if rock != null:
		rock.take_damage(1.0, &"tool", [&"stone"], player)
		check(sound.playing and sound.cooldown_remaining == 0.5, "Successful stone damage triggers sound")
	check(not sound.try_play_strike([&"stone"], stack), "Spam suppressed")
	sound._process(0.49)
	check(not sound.try_play_strike([&"stone"], stack), "Cooldown lasts full half second")
	sound._process(0.011)
	check(sound.try_play_strike([&"stone"], stack), "Next sound allowed after half second")
	check(not sound.stream.loop, "Strike sound is one-shot")
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("TOOL STRIKE AUDIO TEST PASSED")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

