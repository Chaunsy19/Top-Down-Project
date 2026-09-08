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

The current test scene contains a directly controlled player in a grid-backed, collision-backed room. Move with **WASD** or the arrow keys, press **E** to interact or collect drops, and press **I** to open the player inventory. The supply crate opens a paired container/inventory view. Harvested items now enter the same pickup, inventory, transfer, and drop lifecycle.

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

Tool requirements use capability tags rather than specific item IDs. A resource node lists required tags and a minimum tier; a tool profile lists the capabilities it satisfies, its tier, work-speed multiplier, and maximum durability. Until equipment is introduced in Milestone 5, a compatible tool anywhere in the actor's inventory is selected automatically.

Add a definition file, reference it from the matching catalog, then instantiate the generic scene. New resource types should not require a new behavior script unless they truly behave differently.

## Inventory controls

- Click a populated slot, then another slot, to move, merge, or swap stacks.
- Right-click a stack to split it into the first empty slot.
- With a container open, Shift-click or double-click a stack to transfer it.
- Select a player stack and use **Drop selected** to place it in the world.
- The player inventory footer reserves space for future currencies; currency state is not implemented yet.
- Press **Escape** to close the topmost open modal UI. With no modal open, Escape intentionally does nothing until the pause menu is implemented.

## Automated checks

From the project directory, run the smoke and movement suites with the Godot executable:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/milestone_1_test.gd
godot --headless --path . --script res://tests/milestone_2_test.gd
godot --headless --path . --script res://tests/milestone_3_test.gd
godot --headless --path . --script res://tests/milestone_4_test.gd
godot --headless --path . --script res://tests/tool_requirement_test.gd
```
