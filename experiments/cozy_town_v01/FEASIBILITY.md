# Feasibility — cozy old-town study 01

## Finding

This approach can establish a coherent, original art direction and furnish a
small explorable-town prototype. It has not produced a production-ready,
native-resolution pixel-art pack automatically.

The strongest result is the shared vocabulary: cream plaster, terracotta roofs
and planters, dusty teal joinery/metal, warm wood, sage foliage, and a coral-clad
resident. These choices remain recognizable when the delivered assets are placed
together in Godot. The scene reads as an everyday neighborhood rather than a
castle settlement.

The important limitation is the gap between an attractive generated image and
a controlled game asset. Real source dimensions differ substantially from the
requested logical sizes. Palette values, pixel clusters, alpha, scale, and tile
edges still require deliberate art direction and technical handling.

## What worked well

- Generating the first original house as a canonical material reference kept
  subsequent roofs, window frames, warm highlights, and shadows related.
- A small set is enough to suggest a place: two facades, a parked car, civic
  furniture, repeated plants, a fence with an entrance, and one resident.
- The cream/terracotta/teal palette links architecture and street furniture
  without making every object the same color.
- Native texture regions, explicit ground anchors, consistent logical bounds,
  and shared alpha treatment make the image candidates assemble predictably.
- A common-scale preview exposed issues that enlarged source images concealed.
  In particular, reducing a dense grass source to 32px initially made the entire
  lawn noisy. A selected excerpt and a restrained 25% detail layer help the ground
  recede behind objects and characters.

## What was hardest

**Strict pixel discipline.** Requesting pixel art or a 32px tile did not guarantee
an exact native grid or a small indexed palette. The delivered source images are
high-resolution, pixel-styled images. Their material color families are coherent,
but their pixel density and detail frequency vary. Nearest filtering makes their
presentation crisp; it does not convert them into carefully authored native art.

**Alpha and edges.** Several first outputs contained diffuse colored halos. One
targeted cleanup pass per affected asset did not consistently remove them.
The Godot cutout material makes these candidates usable in the assembled preview,
while the raw images still need proper alpha/edge cleanup. This is a genuine
generator limitation observed in the experiment, not finished production work.

**Scale and perspective.** Each image arrived with different padding and apparent
proportions. The manifest and native scene wrappers normalize their base contact
points and fit them within the target bounds. The resident ends up approximately
15×40 pixels, and the tree approximately 64×83, despite larger target bounds.
The car is somewhat more side-facing and the resident more detailed than ideal
for a rigorously uniform camera/pixel language. Door-to-character scale needs a
dedicated second pass before animation or movement work.

**Variety without style drift.** The shop shares much of the house's roof/chimney
massing. That is useful evidence of cohesion, but repeating it across a whole town
would be monotonous. More architecture must vary structure while keeping the
same materials, light, and edge language.

## Reuse and readiness

| Category | What is usable now | What is not completed |
| --- | --- | --- |
| Lamp, bench, planter, notice board | Small reusable Godot scene candidates with consistent anchors and scale | Source alpha cleanup, native-pixel retouch, interaction/footprints |
| Tree | A reusable static scene with a readable canopy | Variants, animation, canopy/trunk separation, occlusion rules |
| Fence | A reusable horizontal two-tile candidate | Precisely matching posts/rails, corner, end, and gate pieces |
| House and shop | Reusable facade candidates for visual layouts | Modular walls/roofs, alternate heights/facings, entrances/interiors |
| Vintage car | A reusable parked prop candidate | Camera consistency, directional views, movement animation |
| Three ground textures | Mockup materials demonstrated in repeated samples | Seamless/native 32px tiles, palette control, curbs, corners, transitions |
| Resident | A clothing, silhouette, palette, and scale concept | A clean native sprite, multiple facings, idle/walk/combat animation |
| Town composition | A static mock scene assembled from this kit | Movement, collision, gameplay, performance validation for a large world |

No asset is labeled final production-ready. The reusable classifications refer
to the native wrappers' immediate usefulness for further visual prototyping.

## Tile assessment

The source textures are not designed seam-locked assets. A read-only edge
diagnostic is included in `validation.json`; nonzero differences at wrap edges
confirm that exact edge matching has not been established. Numerical edge
differences alone do not predict whether a seam will be objectionable: the repeated
contact-sheet samples remain the relevant visual inspection.

The grass excerpt has an obvious repeated motif when inspected closely. The
low-contrast ground treatment keeps it less distracting in the town scene, but
needs two or three properly authored variants before it can support a larger
park. Paving has a regular checker rhythm and needs larger/slightly varied slab
modules and transition pieces. Road material is calm at scene scale but still
contains finer texture than the broad-cluster specification calls for.

## Could this scale to a small RPG world?

Yes, with a controlled asset pipeline and a modest manual art pass. The prop
scenes are already reusable, and a limited palette plus an explicit scale ruler
can keep a few streets and a park coherent. The visual vocabulary is promising
enough to justify another focused iteration.

It should not scale by generating hundreds of unrelated finished pictures.
Buildings need a modular family, ground needs true terrain tiles, and characters
need a stable animation model. Those production tasks are more demanding than
generating extra decorative props. Large-world performance, memory, navigation,
and lighting have not been validated by this static study.

## Recommended next iteration

1. Lock the resident's native 24×40 bounding canvas and exact door/bench/car scale.
   Retouch one standing pose on a real pixel grid before requesting animations.
2. Finish three native 32px ground materials, edge-matched variants, and sidewalk
   curbs/corners. Reduce the current paving rhythm and grass repetition.
3. Clean alpha, reduce the palette, and standardize pixel clusters on the existing
   lamp, bench, planter, tree, and one building. Replace preview-only cutout needs
   with clean source assets and separate shadows.
4. Build one small architectural family with a different roof silhouette, one
   corner facade, and interchangeable windows/doors; avoid expanding the whole town.
5. Assemble the same block again at native scale. If it holds together, create
   a four-facing idle/walk study for the resident and consider a walkable visual
   slice as a separate later task.

Additional gameplay systems and a 3D comparison are not needed to answer the
next art-direction questions.
