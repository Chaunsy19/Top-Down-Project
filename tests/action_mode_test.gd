extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_assert_action_key(&"toggle_combat", KEY_R)
	_assert_action_key(&"rest", KEY_T)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var world := main.get_node("FoundationTest")
	var player := world.get_node("Player") as PlayerController
	var interactor := player.get_node("InteractionRange") as PlayerInteractor
	var inventory := player.get_node("Inventory") as InventoryComponent
	var equipment := player.get_node("Equipment") as EquipmentComponent
	var tree := world.get_node("Tree") as HarvestableResourceNode
	var terminal := world.get_node("TestTerminal")
	var combat_visual := player.get_node("AimPivot/CombatStanceVisual")
	var registry := root.get_node("ContentRegistry")

	_assert(player.are_weapons_holstered(), "The player should begin with weapons holstered.")
	_assert(not combat_visual.is_stance_visible(), "Raised fists or weapons should be hidden while holstered.")
	inventory.add_item(registry.get_item(&"stone_axe"), 1)
	equipment.equip_from_inventory(inventory, inventory.find_first_item(&"stone_axe"))
	player.global_position = tree.global_position + Vector2.RIGHT * 48.0
	player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame

	var initial_harvests := tree.remaining_harvests
	_assert(interactor.begin_primary_action_at(tree.get_interaction_point()), "Holstered left-click on a resource should begin a valid harvest.")
	_assert(interactor.is_holding_primary_action() and tree.is_harvesting(), "Harvesting should enter the held-action state.")
	tree._process(0.5)
	_assert(is_zero_approx(tree.harvest_progress), "Harvest progress must not advance independently of the held action.")
	interactor.continue_primary_action(tree.get_effective_harvest_time(player) * 0.5)
	_assert(tree.harvest_progress > 0.0 and tree.remaining_harvests == initial_harvests, "A partial hold should advance without completing.")
	interactor.end_primary_action()
	_assert(not tree.is_harvesting() and is_zero_approx(tree.harvest_progress), "Releasing left click should cancel and reset partial work.")

	_assert(interactor.begin_primary_action_on(tree), "A harvest should restart after cancellation.")
	interactor.continue_primary_action(tree.get_effective_harvest_time(player) + 0.01)
	_assert(tree.remaining_harvests == initial_harvests - 1, "Holding for the full duration should complete one harvest.")
	interactor.end_primary_action()

	var attacks: Array[Vector2] = []
	player.attack_requested.connect(func(direction: Vector2) -> void: attacks.append(direction))
	player.set_combat_ready(true)
	_assert(player.is_combat_ready and not player.are_weapons_holstered(), "R combat mode should expose the combat-ready state.")
	_assert(combat_visual.is_stance_visible(), "Combat-ready mode should raise fists or the equipped item.")
	_assert(not interactor.begin_primary_action_on(tree), "Combat-ready mode must block harvesting and utility interaction.")
	var attack_event := InputEventAction.new()
	attack_event.action = &"attack"
	attack_event.pressed = true
	player._unhandled_input(attack_event)
	_assert(attacks.size() == 1, "Combat-ready left click should emit one attack request.")
	_assert(combat_visual.is_attack_animating(), "A combat click should play visible fist or weapon attack feedback.")

	player.set_combat_ready(false)
	player.global_position = terminal.global_position + Vector2.RIGHT * 40.0
	await physics_frame
	await physics_frame
	var terminal_uses: int = terminal.activation_count
	_assert(interactor.begin_primary_action_on(terminal), "Holstered left click should perform a one-shot interaction.")
	_assert(terminal.activation_count == terminal_uses + 1, "The terminal should activate on a utility click.")
	var legacy_interact_event := InputEventAction.new()
	legacy_interact_event.action = &"interact"
	legacy_interact_event.pressed = true
	interactor._unhandled_input(legacy_interact_event)
	_assert(terminal.activation_count == terminal_uses + 1, "The old E input should not bypass left-click interaction routing.")

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("ACTION MODE TEST PASSED: held harvesting, release cancellation, holstered utility routing, combat attacks, stance visuals, and R/T mappings are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert_action_key(action: StringName, expected_key: Key) -> void:
	var matched := false
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event.physical_keycode == expected_key or event.keycode == expected_key):
			matched = true
	_assert(matched, "%s should be mapped to %s." % [action, OS.get_keycode_string(expected_key)])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
