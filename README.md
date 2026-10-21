# Project Kingdom

A small Godot action RPG prototype set on the border between the Dog and Cat
Kingdoms. The current debug slice uses a generated cat warrior as the player
and generated dog warriors as enemies, alongside Tiny Swords environment art.

Explore the forest, fight blue Dog Kingdom patrols, defeat Willow Keep's three
dog sentries, then hold its marked circle for five seconds to raise the red Cat
Kingdom banner.

## Run locally

1. Install the standard GDScript edition of Godot 4.7. This prototype is validated
   with **Godot 4.7.2** and uses Forward+.
2. Download the current **Tiny Swords Free Pack** from
   [Pixel Frog](https://pixelfrog-assets.itch.io/tiny-swords).
3. Extract the pack into `assets/tiny_swords/`. The directory should directly contain
   `Buildings/`, `Terrain/`, `Units/`, `Particle FX/`, and `UI Elements/`.
4. Keep the local generated character atlases at
   `assets/local_characters/cat_warrior.png` and
   `assets/local_characters/dog_warrior.png`. These are separate local assets;
   they are not included in the Tiny Swords download. See
   [character art and prompts](docs/character-art.md) for provenance and setup.
5. Import `project.godot` in Godot and press **F6** with the game scene open, or
   **F5** to run the configured main scene.

The source checkout deliberately omits the artwork. Both the environment pack
and the two local animal atlases are required before import, play, or the
integration checks. F5 starts the cat-player / dog-enemy debug scenario.

On this Mac, the engine is currently at
`/Users/n/Downloads/Godot.app/Contents/MacOS/Godot`. From the project directory:

```sh
"/Users/n/Downloads/Godot.app/Contents/MacOS/Godot" --path .
```

## Controls

| Input | Action |
| --- | --- |
| WASD | Move in eight directions |
| Space or left mouse button, held or tapped | Melee attack toward the last movement direction |
| Escape | Pause / resume |
| R | Restart the slice |

Red attack arcs and the exclamation mark indicate an enemy's windup. Step away
or interrupt the attack with your own strike. Leaving the capture circle, dying,
or a nearby surviving enemy resets capture progress. Defeating all three named
keep sentries is required even if they have been lured outside the circle.

## Implemented

- One authored forest island, red Cat Kingdom outpost, six blue dog enemies,
  a friendly cat guard, and a contested keep.
- Cat and dog warrior art with idle, run, melee, and guard animations.
- Continuous movement, foot-based collision, smooth camera, and static-obstacle
  pathfinding with Godot's native `AStarGrid2D`.
- Directional melee with windup, one hit per target per swing, faction filtering,
  obstacle checks, health, knockback, invulnerability, and simple death effects.
- Patrol, chase, attack, and return behavior with a home-area leash.
- Capture eligibility, interruption, ownership change, and red keep artwork
  when the cat player captures the dogs' blue keep.
- Health, objective, capture feedback, minimap, pause, defeat, victory, and restart.

## Deliberate limits

The generated warriors are first-pass prototype art with one three-quarter view,
mirrored left/right. Each has four frames for idle, run, melee, and guard.
Eight-direction movement and attack rules work independently; the additional
slash arc shows the actual attack direction. Dedicated north/south views and
hand-cleaned final animation remain future work. Hurt/death feedback uses effects.

The friendly outpost guard is stationary. There is no faction-selection screen,
audio, inventory, saving, multiplayer, backend service, or castle interior yet.

## Layout

- `scenes/game.tscn` and `scripts/game.gd`: assemble the session and manage results.
- `scenes/actors/`: shared actor, player, and enemy scenes.
- `scripts/actors/`: presentation and movement, with separate input and AI controllers.
- `resources/characters/`: native SpriteFrames resources for the two local atlases.
- `scripts/combat/`: health and melee rules; damage timing does not depend on rendering.
- `scenes/world/` and `scripts/world/`: authored layout, reusable props, navigation,
  and castle ownership. Only cosmetic trail details use a fixed random seed.
- `scenes/ui/` and `scripts/ui/`: the HUD and pause/result controls.
- `tests/`: Godot integration checks.

The terrain and prop placement are assembled from an explicit layout in
`prototype_map.gd`. They can be moved into editor-authored map resources later.
No networking scaffolding or external dependencies are required.

## Validation

With the artwork installed, import scripts/resources and run checks:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/prototype_tests.gd
godot --headless --path . --quit-after 120
```

Substitute the full executable path if `godot` is not on your shell's PATH.
Visual and hands-on checks remain necessary for camera and combat feel.

## Asset handling

Tiny Swords is by Pixel Frog. Its current published terms allow personal and
commercial game use and modification, but prohibit redistributing the asset
files, including modified versions. See the creator's page for the terms.

`assets/tiny_swords/`, the reference-based `assets/local_characters/` images,
and the generated `.godot/` cache are excluded from Git. Keep any local
adaptations under an excluded artwork directory as well.
Never add the downloaded PNG/Aseprite files or copies of them to source control.
Contributors must obtain the pack separately. Older CC0 releases are a separate
download and must not be assumed to cover the current pack.
