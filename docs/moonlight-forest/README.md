# Moonlight Forest

Playable expansion for the Greenshire. The forest is the first dungeon, with its own encounters, route choice, and shortcut. The ruined castle stands at the far end. Its courtyard opens into the castle’s lower passages: descend the entrance staircase, follow the lower vaulted corridor, then climb the far staircase into the Undercroft.

[Route blueprint](blueprint.svg) · [Overhead blockouts](blockouts.svg) · [Forest and castle sketch](forest-reveal.png) · [Cistern sketch](cistern.png)

The entrance sits at the marked woodland location, just north of Ivykeep and west of the main northern road, at regional coordinates `(-50, 385)`. A short branching trail leads to the threshold. Press **F** nearby to enter on foot. The southern forest trail returns to the same location on the mounted overworld.

The threshold has a dedicated painted woodland arch with lanterns. Its shallow ground footprint is independent of the trees' height, so the curved horizon reveals it from roughly twice the previous approach distance. Its size grows with rider proximity from both front and side approaches, with a smooth near-distance size limit.

Inside, the forest, castle passages, Undercroft and Root Chapel each use nine overlapping detail paintings at the existing follow-camera distance. Each covers 1152 × 648 world units with a native image around 1672 × 941 pixels, reducing magnification at 2560 × 1440 from about 3.7× to 1.38×. The same paintings appear in the placement editor. Undercroft water animation uses room coordinates so ripples stay continuous across the overlapping panels, while the stone rim remains fixed.

Root Chapel has registered closed and open door paintings in the same stone arch. The eastern winch changes the painting and removes the doorway blocker together. The saved winch state restores the open doors on subsequent visits and after loading a journey. The closed doors also appear in the Undercroft placement preview.

Native QHD previews: [distant entrance](entrance-distant.png) · [closed chapel doors](chapel-closed.png) · [open chapel doors](chapel-open.png) · [Root Chapel floor without the ladder](root-chapel-floor.png). [Root Chapel artwork detail](root-chapel-detail.png).

Castle passage previews: [full layout](castle-passage-overview.png) · [entrance descent](castle-passage-descent.png) · [open lower landing](castle-passage-landing.png) · [lower corridor](castle-passage-corridor.png) · [staircase up to the Undercroft](castle-passage-ascent.png).

The castle facade and rear are solid. Its forest-facing entrance uses `castle_straight_stairs.png`: one centered, straight flight matching the interior direction. Both passage stair railings and their projected support faces are solid, so the player cannot stand over the painted pillars. Navigation and old-save recovery use the same blockers. Native QHD checks: [Undercroft stair support](stair-support-undercroft.png) · [entrance stair support](stair-support-entrance.png) · [straight castle entrance](castle-straight-entrance.png). Use the stair interaction in front of the arch to descend. Loading a save from the former gap inside the castle restores the character to the front approach.

The playable version uses four connected maps. Moonlight Forest contains the camp, patrol clearings, creek crossings, moonwell and castle courtyard. Castle Lower Passages joins two enclosed stair flights with a lower eastbound corridor. Entering the castle continues north down the western flight, with the courtyard return threshold behind the player to the south. The lower landing opens east around the stair parapet; the separate eastern staircase climbs north into the Undercroft. The entrance contains stone steps and masonry rather than a second outdoor forest view. Arrival facing and exit arrows follow these directions, and old saves from the former upper-left entrance recover to a safe landing. Both connections support return travel, and the passage can be saved mid-stair. The Undercroft contains the Entry Hall, cistern and winch. Root Chapel contains its guard encounter and the Sealed Vault keeper and chest.

**E** interacts, **Space / left click** strikes, **Q** casts Wind Slash, **F** guards or parries, and **V / Ctrl** rolls. Resting at Lantern Camp or Entry Hall restores health and sets the defeat checkpoint. The castle-side wicket opens a return shortcut. Root Chapel returns through its existing southern entrance; the floating ladder and its interactions have been removed. The old ladder-progress flag remains accepted in existing saves. The eastern winch opens the chapel doors. Defeated enemies, opened shortcuts, checkpoint and claimed caches are saved with the existing journey.

This pass reuses the existing dog bandits and treasure chest. The Moonbound Keeper has 22 health and uses the heavy bandit's attacks. The moonwell cache awards 15 coins and two healing draughts. The vault chest awards 100 coins and three draughts. Each cache is collected once per journey.

## Editing the placements

Open [the dungeon placement scene](../../experiments/anime_hub_demo_v07/assets/moonlight/layout.tscn) in Godot's 2D editor. Choose a room using the root node's `Preview Zone` property. Drag the markers for trees, enemies, camp, moonwell, winch and treasure over the room painting. Walking boundaries, water collision and passages are authored in [moonlight_forest.gd](../../experiments/anime_hub_demo_v07/tools/moonlight_forest.gd). The regional trail and its trees and lamps are in [moonlight_approach.tscn](../../experiments/overworld_2d_v01/moonlight_approach.tscn).

The original route and blockout sketches below predate the added castle passage. The current route is Moonlight Forest → Castle Lower Passages → Undercroft → Root Chapel.

## 01–06 · Moonlight Forest

| ID | Area | What the player does |
| --- | --- | --- |
| 01 | Forest Threshold | Enter at the marked woodland location or return to it. |
| 02 | Lantern Camp | Rest at the forest checkpoint. Spot a barred wicket at the side of camp. |
| 03 | Split Willow Glade | Fight the first small group of enemies in an open clearing. Pick a route after the fight. |
| 04 | Creek Crossing | Take the main route over a stone footbridge into a wider encounter space. |
| 05 | Moonwell | Take the optional creekside route and find a reward in a quiet alcove. Stepping stones lead onward to the same courtyard. |
| 06 | Ruined Castle | Reach the courtyard, open the wicket back to camp from this side, and enter the lower passages through the lit arch. |

Use the split willow and the castle towers as landmarks. The first full view of the castle comes across the creek. Keep walking paths clear of the darker foreground branches. The forest should be accessible at any hour, with cool light beneath the canopy as its visual signature.

## 07–11 · The Undercroft

| ID | Area | What the player does |
| --- | --- | --- |
| 06b | Castle Lower Passages | Descend from the forest gate, follow the lantern-lit lower corridor, then climb the separate far staircase into the Undercroft. |
| 07 | Entry Hall | Arrive from the upper passage stairs and reach a second checkpoint. The return stairs remain accessible from the dry western aisle. |
| 08 | Flooded Cistern | Follow a wide, dry ledge around the water. Spot the closed chapel doors before turning into the winch room. |
| 09 | Winch Room | Open the doors, then return to the cistern and cross into the chapel. |
| 10 | Root Chapel | Fight a second encounter. The southern entrance leads back to the Undercroft. |
| 11 | Sealed Vault | Fight the dungeon boss and claim the reward. Return through the chapel entrance and castle stairs. |

Use the same raised three-quarter view in both dungeons. In the cistern, keep the rim and every walkable ledge readable against the water. Let warm lanterns mark the stairs, winch, and gates. Keep the chapel doors visible from the cistern so operating the winch has a clear result.

The route blueprint shows connections and encounter spaces. The overhead plans show initial footprints for the glade and cistern. The grid gives relative proportions for laying out the walking bounds and obstacles in Godot. The castle passage’s collision outline follows the painted stair widths, parapets and lower corridor. The native follow-camera view is used for checking the final artwork’s detail.


## Artwork and verification

New background paintings, the castle cutout and winch are stored with the [dungeon assets](../../experiments/anime_hub_demo_v07/assets/moonlight/). The [generation manifest](../../experiments/anime_hub_demo_v07/assets/moonlight/generation.json) records the prompts and built-in image-generation provenance.

[The integration check](../../experiments/anime_hub_demo_v07/tools/test_moonlight.gd) exercises the normal town-to-overworld transition, forest entry, physical movement through the crossings, both castle stair flights, the lower corridor and around the cistern, combat and damage, locked passage, castle shortcut, chapel return travel, defeat recovery, one-time rewards, save/load, old-save compatibility and return to the marked location. It uses an isolated save under `/tmp`.

The latest native 2560 × 1440 run passed 136 dungeon checks with no script errors. These cover the new castle passage and its HUD, detail density in all four maps, northward entrance continuity, arrival facing, physical descent and ascent, both return connections, saving and loading on the stairs, recovery from the former entrance location, solid central and outer walls, collision across both stair railings and their complete painted support faces, walking/rolling attempts against the reported pillars, safe click-to-move targets and recovery of saves on the old walkable pillars, distant forest entrance visibility and approach scaling, chapel door states and collision, retired ladder-save compatibility, combat, loot, checkpoint recovery and the complete return journey. The prior existing journey suite passed 99/99 checks. Godot reported its existing shutdown resource-cleanup warnings.
