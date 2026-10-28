# Camera, protagonist identity and chibi Mosswood

Updated city scale, landscape art and regional map: [REGION.md](REGION.md).
Current test and performance results: [README.md](README.md).
The historical preview links below show the earlier, larger city layout.

Hold **Q / E** to orbit the camera; **Home** restores north. WASD / arrows move
relative to that view. **F** now inspects a nearby landmark, freeing E for camera
rotation. **4** previews the city entrance. **F4** shows the live mounted rider.
Launching the scene with `-- --city` starts at that entrance.

## 2D camera

Yaw rotates a pair of 2D ground basis vectors. The same basis is used by forward
projection, the shader's inverse ground mapping, scenery culling, depth sorting,
local surface alignment and keyboard steering. The camera orbits the player at
a fixed ground distance; the projected player anchor stays fixed on screen.
The rider's world facing is preserved while the chosen artwork changes relative
to the view. Hop phase is preserved. Pausing stops held camera movement.

The minimap stays north-up and draws a camera direction indicator. Sky layers
pan around the view. The terrain, collision and city remain in world coordinates,
so rotating the view cannot move a river, building or collision footprint.

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

`city.gd` draws height-aware walls, gables, roof planes, windows, awnings, flowers,
clock faces and flowing fountain water using CanvasItem polygons and lines.
Visible walls are selected for the camera heading and roofs are sorted by view
depth. Vertical details follow the same local curved-surface normal as the
surrounding scenery. Degenerate edge-on polygons are skipped before drawing.
This remains a 2D renderer with zero Node3D objects.

Buildings use oriented rectangular collision footprints; the fountain has a
solid base and the surrounding plaza is walkable. The existing detailed town is
unchanged. The miniature is an overworld landmark; entering the detailed town
from it is still a separate integration step.

## Verification

The original 104 checks covered actual Q/E/Home input, camera-relative movement and rider views,
pause, inverse projection at six headings, orbit anchor stability, rotated depth
sorting, city footprint collisions, inward-facing doors, surface normals and
original protagonist references, alongside the existing mount and travel checks.

`preview_camera.gd` renders four city viewpoints and a full stationary-player
camera orbit. See `previews/mosswood_north.png`, `mosswood_east.png`,
`mosswood_south.png`, `mosswood_west.png` and `camera_orbit.gif`. Native preview
logs are checked for rendering and script errors.

`profile_overworld.gd` adds city and camera-orbit samples to the previous native
1080p benchmark. Actual focus, frame timing and the full-orbit sample are in
`performance.json`. Readbacks and exports are outside measured samples; the
meadow was resampled independently after preview encoding. These short samples
do not establish locked 60 FPS.
