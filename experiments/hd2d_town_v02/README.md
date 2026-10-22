# Project Kingdom — HD-2D Garden Street

A playable replacement visual study based on the user's new reference: angled
streets, blue slate roofs, dense planted borders, warm windows, an illustrated
character, foliage shadows, and camera depth of field. The town layout and source
art are original. The main game and the earlier experiment are preserved.

## Run

Open `demo.tscn` in Godot 4.7 and press F6, or run from the repository root:

```sh
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . res://experiments/hd2d_town_v02/demo.tscn
```

WASD/arrows move relative to the screen; Shift runs, Tab changes view, R resets,
F3 toggles the FPS counter, and Esc exits. F5 still starts the existing main game. The scene configures its
own window, camera, and input actions at runtime.

Rendering stays at 1280×720 when the window is enlarged. The FPS counter shows
both frame rate and internal rendering size. Native curbs, fences, and markings
are grouped into shared MultiMesh draws, scenery textures use mipmaps, and
duplicate card shadow meshes have been removed. The default keeps depth of
field and foliage shadows while disabling SSAO and bloom. Frame rate also depends
on other GPU work, window focus, and display timing; the counter and benchmark
are there to verify the behavior under the user's normal conditions.

## Art and implementation

- [Art direction](ART_DIRECTION.md): perspective, scale, palette, and consistency
  rules defined before generation.
- [Assets](assets/): nine original transparent source PNGs — cottage, shop, tree,
  garden flowers, lamp, bench, community board, vintage car, and resident walk sheet.
- [Contact sheet](previews/contact_sheet.png): the nine raster assets together.
- [Rendered demo](previews/hd2d_demo.png): an actual Godot render, not a generated
  full-scene illustration.
- [Generation prompts](generation_prompts.json): exact prompts and source output
  provenance. All raster assets used the built-in image generation tool; the
  cottage established the style for subsequent assets.
- [Catalog](assets/catalog.json): source hashes, non-destructive texture regions,
  and sixteen detected and registered character frame bounds.

Ground, road markings, curbs, drains, and fences are native 3D geometry. Grass,
paving, and asphalt use the reusable procedural `ground.gdshader`; the palette is
converted from sRGB to linear for correct lighting. These cover the original
three ground categories and fence without extra generated PNGs.

The orthographic camera views transparent scenery cards placed in a real 3D
world. Native collision and depth testing determine movement and occlusion.
Cards retain their baked local shading. Directional lighting, batched geometry,
projected foliage masks, depth of field, and drifting motes supply
the environment treatment. Foliage masks are an authored visual approximation;
they are not a light-accurate simulation of a modelled canopy.

The character sheet did not arrive on an exact pixel grid. The catalog tool
detects sixteen silhouettes; native AtlasTexture regions and transparent margins
center them on a shared 180×300 canvas with a common foot baseline. Source pixels
are never edited. Four directions each have four walk frames. Pose variation,
hand/foot shapes, and registration still need an animation artist's review.

## Feasibility and limits

The shared house reference produces substantially more coherent materials and
detail than the previous tiny tile study. Illustrated cards are practical for a
fixed-angle RPG prototype, and the native ground, collisions, shaders, and camera
can be extended independently. The garden sprite and tree are the strongest
repeatable pieces; the buildings establish a recognizable original town palette.

These are prototype assets, not a production pack. Scenery remains flat when
viewed from another angle; the camera must retain its rotation. Source PNGs have
some soft alpha and halos, which the engine cuts off for scenery. Building
colliders approximate their ground footprints, and source perspective is not a
perfect physical match to the underlying geometry. The grass/paving shaders and
repeated planting still need artistic refinement. There are no interiors or
combat changes. Scaling up should focus on artist-authored modular architecture,
more planting variants, tested occlusion, and a polished character animation set.

## Validation and previews

```sh
# Movement, floor contact, collision, frame registration, reset, and camera input:
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --headless --path . --script res://experiments/hd2d_town_v02/tools/test_demo.gd

# Read-only source inspection; rebuild catalog metadata:
python3 experiments/hd2d_town_v02/tools/catalog_assets.py

# Actual renderer captures (require a graphical display):
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . res://experiments/hd2d_town_v02/demo.tscn -- --capture --quit-after-capture
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . --script res://experiments/hd2d_town_v02/tools/render_contact_sheet.gd

# Profile normal launch settings, window resizing, and movement:
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . --script res://experiments/hd2d_town_v02/tools/profile_demo.gd
```

Godot 4.7.2 on Apple M1 / Metal Forward+ was used for rendering. The behavior
suite passes 34 checks. `previews/performance.json` records measured frame rate,
frame-time spikes, focus, render size, and draw calls from the graphical benchmark.
The optimized run measured 120 FPS standing, walking, and maximized with normal
VSync, a fixed 1280×720 render target, and approximately 112 draw calls (previously
664). This does not conclusively isolate the user's earlier small-window slowdown;
the visible counter provides a way to verify the new build during actual use.
Screenshots are exported by Godot from the delivered
assets, not assembled by modifying the raster sources.
