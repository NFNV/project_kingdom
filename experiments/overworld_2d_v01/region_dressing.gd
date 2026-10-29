extends RefCounted
const Map := preload("res://experiments/overworld_2d_v01/layout.gd")
const ART := "res://experiments/anime_hub_assets_v06/"
const PAINTED := "res://experiments/overworld_2d_v01/art/architecture/"
const HOUSE_KINDS := ["ivy_cottage","balcony_cottage","bakery","grocer_shop","bookshop","country_hall"]
const CATALOG := {
 "city_illustration":PAINTED+"mosswood_painted_v1.png",
 "ivy_cottage":PAINTED+"cottage_sage_drawn_v1.png", "balcony_cottage":PAINTED+"cottage_ochre_drawn_v1.png",
 "bakery":PAINTED+"village_shop_drawn_v1.png", "grocer_shop":PAINTED+"village_shop_drawn_v1.png",
 "bookshop":PAINTED+"cottage_sage_drawn_v1.png", "country_hall":PAINTED+"cottage_ochre_drawn_v1.png",
 "bakery_stall":ART+"vendors/bakery_stall.png", "produce_stall":ART+"vendors/produce_stall.png",
 "flowers":ART+"scenery/flower_planter.png", "bench":ART+"scenery/bench.png",
 "lamp":ART+"scenery/street_lamp.png",
 "watermill":"res://experiments/overworld_2d_v01/art/region/watermill_v1.png",
 "lighthouse":"res://experiments/overworld_2d_v01/art/region/lighthouse_v1.png"
}
const WATERMILL := Map.WATERMILL
const LIGHTHOUSE := Map.LIGHTHOUSE
# Cropped-image UVs: small soft light blooms preserve the painted window shapes.
const EMITTERS := {
 "city_illustration":[Vector2(.20,.58),Vector2(.44,.35),Vector2(.71,.36),Vector2(.79,.63)],
 "ivy_cottage":[Vector2(.29,.67),Vector2(.60,.73)],
 "balcony_cottage":[Vector2(.29,.67),Vector2(.60,.73)],
 "bakery":[Vector2(.29,.67),Vector2(.60,.73)],
 "grocer_shop":[Vector2(.29,.67),Vector2(.60,.73)],
 "bookshop":[Vector2(.29,.67),Vector2(.60,.73)],
 "country_hall":[Vector2(.29,.67),Vector2(.60,.73)],
 "windmill":[Vector2(.43,.78),Vector2(.78,.81)],
 "watermill":[Vector2(.37,.64),Vector2(.50,.65)],
 "lighthouse":[Vector2(.35,.25),Vector2(.60,.76)],
 "lamp":[Vector2(.5,.18)]
}

static func props() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 var houses := [
  ["ivy_cottage",Vector2(-80,52)],["balcony_cottage",Vector2(-15,55)],
  ["bakery",Vector2(-86,38)],["bookshop",Vector2(-10,31)],
  ["ivy_cottage",Vector2(-27,-12)],["grocer_shop",Vector2(-70,-6)],
  ["ivy_cottage",Vector2(-157,163)],["balcony_cottage",Vector2(-118,167)],
  ["grocer_shop",Vector2(-149,184)],["bookshop",Vector2(-165,143)],
  ["bakery",Vector2(-12,125)],["ivy_cottage",Vector2(27,129)],
  ["balcony_cottage",Vector2(-27,192)],["bookshop",Vector2(80,198)],
  ["ivy_cottage",Vector2(84,224)],["grocer_shop",Vector2(141,350)],
  ["balcony_cottage",Vector2(145,375)],["country_hall",Vector2(-97,332)],
  ["ivy_cottage",Vector2(-107,300)],["bookshop",Vector2(56,280)]
 ]
 for house in houses:
  if put(result,house[0],house[1],4.6,2.0):
   for side in [-1,1]: put(result,"flowers",house[1]+Vector2(side*3.8,-1),.95,.35)
   put(result,"lamp",house[1]+Vector2(4.7,-3),3.1,.25)
 for stall in [["bakery_stall",Vector2(-79,38)],["produce_stall",Vector2(-146,150)],["bakery_stall",Vector2(91,207)],["produce_stall",Vector2(130,362)],["produce_stall",Vector2(25,146)],["bakery_stall",Vector2(-123,184)]]:
  put(result,stall[0],stall[1],2.3,1.1)
 for at in [Vector2(92,202),Vector2(-144,140),Vector2(150,340),Vector2(-94,302)]: put(result,"bench",at,1.35,.7)
 put(result,"watermill",WATERMILL,8.8,3.5)
 put(result,"lighthouse",LIGHTHOUSE,10.0,3.0)
 # Lanterns follow the main road and both regional branches, clear of the lane.
 for z in range(-10,450,30):
  var side := -1 if posmod(z,60)<30 else 1
  put(result,"lamp",Vector2(Map.road_x(z)+side*6.5,z),3.1,.25)
 for route in Map.ROUTES:
  for i in range(1,route.size()):
   var a: Vector2 = route[i-1]
   var b: Vector2 = route[i]
   var side := (b-a).normalized().orthogonal()*6.5
   for step in range(1,maxi(2,ceili(a.distance_to(b)/28))):
    var at := a.lerp(b,step/float(maxi(2,ceili(a.distance_to(b)/28))))+side
    put(result,"lamp",at,3.1,.25)
 # Town gate lamps are outside the wall and do not narrow its passage.
 for side in [-1,1]:
  result.append(make_prop("lamp",Map.TOWN+Vector2(side*4.0,-16),3.0,.25))
 return result

static func make_prop(kind: String, at: Vector2, height: float, radius: float) -> Dictionary:
 var result := {"p":at,"kind":kind,"height":height,"radius":radius,"tint":Color.WHITE,"phase":float(posmod(hash(at),100))*.1,"dressed":true}
 if kind in HOUSE_KINDS:
  result.max_height = 180.0
  result.max_width = 230.0
 return result

static func put(result: Array[Dictionary],kind: String,at: Vector2,height: float,radius: float) -> bool:
 if not Map.safe_ground(at) or Map.road_distance(at)<radius+1.2 or at.distance_to(Map.TOWN)<22: return false
 if absf(at.y-Map.river_z(at.x))<radius+6: return false
 if result.any(func(item: Dictionary): return item.p.distance_to(at)<item.radius+radius+.25): return false
 result.append(make_prop(kind,at,height,radius))
 return true
