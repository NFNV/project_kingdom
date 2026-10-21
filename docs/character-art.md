# Prototype animal warriors

The debug scenario runs a red Cat Kingdom player against blue Dog Kingdom
patrols and keep sentries. The outpost guard is a friendly cat.

Both atlases were generated with Codex's built-in image generation tool using
the locally installed Tiny Swords Warrior sprites as style references. The dog
generation also used the completed cat atlas to keep the pair visually coherent.
No external API key or CLI generation was used.

## Files and integration

- `assets/local_characters/cat_warrior.png`: generated cat atlas, 1254×1254 RGBA.
- `assets/local_characters/dog_warrior.png`: generated dog atlas, 1254×1254 RGBA.
- `resources/characters/cat_warrior.tres`: native Godot SpriteFrames resource.
- `resources/characters/dog_warrior.tres`: native Godot SpriteFrames resource.

Each atlas contains four rows of four animation poses: idle, run, melee attack,
and guard. Idle and guard run at 5 FPS; run and player attacks at 10 FPS. Enemy
attack playback is slowed to make its anticipation match the longer windup.

The generator did not return the exact requested pixel dimensions or uniform
row baselines. The PNGs are preserved byte-for-byte, including their alpha;
explicit AtlasTexture regions and margins normalize all frames to a 320×320
logical canvas with the contact shadow at y=288. Runtime scale is 0.4, keeping
the warriors close to the original human knight's world size. The final attack
cell excludes a detached neighboring slash fragment through its source region.

These are first-pass prototype animations. They have one three-quarter view,
mirrored left/right. Eight-direction movement and directional combat use the
existing gameplay rules and slash indicator. Dedicated north/south views and
hand-cleaned production animations remain future art work.

The reference-based PNGs and their import metadata are kept local under the
ignored `assets/local_characters/` directory. Do not publish them as part of the
source repository. A source-only checkout needs both local PNGs, alongside the
Tiny Swords pack, to run this scenario. Regeneration requires generating the
art again and authoring regions for that output; prompts do not guarantee exact
pixel-identical atlases.

## Final cat generation prompt

```text
Use case: stylized-concept
Asset type: production 2D game animation sprite atlas, transparent PNG.
Primary request: Draw one anthropomorphic CAT medieval warrior compatible with the proportions, viewpoint, restrained pixel detail and outlines of the provided Tiny Swords knight references, for use as the playable hero in Project Kingdom.
Input images: Image 1 is a reference for the existing game's chibi knight proportions and pixel-art language. Image 2 is a reference for sword-swing motion and red faction armor. These are style references, not pixels to paste. Draw a new animal warrior, not a human with a cat hat.
Subject: one consistent cream-and-orange tabby cat knight, clearly feline face with short muzzle, pointed ears visible above an open steel helmet, amber eyes, whisker marks, curved striped tail. Small stocky humanoid armored body, dark blue-gray steel plate, muted crimson-red tabard and shield with simple gold edging, one short silver sword. Feline ears, face and tail must remain readable at small gameplay scale.
Composition: EXACTLY 4 columns by 4 rows, sixteen isolated full-body sprites, equal 256 by 256 pixel cells on a 1024 by 1024 transparent canvas. No gutters, no labels, no grid lines, no border. Same right-facing three-quarter overhead game camera in all sixteen cells. Every character centered at local x=128, feet baseline y=224 in its own cell. Body without sword about 125 pixels wide and 145 pixels high. Generous transparent margin. No overlapping neighboring cells or cropped ears/tails/weapons.
Animation order, left to right:
Row 1: four subtle idle breathing poses, feet grounded, sword at ready.
Row 2: four successive RUN cycle poses, alternating legs with readable stride and small body bob. Keep body, face, tail, and equipment consistent.
Row 3: four successive MELEE attack poses: ready, raised-sword anticipation, broad forward sword slash with a small pale arc, follow-through. Rightward attack direction.
Row 4: four successive GUARD poses, shield raised in front, subtle breathing.
Style: actual crisp pixel art with hard square pixel edges, chunky color clusters, no smooth vector outlines, no painterly gradients, no anti-aliased illustration. Charming sturdy Tiny Swords-like proportions, head about one third of the character height, bright readable simple forms, dark desaturated outline, top-left lighting. Same character identity and equipment in every cell. Not a concept sheet or sticker collection.
Background: genuinely transparent alpha, including the spaces between sprites. Only a small subtle oval contact shadow directly under each character, no scenery or checkerboard painted into the image.
Text: none. Avoid text, numbers, captions, logos, extra limbs, duplicate swords, inconsistent armor colors or multiple characters within a cell.
```

## Final dog generation prompt

```text
Use case: stylized-concept
Asset type: production 2D game animation sprite atlas, transparent PNG.
Primary request: Draw one anthropomorphic DOG medieval warrior for Project Kingdom, matching the companion cat warrior atlas and the existing Tiny Swords knight references. Dogs are blue-faction enemies in the debug prototype.
Input images: Image 1 is the companion CAT atlas: match its actual pixel-art character scale, four-by-four layout, armor rendering, animation readability and three-quarter camera. Image 2 is the original Tiny Swords knight style reference for BLUE faction colors and proportions. These are references, not pixels to paste. Draw a new canine warrior, not a human wearing a dog hat, and do not include cats in the result.
Subject: the same stocky tan-and-cream DOG knight in every cell: broad rounded canine muzzle, clearly visible black dog nose, determined dark eyes and brows, brown floppy ears extending from an open steel helmet, short thick tan dog tail. Dark navy-gray steel plate, BLUE tabard and blue kite shield edged with gold, a short silver sword. Canine muzzle and floppy ears must clearly distinguish him from the sharp-eared cat hero. Keep helmet, sword, shield and fur markings consistent.
Composition: EXACTLY 4 columns by 4 rows, sixteen separate full-body sprites, equal cells, on a square 1280 by 1280 transparent canvas. Each cell is 320 by 320. No gutters, labels, grid lines or borders. Same right-facing three-quarter overhead game view in all cells. Center the stationary torso at cell x=160; feet on baseline y=288. Body height about 205 pixels including ears. Transparent margin all around; no cropped weapons or overlap with a neighboring cell.
Animation left to right:
Row 1: four idle breathing frames, sword ready and shield at side.
Row 2: four successive run-cycle frames with alternating legs and small body bob.
Row 3: four successive melee frames: ready, raised-sword windup, forward sword slash with a restrained pale arc, follow-through. Rightward attack.
Row 4: four guard frames, shield raised, subtle breathing.
Style: crisp fantasy PIXEL ART, chunky square-pixel color clusters, dark desaturated outlines and modest palette. Same chibi top-down character style as the companion cat. Warm top-left illumination. No smooth vector outlines, painterly brushwork, airbrushed gradients or high-resolution illustration details. Make the sixteen sprites consistent animation frames, not unrelated concept poses.
Background: genuine transparent alpha between and around all sprites, with only a restrained small oval contact shadow underneath each character. No painted checkerboard, scenery, platform or background.
Text: none. Avoid captions, numbers, logos, extra limbs, extra swords, cats, humans, armor drift or inconsistent head size.
```
