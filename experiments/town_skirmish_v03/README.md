# Project Kingdom — Cats & Dogs: Garden Hall

A playable action/capture demo in the new cozy town: red cat player, friendly
cat outpost guard, six blue dog enemies, melee combat, health, navigation, and a
contested capture objective. Dogs wait until the player's first movement or
attack, so the opening scene is safe to inspect.

## Play

Open `demo.tscn` in Godot 4.7 and press F6, or run from the repository root:

```sh
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . res://experiments/town_skirmish_v03/demo.tscn
```

- WASD/arrows: move; Shift: run.
- Space: attack in the movement/facing direction. Left mouse: attack toward cursor.
- Clear dog enemies near Garden Hall, then stand in its blue ring for four seconds.
  Dogs within 5.5 metres contest capture. Leaving the ring lets progress decay.
- Esc: pause/resume. R: fresh battle. Tab: wider view. F3: toggle FPS counter.
- Close the window to exit. F5 still runs the original main game.

Dogs patrol, chase within their territory, follow paths around solid footprints,
and wind up before attacking. Swings hit once per target, skip allies and enemies
behind the attacker, and cannot damage through buildings. Player damage has a
short grace period. Victory and defeat both provide a restart prompt.

## The crooked-building correction

The earlier version placed pre-perspectived building images on flat camera-facing
cards. Their baked perspective could disagree with the real ground and camera.
Here, both buildings have actual mesh walls, gables, sloped roof faces, ridge
caps, fascia, chimney, windows, doors, and steps. Garden Hall adds a native striped
awning. Street, foundations, and roof endpoints share the same world grid; their
projection comes from one orthographic camera. No cottage/shop image cards are
used. Tests verify shared axes, projected foundation alignment, and roof normals.

The 1080p pass adds louvered shutters, recessed frames, painted curtains and sky
reflections, a cottage porch, segmented ridge caps, cornices, gutters, foundation
masonry, and a framed hall sign. Material-local cavity shading and soft fighter
contact shadows add depth without a full-screen ambient-occlusion pass.
Decorative details are batched at world coordinates; these are generated town structures, not a complete modular
building editor. Movement remains on ground level; there are no interiors.

Trees and small props reuse the prior illustrated scenery. A tree fades when its
card covers the player, preserving visibility. The warriors reuse the original
cat/dog idle, run, attack, and guard animations with horizontal mirroring; they
are not a new four-direction character set.

## Assets and provenance

- [Art rules](ART_DIRECTION.md) were written before material generation.
- [New materials](assets/) are original warm plaster and blue slate PNGs, generated
  with the built-in imagegen tool using the prior cottage as a palette/material
  reference. They are flat texture swatches, not perspective building images.
- [Exact prompts](generation_prompts.json) include output provenance.
- [Character assets](assets/characters/) package byte-identical copies of the
  earlier original cat/dog PNGs with their existing native animation regions.
  They are included here so this demo does not depend on ignored local art paths.
- Shared tree, garden, lamp, bench, board, car, and base scene
  utilities live in `experiments/hd2d_town_v02/`.
- [Actual rendered scene](previews/town_skirmish.png) comes from Godot.

Generated materials are exploratory; repeated seams, texel density, architecture
detail, and character direction coverage still need art refinement. Source PNGs
are preserved; the renderer uses mipmaps and native texture/material resources.
No Tiny Swords environment art is used.

## Performance and validation

The scene renders at **native 1920×1080**, targets **60 FPS**, and keeps this
render size when maximized on Retina displays. There is no dynamic resolution
or 3D upscaling. FXAA smooths geometry edges; mipmapped scenery and derivative-
filtered terrain grain reduce shimmer. Shared mesh batches keep architectural
detail cheap. Physics interpolation smooths fighters and the following camera.
SSAO and bloom are off; material-local shading, geometric sun shadows, soft
contact shadows, and subtle depth of field remain. The HUD is sized for 1080p.

```sh
# Movement, combat, AI, occlusion, capture, pause/restart, and geometry alignment:
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --headless --path . --script res://experiments/town_skirmish_v03/tools/test_skirmish.gd

# Normal 60 FPS launch settings; active combat, resizing, and camera turns:
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . --script res://experiments/town_skirmish_v03/tools/profile_skirmish.gd

# Separate uncapped headroom pass (does not alter normal launch settings):
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . --script res://experiments/town_skirmish_v03/tools/profile_skirmish.gd -- --uncapped

# Render preview and exit:
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path . res://experiments/town_skirmish_v03/demo.tscn -- --capture --quit-after-capture
```

The behavior suite passes **55 checks**, including outward-facing gables and
unchanged 1080p output after window resizing. [Performance results](previews/performance.json)
record wall-clock frame intervals, p95/p99, worst frame, counts above 20/33 ms,
focus, draw calls, render scale, and output size. Benchmark-only high health
keeps both sides alive; normal balance is unchanged. The optional uncapped
command writes a separate report without changing normal launch settings.

On this Apple M1 with Godot 4.7.2 / Metal Forward+, the final capped foreground
run measured **59.9–60.0 FPS** across the three cases. P95 frame intervals were
17.24–17.60 ms. Normal combat and running-camera combat had no frames above
20 ms; maximized combat had one 51.86 ms frame. Earlier tuning runs also showed
occasional stalls. These are short warmed measurements, not a guarantee of a
perfectly locked rate in every condition. The visible counter uses wall-clock
time, reports the actual render size and maximum frame interval each second,
and remains available with F3.
