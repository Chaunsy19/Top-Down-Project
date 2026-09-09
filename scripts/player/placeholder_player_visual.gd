extends Node2D

const BODY_COLOR := Color("#e6c36a")
const BODY_SHADOW := Color("#473b30")
const FACING_COLOR := Color("#f5edd7")

var _last_facing := Vector2.DOWN


func _process(_delta: float) -> void:
	var parent_body := get_parent() as CharacterBody2D
	if parent_body and not parent_body.velocity.is_zero_approx():
		_last_facing = parent_body.velocity.normalized()
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(2.0, 4.0), 13.0, BODY_SHADOW)
	draw_circle(Vector2.ZERO, 13.0, BODY_COLOR)
	draw_line(Vector2.ZERO, _last_facing * 13.0, FACING_COLOR, 3.0, true)
	draw_circle(_last_facing * 13.0, 2.5, FACING_COLOR)

