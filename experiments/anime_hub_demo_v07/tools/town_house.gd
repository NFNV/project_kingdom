extends Node2D

const Style := preload("res://experiments/anime_hub_demo_v07/tools/art_style.gd")
var data: Dictionary
var hub: Node2D
var render_only := false
var facade: Sprite2D
var night_windows: Polygon2D
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
	plaster = Style.texture_for("plaster")
	slate = Style.texture_for("slate")
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
	_make_window_lights()
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

func _make_window_lights() -> void:
	# Independent warm panes over the cached daytime painting. One mesh per
	# house, using the same face coordinates; no nighttime building rerenders.
	night_windows = Polygon2D.new()
	var points := PackedVector2Array()
	var faces: Array[PackedInt32Array] = []
	for axis in 2:
		var half: float = data.half_v if axis==0 else data.half_u
		for floor_index in data.floors:
			for index in 2:
				if (int(data.u*10)+int(data.v*10)+floor_index+index)%3==0:
					continue
				if floor_index==0 and axis==data.front_axis and data.front_sign>0:
					continue
				var t: float = half*(-.52 if index==0 else .52)
				var base: float = floor_index*98+43
				var width := .058 if data.shutters else .046
				for side in [-1,1]:
					var start := points.size()
					var t0: float = t+side*.006
					var t1: float = t+side*width
					points.append_array(PackedVector2Array([face_point(axis,1,t0,base+10),face_point(axis,1,t1,base+10),face_point(axis,1,t1,base+45),face_point(axis,1,t0,base+45)]))
					faces.append(PackedInt32Array([start,start+1,start+2,start+3]))
	night_windows.polygon = points
	night_windows.polygons = faces
	night_windows.color = Color(1.0,.76,.37,.70)
	night_windows.hide()
	add_child(night_windows)

func _process(_delta: float) -> void:
	if render_only or hub==null or night_windows==null:
		return
	var night: float = clampf((.9-hub.actor_tint.g)*1.8,0,1)
	night_windows.visible = night>.01
	night_windows.modulate.a = night*facade.modulate.a

func _finish(cache: SubViewport) -> void:
	await RenderingServer.frame_post_draw
	facade.texture = cache.get_texture()
	facade.show()

func face_point(axis: int, sign_value: float, t: float, z: float) -> Vector2:
	return p(sign_value*data.half_u,t,z) if axis==0 else p(t,sign_value*data.half_v,z)

func face_quad(axis: int, sign_value: float, t0: float, t1: float, z0: float, z1: float, color: Color, material: Texture2D = null) -> void:
	var points := PackedVector2Array([face_point(axis,sign_value,t0,z0),face_point(axis,sign_value,t1,z0),face_point(axis,sign_value,t1,z1),face_point(axis,sign_value,t0,z1)])
	var uv := PackedVector2Array([Vector2(t0*2,-z0/180),Vector2(t1*2,-z0/180),Vector2(t1*2,-z1/180),Vector2(t0*2,-z1/180)])
	draw_colored_polygon(points,color,uv,material)

func roof_face(points: Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
	for at in points:
		polygon.append(p(at.x,at.y,at.z))
	draw_colored_polygon(polygon,color,uv,slate)
	var outline := polygon.duplicate()
	outline.append(polygon[0])
	draw_polyline(outline,Color("596570"),2.0,true)
	draw_line(polygon[0]+Vector2(0,4),polygon[1]+Vector2(0,4),Color("b1a28b"),3.0,true)

func window(axis: int, side: float, t: float, base: float, flowers: bool) -> void:
	if data.shutters:
		var points := PackedVector2Array([face_point(axis,side,t-.142,base-22),face_point(axis,side,t+.142,base-22),face_point(axis,side,t+.142,base+63),face_point(axis,side,t-.142,base+63)])
		draw_colored_polygon(points,Color.WHITE,PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]),window_art)
		return
	var detail := Style.texture_for("casement" if flowers else "arched_window")
	var points := PackedVector2Array([face_point(axis,side,t-.10,base-16),face_point(axis,side,t+.10,base-16),face_point(axis,side,t+.10,base+61),face_point(axis,side,t-.10,base+61)])
	draw_colored_polygon(points,Color.WHITE,PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]),detail)

func door(axis: int, side: float) -> void:
	var detail: Texture2D = door_art if data.kind%3==0 else Style.texture_for("teal_door" if data.kind%3==1 else "oak_door")
	var points := PackedVector2Array([face_point(axis,side,-.15,0),face_point(axis,side,.15,0),face_point(axis,side,.15,128),face_point(axis,side,-.15,128)])
	draw_colored_polygon(points,Color.WHITE,PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]),detail)

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
	color = color.darkened(.025 if axis==0 else .14)
	if side<0:
		color = color.darkened(.12)
	face_quad(axis,side,-half,half,0,wall_height,color,plaster)
	if data.style=="brick_rowhouse":
		face_quad(axis,side,-half,half,14,wall_height-8,Color.WHITE.darkened(.08 if axis==1 else 0),Style.texture_for("brick"))
	face_quad(axis,side,-half,half,0,17,Color("d6cbb0"),Style.texture_for("paving"))
	face_quad(axis,side,-half,half,wall_height-7,wall_height,Color("eee0bd"))
	# A narrow painted cornice shadow and corner stones tie the front elevations
	# to the textured walls without changing their fixed isometric geometry.
	face_quad(axis,side,-half,half,wall_height-14,wall_height-8,Color(.31,.38,.41,.18))
	for t in [-half,half]:
		face_quad(axis,side,t-.015,t+.015,17,wall_height-8,Color("f1e5cb"),plaster)
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
			var overhang := Vector2(side*(1 if axis==0 else -1)*23,side*11+12)
			for stripe in 6:
				var a := face_point(axis,side,-.19+stripe*.0633,132)
				var b := face_point(axis,side,-.19+(stripe+1)*.0633,132)
				var cloth: Color = Style.IVORY if stripe%2==0 else Style.TEAL
				draw_colored_polygon(PackedVector2Array([a,b,b+overhang,a+overhang]),cloth)
				draw_colored_polygon(PackedVector2Array([a+overhang,b+overhang,b+overhang+Vector2(0,7),a+overhang+Vector2(0,7)]),cloth.darkened(.07))
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
	var ground := PackedVector2Array([p(-data.half_u,-data.half_v),p(data.half_u,-data.half_v),p(data.half_u,data.half_v),p(-data.half_u,data.half_v)])
	for i in ground.size():
		ground[i] += Vector2(11,9)
	draw_colored_polygon(ground,Color(.24,.29,.30,.14))
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
	# Compensate for the blue pigment in the shared slate art before tinting;
	# terracotta variants retain real overlapping shingles, never wall bricks.
	var tint: Color = data.roof/Color("728699")
	if data.roof_type=="hip":
		roof_face([Vector3(-a,-b,h),Vector3(a,-b,h),Vector3(.13,-.13,top),Vector3(-.13,-.13,top)],tint.darkened(.1))
		roof_face([Vector3(-a,-b,h),Vector3(-a,b,h),Vector3(-.13,.13,top),Vector3(-.13,-.13,top)],tint.darkened(.2))
		roof_face([Vector3(a,-b,h),Vector3(a,b,h),Vector3(.13,.13,top),Vector3(.13,-.13,top)],tint)
		roof_face([Vector3(-a,b,h),Vector3(a,b,h),Vector3(.13,.13,top),Vector3(-.13,.13,top)],tint.darkened(.13))
		roof_face([Vector3(-.13,-.13,top),Vector3(.13,-.13,top),Vector3(.13,.13,top),Vector3(-.13,.13,top)],tint.lightened(.07))
	elif data.roof_axis==0:
		for side in [-1,1]:
			draw_colored_polygon(PackedVector2Array([p(side*data.half_u,-data.half_v,h),p(side*data.half_u,data.half_v,h),p(side*data.half_u,0,top-7)]),data.facade,PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(.5,1)]),plaster)
		roof_face([Vector3(-a,-b,h),Vector3(a,-b,h),Vector3(a,0,top),Vector3(-a,0,top)],tint)
		roof_face([Vector3(-a,b,h),Vector3(a,b,h),Vector3(a,0,top),Vector3(-a,0,top)],tint.darkened(.18))
	else:
		for side in [-1,1]:
			draw_colored_polygon(PackedVector2Array([p(-data.half_u,side*data.half_v,h),p(data.half_u,side*data.half_v,h),p(0,side*data.half_v,top-7)]),data.facade,PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(.5,1)]),plaster)
		roof_face([Vector3(-a,-b,h),Vector3(-a,b,h),Vector3(0,b,top),Vector3(0,-b,top)],tint.darkened(.20))
		roof_face([Vector3(a,-b,h),Vector3(a,b,h),Vector3(0,b,top),Vector3(0,-b,top)],tint)
	if data.chimney:
		var at := p(-.09,-.05,top+13)
		draw_colored_polygon(PackedVector2Array([at+Vector2(-9,0),at+Vector2(5,5),at+Vector2(5,-28),at+Vector2(-9,-33)]),Color("b5a182"))
		draw_colored_polygon(PackedVector2Array([at+Vector2(5,5),at+Vector2(14,0),at+Vector2(14,-33),at+Vector2(5,-28)]),Color("937e67"))
		draw_line(at+Vector2(-11,-34),at+Vector2(5,-29),Color("dec5a0"),4,true)
