extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var hero: CharacterBody2D
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  push_error(message)
func ticks(count: int) -> void:
 for i in count: await physics_frame
func capture(id: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ROOT+"previews/combat_stance_"+id+".png")
func sync_gear() -> void:
 hero.weapon.sync_pose()
 hero.shield.sync_pose()
func run() -> void:
 game = load(ROOT+"demo.tscn").instantiate()
 game.save_path = "/tmp/kingdom-combat-stance-test.json"
 root.add_child(game)
 game.auto_clock = false
 game.autosave_enabled = false
 game.dialogue_left = 0
 game.talk_panel.hide()
 game.ui.notice_left = 0
 game._load_zone("wilds","river")
 hero = game.player
 hero.automated = true
 hero.position = game.Map.Wilds.CAMPS[0]+Vector2(-230,0)
 hero.facing = Vector2.RIGHT
 hero.grace = 0
 hero.reset_physics_interpolation()
 for dog in game.dogs:
  dog.set_physics_process(false)
  dog.position = game.Map.Wilds.CAMPS[2]
 game.camera.force_update_scroll()
 await ticks(3)
 check(not hero.is_in_combat() and not hero.weapon.visible and not hero.shield.visible,"Entering the forest near living enemies does not automatically draw equipment")
 await capture("exploring")
 hero.set_guard(true)
 await ticks(20)
 check(hero.combat_left==0 and not hero.weapon.visible and not hero.shield.visible,"Holding guard alone does not enter combat or reveal equipment")
 hero.set_guard(false)
 hero.try_roll()
 await ticks(45)
 check(hero.combat_left==0 and not hero.weapon.visible and not hero.shield.visible,"A peaceful roll does not enter combat")
 check(hero.try_attack() and is_equal_approx(hero.combat_left,10),"A real sword attack starts exactly ten seconds of combat even when it misses")
 await ticks(4)
 check(hero.combat_art.visible and not hero.weapon.visible,"The drawn attack supplies its own blade without a duplicate carried sword")
 await ticks(36)
 check(hero.swing==0 and hero.weapon.visible and hero.shield.visible,"Both sword and shield remain visible after the attack animation finishes")
 await capture("armed")
 hero.set_guard(true)
 # Reach the last fraction of the actual ten-second window without another attack.
 while hero.combat_left>.12: await physics_frame
 check(hero.combat_left>0 and hero.weapon.visible and hero.shield.visible,"Equipment remains drawn until the end of the ten-second window")
 await ticks(10)
 check(hero.combat_left==0 and not hero.weapon.visible and not hero.shield.visible,"Both items hide automatically after ten seconds even if guard stays held")
 hero.set_guard(false)
 await capture("sheathed")
 check(hero.try_skill() and is_equal_approx(hero.combat_left,10),"Wind Slash also starts the combat timer")
 await ticks(300)
 check(hero.combat_left>4.8 and hero.combat_left<5.2,"Five seconds without combat activity count down normally")
 check(hero.try_attack() and is_equal_approx(hero.combat_left,10),"Another outgoing attack refreshes the full ten seconds")
 await ticks(90)
 check(hero.receive_hit(Vector2.LEFT,1) and is_equal_approx(hero.combat_left,10),"Taking an actual hit refreshes the full combat timer")
 hero.grace = 0
 hero.parry_rearm = 0
 hero.set_guard(true)
 hero.guard_age = .3
 hero.combat_left = 1
 check(not hero.receive_hit(Vector2.LEFT,1) and hero.combat_left==10 and hero.guarding,"A blocked incoming strike refreshes combat without health damage")
 hero.set_guard(false)
 hero.parry_rearm = 0
 hero.set_guard(true)
 hero.combat_left = 1
 check(not hero.receive_hit(Vector2.LEFT,1) and hero.combat_left==10 and hero.defence_result=="PARRY","A parried incoming strike also refreshes combat")
 hero.set_guard(false)
 hero.roll_cooldown = 0
 hero.stamina = 100
 hero.try_roll()
 await ticks(7)
 hero.combat_left = 1
 check(not hero.receive_hit(Vector2.LEFT,1) and hero.combat_left==10,"An incoming strike dodged through the roll's invulnerability refreshes combat")
 await ticks(40)
 var raider = game.dogs[0]
 hero.combat_left = 0
 sync_gear()
 raider.position = hero.position+Vector2(80,0)
 raider.facing = Vector2.LEFT
 raider.cooldown = 0
 raider.attack_kind = "slash"
 check(raider.try_attack() and hero.combat_left==10 and hero.weapon.visible and hero.shield.visible,"An enemy committing an attack draws equipment before the hit lands")
 raider.swing = 0
 var remaining: float = hero.combat_left
 game.set_paused(true)
 await ticks(120)
 check(hero.combat_left==remaining,"Pause freezes the combat timer with the rest of the game")
 game.set_paused(false)
 hero.combat_left = 1
 check(game.state.unequip_item("weapon") and game.state.unequip_item("shield"),"Both equipment pieces can be removed from their real slots")
 sync_gear()
 check(not hero.weapon.visible and not hero.shield.visible,"Combat does not display unequipped items")
 game.state.equip_item("travel_sword")
 game.state.equip_item("trail_shield")
 sync_gear()
 check(hero.weapon.visible and hero.shield.visible,"Re-equipped items follow the existing timer")
 hero.guarding = false
 hero.guard_break = 0
 hero.roll_left = 0
 hero.swing = 0
 check(game.save_game() and game.load_game() and hero.combat_left==0,"Loading restores the journey with a fresh noncombat stance")
 hero.enter_combat()
 game._load_zone("town","forest")
 check(hero.combat_left==0 and not hero.weapon.visible and not hero.shield.visible,"Safe-zone travel clears combat and hides both items immediately")
 check(not hero.try_attack() and hero.combat_left==0,"Rejected attacks in town cannot start a combat timer")
 var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Actual ten-second expiry, outgoing melee/skill refresh, incoming attack commitment and damage/block/parry/dodge refresh, guard/roll isolation, no duplicate attack blade, pause, equipment ownership, travel and load."}
 FileAccess.open(ROOT+"combat_stance_results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
 print("COMBAT STANCE CHECKS ",checks-failures.size(),"/",checks)
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
