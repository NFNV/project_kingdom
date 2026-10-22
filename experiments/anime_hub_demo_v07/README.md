# Garden Square & Mosswood — playable exploration demo

Walk as the cat adventurer through a painted anime town, a woodland trail, and
a riverside glade. The three dog wardens are peaceful residents. Talking to Bram
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
| E | Speak, deliver, record a forest memory, or use a nearby exit |
| J | Show / hide the journal |
| T | Preview the next lighting phase with a short transition |
| Esc | Pause / resume |
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
Most foliage, bridge rails and water in the forest plates are painted/static.
The cat still uses the starter two-pose walking loops; NPCs have standing views.
There are no interiors, audio, combat, or persistent save files in this demo.

New paintings were created with **built-in imagegen**. Source files and exact
prompts: [forest prompt set](assets/forest/generation_prompts.json).
[Forest asset QA](assets/forest/qa_report.json) records hashes, dimensions,
byte-identical copies, and read-only alignment measurements. Global day/night
translation measured zero; sampled local shifts were at most one source pixel.
This is prototype alignment, not a guarantee of identical painted detail.

## Verification

[test_results.json](test_results.json) records 72 gameplay checks: movement,
physical collision, the delivery route, friendly-warden regressions, the longer
clock, physically walking through every connection, all three resting places,
walking over the bridge, returning home, persistent progress and pause/resume.

[performance.json](performance.json) records native graphical measurements on the
current machine with moving characters, the new clock, forest effects, lighting
crossfades and a maximized window. Warmup precedes each six-second sample; long
frames are retained. Travel/loading fades are outside steady-state measurements.

The final focused run on Apple M1 / Metal / Godot 4.7.2 measured **59.9–60.0 FPS**
across all five samples. Worst steady-state frame was **24.35 ms**; none exceeded
33.33 ms. These short samples describe this demo on this machine, not larger maps
or other hardware.

```sh
Godot --headless --path . --fixed-fps 60 --script res://experiments/anime_hub_demo_v07/tools/test_hub.gd
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/profile_hub.gd
```

Native screenshots: [town](previews/town_day.png),
[forest trail](previews/trail_day.png),
[river glade at night](previews/river_night.png).
