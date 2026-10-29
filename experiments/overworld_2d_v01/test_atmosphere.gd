extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
const SLOT := "/tmp/kingdom-overworld-day-night-test.json"
var checks := 0
var failures: Array[String] = []
var world: Node2D
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
func run() -> void:
 world = load(ROOT+"world.tscn").instantiate()
 root.add_child(world)
 world.automated = true
 world.auto_clock = false
 world.set_physics_process(false)
 await process_frame
 var dressed: Array = world.dressed_props
 print("DRESSED REGION: ",dressed.size()," additions / ",world.props.size()," total scenery")
 check(dressed.size()>80,"More than eighty carefully placed painted buildings, stalls, flowers, benches and lamps populate the region")
 for kind in ["ivy_cottage","balcony_cottage","bakery","bookshop","grocer_shop","country_hall","bakery_stall","produce_stall","flowers","lamp","bench","watermill","lighthouse"]:
  check(dressed.any(func(item: Dictionary): return item.kind==kind),"Map displays painted asset: "+kind)
 check(dressed.all(func(item: Dictionary): return not world.can_stand(item.p)),"Added scenery has collision at its foot")
 check(world.textures.size()>=22,"All reused and generated scenery textures are cached")
 check(world.sky_material.get_shader_parameter("day_sky")!=null and world.sky_material.get_shader_parameter("night_sky")!=null,"Both painted sky panoramas are loaded")
 var noon: Dictionary = world.Atmosphere.sample(1)
 var dusk: Dictionary = world.Atmosphere.sample(2)
 var night: Dictionary = world.Atmosphere.sample(3)
 check(noon.night==0 and noon.lamps==0 and night.night==1 and night.lamps==1,"Stars and lamps are absent at noon and active at midnight")
 check(dusk.twilight>.99 and dusk.lamps==1,"Dusk uses warm sky glow and lit lamps")
 check(night.tint.get_luminance()> .25 and night.tint.get_luminance()<noon.tint.get_luminance(),"Night dims the world while preserving readable moonlit terrain")
 check(world.Atmosphere.sample(3.99999).tint.is_equal_approx(world.Atmosphere.sample(0).tint),"Lighting palette wraps continuously from night into dawn")
 world.day_phase = 3
 world.update_lighting()
 world.update_shader()
 check(world.night_weight==1 and world.mounted_rider.light_tint!=Color.WHITE,"Night also grades the mounted hero")
 check(world.terrain.material.get_shader_parameter("night_weight")==1,"Moonlit water and terrain use the same phase as the sky")
 check(world.clock_dial.hour==0,"Celestial clock displays midnight")
 # Fixed-camera sky composition: complete silhouettes remain visible.
 check(world.sun_texture!=null and world.moon_texture!=null,"Both painted celestial drawings are loaded")
 check(world.Atmosphere.moon_is_visible(3.85556) and world.Atmosphere.moon_is_visible(3.99999),"Moon remains the sole active drawing at 05:08 and immediately before dawn")
 check(not world.Atmosphere.moon_is_visible(0) and not world.Atmosphere.moon_is_visible(1.99999) and world.Atmosphere.moon_is_visible(2),"Dawn and dusk switch celestial drawings without overlapping crossfades")
 var contacts_fit := true
 for texture_id in world.texture_feet:
  contacts_fit = contacts_fit and Rect2(0,0,1,1).has_point(world.texture_feet[texture_id])
 check(world.ground_contacts.size()==17 and contacts_fit,"Seventeen calibrated contact points lie inside their cropped textures")
 check(world.foot_uv({"kind":"willow"}).x>.6,"Willow is rooted at its off-center trunk, not at the center of its leaves")
 check(world.foot_uv({"kind":"watermill"}).y<.9,"Watermill is anchored at its structural foundation, excluding the lower garden skirt")
 var roots_match := true
 for kind in ["willow","oak","watermill","ivy_cottage","lighthouse","lamp"]:
  var texture: Texture2D = world.textures[kind]
  var point: Vector2 = world.camera_ground+Vector2(15,45)
  var item := {"kind":kind,"p":point,"height":6.0}
  var size: float = world.sprite_height(item,45)
  var foot: Vector2 = world.foot_uv(item)*texture.get_size()
  var origin: Vector2 = world.project(point)-((foot*size/texture.get_height()).rotated(world.surface_rotation(point)))
  var drawn_contact: Vector2 = origin+((foot*size/texture.get_height()).rotated(world.surface_rotation(point)))
  roots_match = roots_match and world.inverse_ground(drawn_contact).distance_to(point)<.01
 check(roots_match,"Calibrated tree/building/lamp contact pixels project to their actual navigable ground positions")
 var rim_item := {"kind":"watermill","p":world.camera_ground+Vector2(0,world.horizon_radius()-1),"height":8.8}
 world.visible_props.clear()
 world.include_visible(rim_item,world.horizon_radius())
 check(world.visible_props.is_empty(),"Wide foundations are culled before their outer footprint crosses the curved horizon")
 var fits := true
 var clear_hud := true
 for step in 81:
  for is_moon in [false,true]:
   var center: Vector2 = world.Atmosphere.celestial_position(step*.05,0,is_moon)
   var radius: float = (world.Atmosphere.MOON_DIAMETER if is_moon else world.Atmosphere.SUN_DIAMETER)*.5
   var rect := Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2)
   fits = fits and Rect2(0,0,1920,480).encloses(rect)
   clear_hud = clear_hud and not rect.intersects(Rect2(28,28,517,103)) and not rect.intersects(Rect2(868,0,188,156)) and not rect.intersects(Rect2(1540,28,352,242))
 check(fits,"Sun and moon remain fully inside the visible sky throughout a full cycle")
 check(clear_hud,"Painted sun and moon avoid the title, clock and minimap throughout the cycle")
 check(world.Atmosphere.celestial_position(3,PI,true)==world.Atmosphere.celestial_position(3,0,true),"Moon composition is independent of legacy camera yaw")
 check(world.Atmosphere.celestial_position(1,PI,false)==world.Atmosphere.celestial_position(1,0,false),"Sun composition is independent of legacy camera yaw")
 check(world.Atmosphere.celestial_position(0,0,false).distance_to(world.Atmosphere.celestial_position(4,0,false))<.001,"Sun position wraps continuously through dawn")
 check(world.Atmosphere.celestial_position(0,0,true).distance_to(world.Atmosphere.celestial_position(4,0,true))<.001,"Moon position wraps continuously through dawn")
 world.visit(3)
 world.camera_yaw = 0
 world.update_camera()
 world.update_visible()
 check(world.visible_props.count(world.City.illustration_prop())==1,"City draws as one compact painted landmark")
 check(not world.visible_props.any(func(item: Dictionary): return item.get("city_geometry",false)),"Old geometric city never enters the drawing pass")
 check(world.can_stand(world.City.GATE-Vector2(0,4)),"Painted town's south-gate approach remains walkable")
 check(world.sprite_height(world.City.illustration_prop(),5)<=340,"Painted city stays within miniature screen scale up close")
 for item in world.dressed_props:
  if item.kind in world.Dressing.HOUSE_KINDS:
   check(world.sprite_height(item,5)<=180,"Nearby house stays within map-icon scale: "+item.kind)
   break
 world.day_phase = 1
 world.auto_clock = true
 world.advance_day(60)
 check(absf(world.day_phase-1.2)<.00001,"One real minute advances one twentieth of a complete day")
 world.advance_day(1140)
 check(absf(world.day_phase-1)<.00001 and world.CYCLE_SECONDS==1200,"Full cycle takes twenty minutes and wraps exactly")
 world.auto_clock = false
 world.day_phase = 3.75
 await key(KEY_T)
 check(world.clock_target==4,"Real T input requests the next time phase across midnight")
 world.advance_day(.2)
 check(world.day_phase>3.75 and world.day_phase<4,"Time preview transitions gradually")
 world.advance_day(2)
 check(world.clock_target==-1 and world.day_phase==0,"Time preview completes by wrapping to dawn")
 world.auto_clock = true
 var phase: float = world.day_phase
 world.paused = true
 world._physics_process(5)
 check(world.day_phase==phase,"Pause freezes the day/night clock")
 world.paused = false
 world.region_map = true
 world._physics_process(5)
 check(world.day_phase==phase,"Regional map freezes the day/night clock")
 world.queue_free()
 await process_frame
 await process_frame
 # Verify the bridge shares the actual RPG clock, including saves and return.
 var title = load("res://experiments/anime_hub_demo_v07/title.tscn").instantiate()
 title.save_path = SLOT
 root.add_child(title)
 current_scene = title
 title.finish_menu()
 var game: Node2D = title.game
 game.autosave_enabled = false
 game.auto_clock = true
 game.clock = 2.95
 game.player.health = 3
 game.state.add_item("bread",2)
 var before: Dictionary = game.state.snapshot().duplicate(true)
 before.erase("clock")
 game.request_travel("southwest")
 for i in 600:
  await physics_frame
  if is_instance_valid(game.overworld_travel) and is_instance_valid(game.overworld_travel.overworld) and not game.overworld_travel.overworld.transitioning: break
 world = game.overworld_travel.overworld
 check(is_instance_valid(world),"Southwest exit opens the dressed overworld")
 if is_instance_valid(world):
  world.set_physics_process(false)
  check(absf(world.day_phase-game.clock)<.001 and world.auto_clock==game.auto_clock,"Departure inherits Garden Square's current time and cycle setting")
  var before_time: float = game.clock
  world.advance_day(30)
  check(absf(game.clock-before_time-.1)<.00001 and game.clock==world.day_phase,"Roaming advances the same live journey clock")
  world.day_phase = 3.99
  world.advance_day(6)
  check(game.clock<.02 and game.clock>=0,"Shared journey clock wraps within the save format's valid range")
  check(game.overworld_travel.save_checkpoint(),"Updated overworld time saves through the existing checkpoint format")
  var document: Dictionary = game.saves.load_document(SLOT)
  check(not document.is_empty() and absf(document.state.clock-game.clock)<.00001,"Saved checkpoint preserves the advanced time")
  var expected_time: float = world.day_phase
  world.player = world.City.GATE-Vector2(0,4)
  world.gate_cooldown = 0
  world.request_town_entry()
  for i in 300:
   await physics_frame
   if not is_instance_valid(game.overworld_travel.overworld) and not game.transitioning: break
  check(not game.transitioning and game.zone=="town" and absf(game.clock-expected_time)<.02,"Returning to Garden Square keeps the advanced day/night time")
  var after: Dictionary = game.state.snapshot()
  after.erase("clock")
  check(after==before and game.player.health==3,"Time progression leaves inventory, equipment, quests, money and health unchanged")
 title.queue_free()
 await process_frame
 await process_frame
 FileAccess.open(ROOT+"atmosphere_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Painted scenery placement and colliders, day/night resources and lighting, painted sun and moon staying fully visible and clear of HUD through all phases, celestial dial, exact twenty-minute cycle, gradual real T input and midnight wrap, pause/map freeze, actual southwest travel sharing the main RPG clock, checkpoint time persistence and return with other journey state intact."},"  ")+"\n")
 print("ATMOSPHERE CHECKS ",checks-failures.size(),"/",checks)
 quit(0 if failures.is_empty() else 1)
