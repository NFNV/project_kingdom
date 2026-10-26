extends Node2D

const City := preload("res://experiments/anime_hub_demo_v07/tools/northgate_layout.gd")
const Style := preload("res://experiments/anime_hub_demo_v07/tools/art_style.gd")
var paving: Texture2D
var street: Texture2D
var grass: Texture2D
var outskirts: Texture2D
var render_only := false

func _ready() -> void:
	paving = Style.texture_for("paving")
	street = Style.texture_for("street")
	grass = Style.texture_for("grass")
	outskirts = load("res://experiments/anime_hub_demo_v07/assets/forest/briarwood_ground.png")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if render_only:
		return
	if DisplayServer.get_name()=="headless":
		render_only = true
		return
	# The streets never change shape. Render their native geometry once, then
	# sample a single viewport texture instead of issuing thousands of tiny draws.
	var cache := SubViewport.new()
	cache.size = Vector2i(6400,3840)
	cache.disable_3d = true
	cache.world_2d = World2D.new()
	cache.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(cache)
	var paint := get_script().new() as Node2D
	paint.render_only = true
	cache.add_child(paint)
	_finish_cache.call_deferred(cache)

func _finish_cache(cache: SubViewport) -> void:
	await RenderingServer.frame_post_draw
	var plate := Sprite2D.new()
	plate.centered = false
	plate.texture = cache.get_texture()
	add_child(plate)

func patch(u0: float, v0: float, u1: float, v1: float, color: Color, stone := false, material: Texture2D = null) -> void:
	var uv := PackedVector2Array([Vector2(u0,v0),Vector2(u1,v0),Vector2(u1,v1),Vector2(u0,v1)])
	draw_colored_polygon(City.quad(u0,v0,u1,v1),color,uv,material if material!=null else (paving if stone else null))

func _draw() -> void:
	if not render_only:
		return
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(6400,0),Vector2(6400,3840),Vector2(0,3840)]),Color("c2d3b7"),PackedVector2Array([Vector2.ZERO,Vector2(4,0),Vector2(4,3),Vector2(0,3)]),outskirts)
	patch(0,0,13,13,Color("d7dfbe"),false,grass)
	# Soft variation and tiny garden flowers are deterministic, cached geometry.
	var rng := RandomNumberGenerator.new()
	rng.seed = 9182
	for i in 1100:
		var u := rng.randf_range(.05,12.95)
		var v := rng.randf_range(.05,12.95)
		draw_circle(City.iso(u,v),rng.randf_range(1.3,3),Color(.88,.92,.59,.35))
	# All sidewalks first, then all carriageways: crossings remain connected.
	for road in City.ROADS:
		patch(road-.68,0,road+.68,13,Color("fff1d3"),true)
		patch(0,road-.68,13,road+.68,Color("fff1d3"),true)
	for road in City.ROADS:
		patch(road-.31,0,road+.31,13,Color("b6c5cf"),false,street)
		patch(0,road-.31,13,road+.31,Color("b6c5cf"),false,street)
	for i in 3500:
		var u := rng.randf_range(.05,12.95)
		var v := rng.randf_range(.05,12.95)
		var on_road := false
		for road in City.ROADS:
			on_road = on_road or absf(u-road)<.30 or absf(v-road)<.30
		if on_road:
			var at := City.iso(u,v)
			draw_line(at,at+Vector2(2.0,.6),Color(.85,.89,.87,.12),1,true)
	# Curbs stop before intersections rather than running across the crossings.
	for road in City.ROADS:
		for segment in 4:
			var a: float = City.ROADS[segment]+.72
			var b: float = City.ROADS[segment+1]-.72
			for side in [-.32,.32]:
				draw_line(City.iso(road+side,a),City.iso(road+side,b),Color("d8ceb3"),5,true)
				draw_line(City.iso(a,road+side),City.iso(b,road+side),Color("d8ceb3"),5,true)
	# Crosswalk stones, sidewalks and plazas share one fixed ground projection.
	for road in City.ROADS:
		for cross in City.ROADS:
			for i in 5:
				patch(road-.3+i*.13,cross+.38,road-.24+i*.13,cross+.55,Color("e5ddc7"))
	# Building forecourts, district plaza, park and civic forecourt.
	for row in 4:
		for col in 4:
			patch(1.18+col*3,1.18+row*3,2.82+col*3,2.82+row*3,Color("e9dcba"),true)
	# Real entrances follow each lot's street-facing wall, including rear-facing
	# northern lots. The door anchor, paving and physical footprint share data.
	for house in City.houses()+City.civic_and_shops():
		var door := City.door_uv(house)
		var sidewalk := City.sidewalk_uv(house)
		if house.front_axis==0:
			patch(minf(door.x,sidewalk.x),door.y-.13,maxf(door.x,sidewalk.x),door.y+.13,Color("f3e6c6"),true)
		else:
			patch(door.x-.13,minf(door.y,sidewalk.y),door.x+.13,maxf(door.y,sidewalk.y),Color("f3e6c6"),true)
	patch(3.84,3.84,6.16,6.16,Color("fff0d3"),true)
	for radius in [150,165,180]:
		draw_set_transform(City.iso(5,5)+Vector2(0,8),0,Vector2(1,.5))
		draw_arc(Vector2.ZERO,radius,0,TAU,64,Color(.63,.52,.34,.65),2,true)
	draw_set_transform(Vector2.ZERO)
	patch(7.17,4.17,8.83,5.83,Color("a2b493"),false,grass)
	patch(7.27,4.27,8.73,5.73,Color("e0e4c9"),false,grass)
	for i in 1000:
		var u := rng.randf_range(7.28,8.72)
		var v := rng.randf_range(4.28,5.72)
		if absf(u-8)<.14 or absf(v-5)<.14:
			continue
		var at := City.iso(u,v)
		draw_line(at,at+Vector2(rng.randf_range(-1,1),-rng.randf_range(1.0,3.5)),Color(.7,.84,.42,rng.randf_range(.14,.32)),1,true)
	patch(7.18,4.90,8.82,5.10,Color("eadbb5"),true)
	patch(7.9,4.18,8.1,5.82,Color("eadbb5"),true)
	for uv in [Vector2(7.35,4.35),Vector2(8.65,4.35),Vector2(7.35,5.65),Vector2(8.65,5.65)]:
		for i in 16:
			var at := City.iso(uv.x+sin(i*2.4)*.12,uv.y+cos(i*2.4)*.12)
			draw_circle(at,2.5,[Color("f4d899"),Color("c68fb0"),Color("faf6d4")][i%3])
	for label in [["SUNSTONE PLAZA",City.iso(5,5.9)],["LINDEN PARK",City.iso(8,5.9)],["MARKET LANE",City.iso(5,9.0)]]:
		draw_string(ThemeDB.fallback_font,label[1]+Vector2(-100,24),label[0],HORIZONTAL_ALIGNMENT_CENTER,200,17,Color("72694e"))
