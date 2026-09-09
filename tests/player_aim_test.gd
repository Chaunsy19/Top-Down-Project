extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var packed_main := load("res://scenes/main.tscn") as PackedScene
	var main := packed_main.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var player := main.get_node("FoundationTest/Player") as PlayerController
	var aim_pivot := player.get_node("AimPivot") as Node2D
	var tool_socket := player.get_tool_socket()

	player.update_aim_from_world_position(player.global_position + Vector2.RIGHT * 100.0)
	_assert(player.get_aim_direction().is_equal_approx(Vector2.RIGHT), "The player should face a mouse target to the right.")
	_assert(is_equal_approx(aim_pivot.rotation, 0.0), "The aim pivot should rotate toward the aim direction.")
	_assert(tool_socket.global_position.x > player.global_position.x, "The tool socket should sit in front of the player.")

	player.update_aim_from_world_position(player.global_position + Vector2(-60.0, -80.0))
	var expected_direction := Vector2(-0.6, -0.8)
	_assert(player.get_aim_direction().is_equal_approx(expected_direction), "Diagonal mouse aiming should be normalized in world space.")
	_assert(is_equal_approx(player.get_aim_angle(), expected_direction.angle()), "The exposed aim angle should match the direction.")

	var direction_before_deadzone := player.get_aim_direction()
	player.update_aim_from_world_position(player.global_position + Vector2.ONE)
	_assert(player.get_aim_direction().is_equal_approx(direction_before_deadzone), "Targets inside the aim deadzone should preserve facing.")

	player.velocity = Vector2.DOWN * player.movement_speed
	player.update_aim_from_world_position(player.global_position + Vector2.LEFT * 100.0)
	_assert(player.get_aim_direction().is_equal_approx(Vector2.LEFT), "Movement direction must not override mouse aim.")

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("PLAYER AIM TEST PASSED: mouse direction, pivot, tool socket, deadzone, and movement independence are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
