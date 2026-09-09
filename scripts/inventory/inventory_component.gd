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
			add_stack(starting_stack.duplicate_stack())
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


func get_addable_quantity_after_removals(item_definition: Resource, removals: Dictionary) -> int:
	if item_definition == null:
		return 0
	var remaining_removals := removals.duplicate()
	var slot_capacity := 0
	var projected_weight := get_total_weight()
	for item_id in remaining_removals:
		var removed_definition := get_item_definition(item_id)
		if removed_definition != null:
			projected_weight -= removed_definition.weight * int(remaining_removals[item_id])
	for stack in _slots:
		var projected_quantity := 0
		if stack != null:
			projected_quantity = stack.quantity
			var stack_id: StringName = stack.item_definition.item_id
			var removable: int = mini(projected_quantity, int(remaining_removals.get(stack_id, 0)))
			projected_quantity -= removable
			remaining_removals[stack_id] = int(remaining_removals.get(stack_id, 0)) - removable
		if projected_quantity <= 0:
			slot_capacity += item_definition.stack_limit
		elif stack.item_definition == item_definition:
			slot_capacity += maxi(item_definition.stack_limit - projected_quantity, 0)
	if item_definition.weight <= 0.0 or maximum_weight <= 0.0:
		return slot_capacity
	var weight_capacity := floori(maxf(maximum_weight - projected_weight, 0.0) / item_definition.weight)
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
		stack.initialize_runtime_state()
		remaining_to_place -= stack.quantity
		_slots[index] = stack

	if amount_to_add > 0:
		item_added.emit(item_definition, amount_to_add)
		changed.emit()
	return quantity - amount_to_add


func add_stack(incoming_stack: Resource) -> int:
	if incoming_stack == null or not incoming_stack.is_valid():
		return 0
	if incoming_stack.item_definition.stack_limit > 1 or not incoming_stack.has_durability():
		return add_item(incoming_stack.item_definition, incoming_stack.quantity)
	if get_addable_quantity(incoming_stack.item_definition) < incoming_stack.quantity:
		return incoming_stack.quantity
	var empty_index := find_first_empty_slot()
	if empty_index < 0:
		return incoming_stack.quantity
	var placed_stack: Resource = incoming_stack.duplicate_stack()
	_slots[empty_index] = placed_stack
	item_added.emit(placed_stack.item_definition, placed_stack.quantity)
	changed.emit()
	return 0


func remove_from_slot(index: int, quantity: int) -> Resource:
	var stack := get_slot(index)
	if stack == null or quantity <= 0:
		return null
	var removed_quantity := mini(quantity, stack.quantity)
	var removed_stack: Resource = stack.duplicate_stack(removed_quantity)
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


func transfer_to_slot(target: InventoryComponent, from_index: int, to_index: int, quantity := -1) -> int:
	if target == null or not is_valid_slot(from_index) or not target.is_valid_slot(to_index):
		return 0
	if target == self:
		var source_before := get_slot(from_index)
		if source_before == null:
			return 0
		var source_quantity: int = source_before.quantity
		if not move_or_merge(from_index, to_index, quantity):
			return 0
		var source_after := get_slot(from_index)
		if source_after == source_before:
			return source_quantity - source_after.quantity
		return mini(source_quantity, quantity) if quantity >= 0 else source_quantity

	var source := get_slot(from_index)
	if source == null or source.item_definition == null:
		return 0
	var requested: int = source.quantity if quantity < 0 else mini(quantity, source.quantity)
	var destination := target.get_slot(to_index)

	if destination == null or destination.item_definition == source.item_definition:
		var slot_capacity: int = source.item_definition.stack_limit
		if destination != null:
			slot_capacity -= destination.quantity
		var movable := mini(requested, mini(slot_capacity, target._get_weight_capacity(source.item_definition)))
		if movable <= 0:
			return 0
		var moved_stack: Resource = source.duplicate_stack(movable)
		source.quantity -= movable
		if source.quantity <= 0:
			_slots[from_index] = null
		if destination == null:
			target._slots[to_index] = moved_stack
		else:
			destination.quantity += movable
		item_removed.emit(moved_stack.item_definition, movable)
		target.item_added.emit(moved_stack.item_definition, movable)
		changed.emit()
		target.changed.emit()
		return movable

	if requested != source.quantity:
		return 0
	if not target._can_replace_slot(to_index, source) or not _can_replace_slot(from_index, destination):
		return 0
	_slots[from_index] = destination
	target._slots[to_index] = source
	item_removed.emit(source.item_definition, source.quantity)
	item_added.emit(destination.item_definition, destination.quantity)
	target.item_removed.emit(destination.item_definition, destination.quantity)
	target.item_added.emit(source.item_definition, source.quantity)
	changed.emit()
	target.changed.emit()
	return source.quantity


func split_stack(index: int) -> bool:
	var stack := get_slot(index)
	var empty_index := find_first_empty_slot()
	if stack == null or stack.quantity < 2 or empty_index < 0:
		return false
	var split_quantity: int = stack.quantity / 2
	var split_stack_value: Resource = stack.duplicate_stack(split_quantity)
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
	var remainder := target.add_stack(removed)
	if remainder > 0:
		add_stack(removed.duplicate_stack(remainder))
	return transferable - remainder


func get_item_quantity(item_id: StringName) -> int:
	var total := 0
	for stack in _slots:
		if stack != null and stack.item_definition.item_id == item_id:
			total += stack.quantity
	return total


func get_item_definition(item_id: StringName) -> Resource:
	var index := find_first_item(item_id)
	var stack := get_slot(index)
	return stack.item_definition if stack != null else null


func has_item_quantity(item_id: StringName, quantity: int) -> bool:
	return quantity <= 0 or get_item_quantity(item_id) >= quantity


func remove_item(item_id: StringName, quantity: int) -> int:
	var remaining := maxi(quantity, 0)
	for index in _slots.size():
		if remaining <= 0:
			break
		var stack := _slots[index]
		if stack == null or stack.item_definition.item_id != item_id:
			continue
		var removed := remove_from_slot(index, remaining)
		if removed != null:
			remaining -= removed.quantity
	return remaining


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


func _get_weight_capacity(item_definition: Resource) -> int:
	if item_definition == null:
		return 0
	if item_definition.weight <= 0.0 or maximum_weight <= 0.0:
		return item_definition.stack_limit
	return floori(maxf(maximum_weight - get_total_weight(), 0.0) / item_definition.weight)


func _can_replace_slot(index: int, incoming_stack: Resource) -> bool:
	if not is_valid_slot(index) or incoming_stack == null or not incoming_stack.is_valid():
		return false
	if incoming_stack.quantity > incoming_stack.item_definition.stack_limit:
		return false
	if maximum_weight <= 0.0:
		return true
	var outgoing_stack := get_slot(index)
	var projected_weight := get_total_weight()
	if outgoing_stack != null:
		projected_weight -= outgoing_stack.item_definition.weight * outgoing_stack.quantity
	projected_weight += incoming_stack.item_definition.weight * incoming_stack.quantity
	return projected_weight <= maximum_weight + 0.0001
