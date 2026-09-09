class_name PlayerController
extends CharacterBody2D

signal aim_direction_changed(direction: Vector2)
signal combat_mode_changed(is_combat_ready: bool)
signal attack_requested(direction: Vector2)

@export_range(1.0, 1000.0, 1.0) var movement_speed := 220.0
@export_range(1.0, 5000.0, 1.0) var acceleration := 1600.0
@export_range(1.0, 5000.0, 1.0) var deceleration := 2000.0
@export_range(0.0, 64.0, 0.5) var aim_deadzone := 4.0

@onready var survival_needs: SurvivalNeeds = get_node_or_null("Needs") as SurvivalNeeds
@onready var aim_pivot: Node2D = %AimPivot
@onready var equipment: EquipmentComponent = get_node_or_null("Equipment") as EquipmentComponent
@onready var hotbar: HotbarComponent = get_node_or_null("Hotbar") as HotbarComponent
@onready var interactor: PlayerInteractor = get_node_or_null("InteractionRange") as PlayerInteractor

var aim_direction := Vector2.DOWN
var is_combat_ready := false


func _ready() -> void:
	add_to_group("player")
	if hotbar != null:
		hotbar.selected_slot_changed.connect(_on_hotbar_selection_changed)
	if equipment != null:
		equipment.changed.connect(_sync_combat_readiness)
	_sync_combat_readiness()
	_update_aim_pivot()


func _process(_delta: float) -> void:
	update_aim_from_world_position(get_global_mouse_position())


func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	var movement_multiplier := survival_needs.get_movement_multiplier() if survival_needs != null else 1.0
	var target_velocity := input_direction * movement_speed * movement_multiplier
	var velocity_change := acceleration if not input_direction.is_zero_approx() else deceleration

	velocity = velocity.move_toward(target_velocity, velocity_change * delta)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rest") and survival_needs != null and not get_tree().paused and not is_combat_ready:
		survival_needs.toggle_resting()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack") and is_combat_ready and not get_tree().paused:
		if interactor == null or not interactor.begin_primary_action_at(get_global_mouse_position()):
			attack_requested.emit(aim_direction)
		get_viewport().set_input_as_handled()


func set_combat_ready(value: bool) -> void:
	if is_combat_ready == value:
		return
	is_combat_ready = value
	if is_combat_ready and survival_needs != null and survival_needs.is_resting:
		survival_needs.set_resting(false)
	combat_mode_changed.emit(is_combat_ready)


func are_weapons_holstered() -> bool:
	return not is_combat_ready


func _on_hotbar_selection_changed(_slot_index: int, _item_id: StringName) -> void:
	_sync_combat_readiness()


func _sync_combat_readiness() -> void:
	var hand_stack := equipment.get_hand_stack() if equipment != null else null
	var definition: Resource = hand_stack.item_definition if hand_stack != null else null
	var selected_from_hotbar := hotbar != null and hotbar.selected_slot >= 0
	set_combat_ready(selected_from_hotbar and definition != null and definition.has_category(&"weapon"))


func update_aim_from_world_position(target_world_position: Vector2) -> void:
	var aim_delta := target_world_position - global_position
	if aim_delta.length_squared() <= aim_deadzone * aim_deadzone:
		return
	var next_direction := aim_delta.normalized()
	if next_direction.is_equal_approx(aim_direction):
		return
	aim_direction = next_direction
	_update_aim_pivot()
	aim_direction_changed.emit(aim_direction)


func get_aim_direction() -> Vector2:
	return aim_direction


func get_aim_angle() -> float:
	return aim_direction.angle()


func get_aim_origin() -> Vector2:
	return global_position


func get_tool_socket() -> Marker2D:
	return %ToolSocket as Marker2D


func _update_aim_pivot() -> void:
	if is_instance_valid(aim_pivot):
		aim_pivot.rotation = get_aim_angle()
