# Mosswood — 2D overworld prototype

A playable overworld connected to Garden Square, with a curved-world camera, mounted protagonist,
compact city scale and a larger painted region. Branch:
`codex/overworld-2d-prototype`, based on gameplay commit `8e9efdb`.

In the main RPG, walk through **Garden Square’s southwest exit**, labelled
**The Greenshire**, or approach it and press **E**. You leave town riding the
frog outside miniature Mosswood. Walk into its south gate, or press **F**
nearby, to return beside the same town exit. Inventory, equipment, quests, health
and clock remain in the existing live journey. The southeast forest route and
northern district route remain available.

**F5** while roaming saves that journey at a safe town-side checkpoint. Continue
returns to Garden Square’s southwest entrance; overworld roaming coordinates
are not persisted yet. Leaving town also writes this checkpoint when autosaving
is enabled. The existing save format is unchanged.

For a standalone artwork/camera preview, double-click **Play Overworld.command**, or open `world.tscn` in Godot and use
**Run Current Scene / F6**. Project Run / F5 opens the original RPG.

| Control | Action |
|---|---|
| WASD / arrows | Roam relative to the camera |
| Q / E | Rotate the camera |
| Home | Restore north-facing view |
| Shift | Faster frog hops |
| M | Open / close the larger regional map |
| Tab | Toggle minimap |
| 1–8 | Preview meadow, bridge, forest, Mosswood, windmill, lake, ruins, coast |
| F | Enter Garden Square near its gate when linked; otherwise inspect a place |
| F5 | Save the linked journey at the town-side checkpoint |
| Esc | Close map, or pause / resume roaming |
| C | Compare curved and flat projection |
| [ / ] | Adjust curvature |
| G | Ground alignment grid |
| R | Return to the starting meadow |
| F3 | FPS, scenery count and coordinates |
| F4 | Live enlarged mounted hop study |
| F11 | Full screen |

## The Greenshire

Mosswood is now a compact walled city: the whole skyline is visible together,
including Clock Hall, the market awnings, cottages, gardens and fountain. Its
walls and roofs change appearance as the camera rotates.

The region is **480 × 560 units**, **3.64 times** the previous area. Follow the
road north through Riverbend's timber bridge. Branch west to Windsong Ridge and
Ivykeep Ruins, or east to Willowmere Lake and Palestone Coast. The branches form
an interconnected route network. Roads stay clear of random scenery, and water
blocks walking except at the bridge.

There are **1,494 scenery objects**. Four new painted cutouts provide the
windmill, ruins, fir grove and limestone rocks. Elms and willows reuse the main
game's painted art. The runtime caches cropped, mipmapped textures without
altering original PNGs. Native drawings still supply the city, bushes and sky.
[Region details and artwork manifest](REGION.md).

The north-up regional map shows roads, water, vegetation areas, eight places and
a player/view marker. The world pauses and stops rendering behind the opaque
map. Destination keys are development previews, not unlocked fast travel.

## Mount and camera

The cat rides a layered, eight-direction frog with crouch, takeoff, tuck, landing
and recovery. Rider lag, scarf and tail add secondary motion. The actual main
character's eight head drawings are reused with a matching cream shirt, brown
vest, red scarf, olive trousers, backpack and pale tail tip. Original main-game
art is untouched. Front and diagonal frog anatomy uses rounded cheeks and short
bent forelegs. Turning preserves hop phase; stopping retains the last direction
and settles to idle. **F4** opens a live close-up.

Everything uses the **2D canvas**, with no Node3D objects or 3D physics. Logical
positions use two ground coordinates. The camera rotates a pair of basis vectors
shared by perspective projection, the inverse ground shader, depth sorting,
collision navigation and rider facing. The projected player anchor stays fixed.
A radial bend drops the horizon, and scenery leans along its local surface
normal. Default curvature is 0.0014, adjustable from 0.0003 to 0.003.

Painted scenery is camera-facing and does not expose new painted sides during
an orbit. The city uses height-aware canvas polygons. Scenery drawing thins and
fades in the distance in flat mode; collision remains present. A spatial grid
keeps nearby collision checks independent of the whole region's object count.

## Verification and limits

`test_overworld.gd` checks real keyboard input, all eight directions, hop timing,
pause, camera-relative movement, orbit alignment, projection round trips,
collisions, physical bridge and branch-road travel, city doors and framing,
water barriers and regional-map controls. Results are in `test_results.json`.
`test_town_link.gd` adds the title-launched round trip, real E/F/F5 input,
checkpoint validation, retained journey state, viewport/HUD/audio restoration
and existing southeast route. All 26 connection checks pass headlessly and in
the native rendered run; `town_link_results.json` records the latest result.
The existing overworld suite passes 130 checks, and the RPG journey suite passes
99 checks with deterministic `--fixed-fps 60` timing.

Route previews: [southwest exit](previews/travel_southwest_exit.png),
[overworld arrival](previews/travel_overworld_arrival.png),
[return gate prompt](previews/travel_city_gate_prompt.png),
[back in town](previews/travel_garden_square_return.png).

`profile_overworld.gd` measures native 1920×1080 rendering, focus, frame intervals
and draw calls. It supports `-- --stage=mosswood` for a bounded sample. A sample
requires at least 95% window focus to count as foreground evidence. The expanded
region's recent runs lost focus repeatedly, so they **do not verify the 1080p60
target**. Earlier reports and the pre-optimization run are retained for diagnosis.
Read `performance.json` and `PERFORMANCE.md` for the latest scope and limitations.

This is a prototype scale/layout and art pass. The city is still simplified
native artwork rather than finished painted architecture. Terrain heights,
cliff occlusion, overworld encounters and quest-map integration remain future work.
Garden Square is connected; the other region landmarks do not enter detailed
areas yet. Saves preserve the journey at the town-side checkpoint, rather than
the exact overworld coordinates. The main title scene remains the project entry.

Previews: [whole city](previews/miniature_mosswood.png),
[windmill](previews/windsong_ridge.png), [lake](previews/willowmere_lake.png),
[ruins](previews/ivykeep_ruins.png), [coast](previews/palestone_coast.png),
[regional map](previews/greenshire_map.png).

[Mount study](HOP_STUDY.md) · [Camera and city](CAMERA_AND_CITY.md)
