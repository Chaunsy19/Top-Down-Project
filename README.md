# Frontier Hearth

A top-down 2D survival and settlement game built with Godot 4. The player directly controls one survivor; recruited settlers will eventually work autonomously through jobs and priorities.

The complete development roadmap is maintained in `Project Basis/rimworld_style_survival_codex_plan.md`. Work proceeds one milestone at a time, and every completed milestone must leave the project runnable.

## Requirements

- Godot 4.7 or a compatible Godot 4.x release

No third-party plugins or dependencies are currently required.

## Run the project

1. Open Godot Project Manager.
2. Import this folder's `project.godot`.
3. Open the project and press **F6** for the current scene or **F5** for the main scene.

The current foundation scene displays a grid-backed test room. Press **F3** to toggle the debug overlay.

## Project structure

- `scenes/` — reusable scenes and runnable levels
- `scripts/` — GDScript grouped by system
- `data/` — data-driven game definitions and resources
- `ui/` — interface scenes, themes, and assets
- `art/` — original and placeholder visual assets
- `audio/` — music and sound effects
- `tests/` — automated and manual test material
- `saves/` — development fixtures only; runtime saves use `user://`
- `Project Basis/` — project vision and milestone roadmap

## Development rules

- Implement and verify one roadmap milestone at a time.
- Preserve working behavior and avoid unrelated rewrites.
- Prefer modular, data-driven systems.
- Update `CHANGELOG.md` when completing a milestone.
- Record automated checks and a manual test procedure with each milestone.
- Commit each completed milestone with a descriptive message.

## Inputs reserved by the foundation

| Action | Default input |
| --- | --- |
| Move | WASD or arrow keys |
| Interact | E |
| Inventory | I |
| Crafting | C |
| Building | B |
| Attack | Left mouse button |
| Pause | P |
| Camera zoom | Mouse wheel |
| Camera reset | F |
| Debug overlay | F3 |

