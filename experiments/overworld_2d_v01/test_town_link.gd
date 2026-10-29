extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
const HUB := "res://experiments/anime_hub_demo_v07/"
const SLOT := "/tmp/kingdom-overworld-town-link-test.json"
var title: Node
var game: Node2D
var checks := 0
var failures: Array[String] = []
var captures := false

func _initialize() -> void:
 run.call_deferred()

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures.append(message)
  push_error(message)

func ticks(count: int) -> void:
 for i in count: await physics_frame

func key(code: Key) -> void:
 for pressed in [true,false]:
  var event := InputEventKey.new()
  event.physical_keycode = code
  event.pressed = pressed
  Input.parse_input_event(event)
  await process_frame

func capture(id: String) -> void:
 if not captures: return
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ROOT+"previews/travel_"+id+".png")

func enter_overworld(walk := true) -> Node2D:
 game.travel_cooldown = 0
 if walk:
  game.player.route = game.find_path(game.player.position,game.exits.southwest.at)
  check(not game.player.route.is_empty(),"Navigation finds Garden Square's southwest exit")
 else:
  game.player.position = game.exits.southwest.at
  game.player.reset_physics_interpolation()
 for tick in 1200:
  await physics_frame
  if is_instance_valid(game.overworld_travel) and is_instance_valid(game.overworld_travel.overworld) and not game.overworld_travel.overworld.transitioning:
   return game.overworld_travel.overworld
 check(false,"Town's southwest exit opens the overworld")
 return null

func wait_for_town() -> void:
 for tick in 300:
  await physics_frame
  if not is_instance_valid(game.overworld_travel.overworld) and not game.transitioning: return
 check(false,"Overworld return finishes the town transition")

func run() -> void:
 captures = "--travel-capture" in OS.get_cmdline_user_args()
 title = load(HUB+"title.tscn").instantiate()
 title.save_path = SLOT
 root.add_child(title)
 current_scene = title
 title.finish_menu()
 game = title.game
 game.auto_clock = false
 game.clock = 2.1
 game.player.health = 3
 game.coins += 7
 game.state.add_item("bread",2)
 game.state.accept_quest()
 # Test-only save slot; never inspect or modify the player's real save.
 for suffix in ["",".auto",".bak",".auto.bak",".tmp",".auto.tmp"]:
  if FileAccess.file_exists(SLOT+suffix): DirAccess.remove_absolute(SLOT+suffix)
 await ticks(3)
 var hero_id: int = game.player.get_instance_id()
 var state_id: int = game.state.get_instance_id()
 var before: Dictionary = game.state.snapshot().duplicate(true)
 var checkpoint: Vector2 = game.Map.arrival("town","overworld")
 check(game.is_walkable(game.exits.southwest.at,14),"Southwest departure trigger has a safe footprint")
 check(game.is_walkable(checkpoint,14),"Town-side return checkpoint has a safe footprint")
 var old_mode: int = root.content_scale_mode
 var old_aspect: int = root.content_scale_aspect
 game.player.position = Vector2(650,980)
 game.player.reset_physics_interpolation()
 game.camera.force_update_scroll()
 game.dialogue_left = 0
 game.talk_panel.hide()
 game._update_hud()
 await capture("southwest_exit")
 var world := await enter_overworld()
 if world==null:
  finish()
  return
 var first_overworld_id: int = world.get_instance_id()
 check(world.linked_journey and world.player.distance_to(world.City.GATE)>6,"Departure arrives outside Mosswood's gate without an immediate return")
 check(not game.visible and not game.ui.visible and not game.can_process(),"Town rendering, HUD and input processing are suspended")
 check(not game.camera.enabled and root.canvas_transform.is_equal_approx(Transform2D.IDENTITY),"Overworld rendering is independent of the town follow camera")
 check(game.state.snapshot()==before and game.player.health==3,"Inventory, equipment, coins, quests, clock and health survive departure")
 check(game.audio.active_zone=="trail","Overworld uses woodland music and ambience without the town fountain")
 await capture("overworld_arrival")
 var document: Dictionary = game.saves.load_document(SLOT+".auto")
 check(not document.is_empty() and document.state==JSON.parse_string(JSON.stringify(before)),"Leaving town autosaves the existing journey facts")
 check(document.player.zone=="town" and Vector2(document.player.position[0],document.player.position[1])==checkpoint,"Autosave restores a safe southwest town checkpoint with the existing save format")
 await key(KEY_F5)
 check(not game.saves.load_document(SLOT).is_empty(),"F5 from the overworld writes a valid manual checkpoint")
 await key(KEY_M)
 await ticks(2)
 check(world.region_map and game.audio.paused,"Regional map pauses overworld audio")
 await key(KEY_ESCAPE)
 await ticks(2)
 check(not world.region_map and not game.audio.paused,"Closing regional map resumes overworld audio")
 # Walk to the south gate: no teleport is used for this return route.
 world.automated = true
 world.intent = Vector2(0,1)
 for tick in 600:
  await physics_frame
  if not is_instance_valid(game.overworld_travel.overworld): break
 world = null
 await wait_for_town()
 check(game.player.get_instance_id()==hero_id and game.state.get_instance_id()==state_id,"Returning reuses the same hero and journey objects")
 check(game.state.snapshot()==before and game.player.health==3,"Round trip preserves all journey facts and health")
 check(game.player.position.distance_to(checkpoint)<1 and game.is_walkable(game.player.position,14),"Return places the cat safely inside Garden Square's southwest exit")
 check(game.visible and game.ui.visible and game.can_process() and game.camera.enabled,"Town HUD, follow camera and controls resume")
 check(root.content_scale_mode==old_mode and root.content_scale_aspect==old_aspect,"Town viewport scaling is restored")
 check(game.audio.active_zone=="town" and not game.audio.paused,"Returning restores town audio")
 await ticks(95)
 check(not game.transitioning and not is_instance_valid(game.overworld_travel.overworld),"Return checkpoint and cooldown prevent travel ping-pong")
 await capture("garden_square_return")
 # Also test E at the town exit and F at the overworld gate.
 game.player.position = game.exits.southwest.at+Vector2(50,-15)
 game.player.reset_physics_interpolation()
 game.player.stop_motion()
 game.travel_cooldown = 0
 await ticks(3)
 check(game.near_exit=="southwest","Approaching the road displays the correct exit interaction")
 await key(KEY_E)
 for tick in 300:
  await physics_frame
  if is_instance_valid(game.overworld_travel.overworld) and not game.overworld_travel.overworld.transitioning: break
 world = game.overworld_travel.overworld
 check(is_instance_valid(world) and world.get_instance_id()!=first_overworld_id,"E opens a fresh overworld trip through the southwest road")
 if is_instance_valid(world):
  world.automated = true
  world.player = world.City.GATE-Vector2(0,4)
  world.gate_cooldown = 0
  world.update_camera()
  await ticks(2)
  check(world.can_enter_town(),"Gate offers entry while nearby, outside the automatic trigger")
  await capture("city_gate_prompt")
  await key(KEY_F)
  await wait_for_town()
  check(not is_instance_valid(game.overworld_travel.overworld) and not game.transitioning,"F enters Garden Square from the city gate")
 check(game.state.snapshot()==before,"Repeated trips do not duplicate quest or inventory state")
 # Existing southeast forest travel remains available after an overworld trip.
 game.request_travel("southeast")
 for tick in 300:
  await physics_frame
  if game.zone=="trail" and not game.transitioning: break
 check(game.zone=="trail" and not game.transitioning,"Existing southeast woodland connection still works")
 finish()

func finish() -> void:
 FileAccess.open(ROOT+"town_link_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Title-launched journey, physical southwest exit navigation, mounted departure, physical automatic return, real E/F/F5/M/Esc input, retained inventory/equipment/quest/clock/health, safe autosave/manual checkpoint in isolated /tmp slot, camera/HUD/audio restoration, repeat-trip protection and existing southeast forest travel."},"  ")+"\n")
 print("TOWN / OVERWORLD LINK CHECKS ",checks-failures.size(),"/",checks)
 if is_instance_valid(title): title.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
