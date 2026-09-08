extends CanvasLayer

@onready var panel: PanelContainer = %Panel
@onready var readout: Label = %Readout


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	readout.text = "State: %s\nFPS: %d\nScene: %s" % [
		GameState.get_state_name(),
		Engine.get_frames_per_second(),
		get_tree().current_scene.name if get_tree().current_scene else "None",
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()

