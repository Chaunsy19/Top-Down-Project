class_name WorldClock
extends Node

signal time_changed(day: int, hour: float)
signal game_time_advanced(game_minutes: float)

@export_range(60.0, 7200.0, 10.0) var day_length_real_seconds := 1200.0
@export_range(0.0, 24.0, 0.25) var starting_hour := 8.0
@export var starting_day := 1

const NIGHT_COLOR := Color(0.025, 0.035, 0.075, 1.0)
const DAWN_COLOR := Color(0.72, 0.64, 0.58, 1.0)
const DAY_COLOR := Color(1.0, 0.98, 0.93, 1.0)
const DUSK_COLOR := Color(0.48, 0.34, 0.38, 1.0)

var day := 1
var hour := 8.0
var total_game_minutes := 0.0

@onready var ambient_modulate: CanvasModulate = get_node_or_null("../AmbientModulate") as CanvasModulate


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("world_clock")
	day = maxi(starting_day, 1)
	hour = wrapf(starting_hour, 0.0, 24.0)
	total_game_minutes = float(day - 1) * 1440.0 + hour * 60.0
	_update_ambient_light()
	time_changed.emit(day, hour)


func _process(delta: float) -> void:
	advance_real_seconds(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_cycle_time"):
		set_time_of_day(hour + 6.0)
		get_viewport().set_input_as_handled()


func advance_real_seconds(real_seconds: float) -> void:
	if real_seconds <= 0.0 or day_length_real_seconds <= 0.0:
		return
	var game_minutes := real_seconds * 1440.0 / day_length_real_seconds
	advance_game_minutes(game_minutes)


func advance_game_minutes(game_minutes: float) -> void:
	if game_minutes <= 0.0:
		return
	total_game_minutes += game_minutes
	day = floori(total_game_minutes / 1440.0) + 1
	hour = fmod(total_game_minutes, 1440.0) / 60.0
	_update_ambient_light()
	game_time_advanced.emit(game_minutes)
	time_changed.emit(day, hour)


func set_time_of_day(value: float) -> void:
	hour = wrapf(value, 0.0, 24.0)
	total_game_minutes = float(day - 1) * 1440.0 + hour * 60.0
	_update_ambient_light()
	time_changed.emit(day, hour)


func get_time_text() -> String:
	var whole_hour := floori(hour)
	var minute := floori((hour - whole_hour) * 60.0)
	return "Day %d  %02d:%02d" % [day, whole_hour, minute]


func get_period_name() -> String:
	if hour < 5.0 or hour >= 21.0:
		return "Night"
	if hour < 7.0:
		return "Dawn"
	if hour < 18.0:
		return "Daylight"
	return "Dusk"


func get_ambient_color_at(sample_hour: float) -> Color:
	var wrapped_hour := wrapf(sample_hour, 0.0, 24.0)
	if wrapped_hour < 5.0 or wrapped_hour >= 21.0:
		return NIGHT_COLOR
	if wrapped_hour < 7.0:
		var dawn_blend := smoothstep(5.0, 7.0, wrapped_hour)
		return NIGHT_COLOR.lerp(DAWN_COLOR, dawn_blend).lerp(DAY_COLOR, dawn_blend * 0.35)
	if wrapped_hour < 18.0:
		var daylight_blend := smoothstep(7.0, 9.0, wrapped_hour)
		return DAWN_COLOR.lerp(DAY_COLOR, daylight_blend)
	var dusk_blend := smoothstep(18.0, 21.0, wrapped_hour)
	return DAY_COLOR.lerp(DUSK_COLOR, dusk_blend).lerp(NIGHT_COLOR, dusk_blend * dusk_blend)


func _update_ambient_light() -> void:
	if is_instance_valid(ambient_modulate):
		ambient_modulate.color = get_ambient_color_at(hour)
