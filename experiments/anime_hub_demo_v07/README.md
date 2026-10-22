# Garden Square — playable painted hub

A small playable Godot scene using the painted anime assets in
[`anime_hub_assets_v06`](../anime_hub_assets_v06/README.md). Explore as the cat
adventurer, finish five deliveries, then challenge Bram's three dog wardens to
a friendly sparring match. NPC dialogue, collision, ground sorting, wind, water
highlights and a four-minute day/night cycle are included.

## Play

Double-click **[Play Garden Square.command](Play%20Garden%20Square.command)** on
this Mac, or open **[demo.tscn](demo.tscn)** in Godot and press **F6**.
The existing project's main scene is preserved.

```sh
/Users/n/Downloads/Godot.app/Contents/MacOS/Godot --path /Users/n/Documents/project-kingdom res://experiments/anime_hub_demo_v07/demo.tscn
```

| Input | Action |
|---|---|
| WASD / arrows | Walk |
| Shift | Run |
| Right click on paving | Walk to that point, navigating around obstacles |
| E | Speak / collect / deliver / post a letter; near Bram, start sparring |
| Space | Swing in the last movement direction |
| Left click | Swing toward the pointer |
| T | Advance to the next lighting state with a smooth transition |
| Esc | Pause / resume |
| R | Restart the demo, including deliveries |
| F11 | Toggle full screen |

Follow the gold arrow: Pippa → Elder Mallow → Moss → Pip → red postbox.
Your current delivery takes interaction priority when several residents are
nearby. Bram's challenge is optional and repeatable. Each opponent yields after
three hits; red ground rings telegraph strikes. Losing restores the cat and
preserves delivery progress.

## Rendering and limits

The game renders a fixed **1920 × 1080** 2D canvas, initially displayed in a
1280 × 720 window, capped at **60 FPS**. Maximizing/full screen scales the same
canvas. Linear filtering and mipmaps are enabled for the painted cutouts.
The 1672 × 941 source background is scaled to the 1080p canvas.

The architecture is a registered painted background, with no tilted building
cards or moving camera. Hand-authored collision footprints keep movement on the
open plaza. Independent objects and characters sort at their ground anchors;
the fountain can obscure characters walking behind it. The baked foreground
facades are kept outside the accessible area. Right-click routes and enemy
pursuit share a padded obstacle grid, with physical collision as the final check.

Dawn/noon/dusk/night backgrounds crossfade while cutouts receive a matching
tint. Border foliage in the painting remains static; separate trees sway.
This is a single hub, with stationary civilian NPCs and no enterable buildings,
save system or audio. Walks use the starter two-pose loops. Combat uses a native
slash effect and hit feedback; dedicated attack/hit animations are still needed.

## Validation

[test_results.json](test_results.json) records the gameplay checks, including
actual keyboard movement, physical collision, navigating around the fountain,
reaching each delivery via normal proximity, melee cones/line of sight,
invulnerability, challenge victory/defeat, day wrap and pause.

[performance.json](performance.json) records native graphical measurements on
the current machine, including walking, three active opponents during a
background crossfade, and a maximized window. It retains long frames rather than
filtering them out. Benchmark-only high health keeps opponents active.

Measured on Apple M1 / Metal / Godot 4.7.2, with the window focused throughout:

| Case | Average FPS | 95th percentile frame | Worst frame |
|---|---:|---:|---:|
| Walking at noon | 59.9 | 17.49 ms | 27.41 ms |
| Three opponents + background transition | 60.0 | 17.50 ms | 20.56 ms |
| Maximized, same combat + transition | 60.0 | 17.02 ms | 18.18 ms |

Each sample lasted six seconds after warmup. These measurements cover this
small hub; they do not guarantee performance on other machines or larger maps.

```sh
Godot --headless --path . --fixed-fps 60 --script res://experiments/anime_hub_demo_v07/tools/test_hub.gd
Godot --path . --script res://experiments/anime_hub_demo_v07/tools/profile_hub.gd
```

The visual preview is saved in [previews/playable.png](previews/playable.png).
