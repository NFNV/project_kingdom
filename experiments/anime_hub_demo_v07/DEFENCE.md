# Shield, parry and dodge roll

Space / left click and Q retain their sword and Wind Slash bindings.

- **F:** hold a directional guard. Face the incoming attacker; rear attacks get through.
- **Timed F:** the first 0.18 seconds of a shield raise can parry. It cancels the
  incoming attack, staggers even an armored mauler for 1.25 seconds, restores
  14 stamina and opens a 1.6-second counter window. The next successful melee
  contact adds two damage. Release and raise again to parry; a 0.55-second
  rearm prevents repeated tapping from maintaining continuous parry protection.
- **V or Ctrl:** roll along movement input, or facing when standing still.
  It costs 28 of 100 stamina, moves the actual collision body and lasts 0.46
  seconds. Only seconds 0.06–0.32 are invulnerable. Startup and recovery remain
  vulnerable; trees and walls stop it. A 0.66-second reuse limit prevents chaining
  uninterrupted invulnerability. Roll can cancel sword recovery after contact,
  or Wind Slash after release, but cannot cancel anticipation for a free attack.

Late guard absorbs damage at 23 stamina per incoming damage with the buckler.
Insufficient stamina breaks guard for one second and the hit deals full damage.
Stamina regenerates at 30/second after a short delay, or 7/second while guarding.
The turquoise HUD bar and status under health show stamina, guard breaks and the
counter opportunity. A shield flashes pale green during its parry window; impacts
show BLOCK, PARRY or GUARD BROKEN feedback. Rolling tumbles the registered cat
sprite around its body center with a short ground dust trail.

The **Trailwarden buckler** starts equipped in a new eighth inventory slot.
Tomas at Emberforge sells an **Ironleaf shield** for 14 coins; it cuts real block
stamina costs by 30%. Both have distinct vector icons and appear on the character
when carried or guarding. Removing a shield disables guard/parry; rolls still
work. Sword and shield are drawn only during the character's combat stance:
starting a sword attack or Wind Slash, or being attacked, starts a **10-second**
timer. Each new outgoing or incoming attack refreshes it, including blocked,
parried and dodged strikes. Merely standing near enemies, holding guard, moving
or rolling does not refresh it. After ten seconds both items hide automatically.
The drawn attack supplies its own sword, avoiding a duplicate carried blade;
equipment tucks away during rolls. Pause freezes the timer and safe travel/load
clears it. Equipment remains visible in inventory regardless of combat stance.

Carried equipment now uses paw landmarks for each of the 160 idle/walk/run
poses in all eight directions. `equipment_pose.gd` maps source-region coordinates
through the actual sprite's registration, scale, lean and bob. Hidden far paws
use inferred anchors with body occlusion; a single visible paw is never assigned
both items. The sword rests low beside the body between attacks, and its near
grip reuses the original paw pixels. The shield stays below the muzzle, follows
the visible sprite direction during turns, and shows wooden straps from behind.
Native multi-frame contact sheets and face/layer checks are produced by
`tools/preview_equipment_alignment.gd`; the original sprite PNGs are unchanged.

`tools/test_combat_stance.gd` checks the real expiry, refresh sources, carried
equipment visibility and pause/load/travel behavior. It also produces native
1440p [armed](previews/combat_stance_armed.png) and
[sheathed](previews/combat_stance_sheathed.png) captures when run graphically.

Briarwood raiders have **4 hearts**, move faster and recover sooner. Maulers have
**6 hearts**, deal **2 damage**, and resist interruption from one light hit during
an attack; two quick light hits, a three-damage wind blade or parry break poise.
Rook has **12 hearts**, deals **3 damage**, and can follow his first strike with a
second locked attack warning. Parrying cancels that combo. All damage remains
restricted to each attack's active interval; the wardens in town remain friendly.

Save format **3** persists the new slot and items. Valid version 1 and 2 journeys
migrate in memory, preserving progress and supplying the starter shield. The
original save is not rewritten merely by loading. Roll/guard/stamina are transient
combat state, reset safely on travel/load; saves are refused during a roll,
guard break, held guard or attack.

`tools/test_defence.gd` exercises actual enemy contacts, directional guard, parry
and counter damage, stamina, roll timing/collision/pause, heavy poise, captain
combos, shield shop/equipment and version-2 disk migration. Use `--headless
--fixed-fps 60 --script res://experiments/anime_hub_demo_v07/tools/test_defence.gd`.
`tools/preview_defence.gd` produces native 2560×1440 captures using an isolated
`/tmp` save path. These are behavior/rendering checks, not a performance benchmark.

[Guard](previews/defence_guard.png) · [Parry](previews/defence_parry.png) ·
[Roll](previews/defence_roll.png) · [Equipment](previews/defence_equipment.png) ·
[Emberforge](previews/defence_forge.png)
