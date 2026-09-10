class_name DraggableWindowHandle
extends Control

@export_node_path("Control") var drag_target_path: NodePath
@export_range(0.0, 64.0, 1.0) var screen_margin := 8.0

var _drag_target: Control
var _dragging := false
var _pointer_offset := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	_drag_target = get_node_or_null(drag_target_path) as Control
	gui_input.connect(_on_gui_input)


func set_drag_target(target: Control) -> void:
	_drag_target = target


func begin_drag(pointer_global_position: Vector2) -> bool:
	if not is_instance_valid(_drag_target):
		return false
	_drag_target.move_to_front()
	_dragging = true
	_pointer_offset = pointer_global_position - _drag_target.global_position
	return true


func drag_to(pointer_global_position: Vector2) -> void:
	if not _dragging or not is_instance_valid(_drag_target):
		return
	_drag_target.global_position = pointer_global_position - _pointer_offset
	_clamp_to_parent()


func end_drag() -> void:
	_dragging = false


func is_dragging() -> bool:
	return _dragging


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			begin_drag(event.global_position)
		else:
			end_drag()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		drag_to(event.global_position)
		accept_event()


func _clamp_to_parent() -> void:
	var parent_control := _drag_target.get_parent_control()
	if parent_control == null:
		return
	var maximum := Vector2(
		maxf(screen_margin, parent_control.size.x - _drag_target.size.x - screen_margin),
		maxf(screen_margin, parent_control.size.y - _drag_target.size.y - screen_margin)
	)
	_drag_target.position = Vector2(
		clampf(_drag_target.position.x, screen_margin, maximum.x),
		clampf(_drag_target.position.y, screen_margin, maximum.y)
	)
