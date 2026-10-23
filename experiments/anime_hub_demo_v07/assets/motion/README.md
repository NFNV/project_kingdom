# Character motion assets

Built with the built-in `image_gen.imagegen` tool; selected originals are copied
into this folder without pixel edits. The final exact prompts, original source
paths and guide references are saved in each same-named JSON file.

- `cat_*.png`: eight directions, each with 8 walk, 8 run, and 4 idle poses (160).
  South uses `cat_s_v2.png`; the old `cat_s.png` remains as a comparison reference.
- `warden_*.png`: four diagonal directions, 8 walk and 4 idle poses each (48).
- `cat_baker`, `cat_elder`, `cat_bookseller`, `dog_grocer`, `dog_courier`: eight idle
  and four greeting/occupational poses each (60). Clover reuses the baker set.
- `*_frames.tres`: registered Godot SpriteFrames resources.
- `catalog.json`: per-direction and per-pose body calibration used at runtime.
- `registration.json`: hashes, alpha measurements, detected gutters, source
  regions, anatomical landmarks, and atlas margins for every pose. `foot_margin`
  preserves the old player registration for before/after comparisons.

[Initial prompt set](generation_prompts.json) records the first pass. The selected
player sheets were refined using the [final player prompt set](refinement_prompts.json)
and authored skeleton pose guides in `guides/`. Per-sheet JSON files identify the
actual selected outputs; discarded drafts are not loaded by the game.

The guide drawings are technical references, not in-game character art. Their
folder is excluded from Godot imports. `tools/author_pose_guides.py` and
`tools/render_pose_guides.gd` reproduce the guides; `tools/register_motion.py`
requires Python, Pillow and NumPy to regenerate the native atlas resources. The
playable demo requires only Godot, with no Python dependency.

Animation timing is authored in `motion_sprite.gd`: stride follows ground distance,
walk and run preserve gait phase on direction changes, idle blinks are brief,
and civilian gestures have separate timing. This is prototype painted animation;
remaining pose/identity variations should receive artist cleanup before release.

Player registration follows the connected orange head rather than the lowest boot
pixel, which changes as a foot lifts. Per-pose uniform scale keeps the head size
consistent across all three states, while native texture offsets remove accidental
translation. A small authored bob preserves the walk/run rhythm, and a 75 ms
exponential easing time smooths changes of stance and direction. The original PNGs
are unchanged; silhouettes and limb proportions still reflect the painted poses.
Clover alone mirrors the baker set to face the customer side of the bakery counter;
Pippa's town-facing sprites retain their original direction.

`tools/review_registration.gd` renders a native before/after contact sheet of complete
cycles. `tools/test_hub.gd` checks rendered landmark position, head size, placement,
stance transitions and Clover's facing through idle and every greeting pose.

The south replacement was created with built-in `image_gen.imagegen`; its exact
[creation and eye-correction prompts](front_cycle_v2_prompts.json) accompany the
unmodified selected PNG. It keeps a directly front-facing head/chest and a tail
on screen right throughout walk, run and idle. The prior south sheet alternated
front/angled heads and sometimes changed tail side, which alignment alone could
not repair. `cat_s_v1_reference.json` preserves its metadata and atlas calibration.
The [source-pixel audit](front_cycle_v2_audit.json) detects those old failures and
passes all 20 new poses. These are targeted, character-specific heuristics;
native before/after visual review is still required. Other directions retain their
selected artwork and pose variations remain prototype quality.
