extends RefCounted
# Shared by terrain, navigation, the map and scenery placement.
const BOUNDS := Rect2(-240,-80,480,560)
const START := Vector2(0,0)
const TOWN := Vector2(-47,39)
const FOREST := Vector2(9,173)
const WINDMILL := Vector2(-135,155)
const LAKESIDE := Vector2(105,197)
const RUINS := Vector2(-80,315)
const COAST := Vector2(165,350)
const WATERMILL := Vector2(-88,70)
const LIGHTHOUSE := Vector2(174,369)
const LAKE := Vector2(145,205)
const LAKE_SIZE := Vector2(30,38)
const BRIDGE_X := 18.0
const RIVER_Z := 85.0
const RIVER_WAVE := 8.0
const RIVER_RATE := .03
const RIVER_HALF := 4.8
const BRIDGE_HALF := 5.5
const ROUTES := [
 [Vector2(18,105),Vector2(-25,120),Vector2(-95,135),WINDMILL],
 [Vector2(3,173),Vector2(60,170),Vector2(100,180),LAKESIDE],
 [LAKESIDE,Vector2(100,260),Vector2(130,320),COAST],
 [WINDMILL,Vector2(-115,220),RUINS,Vector2(-18,295)],
 [Vector2(-47,24),Vector2(-47,15),Vector2(4,15)],
 [Vector2(-47,15),Vector2(-92,30),Vector2(-98,56),Vector2(-88,62)],
 [COAST,Vector2(169,363),Vector2(174,363)]
]

static func landmarks() -> Array[Dictionary]:
 return [
  {"p":START,"name":"SUNLIT MEADOW","short":"Meadow","description":"Follow the north road to Mosswood and Riverbend Crossing."},
  {"p":Vector2(18,river_z(18)-14),"name":"RIVERBEND CROSSING","short":"Bridge","description":"The timber bridge is the safe passage to the northern routes."},
  {"p":FOREST,"name":"BRIARWOOD FOREST","short":"Briarwood","description":"Deep fir groves frame a fork toward the lake and old ruins."},
  {"p":TOWN+Vector2(15,-25),"location":TOWN,"name":"MOSSWOOD","short":"Mosswood","description":"Clock Hall, Garden Square and the market nestle inside the town walls."},
  {"p":WINDMILL+Vector2(10,-15),"location":WINDMILL,"name":"WINDSONG RIDGE","short":"Windmill","description":"A cream-stone mill and a tiny market hamlet watch over the western meadows."},
  {"p":LAKESIDE,"name":"WILLOWMERE LAKE","short":"Willowmere","description":"Follow the shore path south or continue north toward the coast."},
  {"p":RUINS+Vector2(10,-16),"location":RUINS,"name":"IVYKEEP RUINS","short":"Ivykeep","description":"An ivy-covered arch is all that remains of the old watch keep."},
  {"p":COAST,"name":"PALESTONE COAST","short":"Coast","description":"A little lighthouse watches over the pale rocks and open sea."}
 ]

static func branch_segments() -> Array[Vector4]:
 var result: Array[Vector4] = []
 for route in ROUTES:
  for i in range(1,route.size()):
   result.append(Vector4(route[i-1].x,route[i-1].y,route[i].x,route[i].y))
 return result

static func segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
 return p.distance_to(a+(b-a)*clampf((p-a).dot(b-a)/(b-a).length_squared(),0,1))

static func road_distance(p: Vector2) -> float:
 var result := absf(p.x-road_x(p.y))
 for route in ROUTES:
  for i in range(1,route.size()):
   result = minf(result,segment_distance(p,route[i-1],route[i]))
 return result

static func river_z(x: float) -> float:
 return RIVER_Z+sin(x*RIVER_RATE)*RIVER_WAVE

static func road_x(z: float) -> float:
 return sin(z*.016)*18

static func coast_x(z: float) -> float:
 return 198+sin(z*.02)*7

static func lake_distance(p: Vector2) -> float:
 return ((p-LAKE)/LAKE_SIZE).length()

static func on_bridge(p: Vector2) -> bool:
 return absf(p.x-BRIDGE_X)<BRIDGE_HALF

static func safe_ground(p: Vector2) -> bool:
 return BOUNDS.has_point(p) and lake_distance(p)>1.04 and (p.y<110 or p.x<coast_x(p.y)-1) and (absf(p.y-river_z(p.x))>RIVER_HALF+.7 or on_bridge(p))
