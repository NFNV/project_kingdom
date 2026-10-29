extends SceneTree
const HUB := "res://experiments/anime_hub_demo_v07/"
const SLOT := "/tmp/kingdom-windsong-mill-test.json"
var title: Node
var game: Node2D
var checks := 0
var failures: Array[String] = []
var captures := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
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
func wait_zone(zone: String) -> void:
 for i in 400:
  await physics_frame
  if game.zone==zone and game.visible and not game.transitioning: return
 check(false,"Transition reaches "+zone)
func walk_to(at: Vector2, label: String) -> void:
 game.player.route = game.find_path(game.player.position,at)
 check(not game.player.route.is_empty(),"Connected navigation route: "+label)
 for i in 1200:
  await physics_frame
  if game.player.position.distance_to(at)<32 or game.transitioning: break
 check(game.player.position.distance_to(at)<40 or game.transitioning,"Physical cat movement reaches "+label)
 if game.player.position.distance_to(at)>=40 and not game.transitioning:
  print("WALK DEBUG ",label," position=",game.player.position," target=",at," route=",game.player.route," nearest=",game.near_exit)
 game.player.stop_motion()
func capture(id: String) -> void:
 if not captures: return
 game.camera.force_update_scroll()
 for i in 3: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(HUB+"previews/mill_"+id+".png")
func wait_overworld() -> Node2D:
 for i in 400:
  await physics_frame
  if is_instance_valid(game.overworld_travel) and is_instance_valid(game.overworld_travel.overworld) and game.overworld_travel.overworld.visible and not game.overworld_travel.overworld.transitioning:
   return game.overworld_travel.overworld
 check(false,"Transition reaches the linked overworld")
 return null
func run() -> void:
 captures = "--mill-capture" in OS.get_cmdline_user_args()
 title = load(HUB+"title.tscn").instantiate()
 title.save_path = SLOT
 root.add_child(title)
 current_scene = title
 title.finish_menu()
 game = title.game
 game.autosave_enabled = false
 game.auto_clock = false
 game.clock = 1.0
 game.player.health = 3
 game.coins += 9
 await ticks(3)
 for suffix in ["",".auto",".bak",".auto.bak"]:
  if FileAccess.file_exists(SLOT+suffix): DirAccess.remove_absolute(SLOT+suffix)
 var hero_id: int = game.player.get_instance_id()
 var state_id: int = game.state.get_instance_id()
 var original: Dictionary = game.state.snapshot().duplicate(true)
 game.request_travel("southwest")
 var world := await wait_overworld()
 if world==null: finish(); return
 var world_id: int = world.get_instance_id()
 world.visit(4)
 world.gate_cooldown = 0
 check(world.can_enter_mill(),"Windsong landmark offers F to enter the mill garden")
 await key(KEY_F)
 await wait_zone("mill_garden")
 check(game.overworld_travel.regional_visit and not world.visible and not world.can_process(),"Overworld is retained but suspended while visiting the mill")
 check(game.player.get_instance_id()==hero_id and game.state.get_instance_id()==state_id and game.state.snapshot()==original,"Mill visit reuses the same hero, inventory, quests, coins, clock and health")
 check(game.peaceful_mode and game.dogs.is_empty() and game.residents.size()==2,"Garden is peaceful and has two animated cat residents")
 check(game.world_size==Vector2i(1920,1280) and game.camera.enabled and game.ui.visible,"Compact garden enables its map, follow camera and RPG HUD")
 check(game.is_walkable(game.Mill.GARDEN_ENTRY,14) and game.is_walkable(game.Mill.MILL_DOOR,14),"Garden entry and mill doorstep have safe player footprints")
 game.dialogue_left = 0
 game.talk_panel.hide()
 await capture("garden_entry")
 await walk_to(game.Mill.garden(1130,290),"Mira by the garden gate")
 await ticks(3)
 check(game.nearest=="mill_gardener","Gardener is reachable through the real proximity/line-of-sight interaction")
 await key(KEY_E)
 check(game.talk_text.text.contains("chamomile") and game.interactables.mill_gardener.anchor.sprite.gesture_count>0,"Gardener offers a story and animated greeting")
 await walk_to(game.Mill.garden(1230,95),"the backyard through its open gate")
 check(not game.is_walkable(game.Mill.garden(1370,195),14),"The planted herb bed blocks walking through the vegetables")
 game.dialogue_left = 0
 game.talk_panel.hide()
 await capture("backyard")
 await walk_to(game.Mill.MILL_DOOR+Vector2(0,28),"the mill front door")
 game.travel_cooldown = 0
 await ticks(3)
 check(game.near_exit=="mill_room","Mill doorstep offers the interior doorway")
 await key(KEY_E)
 await wait_zone("mill_room")
 check(game.residents.size()==2 and game.peaceful_mode and game.dogs.is_empty(),"Hearthroom has two friendly cats and no combat")
 check(game.audio.active_zone=="mill_room" and game.audio.surface_at(game.player.position)=="wood","Interior has hearth ambience and wood footsteps")
 check(game.world_size==Vector2i(1280,720) and game.camera.zoom==Vector2(1.5,1.5) and game.is_walkable(game.player.position,14),"Cat-scaled interior is framed as a complete room with a safe entry")
 var room_material: ShaderMaterial = game.bakery_room.room_material
 check(room_material.get_shader_parameter("night_painting")!=null and game.Mill.night_weight(1)==0 and game.Mill.night_weight(3)==1,"Interior has a real night painting and distinct noon/midnight lighting")
 var day_tint: Color = game.actor_tint
 game.clock = 3
 game._update_lighting()
 check(room_material.get_shader_parameter("night_weight")==1 and game.actor_tint.get_luminance()<day_tint.get_luminance(),"Midnight replaces painted sunlight and grades the cats to match the room")
 var counters: Array = game.pieces.filter(func(piece: CanvasItem): return piece.get_meta("mill_room_painting",false))
 check(counters.size()==1 and counters[0].material==game.backgrounds[0].material and counters[0].modulate==Color.WHITE,"Foreground counter uses the exact same day/night blend as the background")
 check(game.Mill.night_weight(3.85556)==1 and absf(game.Mill.night_weight(0)-game.Mill.night_weight(4))<.00001,"Pre-dawn stays lamplit and the lighting cycle wraps continuously")
 game.clock = 1
 game._update_lighting()
 await key(KEY_T)
 await ticks(150)
 check(absf(game.clock-2)<.001 and room_material.get_shader_parameter("night_weight")>.5,"Real T input transitions the room gradually into dusk lighting")
 game.clock = 1
 game.clock_target = -1
 game._update_lighting()
 game.dialogue_left = 0
 game.talk_panel.hide()
 await capture("hearthroom")
 await walk_to(game.Mill.room(665,440),"the miller's counter")
 await ticks(3)
 check(game.nearest=="mill_keeper","Miller is reachable across the counter through the real interaction")
 await key(KEY_E)
 check(game.talk_text.text.contains("kettle") and game.interactables.mill_keeper.anchor.sprite.gesture_count>0,"Miller behind the counter greets the player")
 await walk_to(game.Mill.room(1290,600),"the stair landing")
 await ticks(3)
 await key(KEY_E)
 check(game.talk_text.text.contains("closed for repairs") and not game.exits.has("mill_loft"),"Stairs explain the closed loft; no unfinished second-floor transition exists")
 check(not game.is_walkable(game.Mill.room(1390,500),14),"Roped-off stairs block walking upstairs")
 check(game.save_game(),"Furnished mill room saves through the existing journey schema")
 var document: Dictionary = game.saves.load_document(SLOT)
 check(not document.is_empty() and document.player.zone=="mill_room","Mill save validates as a real location")
 check(game.load_game() and game.zone=="mill_room" and game.state.snapshot()==original,"Loading the mill restores the same journey state")
 check(game.make_save_document().player.mill_room_layout==2,"New interior saves record the cat-scaled layout")
 var old_room: Dictionary = game.make_save_document().duplicate(true)
 old_room.player.erase("mill_room_layout")
 old_room.player.position = [1000.0*1920/1672,650.0*1080/941]
 check(game.saves.write_document(old_room,SLOT) and game.load_game(),"Original larger-interior saves still validate and load")
 check(game.player.position.distance_to(game.Mill.room(1000,650))<1 and game.state.snapshot()==original,"Old interior coordinates rescale while preserving all journey facts")
 await walk_to(game.exits.mill_garden.at,"the garden door from inside")
 await wait_zone("mill_garden")
 if game.zone!="mill_garden": finish(); return
 check(game.is_walkable(game.player.position,14),"Exiting the mill places the hero safely outside the front steps")
 await walk_to(game.exits.overworld.at,"the southern garden gate")
 world = await wait_overworld()
 if world==null: finish(); return
 check(world.get_instance_id()==world_id and world.player.distance_to(world.Map.WINDMILL)<22,"Garden gate restores the retained overworld beside the mill")
 check(world.day_phase==game.clock and game.state.snapshot()==original,"Returning preserves the shared clock and all journey facts")
 check(game.overworld_travel.save_checkpoint(),"Overworld saves a safe mill-garden checkpoint after visiting")
 document = game.saves.load_document(SLOT)
 check(document.player.zone=="mill_garden" and Vector2(document.player.position[0],document.player.position[1])==game.Mill.GARDEN_ENTRY,"Post-mill checkpoint restores the garden rather than mismatched town coordinates")
 world.player = world.City.GATE-Vector2(0,4)
 world.gate_cooldown = 0
 world.update_camera()
 await key(KEY_F)
 await wait_zone("town")
 check(game.player.get_instance_id()==hero_id and game.state.get_instance_id()==state_id and game.state.snapshot()==original,"Mill → overworld → Garden Square retains the original journey")
 check(game.camera.enabled and game.camera.zoom==Vector2(1.5,1.5) and game.audio.active_zone=="town","Town camera framing and sound return correctly after the mill")
 # A loaded mill save can leave through the overworld even without a retained world.
 check(game.load_game() and game.zone=="mill_garden","Continue can load the mill-garden checkpoint")
 check(game.make_save_document().player.mill_garden_layout==2,"New saves record the compact garden layout")
 var legacy: Dictionary = game.make_save_document().duplicate(true)
 legacy.player.erase("mill_garden_layout")
 legacy.player.position = [1230.0*2400/1536,95.0*1600/1024]
 check(game.saves.write_document(legacy,SLOT) and game.load_game(),"Original larger-garden saves remain valid and load")
 check(game.player.position.distance_to(game.Mill.garden(1230,95))<1 and game.state.snapshot()==original,"Old garden coordinates rescale without changing journey facts")
 game.travel_cooldown = 0
 game.request_travel("overworld")
 world = await wait_overworld()
 check(world!=null and world.player.distance_to(world.Map.WINDMILL)<22,"A newly created overworld from a mill save arrives beside Windsong, not town")
 # The standalone overworld art demo can also visit the mill, in its own slot.
 title.queue_free()
 await ticks(3)
 title = null
 var standalone := load("res://experiments/overworld_2d_v01/world.tscn").instantiate() as Node2D
 root.add_child(standalone)
 standalone.auto_clock = false
 standalone.visit(4)
 standalone.gate_cooldown = 0
 check(standalone.can_enter_mill(),"Standalone map also offers entry at Windsong")
 standalone.request_mill_entry()
 for i in 100:
  await physics_frame
  if is_instance_valid(current_scene) and current_scene is Node2D and current_scene.get("zone")=="mill_garden": break
 var preview := current_scene as Node2D
 check(is_instance_valid(preview) and preview.get("zone")=="mill_garden" and preview.save_path=="user://kingdom_mill_preview.json","Standalone mill uses a separate journey slot, preserving the main save")
 if is_instance_valid(preview): preview.queue_free()
 finish()
func finish() -> void:
 FileAccess.open(HUB+"mill_hub_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Title-launched live journey, real F/E entry, garden/backyard and interior physical navigation, cat greetings, counter, closed stairs, save/load in isolated /tmp slot, retained overworld and hero identity, mill checkpoint, town return and fresh overworld departure after loading a mill save."},"  ")+"\n")
 print("WINDSONG MILL CHECKS ",checks-failures.size(),"/",checks)
 if is_instance_valid(title): title.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
