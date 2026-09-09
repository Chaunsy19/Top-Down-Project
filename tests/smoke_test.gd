extends SceneTree

const REQUIRED_ACTIONS := [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"interact",
	"inventory",
	"crafting",
	"rest",
	"building",
	"attack",
	"hotbar_slot_1",
	"hotbar_slot_2",
	"hotbar_slot_3",
	"hotbar_slot_4",
	"hotbar_slot_5",
	"hotbar_slot_6",
	"hotbar_slot_7",
	"hotbar_slot_8",
	"hotbar_slot_9",
	"pause",
	"camera_zoom_in",
	"camera_zoom_out",
	"camera_reset",
	"debug_toggle",
	"debug_cycle_time",
	"ui_cancel",
]
const REQUIRED_SCRIPTS := [
	"res://scripts/core/game_state.gd",
	"res://scripts/main.gd",
	"res://scripts/player/player_controller.gd",
	"res://scripts/interaction/interactable.gd",
	"res://scripts/interaction/player_interactor.gd",
	"res://scripts/world/grid_world.gd",
	"res://scripts/world/terrain_map.gd",
	"res://scripts/world/test_terminal.gd",
	"res://scripts/debug/debug_overlay.gd",
	"res://scripts/data/content_registry.gd",
	"res://scripts/data/items/item_definition.gd",
	"res://scripts/data/items/item_catalog.gd",
	"res://scripts/data/items/item_stack.gd",
	"res://scripts/data/items/tool_profile.gd",
	"res://scripts/data/recipes/recipe_ingredient.gd",
	"res://scripts/data/recipes/recipe_definition.gd",
	"res://scripts/data/recipes/recipe_catalog.gd",
	"res://scripts/data/resource_nodes/resource_node_definition.gd",
	"res://scripts/data/workstations/workstation_definition.gd",
	"res://scripts/data/workstations/workstation_catalog.gd",
	"res://scripts/player/skill_tracker.gd",
	"res://scripts/player/survival_needs.gd",
	"res://scripts/world/resource_node.gd",
	"res://scripts/world/world_item_drop.gd",
	"res://scripts/inventory/inventory_component.gd",
	"res://scripts/inventory/inventory_slot_ui.gd",
	"res://scripts/inventory/inventory_panel.gd",
	"res://scripts/inventory/inventory_ui.gd",
	"res://scripts/equipment/equipment_component.gd",
	"res://scripts/equipment/hotbar_component.gd",
	"res://scripts/crafting/crafting_component.gd",
	"res://scripts/crafting/crafting_ui.gd",
	"res://scripts/world/inventory_container.gd",
	"res://scripts/world/crafting_workstation.gd",
	"res://scripts/world/world_clock.gd",
	"res://scripts/world/soft_light.gd",
	"res://scripts/world/looping_sprite_animation.gd",
	"res://scripts/ui/survival_hud.gd",
	"res://scripts/ui/ui_manager.gd",
	"res://scripts/ui/hotbar_slot.gd",
	"res://scripts/ui/hotbar_ui.gd",
]


func _initialize() -> void:
	var failures: Array[String] = []

	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			failures.append("Missing input action: %s" % action)

	for script_path in REQUIRED_SCRIPTS:
		var script := load(script_path) as GDScript
		if script == null or not script.can_instantiate():
			failures.append("Script could not be parsed: %s" % script_path)

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		failures.append("Main scene could not be loaded.")
	else:
		var instance := main_scene.instantiate()
		if instance == null:
			failures.append("Main scene could not be instantiated.")
		else:
			instance.free()

	if failures.is_empty():
		print("SMOKE TEST PASSED: required scripts, main scene, and input actions are valid.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
