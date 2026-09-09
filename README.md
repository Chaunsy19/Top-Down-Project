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

The current test scene contains a directly controlled player on a grid-backed starter island. Move with **WASD** or the arrow keys, aim by moving the mouse, press **E** to interact or collect drops, **I** for inventory/equipment, **C** for hand crafting, **R** to rest or wake, and **P** to pause. Interact with the campfire to open workstation crafting.

The test world is a small editable island. See [`docs/MAP_DESIGN.md`](docs/MAP_DESIGN.md) for the terrain palette and map-painting workflow.

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
| Aim / face | Mouse |
| Interact | E |
| Inventory | I |
| Crafting | C |
| Rest / wake | R |
| Building | B |
| Attack | Left mouse button |
| Pause | P |
| Camera zoom | Mouse wheel |
| Camera reset | F |
| Debug overlay | F3 |
| Debug time jump | F4 |

## Content authoring

Gameplay content is defined in Godot Resource files rather than hard-coded into world scenes:

- `data/catalogs/item_category_catalog.tres` is the editable table of item categories.
- `data/catalogs/item_catalog.tres` is the table of all item definitions.
- `data/catalogs/resource_node_catalog.tres` is the table of all harvestable node definitions.
- `data/catalogs/recipe_catalog.tres` is the table of all crafting recipes.
- `data/catalogs/workstation_catalog.tres` is the table of all crafting workstations.
- `data/items/` contains individual item records with categories, stacking, weight, and presentation fields.
- `data/resource_nodes/` contains harvest duration, yields, skill requirements, XP, capacity, depletion behavior, and recovery settings.
- `data/recipes/` contains ingredients, outputs, durations, categories, and required workstation tags.
- `data/workstations/` contains reusable workstation identities and capability tags.

Tool requirements use capability tags rather than specific item IDs. A resource node lists required tags and a minimum tier; a tool profile lists the capabilities it satisfies, its tier, work-speed multiplier, and maximum durability. Each tool stack owns its current durability independently. Recipes and workstations use the same tag-oriented approach so new content can be added without creating one-off behavior scripts.

Add a definition file, reference it from the matching catalog, then instantiate the generic scene. New resource types should not require a new behavior script unless they truly behave differently.

## Tile-based world objects

- Blocking interactables snap to the center of a 32×32 world cell and register themselves as that cell's occupant.
- A cell can have only one blocking occupant, providing the placement rule future buildings, walls, doors, furniture, and blueprints will share.
- Mineable stone is represented by full-cell blocks. Cardinally adjacent blocks connect visually but remain individually targetable and mineable.
- Removing a stone block releases its grid cell and refreshes neighboring connections.

## Player aiming

- The player continuously faces the world position beneath the mouse, independently of movement direction.
- `PlayerController` exposes a normalized aim direction and angle for combat and tool actions.
- Attach held-item visuals and action origins to `AimPivot/ToolSocket` so they follow the same aim source.

## Inventory controls

- Click a populated slot, then another slot, to move, merge, or swap stacks.
- Right-click a stack to split it into the first empty slot.
- With a container open, Shift-click or double-click a stack to transfer it.
- Select a player stack and use **Drop selected** to place it in the world.
- Select a tool and choose **Equip selected** to place it in the hand slot; choose **Unequip** to return it to inventory.
- Select food and choose **Eat selected** to consume one item and restore hunger.
- The player inventory footer reserves space for future currencies; currency state is not implemented yet.
- Press **Escape** to close the topmost open modal UI. With no modal open, Escape intentionally does nothing until the pause menu is implemented.

## Crafting controls

- Press **C** to open hand crafting for the stone axe and stone pickaxe recipes.
- Interact with the campfire using **E** to access the cooked berry meal recipe.
- The recipe list shows whether each recipe is ready or locked; selecting one explains missing ingredients or workstation requirements.
- Crafting consumes ingredients when started and completes after its data-defined duration.
- Harvesting consumes one durability from the equipped tool. A tool at zero durability breaks and must be replaced.

## Time, needs, and lighting

- A full in-game day lasts 20 real-time minutes at one fixed speed. Pausing stops world time.
- Ambient light transitions continuously through dawn, daylight, dusk, and near-black night.
- Campfires use a soft radial falloff without hard-edged shadows and become more visually important as ambient light fades.
- Hunger and fatigue decline with game time. Food restores hunger; pressing **R** rests in place and restores fatigue.
- Critical hunger or fatigue damages health and reduces movement speed.
- Press **F4** during development to jump forward six hours and inspect lighting phases without changing normal gameplay speed.

## Automated checks

From the project directory, run the smoke and movement suites with the Godot executable:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/milestone_1_test.gd
godot --headless --path . --script res://tests/milestone_2_test.gd
godot --headless --path . --script res://tests/milestone_3_test.gd
godot --headless --path . --script res://tests/milestone_4_test.gd
godot --headless --path . --script res://tests/tool_requirement_test.gd
godot --headless --path . --script res://tests/milestone_5_test.gd
godot --headless --path . --script res://tests/grid_occupancy_test.gd
godot --headless --path . --script res://tests/milestone_6_test.gd
godot --headless --path . --script res://tests/player_aim_test.gd
godot --headless --path . --script res://tests/terrain_map_test.gd
```
