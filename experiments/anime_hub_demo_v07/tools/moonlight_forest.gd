extends Node2D
## The forest and its undercroft share the live journey, combat and inventory.
const FOREST := "moonlight_forest"
const PASSAGE := "moonlight_passage"
const CISTERN := "moonlight_cistern"
const CHAPEL := "moonlight_chapel"
const ZONES := [FOREST,PASSAGE,CISTERN,CHAPEL]
const ROOT := "res://experiments/anime_hub_demo_v07/assets/moonlight/"
const SIZE := Vector2i(3072,1728)
const CASTLE_BOUNDS := Rect2(1100,260,880,320)
const BRIDGE := Rect2(1770,765,200,210)
const STONES := Rect2(2340,805,150,125)
const CHEST := preload("res://experiments/anime_hub_demo_v07/assets/loot/treasure_chest.tscn")
const LAYOUT := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/layout.tscn")
const ENEMIES := ["glade_1","glade_2","creek_1","creek_2","cistern_1","cistern_2","chapel_1","chapel_2","vault_keeper"]
# Keep the retired chapel_shortcut flag readable for existing journey saves.
const FLAGS := ["forest_shortcut","chapel_shortcut","winch","moonwell_claimed","vault_claimed"]
var hub: Node2D
var layout: Node2D
var effects := 0.0
var chest: Node2D
var cache: Node2D
var gates: Dictionary = {}
var recovering := false
var cistern_detail: Node2D

static func fresh_progress() -> Dictionary:
 return {"defeated":[],"forest_shortcut":false,"chapel_shortcut":false,"winch":false,"moonwell_claimed":false,"vault_claimed":false,"checkpoint":FOREST}

static func progress_valid(data: Variant) -> bool:
 if not data is Dictionary or data.size()!=7: return false
 for flag in FLAGS:
  if not data.get(flag) is bool: return false
 if data.get("checkpoint") not in [FOREST,CISTERN]: return false
 if not data.get("defeated") is Array or data.defeated.size()>ENEMIES.size(): return false
 var seen := {}
 for id in data.defeated:
  if id not in ENEMIES or seen.has(id): return false
  seen[id] = true
 return not data.vault_claimed or "vault_keeper" in data.defeated

static func files_for(zone: String) -> Array:
 return [ROOT+{FOREST:"forest_crossing.png",PASSAGE:"castle_passage_v02.png",CISTERN:"undercroft.png",CHAPEL:"chapel.png"}[zone]]

static func floor_for(zone: String) -> PackedVector2Array:
 if zone==FOREST:
  return PackedVector2Array([Vector2(310,440),Vector2(900,300),Vector2(2200,300),Vector2(2750,540),Vector2(2810,1420),Vector2(2530,1590),Vector2(520,1590),Vector2(270,1280)])
 if zone==CISTERN:
  return PackedVector2Array([Vector2(320,580),Vector2(700,435),Vector2(2400,435),Vector2(2770,680),Vector2(2800,1530),Vector2(340,1530)])
 if zone==PASSAGE:
  # Continue north down from the castle; the lower landing opens east.
  # The separate eastern flight climbs north into the Undercroft.
  return PackedVector2Array([Vector2(450,1040),Vector2(2310,1040),Vector2(2450,620),Vector2(2710,620),Vector2(2710,680),Vector2(2600,1180),Vector2(2790,1280),Vector2(2790,1470),Vector2(1020,1470),Vector2(1020,1640),Vector2(280,1640),Vector2(280,1520)])
 return PackedVector2Array([Vector2(400,660),Vector2(760,460),Vector2(2280,460),Vector2(2710,660),Vector2(2740,1540),Vector2(340,1540)])

static func exits_for(zone: String) -> Dictionary:
 if zone==FOREST:
  return {"overworld":{"at":Vector2(1536,1520),"to":"overworld","entry":FOREST,"sign":"The Greenshire","label":"Forest trail → The Greenshire"},"castle":{"at":Vector2(1536,595),"to":PASSAGE,"entry":FOREST,"sign":"Castle stairs","label":"Enter the castle's lower passages","automatic":false}}
 if zone==PASSAGE:
  return {"castle":{"at":Vector2(570,1570),"to":FOREST,"entry":PASSAGE,"sign":"Castle courtyard","label":"Back up the entrance stairs → Moonlight Forest","automatic":false},"undercroft":{"at":Vector2(2580,650),"to":CISTERN,"entry":PASSAGE,"sign":"Undercroft stairs","label":"Climb the far stairs → The Undercroft","automatic":false}}
 if zone==CISTERN:
  return {"stairs":{"at":Vector2(560,1430),"to":PASSAGE,"entry":CISTERN,"sign":"Castle passages","label":"Down the stairs → Castle passages","automatic":false},"chapel":{"at":Vector2(1536,500),"to":CHAPEL,"entry":CISTERN,"sign":"Root Chapel","label":"Through the chapel doors","automatic":false}}
 return {"cistern":{"at":Vector2(1536,1480),"to":CISTERN,"entry":CHAPEL,"sign":"Undercroft","label":"Return to the cistern","automatic":false}}

static func arrival(zone: String, entry: String) -> Vector2:
 if zone==FOREST: return Vector2(1536,710) if entry in [PASSAGE,CISTERN] else Vector2(1536,1390)
 if zone==PASSAGE: return Vector2(2550,790) if entry==CISTERN else Vector2(570,1460)
 if zone==CISTERN: return Vector2(1536,610) if entry==CHAPEL else Vector2(610,1340)
 return Vector2(1536,1350)

static func passage_stonework() -> Dictionary:
 # Cover the projected faces as well as the caps: the artwork is a floor
 # painting, so these raised surfaces cannot occlude an actor standing on it.
 return {
  "EntranceWestPost":PackedVector2Array([Vector2(145,1355),Vector2(250,1355),Vector2(250,1670),Vector2(145,1670)]),
  "EntranceEastRail":PackedVector2Array([Vector2(780,1140),Vector2(880,1140),Vector2(1040,1670),Vector2(900,1670)]),
  "EntranceEastPost":PackedVector2Array([Vector2(910,1355),Vector2(1040,1355),Vector2(1040,1670),Vector2(910,1670)]),
  "UndercroftWestRail":PackedVector2Array([Vector2(2390,595),Vector2(2460,595),Vector2(2290,1220),Vector2(2180,1220)]),
  "UndercroftWestPost":PackedVector2Array([Vector2(2180,990),Vector2(2290,990),Vector2(2290,1220),Vector2(2180,1220)]),
  "UndercroftEastRail":PackedVector2Array([Vector2(2680,595),Vector2(2740,595),Vector2(2690,1220),Vector2(2590,1220)]),
  "UndercroftEastPost":PackedVector2Array([Vector2(2590,1000),Vector2(2690,1000),Vector2(2690,1220),Vector2(2590,1220)])
 }

static func build(game: Node2D) -> Node2D:
 var area: Node2D = load("res://experiments/anime_hub_demo_v07/tools/moonlight_forest.gd").new()
 area.hub = game
 game.zone_root.add_child(area)
 area.layout = LAYOUT.instantiate()
 game.zone_root.add_child(area.layout)
 game._solid(floor_for(game.zone),true)
 if game.zone==FOREST: area.build_forest()
 elif game.zone==PASSAGE: area.build_passage()
 elif game.zone==CISTERN: area.build_cistern()
 else: area.build_chapel()
 game.combat_active = game.dogs.any(func(dog): return dog.active)
 return area

func point(id: String) -> Vector2:
 return layout.get_node(hub.zone+"/"+id).position

func interactable(id: String, title: String, at: Vector2, words: String) -> void:
 hub.interactables[id] = {"name":title,"at":at,"height":35.0,"text":words,"range":130.0}

func enemy(id: String, at: Vector2, heavy := false) -> void:
 if id in hub.state.moonlight.defeated: return
 var dog = hub._actor(false,at,"mauler" if heavy else "raider")
 dog.resident_id = id
 dog.enemy = true
 dog.home = at
 dog.patrol = PackedVector2Array([at,at+Vector2(65,30),at+Vector2(-55,35)])
 dog.maximum_health = 7 if heavy else 4
 if id=="vault_keeper":
  dog.maximum_health = 22
  dog.sprite.display_height *= 1.32
  dog.sprite.modulate = Color("c4c1ed")
  var title := Label.new()
  title.text = "MOONBOUND KEEPER"
  title.position = Vector2(-90,-dog.sprite.display_height-30)
  title.add_theme_font_size_override("font_size",13)
  title.add_theme_color_override("font_color",Color("e5d9fb"))
  title.add_theme_color_override("font_outline_color",Color("292b48"))
  title.add_theme_constant_override("outline_size",4)
  dog.add_child(title)
 dog.health = dog.maximum_health
 dog.patrol_wait = .5
 hub.dogs.append(dog)

func region_prop(path: String, at: Vector2, height: float) -> void:
 var texture: Texture2D = load(path)
 var image := texture.get_image()
 var used := image.get_used_rect()
 var cropped := AtlasTexture.new()
 cropped.atlas = texture
 cropped.region = Rect2(used)
 var anchor := Node2D.new()
 anchor.position = at
 hub.world.add_child(anchor)
 var sprite := Sprite2D.new()
 sprite.texture = cropped
 sprite.position = Vector2(0,-height*.5+6)
 sprite.scale = Vector2.ONE*height/cropped.get_height()
 anchor.add_child(sprite)
 hub.pieces.append(sprite)

func build_forest() -> void:
 var detail := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
 detail.name = "ForestDetail"
 detail.z_index = -9
 hub.zone_root.add_child(detail)
 for bank in [Rect2(250,805,BRIDGE.position.x-250,125),Rect2(BRIDGE.end.x,805,STONES.position.x-BRIDGE.end.x,125),Rect2(STONES.end.x,805,2860-STONES.end.x,125)]:
  hub._solid(PackedVector2Array([bank.position,Vector2(bank.end.x,bank.position.y),bank.end,Vector2(bank.position.x,bank.end.y)]))
 for marker in layout.get_node(FOREST+"/Trees").get_children():
  hub._piece("willow_tree" if marker.name.begins_with("Willow") else "elm_tree",marker.position,270)
  hub._solid(hub._ellipse(marker.position,Vector2(25,17)))
 # Keep the facade and rear solid. Entry is through the front stair interaction.
 region_prop(ROOT+"castle_straight_stairs.png",Vector2(1536,575),520)
 hub._solid(PackedVector2Array([CASTLE_BOUNDS.position,Vector2(CASTLE_BOUNDS.end.x,CASTLE_BOUNDS.position.y),CASTLE_BOUNDS.end,Vector2(CASTLE_BOUNDS.position.x,CASTLE_BOUNDS.end.y)]))
 for id in ["CampLamp","CastleLamp"]:
  hub._piece("street_lamp",point(id),150)
 var well := point("Moonwell")
 hub._piece("fountain",well-Vector2(0,80),155)
 hub._solid(hub._ellipse(well-Vector2(0,80),Vector2(60,32)))
 cache = CHEST.instantiate()
 cache.position = well+Vector2(70,10)
 cache.display_width = 65
 hub.world.add_child(cache)
 if hub.state.moonlight.moonwell_claimed: cache.open()
 interactable("moon_camp","Lantern Camp · Rest",point("Camp"),"A sheltered camp beneath silver leaves.")
 interactable("moon_well","Moonwell · Open cache",point("Moonwell"),"A small offering beside the old moonwell.")
 interactable("moon_wicket","Castle wicket · Open shortcut",point("Wicket"),"Unbar the woodland path back to Lantern Camp.")
 interactable("moon_wicket_return","Lantern Camp wicket",point("WicketReturn"),"The wicket opens from the castle courtyard.")
 for id in ["glade_1","glade_2","creek_1","creek_2"]:
  enemy(id,point(id),id=="creek_2")

func build_passage() -> void:
 var detail := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
 detail.name = "CastlePassageDetail"
 detail.panel_root = ROOT+"passage_panels_v02/"
 detail.z_index = -9
 hub.zone_root.add_child(detail)
 for id in passage_stonework():
  var body: StaticBody2D = hub._solid(passage_stonework()[id])
  body.name = id

func build_cistern() -> void:
 cistern_detail = preload("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
 cistern_detail.name = "UndercroftDetail"
 cistern_detail.panel_root = ROOT+"cistern_panels/"
 cistern_detail.animate_water = true
 cistern_detail.door_open = hub.state.moonlight.winch
 cistern_detail.z_index = -9
 hub.zone_root.add_child(cistern_detail)
 var winch := point("Winch")+Vector2(55,-30)
 region_prop(ROOT+"winch.png",winch,125)
 hub._solid(hub._ellipse(winch,Vector2(30,18)))
 var water_material := ShaderMaterial.new()
 water_material.shader = load(ROOT+"cistern_water.gdshader")
 hub.backgrounds[0].material = water_material
 hub._solid(PackedVector2Array([Vector2(885,680),Vector2(2145,680),Vector2(2145,1235),Vector2(885,1235)]))
 # Follow the plinths in the painting as well as the water's stone rim.
 for pillar in [Vector2(300,1060),Vector2(2770,1160)]:
  hub._solid(hub._ellipse(pillar,Vector2(115,65)))
 hub._solid(hub._ellipse(Vector2(2075,545),Vector2(80,45)))
 interactable("moon_entry","Entry Hall · Rest",point("Checkpoint"),"The sheltered landing is a safe place to rest.")
 interactable("moon_winch","Cistern winch",point("Winch"),"Turn the winch to open the chapel doors.")
 if not hub.state.moonlight.winch:
  gates["grate"] = hub._solid(PackedVector2Array([Vector2(1410,530),Vector2(1665,530),Vector2(1665,563),Vector2(1410,563)]))
 for id in ["cistern_1","cistern_2"]: enemy(id,point(id),id=="cistern_2")

func build_chapel() -> void:
 var detail := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
 detail.name = "ChapelDetail"
 detail.panel_root = ROOT+"chapel_panels/"
 detail.z_index = -9
 hub.zone_root.add_child(detail)
 for id in ["chapel_1","chapel_2"]: enemy(id,point(id))
 enemy("vault_keeper",point("Keeper"),true)
 if "vault_keeper" in hub.state.moonlight.defeated: show_chest()

func show_chest() -> void:
 if is_instance_valid(chest): return
 chest = CHEST.instantiate()
 chest.position = point("Chest")
 chest.display_width = 115
 hub.world.add_child(chest)
 if hub.state.moonlight.vault_claimed: chest.open()
 interactable("moon_chest","Sealed Vault · Treasure chest",chest.position,"A chest left beneath the roots.")

func can_use_safe_point() -> bool:
 return not hub.dogs.any(func(dog): return dog.active and dog.alerted and dog.position.distance_to(hub.player.position)<400)

func use(id: String) -> void:
 var progress: Dictionary = hub.state.moonlight
 match id:
  "moon_camp","moon_entry":
   if not can_use_safe_point():
    hub._say("Catch your breath","Draw the nearby enemies away before resting.")
    return
   progress.checkpoint = hub.zone
   hub.state.health = hub.state.maximum_health
   hub._say("A quiet moment","Health restored. Your checkpoint is now here.")
  "moon_well":
   if progress.moonwell_claimed:
    hub._say("Moonwell","The moonwell's cache has already been collected.")
    return
   progress.moonwell_claimed = true
   cache.open()
   hub.state.add_item("healing_draught",2)
   hub.coins += 15
   hub._say("Moonwell cache","Two healing draughts and 15 coins collected.")
  "moon_winch":
   progress.winch = true
   cistern_detail.set_door_open(true)
   if gates.has("grate"):
    var body: StaticBody2D = gates.grate
    hub.blockers.erase(body.get_child(0).polygon)
    body.get_parent().remove_child(body)
    body.queue_free()
    gates.erase("grate")
    hub._build_navigation()
   hub.audio.play_event("door",hub.player.position,-5)
   hub._say("The chapel doors open","The path into Root Chapel is open.")
  "moon_wicket":
   if progress.forest_shortcut:
    relocate(point("WicketReturn")+Vector2(60,-30))
   progress.forest_shortcut = true
   hub._say("Castle wicket opened","The shortcut back to Lantern Camp is open. Use either end to cross.")
  "moon_wicket_return":
   if not progress.forest_shortcut:
    hub._say("A barred wicket","Reach the castle courtyard to unbar this path.")
    return
   relocate(point("Wicket")+Vector2(-60,50))
  "moon_chest":
   if progress.vault_claimed:
    hub._say("An empty chest","You have collected the vault treasure.")
    return
   progress.vault_claimed = true
   hub.coins += 100
   hub.state.add_item("healing_draught",3)
   chest.open()
   hub.audio.play_event("victory",hub.player.position,-5)
   hub._say("The Sealed Vault","100 coins and three healing draughts collected. Return through the chapel entrance to reach the Undercroft.")
 hub.queue_autosave()
 queue_redraw()

func relocate(at: Vector2) -> void:
 hub.player.position = at
 hub.player.route.clear()
 hub.player.stop_motion()
 hub.player.reset_physics_interpolation()
 hub.camera.reset_smoothing()
 hub.camera.force_update_scroll()

func yielded(actor: Node2D) -> void:
 if actor==hub.player:
  if recovering: return
  recovering = true
  hub.transitioning = true
  recover.call_deferred()
  return
 if actor.resident_id not in hub.state.moonlight.defeated:
  hub.state.moonlight.defeated.append(actor.resident_id)
 var fade := actor.create_tween()
 fade.tween_property(actor.sprite,"modulate:a",0.0,.35)
 fade.tween_callback(actor.hide)
 hub.combat_active = hub.dogs.any(func(dog): return dog.active)
 if actor.resident_id=="vault_keeper":
  show_chest()
  hub._say("The vault falls silent","The keeper has yielded. Open the chest beneath the roots.")
 hub.queue_autosave()

func recover() -> void:
 var checkpoint: String = hub.state.moonlight.checkpoint
 var game := hub
 game.state.health = game.state.maximum_health
 game._travel.call_deferred(checkpoint,"checkpoint")

func _process(delta: float) -> void:
 if hub.paused or hub.transitioning: return
 effects += delta
 queue_redraw()

func _draw() -> void:
 if not is_instance_valid(hub): return
 if hub.zone==FOREST:
  for i in 36:
   var at := Vector2(410+fposmod(i*173.0+sin(effects*.25+i)*45,2200),520+fposmod(i*89.0,900))
   at.y += sin(effects*.7+i)*12
   var alpha := .3+.25*sin(effects*1.8+i)
   draw_circle(at,9,Color(.60,.85,1,.025))
   draw_circle(at,1.8,Color(.7,.95,1,alpha))
  for id in ["Camp","Wicket","WicketReturn","Moonwell"]:
   var at := point(id)
   draw_arc(at+Vector2(0,-5),30,0,TAU,36,Color(.6,.82,1,.25),1.5,true)
  var camp := point("Camp")+Vector2(-95,-15)
  draw_circle(camp,28,Color(1,.63,.23,.07),true,-1,true)
  for i in 3:
   var log_end := Vector2.from_angle(i*PI/3)*17
   draw_line(camp-log_end,camp+log_end,Color("564437"),7,true)
  var flame := PackedVector2Array([camp+Vector2(-7,0),camp+Vector2(-10,-12),camp+Vector2(-4,-18),camp+Vector2(sin(effects*5)*3,-34),camp+Vector2(5,-20),camp+Vector2(9,-11),camp+Vector2(6,0)])
  draw_colored_polygon(flame,Color("ed9b51"))
  draw_colored_polygon(PackedVector2Array([camp+Vector2(-4,-2),camp+Vector2(sin(effects*6)*2,-22),camp+Vector2(5,-2)]),Color("ffe5a0"))
