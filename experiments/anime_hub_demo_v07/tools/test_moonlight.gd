extends SceneTree
## Journey integration, combat, progression, navigation and save regression checks.
const HUB_SCENE := "res://experiments/anime_hub_demo_v07/demo.tscn"
const Moonlight := preload("res://experiments/anime_hub_demo_v07/tools/moonlight_forest.gd")
var game: Node2D
var checks := 0
var failures: Array[String] = []
var capture := false

func _initialize() -> void:
 run.call_deferred()

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  push_error(message)

func ticks(count: int) -> void:
 for i in count: await physics_frame

func move_to(at: Vector2) -> void:
 game.player.position = at
 game.player.route.clear()
 game.player.stop_motion()
 game.player.reset_physics_interpolation()
 game.camera.force_update_scroll()

func photograph(name: String) -> void:
 if not capture: return
 game.dialogue_left = 0
 game.talk_panel.hide()
 game.player.grace = 0
 game.player.flash = 0
 game.camera.force_update_scroll()
 await ticks(3)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/moonlight_"+name+".png")

func walk(at: Vector2, label: String) -> void:
 game.player.route = game.find_path(game.player.position,at)
 check(not game.player.route.is_empty(),"Navigation reaches "+label)
 for i in 1600:
  await physics_frame
  if game.player.position.distance_to(at)<36: break
 check(game.player.position.distance_to(at)<45,"Physical movement reaches "+label)
 game.player.stop_motion()

func try_castle_wall(at: Vector2, direction: Vector2, rolling := false) -> void:
 move_to(at)
 game.player.automated = true
 game.player.intent = direction
 game.player.facing = direction
 if rolling: game.player.try_roll()
 await ticks(80)
 check(not Moonlight.CASTLE_BOUNDS.has_point(game.player.position),"Castle collision stops "+("rolling" if rolling else "walking")+" from "+str(at))
 game.player.intent = Vector2.ZERO
 game.player.automated = false
 game.player.stop_motion()

func try_stair_post(at: Vector2, direction: Vector2, forbidden: Rect2, rolling: bool) -> void:
 move_to(at)
 game.player.automated = true
 game.player.intent = direction
 game.player.facing = direction
 game.player.stamina = game.player.MAX_STAMINA
 game.player.roll_cooldown = 0
 if rolling: check(game.player.try_roll(),"Roll starts toward the stair support")
 var stayed_clear := true
 for i in 80:
  await physics_frame
  stayed_clear = stayed_clear and not forbidden.has_point(game.player.position)
 check(stayed_clear,"Stair support blocks "+("rolling" if rolling else "walking")+" from "+str(at))
 check(game.player.position.distance_to(at)>10,"The stair collision check physically moves the character")
 await photograph("stair_post_"+("roll_" if rolling else "walk_")+str(int(at.x)))
 game.player.intent = Vector2.ZERO
 game.player.automated = false
 game.player.stop_motion()

func enter_region() -> Node2D:
 game._load_zone("town","start")
 var exit: Vector2 = game.exits.southwest.at
 move_to(exit+Vector2(25,-20))
 game.travel_cooldown = 0
 game.request_travel("southwest")
 for i in 300:
  await physics_frame
  if is_instance_valid(game.overworld_travel) and is_instance_valid(game.overworld_travel.overworld) and not game.overworld_travel.overworld.transitioning:
   return game.overworld_travel.overworld
 return null

func run() -> void:
 capture = "--capture-moonlight" in OS.get_cmdline_user_args()
 game = load(HUB_SCENE).instantiate()
 game.save_path = "/tmp/kingdom-moonlight-test.json"
 root.add_child(game)
 await process_frame
 game.auto_clock = false
 game.autosave_enabled = false
 var overworld := await enter_region()
 check(is_instance_valid(overworld),"Town exit opens the linked overworld")
 if not is_instance_valid(overworld):
  quit(1)
  return
 var entrance: Dictionary = overworld.props.filter(func(prop): return prop.kind=="moonlight_entrance")[0]
 var approach_grows := true
 var previous_size := 0.0
 for distance in [60,50,40,30,20,10,1]:
  overworld.player = entrance.p-Vector2(0,distance)
  overworld.update_camera()
  overworld.update_visible()
  var size: float = overworld.sprite_height(entrance,overworld.view_point(entrance.p).y)
  approach_grows = approach_grows and size>=previous_size and overworld.visible_props.has(entrance)
  previous_size = size
  if capture and distance==60:
   await ticks(3)
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("/tmp/moonlight_entrance_far.png")
 check(approach_grows,"Forest entrance is visible from 60 units away and never shrinks while approaching")
 previous_size = 0.0
 for distance in [40,30,20,10,1]:
  overworld.player = entrance.p-Vector2(distance,5)
  overworld.update_camera()
  var size: float = overworld.sprite_height(entrance,overworld.view_point(entrance.p).y)
  check(size>=previous_size,"Side approach does not shrink the forest entrance at distance "+str(distance))
  previous_size = size
 overworld.player = overworld.Map.MOONLIGHT-Vector2(0,8)
 overworld.gate_cooldown = 0
 check(overworld.props.any(func(prop): return prop.kind=="moonlight_entrance"),"Entrance has a dedicated painted forest landmark")
 if capture:
  overworld.update_camera()
  overworld.update_visible()
  await ticks(3)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/moonlight_overworld_entrance.png")
 check(overworld.can_enter_moonlight(),"Marked woodland location offers the entrance")
 var event := InputEventKey.new()
 event.physical_keycode = KEY_F
 event.pressed = true
 Input.parse_input_event(event)
 await process_frame
 event = InputEventKey.new()
 event.physical_keycode = KEY_F
 event.pressed = false
 Input.parse_input_event(event)
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.FOREST and game.visible and not game.transitioning: break
 check(game.zone==Moonlight.FOREST and game.visible,"Overworld entrance reaches the on-foot forest")
 var detail: Node2D = game.zone_root.get_node("ForestDetail")
 check(detail.get_child_count()==9,"Forest renders nine native-detail panels")
 var dense_enough := true
 for panel in detail.get_children():
  dense_enough = dense_enough and game.camera.zoom.x*panel.scale.x<=1.4
 check(dense_enough,"Forest artwork is magnified less than 1.4x at the QHD follow camera")
 check(not game.peaceful_mode and game.combat_active and game.dogs.size()==4,"Forest combat is enabled with two patrol groups")
 check(game.player.try_attack(),"Normal sword input starts a forest attack")
 await ticks(35)
 check(game.player.try_skill(),"Wind Slash is available in the forest")
 await ticks(50)
 for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
 await photograph("forest_camp")
 await walk(Vector2(1600,680),"castle approach")
 await photograph("forest_castle")
 check(not game.is_walkable(Vector2(1536,400)),"Castle rear and middle are solid")
 await try_castle_wall(Vector2(1536,660),Vector2.UP)
 await try_castle_wall(Vector2(1030,450),Vector2.RIGHT)
 await try_castle_wall(Vector2(2050,450),Vector2.LEFT)
 await try_castle_wall(Vector2(1536,660),Vector2.UP,true)
 var stuck_save: Dictionary = game.make_save_document()
 stuck_save.player.position = [1536,400]
 check(game.saves.write_document(stuck_save,game.save_path),"Formerly stuck castle position can be saved with the existing format")
 check(game.load_game(),"Existing stuck save loads normally")
 check(game.player.position.is_equal_approx(Moonlight.arrival(Moonlight.FOREST,Moonlight.CISTERN)),"Loading a stuck save restores the front castle approach")
 for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
 check(not game.is_walkable(Vector2(1000,850)),"Creek separates the forest routes from the castle")
 move_to(Vector2(2500,1030))
 await walk(Vector2(2415,740),"optional stepping-stone route")
 move_to(Vector2(1870,1030))
 await photograph("forest_creek")
 move_to(game.moonlight_area.point("Camp"))
 game.state.health = 1
 game.interact("moon_camp")
 check(game.state.health==game.state.maximum_health,"Camp restores all three hearts")
 check(game.state.moonlight.checkpoint==Moonlight.FOREST,"Camp becomes the respawn checkpoint")
 var coins: int = game.coins
 var potions: int = game.state.item_counts().healing_draught
 game.interact("moon_well")
 game.interact("moon_well")
 check(game.coins==coins+15 and game.state.item_counts().healing_draught==potions+2,"Moonwell cache is awarded exactly once")
 game.interact("moon_wicket_return")
 check(not game.state.moonlight.forest_shortcut,"Camp-side shortcut starts barred")
 game.interact("moon_wicket")
 check(game.state.moonlight.forest_shortcut,"Castle-side wicket unlocks the camp shortcut")
 game.interact("moon_wicket")
 check(game.player.position.distance_to(game.moonlight_area.point("WicketReturn"))<100,"Opened wicket returns to camp")
 game.interact("moon_wicket_return")
 check(game.player.position.distance_to(game.moonlight_area.point("Wicket"))<100,"Opened wicket returns to the castle")
 # Test normal travel into the next room through the same exit handler.
 game.request_travel("castle")
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.PASSAGE and not game.transitioning: break
 check(game.zone==Moonlight.PASSAGE,"Castle entrance opens the lower passages before the Undercroft")
 check(game.player.facing==Vector2.UP,"Castle entry keeps the northward facing from the exterior stair")
 check(game.exits.castle.at.y>game.player.position.y,"The return threshold is behind the player at the top of the entrance flight")
 game.ui.status_label.text = ""
 game._update_hud()
 check(not game.ui.status_label.text.is_empty(),"Castle passage HUD refresh completes for the new room")
 detail = game.zone_root.get_node("CastlePassageDetail")
 check(detail.get_child_count()==9,"Castle passages render nine native-detail panels from first entry")
 dense_enough = true
 for panel in detail.get_children():
  dense_enough = dense_enough and game.camera.zoom.x*panel.scale.x<=1.4
 check(dense_enough,"Castle passage artwork is magnified less than 1.4x at the QHD follow camera")
 check(not game.is_walkable(Vector2(1536,900)),"Central castle vault blocks shortcuts across the corridor")
 check(not game.is_walkable(Vector2(300,800)),"Outer stair wall blocks walking outside the passage")
 # Independent points read from the painted supports in the reported views.
 for at in [Vector2(2240,1130),Vector2(990,1490),Vector2(2650,1130),Vector2(195,1530)]:
  check(not game.is_walkable(at),"Painted stair support is not walkable at "+str(at))
 var entry_position: Vector2 = game.player.position
 for rolling in [false,true]:
  await try_stair_post(Vector2(2090,1120),Vector2.RIGHT,Rect2(2180,990,110,230),rolling)
  await try_stair_post(Vector2(1100,1400),Vector2.LEFT,Rect2(910,1355,130,315),rolling)
 for at in [Vector2(2240,1130),Vector2(990,1490)]:
  var route: PackedVector2Array = game.find_path(Vector2(1536,1280),at)
  check(not route.is_empty() and Array(route).all(func(step): return game.is_walkable(step,0)),"Click-to-move snaps stair-support targets to safe floor")
  var support_save: Dictionary = game.make_save_document()
  support_save.player.position = [at.x,at.y]
  check(game.saves.write_document(support_save,game.save_path) and game.load_game(),"An old save on a stair support loads")
  check(game.is_walkable(game.player.position,0),"Loading a stair-support save recovers to walkable floor")
 move_to(entry_position)
 # Return links must meet the castle threshold, not the distant forest camp.
 await walk(game.exits.castle.at,"upper castle landing")
 game.travel_cooldown = 0
 game.request_travel("castle")
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.FOREST and not game.transitioning: break
 check(game.zone==Moonlight.FOREST and game.player.position.distance_to(Vector2(1536,710))<5,"Entrance stair returns to the castle courtyard")
 check(game.player.facing==Vector2.DOWN,"Returning up the castle stairs faces out into the courtyard")
 game.travel_cooldown = 0
 game.request_travel("castle")
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.PASSAGE and not game.transitioning: break
 var passage_save: Dictionary = game.make_save_document()
 var stair_position: Vector2 = game.player.position
 check(game.saves.validate(passage_save),"A journey can save on the new castle staircase")
 check(game.saves.write_document(passage_save,game.save_path) and game.load_game(),"Castle passage save restores through normal load handling")
 check(game.zone==Moonlight.PASSAGE and game.player.position.distance_to(stair_position)<1,"Reload retains the staircase location")
 var old_passage_save: Dictionary = passage_save.duplicate(true)
 old_passage_save.player.position = [570.0,700.0]
 check(game.saves.write_document(old_passage_save,game.save_path) and game.load_game(),"A save from the previous stair layout loads safely")
 check(game.is_walkable(game.player.position) and game.player.position.distance_to(Moonlight.arrival(Moonlight.PASSAGE,"start"))<1,"Old stair saves recover to the new top landing instead of a wall")
 await photograph("passage_descent")
 await walk(game.moonlight_area.point("DescentLanding"),"down the castle entrance staircase")
 check(game.player.position.y<stair_position.y-300,"Entrance flight continues north from the castle into the lower corridor")
 check(not game.is_walkable(Vector2(900,1400)),"The entrance parapet blocks walking through the side of the stairs")
 await photograph("passage_lower_landing")
 await walk(game.moonlight_area.point("CorridorBend"),"lower vaulted corridor")
 await photograph("passage_corridor")
 await walk(game.moonlight_area.point("AscentLanding"),"foot of the Undercroft staircase")
 await photograph("passage_ascent")
 await walk(game.exits.undercroft.at,"up the stairs to the Undercroft")
 check(game.player.position.y<700,"Undercroft exit is reached by climbing to an upper landing")
 game.travel_cooldown = 0
 game.request_travel("undercroft")
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.CISTERN and not game.transitioning: break
 check(game.zone==Moonlight.CISTERN,"Upper passage stairs enter the Undercroft")
 # Exercise the opposite end of the stair connection as well.
 game.travel_cooldown = 0
 game.request_travel("stairs")
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.PASSAGE and not game.transitioning: break
 check(game.zone==Moonlight.PASSAGE and game.player.position.distance_to(Moonlight.arrival(Moonlight.PASSAGE,Moonlight.CISTERN))<5,"Undercroft return reaches the far passage staircase")
 check(game.player.facing==Vector2.DOWN,"Returning from the Undercroft faces down its separate stair flight")
 game.travel_cooldown = 0
 game.request_travel("undercroft")
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.CISTERN and not game.transitioning: break
 for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
 detail = game.zone_root.get_node("UndercroftDetail")
 check(detail.get_child_count()==9,"Undercroft renders nine native-detail panels")
 dense_enough = true
 for panel in detail.get_children():
  dense_enough = dense_enough and game.camera.zoom.x*panel.scale.x<=1.4
 check(dense_enough,"Undercroft artwork is magnified less than 1.4x at the QHD follow camera")
 check(not detail.door_open and detail.door_panel.texture.resource_path.ends_with("chapel_closed.png"),"Chapel starts with its painted closed doors")
 check(not game.is_walkable(Vector2(1536,545)),"Closed chapel doors block the threshold")
 check(not game.is_walkable(Vector2(1500,950)),"Cistern water blocks walking")
 game.request_travel("chapel")
 check(not game.transitioning and game.zone==Moonlight.CISTERN,"Chapel passage stays locked before operating winch")
 await walk(Vector2(1536,615),"closed chapel doors")
 await photograph("chapel_door_closed")
 await walk(game.moonlight_area.point("Winch"),"eastern winch around the pool")
 await photograph("cistern")
 game.interact("moon_winch")
 check(game.state.moonlight.winch and game.moonlight_area.gates.is_empty(),"Winch opens the doors and removes their collision")
 check(detail.door_open and detail.door_panel.texture.resource_path.ends_with("0_1.png"),"Winch shows the matching painted open doors")
 check(game.is_walkable(Vector2(1536,545)),"Opened chapel doors leave a walkable threshold")
 check(not game.find_path(game.player.position,game.exits.chapel.at).is_empty(),"Raised grate has a connected navigation route")
 await walk(Vector2(1536,615),"open chapel doors")
 await photograph("chapel_door_open")
 game.interact("moon_entry")
 check(game.state.moonlight.checkpoint==Moonlight.CISTERN,"Entry Hall becomes the underground checkpoint")
 game.request_travel("chapel")
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.CHAPEL and not game.transitioning: break
 check(game.zone==Moonlight.CHAPEL,"Opened grate enters Root Chapel")
 for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
 detail = game.zone_root.get_node("ChapelDetail")
 check(detail.get_child_count()==9,"Root Chapel renders nine native-detail panels")
 dense_enough = true
 for panel in detail.get_children():
  dense_enough = dense_enough and game.camera.zoom.x*panel.scale.x<=1.4
 check(dense_enough,"Root Chapel artwork is magnified less than 1.4x at the QHD follow camera")
 check(not game.interactables.has("moon_ladder"),"Removed chapel ladder leaves no invisible interaction")
 check(game.dogs.size()==3,"Chapel guards and vault keeper spawn")
 await photograph("chapel")
 move_to(Vector2(720,1320))
 await photograph("chapel_former_ladder")
 var keeper: Node2D = game.dogs.filter(func(dog): return dog.resident_id=="vault_keeper")[0]
 game.player.grace = 0
 var health: int = game.player.health
 check(game.player.receive_hit(Vector2.RIGHT,1,0,keeper),"Incoming attack resolves without freezing")
 check(game.player.health==health-1,"Incoming hit removes half a heart")
 await ticks(2)
 check(game.player.active,"Player remains active after a nonlethal attack")
 keeper.grace = 0
 var keeper_hp: int = keeper.health
 check(keeper.receive_hit(Vector2.LEFT,2,0,game.player),"Vault keeper receives damage")
 check(keeper.health==keeper_hp-2,"Vault keeper health decreases")
 keeper.grace = 0
 keeper.receive_hit(Vector2.LEFT,keeper.health,0,game.player)
 check("vault_keeper" in game.state.moonlight.defeated,"Keeper defeat enters persistent dungeon progress")
 check(is_instance_valid(game.moonlight_area.chest),"Defeating keeper reveals the reusable treasure chest")
 check(game.moonlight_area.chest.visible,"Treasure chest is visible")
 move_to(Vector2(1536,860))
 await photograph("chapel_altar")
 coins = game.coins
 game.interact("moon_chest")
 game.interact("moon_chest")
 check(game.coins==coins+100 and game.state.moonlight.vault_claimed,"Vault treasure pays once")
 var document: Dictionary = game.make_save_document()
 check(game.saves.validate(document),"Dungeon save validates")
 var previous: Dictionary = document.duplicate(true)
 previous.state.erase("moonlight")
 previous.player.zone = "town"
 previous.player.position = [840,905]
 check(game.saves.validate(previous),"Existing saves without Moonlight data remain valid")
 var corrupt: Dictionary = document.duplicate(true)
 corrupt.state.moonlight.defeated.append("unknown")
 check(not game.saves.validate(corrupt),"Save rejects unrecognized dungeon enemies")
 var legacy: Dictionary = document.duplicate(true)
 legacy.state.moonlight.chapel_shortcut = true
 check(game.saves.validate(legacy),"Older saves with the retired ladder shortcut still validate")
 check(game.saves.write_document(document,game.save_path),"Dungeon progress writes to disk")
 check(game.load_game(),"Saved dungeon restores through the normal load entry point")
 check(game.zone==Moonlight.CHAPEL and game.state.moonlight.vault_claimed,"Restored journey retains room and collected treasure")
 check(game.dogs.all(func(dog): return dog.resident_id!="vault_keeper"),"Defeated keeper stays defeated after loading")
 for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
 check(game.moonlight_area.chest.opened,"Restored vault chest stays open")
 await walk(game.exits.cistern.at,"chapel return entrance")
 game.travel_cooldown = 0
 game.request_travel("cistern")
 for i in 300:
  await physics_frame
  if game.zone==Moonlight.CISTERN and not game.transitioning: break
 check(game.zone==Moonlight.CISTERN,"Chapel entrance returns to the Undercroft")
 check(not game.interactables.has("moon_ladder_return"),"Undercroft has no stale ladder interaction")
 check(game.moonlight_area.cistern_detail.door_open and game.moonlight_area.gates.is_empty(),"Saved winch progress restores the visible open door and unlocked passage")
 for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
 game.player.grace = 0
 game.player.receive_hit(Vector2.RIGHT,game.player.health,0)
 for i in 300:
  await physics_frame
  if game.player.active and not game.transitioning: break
 check(game.zone==Moonlight.CISTERN and game.player.active,"Lethal damage respawns at the latest checkpoint")
 check(game.player.health==game.player.maximum_health,"Checkpoint respawn restores health")
 check(game.state.moonlight.vault_claimed,"Respawning preserves collected treasure")
 game._load_zone(Moonlight.FOREST,Moonlight.CISTERN)
 game.travel_cooldown = 0
 game.request_travel("overworld")
 for i in 300:
  await physics_frame
  if overworld.visible and not overworld.transitioning: break
 check(overworld.visible and not game.visible,"Forest trail returns to the live overworld")
 check(overworld.player.distance_to(overworld.Map.MOONLIGHT)<20,"Return is at the marked woodland entrance")
 print("MOONLIGHT CHECKS ",checks," FAILURES ",failures)
 game.queue_free()
 await ticks(3)
 quit(0 if failures.is_empty() else 1)
