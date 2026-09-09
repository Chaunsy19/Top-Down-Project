extends Node2D

const BODY_COLOR := Color("#e6c36a")
const BODY_SHADOW := Color("#473b30")
const FACING_COLOR := Color("#f5edd7")

var _facing := Vector2.DOWN


func _ready() -> void:
	var player := get_parent() as PlayerController
	if player != null:
		_facing = player.get_aim_direction()
		player.aim_direction_changed.connect(_on_aim_direction_changed)


func _on_aim_direction_changed(direction: Vector2) -> void:
	_facing = direction
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(2.0, 4.0), 13.0, BODY_SHADOW)
	draw_circle(Vector2.ZERO, 13.0, BODY_COLOR)
	var side := _facing.orthogonal() * 4.0
	var face_center := _facing * 7.0
	draw_circle(face_center + side, 1.8, FACING_COLOR)
	draw_circle(face_center - side, 1.8, FACING_COLOR)
	draw_line(_facing * 5.0, _facing * 18.0, FACING_COLOR, 2.5, true)
	draw_circle(_facing * 18.0, 2.2, FACING_COLOR)

