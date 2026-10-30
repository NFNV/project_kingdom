extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
const SLOT := "/tmp/kingdom-forest-patrol-test.json"
var game: Node2D
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
func freeze_enemies() -> void:
 for dog in game.dogs: dog.set_physics_process(false)
func defeat(dog: Node2D) -> void:
 dog.grace = 0
 check(dog.receive_hit(Vector2.RIGHT,99),"Actual combat hit defeats "+dog.resident_id)
func active_count() -> int:
 return game.dogs.filter(func(dog): return dog.active).size()
func rewards() -> Dictionary:
 var snapshot: Dictionary = game.state.snapshot().duplicate(true)
 snapshot.erase("forest_patrol_defeated")
 return snapshot
func travel(destination: String, entry: String) -> void:
 game.transitioning = true
 game._travel.call_deferred(destination,entry)
 for i in 300:
  await physics_frame
  if not game.transitioning and game.zone==destination: return
 check(false,"Travel reaches "+destination)
func run() -> void:
 game = load(ROOT+"demo.tscn").instantiate()
 game.save_path = SLOT
 root.add_child(game)
 game.auto_clock = false
 game.autosave_enabled = false
 game.player.automated = true
 game._load_zone("wilds","river")
 freeze_enemies()
 await ticks(3)
 check(active_count()==12 and game.combat_active,"Fresh Briarwood spawns all twelve original bandits")
 for dog in game.dogs.slice(0,3): defeat(dog)
 check(game.save_game() and game.load_game() and active_count()==9,"Saving a partly cleared original forest retains its nine survivors")
 freeze_enemies()
 for dog in game.dogs: defeat(dog)
 check(game.forest_defeated.size()==12 and game.state.forest_patrol_defeated.size()==12 and not game.combat_active,"First full clear records unique rewards and leaves the current forest peaceful")
 var original := rewards()
 check(game.save_game() and game.load_game() and active_count()==0,"Reloading a just-cleared forest does not immediately respawn mobs")
 await travel("river","wilds")
 await travel("wilds","river")
 freeze_enemies()
 check(active_count()==12 and game.combat_active and not game.peaceful_mode,"Leaving and returning to a fully cleared forest starts a new hostile patrol")
 check(game.dogs.all(func(dog): return dog.get_meta("returning_patrol",false)) and not game.dogs.any(func(dog): return dog.captain),"Returning patrols use regular raiders and maulers instead of duplicating the quest captain")
 check(rewards()==original,"New patrol preserves all original quest, inventory, loot and coin history")
 defeat(game.dogs[0])
 check(active_count()==11 and game.state.forest_patrol_defeated.size()==1 and rewards()==original,"Patrol death removes a mob without duplicating coins, badges or stolen tools")
 check(game.save_game() and game.load_game() and active_count()==11,"Current patrol casualties persist through save/load")
 freeze_enemies()
 check(game.ui.status_label.text.contains("11 bandits remain"),"HUD shows living patrol mobs rather than the permanent 12/12 quest total")
 var corrupted: Dictionary = game.make_save_document().duplicate(true)
 corrupted.state.forest_patrol_defeated = ["not_a_bandit"]
 check(not game.saves.validate(corrupted),"Unknown patrol IDs are rejected before loading")
 corrupted.state.forest_patrol_defeated = ["wild_dog_0_0","wild_dog_0_0"]
 check(not game.saves.validate(corrupted),"Duplicate patrol casualties are rejected")
 for dog in game.dogs: defeat(dog)
 check(not game.combat_active and active_count()==0 and rewards()==original,"Clearing a returning patrol resolves combat with all original rewards intact")
 check(game.save_game() and game.load_game() and active_count()==0,"A completed returning patrol stays cleared when continuing that encounter")
 await travel("river","wilds")
 await travel("wilds","river")
 freeze_enemies()
 check(active_count()==12 and rewards()==original,"A subsequent visit supplies another complete patrol")
 # Reproduce the user's old fully-cleared-save format without touching it.
 var legacy: Dictionary = game.make_save_document().duplicate(true)
 legacy.state.erase("forest_patrol_defeated")
 check(game.saves.write_document(legacy,SLOT) and game.load_game() and active_count()==12,"Legacy fully cleared saves regain twelve mobs automatically")
 freeze_enemies()
 check(rewards()==original,"Legacy migration keeps original quests, coins, equipment, items and dropped loot")
 # Also check the reported save, read-only, through an isolated copy.
 var reported: Dictionary = game.saves.load_document(game.SaveStore.DEFAULT_PATH+".auto")
 if not reported.is_empty() and reported.state.forest_defeated.size()==12 and not reported.state.has("forest_patrol_defeated"):
  check(game.saves.write_document(reported,SLOT) and game.load_game() and game.zone=="wilds" and active_count()==12,"Read-only copy of the reported cleared save now loads all twelve mobs")
  freeze_enemies()
  var expected: Dictionary = reported.state.duplicate(true)
  # JSON numbers decode as floats; inventory restoration uses integer counts.
  for item in expected.items: expected.items[item] = int(expected.items[item])
  for field in ["coins","delivery_stage","forest_recoveries"]: expected[field] = int(expected[field])
  check(rewards()==expected,"The reported save retains its exact original journey data")
 if DisplayServer.get_name()!="headless":
  root.size = Vector2i(1920,1080)
  game.player.position = game.Map.Wilds.CAMPS[0]-Vector2(230,0)
  game.player.reset_physics_interpolation()
  game.camera.force_update_scroll()
  game.dialogue_left = 0
  game.talk_panel.hide()
  game.ui.notice_left = 0
  for i in 3: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ROOT+"previews/returning_briarwood_patrol.png")
 FileAccess.open(ROOT+"forest_patrol_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Real damage, original/returning bandit spawning, partial and complete encounter persistence, repeated visits, nonduplicated rewards, schema validation and legacy cleared-save compatibility. Isolated temporary save slot."},"  ")+"\n")
 print("FOREST PATROL CHECKS ",checks-failures.size(),"/",checks)
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
