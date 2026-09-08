extends CanvasLayer

@onready var panel: PanelContainer = %Panel
@onready var readout: Label = %Readout


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var grid_world := get_tree().get_first_node_in_group("grid_world")
	var interactor := get_tree().get_first_node_in_group("player_interactor")
	var cell_text := "Unknown"
	var cell_state := "Unknown"
	var target_text := "None"

	if is_instance_valid(player) and is_instance_valid(grid_world):
		var player_cell: Vector2i = grid_world.world_to_cell(player.global_position)
		cell_text = str(player_cell)
		cell_state = grid_world.get_cell_debug_state(player_cell)
	if is_instance_valid(interactor) and is_instance_valid(interactor.get_current_target()):
		var target: Node = interactor.get_current_target()
		target_text = "%s — %s" % [target.display_name, target.get_debug_state()]

	readout.text = "State: %s\nFPS: %d\nScene: %s\nGrid cell: %s (%s)\nTarget: %s" % [
		GameState.get_state_name(),
		Engine.get_frames_per_second(),
		get_tree().current_scene.name if get_tree().current_scene else "None",
		cell_text,
		cell_state,
		target_text,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()
