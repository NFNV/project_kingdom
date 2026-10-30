# Windsong Mill

A peaceful countryside mill and inn at Windsong Ridge in the Greenshire.

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
hearth. Fireplace sparks and warm indoor ambience accompany
the existing music, with wood footsteps inside and grass footsteps outside.

The room follows the shared twenty-minute day/night cycle. A separately painted
night variant replaces the baked sunlight with blue night windows, dimmer wood
and stone, and warm pools around the existing lanterns and fireplace. Dawn and
dusk blend smoothly; **T** previews the next phase. Pre-dawn stays lamplit. The
counter foreground uses the same blend as the background, so its color stays
consistent while Rowan stands behind it. Characters also receive indoor night
coloring. Native rendered comparisons are saved for dawn, day, dusk, midnight
and 05:08.

The rope has been removed from both day and night paintings. Walk to the foot
of the stairs on the right and press **E** to visit the guest floor. The front
doormat returns to the garden. Furniture and stairs have hand-traced collision,
and the central room remains open for walking.

## Upstairs inn

The second floor has three furnished guest rooms: **Sage**, **Bluebell** and
**Rose**. Each has its own quilt, bed, bedside lantern, window and chest. Open
doorways connect the rooms to a shared corridor and the return staircase.
The same 1280 × 720 room size and 1.5× camera retain the corrected cat scale.
Walls and furniture block movement; foreground wall pieces hide the lower
body naturally when the cat stands behind a partition. A finer 8px navigation
grid keeps the narrow bedside paths connected.

Press **E** beside any bed to open the rest dialog. Choose **Sleep until 7 AM**
with the mouse or **Enter**; **Tab** switches buttons, and **Esc/E** cancels.
The stay is complimentary. A short fade advances the shared clock to 7 AM,
restores all hearts and the skill cooldown, then leaves the cat beside the
chosen bed. Inventory, equipment, money and quests stay intact. The completed
stay autosaves when journey autosaves are enabled. Rest confirmation freezes
the clock and movement; cancelling does not spend time or change progress.

Upstairs has aligned day/night paintings: blue night windows, warm bedside
lamps and dimmer floors without baked daytime sunbeams. The existing clock
blends them through dawn and dusk. Walk to the stair landing and press **E**
to return to the hearthroom.

## Journey and saves

In the main RPG, the same hero and GameState remain active through
town → overworld → mill garden → hearthroom → guest rooms and back. Inventory, equipment,
quests, money, health and shared twenty-minute clock are retained. **I**, **J**,
**F5** and **F9** use the existing inventory, journal and save/load systems.
All three mill locations are valid save destinations. Overworld saving after a mill
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
The guest-floor paintings and opened-staircase edits are recorded in
[inn_generation.json](assets/mill/inn_generation.json), including full prompts,
source files and hashes. All use built-in imagegen; source PNGs are copied unchanged.

`tools/test_mill_hub.gd` checks real F/E entry, physical backyard/room navigation,
NPC greetings, solid planted beds, the guest-floor stair entry, save/load in an isolated `/tmp`
slot, retained journey identity, overworld resumption, Garden Square return,
checkpoint recovery and the standalone demo's separate save slot. Run with
`--fixed-fps 60`; add `-- --mill-capture` on a native renderer for screenshots.
Results are in [mill_hub_results.json](mill_hub_results.json).
The suite now also covers smaller-room navigation, original interior-save
migration, actual T input, midnight character coloring and shared counter lighting.
`tools/preview_mill_lighting.gd` checks actual rendered floor glare removal,
night windows, warm hearth contrast and visible cat height; results are in
`mill_room_render_results.json`. It requires the native GPU renderer.

`tools/test_windsong_inn.gd` walks the actual cat up and down the stairs and
through all three room doorways, checks furniture collision, keyboard and modal
behavior, sleeps overnight, checks healing and retained journey facts, then saves
and continues upstairs. It uses `/tmp/kingdom-inn-test.json`, never the player's
slot. On the native renderer it also captures day/night and rest-dialog views,
and checks actual window/floor pixels. Results are in `inn_test_results.json`.

Rendered previews: [garden](previews/mill_garden_entry.png),
[backyard](previews/mill_backyard.png), [room by day](previews/mill_room_day.png),
[room at night](previews/mill_room_night.png).
Upstairs: [day](previews/inn_day.png), [night](previews/inn_night.png),
[rest dialog](previews/inn_rest_dialog.png).
These are functional and visual checks, not a new 1080p60 performance benchmark.
