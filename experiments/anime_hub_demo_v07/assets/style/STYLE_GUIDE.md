# Mosswood painted town style

Garden Square is the visual reference: a warm, hand-painted anime town with
cream limestone, teal joinery, slate roofs, honey oak and lively foliage.
Architecture, interiors and characters should belong to that same world.

## Materials and palette

- Walls: warm ivory and pale cream, broad gouache marks, sparse stone patches.
- Roofs: overlapping slate shingles, mostly blue-grey; muted terracotta, sage
  and mauve variations use the same tile shapes and scale.
- Streets: cool blue-grey cobbles, framed by warm limestone paving and curbs.
- Lawns: painted sage/moss grass and small clover clusters, using `park_grass_v1.png`.
- Joinery: weathered teal, cream stone surrounds, honey oak, small brass fittings.
- Interiors: the same plaster and oak, teal wainscoting and soft window light.
- Characters: existing identities and proportions, gently softened dark pigment
  and warm highlights through a shared material before time-of-day tinting.
- Night: warm selected window panes and lantern pools against cool blue streets;
  the pane meshes use the same wall coordinates and follow facade occlusion.

`tools/art_style.gd` owns the palette, texture regions and shared character
material. `town_materials_v1.png` contains six materials in a 3×2 atlas;
`town_details_v1.png` contains two windows and two doors. The latter is registered
against its actual transparent row gap in `catalog.json`, rather than assuming
the generated grid is exact. All original PNG pixels remain unchanged.

## Projection and readability

Town ground axes are `(240,120)` and `(-240,120)`; every building vertical is
exactly vertical. The bakery uses the same 2:1 projection at room scale.
Facade details are front elevations mapped onto native walls. Buildings keep
their existing eight recipes, collision footprints, door frontage and paths.
The normal camera stays at 1.5× and the internal canvas stays 1920×1080.

Architecture and street paint are cached once per zone; texture regions and the
character material are shared. New art should preserve that rendering budget.
Use broad readable shapes before fine surface noise. Keep walking silhouettes
and interaction prompts clear against busy backgrounds.

## Sources and scope

The two new atlases and matching grass were made with built-in imagegen. Exact
prompts, style inputs and original paths are in `generation.json`,
`details_generation.json` and `grass_generation.json`.
The existing Garden Square lighting paintings, foliage, fountain, furniture and
character drawings remain the reference art. This pass replaces Northgate's
flat surfaces and plain detail variants, dresses the bakery's walls and floor,
and harmonizes character pigment; it does not redraw every historical asset.

Native captures: `previews/style_garden_square.png`, `style_market.png`,
`style_plaza.png`, `style_park.png`, `style_bakery_day.png`,
`style_bakery_night.png` and `style_market_night.png`.
