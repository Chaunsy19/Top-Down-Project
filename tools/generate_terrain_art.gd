extends SceneTree

const TILE_SIZE := 32
const CROP_SIZE := 256
const VARIATION_COUNT := 8
const BLEND_DIRECTION_COUNT := 4
const BLEND_WIDTH := 10.0
const BLEND_ALPHA := 1.0

const TERRAIN_SOURCES := [
	"res://assets/TileBase/GrassyDirtTile.png",
	"res://assets/TileBase/GrassTile.png",
	"res://assets/TileBase/ShallowWaterTile.png",
	"res://assets/TileBase/DeepWaterTile.png",
	"res://assets/TileBase/SandTile.png",
]

const SAMPLE_ORIGINS := [
	Vector2i(24, 32),
	Vector2i(286, 86),
	Vector2i(552, 164),
	Vector2i(826, 246),
	Vector2i(92, 492),
	Vector2i(364, 656),
	Vector2i(638, 822),
	Vector2i(928, 920),
]


func _initialize() -> void:
	var base_atlas := Image.create(TERRAIN_SOURCES.size() * TILE_SIZE, VARIATION_COUNT * TILE_SIZE, false, Image.FORMAT_RGBA8)
	var blend_atlas := Image.create(TERRAIN_SOURCES.size() * TILE_SIZE, VARIATION_COUNT * BLEND_DIRECTION_COUNT * TILE_SIZE, false, Image.FORMAT_RGBA8)

	for terrain_index in TERRAIN_SOURCES.size():
		var source := Image.load_from_file(TERRAIN_SOURCES[terrain_index])
		if source == null or source.is_empty():
			push_error("Could not load terrain source: %s" % TERRAIN_SOURCES[terrain_index])
			quit(1)
			return
		source.convert(Image.FORMAT_RGBA8)
		for variation in VARIATION_COUNT:
			var tile := source.get_region(Rect2i(SAMPLE_ORIGINS[variation], Vector2i.ONE * CROP_SIZE))
			tile.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_LANCZOS)
			base_atlas.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i.ONE * TILE_SIZE), Vector2i(terrain_index * TILE_SIZE, variation * TILE_SIZE))
			for direction in BLEND_DIRECTION_COUNT:
				var overlay := _make_blend_overlay(tile, direction)
				var destination := Vector2i(terrain_index * TILE_SIZE, (variation * BLEND_DIRECTION_COUNT + direction) * TILE_SIZE)
				blend_atlas.blit_rect(overlay, Rect2i(Vector2i.ZERO, Vector2i.ONE * TILE_SIZE), destination)

	var base_error := base_atlas.save_png("res://art/terrain/generated_terrain_atlas.png")
	var blend_error := blend_atlas.save_png("res://art/terrain/generated_terrain_blends.png")
	if base_error != OK or blend_error != OK:
		push_error("Could not save generated terrain atlases: %s / %s" % [error_string(base_error), error_string(blend_error)])
		quit(1)
		return
	print("TERRAIN ART GENERATED: %d terrains, %d variations, and four blend edges per variation." % [TERRAIN_SOURCES.size(), VARIATION_COUNT])
	quit(0)


func _make_blend_overlay(tile: Image, direction: int) -> Image:
	var overlay := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			var distance_from_edge := 0.0
			var sample_position := Vector2i(x, y)
			match direction:
				0:
					distance_from_edge = float(y)
					sample_position.y = TILE_SIZE - 1 - y
				1:
					distance_from_edge = float(TILE_SIZE - 1 - x)
					sample_position.x = TILE_SIZE - 1 - x
				2:
					distance_from_edge = float(TILE_SIZE - 1 - y)
					sample_position.y = TILE_SIZE - 1 - y
				_:
					distance_from_edge = float(x)
					sample_position.x = TILE_SIZE - 1 - x
			var strength := clampf(1.0 - distance_from_edge / BLEND_WIDTH, 0.0, 1.0)
			strength = strength * strength * (3.0 - 2.0 * strength)
			var color: Color = tile.get_pixelv(sample_position)
			color.a = strength * BLEND_ALPHA
			overlay.set_pixel(x, y, color)
	return overlay
