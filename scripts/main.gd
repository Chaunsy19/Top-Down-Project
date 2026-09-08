extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.set_state(GameState.State.FOUNDATION_TEST)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
		if inventory_ui != null and inventory_ui.is_open():
			return
		get_tree().paused = not get_tree().paused
		GameState.set_paused(get_tree().paused)
		get_viewport().set_input_as_handled()
