# Garden Square & Mosswood — playable exploration demo

Walk as the cat adventurer through a painted anime town, a woodland trail, and
a riverside glade, and an enterable bakery. A close 1.7× camera follows the cat
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

All five civilian types have eight idle poses and four occupational/greeting
poses. The baker offers bread, Mallow adjusts her spectacles, Sage reads and turns
a page, Moss inspects an apple, and Pip raises a letter. Their idle/gesture timing
is staggered. Clover uses the baker's animation behind the counter. The three
friendly wardens have eight walking poses and four idle poses in four directions,
walk short routes with resting pauses, stop when approached, and face the cat.
Their conversation prompts follow their current positions. Combat remains off.

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

[test_results.json](test_results.json) records 164 gameplay checks: movement,
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

[performance.json](performance.json) records native graphical measurements on the
current machine with moving characters and camera, fountain effects, the bakery,
its merchant interface, the clock, forest effects, lighting
crossfades and a maximized window. Warmup precedes each six-second sample; long
frames are retained. Travel/loading fades are outside steady-state measurements.

The native run on Apple M1 / Metal / Godot 4.7.2 measured approximately **60 FPS**
(59.9–60.1 over short samples) across all seven cases, including walking/running,
patrolling wardens, animated residents, and the shop. Every sample was fully
focused. One forest sample retained a **53.66 ms** long frame; all other cases
had worst frames under 20 ms. These short samples describe this demo on this
machine, not a guarantee of hitch-free playback or other hardware.

```sh
Godot --headless --path . --fixed-fps 60 --script res://experiments/anime_hub_demo_v07/tools/test_hub.gd
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/profile_hub.gd
```

Native screenshots: [bakery counter](previews/bakery_counter.png),
[shop](previews/bakery_shop.png), [flowing fountain](previews/fountain_close.png),
[town](previews/town_day.png),
[forest trail](previews/trail_day.png),
[river glade at night](previews/river_night.png).


Recreate the close-camera screenshots with:

```sh
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/capture_hub.gd
```


## Animation authoring and preview

The final [motion assets and prompt index](assets/motion/README.md) include 268
registered poses across 17 sheets. Generation used **built-in imagegen**. PNGs
remain byte-identical to the selected outputs; native AtlasTexture regions and
margins register heads and planted boot baselines on a shared canvas. Registration
uses detected transparent gutters rather than assuming perfectly equal AI cells.
The runtime reads only the final catalog and SpriteFrames resources.

[Character motion preview](previews/character_motion.png) shows the directions and
states rendered by Godot. To watch the animated gallery:

```sh
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/preview_motion.gd
```
