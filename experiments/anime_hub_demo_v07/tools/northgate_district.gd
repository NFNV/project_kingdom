extends RefCounted

const SIZE := Vector2i(6400,3840)
const ORIGIN := Vector2(3200,160)
const ROADS := [.5,3.5,6.5,9.5,12.5]
const ENTRY := Vector2(3320,3100)
const RETURN := Vector2(3164,3178)
const PLACES := {"plaza":Vector2(3200,1530),"park":Vector2(3848,1816),"market":Vector2(2528,1936),"civic":Vector2(3200,850),"west":Vector2(1040,1720),"east":Vector2(5360,1720)}
const Layout := preload("res://experiments/anime_hub_demo_v07/tools/northgate_layout.gd")
const House := preload("res://experiments/anime_hub_demo_v07/tools/town_house.gd")
const Terrain := preload("res://experiments/anime_hub_demo_v07/tools/district_ground.gd")
const Lamps := preload("res://experiments/anime_hub_demo_v07/tools/district_lights.gd")

static func iso(u: float, v: float) -> Vector2:
	return ORIGIN+Vector2((u-v)*240,(u+v)*120)

static func quad(u0: float, v0: float, u1: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([iso(u0,v0),iso(u1,v0),iso(u1,v1),iso(u0,v1)])

static func floor_polygon() -> PackedVector2Array:
	return quad(0,0,13,13)

static func houses() -> Array[Dictionary]:
	return Layout.houses()

static func forge_door() -> Vector2:
	for house in Layout.civic_and_shops():
		if house.style=="forge":
			return Layout.doorstep(house)
	return PLACES.market

static func building(hub: Node2D, data: Dictionary) -> void:
	var anchor := House.new()
	anchor.hub = hub
	anchor.data = data
	anchor.position = iso(data.u+data.half_u,data.v+data.half_v)
	anchor.set_meta("house_data",data)
	hub.world.add_child(anchor)
	anchor.add_to_group("district_buildings")
	hub.pieces.append(anchor.facade)
	hub.occluders.append(anchor.facade)
	hub._solid(quad(data.u-data.half_u,data.v-data.half_v,data.u+data.half_u,data.v+data.half_v))

static func resident(hub: Node2D, id: String, name_text: String, art: String, u: float, v: float, text: String) -> void:
	hub._resident(id,name_text,art,iso(u,v))
	hub.interactables[id]["text"] = text

static func build(hub: Node2D) -> void:
	var terrain := Terrain.new()
	terrain.z_index = -10
	hub.zone_root.add_child(terrain)
	hub.pieces.append(terrain)
	hub._solid(floor_polygon(),true)
	for house in houses()+Layout.civic_and_shops():
		building(hub,house)
	var fountain_at := iso(5,5)+Vector2(0,30)
	hub._piece("fountain",fountain_at,235)
	hub._solid(hub._ellipse(fountain_at+Vector2(0,-25),Vector2(139,48)))
	hub.ripples = hub.FountainFX.new()
	hub.ripples.hub = hub
	hub.ripples.position = fountain_at
	hub.world.add_child(hub.ripples)
	for uv in [Vector2(4.25,5.7),Vector2(5.75,4.3),Vector2(7.55,5.55),Vector2(8.45,4.45),Vector2(2.2,1.1)]:
		var at := iso(uv.x,uv.y)
		hub._piece("bench",at,72)
		hub._solid(hub._ellipse(at+Vector2(0,-10),Vector2(48,13)))
	for uv in [Vector2(4.05,4.05),Vector2(5.95,4.05),Vector2(5.95,5.95),Vector2(4.05,5.95),Vector2(7.2,4.2),Vector2(8.8,5.8)]:
		var at := iso(uv.x,uv.y)
		hub._piece("flower_planter",at,62)
		hub._solid(hub._ellipse(at+Vector2(0,-10),Vector2(35,11)))
	for uv in [Vector2(7.45,4.45),Vector2(8.55,5.55),Vector2(8.55,4.45),Vector2(1.05,1.0),Vector2(10.0,1.0),Vector2(1.0,10.0),Vector2(11.0,11.0)]:
		var at := iso(uv.x,uv.y)
		hub._piece("elm_tree",at,280)
		hub._solid(hub._ellipse(at+Vector2(0,-6),Vector2(20,13)))
	var lamps := Lamps.new()
	lamps.hub = hub
	lamps.z_index = 2
	hub.zone_root.add_child(lamps)
	for road in [.5,3.5,6.5,9.5,12.5]:
		for t in [1.1,4.1,7.1,10.1,11.9]:
			var at := iso(road+.52,t)
			hub._piece("street_lamp",at,190)
			lamps.positions.append(at)
			at = iso(t,road-.52)
			hub._piece("street_lamp",at,190)
			lamps.positions.append(at)
	resident(hub,"north_baker","Marigold · Baker","cat_baker",4.0,7.5,"The morning loaves are still warm. Garden Square is down the southern avenue; the little park is across the boulevard.")
	resident(hub,"north_books","Juniper · Bookseller","cat_bookseller",6.0,7.3,"There are streets behind streets up here. Take a seat at Linden Park, or stroll past the old hall in the northwest quarter.")
	resident(hub,"north_grocer","Hazel · Greengrocer","dog_grocer",5.8,8.8,"Peaches, pears and herbs from the valley. This is Market Lane; the fountain plaza is just over the crossing.")
	resident(hub,"north_elder","Nell · Park regular","cat_elder",7.9,5.25,"A little patch of quiet in the middle of town. Watch the leaves for a while; they never seem to be in a hurry.")
	resident(hub,"north_courier","Rowan · Courier","dog_courier",6.5,6.0,"Forty-eight homes, three shops and a town hall on my route. I'm glad the sidewalks are wide!")
	resident(hub,"north_neighbor","Tansy · Neighbour","cat_baker",10.0,9.5,"The terracotta roofs glow at sunset. Keep south at the crossroads when you're ready to go back to Garden Square.")
	resident(hub,"north_reader","Fennel · Reader","cat_bookseller",2.4,.95,"The hall keeps the town's old maps. This northern quarter grew around its crossing streets and courtyard gardens.")
	resident(hub,"north_flowers","Poppy · Flower seller","cat_elder",4.1,5.0,"The fountain keeps our plaza cool. Every flower box up this street has a different story.")
	var neighbors := [["Basil · Neighbour","cat_bookseller",1.0,10.0],["Clover · Shopper","cat_baker",10.0,1.0],["Maple · Courier","dog_courier",4.0,12.5],["Sorrel · Resident","dog_grocer",12.0,4.0],["Olive · Neighbour","cat_elder",3.5,10.0],["Fern · Shopper","cat_baker",9.5,2.6]]
	for index in neighbors.size():
		var neighbor: Array = neighbors[index]
		resident(hub,"north_neighbor_%d" % index,neighbor[0],neighbor[1],neighbor[2],neighbor[3],"A lovely day for a walk through Northgate. The main crossings lead to the fountain plaza, Market Lane and the little park. There is always another street to explore.")
	for item in [["north_human_1","Ada · Gardener","human_herbalist",7.1,5.0],["north_human_2","Leo · Carpenter","human_smith",9.5,10.8],["north_human_3","Mira · Traveller","human_wayfarer",6.5,4.0],["north_human_4","Noah · Resident","human_warden",3.5,2.6]]:
		hub._human_resident(item[0],item[1],item[2],iso(item[3],item[4]),"sw")
		hub.interactables[item[0]]["text"] = "Welcome to Northgate! The park, plaza and Market Lane all connect through the broad sidewalks. Garden Square lies down the southern avenue."
	for i in 2:
		var dog = hub._actor(false,iso(6.5,8.0+i*2))
		dog.resident_id = "north_warden_%d" % i
		dog.patrol = PackedVector2Array([iso(6.5,8.0+i*2),iso(6.5,9.0+i*2),iso(7.2,9.5)])
		dog.patrol_wait = 1+i
		hub.dogs.append(dog)
		hub.interactables[dog.resident_id] = {"at":dog.position,"anchor":dog,"height":dog.sprite.display_height,"name":"Elm · Warden" if i==0 else "Ash · Warden","text":"All peaceful up here. The southern avenue returns to Garden Square; the plaza and little park are worth a stroll first."}
	for place in ["plaza","park","civic"]:
		hub.interactables["north_place_"+place] = {"at":PLACES[place],"height":20.0,"name":{"plaza":"Sunstone Plaza","park":"Linden Park","civic":"The Old Town Hall"}[place],"text":{"plaza":"Water sparkles above the warm stone. From here the sidewalks lead into every neighbourhood.","park":"A tiny green refuge, with benches under the elms and paths between the flowerbeds.","civic":"The old hall watches over the northern streets. Houses and shopfronts spread away from its little forecourt."}[place]}
