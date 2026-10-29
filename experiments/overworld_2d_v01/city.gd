extends RefCounted
# City layout/colliders and legacy polygon study; the active map uses illustration_prop().
const CENTER := Vector2(-47,39)
const SCALE := .38
const HEIGHT_SCALE := .5
const GATE := CENTER+Vector2(0,-13)
const CREAM := Color("e6d7ad")
const SLATE := Color("426780")

static func props() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var buildings := [
		["community_hall",Vector2(0,19),Vector2(15,8),10.0,"hall"],
		["bluebird_bakery",Vector2(-20,0),Vector2(10,7),7.5,"bakery"],
		["grocer",Vector2(20,0),Vector2(10,7),7.5,"grocer"],
		["ivy_cottage",Vector2(-17,-15),Vector2(8,6),7.0,"cottage"],
		["balcony_cottage",Vector2(17,-15),Vector2(8,6),7.0,"cottage"],
		["northgate_west",Vector2(-16,20),Vector2(8,6),8.0,"cottage"],
		["northgate_east",Vector2(16,20),Vector2(8,6),8.0,"cottage"],
		["northgate_terrace_a",Vector2(-27,13),Vector2(7,6),7.0,"cottage"],
		["northgate_terrace_b",Vector2(27,13),Vector2(7,6),7.0,"cottage"]
	]
	for b in buildings:
		var toward: Vector2 = -b[1]
		var heading := snappedf(atan2(toward.x,-toward.y),PI/2)
		result.append({"p":CENTER+b[1]*SCALE,"kind":"city_building","id":b[0],"dims":b[2]*SCALE,"wall_height":b[3]*HEIGHT_SCALE,"height":(b[3]+3.5)*HEIGHT_SCALE,"heading":heading,"style":b[4],"radius":3.5,"tint":Color.WHITE,"phase":0.0})
	result.append({"p":CENTER+Vector2(0,20)*SCALE,"kind":"city_building","id":"clock_tower","dims":Vector2(5.0,5.0)*SCALE,"wall_height":19.0*HEIGHT_SCALE,"height":23.0*HEIGHT_SCALE,"heading":0.0,"style":"tower","radius":1.8,"tint":Color.WHITE,"phase":0.0})
	result.append({"p":CENTER,"kind":"city_fountain","id":"garden_fountain","height":5.5*HEIGHT_SCALE,"radius":2.8*SCALE,"tint":Color.WHITE,"phase":0.0})
	# An enclosing silhouette makes this a whole-city overworld landmark.
	for wall in [["south_west",Vector2(-7.8,-13),Vector2(10.4,1.1),1.7],["south_east",Vector2(7.8,-13),Vector2(10.4,1.1),1.7],["north",Vector2(0,13),Vector2(26,1.1),1.7],["west",Vector2(-13,0),Vector2(1.1,26),1.7],["east",Vector2(13,0),Vector2(1.1,26),1.7],["gate_west",Vector2(-2.4,-13),Vector2(1.3,1.7),3.2],["gate_east",Vector2(2.4,-13),Vector2(1.3,1.7),3.2]]:
		result.append({"p":CENTER+wall[1],"kind":"city_building","id":wall[0],"dims":wall[2],"wall_height":wall[3],"height":wall[3]+.2,"heading":0.0,"style":"wall","radius":1.0,"tint":Color.WHITE,"phase":0.0})
	for offset in [Vector2(-10,8),Vector2(10,8),Vector2(-10,-8),Vector2(10,-8)]:
		result.append({"p":CENTER+offset,"kind":"oak","height":2.9,"radius":.65,"tint":Color.WHITE,"phase":offset.x})
	for item in result: item["city_geometry"] = true
	return result

static func illustration_prop() -> Dictionary:
	# Its painted south gate is the foot anchor, shared with the actual portal.
	return {"p":GATE,"kind":"city_illustration","height":13.0,"max_height":340.0,"max_width":520.0,"anchor_uv":Vector2(.5,.84),"tint":Color.WHITE,"phase":0.0}

static func local(item: Dictionary, p: Vector2) -> Vector2:
	return item.p+p.rotated(item.heading)

static func blocks(item: Dictionary, p: Vector2) -> bool:
	var point: Vector2 = (p-item.p).rotated(-float(item.heading))
	return absf(point.x)<item.dims.x*.5+.45 and absf(point.y)<item.dims.y*.5+.45

static func project(world: Node2D, p: Vector2, height := 0.0) -> Vector2:
	var depth: float = world.view_point(p).y
	if depth<=.5:
		return Vector2(-100000,-100000)
	# Height follows the same local surface normal as the surrounding scenery.
	return world.project(p)+Vector2.UP.rotated(world.surface_rotation(p))*world.FOCAL*height/depth

static func polygon(world: Node2D, canvas: Node2D, points: Array, color: Color, outline := true, emission := 0.0) -> void:
	var projected := PackedVector2Array()
	for point in points:
		var screen: Vector2 = project(world,point[0],point[1])
		if screen.x< -99999: return
		projected.append(screen)
	# Edge-on walls/windows can collapse to a line during a full orbit.
	if Geometry2D.triangulate_polygon(projected).is_empty():
		return
	color = (color*world.light_tint).lerp(Color("ffd28b"),emission*.9)
	canvas.draw_colored_polygon(projected,color)
	if outline:
		projected.append(projected[0])
		canvas.draw_polyline(projected,Color(color.r*.68,color.g*.68,color.b*.68,color.a),1.2,false)

static func wall_patch(world: Node2D, canvas: Node2D, a: Vector2, b: Vector2, left: float, right: float, bottom: float, top: float, color: Color, emission := 0.0) -> void:
	polygon(world,canvas,[[a.lerp(b,left),bottom],[a.lerp(b,right),bottom],[a.lerp(b,right),top],[a.lerp(b,left),top ]],color,false,emission)

static func draw_building(world: Node2D, canvas: Node2D, item: Dictionary) -> void:
	var w: float = item.dims.x*.5
	var d: float = item.dims.y*.5
	var h: float = item.wall_height
	var corners: Array[Vector2] = []
	for p in [Vector2(-w,-d),Vector2(w,-d),Vector2(w,d),Vector2(-w,d)]:
		corners.append(local(item,p))
	var normals := [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]
	for i in 4:
		var a := corners[i]
		var b := corners[(i+1)%4]
		if normals[i].rotated(item.heading).dot(world.camera_ground-(a+b)*.5)<0:
			continue
		var wall := CREAM.darkened(.12 if i in [1,2] else 0)
		polygon(world,canvas,[[a,0.0],[b,0.0],[b,h],[a,h]],wall)
		wall_patch(world,canvas,a,b,0,1,.08,.3,Color("bca983"))
		if item.style=="wall":
			wall_patch(world,canvas,a,b,0,1,h-.25,h,Color("f0dfb1"))
			for joint in range(1,maxi(2,int(a.distance_to(b)/1.5))):
				var at: Vector2 = a.lerp(b,joint/float(maxi(2,int(a.distance_to(b)/1.5))))
				canvas.draw_line(project(world,at,.3),project(world,at,h-.25),Color("bba985")*world.light_tint,.7,false)
			continue
		var window_top := h*.75
		if item.style=="tower":
			wall_patch(world,canvas,a,b,.3,.7,h*.6,h*.8,Color("547c81"))
			var center: Vector2 = project(world,(a+b)*.5,h*.84)
			var radius := maxf(3,world.FOCAL*.8*HEIGHT_SCALE/world.view_point(item.p).y)
			canvas.draw_circle(center,radius,Color("f7eac2"))
			canvas.draw_arc(center,radius,0,TAU,28,Color("997b4d"),1.5,true)
			canvas.draw_line(center,center+Vector2(0,-radius*.65),Color("52604c"),1.4,true)
			canvas.draw_line(center,center+Vector2(radius*.5,radius*.25),Color("52604c"),1.4,true)
		else:
			for pos in [.15,.7]:
				wall_patch(world,canvas,a,b,pos,pos+.15,h*.46,window_top,Color("f5e8bf"))
				wall_patch(world,canvas,a,b,pos+.025,pos+.125,h*.49,window_top-.15,Color("527d83"),world.lamp_weight)
				wall_patch(world,canvas,a,b,pos-.025,pos+.175,h*.4,h*.46,Color("739251"))
				for t in [.0,.06,.12]:
					var flower: Vector2 = project(world,a.lerp(b,pos+t),h*.45)
					canvas.draw_circle(flower,.9,Color("e5b3a5")*world.light_tint)
			if i==0:
				wall_patch(world,canvas,a,b,.41,.59,.7,h*.49,Color("8b6c45"))
				wall_patch(world,canvas,a,b,.44,.56,.75,h*.46,Color("3f6d69"))
				if item.style in ["bakery","grocer"]:
					var outside: Vector2 = normals[i].rotated(item.heading)*1.6*SCALE
					for stripe in 8:
						var t0 := .1+stripe*.1
						var t1 := t0+.1
						var awning := Color("f3e6be") if stripe%2==0 else (SLATE if item.style=="bakery" else Color("71915b"))
						polygon(world,canvas,[[a.lerp(b,t0),h*.48],[a.lerp(b,t1),h*.48],[a.lerp(b,t1)+outside,h*.37],[a.lerp(b,t0)+outside,h*.37]],awning)
	if item.style=="wall":
		polygon(world,canvas,[[corners[0],h],[corners[1],h],[corners[2],h],[corners[3],h]],Color("eadbb4"))
		return
	var front := local(item,Vector2(0,-d))
	var back := local(item,Vector2(0,d))
	var rise := (3.0 if item.style!="tower" else 4.0)*HEIGHT_SCALE
	for i in [0,2]:
		var a := corners[i]
		var b := corners[(i+1)%4]
		if normals[i].rotated(item.heading).dot(world.camera_ground-(a+b)*.5)>0:
			polygon(world,canvas,[[a,h],[b,h],[front if i==0 else back,h+rise]],CREAM)
	var roofs := [
		{"p":[[corners[0],h],[corners[3],h],[back,h+rise],[front,h+rise]],"mid":(corners[0]+corners[3])*.5,"color":SLATE.lightened(.07)},
		{"p":[[corners[1],h],[corners[2],h],[back,h+rise],[front,h+rise]],"mid":(corners[1]+corners[2])*.5,"color":SLATE.darkened(.15)}
	]
	roofs.sort_custom(func(a: Dictionary,b: Dictionary): return world.view_point(a.mid).y>world.view_point(b.mid).y)
	for roof in roofs:
		polygon(world,canvas,roof.p,roof.color)
		for t in [.25,.5,.75]:
			var c0: Vector2 = roof.p[0][0].lerp(roof.p[3][0],t)
			var c1: Vector2 = roof.p[1][0].lerp(roof.p[2][0],t)
			canvas.draw_line(project(world,c0,h+rise*t),project(world,c1,h+rise*t),Color("6f8796")*world.light_tint,.7,false)

static func draw_fountain(world: Node2D, canvas: Node2D, p: Vector2) -> void:
	for ring in [[2.8,.1,Color("b9ad8c")],[2.5,.55,Color("e3d4ab")],[2.1,.65,Color("6bb1af")],[1.0,2.0,Color("dfd3b0")],[.75,2.2,Color("78b7b0")]]:
		var points: Array = []
		for i in 32:
			points.append([p+Vector2(cos(i*TAU/32),sin(i*TAU/32))*ring[0]*SCALE,ring[1]*HEIGHT_SCALE])
		polygon(world,canvas,points,ring[2])
	var base: Vector2 = project(world,p,.6*HEIGHT_SCALE)
	var top: Vector2 = project(world,p,4.8*HEIGHT_SCALE)
	canvas.draw_line(base,top,Color("e1d8b7"),maxf(2,world.FOCAL*.2/world.view_point(p).y),true)
	for i in 7:
		var offset := Vector2(cos(i*TAU/7),sin(i*TAU/7))
		var points := PackedVector2Array()
		for step in 10:
			var t := step/9.0
			points.append(project(world,p+offset*t*1.6*SCALE,(4.7-4*t*t)*HEIGHT_SCALE))
		canvas.draw_polyline(points,Color(.85,.96,.91,.8),1.4,true)
		var t := fposmod(world.clock*.9+i*.13,1)
		canvas.draw_circle(project(world,p+offset*t*1.6*SCALE,(4.7-4*t*t)*HEIGHT_SCALE),1.8,Color("e8f5e5"))
