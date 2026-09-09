extends SceneTree

const GridWorldScript = preload("res://scripts/world/grid_world.gd")
const InteractableScript = preload("res://scripts/interaction/interactable.gd")
const PlayerInteractorScript = preload("res://scripts/interaction/player_interactor.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var packed_main := load("res://scenes/main.tscn") as PackedScene
	if packed_main == null:
		finish_with_failure("Main scene could not be loaded.")
		return

	var main := packed_main.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var world := main.get_node_or_null("FoundationTest") as GridWorldScript
	if world == null:
		finish_with_failure("GridWorld was not found in the main scene.")
		return
	var player := world.get_node_or_null("Player") as CharacterBody2D
	var terminal := world.get_node_or_null("TestTerminal") as InteractableScript
	var interactor := world.get_node_or_null("Player/InteractionRange") as PlayerInteractorScript
	if player == null or terminal == null or interactor == null:
		finish_with_failure("Required Milestone 2 nodes were not found.")
		return
	if get_first_node_in_group("grid_world") != world:
		_failures.append("GridWorld was not discoverable through its runtime group.")
	if get_first_node_in_group("player") != player:
		_failures.append("Player was not discoverable through its runtime group.")

	test_coordinate_conversion(world)
	test_walkability(world)
	test_interaction_reach_symmetry(player, terminal, interactor)
	test_interaction(player, terminal, interactor)

	main.queue_free()
	await process_frame
	finish()


func test_coordinate_conversion(world: GridWorldScript) -> void:
	var expected_cell := Vector2i(7, 6)
	var world_position := world.to_global(world.cell_to_world(expected_cell))
	if world.world_to_cell(world_position) != expected_cell:
		_failures.append("Grid world/cell coordinate conversion did not round-trip.")


func test_walkability(world: GridWorldScript) -> void:
	if world.is_cell_walkable(Vector2i(0, 0)):
		_failures.append("Boundary cell should be blocked.")
	if not world.is_cell_walkable(Vector2i(5, 5)):
		_failures.append("Open interior cell should be walkable.")
	if world.is_cell_walkable(Vector2i(12, 8)):
		_failures.append("The test terminal's occupied cell should be blocked.")
	if world.is_cell_walkable(Vector2i(-1, 4)):
		_failures.append("Out-of-bounds cells should not be walkable.")


func test_interaction(
	player: CharacterBody2D,
	terminal: InteractableScript,
	interactor: PlayerInteractorScript
) -> void:
	interactor.refresh_target()
	if interactor.get_current_target() != terminal:
		_failures.append("Nearby test terminal was not selected as the interaction target.")
		return
	if not terminal.can_interact(player):
		_failures.append("Available test terminal rejected a valid actor.")
		return
	if not interactor.try_interact():
		_failures.append("Player interaction attempt did not succeed.")
		return
	if terminal.get_debug_state() != "Active (uses: 1)":
		_failures.append("Test terminal did not update its interaction state.")


func test_interaction_reach_symmetry(
	player: CharacterBody2D,
	terminal: InteractableScript,
	interactor: PlayerInteractorScript
) -> void:
	var directions := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for direction in directions:
		player.global_position = terminal.global_position + direction * 52.0
		if not interactor.is_target_in_range(terminal):
			_failures.append("Terminal was unreachable from direction %s at equal distance." % direction)

	player.global_position = terminal.global_position + Vector2.RIGHT * 60.0
	if interactor.is_target_in_range(terminal):
		_failures.append("Terminal remained reachable beyond the configured interaction radius.")

	player.position = Vector2(448.0, 256.0)
	player.velocity = Vector2.ZERO


func finish_with_failure(message: String) -> void:
	_failures.append(message)
	finish()


func finish() -> void:
	if _failures.is_empty():
		print("MILESTONE 2 TEST PASSED: grid, walkability, targeting, and interaction are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
