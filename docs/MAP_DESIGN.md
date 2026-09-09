# Designing the starter island

The playable terrain lives in `scenes/world/starter_island.tscn`. It uses one 32×32-pixel `TileMapLayer` named `TerrainMap`, instanced as `StarterIsland` in the test scene.

## Terrain palette and variations

The Tilebase source textures are converted into a compact atlas with eight visual variations for each terrain:

1. Grassy dirt — walkable.
2. Grass — walkable.
3. Shallow water — walkable.
4. Deep water — blocked and collision-backed.
5. Sand — walkable.

In the TileMap palette, each atlas column is one terrain and its eight rows are the variations. Gameplay reads the `terrain_id`, `walkable`, and `blend_priority` custom data attached to each tile; it never guesses behavior from the artwork or atlas position.

`TerrainMap` selects a stable variation for every painted cell when the map starts. The variation is deterministic, so it will not shimmer or change between frames. Change `variation_seed` on the node for a different distribution, or disable `automatic_variations` if you want every hand-picked atlas row preserved.

## Soft terrain blending

`TerrainBlendOverlay` adds a translucent ten-pixel transition wherever unlike cardinal neighbors meet. The natural layering order is:

`deep water → shallow water → sand → grassy dirt → grass`

For example, sand feathers into shallow water and grass feathers into grassy dirt. This is visual only: the underlying painted cell still controls walking, collision, future pathfinding, and building rules. Diagonal-only contacts do not receive a separate corner mask yet.

## Painting the map in Godot

1. Open `scenes/world/starter_island.tscn`.
2. Select the `TerrainMap` root node, not its blend-overlay child.
3. In the TileMap panel at the bottom, switch to tile painting.
4. Choose the desired terrain column. Any row is valid; automatic variation will distribute all eight when the game runs.
5. Use the pencil to paint, right-click to erase, and the rectangle or bucket tools for larger areas.
6. Save with **Ctrl+S** and press **F5** to see automatic variation and blending.

Keep the painted map within the current 28×16 area. If the map size changes, update `grid_dimensions` on `FoundationTest` so building placement and logical walkability use the same bounds.

## A reliable island workflow

1. Fill the full map with deep water.
2. Paint a shallow-water ring around the shore.
3. Add a one- or two-cell sand beach inside the shallow water.
4. Fill the interior with grass.
5. Add grassy dirt for paths, clearings, and future building areas.
6. Place resource nodes and objects at the center of terrain cells.
7. Run the shoreline and confirm shallow water is enterable while deep water stops the player.

## Regenerating the atlas

The original 1254×1254 textures stay in `assets/TileBase`. The checked-in scripts in `tools` sample eight regions from each source, scale them into 32×32 tiles, and rebuild both the base and blend atlases. This keeps the pipeline reproducible if a source texture changes.

Run these commands from the project folder with your Godot executable:

```powershell
godot --headless --path . --script res://tools/generate_terrain_art.gd
godot --editor --headless --path . --quit
godot --headless --path . --script res://tools/generate_terrain_tileset.gd
```

The middle import pass makes the newly written PNG available before the TileSet resource is rebuilt.
