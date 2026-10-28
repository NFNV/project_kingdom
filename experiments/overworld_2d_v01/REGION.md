# The Greenshire region

The overworld now treats Mosswood as a compact whole-city destination. Building
positions and footprints use 38% of the previous horizontal scale, with a readable
clock-hall skyline, market awnings, fountain, gardens, enclosing walls and a south
gate. The approach shows the whole town with countryside around it. City walls
and roofs still rotate through height-aware 2D drawing when Q/E orbit the camera.

The navigable region is 480 × 560 map units, 3.64 times the previous area. Its
1,494 scenery objects include painted elms, waterside willows, fir groves, limestone
outcrops, a windmill and an ivy-covered ruin. The north road crosses Riverbend's
bridge and branches into a loop through Windsong Ridge and Ivykeep, or east to
Willowmere Lake and Palestone Coast. Trees are kept off road corridors. Lake,
river and sea boundaries block walking; the bridge remains a physical crossing.
Scenery collision uses a 16-unit spatial grid, checked against a full object scan.

Press **M** for a larger north-up region map with roads, water, vegetation areas,
landmark artwork and place names. Movement and animation pause while the map is
open. **Esc** or **M** returns to roaming. **1–8** preview the eight destinations;
these are development shortcuts, not unlocked fast travel.

## Artwork

Four original transparent cutouts were generated with the built-in imagegen tool:

- `art/region/windmill.png`
- `art/region/ruins.png`
- `art/region/pine_grove.png`
- `art/region/coastal_rocks.png`

[Generation manifest](art/region/generation.json) preserves prompts, original output
paths, sizes, SHA-256 hashes and alpha inspection results. Original PNGs are
preserved byte for byte. The game crops transparent margins, reduces textures to
at most 768 pixels high and creates mipmaps in its startup cache; it never rewrites
the source artwork. Elm and willow art is reused from the existing
`anime_hub_assets_v06/scenery` collection. Small bushes, the horizon and the city
are still simplified native drawings. The city is a scale and layout prototype;
its architecture is not final painted production art.

Painted scenery is camera-facing artwork. Its foot follows the curved ground and
its size and draw order follow the camera, but it does not expose new painted
sides during an orbit. The city uses rotating geometry. Additional scenery view
sets would be needed for equally complete all-angle artwork.

## Review

[Whole city](previews/miniature_mosswood.png),
[windmill](previews/windsong_ridge.png),
[lake](previews/willowmere_lake.png),
[ruins](previews/ivykeep_ruins.png),
[coast](previews/palestone_coast.png),
[regional map](previews/greenshire_map.png).

`test_results.json` records 130 checks. New checks sample every branch road at
half-unit spacing (1,477 clear samples outside the two landmark footprints), walk
an actual journey from the bridge's north bank to Windsong Ridge, compare the
collision grid with brute force over 600 positions, check water barriers, verify
whole-city framing and exercise real map/shortcut keyboard input.

This remains a separate prototype. Detailed-location transitions, encounters,
world-map quests and save integration are not connected to the original RPG yet.
