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


func _initialize() -> void:
	var failures: Array[String] = []

	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			failures.append("Missing input action: %s" % action)

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
		print("SMOKE TEST PASSED: foundation scene and input actions are valid.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

