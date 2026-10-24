# Garden Square & Mosswood — playable exploration demo

Walk as the cat adventurer through a painted anime town, a woodland trail, and
a riverside glade, and an enterable bakery. A 1.5× camera follows the cat
through every area and stops at the painted scene edges. The three dog wardens are peaceful residents. Talking to Bram
no longer starts sparring, and attacks/damage are disabled in this version.

## Play

Double-click [Play Garden Square.command](Play%20Garden%20Square.command), or open
[demo.tscn](demo.tscn) in Godot 4.7 and press **F6**. This updates the same demo
launcher; the original project's main scene stays unchanged.

```sh
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path /Users/n/Documents/project-kingdom res://experiments/anime_hub_demo_v07/demo.tscn
```

| Input | Action |
|---|---|
| WASD / arrows | Walk |
| Shift | Run |
| Right click | Walk to a point using obstacle navigation |
| E | Speak, deliver, enter a building, browse the shop, or use an exit |
| 1 / 2 / 3, or shop buttons | Buy bread / tea / honey while shopping |
| J | Show / hide the journal |
| T | Preview the next lighting phase with a short transition |
| Esc | Close the shop, or pause / resume |
| R | Restart the demo and reset progress |
| F11 | Toggle full screen |
| F3 | Show / hide FPS and rendering diagnostics |

## Go for a walk

The **southeast gate**, on the lower-right paving of Garden Square, is marked
**Mosswood**. Walk onto its arrow, or press E nearby. It leads to **Mosswood
Trail**, where you can stroll through the meadow and discover the old elm.
Continue to the trail's **southeast exit** to reach **Riverbend Glade**. The
footbridge is walkable, including the far bank; water and rocks block movement.
Return along each area's **west path** to get back to town.

Three resting places can be recorded with E: the old elm, wildflower meadow,
and Riverbend footbridge. The town delivery quest remains available:
Pippa → Elder Mallow → Moss → Pip → red postbox. Delivery progress, forest
memories, the same cat character, and the clock persist across area transitions.
There is no disk save; restarting begins a fresh session.

## Enter the bakery

Walk northwest to the **blue-and-white awning** on the left side of the square.
Its doorway is marked **Bluebird Bakery**. Walk onto the entrance arrow, or press
**E** when the **Enter bakery** prompt appears. The left-hand paving now connects
the square to those steps. Walk back through the shop's front threshold to return.

The interior layout is authored in Godot: an isometric oak floor, plaster walls,
framed windows, timber trim, bread shelves, a cafe table, an oven, and a separate
solid sales counter. **Clover** stands behind that counter; approach the customer
side and press **E** to shop. Begin with 12 coins and buy bread (2), tea (3), or
honey (4) using the buttons or number keys. Purchases and money persist across
area changes; they are a small shopping demonstration, with no item-use system
yet. E/Esc or the return button closes the shop. Shopping blocks world input
while the clock and ambient animations continue.

Furniture cutouts were painted using **built-in imagegen**; their placement,
architecture, floor projection, collision, vendor depth sorting and interactions
are authored in code. Exact [bakery prompts](assets/bakery/prompts.json) and
[asset catalog / alpha QA](assets/bakery/catalog.json) accompany the five images.
PNG copies preserve the generated originals byte for byte; native AtlasTexture
resources trim their transparent margins without rewriting the images.

## Time and interface

A full dawn → noon → dusk → night → dawn cycle now takes **20 real minutes**,
five times longer than before. Daylight and nighttime each span roughly ten
minutes. The shared time stops while paused; T is only a manual preview shortcut.

An original brass celestial dial at the top center shows a moving hour marker,
a sun during daylight, a crescent moon and stars after sunset, and a synchronized
24-hour readout. Its placement and sun/moon concept take inspiration from classic
RTS clocks, including Warcraft III; its drawing is original native Godot geometry.
The rest of the HUD uses parchment, forest green, brass trim and serif headings.
Georgia/Baskerville are requested through SystemFont with system fallbacks;
no proprietary font files are bundled.

## Art and rendering

The fixed internal canvas remains **1920 × 1080**, displayed initially in a
1280 × 720 window and capped at **60 FPS**. Full screen/maximize scales that same
canvas. Source paintings are 1672 × 941 and scale to fit, with linear filtering
and mipmaps. The architecture stays fixed in its painting; no tilted house cards
are introduced. Each area's physical boundaries and obstacle navigation are
traced against its actual painting. Characters and independent props sort at
their ground anchors. Scene transitions use a short fade and preserve session
state, with a cooldown to prevent immediately bouncing back through an entrance.

The town retains its four lighting backgrounds. Both forest areas have original
day and night plates, with twilight blends and matching sprite tints. Independent
trees sway; drifting leaves and night fireflies animate with native 2D drawing.
The plaza fountain now has four source-registered falling streams, traveling
highlights, droplets, impact splashes and ripples. The bakery has native animated
oven flames, rising tea steam, flour motes and swaying curtain edges. Its windows
follow the outdoor light while the room stays warmly lit. Foreground trees fade
when they would cover the cat; interaction prompts track world positions through
the camera. Most foliage, bridge rails and water in forest plates remain static.
The cat now has **eight facing directions**, each with **eight walk poses, eight
separate run poses, and four idle/blink poses**. Its sword stays sheathed during
peaceful exploration. Gait phase follows distance actually travelled, so collision
or releasing movement stops the stepping. Direction hysteresis prevents tiny
steering changes from repeatedly flipping the character.
The player now uses per-pose anatomical alignment and size correction rather than
anchoring each drawing to its lowest boot. That removes accidental body jumps as
a foot lifts, keeps the head size steady, and leaves a small authored gait bob.
Starting/stopping and direction changes ease between the average stances.
The downward cycle now uses a replacement south-facing sheet: every drawing
keeps a centered face/chest and the tail on the same side. This fixes the
alternating front/angled poses and swapping tail visible in the supplied clips.

All five civilian types have eight idle poses and four occupational/greeting
poses. The baker offers bread, Mallow adjusts her spectacles, Sage reads and turns
a page, Moss inspects an apple, and Pip raises a letter. Their idle/gesture timing
is staggered. Clover uses the baker's animation mirrored toward the customer side
of the counter, including during greetings. The three
friendly wardens have eight walking poses and four idle poses in four directions,
walk short routes with resting pauses, stop when approached, and face the cat.
Their conversation prompts follow their current positions. Combat remains off.

Four taller human residents now share the square with the animals. Approach and
press **E** to speak to each one:

| Resident | Location |
|---|---|
| Rhea · Wayfarer | Southern paving, west of the Mosswood gate |
| Captain Alden · Town Warden | Town-hall side, northeast of the fountain |
| Iris · Herbalist | Southwest paving near the bench |
| Tomas · Blacksmith | West side of the fountain |

They use the [human asset pack](../anime_hub_assets_v08_humans/README.md) at
109–117 world pixels tall versus the cat's 73. Humans are reduced 35% and
all cats and dogs 32.5%, including Clover inside the bakery. Foot anchors and
interaction prompts follow the smaller sprites, and stride length scales with
their height. Each has four actual standing
views, turns toward nearby visitors with a directional deadband, breathes gently,
and acknowledges a conversation. Feet stay planted, the shared ground sorting
places people correctly, and clothes follow day/night tint. These humans stay at
their town posts; their prepared artwork has no walk/run cycle. Their dialogue
offers local flavour and directions; purchases remain available at Clover's bakery.

Each human has a solid foot collider included in navigation. When a padded grid
pocket is disconnected, pathfinding chooses a nearby reachable join with physical
clearance, so clicking away after a conversation does not trap the cat by the NPC.
The human residents are recreated on returning to town and do not appear indoors
or in the forest. The delivery errand, animal wardens and existing economy remain
available alongside their conversations.

The new art remains a prototype: some silhouettes and changes between directions
can still benefit from animation-artist cleanup.
There is one enterable interior. Audio, combat, and disk saves are not included.

New paintings were created with **built-in imagegen**. Source files and exact
prompts: [forest prompt set](assets/forest/generation_prompts.json).
[Forest asset QA](assets/forest/qa_report.json) records hashes, dimensions,
byte-identical copies, and read-only alignment measurements. Global day/night
translation measured zero; sampled local shifts were at most one source pixel.
This is prototype alignment, not a guarantee of identical painted detail.

## Verification

[test_results.json](test_results.json) records 255 gameplay checks: movement,
physical collision, the delivery route, friendly-warden regressions, the longer
clock, physically walking through every connection, all three resting places,
walking over the bridge, returning home, persistent progress and pause/resume. New checks cover real camera following,
scene-edge limits, world-to-screen prompts, water flow, physically entering and
leaving the bakery, navigating to the counter, its collision and vendor depth,
shop button purchases, insufficient funds, blocked world input and inventory
persistence through repeated visits. Animation checks also exercise eight-way
resources, all eight poses during real walking, the separate running state,
brief blinks, turning deadband, no stepping against obstacles, actual patrol
movement and collision clearance, moving conversation targets, greeting triggers,
and freezing character/NPC animation on pause.
Additional checks measure source head landmarks through the actual native atlas
and sprite transforms across every player pose, consistent head size across all
gaits, easing when starting a run, caller placement, and Clover's persistent facing.
The downward regression walks and runs through all eight south poses using actual
input and verifies that every frame uses the repaired sheet without mirroring.
The separate [front-art audit](assets/motion/front_cycle_v2_audit.json) reads source
pixels for centered muzzle landmarks and a consistent tail side. It checks all
20 replacement poses and also detects the failures in the preserved old sheet.
Human checks physically approach each resident, use the E prompt, verify distinct
dialogue/greetings, walk into their colliders, leave for the next conversation,
approach from all four directions, check planted feet and relative height, pause
their idle motion, and verify night tint and recreation after area visits.

[performance.json](performance.json) records native graphical measurements on the
current machine with moving characters and camera, fountain effects, the bakery,
its merchant interface, the clock, forest effects, lighting
crossfades and a maximized window. Warmup precedes each six-second sample; long
frames are retained. Travel/loading fades are outside steady-state measurements.

The last native run, before the camera pullback from 1.7× to 1.5×, on Apple M1 /
Metal / Godot 4.7.2 averaged **60 FPS in town**
with four humans, five animal civilians and three patrolling dog wardens. The town
sample's worst frame was 19.21 ms. All seven cases were fully focused and averaged
59.8–60 FPS, including the maximized window, while rendering the fixed 1920×1080
canvas. One forest sample retained a **52.54 ms** hitch; the other six cases had
worst frames below 20 ms. These short samples describe this demo on this machine;
occasional hitches remain and playback is not guaranteed to stay at 60 FPS on
other hardware. Scene-load/travel fades are outside the steady-state samples.

```sh
Godot --headless --path . --fixed-fps 60 --script res://experiments/anime_hub_demo_v07/tools/test_hub.gd
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/profile_hub.gd
```

Native screenshots: [bakery counter](previews/bakery_counter.png),
[shop](previews/bakery_shop.png), [flowing fountain](previews/fountain_close.png),
[town](previews/town_day.png),
[forest trail](previews/trail_day.png),
[river glade at night](previews/river_night.png).
Human NPC captures: [town overview](previews/human_npcs_day.png),
[night lighting](previews/human_npcs_night.png), and
[Captain Alden conversation](previews/human_alden_conversation.png).
The human overview uses a temporary 1.25× camera to show all four placements;
the existing conversation captures were taken at 1.7×. The default follow camera
is now 1.5×, showing a little more of the surroundings.


Recreate the close-camera screenshots with:

```sh
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/capture_hub.gd
```

Add `-- --humans` to capture the human overview, lighting, and four conversations.


## Animation authoring and preview

The final [motion assets and prompt index](assets/motion/README.md) include 268
registered poses across 17 sheets. Generation used **built-in imagegen**. PNGs
remain byte-identical to the selected outputs; native AtlasTexture regions and
margins register anatomical head centers for the player and ground anchors for
other residents on a shared canvas. Player scale and texture offsets are calibrated
per pose, while the physics ground anchor stays fixed. Registration
uses detected transparent gutters rather than assuming perfectly equal AI cells.
The runtime reads only the final catalog and SpriteFrames resources.

[Character motion preview](previews/character_motion.png) shows the directions and
states rendered by Godot. The [body alignment comparison](previews/body_registration.png)
shows complete walk/run cycles before and after correction, using the same PNGs.
The [downward-cycle comparison](previews/downward_cycle.png) compares the old
south drawings with the new sheet, both using the current registration code.
To watch the animated gallery:

```sh
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/preview_motion.gd
```

Recreate the registration comparison with `tools/review_registration.gd`.
Add `-- --front-cycle` to recreate the downward-art comparison. Run
`python3 experiments/anime_hub_demo_v07/tools/audit_front_cycle.py` for its pixel audit.
