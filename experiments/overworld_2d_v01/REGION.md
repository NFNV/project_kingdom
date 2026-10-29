# The Greenshire region

The overworld now treats Mosswood as a compact whole-city destination. Building
positions and footprints use 38% of the previous horizontal scale, with a readable
clock-hall skyline, market awnings, fountain, gardens, enclosing walls and a south
gate. The approach shows the whole town with countryside around it. A single
hand-painted city illustration now replaces the geometric drawing. Its gateway
is anchored at the existing town entrance; collision and travel remain in place.
The redundant terrain plaza circle is removed. A soft foundation shadow and small
grass tufts blend the painting into the road verge without covering the gateway.

The navigable region is 480 × 560 map units, 3.64 times the previous area. Its
1,593 scenery objects include painted elms, waterside willows, fir groves, limestone
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

The initial four original transparent cutouts were generated with the built-in imagegen tool:

- `art/region/windmill.png`
- `art/region/ruins.png`
- `art/region/pine_grove.png`
- `art/region/coastal_rocks.png`

[Generation manifest](art/region/generation.json) preserves prompts, original output
paths, sizes, SHA-256 hashes and alpha inspection results. Original PNGs are
preserved byte for byte. The game crops transparent margins, reduces textures to
at most 768 pixels high and creates mipmaps in its startup cache; it never rewrites
the source artwork. Elm and willow art is reused from the existing
`anime_hub_assets_v06/scenery` collection. Small bushes remain native drawings.
The painted day and night panoramas
replace the old sky drawing. Two new landmark cutouts add a watermill and
lighthouse, and reused stalls, flowers, benches and lamps provide village dressing.
New source paths and prompts are in `art/region/expansion_generation.json`.
The city and three matching, smaller house illustrations are recorded in
[architecture generation manifest](art/architecture/generation.json). Their source
PNGs are preserved; the runtime limits house and city screen sizes.

Painted scenery and the city each have one authored view. The camera now stays
north-facing and tracks the player; camera rotation is disabled. Feet follow the
curved ground, and size and draw order follow the tracking camera.
Seventeen painted sources now use individual trunk/foundation contact pixels;
see [ground contacts](art/ground_contacts.json). Original PNGs are unchanged.
Wide footprints are hidden before their rear corners extend over the dome's
horizon, with a short fade near the conservative cutoff.

## Review

[Painted city](previews/fixed_city_day.png),
[city at night](previews/fixed_city_night.png),
[matching houses](previews/illustrated_hamlet.png),
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

Garden Square is connected through its southwest exit. Windsong Ridge also opens
the mill garden and enterable hearthroom with F near its windmill. Return through miniature
Mosswood’s south gate. The live journey is retained, and autosaves/F5 store a safe
town or mill-garden checkpoint using the existing save format. Other detailed locations,
encounters and world-map quests are not connected yet. See README.md for travel
controls and checkpoint behavior.
