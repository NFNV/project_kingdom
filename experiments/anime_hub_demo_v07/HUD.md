# Handcrafted HUD

The shared clock uses four original gouache medallions: sunrise, daylight,
sunset and a starry crescent-moon night. Each depicts the same mill landscape
inside a carved wooden botanical frame. A single transparent atlas supplies
four runtime texture regions; the drawings dissolve near the next time phase.
The twenty-minute cycle and exact HH:MM display are unchanged. Both the main
RPG and the chibi overworld use this clock.

Wind Slash lives in a compact equipment-cross layout at the bottom left.
Its painted icon accepts **Q** or a mouse click, with an on-tile countdown,
dimming and a thin recharge meter. The existing buffered-attack behavior,
equipped-weapon requirement and equipment-dependent cooldown still apply.
The three quiet empty tiles reserve room for future abilities; they do not
advertise additional implemented skills. The dock is hidden inside shops and
the mill, and disabled with an explanation in peaceful outdoor areas.

The location card, journal, health meter, minimap, interaction prompts, travel
labels, dialogue panel, notices and bottom control hints use less screen space.
The minimap sits under the journal at the right, leaving the left side open for
the skill dock. Inventory, journal, merchant and pause screens keep their usable
modal layouts. In the overworld the miniature map, location card and footer are
also smaller; curvature implementation controls appear with diagnostics.

Assets are saved in `assets/hud/`. They were produced with **built-in imagegen**;
[generation.json](assets/hud/generation.json) records full prompts, original
paths, final workspace paths, dimensions and hashes. Original PNG bytes and
transparency are preserved; atlas cropping occurs at runtime.

Verification: `tools/preview_handcrafted_hud.gd` renders town, four combat time
phases, cooldown, mill and overworld views. It checks the actual viewport mouse
hit target, accurate clock times, icon bounds and compact bar dimensions. The
normal 1280×720 window uses the existing internal 1920×1080 viewport; native
captures show that internal viewport. The script also opens a 1920×1080 window.
It uses an isolated `/tmp` save path. Results: `handcrafted_hud_results.json`.
The existing skill, atmosphere and complete journey regression suites pass.
These are rendering and behavior checks, not a new performance benchmark.

Previews: [combat](previews/hud_wilds_day_1080.png),
[night clock](previews/hud_wilds_night_720.png),
[cooldown](previews/hud_cooldown_720.png),
[town](previews/hud_town_720.png),
[overworld](previews/hud_overworld_night_1080.png).
