# Moonlight Guard · reusable art pack

Hand-painted grim canine soldiers and a dark mastiff captain for the castle dungeon. These are presentation scenes with no embedded AI, health, collision, loot or quest state, so an encounter can reuse them elsewhere without inheriting dungeon progression.

| Scene | Design | Default visual height |
| --- | --- | --- |
| `ashen_vanguard.tscn` | Grey mastiff infantry, sword and round crescent shield | 90 world units |
| `briar_spearman.tscn` | Lean sable dog, iron helmet, spear and worn tabard | 94 |
| `gloam_arbalist.tscn` | Hooded dark hound, crossbow and belt quiver | 87 |
| `blackthorn_captain.tscn` | Large black mastiff, thorn armor, plum cape and two-handed greatsword | 185 |

Each character has 32 native drawings: eight action poses in southeast, southwest, northeast and northwest views. Every direction supplies idle, a four-frame walk sequence using three drawings, attack, windup, strike, recovery and hurt animations. The boss uses four separate eight-pose sheets to retain more native detail at its larger size. The presentation scenes remain independent of combat. Matching `*_enemy.tscn` scenes now supply live combat using the same registered drawings.

Open `preview.tscn` in Godot and run the current scene with **F6**. Use **1–4** for idle/walk/attack/hurt, **Q/E** to turn, **N** for firefly day/night visibility, and **Space** to pause animation. The preview deliberately enlarges the characters for inspection.

To reuse a character, drag its `.tscn` into a scene. Set `Display Height`, `Facing` and `Action` in the Inspector, or call `play_action("attack", "nw")`. Its feet sit at the root origin. `*_frames.tres` are ordinary Godot SpriteFrames resources; AtlasTexture margins register frames to one canvas. The `*_catalog.json` files record source rectangles, foot registration and image hashes. The source PNGs remain unchanged. Rebuild resources with `python3 experiments/anime_hub_demo_v07/tools/register_moonlight_guard.py` from the repository root.

## Fireflies

`fireflies.tscn` is an independent 2D effect using the eight-frame painted `firefly_flutter.png` atlas. Drag it into a scene and set `Night Weight` to **1** to preview it. Adjust `Area`, `Amount`, `Insect Size` and `Pattern Seed`; these controls rebuild the placement immediately. Callers can provide an optional `boundary` polygon before adding it to the tree to keep spawn locations within a clearing. Drift and twinkling give the individual insects different timing. One MultiMesh batches the effect, with a maximum of 256 insects, and it is hidden with no transform updates in daylight.

The live game now supplies the night weight in Garden Square, Northgate, Mosswood, Riverbend, Briarwood, Windsong Mill Garden, Palestone Coast and Moonlight Forest. The mounted overworld uses the same effect over the visible ground, below its HUD; it hides on the regional map and during the separate boss arena. Indoor rooms have no outdoor firefly emitter. The drawn firefly is reusable in any other scene without a dependency on the journey state.

## Sources and checks

`generation.json` records every prompt, built-in image-generation source, refinement and final saved asset path. `blackthorn_captain.png` is the large concept reference; runtime boss views use the four directional atlases.

Native Godot preview: [the complete art set](../../../../docs/moonlight-forest/moonlight-guard-assets.png). Asset checks cover all animation resources, registered canvases, valid source regions, direction selection and day/night visibility across the outdoor areas and indoor rooms. The dungeon journey check also covers mounted-overworld visibility and hiding the effect on the regional map. Existing woodland bandits remain in the forest. Three new soldiers patrol the lower castle corridor; four guard the dry aisles around the Undercroft cistern. Root Chapel contains Blackthorn Captain and two sentries. Lower passage and Undercroft soldiers use a saved five-minute respawn cooldown; other ordinary soldiers stay defeated. The original `vault_keeper` ID records a previous boss victory, while Blackthorn respawns for each new chapel visit.

## Live combat scenes

Use `ashen_vanguard_enemy.tscn`, `briar_spearman_enemy.tscn`, `gloam_arbalist_enemy.tscn` or `blackthorn_captain_enemy.tscn` in a hub-backed encounter. Supply `hub`, `enemy = true`, a stable `resident_id`, `home` and optional `patrol` before adding to `hub.world`; register the actor in `hub.dogs`. Area code owns saved defeat state and loot, so a new area can use its own IDs and reward rules. For standalone art previews use the presentation scenes above.

The vanguard has 7 health and sword slashes/heavy sweeps with limited attack poise. The spearman has 5 health and a narrow, longer thrust that can be sidestepped. The arbalist has 5 health, maintains distance and fires a visible bolt after a locked aiming warning. Bolts stop on stonework, disappear after hitting, and use the player's existing roll, shield and parry damage handling. Blackthorn has 36 health, a 160-unit silhouette, and alternating slash, sweep and rushing lunge attacks. Its warnings lock the attack direction; heavy sweeps remove one heart, other strikes remove half a heart. Parries interrupt it, and Wind Slash works throughout all four Moonlight rooms.

Move encounter markers in `assets/moonlight/layout.tscn`: `passage_1–3`, `cistern_1–4`, `chapel_1–2` and `Keeper`. Blackthorn resets to full health and fresh attack state whenever Root Chapel is entered, including older saves with a recorded boss victory. Its chest appears only after defeating it during that visit. The vault reward remains one-time: 100 coins and three healing draughts; rematches reveal an already-looted chest after the reward has been claimed.

`tools/test_dungeon_encounters.gd` exercises actual crossbow and boss AI, damage in both directions, Wind Slash travel, attack contact windows, parry interruption, walkable patrols, chest rewards, boss rematches, one-time loot history and forest night/day visibility. Pass `-- --capture-encounters` to save native QHD previews under `/tmp`.

## Timed room encounters

The lower passages have three soldiers; the Undercroft has four. Each kill in either room sets that room's respawn deadline to five real-time minutes after the kill. Returning before the deadline preserves the current casualties. Entering after the deadline restores every soldier in that room with full health and fresh AI. Respawns are applied on entry, so enemies never reappear around a player who remains inside the room. The rooms have independent timers, persisted in journey saves; time spent outside the game also counts.

Older saves that permanently cleared these rooms are repopulated on their next entry. Other room defeats, the winch, checkpoints and one-time treasure rewards are preserved. `Moonlight.RESPAWN_SECONDS` controls the duration. `test_dungeon_respawn.gd` covers partial/full clears, cooldown persistence, expired resets, full-health AI resets, legacy saves and invalid timer metadata.

Moonlight Forest enables `Ground Glow = 0.45`, increases `Amount` to 240 and uses 10–17 unit insects. `firefly_ground_glow.gdshader` adds a soft, pulsing amber ground pool using the same MultiMesh transform buffer; its batch draws below actors and scenery. Other areas leave this optional glow disabled. Both batches follow `Night Weight`, and ambient animation updates independently of physics interpolation.
