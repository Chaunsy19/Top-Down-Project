class_name PlayerInteractor
extends Area2D

const InteractableScript = preload("res://scripts/interaction/interactable.gd")

signal target_changed(target: InteractableScript)
signal interaction_attempted(target: InteractableScript, succeeded: bool)

@export_range(1.0, 256.0, 1.0) var radius := 56.0
@export var prompt_label_path: NodePath

var _current_target: InteractableScript
var _held_target: InteractableScript
var _primary_held := false
var _prompt_label: Label


func _ready() -> void:
	add_to_group("player_interactor")
	_prompt_label = get_node_or_null(prompt_label_path) as Label
	var player := get_parent() as PlayerController
	if player != null:
		player.combat_mode_changed.connect(_on_combat_mode_changed)
	queue_redraw()
	_update_prompt()


func _physics_process(_delta: float) -> void:
	refresh_target()


func _process(delta: float) -> void:
	if not _primary_held:
		return
	if not Input.is_action_pressed("attack") or not _can_use_utility_actions():
		end_primary_action()
		return
	continue_primary_action(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_use_utility_actions() or get_tree().paused:
		return
	if event.is_action_pressed("attack"):
		if begin_primary_action_at(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
	elif event.is_action_released("attack") and _primary_held:
		end_primary_action()
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


func begin_primary_action_at(world_position: Vector2) -> bool:
	var target := _find_target_at(world_position)
	return begin_primary_action_on(target)


func begin_primary_action_on(target: InteractableScript) -> bool:
	if not _can_use_utility_actions() or not is_target_in_range(target):
		return false
	set_current_target(target)
	var succeeded := target.interact(get_parent() as Node2D)
	interaction_attempted.emit(target, succeeded)
	if succeeded and target.uses_hold_interaction():
		_held_target = target
		_primary_held = true
	_update_prompt()
	return succeeded


func continue_primary_action(delta: float) -> bool:
	if not _primary_held or not is_instance_valid(_held_target):
		return false
	var actor := get_parent() as Node2D
	if not is_target_in_range(_held_target):
		end_primary_action()
		return false
	var still_active := _held_target.continue_hold_interaction(actor, delta)
	if not still_active:
		if _held_target.can_interact(actor):
			_held_target.interact(actor)
			still_active = _held_target.is_hold_interaction_active(actor)
		if not still_active:
			_primary_held = false
			_held_target = null
	_update_prompt()
	return still_active


func end_primary_action() -> void:
	if is_instance_valid(_held_target):
		_held_target.cancel_hold_interaction(get_parent() as Node2D)
	_primary_held = false
	_held_target = null
	_update_prompt()


func is_holding_primary_action() -> bool:
	return _primary_held


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


func _find_target_at(world_position: Vector2) -> InteractableScript:
	var pointed_target: InteractableScript
	var nearest_pointer_distance := INF
	for area in get_overlapping_areas():
		if area is not InteractableScript:
			continue
		var candidate := area as InteractableScript
		if not is_target_in_range(candidate) or not candidate.is_pointer_near(world_position):
			continue
		var pointer_distance := world_position.distance_squared_to(candidate.get_interaction_point())
		if pointer_distance < nearest_pointer_distance:
			pointed_target = candidate
			nearest_pointer_distance = pointer_distance
	return pointed_target


func _can_use_utility_actions() -> bool:
	var player := get_parent() as PlayerController
	return player == null or not player.is_combat_ready


func _on_combat_mode_changed(is_combat_ready: bool) -> void:
	if is_combat_ready:
		end_primary_action()
	_update_prompt()


func _update_prompt() -> void:
	if not is_instance_valid(_prompt_label):
		return
	_prompt_label.visible = is_instance_valid(_current_target)
	if is_instance_valid(_current_target):
		if not _can_use_utility_actions():
			_prompt_label.text = "[R] Holster to interact"
		elif _current_target.uses_hold_interaction():
			_prompt_label.text = "[Hold LMB] %s" % _current_target.get_prompt_text()
		else:
			_prompt_label.text = "[LMB] %s" % _current_target.get_prompt_text()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.902, 0.765, 0.416, 0.035))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.902, 0.765, 0.416, 0.42), 1.5, true)
