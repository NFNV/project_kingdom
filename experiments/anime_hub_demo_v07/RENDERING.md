# QHD / 1440p rendering

The current RPG and overworld render to an actual **2560 × 1440** viewport,
including in the normal **1280 × 720** output window. Full screen and window
resizing scale that rendered image for display. The scene is not first rendered
at 1080p and then enlarged.

`tools/render_settings.gd` owns the render target size and 4/3 pixel-density
factor. Existing map, physics and HUD coordinates remain authored at their
original sizes. Camera zoom and CanvasLayer scaling preserve the same field of
view, character proportions and HUD layout. World-following prompts and quest
markers convert through the HUD transform; native GUI input handles the scaled
button hit targets. Saves and game-world coordinates do not change.

The title, HUD, travel fade and standalone/linked overworld all use the same
resolution. Going through the mill garden, hearthroom and inn, then back through
the overworld to town, keeps the higher-resolution render target.

The viewport uses linear texture filtering, replacing the old pixel-art nearest
filter that left CanvasLayer HUD text jagged. Both the shared serif and fallback
fonts use MSDF glyphs so fractional UI scaling stays smooth. The painted clock
and skill icon use mipmaps with linear filtering for their reduced display sizes.

`tools/preview_render_1440.gd` verifies actual GPU image dimensions, camera field
of view, GUI scale, prompt projection, real title/skill mouse input, travel and
window resizing. It writes screenshots under `previews/qhd_*` and a report at
`render_1440_results.json`, using only an isolated temporary save path.

Previews: [town](previews/qhd_town.png), [combat](previews/qhd_combat.png),
[inn](previews/qhd_inn.png), [overworld](previews/qhd_overworld_night.png).

Artwork retains its original resolution; increasing the viewport does not add
new painted detail to existing PNGs. Earlier 1080p performance reports remain
historical measurements. The fixed-FPS render checks do not establish 1440p60.
