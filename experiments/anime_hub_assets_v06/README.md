# Garden Square — painted anime hub asset pack

An original starter asset pack inspired by the selected Garden Square painting,
using the elevated isometric camera established in concept 05. All 27 source
PNGs were generated with the built-in imagegen tool and copied byte-for-byte.
Existing gameplay, its main scene and prior art remain unchanged.

## Browse the assets

**[Illustrated asset catalog](CATALOG.md)** — every source image and saved path.

Saved native previews: [assembled noon hub](previews/review_0_noon.png),
[character board](previews/review_2_noon.png).

| Group | Source PNGs | Contents |
|---|---:|---|
| Backgrounds | 4 | Same hub at dawn, noon, dusk and night |
| Buildings | 6 | Community hall, bakery, grocer, bookshop, two cottages |
| Main characters | 2 | Cat adventurer and dog warden; 12 poses each |
| NPCs | 5 | Baker cat, grocer dog, bookseller cat, elder cat, courier dog |
| Vendor stalls | 2 | Bakery cart and produce stall, without baked-in vendors |
| Scenery | 8 | Elm, willow, fountain, bench, lamp, noticeboard, postbox, planter |

The four background images include the permanent plaza architecture and border
planting. The separate buildings are reusable matching pieces, rather than a
layer-for-layer extraction of every baked facade. People, stalls, freestanding
trees, fountain and plaza furniture remain independent assets.

## Asset-only Godot review

Open [asset_review.tscn](asset_review.tscn) in Godot 4.7 and press F6. This is an
asset inspection board with a sample hub assembly, not a gameplay demo.

- **1:** assembled hub; **2:** buildings; **3:** characters; **4:** scenery/stalls.
- **Dawn / Noon / Dusk / Night:** select the supplied background and a simple
  matching tint for the placed cutouts. This is preview lighting, not a complete
  runtime lighting system with separate window emission and animated shadows.
- The character page previews the registered direction/walk drafts.
- The two trees demonstrate the included wind shader/materials.
- **Esc:** close the viewer.

```sh
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . res://experiments/anime_hub_assets_v06/asset_review.tscn
```

## Reuse and readiness

The 23 cutout PNGs have genuine alpha. Native `AtlasTexture` resources in
`godot/` trim their transparent borders without changing source pixels.
`catalog.json` records dimensions, opaque regions, nominal foot/base anchors,
suggested display heights and hashes. These are layout aids; collision shapes
and foreground occlusion masks still need authoring when gameplay is integrated.

The two `*_frames.tres` resources provide `idle_se/sw/ne/nw` and
`walk_se/sw/ne/nw`. Each direction has one idle and two walking poses, registered
to a shared canvas and foot baseline. These are motion drafts: they still need
animation cleanup/in-betweens and attack/hit/death poses. The five civilian NPCs
currently have one standing view each. Fountain water is one painted frame.

`elm_wind.tres` and `willow_wind.tres` are CanvasItem shader materials for the
2D cutouts. They displace the upper texture gently while anchoring its root
area, retaining alpha and node modulation. Their source PNG padding allows this
small motion. They are not physical branch rigs or a 3D wind system.

All source PNG imports enable mipmaps for downscaled painted art. Use linear
filtering with mipmaps, rather than nearest filtering. Source dimensions are
recorded as generated; the four background plates are 1672 × 941. The review
uses a 1920 × 1080 canvas and scales the background to fit.

## Four lighting backgrounds

Noon is the shared master. Dawn, dusk and night are lighting edits of that same
image, not independently generated plaza layouts. Each has the same source
dimensions. Read-only gradient phase-correlation checks measured zero global
integer translation and zero integer displacement across 32 sampled local
patches for each variant. See [qa_report.json](qa_report.json).

This supports using them for a prototype transition; it is not a guarantee of
pixel-identical drawing or subpixel registration. Inspect slow crossfades before
production and correct any remaining painted-detail differences. Baked border
foliage remains static; the separate tree assets supply wind movement.

## Validation and provenance

- [Art direction](ART_DIRECTION.md) was written before generation.
- [Exact prompt set](generation_prompts.json) records every prompt, reference,
  transparency request and original generated file path.
- [Machine-readable catalog](catalog.json) records actual source hashes and sizes.
- [PNG/registration QA](qa_report.json): 27 PNGs, 23 transparent cutouts, no
  missing-alpha, source-copy, clipping or pose-partition issues detected.
- [Godot resource validation](godot_validation.json): 93/93 checks passed,
  including source sizes, atlas bounds, shared animation baselines, all review
  pages and all four backgrounds. This does not measure gameplay performance.

```sh
python3 experiments/anime_hub_assets_v06/tools/build_catalog.py
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --headless --path . --script res://experiments/anime_hub_assets_v06/tools/validate_pack.gd
```

The Python helper reads PNGs for metadata/QA and generates native text resources;
it never edits image pixels. If the original external generation files are no
longer available, it checks the saved catalog hashes instead. Runtime resources
use only files inside this pack. The Godot review renders the actual source assets.
