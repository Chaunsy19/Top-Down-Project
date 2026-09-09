# Designing the starter island

The playable terrain lives in `scenes/world/starter_island.tscn`. It uses one 32×32-pixel `TileMapLayer` named `TerrainMap`, instanced as `StarterIsland` in the test scene.

## Terrain palette

The atlas is one row of four tiles, from left to right:

1. Dirt — walkable.
2. Grass — walkable.
3. Shallow water — walkable.
4. Deep water — blocked and collision-backed.

Each tile also stores `terrain_id` and `walkable` custom data. Gameplay code reads those values instead of deciding movement from tile color or atlas position.

## Painting the map in Godot

1. Open `scenes/world/starter_island.tscn`.
2. Select the `TerrainMap` root node.
3. In the TileMap panel at the bottom, switch to the tile-painting view.
4. Select a tile from the four-tile atlas palette.
5. Use the pencil tool to paint, right-click to erase, and use the rectangle or bucket tools for larger areas.
6. Save the scene with **Ctrl+S** and press **F5** to test the full game on your edited map.

Keep the painted map within the current 28×16 area. If the map size changes, update `grid_dimensions` on `FoundationTest` so building placement and logical walkability use the same bounds.

## A reliable island workflow

1. Fill the full map with deep water.
2. Paint a shallow-water ring where the shoreline should be.
3. Fill the island interior with grass.
4. Add dirt for beaches, paths, clearings, and future building areas.
5. Place resource nodes and objects at the center of terrain cells.
6. Run around the entire shoreline and confirm that shallow water is enterable but deep water stops the player.

Terrain edits are read when the scene starts. Deep-water tiles are also registered with `GridWorld`, so future building and pathfinding checks see those cells as blocked.
