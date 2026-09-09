class_name SoftWorldLight
extends PointLight2D

@export var radius := 180.0
@export var base_energy := 1.15
@export var light_color := Color(1.0, 0.57, 0.25, 1.0)
@export var flicker_amount := 0.08
@export var flicker_speed := 2.2

var _elapsed := 0.0
var _world_clock: Node


func _ready() -> void:
	shadow_enabled = false
	color = light_color
	energy = base_energy
	texture = _create_soft_radial_texture()
	texture_scale = radius / 128.0
	call_deferred("_find_world_clock")


func _process(delta: float) -> void:
	_elapsed += delta
	var slow_wave := sin(_elapsed * flicker_speed)
	var quick_wave := sin(_elapsed * flicker_speed * 2.37 + 1.4)
	var ambient_factor := 1.0
	if is_instance_valid(_world_clock):
		var ambient_luminance: float = _world_clock.get_ambient_color_at(_world_clock.hour).get_luminance()
		var darkness := 1.0 - ambient_luminance
		ambient_factor = lerpf(0.15, 5.0, clampf(darkness, 0.0, 1.0))
	energy = base_energy * ambient_factor * (1.0 + (slow_wave * 0.65 + quick_wave * 0.35) * flicker_amount)


func configure_from_definition(definition: Resource) -> void:
	if definition == null:
		enabled = false
		return
	enabled = definition.emits_light
	light_color = definition.light_color
	base_energy = definition.light_energy
	radius = definition.light_radius
	flicker_amount = definition.light_flicker
	color = light_color
	energy = base_energy
	texture_scale = radius / 128.0


func _find_world_clock() -> void:
	_world_clock = get_tree().get_first_node_in_group("world_clock")


func _create_soft_radial_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.28, 0.7, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 0.94, 0.82, 0.88),
		Color(1.0, 0.72, 0.42, 0.28),
		Color(1.0, 0.55, 0.25, 0.0),
	])
	var radial_texture := GradientTexture2D.new()
	radial_texture.width = 256
	radial_texture.height = 256
	radial_texture.fill = GradientTexture2D.FILL_RADIAL
	radial_texture.fill_from = Vector2(0.5, 0.5)
	radial_texture.fill_to = Vector2(1.0, 0.5)
	radial_texture.gradient = gradient
	return radial_texture
