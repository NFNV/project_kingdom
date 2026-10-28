extends RefCounted

const Wilds := preload("res://experiments/anime_hub_demo_v07/tools/deep_forest.gd")
const District := preload("res://experiments/anime_hub_demo_v07/tools/northgate_district.gd")
const NAMES := {"town":"Garden Square","trail":"Mosswood Trail","river":"Riverbend Glade","bakery":"The Bluebird Bakery","wilds":"Briarwood Wilds","district":"Northgate Quarter","forge":"Emberforge Workshop"}
const SOURCE_SIZE := Vector2(1672,941)


static func point(x: float, y: float) -> Vector2:
	return Vector2(x,y)*Vector2(1920,1080)/SOURCE_SIZE


static func polygon(coords: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for xy in coords:
		result.append(point(xy[0],xy[1]))
	return result


static func world_size(zone: String) -> Vector2i:
	return District.SIZE if zone=="district" else (Wilds.SIZE if zone=="wilds" else Vector2i(1920,1080))


static func floor_for(zone: String) -> PackedVector2Array:
	if zone=="district":
		return District.floor_polygon()
	if zone=="wilds":
		return Wilds.floor_polygon()
	if zone=="trail":
		# Traced against the actual forest painting, in source-image coordinates.
		return polygon([[65,425],[270,415],[355,347],[402,275],[560,202],[745,108],[795,124],[690,220],[525,312],[473,407],[580,448],[650,384],[780,362],[1030,351],[1160,389],[1200,432],[1210,343],[1320,228],[1410,195],[1455,226],[1340,330],[1272,425],[1320,505],[1395,605],[1405,680],[1460,740],[1560,835],[1635,938],[1500,938],[1445,850],[1350,780],[1270,740],[1100,780],[850,780],[690,740],[570,690],[450,610],[350,555],[260,515],[65,486]])
	return polygon([[65,450],[185,520],[330,585],[460,548],[545,466],[645,420],[715,371],[780,329],[795,281],[1010,160],[1020,130],[1100,105],[1200,40],[1250,5],[1350,5],[1300,100],[1230,150],[1160,185],[1140,206],[960,325],[930,338],[850,380],[900,420],[1030,447],[1130,500],[1260,535],[1390,570],[1450,625],[1400,700],[1320,750],[1200,817],[1070,860],[990,840],[950,790],[820,775],[690,737],[590,730],[460,730],[330,720],[230,675],[115,600],[50,545]])


static func exits_for(zone: String) -> Dictionary:
	if zone=="district":
		return {"south":{"at":District.RETURN,"to":"town","entry":"north","sign":"Garden Square","label":"Southern avenue  →  Garden Square"},"forge":{"at":District.forge_door(),"to":"forge","entry":"district","sign":"Emberforge","label":"Enter Emberforge Workshop","automatic":false}}
	if zone=="forge":
		return {"district":{"at":Vector2(960,817),"to":"district","entry":"forge","sign":"Northgate","label":"Front door  →  Northgate Market Lane"}}
	if zone=="town":
		return {"southwest":{"at":Vector2(490,1010),"to":"overworld","entry":"town","sign":"The Greenshire","label":"Southwest road  →  The Greenshire overworld"},"north":{"at":Vector2(790,490),"to":"district","entry":"town","sign":"Northgate","label":"North passage  →  Northgate Quarter"},"bakery":{"at":Vector2(320,580),"to":"bakery","entry":"town","sign":"Bluebird Bakery","label":"Blue awning  →  Enter bakery"},"southeast":{"at":Vector2(1380,966),"to":"trail","entry":"town","sign":"Mosswood","label":"Southeast gate  →  Mosswood Trail"}}
	if zone=="bakery":
		return {"town":{"at":Vector2(960,817),"to":"town","entry":"bakery","sign":"Garden Square","label":"Front door  →  Garden Square"}}
	if zone=="trail":
		return {
			"town":{"at":point(150,461),"to":"town","entry":"forest","sign":"Garden Square","label":"West path  →  Garden Square"},
			"river":{"at":point(1530,872),"to":"river","entry":"trail","sign":"Riverbend","label":"Southeast trail  →  Riverbend Glade"}
		}
	if zone=="wilds":
		return {"river":{"at":Vector2(250,1900),"to":"river","entry":"wilds","sign":"Riverbend","label":"West trail  →  Riverbend Glade"}}
	return {"trail":{"at":point(145,552),"to":"trail","entry":"river","sign":"Mosswood","label":"West path  →  Mosswood Trail"},"wilds":{"at":point(1250,95),"to":"wilds","entry":"river","sign":"Briarwood Wilds","label":"Beyond the bridge  →  Briarwood Wilds"}}


static func arrival(zone: String, entry: String) -> Vector2:
	if zone=="district":
		return District.forge_door()+Vector2(36,18) if entry=="forge" else District.ENTRY
	if zone=="wilds":
		return Wilds.ENTRY
	if zone in ["bakery","forge"]:
		return Vector2(960,745)
	if zone=="town":
		if entry=="overworld":
			return Vector2(580,980)
		if entry=="north":
			return Vector2(850,555)
		if entry=="bakery":
			return Vector2(390,695)
		return Vector2(1290,936) if entry=="forest" else Vector2(840,905)
	if zone=="trail":
		return point(1430,811) if entry=="river" else point(270,469)
	return point(1170,125) if entry=="wilds" else point(280,615)


static func landmarks(zone: String) -> Dictionary:
	if zone=="trail":
		return {
			"old_elm":{"at":point(900,410),"name":"The old elm","height":15.0,"memory":"The old elm hums with bees. For a moment, the whole forest seems to breathe with the breeze."},
			"meadow":{"at":point(1020,710),"name":"Wildflower meadow","height":12.0,"memory":"White petals catch the light beside the path. You tuck the quiet of this place into your journal."}
		}
	return {"river_view":{"at":point(820,354),"name":"Riverbend footbridge","height":15.0,"memory":"Water slips beneath the timber bridge. Beyond the reeds, a small waterfall answers the birds."}}
