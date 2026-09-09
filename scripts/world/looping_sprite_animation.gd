class_name LoopingSpriteAnimation
extends Sprite2D

@export_range(0.1, 60.0, 0.1) var frames_per_second := 10.0
@export_range(1, 64, 1) var animation_frame_count := 8
@export_range(0.0, 10.0, 0.01) var start_offset_seconds := 0.0

var _elapsed := 0.0


func _ready() -> void:
	hframes = animation_frame_count
	_elapsed = start_offset_seconds
	_update_frame()


func _process(delta: float) -> void:
	advance_animation(delta)


func advance_animation(delta: float) -> void:
	var loop_duration := float(animation_frame_count) / frames_per_second
	_elapsed = fmod(_elapsed + delta, loop_duration)
	_update_frame()


func _update_frame() -> void:
	frame = floori(_elapsed * frames_per_second) % animation_frame_count
