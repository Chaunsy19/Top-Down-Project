extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var packed_main := load("res://scenes/main.tscn") as PackedScene
	var main := packed_main.instantiate()
	root.add_child(main)
	await physics_frame

	var campfire := main.get_node("FoundationTest/Campfire") as CraftingWorkstation
	var fire := campfire.get_node("FireAnimation") as LoopingSpriteAnimation
	var smoke := campfire.get_node("SmokeAnimation") as LoopingSpriteAnimation
	_assert(fire != null and fire.texture != null, "The campfire should have a fire sprite sheet.")
	_assert(smoke != null and smoke.texture != null, "The campfire should have a smoke sprite sheet.")
	_assert(fire.hframes == 8 and smoke.hframes == 8, "Both effects should expose all eight animation frames.")
	_assert(smoke.show_behind_parent, "Smoke should render behind the campfire base.")

	var fire_start_frame := fire.frame
	var smoke_start_frame := smoke.frame
	fire.advance_animation(0.2)
	smoke.advance_animation(0.2)
	_assert(fire.frame != fire_start_frame, "The fire animation should advance over time.")
	_assert(smoke.frame != smoke_start_frame, "The smoke animation should advance over time.")
	_assert(campfire.get_node("SoftLight") is SoftWorldLight, "The animated campfire should retain its soft light.")

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("CAMPFIRE ANIMATION TEST PASSED: fire, smoke, looping frames, layering, and soft light are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
