# Quest, inventory and save integration

Baseline: clean commit `f721f5f`, branch `codex/gameplay-foundation`.
`integration_baseline.json` preserves the prior 604-check reports; the hub's
255 checks also ran before integration. No existing local edits were present.

## Addons

| Dependency | Pinned version | Upstream | License |
|---|---|---|---|
| GLoot | 3.0.2 | https://github.com/peter-kish/gloot | MIT |
| Questify | 1.6.0 | https://github.com/TheWalruzz/godot-questify | MIT |

The complete addon directories are vendored at `res://addons/`, with original
licenses. GLoot's release archive omits its root LICENSE, so that file was
retrieved separately from the same tag. Runtime sources are unmodified.
`addons.lock.json` records release archive hashes. Both editor plugins are
enabled. Questify's runtime autoload is explicit in `project.godot` and periodic
polling is disabled; changes trigger quest updates directly.
Source-file hashes were checked against the pinned archives; regenerated
Godot texture-import metadata is excluded from that comparison.

`tools/test_addons.tscn` is the small isolated integration scene. Ten checks
exercise real GLoot stacks, limits, serialization and slot transfers, plus
Questify graph completion and serialization in Godot 4.7.2. The tests run as a
normal scene so the Questify autoload is registered before model compilation.
Dialogic is deliberately deferred until the gameplay loop has settled.

## State and stable IDs

`tools/game_state.gd` owns persistent data independently of world geometry:
money, town-delivery stage, forest quest, discoveries, defeated enemies,
uncollected loot, time, health, GLoot inventory and equipment. It is a child of
the persistent hub, so rebuilding any zone leaves state intact. Existing hub
properties delegate to this node. `hub.inventory` is a read-only count snapshot;
mutations go through `state.add_item`, `remove_item` or equipment methods.

`data/items.json` defines permanent item IDs: `bread`, `tea`, `honey`,
`bandit_badge`, `travel_sword`, `warden_charm`. GLoot stores actual stacks and
transfers equipped items into actual ItemSlot nodes; there is no parallel
authoritative inventory dictionary. The starting sword is equipped throughout;
the charm can be equipped and unequipped and changes maximum health.
One shared JSON prototype resource is reused across fresh journeys so GLoot's
resource-identity cache does not grow on each scene restart.

The quest ID is `briarwood_patrol`; its authorable Questify graph is
`data/briarwood_patrol.tres`. Node IDs use `briarwood.*` and survive presentation
changes. Its objectives are defeat three bandits, collect three badges and
return them to Bram. The existing `warden` resident ID identifies Bram.
Enemy IDs remain `wild_dog_<camp>_<member>`, with four camps of three. Drops use
the same enemy ID, and proximity interactions use `loot:<enemy ID>`.

Accepted/rewarded flags, the unique defeat set and actual inventory are the
canonical quest facts. Loading rebuilds the Questify graph from those facts;
the save never loads arbitrary resource paths or backend-internal graphs.
Reward flags are committed before inventory signals so repeated callbacks or
reloads cannot duplicate hand-ins. Quest resource graph cycles are broken on
teardown without modifying addon code.

## Save format and failure handling

One manual slot: `user://kingdom_journey.json`, plus `.bak` and a temporary
`.tmp` during writing. F5 and the Esc-menu Save button write it; F9 and Continue
load it. A new launch starts fresh unless the player chooses Continue/F9 or
passes `-- --continue`. R starts fresh in memory and leaves disk saves intact.
No tests or preview tools write the user's real slot.

`tools/save_store.gd` defines format `project_kingdom`, schema version **1**:

```text
format, version
state:
  coins, delivery_stage, clock, forest_recoveries
  discoveries[], district_places[], forest_defeated[]
  items: { permanent_item_id: quantity }
  equipment: { weapon, charm }
  quest: { accepted, rewarded }
  loot: { permanent_enemy_id: { position: [x, y] } }
player:
  zone, position[x,y], health, facing[x,y], skill_cooldown
```

All fields are validated before live data changes: required types, integer
quantities, finite ranges, known IDs, unique enemies, allowed zones, equipment
ownership and reward consistency. The number of defeated bandits must match
badges on the ground, in the bag or already handed in. Files are limited to
512 KiB. No objects or scripts are deserialized from saves.

Writing flushes and validates a temporary document, preserves a known-good
previous save, then renames the temporary file over the primary. A corrupt
primary can load the backup. Unsupported versions fail without changing live
state or silently downgrading to the backup. Future schema changes need an
explicit migration; version 1 is the first progress-save format.

The saved position is checked against rebuilt navigation. If it is blocked by
an NPC or changed geometry, loading uses a nearby valid navigation point or
the zone entrance. Active swings/projectiles/AI intent are transient and are
reset; health, facing and skill cooldown persist. Saving is blocked during an
attack, defeat or zone transition. Audio preferences are stored separately.

For a later exported build, include the JSON and WAV source data in the export
filters, since runtime loading uses FileAccess. Desktop editor/source runs are
the verified target of this integration.

## Verification

Existing gameplay/audio tests: **604 passing checks** after integration.
The ten isolated addon checks, 99 journey checks and seven separate-process
reload checks bring the total to **720/720**. Native foreground performance
averaged **59.8–60 FPS**, with all five samples 100% focused, a 1080p internal
canvas and a 1280×720 window on Apple M1. The worst retained interval was
52.75 ms in the night forest. Scene loading is outside these short steady-state
samples; this is not a locked-frame-rate or hardware-wide guarantee.
`tools/test_district.gd` now adds tea through the authoritative inventory API;
its persistence assertion and total count are unchanged.

- `addon_test_results.json`: isolated real addon APIs.
- `journey_test_results.json`: connected travel and actual E/Q/I/H/F5/F9 input,
  real projectile defeats, proximity pickups, purchases, healing, equipment,
  quest hand-in, save/load, corruption and invalid-schema rejection.
- `journey_relaunch_results.json`: a second process restores the first process's
  saved completed journey and cannot repeat its reward.
- The journey suite also saves/restores all six zones, repeats twelve loads
  without accumulating scene nodes, and creates twenty fresh states without
  growing GLoot's prototype cache.
- `journey_performance.json`: native focused 1080p internal rendering, with
  an active Questify quest, GLoot inventory, audio and full zone populations.
- `previews/journey_satchel.png`, `previews/journey_save_menu.png`: staged native
  UI screenshots from `tools/preview_journey.gd`, not gameplay-test evidence.
  `previews/journey_badge_pickup.png` shows the drop and proximity prompt.

The acceptance tests use `/tmp/kingdom-journey-test.json`. They fix three enemy
placements and pause AI for deterministic action/pickup and travel assertions;
the existing bandit suite separately verifies patrols, pursuit and attack types.
Native performance measurements keep all frame intervals and report actual
foreground focus rather than assuming a visible window was focused.

```sh
Godot --headless --path . res://experiments/anime_hub_demo_v07/tools/test_addons.tscn
Godot --headless --path . --fixed-fps 60 res://experiments/anime_hub_demo_v07/tools/test_journey.tscn
Godot --headless --path . --fixed-fps 60 res://experiments/anime_hub_demo_v07/tools/test_journey.tscn -- --verify-save
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/profile_journey.gd
```

Godot's headless shutdown still reports a small number of retained addon/global
resources; there are no script errors in the passing runs. These exit-time
warnings are distinct from bounded inventory, loot and audio ownership during
play. Longer sessions and packaged exports remain separate validation work.
