# Project Kingdom — cozy old-town study 01

Date: 2026-10-21. Status: exploratory art direction, not a final production pack.

## Direction

An original, inviting old town with quiet streets, familiar shops, gardens,
community spaces, and vintage everyday details. Warmth, nostalgia, and a sense
of ordinary life provide the setting for a future small action RPG.

The emotional brief references the warmth of Ni no Kuni's everyday town
environments. No screenshots, named locations, compositions, characters, or UI
from that game are used as production references. The existing medieval pack
and the earlier warrior characters are not visual references for this study.

This experiment adds no combat, movement, faction rules, or other game systems.
It does not replace the project's main scene. Character design is an everyday
town resident concept; cat/dog faction design is deferred.

## Technical and visual rules

| Item | Target at logical/native game scale |
| --- | --- |
| Ground grid | 32×32 pixels; axis-aligned streets, not an isometric diamond grid |
| Composition | 640×384 logical pixels, 20×12 ground tiles |
| Character | Approximately 24×40 pixels, about three heads tall |
| Doors | About 24×40–44 pixels; entrances remain visually obvious |
| House | Approximately 128×144 pixels including roof, with a compact ground footprint |
| Shop/community building | Approximately 160×144 pixels including roof |
| Tree | Approximately 64×96 pixels; readable canopy masses and visible trunk |
| Street lamp | Approximately 16×64 pixels |
| Fence section | 32px grid; selected six-picket candidate uses a 64×32 two-tile module |
| Bench | Approximately 48×32 pixels |
| Planter | Approximately 32×24 pixels |
| Community notice board | Approximately 48×56 pixels |
| Old car | Approximately 80×40 pixels, with roof/hood visible |
| Perspective | Elevated orthographic three-quarter view, south-facing facades, parallel edges |
| Light | Warm daylight from upper-left; short shadows down-right |
| Shading | Three or four broad tones per material, clustered texture, little dithering |
| Outlines | Selective one-logical-pixel colored edges; no heavy black perimeter |
| Presentation | Nearest filtering at logical scale; integer enlargement for inspection |

Dimensions are authoring targets and scene placement sizes. The image generator
may return larger images with imprecise pixel grids. Source dimensions and
normalization are recorded separately; a scaled image is not automatically a
pixel-perfect native-resolution production asset.

The character is the scale ruler. Doors should comfortably admit the character,
sidewalks should allow two people to pass, cars should read as roughly two
character-heights long, and a tree should feel two to three characters tall.
Contact points at the feet, trunk, lamp base, wheels, and building thresholds
anchor sprites to the same ground plane. Transparent canvas size is not used
as a collision or object footprint.

## Palette direction

These are palette anchors, not a claim that generated sources use an indexed
palette. Exact palette reduction is a later production step.

| Role | Anchor |
| --- | --- |
| Warm highlight | `#F7E7BF` |
| Cream plaster | `#E8D5B0` |
| Terracotta roof | `#B96F58` |
| Painted teal wood | `#547A79` |
| Sage grass | `#9CAE7C` |
| Deep foliage | `#405D4E` |
| Biscuit paving | `#CAB79F` |
| Warm gray road | `#847F77` |
| Muted ochre accent | `#D3AB59` |
| Dusty coral accent | `#CF8875` |
| Plum-gray shadow | `#524B5B` |

Most of the scene uses restrained midtones. Stronger warmth and saturation are
reserved for flowers, shop trim, doors, and the playable character's jacket.
Ground textures must remain quieter than objects and characters. The same
cream, teal, terracotta, and shadow families connect different materials.

## Keeping the town rich and readable

- Cluster details near entrances, windows, benches, and the notice board.
- Preserve broad, legible sidewalk and road areas between those clusters.
- Use large canopy and roof shapes before adding small decorative pixels.
- Avoid equally dense texture everywhere, random one-pixel noise, and bright
  outlines around every prop.
- Suggest age through a few broad wear marks and softened colors, not grime.
- Reuse small props intentionally; avoid a repeated identical building facade
  becoming the entire visual vocabulary of the town.

## Consistency workflow

1. Generate an original house using only this written brief. Select it as the
   canonical reference for palette, surfaces, roof shapes, perspective, and light.
2. Generate each other requested asset separately, using that original house
   and the same written style rules as references. No earlier game assets are used.
3. Inspect transparency, silhouettes, camera, materials, apparent scale, and
   separation from the background. Preserve source PNGs without destructive edits.
4. Author Godot texture regions and placement sizes. Use explicit anchors;
   do not let arbitrary transparent padding determine scale or placement.
5. Assemble a static street corner and a labeled contact sheet from the actual
   delivered asset sources. These are assembled previews, not independently
   generated pictures pretending to demonstrate interoperability.
6. Record reuse status, seam limitations, style drift, and required cleanup.

## Production threshold

A production tile must have verified matching edges and a consistent native
pixel grid. A production sprite needs a controlled palette, a deliberate anchor,
clean alpha, and predictable dimensions. Buildings need modular companions and
occlusion/footprint authoring. A single character pose is concept art until it
has a coherent directional animation set.

This experiment evaluates whether the visual vocabulary and assembly approach
are promising. It does not claim those production requirements are completed.
