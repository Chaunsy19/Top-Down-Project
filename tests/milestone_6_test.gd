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
	var clock := world.get_node("WorldClock")
	var ambient := world.get_node("AmbientModulate") as CanvasModulate
	var player := world.get_node("Player")
	var needs := player.get_node("Needs")
	var inventory := player.get_node("Inventory")
	var campfire := world.find_child("Campfire", true, false)
	var campfire_light := campfire.get_node_or_null("SoftLight") as PointLight2D if campfire else null

	_test_clock_and_ambient(clock, ambient)
	_test_needs_and_eating(needs, inventory)
	_test_soft_light(campfire_light)

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("MILESTONE 6 TEST PASSED: real-time clock, smooth darkness, soft light, hunger, rest, health, and eating are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_clock_and_ambient(clock: Node, ambient: CanvasModulate) -> void:
	_assert(is_equal_approx(clock.day_length_real_seconds, 1200.0), "A full day should default to twenty real-time minutes.")
	var night_color: Color = clock.get_ambient_color_at(2.0)
	var dawn_color: Color = clock.get_ambient_color_at(6.0)
	var day_color: Color = clock.get_ambient_color_at(12.0)
	_assert(night_color.get_luminance() < 0.08, "Night ambient light should be nearly black without a light source.")
	_assert(night_color.get_luminance() < dawn_color.get_luminance(), "Dawn should smoothly brighten from night.")
	_assert(dawn_color.get_luminance() < day_color.get_luminance(), "Dawn should remain dimmer than daylight.")
	clock.set_time_of_day(2.0)
	_assert(ambient.color.is_equal_approx(night_color), "The world CanvasModulate should follow the clock.")
	var before_minutes: float = clock.total_game_minutes
	clock.advance_real_seconds(10.0)
	_assert(is_equal_approx(clock.total_game_minutes - before_minutes, 12.0), "Clock progression should use one consistent real-time rate.")


func _test_needs_and_eating(needs: Node, inventory: Node) -> void:
	needs.hunger = 60.0
	needs.fatigue = 60.0
	needs.body_health.blood = 100.0
	needs.advance_game_minutes(60.0)
	_assert(is_equal_approx(needs.hunger, 56.0), "Hunger should decline with game time.")
	_assert(is_equal_approx(needs.fatigue, 56.75), "Fatigue should decline while awake.")

	needs.set_resting(true)
	needs.advance_game_minutes(60.0)
	_assert(needs.fatigue > 70.0, "Resting should restore fatigue.")
	_assert(is_zero_approx(needs.get_movement_multiplier()), "A resting player should remain still.")
	needs.set_resting(false)

	var meal: Resource = root.get_node("ContentRegistry").get_item(&"cooked_berry_meal")
	inventory.add_item(meal, 1)
	var meal_slot: int = inventory.find_first_item(&"cooked_berry_meal")
	var hunger_before_eating: float = needs.hunger
	_assert(needs.consume_item(inventory, meal_slot), "A nutritious inventory item should be edible.")
	_assert(needs.hunger > hunger_before_eating, "Eating should restore hunger.")
	_assert(inventory.get_item_quantity(&"cooked_berry_meal") == 0, "Eating should consume one item.")

	needs.hunger = 0.0
	needs.fatigue = 0.0
	needs.body_health.blood = 100.0
	needs.advance_game_minutes(60.0)
	_assert(needs.body_health.blood == 100.0, "Hunger and fatigue should not consume blood.")
	_assert(needs.get_movement_multiplier() < 0.5, "Critical needs should substantially slow movement.")


func _test_soft_light(campfire_light: PointLight2D) -> void:
	_assert(campfire_light != null and campfire_light.enabled, "The campfire should emit light from data.")
	_assert(campfire_light.texture is GradientTexture2D, "The campfire should use a smooth radial gradient texture.")
	_assert(not campfire_light.shadow_enabled, "The initial light should avoid hard-edged shadows.")
	_assert(campfire_light.texture_scale > 1.0, "The campfire light should cover several world tiles.")
	var gradient_texture := campfire_light.texture as GradientTexture2D
	_assert(gradient_texture.gradient.colors[-1].a == 0.0, "The light edge should feather completely to transparent.")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
