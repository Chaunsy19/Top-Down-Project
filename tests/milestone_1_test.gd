extends SceneTree

const START_POSITION := Vector2(448.0, 248.0)
const MOVEMENT_FRAMES := 30
const COLLISION_FRAMES := 90

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var test_scene := load("res://scenes/test/foundation_test.tscn") as PackedScene
	if test_scene == null:
		finish_with_failure("Foundation test scene could not be loaded.")
		return

	var world := test_scene.instantiate()
	root.add_child(world)
	var player := world.get_node_or_null("Player") as CharacterBody2D
	if player == null:
		finish_with_failure("Player was not found in the foundation test scene.")
		return

	await physics_frame
	await test_cardinal_movement(player)
	await test_diagonal_normalization(player)
	await test_wall_collision(player)
	world.queue_free()
	await process_frame
	finish()


func test_cardinal_movement(player: CharacterBody2D) -> void:
	reset_player(player)
	Input.action_press("move_right")
	await wait_physics_frames(MOVEMENT_FRAMES)
	Input.action_release("move_right")

	if player.position.x <= START_POSITION.x + 20.0:
		_failures.append("Player did not move right in response to input.")
	if absf(player.position.y - START_POSITION.y) > 0.1:
		_failures.append("Cardinal movement drifted on the perpendicular axis.")


func test_diagonal_normalization(player: CharacterBody2D) -> void:
	reset_player(player)
	Input.action_press("move_right")
	await wait_physics_frames(MOVEMENT_FRAMES)
	Input.action_release("move_right")
	var cardinal_distance := player.position.distance_to(START_POSITION)

	reset_player(player)
	Input.action_press("move_right")
	Input.action_press("move_down")
	await wait_physics_frames(MOVEMENT_FRAMES)
	Input.action_release("move_right")
	Input.action_release("move_down")
	var diagonal_distance := player.position.distance_to(START_POSITION)

	if absf(cardinal_distance - diagonal_distance) > 1.0:
		_failures.append("Diagonal movement has a speed advantage.")


func test_wall_collision(player: CharacterBody2D) -> void:
	reset_player(player)
	player.position = Vector2(590.0, 136.0)
	Input.action_press("move_right")
	await wait_physics_frames(COLLISION_FRAMES)
	Input.action_release("move_right")

	var world := player.get_parent()
	var final_cell: Vector2i = world.world_to_cell(player.global_position)
	if final_cell.x <= 0 or final_cell.y <= 0 or final_cell.x >= world.grid_dimensions.x - 1 or final_cell.y >= world.grid_dimensions.y - 1:
		_failures.append("Player passed through the isometric room boundary.")


func reset_player(player: CharacterBody2D) -> void:
	player.position = START_POSITION
	player.velocity = Vector2.ZERO


func wait_physics_frames(frame_count: int) -> void:
	for frame in frame_count:
		await physics_frame


func finish_with_failure(message: String) -> void:
	_failures.append(message)
	finish()


func finish() -> void:
	Input.action_release("move_right")
	Input.action_release("move_down")

	if _failures.is_empty():
		print("MILESTONE 1 TEST PASSED: movement, normalization, and collision are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
