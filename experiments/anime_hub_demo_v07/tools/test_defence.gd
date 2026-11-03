extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
const SLOT := "/tmp/kingdom-defence-test.json"
var game: Node2D
var hero: CharacterBody2D
var raider: CharacterBody2D
var heavy: CharacterBody2D
var checks := 0
var failures: Array[String] = []
var center := Vector2(1550,1650)
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  push_error(message)
func ticks(count: int) -> void:
 for i in count: await physics_frame
func reset() -> void:
 hero.stop_motion()
 hero.guard_requested = false
 hero.position = center
 hero.facing = Vector2.RIGHT
 hero.health = hero.maximum_health
 hero.grace = 0
 hero.swing = 0
 hero.cooldown = 0
 hero.guard_break = 0
 hero.roll_cooldown = 0
 hero.parry_rearm = 0
 hero.riposte_left = 0
 hero.stamina = 100
 hero.stamina_delay = 0
 hero.knockback = Vector2.ZERO
 hero.reset_physics_interpolation()
 for dog in game.dogs:
  dog.set_physics_process(false)
  dog.position = center+Vector2(600,300)
  dog.grace = 0
  dog.stagger = 0
  dog.windup = 0
  dog.swing = 0
  dog.cooldown = 0
  dog.poise_hits = 0
  dog.health = dog.maximum_health
  dog.active = true
  dog.enemy = true
  dog.knockback = Vector2.ZERO
func contact(dog: CharacterBody2D, kind := "slash") -> void:
 dog.position = hero.position+Vector2(65,0)
 dog.facing = Vector2.LEFT
 dog.attack_kind = kind
 dog.cooldown = 0
 dog.stagger = 0
 dog.swing = 0
 dog.try_attack()
 dog.swing = dog.attack_duration-float(dog.profile().contact)-.01
 dog.resolve_hits()
func run() -> void:
 game = load(ROOT+"demo.tscn").instantiate()
 game.save_path = SLOT
 root.add_child(game)
 game.auto_clock = false
 game.autosave_enabled = false
 game.player.automated = true
 game._load_zone("wilds","river")
 hero = game.player
 raider = game.dogs[0]
 heavy = game.dogs[2]
 reset()
 await ticks(2)
 check(game.state.equipped_id("shield")=="trail_shield" and hero.shield.image.texture!=null and not hero.shield.visible,"A new character has a real equipped offhand shield hidden until combat")
 check(game.ui.satchel.slots.size()==8 and game.ui.satchel.slots.shield.icon!=null,"Inventory exposes a distinct eighth shield slot and illustration")
 check(raider.maximum_health==4 and heavy.maximum_health==6 and game.dogs[-1].maximum_health==12,"Raider, heavy and captain have tougher distinct health pools")
 var guard_key := InputEventKey.new()
 guard_key.physical_keycode = KEY_F
 guard_key.pressed = true
 root.push_input(guard_key,true)
 await process_frame
 check(hero.guarding,"An actual F press raises the equipped shield")
 contact(raider)
 check(hero.health==5 and hero.parries==1 and raider.stagger>1 and raider.swing==0,"A real contact inside the raise window parries and cancels the enemy's strike")
 check(hero.riposte_left>0 and hero.stamina==100,"Parrying opens a bonus-damage counter window and restores stamina")
 guard_key = InputEventKey.new()
 guard_key.physical_keycode = KEY_F
 guard_key.pressed = false
 root.push_input(guard_key,true)
 await process_frame
 check(not hero.guarding,"Releasing F lowers the shield")
 hero.try_attack()
 await ticks(18)
 check(raider.health==1 and hero.riposte_left==0,"The counter's actual sword contact deals three damage and consumes the bonus once")
 reset()
 hero.set_guard(true)
 await ticks(14)
 contact(raider)
 check(hero.health==5 and hero.stamina<80 and hero.blocks==1,"A late shield raise blocks real damage but spends stamina")
 var before: float = hero.guard_age
 hero.set_guard(false)
 hero.set_guard(true)
 check(hero.guard_age>hero.PARRY_WINDOW and before>.18,"Repeated shield taps during rearm cannot continually reopen the parry window")
 reset()
 hero.set_guard(true)
 await ticks(14)
 raider.position = hero.position-Vector2(65,0)
 raider.facing = Vector2.RIGHT
 raider.attack_kind = "slash"
 raider.try_attack()
 raider.swing = raider.attack_duration-.12
 raider.resolve_hits()
 check(hero.health==4,"A shield facing away from the attacker cannot block a rear hit")
 reset()
 hero.stamina = 10
 hero.set_guard(true)
 await ticks(14)
 contact(heavy,"sweep")
 check(hero.health==3 and hero.stamina==0 and hero.guard_break>0 and not hero.guarding,"A heavy hit exhausts a weak guard, breaks it and deals two hearts")
 check(not hero.try_roll() and not hero.try_attack() and not hero.set_guard(true),"Guard break prevents immediate roll, attack and reblocking")
 await ticks(100)
 check(hero.guard_break==0 and hero.stamina>0,"A broken guard recovers and stamina regenerates after its delay")
 hero.set_guard(true)
 check(hero.guard_age>hero.PARRY_WINDOW,"Continuing to hold guard after a break cannot automatically create a fresh parry")
 reset()
 hero.intent = Vector2.RIGHT
 var key := InputEventKey.new()
 key.physical_keycode = KEY_V
 key.pressed = true
 Input.parse_input_event(key)
 await ticks(1)
 check(hero.roll_left>0 and hero.stamina==72,"A real V press starts the roll and charges stamina once")
 key.pressed = false
 Input.parse_input_event(key)
 check(not hero.try_attack() and not hero.try_skill() and not hero.try_roll(),"A roll cannot stack attacks, skills or another roll")
 await ticks(6)
 var at: Vector2 = hero.position
 contact(raider)
 check(hero.health==5 and hero.dodges>0 and hero.roll_invulnerable(),"A real enemy contact during the middle of a roll misses")
 check(at.x-center.x>25,"Rolling moves the real physics body, not just the drawing")
 game.set_paused(true)
 var left: float = hero.roll_left
 var energy: float = hero.stamina
 await ticks(20)
 check(hero.roll_left==left and hero.stamina==energy and hero.position==at,"Pause freezes roll movement, invulnerability time and stamina")
 game.set_paused(false)
 await ticks(18)
 contact(raider)
 check(hero.health==4,"Roll recovery is vulnerable instead of granting protection through the whole animation")
 reset()
 hero.intent = Vector2.RIGHT
 hero.try_roll()
 contact(raider)
 check(hero.health==4 and hero.roll_left==0,"A mistimed roll can be hit during startup and is interrupted")
 reset()
 hero.stamina = 20
 check(not hero.try_roll(),"Insufficient stamina cannot create a free roll")
 reset()
 var polygon: PackedVector2Array = game._ellipse(center+Vector2(75,0),Vector2(16,45))
 var wall: StaticBody2D = game._solid(polygon)
 await ticks(2)
 hero.intent = Vector2.RIGHT
 hero.try_roll()
 await ticks(35)
 check(hero.position.x<center.x+50 and hero.sprite.rotation==0,"Rolling collides with solid scenery and restores the upright sprite afterward")
 wall.queue_free()
 game.blockers.erase(polygon)
 reset()
 heavy.position = center+Vector2(70,0)
 heavy.attack_kind = "sweep"
 heavy.windup = heavy.profile().warning
 check(heavy.receive_hit(Vector2.RIGHT,1) and heavy.health==5 and heavy.windup>0,"A heavy takes damage but resists a single light-hit interruption")
 heavy.grace = 0
 check(heavy.receive_hit(Vector2.RIGHT,1) and heavy.health==4 and heavy.windup==0 and heavy.stagger>0,"A second quick hit breaks heavy poise and interrupts its attack")
 reset()
 hero.set_guard(true)
 contact(heavy,"sweep")
 check(heavy.stagger>1 and heavy.windup==0 and heavy.swing==0,"A correctly timed parry bypasses heavy poise")
 reset()
 var captain = game.dogs[-1]
 captain.position = center+Vector2(100,0)
 captain.home = captain.position
 captain.alerted = true
 captain.returning = false
 captain.combo_step = 0
 captain.attacks_started = 0
 captain.set_physics_process(true)
 hero.grace = 100
 var followup_warning := false
 for i in 125:
  await physics_frame
  if captain.combo_step==1 and captain.windup>0: followup_warning = true
 check(followup_warning and captain.attacks_started==2,"The captain physically executes a two-hit combo with a fresh visible warning before the follow-up")
 reset()
 game.state.coins = 40
 check(game.state.buy_equipment("ironleaf_shield") and game.state.coins==26 and not game.state.buy_equipment("ironleaf_shield"),"The smith sells the upgraded shield once at its advertised price")
 check(game.state.equip_item("ironleaf_shield","shield") and game.state.count("trail_shield")==1,"Equipping the upgraded offhand returns the starter to the bag")
 hero.set_guard(true)
 await ticks(14)
 contact(raider)
 check(hero.health==5 and absf(hero.stamina-83.9)<.1,"Ironleaf reduces actual incoming block stamina cost by thirty percent")
 hero.set_guard(false)
 check(game.state.unequip_item("shield") and not hero.set_guard(true),"An empty shield slot disables guard and parry")
 hero.stamina = 100
 hero.roll_cooldown = 0
 check(hero.try_roll(),"Dodging remains available without a shield")
 reset()
 game.state.equip_item("trail_shield")
 var document: Dictionary = game.make_save_document()
 var store = game.SaveStore.new()
 check(store.write_document(document,SLOT) and store.load_document(SLOT).state.equipment.shield=="trail_shield","New shield equipment survives an actual version-three disk save")
 var old: Dictionary = document.duplicate(true)
 old.version = 2
 old.state.equipment.erase("shield")
 old.state.items.erase("trail_shield")
 old.state.items.erase("ironleaf_shield")
 # Previous journeys never owned a shield; emulate that exact old schema.
 var old_coins: int = old.state.coins
 FileAccess.open(SLOT+".v2",FileAccess.WRITE).store_string(JSON.stringify(old))
 var migrated: Dictionary = store.load_document(SLOT+".v2")
 check(not migrated.is_empty() and store.migrated and migrated.version==3 and migrated.state.equipment.shield=="trail_shield" and migrated.state.coins==old_coins,"An existing version-two save gains its starter shield and preserves its old economy")
 old.state.items.erase("bread")
 check(store.upgrade(old).is_empty(),"Migration rejects an old save missing existing inventory data")
 game._load_zone("town","forest")
 check(not hero.set_guard(true) and game.dogs.all(func(dog): return not dog.enemy),"Defensive combat and tougher bandits do not turn friendly town wardens hostile")
 check(hero.stamina==100 and hero.roll_left==0 and hero.guard_break==0,"Zone travel clears transient defense states safely")
 var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Actual enemy contacts, timed parry and riposte, directional guard and break, stamina economy, real V input, roll startup/middle/recovery/collision/pause, heavy poise, shield inventory/shop/save v3 and v2 migration, peaceful travel."}
 FileAccess.open(ROOT+"defence_test_results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
 print("Shield, parry & roll: ",checks-failures.size(),"/",checks)
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
