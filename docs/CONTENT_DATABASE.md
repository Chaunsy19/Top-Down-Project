# Content Database editor

The enabled **Content Database** dock is on the left side of the Godot editor. If it is absent, enable **Content Database** in Project > Project Settings > Plugins, or reopen the project.

1. Select Items, Buildings, Resource nodes, Recipes, Workstations, or Skills.
2. Search by ID, display name, category, or tags. Select a result to edit its properties in Godot's Inspector.
3. Click **Save** in the dock to validate the record, save it, and rebuild that type's catalog. The status box lists validation errors.
4. **New** asks for a unique lowercase ID and creates a draft file. Fill required fields in the Inspector and save. Invalid drafts are kept out of the rebuilt catalog until corrected.
5. **Duplicate** copies the selected record with a new ID and name. Referenced resources remain shared: make a referenced profile/resource unique in the Inspector before modifying it for the copy.
6. **Remove** checks text resource, scene, and script references, then asks to move an unused file to the Recycle Bin. Resolve listed references first. This check is conservative and cannot prove the absence of dynamically constructed IDs.
7. **Refresh** rescans the list. **Rebuild catalog** validates and includes all definitions of this type found recursively under its data folder. Use it after adding files outside the panel. Catalog generation is explicit, so unfinished drafts do not silently change game content.

Keep IDs stable; the dock rejects ID changes on Save. Names and descriptions can change freely. Godot's Inspector remains the property editor, including its resource pickers, textures, arrays, and nested resources. Save external linked resources using Godot's normal resource Save action after editing them. Changes made through the Inspector use Godot's normal editing behavior; the dock itself does not add undo for file creation/removal. Deleted files can be recovered from the Recycle Bin and catalogs rebuilt.

## Skills

Skill definitions now live under `data/skills/`. Edit display name, description, icon, and default starting level through this dock. The current Foraging, Forestry, and Mining IDs are retained. Actor-specific starting levels override defaults. XP accumulation is unchanged; automatic level progression is not implemented by this editor work. Resource-node skill IDs should match these definitions.

## Extending the panel

`addons/content_database/content_store.gd` contains the `TYPES` table. Each row defines the label, data folder, definition script, catalog filename, catalog array property, and ID property. New Resource types can reuse the same dock by adding a row, a catalog, and an editor-safe definition script exposing `display_name` and `validate()`. Definition/validation scripts use `@tool` so their validation methods work in the editor as well as in the game.

## Verification

Run `godot --headless --path . --script res://tests/content_database_test.gd`. Also tested: editor plugin loading, smoke, crafting, building, and armor suites.

Manual check: select and duplicate an item with a new ID; change its name and save; find it by search; verify its catalog entry. Try removing Wood and inspect the blocked-reference list. Remove the unused duplicate and verify the file is in the Recycle Bin and absent from the catalog. Repeat with a building. Change a skill's display name and inspect a resource node's debug text in-game.
