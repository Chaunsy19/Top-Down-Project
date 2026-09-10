class_name PlayerController
extends CharacterBody2D

signal aim_direction_changed(direction: Vector2)
signal combat_mode_changed(is_combat_ready: bool)
signal attack_requested(direction: Vector2)

@export_range(1.0, 1000.0, 1.0) var movement_speed := 220.0
@export_range(1.0, 5000.0, 1.0) var acceleration := 1600.0
@export_range(1.0, 5000.0, 1.0) var deceleration := 2000.0
@export_range(0.0, 64.0, 0.5) var aim_deadzone := 4.0
@export_range(0.0, 1000.0, 0.5) var unarmed_melee_damage := 5.0

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
		perform_primary_action_at(get_global_mouse_position())
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
	set_combat_ready(selected_from_hotbar and definition != null and (definition.has_category(&"weapon") or definition.has_category(&"tool")))


func perform_primary_action_at(world_position: Vector2) -> bool:
	if interactor != null and interactor.begin_armed_primary_action_at(world_position):
		attack_requested.emit(aim_direction)
		return true
	return perform_melee_attack_at(world_position) != null


func perform_melee_attack_at(world_position: Vector2) -> Node2D:
	if get_action_multiplier() <= 0.0:
		return null
	var hand_stack := equipment.get_hand_stack() if equipment != null else null
	var damage: float = unarmed_melee_damage
	if hand_stack != null and hand_stack.item_definition != null:
		damage = hand_stack.item_definition.melee_damage
	damage *= get_action_multiplier()
	var target: Node2D
	var closest := INF
	var reach := interactor.radius if interactor != null else 56.0
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if candidate is not Node2D or not candidate.has_method("take_damage"):
			continue
		var damageable := candidate as Node2D
		if global_position.distance_to(damageable.global_position) > reach:
			continue
		var pointer_distance := world_position.distance_squared_to(damageable.global_position)
		if pointer_distance <= 28.0 * 28.0 and pointer_distance < closest:
			target = damageable
			closest = pointer_distance
	if target != null:
		var applied: float = 0.0
		if hand_stack != null and hand_stack.item_definition.tool_damage > 0.0:
			applied = target.call("take_damage", hand_stack.item_definition.tool_damage * get_action_multiplier(), &"tool", hand_stack.item_definition.tool_damage_tags, self)
		if applied <= 0.0:
			target.call("take_damage", damage, &"melee", [], self)
		if hand_stack != null:
			equipment.damage_hand_item(1)
	attack_requested.emit(aim_direction)
	return target


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

func get_action_multiplier() -> float:
	return survival_needs.get_action_multiplier() if survival_needs != null else 1.0


func take_region_damage(region: StringName, amount: float, bleeding_rate: float = 0.0) -> float:
	if survival_needs == null or survival_needs.body_health.is_collapsed():
		return 0.0
	var applied := survival_needs.body_health.apply_damage(region, amount, bleeding_rate)
	if applied > 0.0:
		survival_needs.set_resting(false)
		survival_needs.needs_changed.emit(survival_needs.hunger, survival_needs.fatigue, survival_needs.body_health.blood)
	return applied
