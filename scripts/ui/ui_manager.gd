extends Node

signal modal_stack_changed(open_modal_count: int)

var _modal_stack: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and close_top_modal():
		get_viewport().set_input_as_handled()


func register_modal(owner: Object, close_callback: Callable) -> void:
	if not is_instance_valid(owner) or not close_callback.is_valid():
		push_warning("UIManager rejected an invalid modal registration.")
		return
	unregister_modal(owner)
	_modal_stack.append({
		"owner": owner,
		"close_callback": close_callback,
	})
	modal_stack_changed.emit(_modal_stack.size())


func unregister_modal(owner: Object) -> void:
	var removed := false
	for index in range(_modal_stack.size() - 1, -1, -1):
		if _modal_stack[index].owner == owner:
			_modal_stack.remove_at(index)
			removed = true
	if removed:
		modal_stack_changed.emit(_modal_stack.size())


func close_top_modal() -> bool:
	while not _modal_stack.is_empty():
		var entry: Dictionary = _modal_stack.pop_back()
		var owner: Object = entry.owner
		var close_callback: Callable = entry.close_callback
		if is_instance_valid(owner) and close_callback.is_valid():
			modal_stack_changed.emit(_modal_stack.size())
			close_callback.call()
			return true
	modal_stack_changed.emit(0)
	return false


func has_open_modal() -> bool:
	_cleanup_invalid_entries()
	return not _modal_stack.is_empty()


func get_open_modal_count() -> int:
	_cleanup_invalid_entries()
	return _modal_stack.size()


func _cleanup_invalid_entries() -> void:
	var changed := false
	for index in range(_modal_stack.size() - 1, -1, -1):
		var entry: Dictionary = _modal_stack[index]
		if not is_instance_valid(entry.owner) or not (entry.close_callback as Callable).is_valid():
			_modal_stack.remove_at(index)
			changed = true
	if changed:
		modal_stack_changed.emit(_modal_stack.size())

