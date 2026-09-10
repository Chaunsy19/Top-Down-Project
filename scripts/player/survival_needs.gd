class_name SurvivalNeeds
extends Node

signal needs_changed(hunger: float, fatigue: float, health: float)
signal resting_changed(is_resting: bool)

@export_range(0.0, 100.0, 0.1) var hunger_depletion_per_game_hour := 4.0
@export_range(0.0, 100.0, 0.1) var fatigue_depletion_per_game_hour := 3.25
@export_range(0.0, 100.0, 0.1) var fatigue_recovery_per_game_hour := 20.0
@export_range(0.0, 100.0, 0.1) var critical_threshold := 20.0
@export_range(0.0, 100.0, 0.1) var critical_health_damage_per_game_hour := 4.0
@export_range(0.0, 100.0, 0.1) var safe_health_recovery_per_game_hour := 1.0

var body_health := preload("res://scripts/combat/body_health.gd").new()
var hunger := 100.0
var fatigue := 100.0
var health := 100.0
var is_resting := false


func _ready() -> void:
	add_child(body_health)
	add_to_group("survival_needs")
	call_deferred("_connect_world_clock")


func _connect_world_clock() -> void:
	var world_clock := get_tree().get_first_node_in_group("world_clock")
	if world_clock != null and not world_clock.game_time_advanced.is_connected(_on_game_time_advanced):
		world_clock.game_time_advanced.connect(_on_game_time_advanced)


func _on_game_time_advanced(game_minutes: float) -> void:
	advance_game_minutes(game_minutes)


func advance_game_minutes(game_minutes: float) -> void:
	body_health.advance_game_minutes(game_minutes, is_resting and hunger >= 50.0 and fatigue >= 50.0)
	var game_hours := maxf(game_minutes, 0.0) / 60.0
	hunger = maxf(hunger - hunger_depletion_per_game_hour * game_hours, 0.0)
	if is_resting:
		fatigue = minf(fatigue + fatigue_recovery_per_game_hour * game_hours, 100.0)
	else:
		fatigue = maxf(fatigue - fatigue_depletion_per_game_hour * game_hours, 0.0)
	var critical_needs := int(hunger <= critical_threshold) + int(fatigue <= critical_threshold)
	if critical_needs > 0:
		health = maxf(health - critical_health_damage_per_game_hour * critical_needs * game_hours, 0.0)
	elif health > 0.0 and not body_health.is_collapsed() and body_health.get_bleeding_rate() <= 0.0 and hunger >= 50.0 and fatigue >= 50.0:
		health = minf(health + safe_health_recovery_per_game_hour * game_hours, 100.0)
	needs_changed.emit(hunger, fatigue, health)


func consume_item(inventory: Node, slot_index: int) -> bool:
	if inventory == null:
		return false
	var stack: Resource = inventory.get_slot(slot_index)
	if stack == null or stack.item_definition == null or stack.item_definition.nutrition <= 0.0:
		return false
	var nutrition: float = stack.item_definition.nutrition
	if inventory.remove_from_slot(slot_index, 1) == null:
		return false
	hunger = minf(hunger + nutrition, 100.0)
	needs_changed.emit(hunger, fatigue, health)
	return true


func set_resting(value: bool) -> void:
	if is_resting == value:
		return
	is_resting = value
	resting_changed.emit(is_resting)
	needs_changed.emit(hunger, fatigue, health)


func toggle_resting() -> void:
	set_resting(not is_resting)


func get_movement_multiplier() -> float:
	if is_resting or health <= 0.0 or body_health.is_collapsed():
		return 0.0
	var multiplier := 1.0
	if hunger <= critical_threshold:
		multiplier *= 0.7
	if fatigue <= critical_threshold:
		multiplier *= 0.6
	if health < 50.0:
		multiplier *= lerpf(0.45, 1.0, health / 50.0)
	return multiplier * body_health.get_movement_multiplier()


func get_condition_text() -> String:
	if health <= 0.0 or body_health.is_collapsed():
		return "Collapsed"
	if is_resting:
		return "Resting"
	if hunger <= critical_threshold and fatigue <= critical_threshold:
		return "Starving and exhausted"
	if hunger <= critical_threshold:
		return "Starving"
	if fatigue <= critical_threshold:
		return "Exhausted"
	if body_health.get_bleeding_rate() > 0.0:
		return "Bleeding"
	if not body_health.injuries.is_empty():
		return "Injured"
	return "Stable"


func get_action_multiplier() -> float:
	return body_health.get_action_multiplier() if health > 0.0 else 0.0
