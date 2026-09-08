extends Node

signal state_changed(previous_state: State, current_state: State)

enum State {
	BOOTING,
	FOUNDATION_TEST,
	PAUSED,
}

var current_state: State = State.BOOTING
var _state_before_pause: State = State.FOUNDATION_TEST


func set_state(next_state: State) -> void:
	if next_state == current_state:
		return

	var previous_state := current_state
	current_state = next_state
	state_changed.emit(previous_state, current_state)


func set_paused(is_paused: bool) -> void:
	if is_paused:
		_state_before_pause = current_state
		set_state(State.PAUSED)
	else:
		set_state(_state_before_pause)


func get_state_name() -> String:
	return State.keys()[current_state].capitalize()

