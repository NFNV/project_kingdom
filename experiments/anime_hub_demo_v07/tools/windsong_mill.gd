extends Node2D
## Two hand-authored peaceful areas, using the existing live RPG journey.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/mill/"
const GARDEN_SIZE := Vector2i(1920,1280)
const GARDEN_LAYOUT := 2
const ROOM_SIZE := Vector2i(1280,720)
const ROOM_LAYOUT := 2
const MILL_HEIGHT := 750.0
const MILL_CONTACT := Vector2(716,1007)
const MILL_FOOT := Vector2(944,950)
const MILL_DOOR := MILL_FOOT+Vector2(-176,48)*MILL_HEIGHT/1164.0
const GARDEN_ENTRY := Vector2(970,1120)
const GARDEN_EXIT := Vector2(960,1208)
var hub: Node2D
var indoors := false
var effect_clock := 0.0
var room_material: ShaderMaterial

static func garden(x: float,y: float) -> Vector2:
 return Vector2(x,y)*Vector2(GARDEN_SIZE)/Vector2(1536,1024)

static func room(x: float,y: float) -> Vector2:
 return Vector2(x,y)*Vector2(ROOM_SIZE)/Vector2(1672,941)

static func night_weight(phase: float) -> float:
 # Keep pre-dawn windows dark; warm lanterns take over around sunset.
 return 1.0-smoothstep(-.22,.45,sin(fposmod(phase,4)*PI*.5))

func update_lighting(phase: float) -> void:
 if room_material!=null:
  room_material.set_shader_parameter("night_weight",night_weight(phase))

static func polygon(coords: Array, inside: bool) -> PackedVector2Array:
 var points := PackedVector2Array()
 for p in coords: points.append(room(p[0],p[1]) if inside else garden(p[0],p[1]))
 return points

static func floor_for(inside: bool) -> PackedVector2Array:
 if inside:
  return polygon([[440,390],[810,300],[1030,325],[1250,415],[1410,565],[1500,585],[1440,680],[1260,740],[1080,775],[970,775],[935,838],[740,838],[700,782],[520,747],[485,705],[515,665],[480,618],[430,580],[415,515]],true)
 return polygon([[140,400],[300,260],[520,200],[720,150],[930,170],[1050,245],[1110,260],[1160,220],[1140,170],[1100,155],[1100,80],[1250,45],[1410,75],[1450,205],[1430,240],[1510,300],[1470,470],[1425,590],[1320,665],[1200,735],[1030,800],[900,865],[875,1020],[695,1020],[670,855],[480,775],[330,725],[255,665],[170,580]],false)

static func exits_for(inside: bool) -> Dictionary:
 if inside:
  return {"mill_garden":{"at":room(840,800),"to":"mill_garden","entry":"mill_room","sign":"Mill garden","label":"Front door → Mill garden"}}
 return {"mill_room":{"at":MILL_DOOR,"to":"mill_room","entry":"mill_garden","sign":"Windsong Mill","label":"Enter the cozy mill","automatic":false},"overworld":{"at":GARDEN_EXIT,"to":"overworld","entry":"mill_garden","sign":"The Greenshire","label":"Garden gate → Windsong Ridge"}}

static func arrival(inside: bool, entry: String) -> Vector2:
 if inside: return room(840,745)
 return MILL_DOOR+Vector2(0,60) if entry=="mill_room" else GARDEN_ENTRY

static func mill_footprint() -> PackedVector2Array:
 # Authored at a 500px mill height; scale collision with the actual building.
 var points := PackedVector2Array()
 for offset in [Vector2(-170,-95),Vector2(-20,-165),Vector2(215,-100),Vector2(215,-15),Vector2(5,30),Vector2(-30,-30),Vector2(-150,-30)]:
  points.append(MILL_FOOT+offset*MILL_HEIGHT/500.0)
 return points

static func build(game: Node2D, inside: bool) -> Node2D:
 var place: Node2D = load("res://experiments/anime_hub_demo_v07/tools/windsong_mill.gd").new()
 place.hub = game
 place.indoors = inside
 place.z_index = 3
 game.zone_root.add_child(place)
 game._solid(floor_for(inside),true)
 if inside: place.build_room()
 else: place.build_garden()
 return place

func resident(id: String, title: String, asset: String, at: Vector2, words: String) -> Node2D:
 hub._resident(id,title,asset,at,108)
 hub.interactables[id].text = words
 return hub.interactables[id].anchor

func landmark(id: String,title: String,at: Vector2,words: String) -> void:
 hub.interactables[id] = {"name":title,"at":at,"height":35.0,"text":words}

func build_garden() -> void:
 var anchor := Node2D.new()
 anchor.position = MILL_FOOT
 hub.world.add_child(anchor)
 var sprite := Sprite2D.new()
 sprite.texture = load("res://experiments/overworld_2d_v01/art/region/windmill.png")
 sprite.centered = false
 # The same original painting and calibrated foundation used on the world map.
 sprite.offset = -MILL_CONTACT
 sprite.scale = Vector2.ONE*MILL_HEIGHT/sprite.texture.get_height()
 anchor.add_child(sprite)
 hub.pieces.append(sprite)
 hub.occluders.append(sprite)
 hub._solid(mill_footprint())
 # Garden beds are solid; the gate and path through the backyard remain open.
 hub._solid(polygon([[1190,120],[1290,132],[1275,185],[1195,175]],false))
 hub._solid(polygon([[1300,160],[1410,150],[1440,215],[1320,250]],false))
 hub._solid(polygon([[1280,45],[1395,48],[1410,85],[1305,100]],false))
 resident("mill_gardener","Mira · Mill gardener","cat_baker",garden(1080,275),"Welcome to Windsong! The backyard is open. I grow chamomile by the gate, lavender by the wall, and enough daisies for everyone.")
 resident("mill_grandfather","Orin · Keeper of the orchard","cat_elder",garden(425,310),"I planted this apple tree when the mill was young. Sit a while if you like. Rowan keeps the kettle warm inside.")
 landmark("mill_backyard","The flower garden",garden(1230,95),"Mint, rosemary and hollyhocks fill the little backyard. Fresh laundry catches the breeze beyond the vegetable beds.")
 landmark("mill_garden_bench","The orchard bench",garden(340,258),"A quiet seat beneath the apple tree. The sound of the windmill drifts across the garden.")
 landmark("mill_sign","Windsong Mill",MILL_DOOR+Vector2(115,90),"A mill, a warm hearth and an open door. Rowan welcomes travellers on the ground floor; the loft is closed for repairs.")

func build_room() -> void:
 room_material = ShaderMaterial.new()
 room_material.shader = load(ROOT+"mill_room_light.gdshader")
 room_material.set_shader_parameter("night_painting",load(ROOT+"mill_interior_night_v1.png"))
 hub.backgrounds[0].material = room_material
 update_lighting(hub.clock)
 # Traced against the painting: millstone, counter, sacks and stairs cannot be crossed.
 for coords in [[[420,310],[760,270],[790,310],[745,355],[470,415]],[[1050,310],[1240,355],[1305,435],[1250,465],[1060,380]],[[1270,390],[1440,470],[1460,550],[1360,570]],[[425,510],[480,530],[500,625],[470,660],[420,615]]]:
  hub._solid(polygon(coords,true))
 var miller := resident("mill_keeper","Rowan · Windsong miller","cat_baker",room(650,260),"Come in, friend. There is always a place by the fire here. The flour is fresh, the kettle is on, and the road can wait a little.")
 miller.face_towards(room(665,415))
 hub.interactables.mill_keeper.at = room(665,410)
 # Restore the painted counter in front of the keeper's lower body. It shares
 # the original pixels, so the NPC is genuinely behind the counter in the view.
 var counter_anchor := Node2D.new()
 counter_anchor.position = room(650,410)
 hub.world.add_child(counter_anchor)
 var counter := Polygon2D.new()
 var source := PackedVector2Array([Vector2(450,270),Vector2(700,220),Vector2(780,220),Vector2(790,310),Vector2(745,355),Vector2(470,405)])
 var points := PackedVector2Array()
 for p in source: points.append(room(p.x,p.y)-counter_anchor.position)
 counter.polygon = points
 counter.uv = source
 counter.texture = load(ROOT+"mill_interior_v1.png")
 counter.material = room_material
 counter.set_meta("mill_room_painting",true)
 counter_anchor.add_child(counter)
 hub.pieces.append(counter)
 resident("mill_reader","Juniper · A travelling reader","cat_bookseller",room(1095,670),"I came for a cup of tea and stayed for the stories. On windy evenings, the timbers hum like a very old song.")
 landmark("mill_tea","A pot of meadow tea",room(520,610),"Rowan pours fragrant chamomile tea. A little warmth, a little honey, and nowhere you have to hurry.")
 landmark("mill_stairs","Stairs to the loft",room(1325,575),"The upper loft is closed for repairs. For now, make yourself at home downstairs.")
 landmark("mill_hearth","The mill hearth",room(970,390),"The kettle murmurs over a gentle fire. The stones hold their warmth long after sunset.")

func _process(delta: float) -> void:
 if hub.paused or hub.transitioning: return
 effect_clock += delta
 queue_redraw()

func _draw() -> void:
 if indoors:
  var fire := room(950,270)
  for i in 4:
   var age := fposmod(effect_clock*.38+i*.25,1)
   draw_circle(fire+Vector2(sin(i*2+effect_clock)*7,-age*33),1.5*(1-age),Color(1,.65,.22,(1-age)*.45))
  # Low, warm, flickering firelight remains readable during the night cycle.
  draw_circle(fire+Vector2(0,10),36+sin(effect_clock*3)*2,Color(1,.66,.26,.035))
 else:
  for i in 15:
   var at := garden(260+fposmod(i*107.0+effect_clock*(2+i%3),1000),310+fposmod(i*83.0,400))
   at.y += sin(effect_clock*.8+i)*12
   draw_set_transform(at,sin(effect_clock*2+i)*.4,Vector2(1,.55))
   draw_circle(Vector2(-3,0),2,Color(1,.92,.70,.6))
   draw_circle(Vector2(3,0),2,Color(1,.92,.70,.6))
  draw_set_transform(Vector2.ZERO)
