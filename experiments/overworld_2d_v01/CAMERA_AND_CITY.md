# Camera, protagonist identity and chibi Mosswood

Updated city scale, landscape art and regional map: [REGION.md](REGION.md).
Current test and performance results: [README.md](README.md).
The historical preview links below show the earlier, larger city layout.

The camera is now fixed north-facing and tracks the player. **Q / E** no longer
rotate it. WASD / arrows roam; **F** inspects a nearby landmark or enters Garden
Square near its gate. **4** previews the city entrance. **F4** shows the live mounted rider.
Launching the scene with `-- --city` starts at that entrance.

## 2D camera

The fixed north-facing basis is shared by forward
projection, the shader's inverse ground mapping, scenery culling, depth sorting,
local surface alignment and keyboard steering. The camera follows the player at
a fixed ground distance; the projected player anchor stays fixed on screen.
The rider's world facing is preserved while the chosen artwork changes relative
to the view. Hop phase is preserved. Legacy orbit requests also retain the fixed heading.

The minimap stays north-up and draws a camera direction indicator. The sky
samples horizontal viewing rays using the terrain's focal length, with a fixed
vertical mapping. It does not roll, tilt or drift the entire star field. The
painted strips repeat three times around the horizon, with blended seams.
The sun and moon have gentle periodic sky paths that keep their complete
silhouettes above terrain and clear of the title, clock and minimap. A watercolor
sun appears from 06:00–18:00 and the large painted moon from 18:00–06:00. They
never crossfade together; the selected drawing stays opaque while the sky and
lighting blend through twilight. The moon has a brighter halo. Birds move
independently. Terrain and collision remain in world coordinates.

## Existing protagonist

`art/rider/hero_reference.json` records exact source rectangles from the existing
playable character's eight `idle` views in `cat_frames.tres`, using its registered
head centers and widths. This includes the actual separately drawn west views.
Godot extracts and caches those head textures once at startup. The original
main-game PNGs, SpriteFrames and metadata are not modified.

The mounted body retains its layered animation and now has the protagonist's
brown vest, cream sleeves, red scarf, olive trousers, boots, backpack and pale
tail tip. It is a mounted adaptation of the same character, rather than the
entire original walking sprite placed onto a frog. Original head sources and
new native SVG parts are audited in `art/rider/manifest.json`.

## Main city

The generic rows have been replaced with a chibi miniature of Mosswood / Garden
Square: central clock hall, fountain and circular paving, Bluebird Bakery's blue
awning, the green grocer awning, cottages and Northgate terraces. Entrances face
the plaza. Random trees are excluded from the city and its approach.

A complete hand-painted city landmark now replaces the earlier polygon renderer.
Its gateway is anchored at the existing south entrance. Like the surrounding
painted scenery, it faces the camera and follows the local curved-ground normal.
It has one authored view; different painted facades would require more artwork.
The old `city.gd` geometry remains available as collision/layout data.
The old terrain plaza circle has been removed: the painting already contains a
plaza. A soft contact shadow and small grass tufts soften the foundation edge,
with the gateway path left clear.
Buildings, trees and props use the individual original-image contact points in
`art/ground_contacts.json`. Wide foundations are culled conservatively before
they extend over the curved horizon; their cutoff fade lasts three map units.
This remains a 2D renderer with zero Node3D objects.

Buildings use oriented rectangular collision footprints; the fountain has a
solid base and the surrounding plaza is walkable. The existing detailed town is
unchanged. The miniature is an overworld landmark; its south gateway now returns
to Garden Square through the existing travel bridge.

## Verification

The current 130 overworld checks cover real keyboard roaming, Q/E leaving the
camera locked, ignored legacy orbit callers, fixed-view inverse projection and
depth order, city footprints, doors, surface normals, mount identity and travel.
The 58 atmosphere checks include exclusive celestial selection, calibrated
ground contacts, horizon footprint clearance, complete sun/moon framing across
all phases, HUD clearance and continuous positions at dawn. Eight native rendered
checks verify celestial brightness and no inactive-body ghost at dawn/dusk.
The 26 town-link checks cover
the live journey round trip and save checkpoint.

`preview_fixed_camera.gd` renders the current city at dawn, noon, dusk and night,
plus side and gateway approaches. See `previews/fixed_city_*.png`.
`preview_painted_city.gd` and `previews/moon_direction_*.png` are historical
camera-orbit studies; rotation is disabled in the current game.

The historical `preview_camera.gd` renders four geometric city viewpoints and a full stationary-player
camera orbit. See `previews/mosswood_north.png`, `mosswood_east.png`,
`mosswood_south.png`, `mosswood_west.png` and `camera_orbit.gif`. Native preview
logs are checked for rendering and script errors.

The historical `profile_overworld.gd` camera-orbit samples predate the fixed view.
It also provides city samples for the previous native
1080p benchmark. Actual focus, frame timing and the full-orbit sample are in
`performance.json`. Readbacks and exports are outside measured samples; the
meadow was resampled independently after preview encoding. These short samples
do not establish locked 60 FPS.
