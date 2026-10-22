# Project Kingdom — HD-2D town study 02

The supplied reference corrects the first study's visual direction: a close,
angled street scene, abundant gardens, blue slate roofs, warm stone pavement,
dappled light, and a readable small character. This study uses an original layout
and original building designs, with no copied insignia or signage.

## Rules before generation

- Actual 3D ground and collision; illustrated transparent sprite scenery in 3D.
  An orthographic camera looks from southeast, approximately 34 degrees above
  the ground. Screen-right roof edges descend approximately 20 degrees.
- The street is about 5 metres wide. Houses are about 6 metres tall; the resident
  is about 1.6 metres tall. Texture detail is dense, unlike the previous 32px kit.
- Crisp clustered pixel-like illustration with small edge steps and rich material
  detail, not flat low-resolution tiles. Source images remain intact. Their world
  scale is specified per asset rather than claiming a uniform native pixel grid.
- Pale warm plaster, aged timber, blue slate, amber lamps, ivory paving, dark
  desaturated asphalt, deep green shadows, bright yellow-green leaf highlights.
- Sunlight comes from the upper left. Source props have baked local shading;
  the engine supplies ground lighting and directional cast shadows. Leaves and
  flowers repeat at different sizes to create planted borders, not isolated props.
- The first generated house establishes the source-art palette and material
  treatment. Subsequent props use that house as their style reference, with the
  same elevated camera and light direction. Character art uses the same palette.
- Quiet, compact UI over a full scene; no large editor/debug panels. Subtle bloom,
  light atmospheric motes, and foreground foliage provide depth without hiding
  the walkable road and sidewalks.

## Prototype boundary

This is a fixed-angle hybrid diorama, not a fully modelled 3D town. Transparent
scenery cards are reusable at this camera angle; rotating the camera would expose
their flatness. Ground, sidewalks, collision, moving character, and cast shadows
are native engine elements. Full production would need authored meshes or more
view angles, consistent pixel cleanup, and an artist-reviewed directional walk
cycle. The existing main game and first study remain available.
