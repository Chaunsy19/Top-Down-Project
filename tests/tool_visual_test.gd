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
	player.set_process(false)
	var inventory := player.get_node("Inventory") as InventoryComponent
	var hotbar := player.hotbar
	var visual := player.get_node("AimPivot/CombatStanceVisual")
	for tool in [&"stone_axe", &"stone_pickaxe"]:
		var definition: Resource = root.get_node("ContentRegistry").get_item(tool)
		check(definition.icon is AtlasTexture, "Tool uses cropped supplied art")
		inventory.add_item(definition, 1)
		hotbar.assign_from_inventory(0, inventory.find_first_item(tool))
		hotbar.select_slot(0)
		check(visual.is_stance_visible(), "Equipped tool is visible")
		check(visual.position.length() < 12.0 and visual.rotation < -PI / 2.0, "Idle tool is tucked across the body")
		player.update_aim_from_world_position(player.global_position + Vector2.LEFT * 100)
		check(is_equal_approx(player.aim_pivot.rotation, PI), "Held tool follows aim around player")
		player.perform_melee_attack_at(player.global_position + Vector2.LEFT * 100)
		check(visual.is_attack_animating() and visual.rotation < 0.0, "Strike starts at windup angle")
		visual._process(0.192)
		check(absf(visual.rotation) < 0.3 and visual.position.x >= 15.0, "Chop extends outward toward mouse aim")
		visual._process(0.2)
		check(not visual.is_attack_animating() and is_equal_approx(visual.rotation, deg_to_rad(-105.0)) and visual.position.length() < 12.0, "Swing recovers to the tucked body pose")
		hotbar.select_slot(0)
		check(not visual.is_stance_visible(), "Holstering hides tool")
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("TOOL VISUAL TEST PASSED")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
