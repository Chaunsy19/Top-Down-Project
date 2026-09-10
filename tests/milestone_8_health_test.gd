extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
func run() -> void:
	var body := BodyHealth.new()
	check(body.apply_damage(&"unknown", 20.0) == 0.0, "Invalid region rejected")
	check(body.apply_damage(&"head", -1.0) == 0.0, "Negative damage rejected")
	body.apply_damage(&"left_leg", 75.0, 8.0)
	check(body.condition[&"right_leg"] == 100.0, "Damage remains regional")
	check(body.get_movement_multiplier() < body.get_action_multiplier(), "Leg injuries slow movement")
	body.advance_game_minutes(60.0)
	check(is_equal_approx(body.blood, 94.0), "Integrated bleeding loses six blood in first hour")
	check(is_equal_approx(body.get_bleeding_rate(), 4.0), "Wound clots over game time")
	body.advance_game_minutes(60.0)
	check(is_equal_approx(body.blood, 92.0) and body.get_bleeding_rate() == 0.0, "Clotting stops blood loss")
	body.advance_game_minutes(60.0, true)
	check(body.blood == 94.0 and body.condition[&"left_leg"] == 27.0, "Safe rest restores blood and tissue")
	body.free()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame
	var player: PlayerController = get_first_node_in_group("player")
	player.take_region_damage(&"left_arm", 80.0, 8.0)
	check(player.get_action_multiplier() < 1.0, "Arm injury affects actor action effectiveness")
	check(player.survival_needs.health == 100.0, "Overall health remains separate")
	var ui: CharacterUI = get_first_node_in_group("character_ui")
	ui.open_health()
	await process_frame
	check(ui._body_label.text.contains("Left Arm") and ui._body_label.text.contains("bleeding"), "Health panel exposes regional wounds")
	check(ui.health_panel.size.y + ui.health_panel.position.y <= 720.0, "Health panel fits viewport")
	var before: float = player.survival_needs.body_health.blood
	await create_timer(0.1).timeout
	check(player.survival_needs.body_health.blood == before, "Modal pause stops bleeding")
	ui.close_health()
	player.take_region_damage(&"head", 100.0)
	check(player.get_action_multiplier() == 0.0 and player.survival_needs.get_movement_multiplier() == 0.0, "Vital region depletion collapses actor")
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("MILESTONE 8 HEALTH TEST PASSED")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

