# Garden Square, Mosswood & Briarwood — playable RPG demo

Walk as the cat adventurer through a painted anime town, a woodland trail, and
a riverside glade, an enterable bakery, and the large Briarwood combat forest. A 1.5× camera follows the cat
through every area and stops at the painted scene edges. The three dog wardens are peaceful residents. Talking to Bram
no longer starts sparring. Combat is enabled only in Briarwood Wilds.

## Play

For the latest combat demo, double-click [Play Briarwood.command](Play%20Briarwood.command).
For the town start, double-click [Play Garden Square.command](Play%20Garden%20Square.command), or open
[demo.tscn](demo.tscn) in Godot 4.7 and use **Run Current Scene (F6)**.
The project's main scene now points here too: **Run Project (F5)** starts this
current demo in Garden Square, including the latest animation changes.

```sh
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path /Users/n/Documents/project-kingdom res://experiments/anime_hub_demo_v07/demo.tscn
```

| Input | Action |
|---|---|
| WASD / arrows | Walk |
| Shift | Run |
| Right click | Walk to a point using obstacle navigation |
| Space / left click | Sword attack; left click aims the strike |
| Q | Wind Slash: piercing ranged blade, six-second cooldown |
| E | Speak, deliver, enter a building, browse the shop, or use an exit |
| 1 / 2 / 3, or shop buttons | Buy bread / tea / honey while shopping |
| J | Show / hide the journal |
| T | Preview the next lighting phase with a short transition |
| M | Mute / unmute all sound |
| Esc | Close the shop, or pause / resume |
| R | Restart the demo and reset progress |
| F11 | Toggle full screen |
| F3 | Show / hide FPS and rendering diagnostics |

## Sound and performance

Four original instrumental themes accompany the town, woodland, night and
battles. Music crossfades when the setting changes, and nearby hostile bandits
trigger the battle theme. Birds, breeze and crickets follow the shared clock;
fountains, the river and the bakery oven have positional sound.

Footsteps follow actual distance travelled over stone, wood, grass and earth.
Sword swings, impacts, enemy attacks, Wind Slash, damage, doors, purchases and
rewards have separate cues. A fixed pool of twelve positional effects players
and distance culling bound playback work. Finished PCM clips load once; music
and effects are not synthesized during play.

Press **Esc** for Master, Music, Ambience and Effects sliders plus a mute
checkbox, or **M** to mute immediately. Volume preferences survive restarting.
Pause freezes music and ambience and stops transient effects, so old attacks
do not replay on resume. See the [audio source notes](assets/audio/README.md),
[asset audit](assets/audio/qa_report.json), and
[settings screenshot](previews/audio_settings.png).

The audio regression adds **39 passing checks**, bringing the demo suite to
**604/604**. It exercises real movement, attacks, purchases, music transitions,
pause, volume widgets and non-silent PCM from the actual mixer.
[Results](audio_test_results.json).

The [native audio performance run](audio_performance.json) used CoreAudio on
Apple M1 / Godot 4.7.2, the normal 1.5× camera and a **1920×1080 internal
canvas** displayed in the initial 1280×720 window. All five four-second samples
were **100% foreground focused**, with movement, populated scenes and combat
in Briarwood: **59.8–60 FPS**. Town, bakery and Northgate had no frames over
20 ms; Briarwood retained a 20.8 ms frame by day and a **59.76 ms hitch at
night**. This is a short steady-state test on this machine, excluding scene
loading; occasional hitches remain. No movie capture or encoding ran alongside
the benchmark. Run `tools/profile_audio.gd` graphically to repeat it; the report
rejects samples with less than 95% measured foreground focus.

## Shared painted art direction

Northgate now matches Garden Square more closely: painted lime plaster, slate
shingles, terracotta/blue/sage roof variants, warm limestone paving and cooler
cobbled streets, with painted grass and clover in Linden Park. Plain placeholder windows and doors have been replaced with
painted casements, arches and timber/teal doors. Striped awnings, cornice shade
and corner stones dress the existing straight house geometry. Some windows glow
warmly at night through a small separate mesh, while buildings still fade when
they cover the player.

The bakery shares the same plaster and oak, with teal wainscoting, painted
window frames, soft window light and furniture contact shade. Human and animal
characters use one subtle pigment response before the existing day/night tint.
Their source art, proportions, movement and combat remain intact.

Two original atlases were generated with **built-in imagegen**:
[six materials](assets/style/town_materials_v1.png) and
[four facade details](assets/style/town_details_v1.png), plus matching
[park grass](assets/style/park_grass_v1.png). Exact prompts and sources:
[materials](assets/style/generation.json), [details](assets/style/details_generation.json),
[grass](assets/style/grass_generation.json), or the combined
[prompt set with saved asset paths](assets/style/prompt_set.json).
The [style guide](assets/style/STYLE_GUIDE.md), [region catalog](assets/style/catalog.json)
and [asset QA](assets/style/qa_report.json) document the shared art direction.
Native screenshots: [Northgate](previews/style_market.png),
[bakery](previews/style_bakery_day.png), [night](previews/style_market_night.png),
[Garden Square](previews/style_garden_square.png).

The atlas textures and character material are shared; buildings and street paint
remain cached once per zone. The 1.5× camera, 1080p internal viewport, building
footprints, all four door frontages and navigation paths stay in use.
Run [preview_art_style.gd](tools/preview_art_style.gd) with `-- --profile` for
live graphical measurements and native captures; see
[art_style_performance.json](art_style_performance.json). Movie mode is for
capture only and must not be used to measure live performance.

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
Game progress has no disk save; restarting begins a fresh session. Audio
preferences are saved separately.

## Northgate Quarter — northern town district

Take the **north passage** in Garden Square, above the fountain and west of the
hall, to enter **Northgate Quarter**. Its **southern avenue** returns to the hub.
You can also double-click [Play Northgate.command](Play%20Northgate.command) or
append `-- --district` to the normal Godot launch command.

Northgate is one **6400 × 3840** district with a consistent isometric street grid,
wide limestone sidewalks, grey carriageways, curbs and crosswalks. Its sixteen
blocks include **48 homes**, **three shopfronts**, an **old town hall**,
**Sunstone Plaza** with a flowing fountain, and the small **Linden Park** with
paths, benches, flowers and wind-blown elms. All 52 buildings now use native
wall/roof geometry on the exact street projection, rather than perspective-mismatched
cutouts. Eight residential recipes vary footprint, one-to-three-storey height,
gabled/hipped roof form and pitch, facade/roof colors, shutters, awnings, balconies
and timber/brick details. Doors select the nearest sidewalk in all four directions,
with a matching paved path and reachable doorstep; northern lots no longer have
a front door drawn on the wrong visible wall. Buildings fade when they obscure the cat. The camera keeps
the existing 1.5× zoom and can follow across the full district.

**Twenty residents** populate the area: fourteen animated animal civilians,
four taller humans and two friendly wardens with actual walking patrols.
Approach and press E for conversations. Visiting the plaza, park and old hall
records three town places separately from forest memories. A district map shows
the streets and the way back. Fountain, trees, lighting and patrols pause with
the game. Day/night tint and warm street-lamp pools use the same twenty-minute
clock as all earlier zones. Errands, purchases, coins and forest progress survive
round trips. This remains a peaceful area. New houses and shops are exteriors;
the enterable Bluebird Bakery remains available in Garden Square.

Existing props and characters remain in use. The earlier whole-building cutouts,
including the ochre townhouse, remain as historical art assets; Northgate no
longer places them. New [plaster](assets/district/plaster_v2.png) and
[slate](assets/district/slate_v2.png) textures, plus straight-on
[window](assets/district/window_v2.png) and [door](assets/district/door_v2.png)
elevations, were made with built-in imagegen. Their [material prompts](assets/district/architecture_v2.json)
and [facade prompts](assets/district/facades_v2.json) accompany the unmodified PNGs.
Native wall planes project the elevation details, keeping all verticals plumb and
roof/paving directions aligned. Both streets and individual buildings render once
into native viewport caches, so normal play draws cached surfaces.

[test_district.gd](tools/test_district.gd) physically walks through the hub's north
exit, visits all six major destinations, interacts with landmarks and a human,
checks building collision/occlusion and upright transforms, returns to the hub,
and reenters while checking preserved state and populations.
[preview_district.gd](tools/preview_district.gd) captures the district and measures
normal-camera 1080p exploration at the plaza, park and a lit street at night.
The district checks pass **154/154** alongside **344/344** existing gameplay checks.
They verify every residential frontage and navigable doorstep as well as the
actual vertical geometry, variety, full walking route and preserved progress.
See the native performance report for the latest day/night samples and retained
long frames; captures use the normal 1.5× follow camera and 1920×1080 canvas.
The latest run remained unfocused, so its samples do not establish foreground
60 FPS performance.
Results are saved to [district_test_results.json](district_test_results.json) and
[district_performance.json](district_performance.json). Preview: [whole district](previews/district_overview.png),
[plaza](previews/district_plaza.png), [park](previews/district_park.png),
[Market Lane](previews/district_market.png), [night](previews/district_night.png).

## Briarwood Wilds — the combat forest

From Garden Square, take the **southeast gate → Mosswood Trail → Riverbend
Glade**. Cross Riverbend's footbridge and continue to the **Briarwood Wilds**
sign on the far bank. The return path lies on the forest's western edge.
For a direct combat preview, append `-- --wilds` to the launch command above.

This continuous **4608 × 2592** world has 5.76 times the ground area of an older
forest scene. 272 layered elm and willow crowns sway independently, solid trunks
block movement and melee, and foliage fades around the cat. A schematic map
shows the four clearings, cleared packs, the player and the western exit.
The existing 1.5× follow camera and the smaller animal scale stay in use.

**Twelve dog bandits** now have their own artwork and behavior: four camps each
contain two burgundy-scarf **sword raiders** and one ochre-scarf **club mauler**.
They walk short local patrols, notice nearby intruders, pursue within their
territory, and return to camp before resuming patrol when the cat escapes.
The friendly blue town wardens keep their existing art and peaceful behavior.

| Enemy attack | Warning | Escape |
|---|---|---|
| Raider slash | 0.55 seconds; red forward sector | Step back or behind |
| Raider lunge | 0.72 seconds; red straight lane | Sidestep; trunks stop the dash |
| Mauler sweep | 1.0 second; amber wide sector | Leave its reach or move behind |

Attack aim locks during the warning. Damage is confined to the visible active
stage, once per swing; recovery is safe. Lunge damage stays within its lane and
uses real collision movement. A sword hit cancels anticipation, briefly staggers
the bandit, displays its drawn recoil pose, flashes the body, pushes it away and
shows a short impact burst/damage number. Defeated bandits recoil and fade.
All still take three normal hits or one Wind Slash, and give two coins each.

The two [enemy sheets](assets/bandits/generation.json) contain **64 original
drawings**: eight poses in four views per role, including three drawn walk poses,
wind-up, contact, recovery and hurt. They were made with **built-in imagegen**;
the exact prompts and original paths are saved beside the PNGs. Read-only
[registration](tools/register_bandits.py) and native alpha polygons isolate
complete figures, preserve grounded boots and limit accidental size changes.
See the [native combat preview](previews/bandit_combat.mp4),
[all 64 native poses](previews/bandit_pose_review.png), and
[enemy checks](tools/test_bandits.gd). These remain prototype key-pose animations.
The two sheet textures, contours, pose meshes and triangle indices are cached
and shared; all views are prepared during zone loading. Use
`preview_bandits.gd -- --profile` for live full-forest measurements at the normal
camera, recorded in [bandit_performance.json](bandit_performance.json).
On macOS, normal launch uses the 60 FPS engine cap with Metal VSync disabled
after profiling found long focus-change waits with both pacing mechanisms.
The report retains long intervals and focus state; it is not a guarantee of
locked 60 FPS under every desktop condition.
The MP4 was recorded at a fixed 60 FPS for inspection; its encoding speed is
not a live gameplay benchmark.

The cat keeps its sword sheathed while idle, walking, running and shopping.
Only attack/skill poses show the blade in its paw. During attacks, **32 drawn combat
poses** replace the walking body: eight timed stages in four real facing views,
including drawing the blade, anticipation, early slash, contact, follow-through,
settling, recovery and sheathing. Arms, shoulders and the held blade move together.
Read-only component analysis and native alpha polygons isolate the complete figures.
The head and boots retain their artwork proportions; a three-band body rig eases
the stance between the walking reference, a shallow attack crouch and recovery.
These remain authored key poses in four directions, with room for artist cleanup.
**Space** attacks in the facing direction; **left click** aims a normal strike.
Movement updates facing before a new attack, and facing stays locked through the
swing. An aimed click during recovery queues the next strike. Q takes priority.
Normal attacks last 0.60 seconds, with damage only between 0.22 and 0.34 seconds;
recovery poses cannot deal late damage. Art and gameplay share
[combat_timing.gd](tools/combat_timing.gd).

**Q — Wind Slash** is a separate ranged ability. After a short 0.28-second
wind-up, a bright blue crescent travels up to 520 ground pixels, dealing three
damage and stronger knockback, and piercing up to three dogs. Trees stop the
wave. The skill has a six-second cooldown. Press Q **during a normal attack**
and it queues for up to 0.7 seconds, then takes priority over held Space input.
The skill card is also a clickable button, with queued/recharge/ready feedback.
Town UI explains that the skill is available in Briarwood; it cannot hurt
friendly residents. Pausing freezes both recharge and projectiles; travel
cancels pending/airborne attacks and preserves cooldown.

Move away from red enemy warnings to dodge. A bandit takes three normal hits
or one wind slash. The cat has five health and brief invulnerability after
being hit. Each unique defeat rewards **two coins**. Defeated bandits remain
defeated across travel and checkpoint recovery; clearing all twelve completes
the objective. Bandit bodies use their own cached sheets and native silhouettes.

On defeat, a short fade returns the cat to the sheltered western entrance with
full health. Coins, defeated enemies, errands, purchases and the shared clock
remain intact. Leaving a zone restores health. The town wardens, older forest
areas and bakery remain peaceful. Progress is in memory until restarting.

The painted [ground asset](assets/forest/briarwood_ground.png) was made with
**built-in imagegen**; its exact [prompt and source](assets/forest/briarwood_generation.json)
are saved beside it. A native mirror-repeat shader keeps the painted ground at
local scenery scale rather than stretching one low-resolution plate over the
whole map. Existing transparent trees supply the separate canopy layer.

The [sword and skill checks](tools/test_skill.gd) cover the four-direction drawn
attack poses, actual Q input while Space remains held, input priority, clickable
skill input, projectile damage/piercing/range, walls, cooldown UI, pause in flight,
travel cleanup and safe-area guards. The **255 gameplay**, **45 forest combat**
and **44 sword/skill** checks pass. The **35 animation checks** additionally test
phase continuity, pivots, all eight stages, actual rendered head landmarks and
grounded boots, current-direction attacks, recovery hit safety, queued input and
travel cleanup. With the 154 district checks and 32 enemy checks,
**565/565 checks pass**. The enemy checks cover actual patrols, three attacks,
locked warnings, dodges, collision during lunges, recovery safety, stagger,
pause, retreat, rewards, persistent roles and friendly-town isolation.
Native previews: [attack](previews/drawn_sword_attack.png),
[all 32 poses](previews/polished_attack_phases.png), [Q projectile](previews/wind_slash.png).

The new [attack sheet](assets/combat/cat_sword_attack.png) was generated with
**built-in imagegen**; its [exact prompt/source](assets/combat/generation.json)
and [registration catalog](assets/combat/catalog.json) are preserved. The PNG is
unchanged. [cat_combat.gd](tools/cat_combat.gd) clips the original alpha contours
with native textured polygons instead of assuming that generated grid spacing
is exact. The earlier native sword overlay is disabled during normal play; attack art
includes the actual held blade. [preview_combat.gd](tools/preview_combat.gd)
reproduces the native render checks. Older Crescent Cleave previews are historical.

The matching [transition sheet](assets/combat/cat_transitions_v2.png) adds 16
draw, intermediate slash and sheath drawings, made with **built-in imagegen**.
Its [exact prompt and source](assets/combat/transitions_generation.json) and
[registration catalog](assets/combat/transitions_catalog.json) are saved. Both
source PNGs remain unchanged. [register_combat_transitions.py](tools/register_combat_transitions.py)
only reads alpha components and anatomical landmarks; the native renderer handles
clipping and body registration. [preview_animation_polish.gd](tools/preview_animation_polish.gd)
records walking, downward movement, running, pivots, attacks and Q at a temporary
2.5× review zoom. See the [nine-second native motion review](previews/animation_polish.mp4).
Normal play keeps the 1.5× follow camera. The review was recorded at a fixed
60 FPS for inspection; movie encoding speed is not a live performance benchmark.

Native M1 graphical samples, recorded in [wilds_performance.json](wilds_performance.json),
cover western exploration, an active three-dog pack and a deep-forest night
encounter at the fixed 1920×1080 canvas. Before the combat-animation/Wind Slash update, these three six-second samples each
measured about 60 FPS, with no frame above 20 ms. The 45 Briarwood checks and
255 existing gameplay checks pass. The reproducible capture/profiling
script is [preview_wilds.gd](tools/preview_wilds.gd); preview captures are
[day](previews/wilds_day.png), [combat](previews/wilds_combat.png) and
[night](previews/wilds_night.png). Run [test_wilds.gd](tools/test_wilds.gd) headlessly
for bridge entry, walking all four clearings, camera bounds, pursuit/leash,
attack warnings/dodge/damage, Space attacks, rewards, pause, recovery, physical
retreat/reentry, persistent clears and friendly-town regressions.

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
steering changes from repeatedly flipping the character. Large turns now pivot
through the existing drawn views instead of snapping directly across them, while
movement remains responsive. Brief stops preserve the foot phase for the next step.
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
There is one enterable interior. Game progress is not saved to disk; combat
is available in Briarwood only. Sound and saved volume preferences are included.

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
