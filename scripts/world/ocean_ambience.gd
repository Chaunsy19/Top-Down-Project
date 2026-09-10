class_name OceanAmbience
extends Node
## One non-positional ocean bed; overlapping water tiles never stack voices.
@export var stream: AudioStream = preload("res://assets/Sounds/Environment/TileProximity/ocean.mp3")
@export_range(1.0, 50.0, 0.5) var proximity_tiles := 10.0
@export_range(0.1, 10.0, 0.1) var fade_seconds := 2.5
@export_range(-40.0, 0.0, 1.0) var maximum_volume_db := -16.0
var audio: AudioStreamPlayer
var terrain_maps: Array[TerrainMap] = []
var player: Node2D
var target_gain := 0.0
var gain := 0.0
var _check_elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	audio = AudioStreamPlayer.new()
	audio.name = "OceanAudio"
	audio.stream = stream.duplicate() if stream != null else null
	if audio.stream is AudioStreamMP3 or audio.stream is AudioStreamOggVorbis:
		audio.stream.loop = true
	elif audio.stream is AudioStreamWAV:
		audio.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.volume_db = -80.0
	add_child(audio)
	call_deferred("_find_sources")

func _find_sources() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	terrain_maps.clear()
	for candidate in get_tree().root.find_children("*", "TileMapLayer", true, false):
		if candidate is TerrainMap:
			terrain_maps.append(candidate)
	update_proximity()

func _process(delta: float) -> void:
	_check_elapsed += delta
	if _check_elapsed >= 0.2:
		_check_elapsed = 0.0
		update_proximity()
	advance_fade(delta)

func update_proximity() -> void:
	target_gain = 0.0
	if not is_instance_valid(player):
		return
	for terrain in terrain_maps:
		if is_instance_valid(terrain) and is_near_deep_water(terrain, player.global_position):
			target_gain = 1.0
			return

func is_near_deep_water(terrain: TerrainMap, world_position: Vector2) -> bool:
	if terrain.tile_set == null:
		return false
	var local_position := terrain.to_local(world_position)
	var center := terrain.local_to_map(local_position)
	var radius := ceili(proximity_tiles) + 1
	var tile_size := Vector2(terrain.tile_set.tile_size)
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if terrain.get_terrain_id(cell) != &"deep_water":
				continue
			var distance_in_tiles := (terrain.map_to_local(cell) - local_position) / tile_size
			if distance_in_tiles.length_squared() <= proximity_tiles * proximity_tiles:
				return true
	return false

func advance_fade(delta: float) -> void:
	gain = move_toward(gain, target_gain, maxf(delta, 0.0) / maxf(fade_seconds, 0.01))
	if gain > 0.0:
		audio.volume_db = maximum_volume_db + linear_to_db(gain)
		if not audio.playing and audio.stream != null:
			audio.play()
	else:
		audio.volume_db = -80.0
		audio.stop()
