class_name EquipmentComponent
extends Node

signal changed()
signal item_equipped(item_stack: Resource)
signal item_unequipped(item_stack: Resource)
signal equipped_item_broken(item_definition: Resource)

var _hand_stack: Resource
const ARMOR_SLOTS: Array[StringName] = [&"head", &"torso", &"legs"]
var _armor: Dictionary = {}


func get_armor_stack(slot: StringName) -> Resource:
	return _armor.get(slot)


func equip_armor_from_inventory(inventory: InventoryComponent, index: int, slot: StringName) -> bool:
	if inventory == null or slot not in ARMOR_SLOTS:
		return false
	var candidate: Resource = inventory.get_slot(index)
	if candidate == null or candidate.quantity != 1:
		return false
	var definition: Resource = candidate.item_definition
	if definition == null or definition.armor_slot != String(slot) or not definition.validate().is_empty():
		return false
	var previous := get_armor_stack(slot)
	if previous != null and inventory.get_addable_quantity_after_removals(previous.item_definition, {definition.item_id: 1}) < 1:
		return false
	var removed: Resource = inventory.remove_from_slot(index, 1)
	if removed == null:
		return false
	_armor[slot] = removed
	if previous != null:
		inventory.add_stack(previous)
		item_unequipped.emit(previous)
	item_equipped.emit(removed)
	changed.emit()
	return true


func unequip_armor_to_inventory(inventory: InventoryComponent, slot: StringName) -> bool:
	var previous := get_armor_stack(slot)
	if previous == null or inventory == null or inventory.get_addable_quantity(previous.item_definition) < 1:
		return false
	if inventory.add_stack(previous) > 0:
		return false
	_armor.erase(slot)
	item_unequipped.emit(previous)
	changed.emit()
	return true


func get_region_protection(region: StringName) -> float:
	var slot := region
	if region in [&"left_leg", &"right_leg"]:
		slot = &"legs"
	elif region not in [&"head", &"torso"]:
		return 0.0
	var stack := get_armor_stack(slot)
	return clampf(stack.item_definition.armor_protection, 0.0, 0.9) if stack != null else 0.0


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
