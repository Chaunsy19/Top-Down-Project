extends Node2D

const GRID_SIZE := 32
const ROOM_SIZE := Vector2i(28, 16)
const FLOOR_COLOR := Color("#25352f")
const GRID_COLOR := Color("#385047")
const WALL_COLOR := Color("#9b7859")


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var room_rect := Rect2(Vector2.ZERO, Vector2(ROOM_SIZE * GRID_SIZE))
	draw_rect(room_rect, FLOOR_COLOR)

	for x in range(ROOM_SIZE.x + 1):
		var x_position := float(x * GRID_SIZE)
		draw_line(Vector2(x_position, 0.0), Vector2(x_position, room_rect.size.y), GRID_COLOR)

	for y in range(ROOM_SIZE.y + 1):
		var y_position := float(y * GRID_SIZE)
		draw_line(Vector2(0.0, y_position), Vector2(room_rect.size.x, y_position), GRID_COLOR)

	draw_rect(room_rect, WALL_COLOR, false, 8.0)
	draw_circle(room_rect.get_center(), 18.0, Color("#e6c36a"))
	draw_circle(room_rect.get_center(), 8.0, Color("#473b30"))

