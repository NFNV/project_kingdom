# Town Skirmish — architecture and gameplay study 03

Keep the warm old-town palette, detailed gardens, blue slate roofs, and angled
orthographic camera. Restore the cat-player/dog-enemy melee and capture demo.

Buildings are real 3D geometry this time. Walls, roof ridges, eaves, windows,
doors, steps, and awnings share the world's X/Z grid. Their perspective comes
from the same camera as the road. Never rotate a pre-perspectived building
illustration to pretend it is geometry. Terrain and building axes are verified
in the scene tests and inspected together in the actual renderer.

Generate only two original, flat material textures: warm plaster and blue slate.
Use the prior cottage as palette/material reference, not as an angled building
card. Textures contain no baked perspective or cast shadows. Native geometry
supplies the shape and light. Reuse the existing original cat/dog animation
resources and garden scenery; no Tiny Swords environment assets are used.

Cat warriors remain the playable red faction and blue dog warriors remain the
enemy faction. Their earlier sword-and-shield designs are reused for this
gameplay prototype; this is not a new production character art pass.

Target native 1920×1080 at 60 FPS, with no dynamic resolution or 3D upscaling.
Use batched small meshes, mipmapped scenery, filtered terrain grain, FXAA, and a
visible FPS counter. Add shutters, masonry, porch supports, cornices, ridge caps,
gutters, reflected window glass, and curtains as native geometry/materials.
Prefer local cavity shading and soft character contact shadows over costly
full-screen effects. Use physics interpolation for fighters and their following
camera. Benchmark combat, camera turns, and maximized output, not only a static
view. Preserve the street/building axes and the existing cat/dog gameplay.
