extends Node2D

const Map := preload("res://experiments/overworld_2d_v01/layout.gd")
const WALL := preload("res://experiments/overworld_2d_v01/art/fortifications/boundary_wall.png")
const GATE := preload("res://experiments/overworld_2d_v01/art/fortifications/boundary_gate.png")
const LATERAL_STONE := preload("res://experiments/overworld_2d_v01/art/fortifications/lateral_masonry.png")
const CAPSTONE := preload("res://experiments/overworld_2d_v01/art/fortifications/lateral_capstone.png")
const WALL_ART := Rect2(0,231,1536,592)
const COPING_ART := Rect2(0,419,1536,18)
const GATE_ART := Rect2(175,11,1186,983)
const MERLON_ART := Rect2(568,0,390,421)
const SINGLE_CAP_ART := Rect2(370,335,805,342)
const WALL_HEIGHT := 5.6
const COPING_HEIGHT := WALL_HEIGHT*.70
const WALL_TILE_WIDTH := 14.6
const MERLONS_PER_TILE := 5
const PIER_HEIGHT := 5.95
const GATE_HEIGHT := 13.0
const GATE_WIDTH := 16.0
const GATE_HALF_DEPTH := 1.5
const RIDER_CLEARANCE := .45
enum Style { FRONT, SIDE, PIER, GATEHOUSE }

var runs: Array[Dictionary] = []
var pieces: Array[Dictionary] = []

func bake(reference: Node2D) -> void:
	runs.clear()
	pieces.clear()
	var side_ends: Dictionary = {}
	for wall in $Walls.get_children():
		if not wall is Line2D:
			continue
		for i in range(1,wall.points.size()):
			var a := map_point(reference,wall,wall.points[i-1])
			var b := map_point(reference,wall,wall.points[i])
			var length := a.distance_to(b)
			if is_zero_approx(length):
				continue
			var half_depth: float = wall.width*.5
			runs.append({"a":a,"b":b,"half_depth":half_depth})
			if absf(b.y-a.y)>absf(b.x-a.x):
				add_side_wall(a,b,half_depth)
				for end in [a,b]:
					if side_ends.has(end):
						side_ends.erase(end)
					else:
						side_ends[end] = half_depth
			else:
				var count := maxi(1,roundi(length/WALL_TILE_WIDTH))
				for tile in count:
					add_piece(a.lerp(b,float(tile)/count),a.lerp(b,float(tile+1)/count),half_depth,Style.FRONT)
	for end in side_ends:
		var radius: float = side_ends[end]+.25
		var offset := Vector2(radius,0)
		add_piece(end-offset,end+offset,radius,Style.PIER)
	for gate in $Gatehouses.get_children():
		if not gate is Marker2D:
			continue
		var a := map_point(reference,gate,Vector2(-GATE_WIDTH*.5,0))
		var b := map_point(reference,gate,Vector2(GATE_WIDTH*.5,0))
		if a.is_equal_approx(b):
			continue
		runs.append({"a":a,"b":b,"half_depth":GATE_HALF_DEPTH})
		add_piece(a,b,GATE_HALF_DEPTH,Style.GATEHOUSE)

func add_side_wall(a: Vector2, b: Vector2, half_depth: float) -> void:
	# Small spans follow the curved ground and keep the stonework from stretching near the camera.
	var tile_count := maxi(1,roundi(a.distance_to(b)/WALL_TILE_WIDTH))
	var count := tile_count*MERLONS_PER_TILE
	for span in count:
		add_piece(a.lerp(b,float(span)/count),a.lerp(b,float(span+1)/count),half_depth,Style.SIDE)
		pieces.back()["section"] = span%MERLONS_PER_TILE

func map_point(reference: Node2D, node: Node2D, point: Vector2) -> Vector2:
	var local := reference.to_local(node.to_global(point))
	return Vector2(local.x,-local.y)

func add_piece(a: Vector2, b: Vector2, half_depth: float, style: Style) -> void:
	var height := WALL_HEIGHT
	match style:
		Style.GATEHOUSE: height = GATE_HEIGHT
		Style.PIER: height = PIER_HEIGHT
	pieces.append({"kind":"fortification","p":(a+b)*.5,"a":a,"b":b,"half_depth":half_depth,"style":style,"height":height})

func blocks(p: Vector2, padding := RIDER_CLEARANCE) -> bool:
	for run in runs:
		if Map.segment_distance(p,run.a,run.b)<run.half_depth+padding:
			return true
	return false

func append_visible(world: Node2D, visible: Array[Dictionary], limit: float) -> void:
	for piece in pieces:
		var center: Vector2 = piece.p
		var depth: float = world.view_point(center).y
		if depth<4.0 or depth>limit:
			continue
		var span: float = piece.a.distance_to(piece.b)
		if world.bend()>0 and center.distance_to(world.camera_ground)>limit+span*.5:
			continue
		var offset := face_offset(piece,world.camera_ground)
		var a: Vector2 = piece.a+offset
		var b: Vector2 = piece.b+offset
		if minf(world.view_point(a).y,world.view_point(b).y)<=3.0:
			continue
		var base_a: Vector2 = world.project(a)
		var base_b: Vector2 = world.project(b)
		var height: float = piece.height
		var top_a: Vector2 = world.project(a,height)
		var top_b: Vector2 = world.project(b,height)
		if maxf(base_a.x,base_b.x)<-20.0 or minf(base_a.x,base_b.x)>1940.0:
			continue
		if minf(top_a.y,top_b.y)>1080.0:
			continue
		visible.append(piece)

func face_offset(piece: Dictionary, camera: Vector2) -> Vector2:
	var axis: Vector2 = (piece.b-piece.a).normalized()
	var normal := axis.orthogonal()
	if (camera-piece.p).dot(normal)<0.0:
		normal = -normal
	return normal*float(piece.half_depth)

func draw_piece(world: Node2D, canvas: CanvasItem, piece: Dictionary, limit: float) -> void:
	var center: Vector2 = piece.p
	var offset := face_offset(piece,world.camera_ground)
	var a: Vector2 = piece.a+offset
	var b: Vector2 = piece.b+offset
	var depth: float = world.view_point(center).y
	var tint: Color = world.light_tint.lerp(world.lighting.haze,smoothstep(80.0,330.0,depth)*.7)
	if world.bend()>0:
		tint.a = 1.0-smoothstep(limit-10.0,limit,center.distance_to(world.camera_ground))
	if depth<world.CAMERA_LEAD:
		# Fade only the foreground span that covers the rider.
		var rider: Vector2 = world.project(world.player)
		var left: Vector2 = world.project(a)
		var right: Vector2 = world.project(b)
		var overlap := minf(rider.x-minf(left.x,right.x),maxf(left.x,right.x)-rider.x)
		tint.a *= lerpf(1.0,.70,smoothstep(-28.0,12.0,overlap))
		if piece.style==Style.FRONT or piece.style==Style.GATEHOUSE:
			tint.a *= smoothstep(4.0,14.0,depth)
	if tint.a<=.002:
		return
	match piece.style:
		Style.SIDE:
			draw_side_wall(world,canvas,piece,tint)
			return
		Style.PIER:
			draw_stone_box(world,canvas,piece,Vector2(0,PIER_HEIGHT),Rect2(0,0,650,1024),SINGLE_CAP_ART,tint)
			return
	var is_gate: bool = piece.style==Style.GATEHOUSE
	if not is_gate:
		var back_a: Vector2 = piece.a-offset
		var back_b: Vector2 = piece.b-offset
		draw_face(canvas,WALL,COPING_ART,[
			world.project(a,COPING_HEIGHT),world.project(b,COPING_HEIGHT),
			world.project(back_b,COPING_HEIGHT),world.project(back_a,COPING_HEIGHT)
		],tint.lightened(.10))
	var height: float = piece.height
	draw_face(canvas,GATE if is_gate else WALL,GATE_ART if is_gate else WALL_ART,[
		world.project(a,height),world.project(b,height),world.project(b),world.project(a)
	],tint)

func draw_side_wall(world: Node2D, canvas: CanvasItem, piece: Dictionary, tint: Color) -> void:
	var section: int = piece.section
	var slice := LATERAL_STONE.get_width()/float(MERLONS_PER_TILE)
	var body_art := Rect2(slice*section,0,slice,LATERAL_STONE.get_height())
	var coping_art := Rect2(slice*section,0,slice,CAPSTONE.get_height())
	draw_stone_box(world,canvas,piece,Vector2(0,COPING_HEIGHT),body_art,coping_art,tint,false)
	var a: Vector2 = piece.a
	var b: Vector2 = piece.b
	var merlon := {
		"a":a.lerp(b,.22),"b":a.lerp(b,.78),"p":piece.p,
		"half_depth":float(piece.half_depth)*.83
	}
	draw_stone_box(world,canvas,merlon,Vector2(COPING_HEIGHT,WALL_HEIGHT),MERLON_ART,SINGLE_CAP_ART,tint)

func draw_stone_box(world: Node2D, canvas: CanvasItem, piece: Dictionary, heights: Vector2, side_art: Rect2, cap_art: Rect2, tint: Color, show_end := true) -> void:
	var offset := face_offset(piece,world.camera_ground)
	var a: Vector2 = piece.a+offset
	var b: Vector2 = piece.b+offset
	var top_a: Vector2 = world.project(a,heights.y)
	var top_b: Vector2 = world.project(b,heights.y)
	var back_a: Vector2 = piece.a-offset
	var back_b: Vector2 = piece.b-offset
	draw_face(canvas,LATERAL_STONE,side_art,[
		top_a,top_b,world.project(b,heights.x),world.project(a,heights.x)
	],tint)
	if show_end:
		var axis: Vector2 = b-a
		var at_a: bool = (world.camera_ground-piece.p).dot(axis)<0.0
		var near: Vector2 = a if at_a else b
		var far: Vector2 = back_a if at_a else back_b
		draw_face(canvas,LATERAL_STONE,side_art,[
			world.project(near,heights.y),world.project(far,heights.y),
			world.project(far,heights.x),world.project(near,heights.x)
		],tint*Color(.78,.80,.81))
	draw_face(canvas,CAPSTONE,cap_art,[
		top_a,top_b,world.project(back_b,heights.y),world.project(back_a,heights.y)
	],tint.lightened(.09))

func draw_face(canvas: CanvasItem, texture: Texture2D, art: Rect2, points: PackedVector2Array, tint: Color) -> void:
	if Geometry2D.triangulate_polygon(points).is_empty():
		return
	var top_left := art.position/texture.get_size()
	var bottom_right := art.end/texture.get_size()
	var uv := PackedVector2Array([
		top_left,Vector2(bottom_right.x,top_left.y),bottom_right,Vector2(top_left.x,bottom_right.y)
	])
	canvas.draw_polygon(points,PackedColorArray([tint]),uv,texture)
