extends Area2D

@export_range(1.0, 256.0, 1.0) var radius := 56.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.902, 0.765, 0.416, 0.035))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.902, 0.765, 0.416, 0.42), 1.5, true)

