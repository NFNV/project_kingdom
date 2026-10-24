extends RefCounted

const ORIGIN := Vector2(3200,160)
const ROADS := [.5,3.5,6.5,9.5,12.5]
const TYPES := ["garden_cottage","gable_townhouse","brick_rowhouse","bay_house","mansard_house","timber_house","hip_roof_villa","terraced_house"]
const FACADES := [Color("f1dfbf"),Color("dec8b4"),Color("c3d8cc"),Color("e5c8bf"),Color("c9d9df"),Color("eadab4"),Color("d7d6bb"),Color("ddd0d9")]
const ROOFS := [Color("7192ae"),Color("bb7853"),Color("638c7e"),Color("8b7691"),Color("8795a4"),Color("a68b67"),Color("687f9b"),Color("a96b59")]

static func iso(u: float, v: float) -> Vector2:
	return ORIGIN+Vector2((u-v)*240,(u+v)*120)

static func quad(u0: float, v0: float, u1: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([iso(u0,v0),iso(u1,v0),iso(u1,v1),iso(u0,v1)])

static func houses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in 4:
		for col in 4:
			if Vector2i(col,row) in [Vector2i(0,0),Vector2i(1,1),Vector2i(2,1),Vector2i(1,2)]:
				continue
			for local in 4:
				var du := -.52 if local%2==0 else .52
				var dv := -.52 if local<2 else .52
				var u: float = 2+col*3+du
				var v: float = 2+row*3+dv
				var kind: int = (result.size()+row*2+col*3)%TYPES.size()
				var axis := 0 if (row+col+local)%2==0 else 1
				var sign := signf(du if axis==0 else dv)
				var road: float = (.5+col*3 if sign<0 else 3.5+col*3) if axis==0 else (.5+row*3 if sign<0 else 3.5+row*3)
				result.append({"u":u,"v":v,"half_u":.26+(kind%3)*.025,"half_v":.27+((kind+1)%3)*.025,"kind":kind,"style":TYPES[kind],"floors":1 if kind==0 else (3 if kind in [2,4] else 2),"roof_axis":kind%2,"roof_type":"hip" if kind in [4,6] else "gable","facade":FACADES[(kind+row+col)%8],"roof":ROOFS[(kind+col)%8],"front_axis":axis,"front_sign":sign,"road":road,"shutters":kind%3!=1,"balcony":kind in [1,3,4,7],"awning":kind in [3,5],"chimney":kind%3!=0})
	return result

static func door_uv(house: Dictionary) -> Vector2:
	var point := Vector2(house.u,house.v)
	point[house.front_axis] += house.front_sign*(house.half_u if house.front_axis==0 else house.half_v)
	return point

static func sidewalk_uv(house: Dictionary) -> Vector2:
	var point := door_uv(house)
	point[house.front_axis] = house.road-house.front_sign*.52
	return point

static func doorstep(house: Dictionary) -> Vector2:
	var point := door_uv(house)
	point[house.front_axis] += house.front_sign*.16
	return iso(point.x,point.y)

static func civic_and_shops() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in [["community_hall",2.0,2.0,.65,4],["bakery",4.5,7.8,.32,3],["bookshop",5.5,7.8,.32,5],["grocer_shop",5.2,8.5,.32,7]]:
		var house: Dictionary = houses()[0].duplicate(true)
		house.u = spec[1]
		house.v = spec[2]
		house.half_u = spec[3]
		house.half_v = spec[3]
		house.kind = spec[4]
		house.style = spec[0]
		house.floors = 2
		house.roof_type = "hip" if spec[0]=="community_hall" else "gable"
		house.roof_axis = spec[4]%2
		house.facade = FACADES[spec[4]]
		house.roof = ROOFS[spec[4]]
		house.awning = spec[0]!="community_hall"
		house.balcony = spec[0]=="bookshop"
		house.civic = spec[0]=="community_hall"
		var closest := INF
		for axis in 2:
			var at: float = house.u if axis==0 else house.v
			for road in ROADS:
				if absf(road-at)<closest:
					closest = absf(road-at)
					house.front_axis = axis
					house.front_sign = signf(road-at)
					house.road = road
		result.append(house)
	return result
