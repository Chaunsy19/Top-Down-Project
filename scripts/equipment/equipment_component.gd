class_name EquipmentComponent
extends Node

signal changed()
signal item_equipped(item_stack: Resource)
signal item_unequipped(item_stack: Resource)
signal equipped_item_broken(item_definition: Resource)

var _hand_stack: Resource


func _ready() -> void:
	add_to_group("equipment")


func get_hand_stack() -> Resource:
	return _hand_stack


func get_equipped_tool(required_tags: Array[StringName], minimum_tier := 1) -> Resource:
	if _hand_stack == null or _hand_stack.item_definition == null:
		return null
	var profile: Resource = _hand_stack.item_definition.tool_profile
	if profile == null or not profile.satisfies(required_tags, minimum_tier):
		return null
	return _hand_stack


func equip_from_inventory(inventory: Node, slot_index: int) -> bool:
	if inventory == null:
		return false
	var candidate: Resource = inventory.get_slot(slot_index)
	if candidate == null or not can_equip_definition(candidate.item_definition):
		return false
	var removed: Resource = inventory.remove_from_slot(slot_index, candidate.quantity)
	if removed == null:
		return false
	var previous := _hand_stack
	_hand_stack = removed
	if previous != null and inventory.add_stack(previous) > 0:
		inventory.add_stack(removed)
		_hand_stack = previous
		return false
	item_equipped.emit(_hand_stack)
	changed.emit()
	return true


func can_equip_definition(item_definition: Resource) -> bool:
	return (
		item_definition != null
		and (item_definition.has_category(&"tool") or item_definition.has_category(&"weapon"))
	)


func unequip_to_inventory(inventory: Node) -> bool:
	if _hand_stack == null:
		return false
	if inventory == null or inventory.add_stack(_hand_stack) > 0:
		return false
	var previous := _hand_stack
	_hand_stack = null
	item_unequipped.emit(previous)
	changed.emit()
	return true


func damage_hand_item(amount := 1) -> bool:
	if _hand_stack == null:
		return false
	if not _hand_stack.damage_durability(amount):
		changed.emit()
		return false
	var broken_definition: Resource = _hand_stack.item_definition
	_hand_stack = null
	equipped_item_broken.emit(broken_definition)
	changed.emit()
	return true
