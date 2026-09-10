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

`TerrainMap` listens to its own change notifications and watches the compact tile-data fingerprint for raw TileMap edits. Every cell painted in the editor, placed through `set_cell`, or created by a future map generator automatically receives a stable variation and requests a blend redraw within `automatic_refresh_interval` (0.1 seconds by default). The variation is deterministic, so it will not shimmer or change between frames. Change `variation_seed` on the node for a different distribution, or disable `automatic_variations` if you want every hand-picked atlas row preserved.

## Soft terrain blending

`TerrainBlendOverlay` adds a ten-pixel transition along every cardinal tile boundary. It samples the neighbor's matching opposite edge, so the pixels on both sides of a boundary meet before feathering inward. Variations of the same terrain crossfade first, then actual terrain boundaries are composited on top so those side blends cannot cut square notches into shoreline corners. When several terrain types meet, higher-priority terrain is drawn last. Different terrains use this natural layering order:

`deep water → shallow water → sand → grassy dirt → grass`

For example, sand feathers into shallow water and grass feathers into grassy dirt. There is no transition tile to select and no cleanup pass after painting. This is visual only: the underlying painted cell still controls walking, collision, future pathfinding, and building rules. Diagonal-only contacts do not require a transition because they share no visible edge.

## Painting the map in Godot

1. Open `scenes/world/starter_island.tscn`.
2. Select the `TerrainMap` root node, not its blend-overlay child.
3. In the TileMap panel at the bottom, switch to tile painting.
4. Choose the desired terrain column. Any row is valid; automatic variation will distribute all eight when the game runs.
5. Use the pencil to paint, right-click to erase, and the rectangle or bucket tools for larger areas.
6. Variations and blends refresh automatically. Save with **Ctrl+S** and press **F5** to test walking and collision.

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
