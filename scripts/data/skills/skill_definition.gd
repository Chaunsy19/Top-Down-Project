@tool
class_name SkillDefinition
extends Resource
@export var skill_id: StringName
@export var display_name := "Skill"
@export_multiline var description := ""
@export var icon: Texture2D
@export_range(0, 100, 1) var starting_level := 0
func validate() -> PackedStringArray:
	return PackedStringArray(["Skill ID is required."]) if skill_id.is_empty() else PackedStringArray()

