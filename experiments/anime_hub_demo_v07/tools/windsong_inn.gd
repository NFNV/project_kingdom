extends Node2D
## Painted guest floor. Coordinates are traced in the original painting's pixels.
const Mill := preload("res://experiments/anime_hub_demo_v07/tools/windsong_mill.gd")
const SIZE := Vector2i(1280,720)
const ROOT := Mill.ROOT
const BEDS := {
 "inn_sage":{"title":"Sage Room","at":Vector2(550,345),"wake":Vector2(550,345)},
 "inn_blue":{"title":"Bluebell Room","at":Vector2(710,350),"wake":Vector2(710,350)},
 "inn_rose":{"title":"Rose Room","at":Vector2(1340,345),"wake":Vector2(1340,345)}
}
var hub: Node2D
var room_material: ShaderMaterial

static func point(x: float,y: float) -> Vector2:
 return Vector2(x,y)*Vector2(SIZE)/Vector2(1672,941)

static func polygon(coords: Array) -> PackedVector2Array:
 var result := PackedVector2Array()
 for xy in coords: result.append(point(xy[0],xy[1]))
 return result

static func floor_polygon() -> PackedVector2Array:
 return polygon([[195,470],[230,350],[310,275],[560,270],[640,285],[675,265],[970,265],[1050,280],[1375,300],[1450,430],[1460,505],[1320,505],[1320,740],[1100,760],[930,800],[680,800],[430,755],[260,680],[195,605]])

static func exits() -> Dictionary:
 return {"mill_room":{"at":point(1265,655),"to":"mill_room","entry":"mill_loft","sign":"Hearthroom","label":"Stairs → Hearthroom","automatic":false}}

static func arrival() -> Vector2:
 return point(1135,650)

static func build(game: Node2D) -> Node2D:
 var inn: Node2D = load("res://experiments/anime_hub_demo_v07/tools/windsong_inn.gd").new()
 inn.hub = game
 game.zone_root.add_child(inn)
 game._solid(floor_polygon(),true)
 inn.build_rooms()
 return inn

func build_rooms() -> void:
 room_material = ShaderMaterial.new()
 room_material.shader = load(ROOT+"mill_room_light.gdshader")
 room_material.set_shader_parameter("night_painting",load(ROOT+"mill_inn_night_v1.png"))
 hub.backgrounds[0].material = room_material
 update_lighting(hub.clock)
 # Bed frames, bedside furniture, cutaway walls and stairwell rails are solid.
 # All three doorway gaps remain wide enough for the cat and navigation grid.
 for coords in [
  [[365,160],[520,160],[520,385],[365,385]],
  [[770,145],[925,145],[925,375],[770,375]],
  [[1150,170],[1310,170],[1310,390],[1150,390]],
  [[305,185],[385,185],[385,270],[305,285]],
  [[535,185],[585,185],[585,275],[535,275]],
  [[640,150],[685,150],[685,285],[640,285]],
  [[710,170],[775,170],[775,255],[710,255]],
  [[1040,175],[1150,175],[1150,280],[1040,280]],
  [[1310,215],[1390,215],[1390,310],[1310,310]],
  [[580,130],[640,130],[640,485],[580,485]],
  [[995,130],[1045,130],[1045,490],[995,490]],
  [[255,450],[395,455],[395,490],[255,490]],
  [[510,455],[750,455],[750,490],[510,490]],
  [[880,455],[1150,455],[1150,490],[880,490]],
  [[1260,455],[1450,440],[1450,490],[1260,490]],
  [[1320,515],[1510,515],[1510,740],[1350,740]],
  [[190,505],[275,540],[290,615],[235,640]]
 ]:
  hub._solid(polygon(coords))
 # Restore cutaway walls in front of a cat standing inside a bedroom.
 for coords in [[[245,350],[395,385],[395,490],[255,465]],[[510,385],[750,385],[750,490],[510,490]],[[880,385],[1150,385],[1150,490],[880,490]],[[1260,385],[1425,360],[1450,465],[1260,490]]]:
  foreground_wall(coords)
 for id in BEDS:
  var bed: Dictionary = BEDS[id]
  hub.interactables[id] = {"name":"Rest · "+bed.title,"at":point(bed.at.x,bed.at.y),"height":20.0,"range":110.0,"text":"A freshly made bed. Rest until 7 AM and recover all hearts."}
 hub.interactables.inn_flowers = {"name":"Flowers from the garden","at":point(1230,725),"height":15.0,"text":"Mira leaves a few stems of lavender here each evening. The landing smells faintly of flowers and fresh linen."}

func foreground_wall(coords: Array) -> void:
 var anchor := Node2D.new()
 anchor.position = point(0,490)
 hub.world.add_child(anchor)
 var wall := Polygon2D.new()
 var source := PackedVector2Array()
 var local_points := PackedVector2Array()
 for xy in coords:
  source.append(Vector2(xy[0],xy[1]))
  local_points.append(point(xy[0],xy[1])-anchor.position)
 wall.polygon = local_points
 wall.uv = source
 wall.texture = load(ROOT+"mill_inn_day_v2.png")
 wall.material = room_material
 wall.set_meta("mill_room_painting",true)
 anchor.add_child(wall)
 hub.pieces.append(wall)

func update_lighting(phase: float) -> void:
 if room_material!=null:
  room_material.set_shader_parameter("night_weight",Mill.night_weight(phase))

func can_use_bed(id: String) -> bool:
 if hub.zone!="mill_loft" or not BEDS.has(id) or not hub.player.active: return false
 var target: Vector2 = hub.interactables[id].at
 return hub.Actor.ground_vector(target-hub.player.position).length()<110 and hub.clear_line(hub.player.position,target)

func open_bed(id: String) -> void:
 if hub.shopping or hub.paused or hub.transitioning or not can_use_bed(id): return
 hub.inn_bed = id
 hub.shopping = true
 hub.player.stop_motion()
 hub.dialogue_left = 0
 hub.talk_panel.hide()
 hub.prompt.hide()
 hub.ui.inn_title.text = BEDS[id].title+" · Windsong Inn"
 hub.ui.inn_dialog.show()
 hub.ui.inn_sleep_button.grab_focus()

func rest(id: String) -> void:
 if hub.resting or hub.paused or hub.transitioning or not hub.ui.inn_dialog.visible or hub.inn_bed!=id or not can_use_bed(id): return
 hub.close_inn()
 hub.resting = true
 hub.transitioning = true
 hub.player.stop_motion()
 var fade := hub.create_tween()
 fade.tween_property(hub.ui.fade,"modulate:a",1.0,.4)
 await fade.finished
 hub.clock_target = -1.0
 hub.clock = 1.0/6.0 # 7 AM; the shared clock starts at 6 AM.
 hub.player.health = hub.player.maximum_health
 hub.player.skill_cooldown = 0
 var wake: Vector2 = BEDS[id].wake
 hub.player.position = point(wake.x,wake.y)
 hub.player.reset_physics_interpolation()
 hub._update_lighting()
 hub._update_hud()
 await hub.get_tree().create_timer(.45).timeout
 fade = hub.create_tween()
 fade.tween_property(hub.ui.fade,"modulate:a",0.0,.45)
 await fade.finished
 hub.transitioning = false
 hub.resting = false
 hub.audio.play_event("ui_confirm",hub.player.position,-8)
 hub.ui.show_notice("Good morning · 7 AM · All hearts restored")
 hub.queue_autosave()
