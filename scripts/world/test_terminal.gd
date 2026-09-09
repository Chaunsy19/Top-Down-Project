extends "res://scripts/interaction/interactable.gd"

const INACTIVE_COLOR := Color("#4f7185")
const ACTIVE_COLOR := Color("#72c9a5")

var is_active := false
var activation_count := 0

@onready var state_label: Label = %StateLabel


func _ready() -> void:
	super()
	_update_presentation()


func _perform_interaction(_actor: Node2D) -> void:
	is_active = not is_active
	activation_count += 1
	_update_presentation()


func get_debug_state() -> String:
	return "%s (uses: %d)" % ["Active" if is_active else "Idle", activation_count]


func _update_presentation() -> void:
	state_label.text = "ACTIVE" if is_active else "IDLE"
	queue_redraw()


func _draw() -> void:
	var color := ACTIVE_COLOR if is_active else INACTIVE_COLOR
	draw_rect(Rect2(-16.0, -16.0, 32.0, 32.0), Color("#18211e"))
	draw_rect(Rect2(-12.0, -12.0, 24.0, 18.0), color)
	draw_circle(Vector2(0.0, 11.0), 3.0, color)
