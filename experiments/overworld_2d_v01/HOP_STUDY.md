# Eight-direction mounted hop

The cat and frog now have N, NE, E, SE, S, SW, W and NW views. Every view uses
`mounted_rider.gd`; the original circle placeholder renderer has been removed.
The frog and mounted body remain layered drawings. The head now reuses the
actual protagonist’s eight view images, with matching brown vest and pale tail
tip added to the mounted outfit. Body views for west mirror east; protagonist
heads use their actual separately drawn west images.

## In play

WASD / arrows choose the direction; pairs of keys select diagonals. Shift gives
faster hops. F4 opens a live enlarged view with the current direction and stage.
The close-up uses the same rig and pose as the world character.

The frog crouches, pushes with both hind legs, lifts off, tucks its feet, reaches
for the ground, compresses on landing and recovers. The cat follows the saddle
with delayed torso/head movement; scarf and tail have their own motion. Only the
frog's body squashes. The grounded shadow shrinks and fades slightly in flight;
landing produces a small dust puff.

Actual travelled distance advances the cycle: six map units per hop. Turning
changes the view without resetting phase, elevation or rider reaction. Eight
facing sectors have four degrees of hysteresis beyond their ordinary half-width,
preventing tiny changes from flickering the artwork. Stopping retains the last
direction. Releasing input or meeting an obstacle finishes the current cycle and
settles. Pause freezes the exact pose and clock, including a hop stopped in
midair. Landmark shortcuts return to a grounded pose.

## Artwork and implementation

Fifty-one native SVG layers share a 256x256 canvas and ground anchor (128,225).
Five authored viewpoints plus three mirrored viewpoints cover eight directions.
Front eyes/muzzles, profile faces, three-quarter shoulders, boots, packs,
forelegs and layer ordering change with the view. Near/far limbs are ordered
around the mount, saddle and rider. Front facial features render above the
shoulder joints so the frog's eyes remain visible.

`art/rider/build_parts.py` reproduces the original fourteen layers.
`art/rider/build_direction_parts.py` authors thirty-two additional layers without
replacing the north files. `art/rider/build_hero_outfit.py` adds the matching vest layers.
`art/rider/build_hero_reference.py` reads the existing main-game SpriteFrames
and body registration, storing exact source head rectangles in
`hero_reference.json`. Godot caches these head textures without modifying the
original PNGs. The remaining parts are native vector drawings.
`art/rider/manifest.json` records hashes and view metadata. Every pose reuses the
same artwork within its view.

Nine timeline keys interpolate the same hop across all eight directions. A
mirrored view flips around the ground anchor, not around a changing image edge.
This remains 2D canvas drawing, with no 3D model, new addon or external API.

The artwork is a coherent prototype set. Body mirroring also mirrors accessories;
individually authored west views would be needed for strict handedness or
asymmetric equipment. A separate unmounted animation is not included.

## Verification and previews

`test_overworld.gd` exercises physical keyboard input for all eight views,
retained idle facing, hysteresis, phase-preserving turns, texture loading,
crouch/apex/landing, exact loop closure, continuous elevation, travel cadence,
idle settling, F4 and midair pause/resume. Projection, surface alignment,
collisions, bridge crossing and continuous road travel also run: 104/104 checks, including camera steering, projection at six headings, city
footprints, surface normals and original protagonist references.

`preview_directions.gd` captures each view in the actual world and renders the
same rig into eight-view idle/airborne galleries. Its forty animation frames
export to [eight_directions.gif](previews/eight_directions.gif). Individual world
captures are `previews/direction_N.png`, `direction_NE.png`, and so on. The original
`preview_hop.gd` still captures the north-only cycle for comparison.

`profile_overworld.gd` separately measures native 1920x1080 movement, including
the live close-up and a turning sample that records all eight rendered headings.
Capture readback and encoding are excluded from performance measurements.

The camera yaw changes the selected relative view without changing world facing
or restarting a hop. Q/E orbit and Home restores north; the enlarged F4 rider
uses exactly the same camera-relative pose as the world character.

## Front and diagonal anatomy correction

The frog now has a broad rounded head, cream lower jaw and subtle nostrils,
rather than a flat mouth line over the torso. Front legs have compact elbows
and webbed hands. Front view uses two hind and two forelimbs; a duplicate foreleg
and duplicate rider layers were removed. Forehands stay planted through the
crouch, with the upper limb compressing toward the shoulder; they tuck in flight.
The muzzle covers shoulder roots for a coherent attachment. The actual
protagonist head textures and the north-facing frog artwork are unchanged.
`preview_frog.gd` reviews the front and diagonal views over two full hop cycles;
see [frog_front_diagonal.gif](previews/frog_front_diagonal.gif).
