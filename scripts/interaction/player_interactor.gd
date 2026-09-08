class_name PlayerInteractor
extends Area2D

const InteractableScript = preload("res://scripts/interaction/interactable.gd")

signal target_changed(target: InteractableScript)
signal interaction_attempted(target: InteractableScript, succeeded: bool)

@export_range(1.0, 256.0, 1.0) var radius := 56.0
@export var prompt_label_path: NodePath

var _current_target: InteractableScript
var _prompt_label: Label


func _ready() -> void:
	add_to_group("player_interactor")
	_prompt_label = get_node_or_null(prompt_label_path) as Label
	queue_redraw()
	_update_prompt()


func _physics_process(_delta: float) -> void:
	refresh_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		try_interact()
		get_viewport().set_input_as_handled()


func refresh_target() -> void:
	var nearest_target: InteractableScript
	var nearest_distance := INF
	for area in get_overlapping_areas():
		if area is not InteractableScript:
			continue
		var candidate := area as InteractableScript
		if not is_target_in_range(candidate):
			continue
		var distance := global_position.distance_squared_to(candidate.get_interaction_point())
		if distance < nearest_distance:
			nearest_target = candidate
			nearest_distance = distance

	set_current_target(nearest_target)
	_update_prompt()


func try_interact() -> bool:
	refresh_target()
	var succeeded := false
	if is_target_in_range(_current_target):
		succeeded = _current_target.interact(get_parent() as Node2D)
	interaction_attempted.emit(_current_target, succeeded)
	_update_prompt()
	return succeeded


func get_current_target() -> InteractableScript:
	return _current_target


func is_target_in_range(target: InteractableScript) -> bool:
	return (
		is_instance_valid(target)
		and global_position.distance_to(target.get_interaction_point()) <= radius
	)


func set_current_target(target: InteractableScript) -> void:
	if target == _current_target:
		return
	_current_target = target
	target_changed.emit(_current_target)
	_update_prompt()


func _update_prompt() -> void:
	if not is_instance_valid(_prompt_label):
		return
	_prompt_label.visible = is_instance_valid(_current_target)
	if is_instance_valid(_current_target):
		_prompt_label.text = "[E] %s" % _current_target.get_prompt_text()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.902, 0.765, 0.416, 0.035))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.902, 0.765, 0.416, 0.42), 1.5, true)
