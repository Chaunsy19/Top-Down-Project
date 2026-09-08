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
