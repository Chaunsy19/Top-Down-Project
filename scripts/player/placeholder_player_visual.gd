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
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2(3.0, 18.0), 14.0, Color(0.05, 0.07, 0.06, 0.35))
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(-5.0, 11.0), Vector2(-5.0, 19.0), BODY_SHADOW, 5.0, true)
	draw_line(Vector2(5.0, 11.0), Vector2(5.0, 19.0), BODY_SHADOW, 5.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, -5.0), Vector2(11.0, -5.0), Vector2(8.0, 13.0), Vector2(-8.0, 13.0),
	]), BODY_COLOR)
	draw_circle(Vector2(0.0, -11.0), 8.0, BODY_COLOR.lightened(0.08))
	draw_line(Vector2(0.0, -2.0), _last_facing * 11.0 + Vector2(0.0, -2.0), FACING_COLOR, 2.5, true)
	draw_circle(_last_facing * 11.0 + Vector2(0.0, -2.0), 2.0, FACING_COLOR)
