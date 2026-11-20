@tool
extends Node2D

const Map := preload("res://experiments/overworld_2d_v01/layout.gd")
const MASK_BOUNDS := Rect2(89,187,119,211)
const PIXELS_PER_UNIT := 3

@export var show_district_background := true
var routes: Array[Dictionary] = []
var squares: Array[PackedVector2Array] = []
var clearings: Array[PackedVector2Array] = []
var props: Array[Dictionary] = []
var mask: Image
var mask_bounds := MASK_BOUNDS
var pixels_per_unit := PIXELS_PER_UNIT

static func world_point(point: Vector2) -> Vector2:
	return Vector2(point.x,-point.y)

func bake() -> void:
	clear_layout()
	collect_layout(self)
	bake_surfaces(MASK_BOUNDS,PIXELS_PER_UNIT)

func clear_layout() -> void:
	routes.clear()
	squares.clear()
	clearings.clear()
	props.clear()

func collect_layout(district: Node2D) -> void:
	for route in district.get_node("Roads").get_children():
		if not route is Path2D or route.curve==null:
			continue
		var points := PackedVector2Array()
		for point in route.curve.get_baked_points():
			points.append(world_point(to_local(route.to_global(point))))
		if points.size()>1:
			var width: float = route.width if "width" in route else 8.0
			var surface: int = route.surface if "surface" in route else 0
			routes.append({"name":route.name,"points":points,"width":width,"surface":surface})
	for square in district.get_node("Squares").get_children():
		if square is Polygon2D:
			squares.append(world_polygon(square))
	for clearing in district.get_node("Clearings").get_children():
		if clearing is Polygon2D:
			clearings.append(world_polygon(clearing))
	collect_props(district.get_node("Scenery"),props)

func collect_props(folder: Node, into: Array[Dictionary]) -> void:
	for node in folder.get_children():
		if node is Marker2D and "kind" in node:
			into.append({"kind":node.kind,"at":world_point(to_local(node.global_position)),"height":node.height,"radius":node.radius,"tint":node.modulate})
		else:
			collect_props(node,into)

func bake_surfaces(bounds: Rect2, resolution: int) -> void:
	mask_bounds = bounds
	pixels_per_unit = resolution
	var size := Vector2i(bounds.size*resolution)
	mask = Image.create_empty(size.x,size.y,false,Image.FORMAT_RGBA8)
	mask.fill(Color(0,0,0,0))
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
	var start := ((bounds.position-mask_bounds.position)*pixels_per_unit).floor()
	var finish := ((bounds.end-mask_bounds.position)*pixels_per_unit).ceil()
	return Rect2i(Vector2i(start),Vector2i(finish-start)).intersection(Rect2i(Vector2i.ZERO,mask.get_size()))

func stamp_segment(a: Vector2, b: Vector2, radius: float, channel: int) -> void:
	if a.is_equal_approx(b):
		return
	var area := mask_area(Rect2(a,Vector2.ZERO).expand(b).grow(radius+1))
	var inner_edge := radius-(.8 if channel==3 else .55)
	var outer_edge := radius+(.8 if channel==3 else .75)
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var at := mask_bounds.position+(Vector2(x,y)+Vector2(.5,.5))/pixels_per_unit
			var weight := 1.0-smoothstep(inner_edge,outer_edge,Map.segment_distance(at,a,b))
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
			var at := mask_bounds.position+(Vector2(x,y)+Vector2(.5,.5))/pixels_per_unit
			if Geometry2D.is_point_in_polygon(at,square):
				var color := mask.get_pixel(x,y)
				color.b = 1
				mask.set_pixel(x,y,color)

func surface_at(at: Vector2) -> Color:
	if not mask_bounds.has_point(at):
		return Color(0,0,0,0)
	return mask.get_pixelv(Vector2i((at-mask_bounds.position)*pixels_per_unit))

func reserved(at: Vector2) -> bool:
	for clearing in clearings:
		if Geometry2D.is_point_in_polygon(at,clearing):
			return true
	var surface := surface_at(at)
	return maxf(maxf(surface.r,surface.g),maxf(surface.b,surface.a))>.1

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_district_background:
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
