# Windsong Mill

A peaceful, enterable countryside hub at Windsong Ridge in the Greenshire.

From Garden Square, take the southwest road to the overworld. Follow the west
road after the river crossing to Windsong Ridge, or press **5** for its development
shortcut. Near the windmill, press **F** to visit.

The standalone **Play Overworld.command** also supports **5**, then **F**. Since
that art demo has no active RPG journey, it starts a separate mill preview journey
in `user://kingdom_mill_preview.json`; the main RPG save is untouched.

## Garden and backyard

The garden is a compact 1920 × 1280 painted area, with a looping path, grass, flowers,
an apple tree, orchard bench, open backyard gate, herb and vegetable beds,
picnic table and laundry. The original overworld mill artwork supplies the main
building, enlarged from 500 to 750 world pixels high, with its own matching solid
footprint and foreground fading when it hides the cat. Background features and
travel distances are 20% smaller than the first layout, while the cats keep their
existing scale. The garden uses a finer navigation grid for its tighter paths.
Butterflies move over the grass. Mira the gardener and Orin the orchard keeper
are animated cat residents with greetings and their own dialogue.

Walk to the mill steps and press **E** to enter. The south garden gate returns
to the overworld beside the same mill. The garden camera is framed to show the
building on arrival; the main town camera settings return when you leave.

## Hearthroom

The ground floor is a painted cutaway with a millstone and drive shaft, a service
counter, shelves of jars and flour sacks, a hearth and kettle, tea corner, woven
rug and timber stairs. Its playable size is now **1280 × 720**, one-third smaller
in each direction than the first interior. Furniture, collision, entrances and
NPC positions scale together; cats keep their existing size. A 1.5× camera frames
the complete room, making the cats 50% taller on screen than the first version.
Rowan the miller greets the player from behind the counter;
Juniper the travelling reader has a story to share. **E** inspects the tea,
hearth and stair landing. Fireplace sparks and warm indoor ambience accompany
the existing music, with wood footsteps inside and grass footsteps outside.

The room follows the shared twenty-minute day/night cycle. A separately painted
night variant replaces the baked sunlight with blue night windows, dimmer wood
and stone, and warm pools around the existing lanterns and fireplace. Dawn and
dusk blend smoothly; **T** previews the next phase. Pre-dawn stays lamplit. The
counter foreground uses the same blend as the background, so its color stays
consistent while Rowan stands behind it. Characters also receive indoor night
coloring. Native rendered comparisons are saved for dawn, day, dusk, midnight
and 05:08.

The stairs are physically blocked by a rope barrier. Interacting explains that
the loft is closed for repairs. There is no second-floor scene or transition yet.
The front doormat returns to the garden. Furniture and stairs have hand-traced
collision, and the central room remains open for walking.

## Journey and saves

In the main RPG, the same hero and GameState remain active through
town → overworld → mill garden → hearthroom and back. Inventory, equipment,
quests, money, health and shared twenty-minute clock are retained. **I**, **J**,
**F5** and **F9** use the existing inventory, journal and save/load systems.
Both mill locations are valid save destinations. Overworld saving after a mill
visit records a safe mill-garden checkpoint. No quest rewards or purchases have
been added to this peaceful hub.
New garden saves record layout 2; original 2400 × 1600 garden saves are still
accepted and their positions are rescaled before checking the new collision.
New interior saves also record layout 2; unmarked 1920 × 1080 room saves are
rescaled into the smaller room, preserving inventory, equipment, quests and money.

## Art and verification

New garden and interior paintings use **built-in imagegen**. Full prompts,
reference paths, original paths, dimensions and hashes are recorded in
[generation.json](assets/mill/generation.json). The original PNGs are copied
without alteration. The counter's foreground polygon samples the interior's
existing pixels to place Rowan behind it. Garden v2 opens the gate from v1;
v1 remains as the source reference. The midnight painting is an edit of the same
interior, retaining the original canvas and layout. Its saved path, full prompt,
reference, dimensions and hash are recorded in
[night_generation.json](assets/mill/night_generation.json).

`tools/test_mill_hub.gd` checks real F/E entry, physical backyard/room navigation,
NPC greetings, solid planted beds, blocked stairs, save/load in an isolated `/tmp`
slot, retained journey identity, overworld resumption, Garden Square return,
checkpoint recovery and the standalone demo's separate save slot. Run with
`--fixed-fps 60`; add `-- --mill-capture` on a native renderer for screenshots.
Results are in [mill_hub_results.json](mill_hub_results.json).
The suite now also covers smaller-room navigation, original interior-save
migration, actual T input, midnight character coloring and shared counter lighting.
`tools/preview_mill_lighting.gd` checks actual rendered floor glare removal,
night windows, warm hearth contrast and visible cat height; results are in
`mill_room_render_results.json`. It requires the native GPU renderer.

Rendered previews: [garden](previews/mill_garden_entry.png),
[backyard](previews/mill_backyard.png), [room by day](previews/mill_room_day.png),
[room at night](previews/mill_room_night.png).
These are functional and visual checks, not a new 1080p60 performance benchmark.
