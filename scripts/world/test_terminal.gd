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
	draw_colored_polygon(PackedVector2Array([Vector2(-19, -8), Vector2(0, -18), Vector2(19, -8), Vector2(0, 2)]), Color("#53615c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-19, -8), Vector2(0, 2), Vector2(0, 22), Vector2(-19, 12)]), Color("#303b37"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 2), Vector2(19, -8), Vector2(19, 12), Vector2(0, 22)]), Color("#3d4a46"))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -7), Vector2(0, -13), Vector2(12, -7), Vector2(0, -1)]), color)
	draw_circle(Vector2(8.0, 8.0), 2.5, color.lightened(0.2))
