extends SceneTree

const GridWorldScript = preload("res://scripts/world/grid_world.gd")
const PlayerInteractorScript = preload("res://scripts/interaction/player_interactor.gd")
const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")
const SkillTrackerScript = preload("res://scripts/player/skill_tracker.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	test_content_catalogs()

	var packed_main := load("res://scenes/main.tscn") as PackedScene
	if packed_main == null:
		finish_with_failure("Main scene could not be loaded.")
		return
	var main := packed_main.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var world := main.get_node_or_null("FoundationTest") as GridWorldScript
	var player := world.get_node_or_null("Player") as CharacterBody2D if world else null
	var interactor := world.get_node_or_null("Player/InteractionRange") as PlayerInteractorScript if world else null
	var skills := world.get_node_or_null("Player/Skills") as SkillTrackerScript if world else null
	var inventory := world.get_node_or_null("Player/Inventory") if world else null
	var equipment := world.get_node_or_null("Player/Equipment") if world else null
	var tree := world.find_child("Tree", true, false) as ResourceNodeScript if world else null
	var rock := world.find_child("Rock", true, false) as ResourceNodeScript if world else null
	var bush := world.find_child("BerryBush", true, false) as ResourceNodeScript if world else null
	if world == null or player == null or interactor == null or skills == null or inventory == null or equipment == null or tree == null or rock == null or bush == null:
		finish_with_failure("Milestone 3 world nodes are incomplete.")
		return
	var registry := root.get_node("ContentRegistry")
	inventory.add_item(registry.get_item(&"stone_axe"), 1)
	inventory.add_item(registry.get_item(&"stone_pickaxe"), 1)

	equipment.equip_from_inventory(inventory, inventory.find_first_item(&"stone_pickaxe"))
	test_skill_requirement(player, skills, rock)
	equipment.equip_from_inventory(inventory, inventory.find_first_item(&"stone_axe"))
	await test_timed_harvest(player, skills, interactor, tree)
	test_regrowth(player, bush)

	main.queue_free()
	await process_frame
	finish()


func test_content_catalogs() -> void:
	var registry := root.get_node_or_null("ContentRegistry")
	if registry == null:
		_failures.append("ContentRegistry autoload was not available.")
		return
	var catalog_errors: PackedStringArray = registry.validate_catalogs()
	for catalog_error in catalog_errors:
		_failures.append("Catalog validation: %s" % catalog_error)
	for item_id in [&"wood", &"stone", &"berries"]:
		if registry.get_item(item_id) == null:
			_failures.append("Item catalog is missing '%s'." % item_id)
	for node_id in [&"tree", &"rock", &"berry_bush"]:
		if registry.get_resource_node(node_id) == null:
			_failures.append("Resource-node catalog is missing '%s'." % node_id)
	if registry.get_items_in_category(&"material").size() != 3:
		_failures.append("Material category query should return wood, stone, and sticks.")
	if registry.get_items_in_category(&"food").size() != 2:
		_failures.append("Food category query should return berries and the cooked meal.")


func test_skill_requirement(
	player: CharacterBody2D,
	skills: SkillTrackerScript,
	rock: ResourceNodeScript
) -> void:
	skills.set_skill_level(&"mining", 0)
	if rock.can_interact(player):
		_failures.append("Rock ignored its required mining level.")
	skills.set_skill_level(&"mining", 1)
	if not rock.can_interact(player):
		_failures.append("Rock rejected an actor meeting its mining requirement.")


func test_timed_harvest(
	player: CharacterBody2D,
	skills: SkillTrackerScript,
	interactor: PlayerInteractorScript,
	tree: ResourceNodeScript
) -> void:
	player.global_position = tree.global_position + Vector2.RIGHT * 48.0
	player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	interactor.refresh_target()
	if interactor.get_current_target() != tree:
		_failures.append("Tree was not selected in interaction range.")
		return
	var initial_health: float = tree.health.current_health
	if not interactor.try_interact():
		_failures.append("Tree harvesting could not be started.")
		return
	if not tree.is_harvesting():
		_failures.append("Tree did not enter its timed harvesting state.")
		return
	var effective_harvest_time := tree.get_effective_harvest_time(player)
	tree.advance_simulation(effective_harvest_time * 0.5)
	if tree.health.current_health != initial_health or not tree.is_harvesting():
		_failures.append("Tree harvest completed before its configured duration.")
		return
	tree.advance_simulation(effective_harvest_time * 0.5 + 0.01)
	if tree.health.current_health != initial_health - 30.0:
		_failures.append("A stone axe work strike did not apply its configured 30 tool damage.")
	while not tree.is_depleted():
		if not tree.interact(player):
			_failures.append("Tree could not continue health-based harvesting.")
			return
		tree.advance_simulation(tree.get_effective_harvest_time(player) + 0.01)
	if skills.get_experience(&"forestry") != tree.definition.experience_reward:
		_failures.append("Tree did not award configured forestry experience on depletion.")
	var wood_drops := get_nodes_in_group("world_item_drop").filter(
		func(drop: Node) -> bool:
			return drop.item_stack.item_definition.item_id == &"wood"
	)
	if wood_drops.is_empty():
		_failures.append("Tree harvest did not create a typed wood world drop.")


func test_regrowth(player: CharacterBody2D, bush: ResourceNodeScript) -> void:
	player.global_position = bush.global_position + Vector2.RIGHT * 48.0
	while not bush.is_depleted():
		if not bush.interact(player):
			_failures.append("Berry bush could not continue hand harvesting.")
			return
		bush.advance_simulation(bush.definition.harvest_time_seconds + 0.01)
	if not bush.is_depleted():
		_failures.append("Berry bush did not deplete after its configured harvest count.")
		return
	bush.advance_simulation(bush.definition.recovery_time_seconds + 0.01)
	if bush.is_depleted() or bush.health.current_health != bush.definition.maximum_health:
		_failures.append("Berry bush did not regrow according to its data definition.")


func finish_with_failure(message: String) -> void:
	_failures.append(message)
	finish()


func finish() -> void:
	if _failures.is_empty():
		print("MILESTONE 3 TEST PASSED: catalogs, skills, health-based harvesting, drops, depletion, and regrowth are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
