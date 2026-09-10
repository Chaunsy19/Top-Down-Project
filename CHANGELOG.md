# Changelog

All notable project changes are recorded here by milestone.

### Click-per-strike harvesting

- Changed resource harvesting from held progress to one damage strike per left-click.
- Preserved tool requirements, typed damage, durability wear, skill rewards, drops, depletion, and regrowth.
- Added immediate tool-swing feedback for successful harvesting clicks.

### Health and typed damage foundation

- Replaced resource harvest counts with reusable health, damage, depletion, and recovery state.
- Added exported melee damage, tool damage, and effective material tags to item definitions; the stone axe starts at 30 wood tool damage and the pickaxe at 60 stone tool damage.
- Set trees to 150 HP, stone nodes to 300 HP, and current wood buildables to 200 HP.
- Added material-aware tool attacks, universal tool melee fallback, visible damage bars, destructible structures, and health restoration for regrowing resources.

## Milestone 7 — First base-building vertical slice

- Added a validated, data-driven catalog for wood floors, wood walls, doors, storage, campfires, and sleeping spots.
- Added a `B` build palette, grid-snapped green/red placement preview, material checks, per-site cost deduction, and continuous placement.
- Added held construction with visible progress and functional completed structures: collision, opening doors, container storage, campfire crafting/light, and resting.

### Drag-and-drop inventory

- Added direct inventory slot dragging for moves, merges, swaps, and player/container transfers.
- Replaced click-plus-number hotbar assignment with dragging tools and weapons onto visible hotbar slots.
- Added right-click clearing for hotbar assignments while preserving number-key item selection during play.

### Hotbar-driven held-item mode

- Removed the separate `R` combat-mode input.
- Selecting a weapon-capable hotbar item now readies it; selecting the active slot again or an empty slot holsters it.
- Tool clicks remain contextual: valid work targets use the equipped tool, while weapon clicks away from a work target attack.

### Optional world-object labels

- Made resource name/status labels, container titles, and workstation name labels optional presentation nodes.
- Kept harvesting, connected stone rendering, storage, crafting, and campfire lighting functional when floating labels are removed.
- Updated integration tests to tolerate resource nodes organized inside editor folders and custom map layouts.

## Unreleased

### Held utility actions and combat stance

- Added holstered and combat-ready player modes toggled with R, with an on-screen state readout and raised fists/equipped-tool attack feedback.
- Routed left click to utility interactions while holstered and to a reusable attack signal while combat-ready.
- Changed harvesting to advance only while left click remains held; releasing, leaving range, losing the required tool, or drawing a weapon cancels progress.
- Added a shared continuous-interaction contract for future construction and repair actions, and moved rest/wake to T.

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

### Tilebase terrain variations and blending

- Converted the five large Tilebase textures into reproducible 32×32 atlases with eight variations per terrain.
- Added walkable sand, retained blocked deep-water collision, and painted a sand band around the starter shoreline.
- Added deterministic runtime variation and reusable terrain-painting helpers.
- Added soft priority-based transitions from deep water through shallow water, sand, grassy dirt, and grass.

### Automatic seamless terrain edges

- Made every direct TileMap change automatically refresh deterministic variations and edge blending in both editor-authored and generated maps.
- Changed blend textures to sample the matching opposite edge of each neighbor at full boundary opacity.
- Added equal crossfades between visual variations of the same terrain, removing the need for manually painted transition tiles.

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
