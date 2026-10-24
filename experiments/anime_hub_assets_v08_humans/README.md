# Human citizens — asset pack

Four adult humans in the town's painted anime style. Each has four transparent
directional idle views: front right (SE), front left (SW), back right (NE), and
back left (NW). These are turnaround/idle assets; walking, running, and gestures
are future animation work. The [playable demo](../anime_hub_demo_v07/README.md)
now includes all four as friendly NPCs: Rhea, Captain Alden, Iris, and Tomas.
Their controller adds turning, subtle idle breathing and a conversation nod while
preserving the foot anchor; the existing animal residents remain in the square.

| Character | Role | World height | Height versus animals |
|---|---|---:|---:|
| Wayfarer | Traveller / adventurer | 172 px | 1.59× |
| Town Warden | Civic guard | 180 px | 1.67× |
| Herbalist | Shopkeeper / healer | 168 px | 1.56× |
| Blacksmith | Town craftsperson | 178 px | 1.65× |

The existing cat and dog render at 108 world pixels. Heights include the complete
figure from the lowest boot to the top of the hair/hat/ears, before camera zoom.
All comparison figures share a ground baseline and display scale. Humans have
adult proportions and longer legs, rather than enlarged animal/chibi proportions.

- `characters/`: four selected PNG sheets, copied unchanged from built-in
  `image_gen.imagegen` outputs. Each is 2 columns × 2 rows; 16 human views total.
- `resources/`: four native Godot SpriteFrames resources, each with one frame in
  `idle_se`, `idle_sw`, `idle_ne`, and `idle_nw`.
- [catalog.json](catalog.json): source hashes, alpha measurements, regions,
  foot anchors, native margins and recommended sizes for every view.
- [generation_prompts.json](generation_prompts.json): exact prompts, selected
  originals and style references. No external API or CLI generation was used.
- [Scale lineup](previews/human_scale_lineup.png) and
  [all directional views](previews/human_turnarounds.png): native Godot renders.

## Preview

Open `human_preview.tscn` in the existing Godot project and press F6. Tab switches
between the lineup and the four-view gallery; 1–4 selects a common facing in the
lineup. The preview uses the existing animal sprites for an accurate comparison.

```sh
Godot --path . res://experiments/anime_hub_assets_v08_humans/human_preview.tscn
Godot --path . res://experiments/anime_hub_assets_v08_humans/human_preview.tscn -- --capture
Godot --path . res://experiments/anime_hub_assets_v08_humans/human_preview.tscn -- --capture --four-views
```

## Native use

Assign the desired resource from `resources/` to an AnimatedSprite2D. Set
`centered = false`, `offset = Vector2(-512, -984)`, and select an `idle_*`
animation. Its foot origin is then the node position. Scale the sprite using
`recommended_height_at_1080p / frames[direction].height` from the catalog;
the transparent 1024×1024 atlas canvas is not the character's visible height.
The preview demonstrates this calibration for all 16 views. Native AtlasTexture
margins trim/register the source artwork without rewriting PNG pixels.

`tools/register_humans.py` regenerates the catalog and native resources from the
selected originals, using Python, Pillow and NumPy. Godot handles playback without
Python. Registration checks genuine transparency, clear sheet gutters, complete
frame bounds and a minimum 1.5× human/animal height ratio. All four source copies
are checked byte for byte. Native previews verify that the resources load, the
alpha displays correctly and the intended size difference is visible.

The artwork is a prototype. Fine facial, costume and accessory details can vary
between views; animation authoring should preserve one consistent character model.
