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
| WASD / arrows | Roam with the fixed north-facing camera |
| Shift | Faster frog hops |
| M | Open / close the larger regional map |
| T | Smoothly preview the next time of day |
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
whole silhouette uses one hand-painted map illustration, anchored at the south gate.
A soft contact shadow and small grass tufts blend its foundation into the terrain.
The redundant terrain plaza circle has been removed; the painting contains the plaza.

The region is **480 × 560 units**, **3.64 times** the previous area. Follow the
road north through Riverbend's timber bridge. Branch west to Windsong Ridge and
Ivykeep Ruins, or east to Willowmere Lake and Palestone Coast. The branches form
an interconnected route network. Roads stay clear of random scenery, and water
blocks walking except at the bridge.

There are **1,593 scenery objects**, including **136 placed buildings, stalls,
flowers, benches and lamps**. The windmill hamlet, roadside cottages, lakeside
shops, river watermill and coastal lighthouse use painted cutouts. Three matching
new house drawings replace the six earlier house appearances. Houses have smaller
footprints and screen-size limits to preserve the miniature scale. Two stalls,
flowers, benches and lamps reuse the main game’s artwork.
Elms and willows also reuse its painted art. The runtime caches cropped, mipmapped textures without
altering original PNGs. Small bushes retain native drawings.
[Region details and artwork manifest](REGION.md).

The north-up regional map shows roads, water, vegetation areas, eight places and
a player/view marker. The world pauses and stops rendering behind the opaque
map. Destination keys are development previews, not unlocked fast travel.

## Painted skies and shared day/night cycle

The complete cycle lasts **20 minutes**, using the same dawn/noon/dusk/night
phases as Garden Square. **T** smoothly previews the next phase. The celestial
sun-and-moon clock shows the time. Painted sky panoramas crossfade into a starry
night with subtle twinkling, a large hand-painted full moon, cool moonlight, warm windows and
lanterns, fireflies, a lighthouse beacon and water reflections. A new watercolor
sun is visible through daylight, and the large painted moon through the night.
Their gentle periodic sky paths keep both complete silhouettes above the ground
and clear of the title, clock and minimap. Exactly one drawing is shown: the sun
from 06:00 to 18:00, and the moon from 18:00 to 06:00. The moon is drawn at full
opacity with a brighter halo, including before sunrise. Sky and terrain lighting
still blend smoothly through twilight. The camera is locked north and follows the player; Q/E no
longer rotate it. The painting and star field remain stable; individual stars
twinkle, birds fly and chimney smoke moves gently. Pausing or opening the map
freezes the cycle.

When connected through Garden Square’s southwest gate, the overworld inherits
the journey’s time, advances it while roaming, saves it through the existing
checkpoint format and carries it back into town. Inventory, equipment and quest
state remain in the same journey. Updated native rendered previews:
[pre-dawn moon without a sun ghost](previews/grounded_before_dawn.png),
[dawn sun without a moon ghost](previews/grounded_dawn.png),
[grounded town gate](previews/grounded_city_gate.png),
[watermill approach](previews/grounded_watermill_approach.png),
[matching houses](previews/illustrated_hamlet.png).
Earlier region previews:
[day](previews/painted_hamlet_noon.png), [dusk](previews/painted_hamlet_dusk.png),
[night](previews/painted_hamlet_night.png),
[watermill](previews/painted_watermill_day.png),
[lighthouse at night](previews/painted_lighthouse_night.png).

New sky and landmark PNGs were created with **built-in imagegen**. Originals,
paths, prompts, dimensions and hashes are recorded in
[expansion_generation.json](art/region/expansion_generation.json).
[reuse_manifest.json](art/region/reuse_manifest.json) identifies reused originals.
The city and three matching houses were created with **built-in imagegen**;
[architecture generation manifest](art/architecture/generation.json) records their
full prompts, original paths, dimensions and hashes.
The moon is a separate transparent painting rendered at 380 pixels across at
1080p, with its original and prompt recorded in
[moon_generation.json](art/sky/moon_generation.json). The new sun is rendered at
230 pixels across, including its painted rays. Its original PNG, full prompt,
alpha bounds and hash are in [sun_generation.json](art/sky/sun_generation.json);
it was created with **built-in imagegen**.
The source images are preserved; cropping, mipmaps, tint and light blooms are
runtime rendering. The new houses and mills are scenery, not enterable shops.
Seventeen original paintings have individual trunk/foundation contact pixels in
[ground_contacts.json](art/ground_contacts.json). The texture cache converts those
original-image pixels into cropped UVs; a shared bottom-center anchor is no longer
used for these assets. Small contact shadows reinforce the roots and foundations.
Wide painted footprints are conservatively culled before they cross the dome's
horizon, with a short three-unit fade at that cutoff. This avoids suspended rear
corners; it can hide a distant building earlier than its center alone would require.

## Mount and camera

The cat rides a layered, eight-direction frog with crouch, takeoff, tuck, landing
and recovery. Rider lag, scarf and tail add secondary motion. The actual main
character's eight head drawings are reused with a matching cream shirt, brown
vest, red scarf, olive trousers, backpack and pale tail tip. Original main-game
art is untouched. Front and diagonal frog anatomy uses rounded cheeks and short
bent forelegs. Turning preserves hop phase; stopping retains the last direction
and settles to idle. **F4** opens a live close-up.

Everything uses the **2D canvas**, with no Node3D objects or 3D physics. Logical
positions use two ground coordinates. The camera tracks the player from a fixed
north-facing heading. Perspective projection, the inverse ground shader, depth
sorting, collision navigation and rider facing share that basis. Q/E and legacy
orbit callers cannot change the heading. The projected player anchor stays fixed.
A radial bend drops the horizon, and scenery leans along its local surface
normal. Default curvature is 0.0014, adjustable from 0.0003 to 0.003.

Painted scenery and the city each have one authored view, which is why camera
rotation is disabled. The old city polygon layout remains as collision data. Scenery drawing thins and
fades in the distance in flat mode; collision remains present. A spatial grid
keeps nearby collision checks independent of the whole region's object count.

## Verification and limits

`test_atmosphere.gd` adds **58 checks** for painted city rendering, house size
limits, exclusive day/night celestial selection, original-image ground contacts,
conservative footprint culling, sun/moon framing across all phases and HUD clearance, scenery,
lighting, twenty-minute
cycle, real T input, wraparound, pause, shared journey time, saved time and return
to town. `atmosphere_results.json` records the result.

`preview_ground_contacts.gd` adds **8 native GPU checks** at 05:08, dawn and both
sides of dusk: the active celestial drawing is bright and the inactive drawing
leaves no ghost pixels. It also renders the city gate, watermill and hamlet for
ground-contact review. Run without `--headless`; results are recorded in
`ground_contacts_render_results.json` and previews in `previews/grounded_*.png`.

The lower-level `test_sky_projection.gd` retains **7 native GPU checks** comparing rendered pixels
on the same world rays through camera turns, screen-edge perspective, full turns,
yaw and painting wraps, elapsed time and night twinkle. It also captures day/night
views in `previews/sky_projection_*`. Run it without `--headless`;
`sky_projection_results.json` records its results.

`test_overworld.gd` checks real keyboard input, all eight directions, hop timing,
pause, fixed north-facing movement, ignored Q/E and legacy orbit requests, projection round trips,
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
These timing reports predate the new painted skies and village dressing; this
pass was checked functionally and visually, without certifying a new FPS result.
Read `performance.json` and `PERFORMANCE.md` for their scope and limitations.

This is a prototype scale/layout and art pass. The camera is deliberately fixed
to suit the single-view paintings. Terrain heights,
cliff occlusion, overworld encounters and quest-map integration remain future work.
Garden Square is connected; the other region landmarks do not enter detailed
areas yet. Saves preserve the journey at the town-side checkpoint, rather than
the exact overworld coordinates. The main title scene remains the project entry.

Previews: [whole city](previews/fixed_city_day.png),
[windmill](previews/windsong_ridge.png), [lake](previews/willowmere_lake.png),
[ruins](previews/ivykeep_ruins.png), [coast](previews/palestone_coast.png),
[regional map](previews/greenshire_map.png).

[Mount study](HOP_STUDY.md) · [Camera and city](CAMERA_AND_CITY.md)
