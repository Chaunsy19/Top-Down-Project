# RimWorld-Style Survival Settlement Game

## Codex Development Plan

## 1. Project vision

Create a top-down 2D survival and settlement-building game inspired by the readable, compact art style and emergent survival-world feeling of RimWorld, while keeping the player experience fundamentally different:

- The player directly controls one character.
- The player explores, gathers resources, crafts, fights, builds, and survives.
- NPCs can eventually be recruited into the player's settlement.
- Recruited NPCs are AI-controlled. The player does not directly move them like party members.
- The player assigns priorities, jobs, areas, and settlement policies.
- NPCs perform useful work such as farming, cooking, hauling, crafting, construction, healing, and defense.
- The player and colonists have equipment, body-part health, injuries, illness, diseases, needs, and recovery systems.

The target is a game that starts as a focused solo survival experience and gradually grows into a living settlement simulation.

The project should be built in Godot 4 using small, testable milestones. Each milestone must leave the game in a runnable state.

## 2. High-level design pillars

### Direct character control

The player controls only the main character directly. NPCs may be selected and inspected, but their movement and work are handled by AI systems, job priorities, and task assignment.

### Readable top-down presentation

Use a compact, stylized top-down 2D presentation with simple, readable sprites and strong visual clarity. A 16x16-inspired art scale is a good starting point, but gameplay readability is more important than strict pixel dimensions.

Do not copy RimWorld's exact art, characters, interface, names, or assets. Use it only as a high-level reference for the presentation and settlement-survival atmosphere.

### Data-driven content

Items, recipes, buildings, weapons, diseases, jobs, equipment, and character traits should be defined as data rather than hard-coded wherever practical. Prefer Godot Resources or a similarly maintainable data format.

### Simulation before content volume

Build reusable systems before adding large numbers of items, enemies, buildings, or NPC types. One working axe, one resource node, one recipe, and one job are more valuable than twenty incomplete versions.

### Playable after every milestone

Every milestone should produce a playable build, a clear test procedure, and a short list of known limitations. Avoid adding several unrelated systems in one step.

## 3. Core gameplay loop

The intended long-term loop is:

1. Explore the surrounding world.
2. Find and harvest resources.
3. Return to a safe location.
4. Craft tools, weapons, food, medicine, and building materials.
5. Build and improve a settlement.
6. Manage hunger, health, temperature, fatigue, injuries, illness, and danger.
7. Encounter potential recruits and threats.
8. Recruit NPCs with different skills, traits, needs, and medical conditions.
9. Assign priorities and jobs to keep the settlement functioning.
10. Expand, survive events, and create an emergent story through simulation.

## 4. Scope guardrails for the first version

The following features should not be attempted early:

- Multiplayer or networking.
- Direct control of multiple characters.
- Complex procedural world generation before the core loop works.
- Large-scale faction diplomacy.
- Vehicles.
- Advanced fluid, electrical, or temperature simulation.
- Hundreds of items and recipes.
- Full quest, reputation, and narrative systems.
- Mod support.
- Large-scale combat before movement, health, and equipment are stable.

The first playable version should use a small handcrafted test map and a deliberately limited content set.

## 5. Recommended technical foundation

- Engine: Godot 4.x.
- View: top-down 2D.
- World: grid- or tile-based for building, resource placement, navigation, and job targeting.
- Player: `CharacterBody2D` or an equivalent dedicated movement controller.
- World objects: reusable scenes with data-driven definitions.
- UI: separate HUD, inventory, crafting, character, building, and inspection panels.
- Time: a centralized world clock rather than independent timers scattered across scenes.
- Saving: versioned save data from the beginning, even if only a small amount of state is saved initially.
- Testing: small automated tests for data, inventory, health, recipes, save/load, and task selection where practical.

Keep systems modular. A future colonist should reuse the same inventory, health, equipment, needs, movement, and interaction systems as the player where their behavior overlaps.

## 6. Milestone roadmap

Milestones are ordered from lower complexity to higher complexity. The size labels are relative implementation estimates:

- XS: very small foundation or isolated feature.
- S: small feature with limited integration.
- M: medium feature requiring multiple systems.
- L: large feature with significant interaction between systems.
- XL: advanced simulation or content layer.

### Milestone 0 — Project foundation and development rules

Size: XS

Create the Godot project and establish the folder structure, naming conventions, input actions, test scene, main scene, and basic documentation.

Deliverables:

- Godot project opens and runs.
- Main scene loads successfully.
- Basic folders exist for scenes, scripts, data, UI, art, audio, tests, and saves.
- Input actions are defined for movement, interaction, inventory, crafting, building, attack, pause, and camera controls.
- A short `README` explains how to run the project and how milestones should be handled.
- A debug overlay can display the current game state and frame rate.

Acceptance criteria:

- The project launches without errors.
- The test scene can be opened and played.
- Codex can make future changes without guessing the project's structure.

### Milestone 1 — Player movement and camera

Size: S

Implement a controllable player character in a simple test room.

Deliverables:

- Eight-direction or four-direction movement, chosen consistently.
- Acceleration or direct movement, but no jitter or diagonal speed advantage.
- Collision with walls and obstacles.
- Camera follows the player smoothly.
- Temporary placeholder character and environment art.
- Basic interaction range indicator or debug visualization.

Acceptance criteria:

- The player can move reliably for several minutes.
- The player cannot walk through collision objects.
- Movement code is isolated from later inventory, combat, and AI systems.

### Milestone 2 — Grid world and interactable objects

Size: S

Create the basic world representation used by gathering, building, navigation, and jobs.

Deliverables:

- Tile-based or grid-based world coordinates.
- Walkable and blocked cells.
- Interactable world objects.
- A reusable interaction system for approaching, checking, and using an object.
- Debug display for grid coordinates and object state.

Acceptance criteria:

- The player can interact with at least one test object.
- The same interaction interface can later be used for trees, rocks, workstations, doors, storage, and NPCs.

### Milestone 3 — Resource nodes and harvesting

Size: S

Add the first survival action: harvesting resources from the environment.

Initial content should be intentionally small:

- Tree producing wood.
- Rock producing stone.
- Berry bush producing food.

Deliverables:

- Resource nodes have quantities and states.
- Harvesting requires time or an action duration.
- Resource nodes can be depleted.
- Depleted nodes either respawn, regrow, or remain depleted according to data settings.
- Harvest feedback is visible and understandable.

Acceptance criteria:

- The player can harvest three resource types.
- Harvesting produces item data rather than directly modifying arbitrary counters.

### Milestone 4 — Item definitions and inventory

Size: M

Create the reusable item and inventory foundation.

Deliverables:

- Item definitions with IDs, names, icons, categories, stack limits, weight, and tags.
- Inventory with slots and stack splitting/combining.
- Item pickup and drop.
- Inventory UI.
- Weight or capacity limit, if included in the design.
- Notifications for collected, dropped, or failed item actions.

Acceptance criteria:

- Wood, stone, berries, and at least one tool can move through the full item lifecycle.
- Inventory state is not stored only in UI nodes.
- Item definitions are data-driven.

### Milestone 5 — Tools, gathering actions, and basic crafting

Size: M

Connect equipment and resource actions to a simple crafting system.

Initial content:

- Hand gathering.
- Stone axe.
- Basic pickaxe or equivalent.
- Campfire.
- Simple cooked food.

Deliverables:

- Tools have valid use categories and durability, if durability is desired.
- Recipes define ingredients, output, crafting time, and required workstation.
- Crafting UI shows requirements and results.
- The player can craft a tool and use it to improve or enable harvesting.
- Crafting fails clearly when requirements are not met.

Acceptance criteria:

- The player can harvest, craft, equip, use, and replace a tool.
- At least one recipe requires a workstation.

### Milestone 6 — World clock, needs, and basic survival pressure

Size: M

Introduce time and the first survival needs.

Deliverables:

- Centralized day/night clock.
- Pause and time-speed controls.
- Hunger.
- Thirst, if included in the intended survival tone.
- Fatigue or sleep.
- Basic health consequences when needs become critical.
- Simple day/night visual change.

Acceptance criteria:

- The player must eat and rest to remain effective.
- Time advances consistently across world systems.
- The game remains playable without requiring many UI panels.

### Milestone 7 — First base-building vertical slice

Size: M

Make the solo survival loop into a real playable prototype.

Initial buildables:

- Floor.
- Wall.
- Door.
- Storage container.
- Campfire or cooking station.
- Sleeping spot.

Deliverables:

- Building mode with a transparent placement preview.
- Valid and invalid placement feedback.
- Grid snapping.
- Construction cost deduction.
- Basic construction completion.
- Built objects have collision and usable interaction points.
- Storage can hold items.

Acceptance criteria:

- A new game can be started with no base.
- The player can gather materials and construct a functional shelter.
- The player can store food, cook, and sleep inside the shelter.

This milestone is the first major playable target. Stop and test the game here before adding NPC simulation.

### Milestone 8 — Equipment, weapons, and body-part health

Size: L

Add the character systems needed for meaningful danger and injury.

Body regions:

- Head.
- Chest.
- Left and right arms.
- Left and right legs.

Deliverables:

- Character stats separate overall health from body-part condition.
- Equipment slots for head, body, arms or hands, legs, and weapon/tool.
- Armor protection by body region.
- Basic weapon data and attack action.
- Injury records with severity, bleeding or impairment where appropriate.
- Movement and action penalties for serious injuries.
- Character health screen.

Acceptance criteria:

- The player can equip an item and see its effects.
- A test attack can damage a specific body region.
- Injuries affect gameplay in a clear but manageable way.
- The system is reusable by NPCs later.

### Milestone 9 — Basic hostile wildlife or enemy encounters

Size: M

Add one simple enemy to test combat, danger, and recovery.

Deliverables:

- Enemy detection and chase behavior.
- Basic attack behavior.
- Player attack and damage resolution.
- Death, loot, and despawn rules.
- Escape or disengagement behavior.
- Minimal combat feedback.

Acceptance criteria:

- The player can encounter, fight, survive, and recover from one enemy type.
- Combat does not require NPC colonists or a full faction system.

### Milestone 10 — Medical treatment and disease foundation

Size: M

Add sickness and treatment first for the player, while designing the system for future colonists.

Deliverables:

- Disease and condition data definitions.
- Symptoms such as fever, weakness, pain, reduced movement, or reduced work speed.
- Progression states: incubation, active, improving, recovered, or worsening.
- Medicine and treatment actions.
- Rest and recovery effects.
- Health panel showing injuries, conditions, severity, and treatment needs.

Acceptance criteria:

- The player can become sick through at least one controlled test.
- The player can treat the condition and observe recovery or deterioration.
- Conditions are data-driven and can later be attached to NPCs.

### Milestone 11 — Save and load

Size: M

Implement reliable persistence before the project becomes simulation-heavy.

Persist at minimum:

- World time.
- Player position and stats.
- Inventory and equipment.
- Resource node states.
- Built objects.
- Storage contents.
- Active conditions.

Deliverables:

- New game, save game, load game, and quit flow.
- At least three save slots or a clearly designed save policy.
- Save version number.
- Graceful handling of missing or invalid data.
- Debug save/load testing tools.

Acceptance criteria:

- The game can be closed and reopened without losing the tested state.
- Save data is not tightly coupled to scene instance IDs.

### Milestone 12 — Farming and food production

Size: M

Expand the settlement loop with renewable food.

Deliverables:

- Soil or farmland tiles.
- Planting.
- Growth stages.
- Watering or environmental requirements, if desired.
- Harvesting.
- Food spoilage, if desired.
- Seed items and a small number of crops.

Acceptance criteria:

- The player can establish a small renewable food source.
- Crop state survives saving and loading.
- Farming can later be performed by an AI job rather than being player-only.

### Milestone 13 — NPC data, recruitment, and follower behavior

Size: L

Introduce the first recruitable NPC without implementing the complete settlement simulation.

Deliverables:

- NPC character data.
- Skills or proficiencies.
- Traits or personality modifiers.
- Needs shared with the player where appropriate.
- Relationship or recruitment state.
- Recruitment interaction.
- NPC follows or travels to the settlement.
- NPC can be inspected but not directly controlled by the player.

Acceptance criteria:

- The player can meet and recruit one NPC.
- The NPC persists through saving and loading.
- The NPC can exist safely in the settlement without needing every future job system.

### Milestone 14 — Job, task, and priority system

Size: XL

Build the core AI system that allows colonists to help around the base.

Core concepts:

- Work types such as farming, cooking, hauling, crafting, construction, cleaning, healing, and guarding.
- Colonist work priorities.
- Job availability.
- Job reservation to prevent conflicts.
- Task execution and interruption.
- Pathfinding to targets.
- Failure handling when a target disappears or becomes inaccessible.
- Idle, eating, sleeping, social, and emergency behaviors.

Initial job order:

1. Hauling.
2. Construction.
3. Farming.
4. Cooking.
5. Crafting.

Deliverables:

- One colonist can automatically haul an item.
- One colonist can build a wall.
- One colonist can plant or harvest a crop.
- Player priorities affect job selection.
- Jobs do not deadlock the game when interrupted.

Acceptance criteria:

- The player can recruit a colonist and observe useful autonomous work.
- The player remains responsible for strategic decisions rather than manually moving every colonist.
- The AI is debuggable through visible job state, target, path, and reason for failure.

### Milestone 15 — Settlement production chain

Size: L

Connect jobs, storage, workstations, recipes, and stockpiles into a small functioning economy.

Deliverables:

- Stockpile zones or designated storage rules.
- Workstations with input and output behavior.
- Hauling priorities.
- Cooking chain from raw food to prepared meals.
- Crafting chain from raw materials to tools or equipment.
- Basic work orders such as maintain a quantity or craft a number of items.

Acceptance criteria:

- A colonist can move resources from the world to storage, use them at a workstation, and return the result to storage.
- The player can configure at least one production order.

### Milestone 16 — Colonist health, needs, equipment, and diseases

Size: XL

Extend player survival systems to recruitable NPCs.

Deliverables:

- Colonist hunger, fatigue, rest, and morale or mood.
- Colonist injuries using the same body regions as the player.
- Colonist equipment and armor.
- Colonist disease and treatment.
- Medical job.
- Bed assignment and recovery.
- Emergency behavior for severe injuries or illness.
- Colonist health and needs inspection panel.

Acceptance criteria:

- A colonist can become hungry, injured, or sick.
- A healthy colonist can identify and treat a sick or injured colonist when the required supplies exist.
- The player can understand why a colonist is not working.

### Milestone 17 — Social behavior, morale, and settlement events

Size: XL

Add the systems that make colonists feel like individuals rather than workers.

Possible features:

- Relationships.
- Conversations.
- Personal likes and dislikes.
- Mood modifiers.
- Recreation.
- Conflicts.
- Positive and negative settlement events.
- Colonist departure, breakdown, or refusal to work, if appropriate for the intended tone.

Acceptance criteria:

- At least two colonists can have different needs, traits, and reactions to the same settlement conditions.
- Events create interesting decisions without becoming a full narrative system.

### Milestone 18 — World expansion, exploration, and external threats

Size: XL

Expand beyond the initial settlement once the local simulation is reliable.

Potential features:

- Larger map or connected map regions.
- Points of interest.
- Wildlife and enemy variety.
- Weather.
- Seasons.
- Factions or nearby settlements.
- Trading.
- Raids or attacks.
- Exploration rewards.

Implement these as separate milestones rather than one large feature bundle.

### Milestone 19 — Content, balance, polish, and release preparation

Size: L/XL

Only after the core systems are stable, add content and improve presentation.

Deliverables:

- Consistent art pass.
- Sound effects and music.
- Better feedback for harvesting, crafting, combat, injury, illness, and jobs.
- Tutorial or onboarding.
- Balance pass.
- Performance profiling.
- Bug fixing.
- Accessibility options.
- Settings and key rebinding.
- Exported test builds.

## 7. Suggested first playable target

The first meaningful demo should end after Milestone 7, with the following loop:

- Move around a small map.
- Harvest wood, stone, and berries.
- Manage inventory.
- Craft a tool and cook food.
- Eat, sleep, and survive the passage of time.
- Build a small shelter with walls, a door, storage, a campfire, and a sleeping spot.
- Save and load the game.

Do not add recruitment before this loop is enjoyable and reliable.

## 8. Codex execution rules

Use the following rules when asking Codex to implement the project:

1. Work on one milestone at a time.
2. Before editing, inspect the existing project structure and current implementation.
3. Do not rewrite unrelated systems.
4. Do not silently expand the milestone's scope.
5. If a prerequisite is missing, implement the smallest prerequisite needed and explain it.
6. Prefer reusable systems and data-driven definitions over hard-coded one-off logic.
7. Keep placeholder art acceptable until the related system is proven.
8. Add or update tests and debug tools for important systems.
9. Run the project after each significant change.
10. Report changed files, implemented behavior, test results, and known limitations.
11. Do not claim a feature works without testing it in the running project.
12. Keep a short `CHANGELOG.md` or milestone log.
13. Commit each completed milestone with a descriptive commit message when version control is available.

## 9. Standard Codex milestone prompt

Copy and customize this prompt for each milestone:

```text
You are helping me build a Godot 4 top-down 2D survival settlement game.

The game is inspired by the readable top-down presentation and emergent settlement-survival systems of RimWorld, but the player directly controls only one character. Recruited NPCs will eventually be AI-controlled colonists who perform jobs around the settlement. Do not copy RimWorld assets or exact implementation details.

Project rules:
- Work only on the milestone below.
- Inspect the current project before making changes.
- Preserve working behavior from earlier milestones.
- Keep systems modular and data-driven.
- Use placeholder art where necessary.
- Do not add unrelated content or future systems unless they are a minimal prerequisite.
- Test the feature in the running Godot project.
- Report changed files, test results, known limitations, and a manual test procedure.

Current milestone:
[PASTE ONE MILESTONE HERE]

Before coding:
1. Summarize the current relevant architecture you found.
2. List the smallest implementation plan for this milestone.
3. Identify any assumptions or missing prerequisites.

After coding:
1. Run the project and test the milestone.
2. Fix errors caused by the implementation.
3. Summarize what works.
4. List changed files.
5. List known limitations and the next recommended milestone.
```

## 10. Definition of done for the overall project

The project is ready for a larger playtest when:

- A new player can understand how to move, gather, craft, build, eat, sleep, and survive.
- The player can establish a functioning base without manual editing or debug commands.
- NPCs can be recruited and perform useful autonomous work.
- Jobs can be interrupted and recovered from safely.
- The player and colonists can become injured or sick and receive understandable treatment.
- Equipment, body-part health, needs, inventory, buildings, and colonists persist through save/load.
- The game produces interesting choices without requiring the player to micromanage every action.
- The project can be extended with new items, recipes, buildings, diseases, jobs, and NPC traits without rewriting core systems.

The most important design principle is to make the solo survival loop enjoyable before attempting the full settlement simulation. The settlement layer should grow out of proven player systems instead of becoming a separate, fragile codebase.
