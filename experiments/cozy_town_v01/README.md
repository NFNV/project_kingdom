# Project Kingdom — cozy old-town experiment 01

An original visual-direction experiment for the new warm, nostalgic everyday
town setting. The original static art study is now accompanied by a small walkable
visual demo. This is not a full gameplay milestone or a final production asset
pack. The existing game's files and main scene are unchanged by this experiment.

## Walk around the town

Open `walk_demo.tscn` in Godot and run the current scene with **F6**, or launch
from the repository root:

```sh
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . res://experiments/cozy_town_v01/walk_demo.tscn
```

Use **WASD / arrow keys** to move, **Shift** to run, **Tab** to switch between
the whole-town view and a following close-up camera, **R** to reset, and **Esc**
to quit. The resident uses the existing single pose, mirrored when moving left;
there is no walking animation yet. Props block movement and share depth sorting
with the resident. Buildings use conservative rectangular bounds; other props
use small ground footprints. This demo adds no combat, quests, or interiors.
F5 continues to run the existing game.

The demo's collision and movement checks can be run with:

```sh
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --headless --path . --script res://experiments/cozy_town_v01/tools/test_walk_demo.gd
```

## Deliverables

- [Visual specification](VISUAL_SPEC.md): scale, camera, palette, light, pixel rules,
  composition, and the consistency workflow defined before asset generation.
- [Selected source PNGs](assets/sources/): all 13 requested original asset types.
- [Contact sheet](previews/contact_sheet.png): the actual assets, reuse labels,
  enlarged inspection views, palette, and a common-scale comparison.
- [Sample composition](previews/town_corner.png): an assembled 1280×768 street corner.
- [Native-scale composition](previews/town_corner_native.png): the same layout at
  its 640×384 logical resolution.
- [Feasibility analysis](FEASIBILITY.md): results, limitations, and the next iteration.
- [Generation requests](generation_requests.json): full prompts and cleanup prompts,
  using the built-in image generation tool, plus original output filenames.
- [Asset manifest](asset_manifest.json): source hashes, actual dimensions, Godot
  regions, target sizes, anchors, native scene paths, and readiness classifications.

The contact sheet and street corner are rendered from these delivered asset
sources. They are not separately generated scene illustrations. They include
no art from the existing medieval prototype and no reference screenshots from
another game. The first original house was the palette/material reference for
the rest of this kit.

## The small kit

Sizes below are **logical target bounds**, not claims about source PNG dimensions.
Assets preserve aspect ratio; actual displayed body sizes are in the manifest.

| Asset/source | Target bounds | Current status |
| --- | --- | --- |
| `house.png` | 128×144 | Reusable static scene candidate; not a modular building system |
| `community_shop.png` | 160×144 | Reusable static scene candidate; distinct storefront, similar house massing |
| `tree.png` | 64×96 | Reusable static scene candidate; displayed body is approximately 64×83 |
| `street_lamp.png` | 16×64 | Reusable static scene candidate |
| `fence.png` | 64×32 | Two-tile module candidate; joins need final authoring |
| `bench.png` | 48×32 | Reusable static scene candidate |
| `planter.png` | 32×24 | Reusable static scene candidate |
| `notice_board.png` | 48×56 | Reusable static scene candidate with intentionally blank paper |
| `old_car.png` | 80×40 | Reusable parked-prop candidate; directional versions are absent |
| `resident.png` | 24×40 | One character concept pose; not an animated playable character |
| `grass_tile.png` | 32×32 | Mockup texture, using a selected source excerpt and subdued detail |
| `pavement_tile.png` | 32×32 | Mockup texture; matching edges and curb/corner variants are not authored |
| `road_tile.png` | 32×32 | Mockup texture; matching edges and road transitions are not authored |

No extra NPC was generated: it was optional, and the study prioritizes the
cohesion of this small set.

## Native Godot reuse

Each source has an `AtlasTexture` in `assets/textures/` and a small `Node2D` scene
in `assets/scenes/`. Drag a prop scene into a 2D scene: its origin is the base
contact point, with its source region and world scale already set. These wrappers
are practical prototype assets. They do not provide collision, navigation,
interaction, animation, facade modularity, or canopy/roof occlusion layers.

The ground wrappers draw one 32×32 logical tile. They are not native-resolution
32px PNGs or a production Godot terrain TileSet. That requires a deliberate
native-pixel cleanup/bake, matching edges, and transition/corner tiles.

The selected PNGs are copied byte-for-byte from built-in image generation outputs.
The packaging script uses Pillow to read dimensions/alpha and author metadata;
it does not edit, resize, repaint, or save source raster pixels.

Some generated sources retain diffuse low-opacity halos despite targeted
cleanup prompts. The supplied `pixel_cutout.gdshader` discards alpha below 0.97
and renders the surviving sprite opaque. The previews use this material. It
removes those halos in Godot, but is not a claim that the raw PNGs have clean
production alpha; some colored fringes and thin edge detail still need review.

Grass uses a quiet 256px source excerpt, displayed at 32px, with 25% texture
opacity over a flat `#9CAE7C` base. Both its native wrapper and the preview use
that same treatment. This is a documented presentation adjustment, not a changed
source PNG. It reduces visual noise but does not establish seamless tiling.

## Inspect or regenerate previews

Open `town_corner.tscn` in Godot and run that scene to inspect the static composition.
Its authored layout occupies 640×384 logical pixels. F5 still starts the existing
game, because this study does not change `project.godot`.

To regenerate the final-sized PNGs from the repository root:

```sh
godot --headless --path . --editor --import
godot --path . --script res://experiments/cozy_town_v01/tools/render_previews.gd
```

On the current Mac, substitute
`/Users/n/Downloads/Godot.app/Contents/MacOS/Godot` for `godot` if necessary.
The export step requires a graphical renderer; it cannot capture images through
Godot's headless/dummy renderer. The study was rendered with Godot 4.7.2,
Forward+, and Metal on Apple M1.

`tools/package_assets.py` can rebuild texture and scene wrappers from the copied
sources and requests. It requires Pillow for read-only source inspection. The
sources and prompts are already present; normal preview rendering needs only Godot.

The small curb lines, road markings, and entry paving positions are composition
elements drawn by the preview, not extra generated assets. The notice-board
papers and shop sign are deliberately blank. The original static composition has
no gameplay systems; movement and collision are added only by `walk_demo.tscn`.
