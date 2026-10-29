extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
const SLOT := "/tmp/kingdom-inn-test.json"
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
func walk(at: Vector2, name: String) -> void:
 game.player.route = game.find_path(game.player.position,at)
 check(not game.player.route.is_empty(),"Connected route: "+name)
 for i in 1000:
  await physics_frame
  if game.player.position.distance_to(at)<15: break
 game.player.stop_motion()
 check(game.player.position.distance_to(at)<25,"Physical cat reaches "+name)
 if game.player.position.distance_to(at)>=25: print("INN WALK DEBUG ",name," at=",game.player.position," target=",at)
 await ticks(3)
func wait_zone(zone: String) -> void:
 for i in 300:
  await physics_frame
  if game.zone==zone and not game.transitioning: return
 check(false,"Travel reaches "+zone)
func capture(name: String, phase: float) -> Image:
 game.clock = phase
 game._update_lighting()
 game._update_hud()
 game.camera.force_update_scroll()
 for i in 3: await process_frame
 if not captures: return null
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 picture.save_png(ROOT+"previews/inn_"+name+".png")
 return picture
func facts() -> Dictionary:
 var result: Dictionary = game.state.snapshot().duplicate(true)
 result.erase("clock")
 return result
func run() -> void:
 captures = DisplayServer.get_name()!="headless"
 game = load(ROOT+"demo.tscn").instantiate()
 game.save_path = SLOT
 root.add_child(game)
 if captures: root.size = Vector2i(1920,1080)
 game.autosave_enabled = false
 game.auto_clock = false
 for suffix in ["",".auto",".bak",".auto.bak"]:
  if FileAccess.file_exists(SLOT+suffix): DirAccess.remove_absolute(SLOT+suffix)
 game._load_zone("mill_room","mill_garden")
 game.player.position = game.Mill.room(1000,650)
 game.player.reset_physics_interpolation()
 game.dialogue_left = 0
 game.talk_panel.hide()
 game.ui.notice_left = 0
 await ticks(5)
 var hero: int = game.player.get_instance_id()
 var state_id: int = game.state.get_instance_id()
 var original := facts()
 await walk(game.exits.mill_loft.at,"the downstairs staircase")
 check(game.near_exit=="mill_loft","E offers the guest floor at the real stair landing")
 await key(KEY_E)
 await wait_zone("mill_loft")
 if game.zone!="mill_loft": finish(); return
 check(game.player.get_instance_id()==hero and game.state.get_instance_id()==state_id and facts()==original,"Stairs retain the original hero, inventory, coins and quests")
 check(game.peaceful_mode and game.world_size==Vector2i(1280,720) and game.camera.zoom==Vector2(1.5,1.5),"Guest floor retains the corrected compact cat scale")
 check(game.is_walkable(game.player.position,14),"Upstairs landing has a safe arrival footprint")
 check(game.audio.active_zone=="mill_loft" and game.audio.surface_at(game.player.position)=="wood","Guest floor uses indoor ambience and wooden footsteps")
 check(not game.ui.skill_panel.visible and game.ui.objective.text.contains("7 AM"),"Inn HUD explains sleep and hides combat controls")
 check(not game.is_walkable(game.Map.Inn.point(450,300),14) and not game.is_walkable(game.Map.Inn.point(600,475),14),"Bed frames and partition walls block walking")
 var day := await capture("day",1)
 check(game.bakery_room.room_material.get_shader_parameter("night_weight")==0,"Upstairs has daytime art")
 var night := await capture("night",3)
 check(game.bakery_room.room_material.get_shader_parameter("night_weight")==1,"Upstairs replaces daytime art with night windows and lamplight")
 if captures:
  var window := Vector2i(Vector2(780,100)*Vector2(1920,1080)/Vector2(1672,941))
  var floor_point := Vector2i(Vector2(450,550)*Vector2(1920,1080)/Vector2(1672,941))
  check(night.get_pixelv(window).get_luminance()<day.get_pixelv(window).get_luminance()*.5,"Rendered night window is visibly darker than daytime")
  check(night.get_pixelv(floor_point).get_luminance()<day.get_pixelv(floor_point).get_luminance()*.6,"Rendered nighttime removes daylight stripes from hallway")
 game.bakery_room.open_bed("inn_sage")
 check(not game.shopping and not game.ui.inn_dialog.visible,"Beds cannot be used remotely across the inn")
 for id in ["inn_sage","inn_blue","inn_rose"]:
  var target: Vector2 = game.interactables[id].at
  await walk(target,id+" bedside through its doorway")
  check(game.nearest==id,"Bed prompt is reachable in "+id)
  var before_clock: float = game.clock
  await key(KEY_E)
  check(game.shopping and game.ui.inn_dialog.visible and game.inn_bed==id,"E opens the selected room's rest confirmation")
  var at: Vector2 = game.player.position
  await key(KEY_T)
  var moving := InputEventKey.new()
  moving.physical_keycode = KEY_W
  moving.pressed = true
  Input.parse_input_event(moving)
  await ticks(15)
  moving = InputEventKey.new()
  moving.physical_keycode = KEY_W
  moving.pressed = false
  Input.parse_input_event(moving)
  await ticks(3)
  check(game.clock==before_clock and game.player.position==at,"Rest dialog blocks time-skip hotkey and movement")
  if id=="inn_blue":
   await key(KEY_TAB)
   await key(KEY_ENTER)
  else:
   await key(KEY_ESCAPE)
  check(not game.shopping and not game.ui.inn_dialog.visible and game.clock==before_clock and facts()==original,"Cancel preserves time and the journey")
  # Return through the actual doorway before trying the next room.
  var door_x: float = {"inn_sage":450.0,"inn_blue":815.0,"inn_rose":1205.0}[id]
  await walk(game.Map.Inn.point(door_x,550),id+" corridor")
 await walk(game.interactables.inn_sage.at,"Sage Room for the night")
 game.clock = 2.5 # 9 PM
 game.clock_target = 3
 game.player.health = 1
 game.player.skill_cooldown = 4
 await key(KEY_E)
 await capture("rest_dialog",2.5)
 check(is_equal_approx(game.clock,2.5),"Rest confirmation freezes a pending time transition")
 game.autosave_enabled = true
 await key(KEY_ENTER)
 check(game.resting and game.transitioning and not game.ui.inn_dialog.visible,"Confirm begins a single fade-to-sleep transition")
 await key(KEY_ENTER)
 for i in 400:
  await physics_frame
  if not game.resting and not game.transitioning: break
 check(not game.resting and not game.transitioning and not game.shopping,"Morning releases movement and the rest dialog")
 check(absf(game.clock-1.0/6.0)<.0001 and game.clock_target==-1,"Sleep wakes at 7 AM and clears a pending T transition")
 check(game.player.health==game.player.maximum_health and game.player.skill_cooldown==0,"Sleep restores every heart and the skill cooldown")
 check(facts()==original and game.player.get_instance_id()==hero,"Sleep preserves inventory, equipment, money, quests and hero identity")
 check(game.is_walkable(game.player.position,14) and game.player.position.distance_to(game.interactables.inn_sage.at)<1,"Cat wakes safely beside its chosen bed")
 await ticks(100)
 check(FileAccess.file_exists(SLOT+".auto"),"Completed stay autosaves in the existing journey slot")
 check(game.save_game(),"Upstairs can be saved manually")
 var document: Dictionary = game.saves.load_document(SLOT)
 check(not document.is_empty() and document.player.zone=="mill_loft","Save schema accepts the guest floor and its coordinates")
 game._load_zone("town","start")
 check(game.load_game() and game.zone=="mill_loft" and facts()==original and game.player.health==game.player.maximum_health,"Continue restores the room, morning, health and original journey")
 await walk(game.Map.Inn.point(450,550),"Sage doorway after Continue")
 await walk(game.exits.mill_room.at,"the upstairs staircase")
 check(game.near_exit=="mill_room","E offers the hearthroom downstairs")
 await key(KEY_E)
 await wait_zone("mill_room")
 check(game.zone=="mill_room" and game.is_walkable(game.player.position,14) and facts()==original,"Descending returns beside the same stairs with the journey intact")
 finish()
func finish() -> void:
 FileAccess.open(ROOT+"inn_test_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"native":captures,"scope":"Physical staircase/room navigation, collisions, modal cancel/confirm, day/night rendering, resting, health, save/load and return downstairs."},"  ")+"\n")
 print("INN CHECKS ",checks-failures.size(),"/",checks)
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
