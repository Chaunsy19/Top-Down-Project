extends SceneTree

const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")
const InventoryComponentScript = preload("res://scripts/inventory/inventory_component.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var registry := root.get_node_or_null("ContentRegistry")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var world := main.get_node("FoundationTest")
	var player := world.get_node("Player") as CharacterBody2D
	var inventory := player.get_node("Inventory") as InventoryComponentScript
	var equipment := player.get_node("Equipment")
	var tree := world.find_child("Tree", true, false) as ResourceNodeScript
	var rock := world.find_child("Rock", true, false) as ResourceNodeScript
	var bush := world.find_child("BerryBush", true, false) as ResourceNodeScript

	if tree.has_required_tool(player):
		_failures.append("Tree was harvestable without an axe.")
	if rock.has_required_tool(player):
		_failures.append("Rock was harvestable without a pickaxe.")
	if not bush.has_required_tool(player) or not bush.can_interact(player):
		_failures.append("Berry bush incorrectly requires a tool.")

	var axe: Resource = registry.get_item(&"stone_axe")
	var pickaxe: Resource = registry.get_item(&"stone_pickaxe")
	var axe_tags: Array[StringName] = [&"axe"]
	var pickaxe_tags: Array[StringName] = [&"pickaxe"]
	if axe.tool_profile == null or not axe.tool_profile.satisfies(axe_tags, 1):
		_failures.append("Stone axe is missing its axe capability profile.")
	if pickaxe.tool_profile == null or not pickaxe.tool_profile.satisfies(pickaxe_tags, 1):
		_failures.append("Stone pickaxe is missing its pickaxe capability profile.")
	if axe.tool_profile.maximum_durability <= 0 or pickaxe.tool_profile.maximum_durability <= 0:
		_failures.append("Tier-one tools are missing future durability capacity.")
	if axe.tool_damage != 30.0 or axe.tool_damage_tags != Array([&"wood"]):
		_failures.append("Stone axe should export 30 wood-only tool damage.")
	if pickaxe.tool_damage != 60.0 or pickaxe.tool_damage_tags != Array([&"stone"]):
		_failures.append("Stone pickaxe should export 60 stone-only tool damage.")
	if axe.melee_damage <= 0.0 or pickaxe.melee_damage <= 0.0:
		_failures.append("Every tool should export independent melee damage.")
	if tree.definition.maximum_health != 150.0 or rock.definition.maximum_health != 300.0:
		_failures.append("Tree and stone health are not set to their initial 150/300 values.")

	inventory.add_item(axe, 1)
	if tree.has_required_tool(player):
		_failures.append("A carried but unequipped axe satisfied the tree requirement.")
	equipment.equip_from_inventory(inventory, inventory.find_first_item(&"stone_axe"))
	if not tree.has_required_tool(player) or not tree.can_interact(player):
		_failures.append("An equipped axe did not satisfy the tree requirement.")
	if rock.has_required_tool(player):
		_failures.append("An axe incorrectly satisfied the rock's pickaxe requirement.")
	inventory.add_item(pickaxe, 1)
	equipment.equip_from_inventory(inventory, inventory.find_first_item(&"stone_pickaxe"))
	if not rock.has_required_tool(player) or not rock.can_interact(player):
		_failures.append("An equipped pickaxe did not satisfy the rock requirement.")

	if tree.definition.required_tool_tags != axe_tags:
		_failures.append("Tree data does not explicitly require the axe tag.")
	if rock.definition.required_tool_tags != pickaxe_tags:
		_failures.append("Rock data does not explicitly require the pickaxe tag.")
	if not bush.definition.required_tool_tags.is_empty():
		_failures.append("Berry bush data should have no required tool tags.")

	var loose_sticks := world.find_child("LooseSticks", true, false)
	var loose_stones := world.find_child("LooseStones", true, false)
	if loose_sticks.item_stack.item_definition.item_id != &"stick":
		_failures.append("Loose starter sticks are missing from the world.")
	if loose_stones.item_stack.item_definition.item_id != &"stone":
		_failures.append("Loose starter stones are missing from the world.")

	main.queue_free()
	await process_frame
	finish()


func finish() -> void:
	if _failures.is_empty():
		print("TOOL REQUIREMENT TEST PASSED: capability tags, tiers, node requirements, and loose starter resources are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
