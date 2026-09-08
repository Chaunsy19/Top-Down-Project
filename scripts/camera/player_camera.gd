extends Camera2D

@export_range(0.25, 4.0, 0.05) var default_zoom := 1.25
@export_range(0.25, 4.0, 0.05) var minimum_zoom := 0.75
@export_range(0.25, 4.0, 0.05) var maximum_zoom := 2.0
@export_range(0.05, 1.0, 0.05) var zoom_step := 0.15


func _ready() -> void:
	set_zoom_level(default_zoom)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		set_zoom_level(zoom.x + zoom_step)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_zoom_out"):
		set_zoom_level(zoom.x - zoom_step)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_reset"):
		set_zoom_level(default_zoom)
		get_viewport().set_input_as_handled()


func set_zoom_level(value: float) -> void:
	var clamped_value := clampf(value, minimum_zoom, maximum_zoom)
	zoom = Vector2.ONE * clamped_value

