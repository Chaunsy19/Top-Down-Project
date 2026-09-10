class_name HealthComponent
extends Node

signal health_changed(current_health: float, maximum_health: float)
signal damaged(amount: float, damage_kind: StringName)
signal depleted()

var maximum_health := 1.0
var current_health := 1.0
var material_tags: Array[StringName] = []


func configure(max_health: float, tags: Array[StringName]) -> void:
	maximum_health = maxf(max_health, 1.0)
	current_health = maximum_health
	material_tags = tags.duplicate()
	health_changed.emit(current_health, maximum_health)


func apply_damage(amount: float, damage_kind: StringName = &"melee", effective_tags: Array = []) -> float:
	if amount <= 0.0 or is_depleted():
		return 0.0
	if damage_kind == &"tool" and not _has_matching_tag(effective_tags):
		return 0.0
	var applied := minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied, damage_kind)
	health_changed.emit(current_health, maximum_health)
	if is_depleted():
		depleted.emit()
	return applied


func restore_full() -> void:
	current_health = maximum_health
	health_changed.emit(current_health, maximum_health)


func is_depleted() -> bool:
	return current_health <= 0.0


func get_ratio() -> float:
	return clampf(current_health / maximum_health, 0.0, 1.0)


func _has_matching_tag(effective_tags: Array) -> bool:
	for tag in effective_tags:
		if tag in material_tags:
			return true
	return false
