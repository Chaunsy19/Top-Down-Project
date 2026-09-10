extends Node2D

const FIST_COLOR := Color("#d6a957")
const HANDLE_COLOR := Color("#65402a")
const ATTACK_DURATION := 0.32
const REST_ANGLE := -85.0
const REST_HAND := Vector2(3.0, 10.0)
const EXTENDED_HAND := Vector2(16.0, 2.0)

var _player: PlayerController
var _equipment: EquipmentComponent
var _hotbar: HotbarComponent
var _attack_remaining := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rotation = deg_to_rad(REST_ANGLE)
	position = REST_HAND
	_player = get_parent().get_parent() as PlayerController
	_equipment = _player.get_node_or_null("Equipment") as EquipmentComponent if _player != null else null
	_hotbar = _player.get_node_or_null("Hotbar") as HotbarComponent if _player != null else null
	if _player != null:
		_player.combat_mode_changed.connect(_on_visual_state_changed)
		_player.attack_requested.connect(_on_attack_requested)
	if _equipment != null:
		_equipment.changed.connect(_on_equipment_changed)
	queue_redraw()


func _process(delta: float) -> void:
	if _attack_remaining <= 0.0:
		return
	_attack_remaining = maxf(_attack_remaining - delta, 0.0)
	rotation = get_swing_angle()
	position = get_hand_position()
	queue_redraw()


func is_stance_visible() -> bool:
	return _hotbar != null and _hotbar.selected_slot >= 0 and _equipment != null and _equipment.get_hand_stack() != null


func is_attack_animating() -> bool:
	return _attack_remaining > 0.0


func _on_visual_state_changed(_is_combat_ready: bool) -> void:
	_attack_remaining = 0.0
	rotation = deg_to_rad(REST_ANGLE)
	position = REST_HAND
	queue_redraw()


func _on_equipment_changed() -> void:
	queue_redraw()


func _on_attack_requested(_direction: Vector2) -> void:
	_attack_remaining = ATTACK_DURATION
	rotation = get_swing_angle()
	position = get_hand_position()
	queue_redraw()


func _draw() -> void:
	if not is_stance_visible():
		return
	var attack_progress := 1.0 - (_attack_remaining / ATTACK_DURATION)
	var extension := sin(attack_progress * PI) * 7.0 if is_attack_animating() else 0.0
	var hand_stack := _equipment.get_hand_stack() if _equipment != null else null
	if hand_stack == null:
		draw_circle(Vector2(13 + extension, -7), 4.0, FIST_COLOR)
		draw_circle(Vector2(13 + extension * 0.35, 7), 4.0, FIST_COLOR)
		return
	var definition: Resource = hand_stack.item_definition
	if definition.icon != null:
		var texture_size: Vector2 = definition.icon.get_size()
		var draw_size := texture_size * (34.0 / maxf(texture_size.x, 1.0))
		# Mirror around the grip so the handle stays anchored to the hand.
		if definition.held_flip_v:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, -1.0))
		draw_texture_rect(definition.icon, Rect2(-definition.held_grip * draw_size, draw_size), false)
		draw_set_transform(Vector2.ZERO)
		draw_circle(Vector2.ZERO, 2.5, FIST_COLOR)
		return
	var item_color: Color = definition.world_color
	draw_line(Vector2(7, 0), Vector2(25 + extension, 0), HANDLE_COLOR, 4.0, true)
	draw_rect(Rect2(20 + extension, -6, 10, 12), item_color)

func get_swing_angle() -> float:
	if not is_attack_animating():
		return deg_to_rad(REST_ANGLE)
	var progress := 1.0 - _attack_remaining / ATTACK_DURATION
	if progress < 0.15:
		return deg_to_rad(lerpf(REST_ANGLE, -125.0, smoothstep(0.0, 0.15, progress)))
	if progress < 0.65:
		return deg_to_rad(lerpf(-125.0, 15.0, smoothstep(0.15, 0.65, progress)))
	return deg_to_rad(lerpf(15.0, REST_ANGLE, smoothstep(0.65, 1.0, progress)))


func get_hand_position() -> Vector2:
	if not is_attack_animating():
		return REST_HAND
	var progress := 1.0 - _attack_remaining / ATTACK_DURATION
	var reach := smoothstep(0.15, 0.6, progress) if progress < 0.65 else 1.0 - smoothstep(0.65, 1.0, progress)
	return REST_HAND.lerp(EXTENDED_HAND, reach)
