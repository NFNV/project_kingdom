extends Node2D

# Authored room geometry and furnishing coordinates; orthographic 2:1 ground plane.
const ASSETS := "res://experiments/anime_hub_demo_v07/assets/bakery/"
var hub: Node2D
var floor_texture: Texture2D


static func iso(u: float, v: float) -> Vector2:
	return Vector2(960,245)+Vector2((u-v)*78,(u+v)*39)


static func footprint(u: float, v: float, width: float, depth: float) -> PackedVector2Array:
	return PackedVector2Array([iso(u,v),iso(u+width,v),iso(u+width,v+depth),iso(u,v+depth)])


static func floor_polygon() -> PackedVector2Array:
	return footprint(0,0,8,8)


func _ready() -> void:
	floor_texture = load(ASSETS+"oak_floor.png")


func _draw() -> void:
	draw_rect(Rect2(0,0,1920,1080),Color("20392f"))
	var floor_points := floor_polygon()
	# Shallow stone foundation makes the cutaway feel grounded.
	for edge in [[iso(0,8),iso(8,8)],[iso(8,8),iso(8,0)]]:
		var face := PackedVector2Array([edge[0],edge[1],edge[1]+Vector2(0,22),edge[0]+Vector2(0,22)])
		draw_colored_polygon(face,Color("69543e"))
	if floor_texture:
		draw_polygon(floor_points,PackedColorArray([Color("fff0d7")]),PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]),floor_texture)
	else:
		draw_colored_polygon(floor_points,Color("cda675"))
	for edge in [[iso(0,8),iso(0,0)],[iso(0,0),iso(8,0)]]:
		var wall := PackedVector2Array([edge[0],edge[1],edge[1]-Vector2(0,230),edge[0]-Vector2(0,230)])
		draw_colored_polygon(wall,Color("e9d8b4") if edge[0].x<960 else Color("d7c39f"))
		draw_line(edge[0],edge[1],Color("83704f"),12,true)
		draw_line(edge[0]-Vector2(0,230),edge[1]-Vector2(0,230),Color("776044"),11,true)
		for index in 5:
			var base: Vector2 = edge[0].lerp(edge[1],index/4.0)
			draw_line(base,base-Vector2(0,230),Color("a28b61"),6,true)
	# Two inset windows, on the right wall, share the outdoor time of day.
	for u in [2.4,5.2]:
		var a := iso(u,0)-Vector2(0,185)
		var b := iso(u+1.25,0)-Vector2(0,185)
		var pane := PackedVector2Array([a,b,b+Vector2(0,105),a+Vector2(0,105)])
		var phase: int = int(floorf(hub.clock))%4
		var outdoor: Color = hub.TINTS[phase].lerp(hub.TINTS[(phase+1)%4],smoothstep(.35,1,fposmod(hub.clock,1)))
		var glass := Color("b6d9ce").lerp(Color("253848"),clampf((1-outdoor.g)*2,0,1))
		draw_colored_polygon(pane,glass)
		draw_polyline(PackedVector2Array([a,b,b+Vector2(0,105),a+Vector2(0,105),a]),Color("56786e"),7,true)
		draw_line(a+Vector2(0,52),b+Vector2(0,52),Color("eee0bf"),4,true)
		draw_line(a.lerp(b,.5),a.lerp(b,.5)+Vector2(0,105),Color("eee0bf"),4,true)
		# Fabric edges sway, independently of the solid window frame.
		var sway := sin(hub.elapsed*1.25+u)*3
		draw_colored_polygon(PackedVector2Array([a-Vector2(7,5),a+Vector2(19,8),a+Vector2(13+sway,97),a+Vector2(-7,103)]),Color("e9e6cc"))
		var sill := PackedVector2Array([a+Vector2(-8,109),b+Vector2(8,109),b+Vector2(8,117),a+Vector2(-8,117)])
		draw_colored_polygon(sill,Color("8e7855"))
	# Enamel wheat medallion, a wall clock, and warm hanging lamps.
	var plaque := iso(0,4.3)-Vector2(0,145)
	draw_circle(plaque,31,Color("54766b"))
	draw_arc(plaque,31,0,TAU,48,Color("c9b078"),3,true)
	for stalk in [-1,0,1]:
		var tip := plaque+Vector2(stalk*9,-17+abs(stalk)*5)
		draw_line(plaque+Vector2(0,19),tip,Color("e8d5a1"),1.5,true)
		for grain in 4:
			var at := tip+Vector2(0,grain*5)
			draw_line(at-Vector2(5,3),at,Color("e8d5a1"),3,true)
			draw_line(at+Vector2(5,-3),at,Color("e8d5a1"),3,true)
	for u in [1.0,7.0]:
		var at := iso(u,0)-Vector2(0,170)
		draw_line(at-Vector2(0,42),at,Color("63533c"),2,true)
		draw_circle(at,17,Color(1,.77,.33,.12))
		draw_circle(at,11,Color("fce0a1"))
		draw_arc(at,12,0,TAU,24,Color("766044"),2,true)
	# Front threshold/rug and room edging are hand placed, with a visible exit.
	var rug := footprint(5.7,5.7,1.7,1.7)
	draw_colored_polygon(rug,Color("63887b"))
	draw_polyline(PackedVector2Array([rug[0],rug[1],rug[2],rug[3],rug[0]]),Color("d7bc7e"),3,true)
	draw_line(iso(0,8),iso(8,8),Color("b69a70"),5,true)
	draw_line(iso(8,8),iso(8,0),Color("b69a70"),5,true)


func draw_air(node: Node2D) -> void:
	var time: float = hub.elapsed
	# Fire is anchored to the generated oven's mouth, not its whole silhouette.
	var mouth := Vector2(1331,427)
	for i in 5:
		var height := 10+sin(time*8+i*1.7)*4+i%2*4
		var at := mouth+Vector2((i-2)*4,0)
		node.draw_colored_polygon(PackedVector2Array([at+Vector2(-4,4),at+Vector2(sin(time*7+i)*3,-height),at+Vector2(4,4)]),Color("ffb74e") if i%2==0 else Color("ffe49c"))
	# Steam from the tea table and drifting flour motes give the room quiet life.
	for i in 7:
		var t := fposmod(time*.24+i/7.0,1)
		var at := iso(2.5,5.8)+Vector2(sin(t*8+i)*5,-84-t*38)
		node.draw_circle(at,1.5+t*2,Color(1,.97,.87,sin(t*PI)*.25))
	for i in 16:
		var at := Vector2(640+fposmod(i*79+time*3,710),310+fposmod(i*53-time*2,360))
		node.draw_circle(at,1,Color(1,.91,.7,.17+.1*sin(time+i)))
