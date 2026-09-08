class_name SkillTracker
extends Node

signal experience_gained(skill_id: StringName, amount: int, total: int)
signal skill_level_changed(skill_id: StringName, level: int)

@export var starting_levels: Dictionary[StringName, int] = {}

var _levels: Dictionary[StringName, int] = {}
var _experience: Dictionary[StringName, int] = {}


func _ready() -> void:
	_levels = starting_levels.duplicate()


func get_skill_level(skill_id: StringName) -> int:
	return _levels.get(skill_id, 0)


func set_skill_level(skill_id: StringName, level: int) -> void:
	_levels[skill_id] = maxi(level, 0)
	skill_level_changed.emit(skill_id, _levels[skill_id])


func add_experience(skill_id: StringName, amount: int) -> void:
	if skill_id.is_empty() or amount <= 0:
		return
	_experience[skill_id] = _experience.get(skill_id, 0) + amount
	experience_gained.emit(skill_id, amount, _experience[skill_id])


func get_experience(skill_id: StringName) -> int:
	return _experience.get(skill_id, 0)

