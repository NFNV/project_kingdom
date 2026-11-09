extends RefCounted

const ART := "res://experiments/anime_hub_demo_v07/assets/lighthouse/"
const COAST := "palestone_coast"
const KEEPER := "lighthouse_keeper"
const LANTERN := "lighthouse_lantern"
const ZONES := [COAST, KEEPER, LANTERN]
const COAST_SIZE := Vector2i(1920,1080)
const ROOM_SIZE := Vector2i(1280,720)
const SOURCE_SIZE := Vector2(1672,941)
const KEEPER_ID := "iona"
const BEACON_ID := "beacon_control"
const GLOW := preload(ART+"beacon_glow.png")
const LANTERN_TINTS := [Color("ffe4cc"),Color("fff1db"),Color("e6bfb9"),Color("c6c4d2")]


static func size_for(zone: String) -> Vector2i:
	return COAST_SIZE if zone==COAST else ROOM_SIZE


static func point(zone: String, x: float, y: float) -> Vector2:
	return Vector2(x,y)*Vector2(size_for(zone))/SOURCE_SIZE


static func polygon(zone: String, outline: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for at in outline:
		result.append(point(zone,at[0],at[1]))
	return result


static func files_for(zone: String) -> Array[String]:
	match zone:
		COAST: return [ART+"palestone_approach_day.png",ART+"palestone_approach_night.png"]
		KEEPER: return [ART+"keeper_room.png",ART+"keeper_room_night.png"]
		_: return [ART+"lantern_room_dawn.png",ART+"lantern_room.png",ART+"lantern_room_dusk.png",ART+"lantern_room_night.png"]


static func floor_for(zone: String) -> PackedVector2Array:
	match zone:
		COAST:
			return polygon(zone,[[97,590],[242,547],[434,552],[646,571],[669,548],[776,548],[805,576],[1000,565],[1180,506],[1248,453],[1294,424],[1455,442],[1450,502],[1399,534],[1368,617],[1450,691],[1454,757],[1280,810],[1060,856],[848,871],[845,937],[585,937],[584,876],[425,827],[263,765],[155,688]])
		KEEPER:
			return polygon(zone,[[245,475],[714,466],[738,414],[1034,413],[1322,473],[1364,543],[1510,568],[1461,595],[1320,675],[1280,717],[1049,729],[1003,750],[991,847],[652,847],[636,750],[541,727],[249,710],[233,652]])
		_:
			return polygon(zone,[[462,507],[605,453],[652,479],[674,545],[998,545],[1050,483],[1054,451],[1220,485],[1330,571],[1374,650],[1288,703],[1084,728],[1012,749],[994,842],[660,842],[642,749],[534,724],[385,689],[475,635]])


static func exits_for(zone: String) -> Dictionary:
	match zone:
		COAST:
			return {
				KEEPER: {"at":point(zone,728,573),"to":KEEPER,"entry":COAST,"sign":"Keeper's workshop","label":"Enter the lighthouse","automatic":false},
				"overworld": {"at":point(zone,729,905),"to":"overworld","entry":COAST,"sign":"The Greenshire","label":"Coast road → The Greenshire"}}
		KEEPER:
			return {
				LANTERN: {"at":point(zone,1438,565),"to":LANTERN,"entry":KEEPER,"sign":"Lantern room","label":"Climb the stairs","automatic":false},
				COAST: {"at":point(zone,822,810),"to":COAST,"entry":KEEPER,"sign":"Palestone Coast","label":"Workshop door → Palestone Coast","automatic":false}}
		_:
			return {
				KEEPER: {"at":point(zone,833,807),"to":KEEPER,"entry":LANTERN,"sign":"Keeper's workshop","label":"Go downstairs","automatic":false}}


static func arrival(zone: String, entry: String) -> Vector2:
	match zone:
		COAST: return point(zone,727,640) if entry==KEEPER else point(zone,729,828)
		KEEPER: return point(zone,1328,573) if entry==LANTERN else point(zone,822,703)
		_: return point(zone,833,719)


static func build(hub: Node2D) -> Sprite2D:
	var zone: String = hub.zone
	hub._solid(hub.FLOOR,true)
	if zone==KEEPER:
		hub._resident(KEEPER_ID,"Iona · Lighthouse keeper","cat_elder",point(zone,781,461),100.0)
		var keeper: Dictionary = hub.interactables[KEEPER_ID]
		keeper.at = point(zone,781,509)
		keeper.anchor.face_towards(keeper.at)
	elif zone==LANTERN:
		hub.interactables[BEACON_ID] = {"name":"Beacon controls","at":point(zone,843,572),"height":66.0}
	else:
		hub.interactables["coast_lookout"] = {"name":"Cliffside lookout","at":point(zone,1300,470),"height":28.0}
	if zone==KEEPER:
		return null
	var glow := Sprite2D.new()
	glow.texture = GLOW
	glow.position = point(zone,614,153) if zone==COAST else point(zone,845,273)
	glow.scale = Vector2.ONE*(.27 if zone==COAST else .33)
	glow.z_index = -6
	var light := CanvasItemMaterial.new()
	light.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = light
	hub.zone_root.add_child(glow)
	return glow
