# Changelog

All notable project changes are recorded here by milestone.

## Unreleased

### Tool and weapon hotbar

- Added an always-visible nine-slot HUD controlled by number keys 1–9.
- Added inventory-to-hotbar assignment by item ID so shortcuts survive inventory moves and tool swapping.
- Added automatic equipment swapping, empty-slot unequipping, missing-item feedback, durability display, and tool/weapon category filtering.
- Added automated coverage for mappings, assignment, selection, swapping, and HUD structure.

### Animated campfire effects

- Replaced the procedural flame with the supplied eight-frame fire and smoke sprite sheets.
- Added independently configurable looping fire and smoke animations while retaining the stone/log base, crafting interaction, and soft flickering light.
- Added automated coverage for animation frames, effect layering, and light integration.

### Editable starter-island terrain

- Added a reusable 32×32 terrain tileset with dirt, grass, walkable shallow water, and blocked deep water.
- Replaced the procedural test-room floor with an editable starter-island `TileMapLayer`.
- Connected terrain walkability to both physics collision and the shared `GridWorld` blocked-cell API.
- Added a map-design guide and automated terrain integration coverage.

### Mouse-facing player aim

- Added continuous world-space mouse aiming that remains independent from player movement.
- Added a reusable aim direction, angle, pivot, and forward tool socket for future tools and weapons.
- Updated the placeholder player to visibly face the aim direction.
- Added automated coverage for cardinal and diagonal aim, deadzone behavior, pivot rotation, socket placement, and movement independence.

### Milestone 6 — World clock, needs, and survival lighting

- Added a centralized 20-minute real-time day/night clock with pause-compatible progression and a debug time-cycle action.
- Added smooth multi-hour dawn and dusk ambient-light transitions and near-black unlit nights.
- Added reusable data-driven soft lights with radial falloff, ambient-aware intensity, and subtle campfire flicker.
- Added hunger, fatigue, resting, health damage from critical needs, recovery, and movement penalties.
- Added nutrition data to food and an inventory action for eating selected items.
- Added a compact always-visible clock and survival-needs HUD.
- Added automated coverage for time progression, light curves, soft light, eating, resting, penalties, and health pressure.

### Tile-based world foundation

- Added authoritative cell ownership so the grid can identify the blocking object occupying each tile and reject overlapping placement.
- Made blocking interactables snap to the center of their claimed grid cell.
- Reworked mineable rock into full-cell stone blocks with cardinal neighbor connections, full-tile collision, and cluster-aware labels.
- Added a connected three-tile stone formation to the test scene.
- Added automated coverage for snapping, occupancy ownership, exclusive placement, and tile connections.

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
