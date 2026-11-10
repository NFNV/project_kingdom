@tool
extends Node2D

const Map := preload("res://experiments/overworld_2d_v01/layout.gd")
const MASK_BOUNDS := Rect2(89,187,119,211)
const PIXELS_PER_UNIT := 3

var routes: Array[Dictionary] = []
var squares: Array[PackedVector2Array] = []
var clearings: Array[PackedVector2Array] = []
var props: Array[Dictionary] = []
var mask: Image

static func world_point(point: Vector2) -> Vector2:
	return Vector2(point.x,-point.y)

func bake() -> void:
	routes.clear()
	squares.clear()
	clearings.clear()
	props.clear()
	for route in $Roads.get_children():
		if route.curve==null:
			continue
		var points := PackedVector2Array()
		for point in route.curve.get_baked_points():
			points.append(world_point(to_local(route.to_global(point))))
		if points.size()>1:
			routes.append({"points":points,"width":route.width,"surface":route.surface})
	for square in $Squares.get_children():
		squares.append(world_polygon(square))
	for clearing in $Clearings.get_children():
		clearings.append(world_polygon(clearing))
	for prop in $Scenery.get_children():
		props.append({"kind":prop.kind,"at":world_point(to_local(prop.global_position)),"height":prop.height,"radius":prop.radius})
	var size := Vector2i(MASK_BOUNDS.size*PIXELS_PER_UNIT)
	mask = Image.create_empty(size.x,size.y,false,Image.FORMAT_RGB8)
	for route in routes:
		for i in range(1,route.points.size()):
			stamp_segment(route.points[i-1],route.points[i],route.width*.5,route.surface)
	for square in squares:
		stamp_square(square)

func world_polygon(node: Polygon2D) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in node.polygon:
		points.append(world_point(to_local(node.to_global(point))))
	return points

func mask_area(bounds: Rect2) -> Rect2i:
	var start := ((bounds.position-MASK_BOUNDS.position)*PIXELS_PER_UNIT).floor()
	var finish := ((bounds.end-MASK_BOUNDS.position)*PIXELS_PER_UNIT).ceil()
	return Rect2i(Vector2i(start),Vector2i(finish-start)).intersection(Rect2i(Vector2i.ZERO,mask.get_size()))

func stamp_segment(a: Vector2, b: Vector2, radius: float, channel: int) -> void:
	if a.is_equal_approx(b):
		return
	var area := mask_area(Rect2(a,Vector2.ZERO).expand(b).grow(radius+1))
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var at := MASK_BOUNDS.position+(Vector2(x,y)+Vector2(.5,.5))/PIXELS_PER_UNIT
			var weight := 1.0-smoothstep(radius-.55,radius+.75,Map.segment_distance(at,a,b))
			if weight>0:
				var color := mask.get_pixel(x,y)
				color[channel] = maxf(color[channel],weight)
				mask.set_pixel(x,y,color)

func stamp_square(square: PackedVector2Array) -> void:
	if square.size()<3:
		return
	var bounds := Rect2(square[0],Vector2.ZERO)
	for point in square:
		bounds = bounds.expand(point)
	var area := mask_area(bounds)
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var at := MASK_BOUNDS.position+(Vector2(x,y)+Vector2(.5,.5))/PIXELS_PER_UNIT
			if Geometry2D.is_point_in_polygon(at,square):
				var color := mask.get_pixel(x,y)
				color.b = 1
				mask.set_pixel(x,y,color)

func surface_at(at: Vector2) -> Color:
	if not MASK_BOUNDS.has_point(at):
		return Color.BLACK
	return mask.get_pixelv(Vector2i((at-MASK_BOUNDS.position)*PIXELS_PER_UNIT))

func reserved(at: Vector2) -> bool:
	for clearing in clearings:
		if Geometry2D.is_point_in_polygon(at,clearing):
			return true
	var surface := surface_at(at)
	return maxf(surface.r,maxf(surface.g,surface.b))>.1

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var land := Rect2(MASK_BOUNDS.position.x,-MASK_BOUNDS.end.y,MASK_BOUNDS.size.x,MASK_BOUNDS.size.y)
	draw_rect(land,Color("61734a"))
	var sea := PackedVector2Array([Vector2(land.end.x,land.position.y),land.end])
	for y in range(roundi(MASK_BOUNDS.position.y),roundi(MASK_BOUNDS.end.y)+1,2):
		sea.append(Vector2(Map.coast_x(y),-y))
	draw_colored_polygon(sea,Color("437d87"))
	draw_set_transform(world_point(Map.LAKE),0,Map.LAKE_SIZE)
	draw_circle(Vector2.ZERO,1,Color("62928d"))
	draw_set_transform(Vector2.ZERO)
	var font := ThemeDB.fallback_font
	for landmark in [[Map.LAKESIDE,"Willowmere"],[Map.LIGHTHOUSE,"Lighthouse"]]:
		var at := world_point(landmark[0])
		draw_circle(at,.8,Color("f9d9a4"),true,-1,true)
		draw_set_transform(at+Vector2(2,-2),0,Vector2(.29,.29))
		draw_string(font,Vector2.ZERO,landmark[1],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("fff0ce"))
	draw_set_transform(Vector2.ZERO)
