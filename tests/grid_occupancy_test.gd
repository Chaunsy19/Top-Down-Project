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

	var world := main.get_node("FoundationTest")
	var rock := world.get_node("Rock")
	var rock_east := world.get_node("RockEast")
	var rock_south := world.get_node("RockSouth")

	_assert(rock.global_position == world.to_global(world.cell_to_world(rock.get_occupied_cell())), "Blocking objects should snap to cell centers.")
	_assert(world.get_cell_occupant(rock.get_occupied_cell()) == rock, "The grid should identify the object occupying a cell.")
	_assert(rock.get_connection_mask() == 6, "The corner stone should connect east and south; got %d." % rock.get_connection_mask())
	_assert(rock_east.get_connection_mask() == 8, "The east stone should connect west; got %d." % rock_east.get_connection_mask())
	_assert(rock_south.get_connection_mask() == 1, "The south stone should connect north; got %d." % rock_south.get_connection_mask())
	_assert(rock.get_node("NameLabel").visible, "A connected stone mass should keep one cluster label.")
	_assert(not rock_east.get_node("NameLabel").visible, "Connected stone tiles should suppress duplicate labels.")

	var duplicate := Node2D.new()
	world.add_child(duplicate)
	_assert(not world.try_register_cell_occupant(rock.get_occupied_cell(), duplicate), "A second blocking object must not claim an occupied cell.")
	_assert(not world.try_register_cell_occupant(Vector2i.ZERO, duplicate), "Placed objects must not claim blocked terrain or boundary cells.")
	duplicate.queue_free()

	var mined_cell: Vector2i = rock.get_occupied_cell()
	rock.remaining_harvests = 0
	rock._begin_depletion()
	await process_frame
	_assert(world.get_cell_occupant(mined_cell) == null, "Mining out stone should release its occupied cell.")
	_assert(world.is_cell_walkable(mined_cell), "A mined-out stone cell should become walkable.")
	_assert(rock_east.get_connection_mask() == 0, "Neighbor connections should refresh when stone is removed; got %d." % rock_east.get_connection_mask())

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("GRID OCCUPANCY TEST PASSED: snapping, ownership, exclusivity, and stone connections are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
