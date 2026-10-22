# Character motion assets

Built with the built-in `image_gen.imagegen` tool; selected originals are copied
into this folder without pixel edits. The final exact prompts, original source
paths and guide references are saved in each same-named JSON file.

- `cat_*.png`: eight directions, each with 8 walk, 8 run, and 4 idle poses (160).
- `warden_*.png`: four diagonal directions, 8 walk and 4 idle poses each (48).
- `cat_baker`, `cat_elder`, `cat_bookseller`, `dog_grocer`, `dog_courier`: eight idle
  and four greeting/occupational poses each (60). Clover reuses the baker set.
- `*_frames.tres`: registered Godot SpriteFrames resources.
- `catalog.json`: per-direction calibration used at runtime.
- `registration.json`: hashes, alpha measurements, detected gutters, source
  regions and ground-anchor margins for every pose.

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
