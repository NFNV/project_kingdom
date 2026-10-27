# Equipment and Emberforge chapter

Baseline: `ab28c19` (the original quest/inventory/save integration). GLoot 3.0.2
and Questify 1.6.0 remain pinned and unmodified; see `addons.lock.json`.

## Play and equipment

Run the project with F5 or launch `Play Garden Square.command` for New Journey /
Continue. F6 runs whichever scene is currently open in the editor.

I opens a parchment equipment screen with a base cat illustration, seven
labelled slots and 24 backpack cells. Helmet, chest, pants, gloves, boots, weapon
and charm each have a separate item image and a real GLoot ItemSlot. Click to
inspect and compare, double-click to equip/use, or drag gear between the bag and
its matching slot. Swapping returns the previous item to the bag. Food and quest
items cannot enter equipment slots. Opening inventory or J's journal pauses the
world and blocks combat input.

Starter shirt, trousers, gloves, boots and sword persist independently. Gear
ownership is unique; purchases and rewards cannot duplicate it. Removing health
gear clamps current health. Removing the weapon disables both sword attacks and
Wind Slash until another weapon is equipped.

| Item | Slot | Effect | Source |
|---|---|---|---|
| Scout leather cap | Helmet | +1 maximum heart | Tomas, 8 coins |
| Emberguard vest | Chest | +2 maximum hearts | Tomas, 12 coins |
| Pathfinder boots | Boots | +10% walk/run speed | Tomas, 10 coins |
| Windfeather charm | Charm | Wind Slash recharge 6 → 4.5 seconds | Tomas, 12 coins |
| Warden's charm | Charm | +1 maximum heart | Bram's bounty |
| Embersteel sword | Weapon | Normal damage 1 → 2; Wind Slash 3 → 4 | Stolen-tools reward |

Projectile damage is captured when cast. Changing weapons while a wave flies
does not change that wave's damage. Starter clothing without bonuses still
occupies and saves its individual slot. Maximum current outfit health is nine
hearts; both charms cannot be worn together.

The paper-doll portrait is a fixed base illustration. Slot icons and gameplay
stats change; equipping gear does not yet replace the portrait's clothing or the
animated world sprite. A cosmetic outfit pipeline remains future work.

## Workshop, quest and journal

Garden Square's northern exit leads to Northgate. Emberforge replaces the former
bookshop's shop role on Market Lane, retaining the existing footprint and town
building counts. Its entrance requires E near the doorstep, so walking along the
sidewalk does not enter accidentally. Inside are authored stone floors, brick
walls, furniture collision, an anvil, sword rack, animated hearth and counter.
Tomas stands behind the counter and faces the player. The outdoor resident with
stable ID `tomas` is now Nico, the smith's apprentice; existing IDs remain valid.

Tomas accepts The stolen tools. Rook replaces the existing southeast camp
mauler (`wild_dog_3_2`), keeping Briarwood's population at twelve. Rook has eight
health and a two-heart sweep, with a 1.25-second warning and longer recovery.
Collect his pouch, then return the hammer and tongs for twelve coins and the
Embersteel sword. Ordinary badges still drop. Previously defeated Rook can yield
the tools without respawning or blocking the quest.

The new graph `data/emberforge_tools.tres` runs through Questify on events, beside
Bram's existing graph. J shows all three quests, completion checks, routes and
rewards. Tracking a card changes both the HUD text and world guide marker.

## Persistence and title flow

`save_store.gd` writes schema 2. `save_v1.gd` retains the strict schema-1 validator
for migration. Both manual and autosave slots use temporary-file validation,
atomic replacement and a previous validated backup. The manual slot is
`user://kingdom_journey.json`; the autosave has `.auto` appended. A high-resolution
`saved_at` stamp determines the newest validated slot, even within one second.

Schema 2 adds all seven equipment IDs, additional inventory quantities, smith
quest state, tracked quest and the forge location. Ownership, compatible slots,
unique items, reward flags and badge/tool conservation are checked before any
live state changes. Unsupported future schemas are rejected. Valid schema-1
saves receive starter clothing and retain money, quests and weapon/charm state.
An already collected captain pouch supplies the tools during migration; an
uncollected pouch keeps them in the world. Reading does not rewrite the old file.

Travel, quest milestones, purchases, item use and equipment changes queue an
autosave after a 0.7-second debounce. Saving waits for transitions/swings to end,
a living player and no alerted bandit within 500 ground units. F5 remains manual
save; F9 loads the newest valid slot. The Esc menu and R can save and return to
title. New Journey confirms if a save exists, begins a fresh autosave, and keeps
the last manual slot. The title suspends the background game and blocks world
input. `-- --continue` can resume automatically. Tests use isolated `/tmp` slots.

## Art and runtime cost

Sixteen transparent PNGs were created with built-in imagegen: the character,
twelve equipment/quest icons and three workshop props. Exact prompts, original
paths, alpha information and hashes are in
[generation.json](assets/equipment/generation.json). Original generated PNGs are
preserved byte-for-byte. Seven empty-slot SVG silhouettes are native UI assets.
[Asset QA](assets/equipment/qa_report.json) checks the original copies, alpha,
SVG XML and all sixteen item icon references.

Godot caches mipmapped 256px item textures and a larger portrait; furnishing
textures use measured alpha bounds. Runtime transformations preserve the source
PNGs. Hearth particles originate at a measured coal anchor. No generation,
filesystem search or texture decoding runs each frame.

## Verification

[Combined results](equipment_results.json): **847/847** checks across eleven
suites. The 127 new checks exercise physical connected travel, real counter and
shop buttons, two active Questify quests, actual captain combat and pickup,
real pointer drag/drop, comparisons and derived combat/movement effects,
journal tracking, seven-slot persistence, title flow, safe autosaves and old-save
migration. An additional focused process verified `--continue` starts the title
flow without leaving gameplay suspended. Native previews are in `previews/`.

[Foreground performance](equipment_performance.json): Godot 4.7.2 / Apple M1 /
Metal / CoreAudio, 1920×1080 internal canvas in the normal 1280×720 window. Seven
four-second samples after warmup were 100% focused, averaging 60 FPS across town,
bakery, forge, district, forest day/night and the inventory. Six forest frames
exceeded 20ms, worst 21.11ms. First inventory open took 25.08ms. These short
steady-state samples exclude scene loading and do not establish locked 60 FPS.
The inventory sample includes item selection while the world is paused.

Godot exit logs still report retained addon/global resources during teardown;
the application-level runtime and suite assertions pass. This chapter does not
claim to fix that pre-existing teardown warning.
