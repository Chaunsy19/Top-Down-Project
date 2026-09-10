extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
func run() -> void:
	var terrain := TerrainMap.new()
	terrain.tile_set = load("res://data/terrain/starter_terrain_tileset.tres")
	root.add_child(terrain)
	terrain.paint_terrain(Vector2i.ZERO, &"deep_water")
	var ocean := OceanAmbience.new()
	root.add_child(ocean)
	await process_frame
	ocean.set_process(false)
	check(ocean.gain == 0.0 and not ocean.audio.playing, "Ambience starts silent away from water")
	var origin := terrain.to_global(terrain.map_to_local(Vector2i.ZERO))
	check(ocean.is_near_deep_water(terrain, origin + Vector2(320, 0)), "Exactly ten tiles is inside")
	check(not ocean.is_near_deep_water(terrain, origin + Vector2(321, 0)), "Beyond ten tiles is outside")
	check(not ocean.is_near_deep_water(terrain, origin + Vector2(256, 256)), "Diagonal distance uses circular radius")
	terrain.paint_terrain(Vector2i.ZERO, &"shallow_water")
	check(not ocean.is_near_deep_water(terrain, origin), "Shallow water does not trigger ocean")
	ocean.target_gain = 1.0
	ocean.advance_fade(1.25)
	check(is_equal_approx(ocean.gain, 0.5) and ocean.audio.playing, "Audio fades in and starts")
	ocean.advance_fade(1.25)
	check(is_equal_approx(ocean.gain, 1.0), "Fade reaches configured volume")
	check(ocean.audio.stream is AudioStreamMP3 and ocean.audio.stream.loop, "Supplied MP3 loops")
	ocean.target_gain = 0.0
	ocean.advance_fade(1.25)
	check(is_equal_approx(ocean.gain, 0.5) and ocean.audio.playing, "Fade out does not cut abruptly")
	ocean.target_gain = 1.0
	ocean.advance_fade(0.25)
	check(is_equal_approx(ocean.gain, 0.6), "Reentry reverses fade smoothly")
	ocean.target_gain = 0.0
	ocean.advance_fade(2.5)
	check(ocean.gain == 0.0 and not ocean.audio.playing, "Silent ambience stops playback")
	ocean.gain = 15.5
	ocean.advance_fade(ocean.fade_seconds)
	check(ocean.gain == 0.0 and not ocean.audio.playing, "Out-of-range gain cannot prolong fade-out")
	var actor := Node2D.new()
	root.add_child(actor)
	ocean.player = actor
	ocean.terrain_maps = [terrain]
	terrain.paint_terrain(Vector2i.ZERO, &"deep_water")
	actor.global_position = origin
	ocean.update_proximity()
	ocean.advance_fade(ocean.fade_seconds)
	check(ocean.audio.playing, "Approaching water starts ambience")
	actor.global_position = origin + Vector2(352, 0)
	ocean.update_proximity()
	ocean.advance_fade(ocean.fade_seconds)
	check(ocean.target_gain == 0.0 and not ocean.audio.playing, "Walking beyond radius fades to silence")
	actor.queue_free()
	ocean.queue_free()
	terrain.queue_free()
	await process_frame
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var live := main.get_node("OceanAmbience") as OceanAmbience
	check(live.player != null and not live.terrain_maps.is_empty(), "Main scene finds player and terrain")
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("OCEAN AMBIENCE TEST PASSED")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
