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

The current test scene contains a directly controlled player in a grid-backed, collision-backed room. Move with **WASD** or the arrow keys, approach the terminal or a resource node and press **E** to act, zoom with the mouse wheel, press **F** to reset the camera zoom, and press **F3** to toggle grid/object debug information. Harvested items appear as labeled world drops.

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

## Content authoring

Gameplay content is defined in Godot Resource files rather than hard-coded into world scenes:

- `data/catalogs/item_category_catalog.tres` is the editable table of item categories.
- `data/catalogs/item_catalog.tres` is the table of all item definitions.
- `data/catalogs/resource_node_catalog.tres` is the table of all harvestable node definitions.
- `data/items/` contains individual item records with categories, stacking, weight, and presentation fields.
- `data/resource_nodes/` contains harvest duration, yields, skill requirements, XP, capacity, depletion behavior, and recovery settings.

Add a definition file, reference it from the matching catalog, then instantiate the generic scene. New resource types should not require a new behavior script unless they truly behave differently.

## Automated checks

From the project directory, run the smoke and movement suites with the Godot executable:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/milestone_1_test.gd
godot --headless --path . --script res://tests/milestone_2_test.gd
godot --headless --path . --script res://tests/milestone_3_test.gd
```
