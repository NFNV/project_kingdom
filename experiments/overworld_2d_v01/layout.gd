extends RefCounted
# Shared by terrain, navigation, the map and scenery placement.
const BOUNDS := Rect2(-240,-80,480,560)
const START := Vector2(0,0)
const TOWN := Vector2(-47,39)
const MOONLIGHT := Vector2(-50,385)
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
const BRIDGE_HALF_LENGTH := 7.6
const BRIDGE_RAIL_X := BRIDGE_HALF-.30

static func landmarks(bridge_x := BRIDGE_X) -> Array[Dictionary]:
 var crossing := bridge_center(bridge_x)
 return [
  {"p":START,"name":"SUNLIT MEADOW","short":"Meadow","description":"Follow the north road to Mosswood and Riverbend Crossing."},
  {"p":crossing-Vector2(0,14),"location":crossing,"name":"RIVERBEND CROSSING","short":"Bridge","description":"The stone bridge is the safe passage to the northern routes."},
  {"p":FOREST,"name":"BRIARWOOD FOREST","short":"Briarwood","description":"Deep fir groves frame a fork toward the lake and old ruins."},
  {"p":TOWN+Vector2(15,-25),"location":TOWN,"name":"MOSSWOOD","short":"Mosswood","description":"Clock Hall, Garden Square and the market nestle inside the town walls."},
  {"p":WINDMILL+Vector2(10,-15),"location":WINDMILL,"name":"WINDSONG RIDGE","short":"Windmill","description":"A cream-stone mill and a tiny market hamlet watch over the western meadows."},
  {"p":LAKESIDE,"name":"WILLOWMERE LAKE","short":"Willowmere","description":"Follow the shore path south or continue north toward the coast."},
  {"p":RUINS+Vector2(10,-16),"location":RUINS,"name":"IVYKEEP RUINS","short":"Ivykeep","description":"An ivy-covered arch is all that remains of the old watch keep."},
  {"p":COAST,"name":"PALESTONE COAST","short":"Coast","description":"A little lighthouse watches over the pale rocks and open sea."},
  {"p":MOONLIGHT,"name":"MOONLIGHT FOREST","short":"Moonlight","description":"A silver woodland trail leads to a ruined castle and the Undercroft. F to enter on foot."}
 ]

static func segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
 var line := b-a
 return p.distance_to(a+line*clampf((p-a).dot(line)/line.length_squared(),0,1))

static func river_z(x: float) -> float:
 return RIVER_Z+sin(x*RIVER_RATE)*RIVER_WAVE

static func road_x(z: float) -> float:
 return sin(z*.016)*18

static func coast_x(z: float) -> float:
 return 198+sin(z*.02)*7

static func lake_distance(p: Vector2) -> float:
 return ((p-LAKE)/LAKE_SIZE).length()

static func bridge_center(x := BRIDGE_X) -> Vector2:
 x = clampf(x,BOUNDS.position.x+BRIDGE_HALF+1,BOUNDS.end.x-BRIDGE_HALF-1)
 return Vector2(x,river_z(x))

static func on_bridge(p: Vector2, bridge_x := BRIDGE_X) -> bool:
 var offset := (p-bridge_center(bridge_x)).abs()
 return offset.x<BRIDGE_HALF and offset.y<BRIDGE_HALF_LENGTH

static func bridge_rail_blocks(p: Vector2, bridge_x := BRIDGE_X) -> bool:
 var offset := (p-bridge_center(bridge_x)).abs()
 return absf(offset.x-BRIDGE_RAIL_X)<.40 and offset.y<BRIDGE_HALF_LENGTH

static func safe_ground(p: Vector2, bridge_x := BRIDGE_X) -> bool:
 return BOUNDS.has_point(p) and lake_distance(p)>1.04 and (p.y<110 or p.x<coast_x(p.y)-1) and (absf(p.y-river_z(p.x))>RIVER_HALF+.7 or on_bridge(p,bridge_x))
