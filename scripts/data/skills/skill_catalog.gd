@tool
class_name SkillCatalog
extends Resource
@export var skills: Array[Resource] = []
func get_skill(id: StringName) -> Resource:
	for skill in skills:
		if skill != null and skill.skill_id == id:
			return skill
	return null
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	for skill in skills:
		if skill == null:
			errors.append("Empty skill record.")
			continue
		errors.append_array(skill.validate())
		if ids.has(skill.skill_id):
			errors.append("Duplicate skill ID: %s" % skill.skill_id)
		ids[skill.skill_id] = true
	return errors
