extends SceneTree

const REQUIRED_ACTIONS := [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"interact",
	"inventory",
	"crafting",
	"building",
	"attack",
	"pause",
	"camera_zoom_in",
	"camera_zoom_out",
	"camera_reset",
	"debug_toggle",
]
const REQUIRED_SCRIPTS := [
	"res://scripts/core/game_state.gd",
	"res://scripts/main.gd",
	"res://scripts/player/player_controller.gd",
	"res://scripts/interaction/interactable.gd",
	"res://scripts/interaction/player_interactor.gd",
	"res://scripts/world/grid_world.gd",
	"res://scripts/world/test_terminal.gd",
	"res://scripts/debug/debug_overlay.gd",
	"res://scripts/data/content_registry.gd",
	"res://scripts/data/items/item_definition.gd",
	"res://scripts/data/items/item_catalog.gd",
	"res://scripts/data/items/item_stack.gd",
	"res://scripts/data/resource_nodes/resource_node_definition.gd",
	"res://scripts/player/skill_tracker.gd",
	"res://scripts/world/resource_node.gd",
	"res://scripts/world/world_item_drop.gd",
	"res://scripts/inventory/inventory_component.gd",
	"res://scripts/inventory/inventory_slot_ui.gd",
	"res://scripts/inventory/inventory_panel.gd",
	"res://scripts/inventory/inventory_ui.gd",
	"res://scripts/world/inventory_container.gd",
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
