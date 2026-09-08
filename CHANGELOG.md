# Changelog

All notable project changes are recorded here by milestone.

## Unreleased

### Milestone 0 — Project foundation

- Created the Godot 4 project and baseline directory structure.
- Added main and standalone foundation test scenes.
- Added centralized game-state and debug-overlay scripts.
- Defined initial gameplay, camera, pause, and debugging input actions.
- Added project documentation and basic automated smoke checks.

### Milestone 1 — Player movement and camera

- Added reusable eight-direction player movement with acceleration and deceleration.
- Normalized diagonal input to prevent a diagonal speed advantage.
- Added physical walls and player collision to the foundation test room.
- Added a smooth follow camera with bounded zoom and reset controls.
- Added placeholder player visuals and a visible interaction-range indicator.
- Added automated movement, normalization, and collision checks.

### Milestone 2 — Grid world and interactable objects

- Added reusable world/cell coordinate conversion and blocked-cell tracking.
- Added an extensible interactable contract with approach points, validation, use, prompts, and debug state.
- Added player-side nearest-target discovery and interaction handling.
- Added an interactive test terminal that toggles state and occupies a blocked grid cell.
- Expanded the debug overlay with player grid coordinates, walkability, and target state.
- Added automated grid, occupancy, targeting, and interaction checks.
- Centered test-object interaction reach and added four-direction range regression coverage.

### Milestone 3 — Resource nodes and harvesting

- Added editable catalogs for item categories, items, and resource-node definitions.
- Added reusable item-definition and item-stack data types for future inventory work.
- Added generic timed harvesting with skill checks, XP rewards, cancellation, yields, depletion, respawning, and regrowth.
- Added data-defined trees, rocks, and berry bushes producing typed world-item drops.
- Added a reusable skill tracker shared by future player and NPC character systems.
- Added automated catalog, requirement, harvesting, drop, depletion, and regrowth checks.

### Milestone 4 — Inventory and containers

- Added reusable slot-based inventories with data-defined stack limits and weight capacity.
- Added stack splitting, merging, swapping, partial transfer, and full transfer behavior.
- Connected world drops to player pickup and inventory-backed dropping.
- Added a reusable paired container/inventory interface inspired by the supplied layout reference.
- Added category-colored slots, quantities, tooltips, selection state, and inventory notifications.
- Reserved a dedicated player-inventory footer for future currencies.
- Added a supply crate and stone axe to exercise the complete item lifecycle.
- Added automated inventory-unit and scene-integration coverage.

### Interface foundation

- Added a reusable modal UI stack for current and future screens.
- Escape closes the topmost open inventory or container interface and restores world pause state.
- Escape intentionally does nothing when no modal interface is open; pause-menu behavior remains deferred.

### Tool requirement foundation

- Added reusable tool profiles with capability tags, tiers, work-speed multipliers, and durability capacity.
- Trees now require an axe; rocks require a pickaxe; berry bushes require no tool.
- Added a tier-one stone pickaxe and configured the stone axe as a tier-one harvesting tool.
- Added loose stick and stone pickups to support the future first-tool crafting loop.
- Compatible tools are selected by the equipment system added in Milestone 5.

### Milestone 5 — Tools, gathering actions, and basic crafting

- Added a reusable hand equipment component shared by future player and NPC actors.
- Added per-item tool durability that survives inventory transfers, equipment, dropping, and pickup.
- Harvesting now requires the correct equipped tool, consumes durability, and removes broken tools.
- Added data-driven recipe ingredients, recipes, recipe catalogs, workstation tags, and validation.
- Added timed hand crafting for stone axes and stone pickaxes.
- Added a generic campfire workstation and a campfire-only cooked berry meal recipe.
- Added a modal crafting UI with recipe availability, ingredient counts, results, workstation requirements, progress, and clear failure feedback.
- Added equipment controls and durability display to the inventory UI.
- Expanded loose starter materials so both first-tier tools can be crafted in the test world.
- Added automated Milestone 5 coverage for crafting, equipment, durability, breakage, replacement, workstation rules, and modal behavior.

### Milestone 5.5 — True-isometric world conversion

- Replaced the orthogonal test room with a logical 14×14 grid projected as 64×32 isometric diamonds.
- Added reusable discrete and continuous grid/projection conversion methods for future placement, pathfinding, and jobs.
- Generated a four-edge physical boundary from the playable isometric diamond.
- Repositioned all world content by logical grid cell and enabled Y-sorted depth ordering.
- Changed interaction reach to use logical grid distance, avoiding projection-dependent directional bias.
- Updated the player, terminal, crate, tree, rock, and depleted-node placeholders for an isometric presentation.
- Preserved screen-relative direct movement while keeping world queries in logical grid coordinates.
- Added projection, placement, diamond geometry, Y-sorting, boundary, and interaction regression coverage.
