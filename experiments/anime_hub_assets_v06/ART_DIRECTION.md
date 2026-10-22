# Garden Square hub — asset pack 06

Create reusable source assets for the original painted-anime hub. Use the
user-selected Garden Square painting for architecture, palette and daily-life
detail, and isometric concept 05 for the gameplay camera and character scale.
The current task is asset preparation, not changing or launching gameplay.

## Shared rules

- Fixed elevated orthographic three-quarter camera, approximately 35 degrees
  down. Roofs and two building walls are visible. Keep verticals upright and
  architectural axes consistent. No horizon, floating diorama or lens distortion.
- Soft gouache/watercolor environment texture and delicate drawn structure;
  clean, softly cel-shaded anime characters. No pixel grid, photorealism, copied
  franchise characters, or heavy medieval architecture.
- Cream plaster, warm stone, teal shutters, blue slate roofs, natural greens;
  red cat accents and blue dog accents. Neutral diffuse light on movable assets.
- Keep paving clear around a central fountain socket. Six permanent rear/side
  building fronts define the plaza. Interactive furniture, people, vendors and
  freestanding trees are separate from the background.
- Cutouts have real alpha, complete uncropped silhouettes, generous padding,
  and no baked floor or long cast shadow. Feet/building bases are the anchors.
- Character sheets use four diagonal isometric directions, one idle and two
  walking poses per direction. This is a starter motion set, not a finished
  combat animation library. Individual NPCs begin as standing cutouts.

## Deliverables

1. One clean noon plaza master, plus dawn, dusk and night relighting studies
   derived from that master. Analyze edge registration before calling these
   crossfade-ready; do not silently claim image edits preserve every pixel.
2. Six separate architecture cutouts: hall, bakery, grocer, bookshop, ivy cottage
   and balcony cottage, in addition to the static background architecture.
3. Cat adventurer and dog warden direction/pose sheets.
4. Baker cat, grocer dog, bookseller cat, elder cat and courier dog NPC cutouts.
5. Separate bakery and produce stalls, without baked-in vendors.
6. Elm, willow, flower planter, fountain, bench, lamp, noticeboard and postbox.
7. Catalog, exact generation prompts/provenance, alpha/registration QA and
   native atlas resources where the generated source permits reliable slicing.

Original PNGs are preserved byte-for-byte. Any runtime lighting/wind resources
must be separate code-native assets. Existing gameplay and experiments remain
unchanged. Source sizes are recorded from actual files, not assumed from prompts.
