extends Node2D
## Hand-authored cutaway, on the same orthographic ground plane as the bakery.
const Style := preload("res://experiments/anime_hub_demo_v07/tools/art_style.gd")
const Prop := preload("res://experiments/anime_hub_demo_v07/tools/forge_prop.gd")
var hub: Node2D
var floor_texture: Texture2D
var wall_texture: Texture2D

static func iso(u: float, v: float) -> Vector2:
	return Vector2(960,245)+Vector2((u-v)*78,(u+v)*39)

static func footprint(u: float, v: float, width: float, depth: float) -> PackedVector2Array:
	return PackedVector2Array([iso(u,v),iso(u+width,v),iso(u+width,v+depth),iso(u,v+depth)])

static func floor_polygon() -> PackedVector2Array:
	return footprint(0,0,8,8)

static func build(game: Node2D) -> Node2D:
	var room: Node2D = load("res://experiments/anime_hub_demo_v07/tools/forge_room.gd").new()
	room.hub = game
	room.z_index = -10
	game.zone_root.add_child(room)
	game.pieces.append(room)
	game._solid(floor_polygon(),true)
	var furniture := [
		["counter",3.0,2.7,2.8,.8], ["hearth",5.7,.35,1.5,1.25],
		["anvil",1.8,4.4,.9,.7], ["rack",.25,2.5,.55,2.1],
		["crate",.7,6.0,.9,.85], ["bench",5.9,4.6,1.3,.65]]
	for spec in furniture:
		var piece := Prop.new()
		piece.hub = game
		piece.kind = spec[0]
		piece.span = Vector2(spec[3],spec[4])
		piece.position = iso(spec[1]+spec[3]*.5,spec[2]+spec[4]*.5)
		game.world.add_child(piece)
		game.pieces.append(piece)
		game._solid(footprint(spec[1],spec[2],spec[3],spec[4]))
	game._human_resident("forge_smith","Tomas · Master smith","human_smith",iso(4.45,1.85),"sw")
	game.interactables.forge_smith.at = iso(4.3,4.15)
	return room

func _ready() -> void:
	floor_texture = Style.texture_for("paving")
	wall_texture = Style.texture_for("brick")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _draw() -> void:
	draw_rect(Rect2(0,0,1920,1080),Color("273635"))
	var floor_points := floor_polygon()
	draw_polygon(floor_points,PackedColorArray([Color("b9b59b")]),PackedVector2Array([Vector2.ZERO,Vector2(3,0),Vector2(3,3),Vector2(0,3)]),floor_texture)
	for edge in [[iso(0,8),iso(0,0)],[iso(0,0),iso(8,0)]]:
		var wall := PackedVector2Array([edge[0],edge[1],edge[1]-Vector2(0,230),edge[0]-Vector2(0,230)])
		draw_polygon(wall,PackedColorArray([Color("d9b997")]),PackedVector2Array([Vector2(0,2),Vector2(3,2),Vector2(3,0),Vector2.ZERO]),wall_texture)
		draw_line(edge[0],edge[1],Color("574e3e"),8,true)
		draw_line(edge[0]-Vector2(0,230),edge[1]-Vector2(0,230),Color("63553d"),13,true)
		for i in [0,1,2,3,4]:
			var at: Vector2 = edge[0].lerp(edge[1],i/4.0)
			draw_line(at,at-Vector2(0,230),Color("786142"),9,true)
	# Inset window on the quiet west wall and a hanging enamel forge sign.
	var a := iso(0,5.2)-Vector2(0,205)
	var b := iso(0,6.7)-Vector2(0,205)
	draw_polygon(PackedVector2Array([a,b,b+Vector2(0,125),a+Vector2(0,125)]),PackedColorArray([Color("c7d9cb")]),PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]),Style.texture_for("casement"))
	var plaque := iso(2.9,0)-Vector2(0,155)
	draw_circle(plaque,40,Color("345a53"))
	draw_arc(plaque,39,0,TAU,48,Color("c7a469"),3,true)
	draw_line(plaque+Vector2(-12,20),plaque+Vector2(11,-17),Color("c0a579"),7,true)
	draw_line(plaque+Vector2(-3,-21),plaque+Vector2(24,-6),Color("ddd7b4"),12,true)
	for u in [1.0,4.5,7.7]:
		var lamp := iso(u,0)-Vector2(0,155)
		draw_line(lamp-Vector2(0,66),lamp,Color("504c3c"),2,true)
		draw_circle(lamp,22,Color(1,.71,.3,.08))
		draw_circle(lamp,10,Color("ffe1a0"))
	# Entry rug and stone edging share the collision plane exactly.
	var rug := footprint(5.6,5.6,1.8,1.8)
	draw_colored_polygon(rug,Color("5e7562"))
	draw_polyline(PackedVector2Array([rug[0],rug[1],rug[2],rug[3],rug[0]]),Color("c4aa72"),3,true)
	for edge in [[iso(0,8),iso(8,8)],[iso(8,8),iso(8,0)]]:
		draw_line(edge[0],edge[1],Color("9e8f70"),8,true)
