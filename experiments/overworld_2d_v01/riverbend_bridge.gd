extends RefCounted

const Map := preload("res://experiments/overworld_2d_v01/layout.gd")
const DECK := preload("res://experiments/overworld_2d_v01/art/region/riverbend_stone_deck.png")
const ELEVATION := preload("res://experiments/overworld_2d_v01/art/region/riverbend_stone_elevation.png")
enum Layer { DECK_AND_ARCH, PARAPETS }
const SECTION_COUNT := 12
const RISE := 2.05
const WALL_HALF := .30
# In the side painting the continuous sill marks the level of the paving.
const SILL_Y := 404.0
const ART_TOP := 225.0
const ART_BOTTOM := 835.0
const CAP_Y := 269.0
const END_CAP_Y := 236.0
const ART_HEIGHT_SCALE := .009

static func pieces() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in SECTION_COUNT:
		var start := float(i)/SECTION_COUNT
		var finish := float(i+1)/SECTION_COUNT
		var center := Map.bridge_center()
		center.y += z_offset((start+finish)*.5)
		result.append({"p":center,"kind":"bridge_section","height":6.0,"start":start,"finish":finish})
	return result

static func z_offset(t: float) -> float:
	return lerpf(-Map.BRIDGE_HALF_LENGTH,Map.BRIDGE_HALF_LENGTH,t)

static func deck_height(p: Vector2) -> float:
	if not Map.on_bridge(p): return 0.0
	var from_center := absf(p.y-Map.bridge_center().y)/Map.BRIDGE_HALF_LENGTH
	return RISE*(1.0-from_center*from_center)

static func draw_piece(world: Node2D, canvas: CanvasItem, piece: Dictionary, shade: Color, layer: Layer) -> void:
	var start: float = piece.start
	var finish: float = piece.finish
	var center := Map.bridge_center()
	var a := center+Vector2(0,z_offset(start))
	var b := center+Vector2(0,z_offset(finish))
	var ha := deck_height(a)
	var hb := deck_height(b)
	var deck_edge := Vector2(Map.BRIDGE_HALF,0)
	if layer==Layer.DECK_AND_ARCH:
		for side in [-1.0,1.0]:
			if side*(world.camera_ground.x-center.x)>Map.BRIDGE_HALF:
				var edge: Vector2 = side*deck_edge
				var uv := elevation_uv(start,finish,SILL_Y,ART_BOTTOM)
				draw_quad(canvas,ELEVATION,[
					world.project(a+edge,ha),world.project(b+edge,hb),
					world.project(b+edge,-.06),world.project(a+edge,-.06)
				],uv,shade*Color(.83,.84,.81))
		draw_quad(canvas,DECK,[
			world.project(a-deck_edge,ha),world.project(a+deck_edge,ha),
			world.project(b+deck_edge,hb),world.project(b-deck_edge,hb)
		],Rect2(0,start,1,finish-start),shade)
		return
	for side in [-1.0,1.0]:
		var wall_x: float = center.x+side*Map.BRIDGE_RAIL_X
		var front := Vector2(wall_x,a.y)
		var back := Vector2(wall_x,b.y)
		var half_width := Vector2(WALL_HALF,0)
		var facing := half_width if world.camera_ground.x>wall_x else -half_width
		var top := art_height(ART_TOP)
		draw_quad(canvas,ELEVATION,[
			world.project(front+facing,ha+top),world.project(back+facing,hb+top),
			world.project(back+facing,hb),world.project(front+facing,ha)
		],elevation_uv(start,finish,ART_TOP,SILL_Y),shade*Color(.93,.94,.92))
		# The narrow top and entrance end close the thickness of each painted wall.
		var near_end := is_zero_approx(start)
		var coping := art_height(END_CAP_Y if near_end or is_equal_approx(finish,1.0) else CAP_Y)
		draw_quad(canvas,DECK,[
			world.project(front-half_width,ha+coping),world.project(front+half_width,ha+coping),
			world.project(back+half_width,hb+coping),world.project(back-half_width,hb+coping)
		],Rect2(.09,start,.10,finish-start),shade)
		if near_end:
			draw_quad(canvas,DECK,[
				world.project(front-half_width,ha+coping),world.project(front+half_width,ha+coping),
				world.project(front+half_width,ha),world.project(front-half_width,ha)
			],Rect2(.12,.26,.07,.10),shade*Color(.83,.82,.78))

static func art_height(pixel_y: float) -> float:
	return (SILL_Y-pixel_y)*ART_HEIGHT_SCALE

static func elevation_uv(start: float, finish: float, top: float, bottom: float) -> Rect2:
	var image_height := ELEVATION.get_height()
	return Rect2(start,top/image_height,finish-start,(bottom-top)/image_height)

static func draw_quad(canvas: CanvasItem, texture: Texture2D, points: PackedVector2Array, uv: Rect2, tint: Color) -> void:
	var corners := PackedVector2Array([
		uv.position,Vector2(uv.end.x,uv.position.y),uv.end,Vector2(uv.position.x,uv.end.y)
	])
	canvas.draw_polygon(points,PackedColorArray([tint]),corners,texture)
