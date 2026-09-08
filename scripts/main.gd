extends Node


func _ready() -> void:
	GameState.set_state(GameState.State.FOUNDATION_TEST)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		GameState.set_paused(get_tree().paused)
		get_viewport().set_input_as_handled()

