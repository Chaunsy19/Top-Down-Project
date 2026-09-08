class_name InventoryComponent
extends Node

const ItemStackScript = preload("res://scripts/data/items/item_stack.gd")

signal changed()
signal item_added(item_definition: Resource, quantity: int)
signal item_removed(item_definition: Resource, quantity: int)

@export_range(1, 200, 1) var slot_count := 24
@export_range(0.0, 10000.0, 0.1) var maximum_weight := 40.0
@export var starting_stacks: Array[Resource] = []

var _slots: Array[Resource] = []


func _ready() -> void:
	add_to_group("inventory")
	initialize_slots()


func initialize_slots() -> void:
	_slots.clear()
	_slots.resize(slot_count)
	for starting_stack in starting_stacks:
		if starting_stack != null and starting_stack.is_valid():
			add_item(starting_stack.item_definition, starting_stack.quantity)
	changed.emit()


func get_slot(index: int) -> Resource:
	return _slots[index] if is_valid_slot(index) else null


func get_slots() -> Array[Resource]:
	return _slots.duplicate()


func get_used_slot_count() -> int:
	var used := 0
	for stack in _slots:
		if stack != null:
			used += 1
	return used


func get_total_weight() -> float:
	var total := 0.0
	for stack in _slots:
		if stack != null and stack.item_definition != null:
			total += stack.item_definition.weight * stack.quantity
	return total


func get_addable_quantity(item_definition: Resource) -> int:
	if item_definition == null:
		return 0
	var slot_capacity := 0
	for stack in _slots:
		if stack == null:
			slot_capacity += item_definition.stack_limit
		elif stack.item_definition == item_definition:
			slot_capacity += maxi(item_definition.stack_limit - stack.quantity, 0)
	if item_definition.weight <= 0.0 or maximum_weight <= 0.0:
		return slot_capacity
	var weight_capacity := floori(maxf(maximum_weight - get_total_weight(), 0.0) / item_definition.weight)
	return mini(slot_capacity, weight_capacity)


func add_item(item_definition: Resource, quantity: int) -> int:
	if item_definition == null or quantity <= 0:
		return maxi(quantity, 0)
	var amount_to_add := mini(quantity, get_addable_quantity(item_definition))
	var remaining_to_place := amount_to_add

	for stack in _slots:
		if remaining_to_place <= 0:
			break
		if stack != null and stack.item_definition == item_definition:
			var space: int = item_definition.stack_limit - stack.quantity
			var moved := mini(space, remaining_to_place)
			stack.quantity += moved
			remaining_to_place -= moved

	for index in _slots.size():
		if remaining_to_place <= 0:
			break
		if _slots[index] != null:
			continue
		var stack := ItemStackScript.new()
		stack.item_definition = item_definition
		stack.quantity = mini(item_definition.stack_limit, remaining_to_place)
		remaining_to_place -= stack.quantity
		_slots[index] = stack

	if amount_to_add > 0:
		item_added.emit(item_definition, amount_to_add)
		changed.emit()
	return quantity - amount_to_add


func remove_from_slot(index: int, quantity: int) -> Resource:
	var stack := get_slot(index)
	if stack == null or quantity <= 0:
		return null
	var removed_quantity := mini(quantity, stack.quantity)
	var removed_stack := ItemStackScript.new()
	removed_stack.item_definition = stack.item_definition
	removed_stack.quantity = removed_quantity
	stack.quantity -= removed_quantity
	if stack.quantity <= 0:
		_slots[index] = null
	item_removed.emit(removed_stack.item_definition, removed_quantity)
	changed.emit()
	return removed_stack


func move_or_merge(from_index: int, to_index: int, quantity := -1) -> bool:
	if not is_valid_slot(from_index) or not is_valid_slot(to_index) or from_index == to_index:
		return false
	var source := _slots[from_index]
	if source == null:
		return false
	var amount: int = source.quantity if quantity < 0 else mini(quantity, source.quantity)
	var destination := _slots[to_index]

	if destination == null:
		var moved_stack := remove_from_slot(from_index, amount)
		_slots[to_index] = moved_stack
		changed.emit()
		return true
	if destination.item_definition == source.item_definition:
		var capacity: int = destination.item_definition.stack_limit - destination.quantity
		var moved := mini(amount, capacity)
		if moved <= 0:
			return false
		destination.quantity += moved
		source.quantity -= moved
		if source.quantity <= 0:
			_slots[from_index] = null
		changed.emit()
		return true
	if amount == source.quantity:
		_slots[from_index] = destination
		_slots[to_index] = source
		changed.emit()
		return true
	return false


func split_stack(index: int) -> bool:
	var stack := get_slot(index)
	var empty_index := find_first_empty_slot()
	if stack == null or stack.quantity < 2 or empty_index < 0:
		return false
	var split_quantity: int = stack.quantity / 2
	var split_stack_value := ItemStackScript.new()
	split_stack_value.item_definition = stack.item_definition
	split_stack_value.quantity = split_quantity
	stack.quantity -= split_quantity
	_slots[empty_index] = split_stack_value
	changed.emit()
	return true


func transfer_to(target: InventoryComponent, from_index: int, quantity := -1) -> int:
	var source := get_slot(from_index)
	if source == null or target == null or target == self:
		return 0
	var requested: int = source.quantity if quantity < 0 else mini(quantity, source.quantity)
	var transferable := mini(requested, target.get_addable_quantity(source.item_definition))
	if transferable <= 0:
		return 0
	var definition: Resource = source.item_definition
	var removed := remove_from_slot(from_index, transferable)
	var remainder := target.add_item(definition, removed.quantity)
	if remainder > 0:
		add_item(definition, remainder)
	return transferable - remainder


func find_first_empty_slot() -> int:
	for index in _slots.size():
		if _slots[index] == null:
			return index
	return -1


func find_first_item(item_id: StringName) -> int:
	for index in _slots.size():
		var stack := _slots[index]
		if stack != null and stack.item_definition.item_id == item_id:
			return index
	return -1


func find_compatible_tool(required_tags: Array[StringName], minimum_tier := 1) -> Resource:
	if required_tags.is_empty():
		return null
	for stack in _slots:
		if stack == null or stack.item_definition == null:
			continue
		var tool_profile: Resource = stack.item_definition.tool_profile
		if tool_profile != null and tool_profile.satisfies(required_tags, minimum_tier):
			return stack.item_definition
	return null


func is_valid_slot(index: int) -> bool:
	return index >= 0 and index < _slots.size()
