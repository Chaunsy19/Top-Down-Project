class_name PlayerController
extends CharacterBody2D

@export_range(1.0, 1000.0, 1.0) var movement_speed := 220.0
@export_range(1.0, 5000.0, 1.0) var acceleration := 1600.0
@export_range(1.0, 5000.0, 1.0) var deceleration := 2000.0

@onready var survival_needs: SurvivalNeeds = get_node_or_null("Needs") as SurvivalNeeds


func _ready() -> void:
	add_to_group("player")


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
	if event.is_action_pressed("rest") and survival_needs != null and not get_tree().paused:
		survival_needs.toggle_resting()
		get_viewport().set_input_as_handled()
