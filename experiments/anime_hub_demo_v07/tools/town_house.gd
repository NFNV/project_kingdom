extends Node2D

var data: Dictionary
var render_only := false
var facade: Sprite2D
var plaster: Texture2D
var slate: Texture2D
var window_art: Texture2D
var door_art: Texture2D
var wall_height := 220.0
var roof_height := 78.0
var cache_size := Vector2i(400,500)
var serial := 0

func p(u: float, v: float, z := 0.0) -> Vector2:
	return Vector2((u-v)*240,(u+v-data.half_u-data.half_v)*120-z)

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	plaster = load("res://experiments/anime_hub_demo_v07/assets/district/plaster_v2.png")
	slate = load("res://experiments/anime_hub_demo_v07/assets/district/slate_v2.png")
	window_art = load("res://experiments/anime_hub_demo_v07/assets/district/window_v2.png")
	door_art = load("res://experiments/anime_hub_demo_v07/assets/district/door_v2.png")
	wall_height = float(data.floors)*98.0+40
	roof_height = 60.0+float(data.kind%4)*13
	if render_only:
		return
	cache_size = Vector2i(ceili((data.half_u+data.half_v)*480+76),ceili(wall_height+roof_height+(data.half_u+data.half_v)*240+65))
	facade = Sprite2D.new()
	facade.centered = false
	facade.offset = Vector2(-cache_size.x*.5,-cache_size.y+22)
	var placeholder := GradientTexture2D.new()
	placeholder.width = cache_size.x
	placeholder.height = cache_size.y
	facade.texture = placeholder
	add_child(facade)
	if DisplayServer.get_name()=="headless":
		return
	facade.hide()
	var cache := SubViewport.new()
	cache.size = cache_size
	cache.transparent_bg = true
	cache.disable_3d = true
	cache.world_2d = World2D.new()
	cache.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(cache)
	var paint := get_script().new() as Node2D
	paint.data = data
	paint.render_only = true
	paint.position = Vector2(cache_size.x*.5,cache_size.y-22)
	cache.add_child(paint)
	_finish.call_deferred(cache)

func _finish(cache: SubViewport) -> void:
	await RenderingServer.frame_post_draw
	facade.texture = cache.get_texture()
	facade.show()

func face_point(axis: int, sign_value: float, t: float, z: float) -> Vector2:
	return p(sign_value*data.half_u,t,z) if axis==0 else p(t,sign_value*data.half_v,z)

func face_quad(axis: int, sign_value: float, t0: float, t1: float, z0: float, z1: float, color: Color, material: Texture2D = null) -> void:
	var points := PackedVector2Array([face_point(axis,sign_value,t0,z0),face_point(axis,sign_value,t1,z0),face_point(axis,sign_value,t1,z1),face_point(axis,sign_value,t0,z1)])
	var uv := PackedVector2Array([Vector2(t0*3,z0/150),Vector2(t1*3,z0/150),Vector2(t1*3,z1/150),Vector2(t0*3,z1/150)])
	draw_colored_polygon(points,color,uv,material)

func roof_face(points: Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
	for at in points:
		polygon.append(p(at.x,at.y,at.z))
	draw_colored_polygon(polygon,color,uv,slate)
	var outline := polygon.duplicate()
	outline.append(polygon[0])
	draw_polyline(outline,Color("5e6257"),1.2,true)

func window(axis: int, side: float, t: float, base: float, flowers: bool) -> void:
	if data.shutters:
		var points := PackedVector2Array([face_point(axis,side,t-.142,base-22),face_point(axis,side,t+.142,base-22),face_point(axis,side,t+.142,base+63),face_point(axis,side,t-.142,base+63)])
		draw_colored_polygon(points,Color.WHITE,PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]),window_art)
		return
	face_quad(axis,side,t-.083,t+.083,base-3,base+53,Color("5a625b"))
	face_quad(axis,side,t-.072,t+.072,base,base+50,Color("f5e9cd"))
	face_quad(axis,side,t-.058,t+.058,base+5,base+45,Color("6d9ba7") if (data.kind+int(base))%3 else Color("d6ae68"))
	face_quad(axis,side,t-.007,t+.007,base+4,base+46,Color("e7dec2"))
	face_quad(axis,side,t-.06,t+.06,base+24,base+28,Color("e7dec2"))
	if data.shutters:
		for offset in [-.117,.117]:
			face_quad(axis,side,t+offset-.027,t+offset+.027,base+1,base+48,data.roof.darkened(.13))
			for slat in 5:
				draw_line(face_point(axis,side,t+offset-.022,base+6+slat*8),face_point(axis,side,t+offset+.022,base+6+slat*8),Color(.92,.88,.72,.5),1,true)
	face_quad(axis,side,t-.095,t+.095,base-7,base-2,Color("d3c7a3"))
	if flowers:
		face_quad(axis,side,t-.09,t+.09,base-13,base-6,Color("997d56"))
		for i in 8:
			var at := face_point(axis,side,t-.08+i*.023,base-5)
			draw_circle(at,3.6,Color("527649"))
			draw_circle(at+Vector2(sin(i)*1.5,-2.5),1.9,[Color("fff5c9"),Color("d6909c"),Color("d9b45d")][(i+data.kind)%3])

func door(axis: int, side: float) -> void:
	if data.kind%3!=1:
		var points := PackedVector2Array([face_point(axis,side,-.15,0),face_point(axis,side,.15,0),face_point(axis,side,.15,128),face_point(axis,side,-.15,128)])
		draw_colored_polygon(points,Color.WHITE,PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]),door_art)
		return
	face_quad(axis,side,-.115,.115,4,111,Color("c2b28f"))
	face_quad(axis,side,-.095,.095,5,106,Color("544839"))
	face_quad(axis,side,-.082,.082,8,102,[Color("698a7f"),Color("76604b"),Color("697e92")][data.kind%3])
	for t in [-.048,.048]:
		for z in [20,66]:
			face_quad(axis,side,t-.026,t+.026,z,z+27,Color(.18,.25,.23,.3))
	draw_circle(face_point(axis,side,.055,51),2.5,Color("e5c77d"))
	face_quad(axis,side,-.13,.13,0,5,Color("d7cfb4"))

func balcony(axis: int) -> void:
	var side := 1.0
	var z := 121.0
	face_quad(axis,side,-.20,.20,z-5,z,Color("a38d65"))
	draw_line(face_point(axis,side,-.20,z+21),face_point(axis,side,.20,z+21),Color("4b6257"),2.5,true)
	for i in 9:
		var t := -.20+i*.05
		draw_line(face_point(axis,side,t,z),face_point(axis,side,t,z+21),Color("4b6257"),1.5,true)

func wall(axis: int, side: float) -> void:
	var half: float = data.half_v if axis==0 else data.half_u
	var color: Color = data.facade
	color = color.darkened(.10 if axis==0 else .21)
	if side<0:
		color = color.darkened(.12)
	face_quad(axis,side,-half,half,0,wall_height,color,plaster)
	if data.style=="brick_rowhouse":
		face_quad(axis,side,-half,half,14,wall_height-8,Color("c0957e").darkened(.1 if axis==1 else 0),plaster)
		for row in int(wall_height/15):
			var z := 16+row*15.0
			draw_line(face_point(axis,side,-half,z),face_point(axis,side,half,z),Color(.9,.83,.69,.35),1,true)
			for column in 5:
				var t: float = -half+column*half*.4+(half*.2 if row%2==0 else 0)
				if t<half:
					draw_line(face_point(axis,side,t,z),face_point(axis,side,t,minf(z+15,wall_height-8)),Color(.9,.83,.69,.28),1,true)
	face_quad(axis,side,-half,half,0,13,Color("b8ad92"))
	face_quad(axis,side,-half,half,wall_height-7,wall_height,Color("eee0bd"))
	for floor_index in data.floors:
		var base: float = floor_index*98+43.0
		for t in [-half*.52,half*.52]:
			if floor_index==0 and axis==data.front_axis and side==data.front_sign:
				continue
			window(axis,side,t,base,(floor_index+data.kind)%2==0)
		if floor_index>0:
			face_quad(axis,side,-half,half,floor_index*98+25,floor_index*98+29,Color("dccbaa"))
	if axis==data.front_axis and side==data.front_sign:
		door(axis,side)
		if data.awning:
			var points := PackedVector2Array([face_point(axis,side,-.15,117),face_point(axis,side,.15,117),face_point(axis,side,.15,108)+Vector2(0,8),face_point(axis,side,-.15,108)+Vector2(0,8)])
			draw_colored_polygon(points,data.roof.lightened(.15))
		if data.balcony and data.floors>1:
			balcony(axis)
	if data.style=="timber_house":
		for t in [-half,0.0,half]:
			draw_line(face_point(axis,side,t,15),face_point(axis,side,t,wall_height-8),Color("827258"),4,true)
		draw_line(face_point(axis,side,-half,128),face_point(axis,side,half,wall_height-10),Color("827258"),3,true)
	if data.get("civic",false) and axis==0 and side>0:
		var at := face_point(axis,side,0,wall_height-54)
		draw_circle(at,22,Color("796f55"))
		draw_circle(at,19,Color("eee5c7"))
		draw_line(at,at+Vector2(0,-12),Color("526257"),2,true)
		draw_line(at,at+Vector2(9,3),Color("526257"),2,true)

func _draw() -> void:
	if not render_only:
		return
	# Every vertical edge is exactly (0,-height), every ground edge is (240,120)
	# or (-240,120). Source images cannot introduce leaning or camera mismatch.
	wall(0,-1)
	wall(1,-1)
	wall(0,1)
	wall(1,1)
	var a: float = data.half_u+.055
	var b: float = data.half_v+.055
	var h := wall_height
	var top := h+roof_height
	var tint: Color = data.roof*1.65
	if data.roof_type=="hip":
		roof_face([Vector3(-a,-b,h),Vector3(a,-b,h),Vector3(.13,-.13,top),Vector3(-.13,-.13,top)],tint.darkened(.1))
		roof_face([Vector3(-a,-b,h),Vector3(-a,b,h),Vector3(-.13,.13,top),Vector3(-.13,-.13,top)],tint.darkened(.2))
		roof_face([Vector3(a,-b,h),Vector3(a,b,h),Vector3(.13,.13,top),Vector3(.13,-.13,top)],tint)
		roof_face([Vector3(-a,b,h),Vector3(a,b,h),Vector3(.13,.13,top),Vector3(-.13,.13,top)],tint.darkened(.13))
		roof_face([Vector3(-.13,-.13,top),Vector3(.13,-.13,top),Vector3(.13,.13,top),Vector3(-.13,.13,top)],tint.lightened(.07))
	elif data.roof_axis==0:
		for side in [-1,1]:
			draw_colored_polygon(PackedVector2Array([p(side*data.half_u,-data.half_v,h),p(side*data.half_u,data.half_v,h),p(side*data.half_u,0,top-7)]),data.facade)
		roof_face([Vector3(-a,-b,h),Vector3(a,-b,h),Vector3(a,0,top),Vector3(-a,0,top)],tint)
		roof_face([Vector3(-a,b,h),Vector3(a,b,h),Vector3(a,0,top),Vector3(-a,0,top)],tint.darkened(.18))
	else:
		for side in [-1,1]:
			draw_colored_polygon(PackedVector2Array([p(-data.half_u,side*data.half_v,h),p(data.half_u,side*data.half_v,h),p(0,side*data.half_v,top-7)]),data.facade)
		roof_face([Vector3(-a,-b,h),Vector3(-a,b,h),Vector3(0,b,top),Vector3(0,-b,top)],tint.darkened(.20))
		roof_face([Vector3(a,-b,h),Vector3(a,b,h),Vector3(0,b,top),Vector3(0,-b,top)],tint)
	if data.chimney:
		var at := p(-.09,-.05,top+13)
		draw_colored_polygon(PackedVector2Array([at+Vector2(-9,0),at+Vector2(5,5),at+Vector2(5,-28),at+Vector2(-9,-33)]),Color("b5a182"))
		draw_colored_polygon(PackedVector2Array([at+Vector2(5,5),at+Vector2(14,0),at+Vector2(14,-33),at+Vector2(5,-28)]),Color("937e67"))
		draw_line(at+Vector2(-11,-34),at+Vector2(5,-29),Color("dec5a0"),4,true)
