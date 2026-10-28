extends Node2D
# All geometry is CanvasItem drawing. Logical positions are 2D map coordinates.
const City := preload("res://experiments/overworld_2d_v01/city.gd")
const Rider := preload("res://experiments/overworld_2d_v01/mounted_rider.gd")
const Map := preload("res://experiments/overworld_2d_v01/layout.gd")
const ROOT := "res://experiments/overworld_2d_v01/"
const FOCAL := 900.0
const CAMERA_HEIGHT := 14.0
const HORIZON := 245.0
const DEFAULT_BEND := .0014
const MAX_BEND := .003
const CAMERA_LEAD := 28.0
var mounted_rider: RefCounted
var hop_study := false
var player := Map.START
var camera_yaw := 0.0
var camera_spin := 0.0
var sky_tiles: Array[TextureRect] = []
var camera_ground := player-Vector2(0,28)
var velocity := Vector2.ZERO
var facing := Vector2(0,1)
var clock := 0.0
var stride := 0.0
var curvature := DEFAULT_BEND
var curved := true
var grid := false
var paused := false
var diagnostics := false
var automated := false
var show_map := true
var region_map := false
var prop_grid: Dictionary = {}
var region_segments: Array[Vector4] = []
var shader_segment_key := Vector3i(-9999,-9999,-9999)
var near_landmark := ""
var notice := "Explore Mosswood and the northern routes. M opens your region map."
var notice_left := 6.0
var props: Array[Dictionary] = []
var visible_props: Array[Dictionary] = []
var textures: Dictionary = {}
var terrain: ColorRect
var scenery: Node2D
var hud: Node2D
var font: Font
var distance_walked := 0.0
var intent := Vector2.ZERO
var bound_hint := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	get_tree().root.content_scale_size = Vector2i(1920,1080)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().title = "Project Kingdom — 2D overworld laboratory"
	Engine.max_fps = 60
	font = ThemeDB.fallback_font
	mounted_rider = Rider.new()
	for i in 3:
		var sky := TextureRect.new()
		sky.texture = load(ROOT+"art/sky.svg")
		sky.size = Vector2(1920,1080)
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sky)
		sky_tiles.append(sky)
	terrain = ColorRect.new()
	terrain.size = Vector2(1920,1080)
	terrain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader = load(ROOT+"ground.gdshader")
	terrain.material = shader
	add_child(terrain)
	for id in ["oak","pine","rock","bush","house","clocktower"]:
		textures[id] = load(ROOT+"art/"+id+".svg")
	# Cache modest gameplay textures with mipmaps; keep original PNGs untouched.
	for pair in [["oak","res://experiments/anime_hub_assets_v06/scenery/elm_tree.png"],["willow","res://experiments/anime_hub_assets_v06/scenery/willow_tree.png"],["pine",ROOT+"art/region/pine_grove.png"],["rock",ROOT+"art/region/coastal_rocks.png"],["windmill",ROOT+"art/region/windmill.png"],["ruins",ROOT+"art/region/ruins.png"]]:
		var source: Texture2D = load(pair[1])
		var image := source.get_image()
		image = image.get_region(image.get_used_rect())
		if image.get_height()>768:
			image.resize(roundi(image.get_width()*768.0/image.get_height()),768,Image.INTERPOLATE_LANCZOS)
		image.generate_mipmaps()
		textures[pair[0]] = ImageTexture.create_from_image(image)
	region_segments = Map.branch_segments()
	build_region()
	scenery = Node2D.new()
	scenery.draw.connect(draw_scene)
	add_child(scenery)
	hud = Node2D.new()
	hud.draw.connect(draw_hud)
	add_child(hud)
	update_shader()
	update_visible()
	if "--city" in OS.get_cmdline_user_args():
		visit(3)

func bend() -> float:
	return curvature if curved else 0.0

func camera_right() -> Vector2:
	return Vector2(cos(camera_yaw),-sin(camera_yaw))

func camera_forward() -> Vector2:
	return Vector2(sin(camera_yaw),cos(camera_yaw))

func view_vector(vector: Vector2) -> Vector2:
	return Vector2(vector.dot(camera_right()),vector.dot(camera_forward()))

func view_point(p: Vector2) -> Vector2:
	return view_vector(p-camera_ground)

func world_vector(vector: Vector2) -> Vector2:
	return camera_right()*vector.x+camera_forward()*vector.y

func update_camera() -> void:
	camera_ground = player-camera_forward()*CAMERA_LEAD

func rotate_camera(axis: float, delta: float) -> void:
	camera_yaw = wrapf(camera_yaw+axis*delta*1.25,-PI,PI)
	update_camera()
	mounted_rider.set_direction(view_vector(facing))

func project(p: Vector2, height := 0.0) -> Vector2:
	var relative := view_point(p)
	if relative.y<=.5:
		return Vector2(-100000,-100000)
	var drop := bend()*(relative.length_squared()-CAMERA_LEAD*CAMERA_LEAD)
	return Vector2(960+FOCAL*relative.x/relative.y,HORIZON+FOCAL*(CAMERA_HEIGHT-height+drop)/relative.y)

func inverse_ground(screen: Vector2) -> Vector2:
	var t := (screen.y-HORIZON)/FOCAL
	var slope := (screen.x-960)/FOCAL
	var effective_height := CAMERA_HEIGHT-bend()*CAMERA_LEAD*CAMERA_LEAD
	var discriminant := t*t-4*bend()*(1+slope*slope)*effective_height
	if t<=0 or discriminant<0:
		return Vector2(INF,INF)
	var depth := 2*effective_height/(t+sqrt(discriminant))
	return camera_ground+world_vector(Vector2((screen.x-960)*depth/FOCAL,depth))

func build_region() -> void:
	props.clear()
	prop_grid.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 27102026
	var landmarks := Map.landmarks()
	for i in 1800:
		var p := Vector2(rng.randf_range(-238,238),rng.randf_range(-78,478))
		if not Map.safe_ground(p) or Map.road_distance(p)<7 or absf(p.y-Map.river_z(p.x))<10 or p.distance_to(Map.TOWN)<22:
			continue
		if landmarks.any(func(marker: Dictionary): return p.distance_to(marker.p)<12):
			continue
		if p.distance_to(Map.WINDMILL)<18 or p.distance_to(Map.RUINS)<16:
			continue
		var kind := "pine" if p.y>155 and p.x<65 else "oak"
		if absf(p.y-Map.river_z(p.x))<24 or absf(Map.lake_distance(p)-1)<.35:
			kind = "willow"
		if rng.randf()<(.55 if p.y<120 or p.x>140 else .22):
			kind = "rock" if rng.randf()<.4 else "bush"
		var height := rng.randf_range(4.0,6.5) if kind in ["oak","pine","willow"] else rng.randf_range(1.0,2.6)
		props.append({"p":p,"kind":kind,"height":height,"radius":1.1 if kind in ["oak","pine","willow"] else .75,"tint":Color.from_hsv(rng.randf_range(.0,.04),rng.randf_range(.0,.05),rng.randf_range(.93,1.0)),"phase":rng.randf()*TAU})
	for item in [["windmill",Map.WINDMILL,11.0,3.0],["ruins",Map.RUINS,8.0,3.0]]:
		props.append({"p":item[1],"kind":item[0],"height":item[2],"radius":item[3],"tint":Color.WHITE,"phase":0.0})
	# Small stone outcrops make the coastline readable from the approach.
	for i in 12:
		var p := Vector2(Map.coast_x(285+i*12)-9,285+i*12)
		props.append({"p":p,"kind":"rock","height":2.6,"radius":1.0,"tint":Color.WHITE,"phase":0.0})
	props.append_array(City.props())
	for item in props:
		item["lod"] = posmod(hash(item.p),4)
		var cell := grid_cell(item.p)
		if not prop_grid.has(cell): prop_grid[cell] = []
		prop_grid[cell].append(item)

func grid_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x/16),floori(p.y/16))

func can_stand(p: Vector2) -> bool:
	if not Map.safe_ground(p): return false
	var cell := grid_cell(p)
	for x in range(cell.x-1,cell.x+2):
		for y in range(cell.y-1,cell.y+2):
			for item in prop_grid.get(Vector2i(x,y),[]):
				if item.kind=="city_building":
					if City.blocks(item,p): return false
				elif p.distance_squared_to(item.p)<pow(item.radius+.65,2):
					return false
	return true

func move_player(direction: Vector2, delta: float, running := false) -> void:
	var target := direction.limit_length()* (16.0 if running else 9.0)
	velocity = velocity.move_toward(target,delta*48)
	var before := player
	var step := velocity*delta
	# Axis separation permits sliding along tree trunks and riverbanks.
	if can_stand(player+Vector2(step.x,0)):
		player.x += step.x
	if can_stand(player+Vector2(0,step.y)):
		player.y += step.y
	var travelled := before.distance_to(player)
	distance_walked += travelled
	mounted_rider.step(delta,travelled)
	if travelled>.0001:
		stride += travelled*.83
		facing = (player-before).normalized()
		mounted_rider.set_direction(view_vector(facing))
	if target.length()>0 and travelled<.0001 and bound_hint<=0:
		notice = "Find the bridge to cross the river." if absf(player.y-Map.river_z(player.x))<7 else "Scenery blocks the way. Walk around it."
		notice_left = 2
		bound_hint = 3

func _physics_process(delta: float) -> void:
	if paused or region_map:
		return
	clock += delta
	notice_left = maxf(0,notice_left-delta)
	bound_hint = maxf(0,bound_hint-delta)
	var direction := intent
	var rotation := camera_spin
	if not automated:
		rotation = float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q))
	rotate_camera(rotation,delta)
	if not automated:
		direction = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))-float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)))
		direction = world_vector(direction)
	move_player(direction,delta,Input.is_physical_key_pressed(KEY_SHIFT) and not automated)
	update_camera()
	near_landmark = ""
	for marker in Map.landmarks():
		if minf(player.distance_to(marker.p),player.distance_to(marker.get("location",marker.p)))<19:
			near_landmark = marker.name
			break

func _process(_delta: float) -> void:
	terrain.visible = not region_map
	scenery.visible = not region_map
	for sky in sky_tiles: sky.visible = not region_map
	if region_map:
		hud.queue_redraw()
		return
	var pan := fposmod(camera_yaw/TAU*1920,1920)
	for i in sky_tiles.size():
		sky_tiles[i].position.x = (i-1)*1920-pan
	update_shader()
	update_visible()
	scenery.queue_redraw()
	hud.queue_redraw()

func update_shader() -> void:
	var material := terrain.material as ShaderMaterial
	var values := {"city_center":Map.TOWN,"camera_ground":camera_ground,"camera_right":camera_right(),"camera_forward":camera_forward(),"focal":FOCAL,"camera_height":CAMERA_HEIGHT,"horizon":HORIZON,"bend":bend(),"camera_lead":CAMERA_LEAD,"world_time":clock,"grid":grid,"river_z":Map.RIVER_Z,"river_wave":Map.RIVER_WAVE,"river_rate":Map.RIVER_RATE,"river_half":Map.RIVER_HALF,"bridge_x":Map.BRIDGE_X,"bridge_half":Map.BRIDGE_HALF}
	for key in values:
		material.set_shader_parameter(key,values[key])
	# Only road segments within the visible ground disc are evaluated per pixel.
	var cell := grid_cell(camera_ground)
	var key := Vector3i(cell.x,cell.y,roundi(horizon_radius()))
	if key!=shader_segment_key:
		shader_segment_key = key
		var segments: Array[Vector4] = []
		for segment in region_segments:
			if Map.segment_distance(camera_ground,Vector2(segment.x,segment.y),Vector2(segment.z,segment.w))<horizon_radius()+24:
				segments.append(segment)
		material.set_shader_parameter("route_count",segments.size())
		while segments.size()<32: segments.append(Vector4.ZERO)
		material.set_shader_parameter("routes",segments)

func horizon_radius() -> float:
	return minf(355.0,sqrt((CAMERA_HEIGHT-bend()*CAMERA_LEAD*CAMERA_LEAD)/bend())) if bend()>0 else 355.0

func surface_rotation(p: Vector2) -> float:
	# Match the projected east/west ground tangent. The perpendicular points
	# outward from the dome, rather than using the screen's fixed vertical.
	return atan(2.0*bend()*view_point(p).x)

func update_visible() -> void:
	visible_props.clear()
	var limit := horizon_radius()
	for item in props:
		var depth: float = view_point(item.p).y
		if depth<4 or depth>355 or (bend()>0 and (item.p-camera_ground).length()>limit):
			continue
		if not curved and item.kind in ["oak","pine","willow","rock","bush"]:
			var lod: int = item.get("lod",0)
			if (lod>1 and depth>110) or (lod==1 and depth>185): continue
		var at := project(item.p)
		var height: float = FOCAL*item.height/depth
		if at.x < -height or at.x>1920+height or at.y-height>1080:
			continue
		visible_props.append(item)
	visible_props.append({"p":player,"kind":"rider","height":3.5})
	visible_props.sort_custom(func(a: Dictionary,b: Dictionary): return view_point(a.p).y>view_point(b.p).y)

func draw_scene() -> void:
	for item in visible_props:
		var p: Vector2 = item.p
		var at := project(p)
		var depth := view_point(p).y
		if item.kind=="city_building":
			City.draw_building(self,scenery,item)
			continue
		if item.kind=="city_fountain":
			City.draw_fountain(self,scenery,p)
			continue
		if item.kind=="rider":
			draw_rider(at)
			continue
		var size: float = FOCAL*item.height/depth
		var sway := sin(clock*1.35+item.phase)*.004 if item.kind in ["oak","pine","willow"] else 0.0
		var shade: Color = item.tint.lerp(Color("b2c9b1"),smoothstep(80,330,depth)*.7)
		if not curved:
			var lod: int = item.get("lod",0)
			if lod>1: shade.a *= 1.0-smoothstep(80,110,depth)
			elif lod==1: shade.a *= 1.0-smoothstep(155,185,depth)
		if bend()>0:
			shade.a *= 1.0-smoothstep(horizon_radius()-8,horizon_radius(),(p-camera_ground).length())
		# SVG foot anchor is (80,152). Rotate about that foot, including wind,
		# so crowns and roofs lean with the terrain without sliding the base.
		var texture: Texture2D = textures[item.kind]
		var dimensions := texture.get_size()
		var painted: bool = item.kind!="bush"
		var foot := Vector2(dimensions.x*.5,dimensions.y*(.98 if painted else .95))
		scenery.draw_set_transform(at,surface_rotation(p)+sway,Vector2.ONE*(size/dimensions.y))
		scenery.draw_texture_rect(texture,Rect2(-foot,dimensions),false,shade)
		scenery.draw_set_transform(Vector2.ZERO)
	if grid:
		var at := project(player)
		scenery.draw_line(at-Vector2(15,0),at+Vector2(15,0),Color("f4d386"),2)
		scenery.draw_line(at-Vector2(0,10),at+Vector2(0,10),Color("f4d386"),2)

func draw_rider(at: Vector2) -> void:
	mounted_rider.draw(scenery,at,FOCAL/CAMERA_LEAD*.021)

func text(at: Vector2, words: String, size := 20, color := Color("f6edcf")) -> void:
	hud.draw_string(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func panel(rect: Rect2, color := Color("203e36")) -> void:
	hud.draw_style_box(panel_style(color),rect)

func panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("b9a86f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	return style

func draw_hud() -> void:
	panel(Rect2(28,28,484,103),Color("203e36"))
	text(Vector2(50,61),"MOSSWOOD  /  THE GREENSHIRE",16,Color("d1c38d"))
	text(Vector2(50,98),"A little world to explore",29)
	if near_landmark!="":
		panel(Rect2(670,178,580,55))
		text(Vector2(699,213),near_landmark+"  ·  F",21)
	panel(Rect2(28,971,1864,81))
	text(Vector2(50,1003),"WASD / arrows  Roam     Q / E  Rotate camera     Home  North view     Shift  Faster hops     C  Curve     Esc  Pause",20)
	text(Vector2(50,1032),"1–8 Landmarks   M Region map   F Inspect   G Grid   [ / ] Bend   Tab Minimap   R Reset   F3 Stats   F4 Rider   F11 Screen",18,Color("c3c9a8"))
	panel(Rect2(28,875,485,66))
	text(Vector2(48,902),"CURVATURE  "+("ON" if curved else "OFF"),18)
	text(Vector2(48,926),"Bend %.0f%%  ·  All terrain and scenery rendered in 2D" % (curvature/MAX_BEND*100),16,Color("c3c9a8"))
	if notice_left>0:
		panel(Rect2(540,882,1040,52),Color("e9dfb9"))
		text(Vector2(562,916),notice,20,Color("294c3e"))
	if show_map:
		draw_minimap()
	if hop_study:
		panel(Rect2(28,340,440,480),Color("e9dfb9"))
		text(Vector2(50,376),"MOUNTED HOP STUDY",20,Color("294c3e"))
		text(Vector2(50,406),mounted_rider.direction_name()+"  ·  "+mounted_rider.stage(),18,Color("53694b"))
		mounted_rider.draw(hud,Vector2(248,731),1.45)
		text(Vector2(50,803),"WASD hop  ·  Shift faster  ·  F4 close",17,Color("53694b"))
	if diagnostics:
		panel(Rect2(28,150,475,128))
		text(Vector2(48,180),"%d FPS  ·  %d visible props" % [Engine.get_frames_per_second(),visible_props.size()],21)
		text(Vector2(48,211),"Position  %.1f, %.1f  ·  Travelled %.1f" % [player.x,player.y,distance_walked],18)
		text(Vector2(48,242),"Camera %.0f° · 2D projection · no 3D nodes" % rad_to_deg(camera_yaw),18)
	if region_map:
		draw_region_map()
	if paused and not region_map:
		panel(Rect2(710,430,500,140),Color("e9dfb9"))
		text(Vector2(856,482),"RESTING",28,Color("294c3e"))
		text(Vector2(786,526),"Press Esc to continue roaming",22,Color("294c3e"))

func map_point(p: Vector2, large := false) -> Vector2:
	return (Vector2(846,535) if large else Vector2(1697,166))+(p-Vector2(0,200))*(Vector2(1.17,-1.17) if large else Vector2(.29,-.29))

func draw_map_contents(large: bool) -> void:
	var scale := 1.17 if large else .29
	# Vegetation washes and sea shape stay in map coordinates, north always up.
	for area in [[Vector2(-80,265),Vector2(100,125)],[Vector2(60,365),Vector2(90,75)]]:
		hud.draw_set_transform(map_point(area[0],large),0,area[1]*scale)
		hud.draw_circle(Vector2.ZERO,1,Color(.33,.49,.31,.18))
		hud.draw_set_transform(Vector2.ZERO)
	var sea := PackedVector2Array([map_point(Vector2(240,110),large),map_point(Vector2(240,480),large)])
	for z in range(480,109,-10): sea.append(map_point(Vector2(Map.coast_x(z),z),large))
	hud.draw_colored_polygon(sea,Color("8ebbb4"))
	var river := PackedVector2Array()
	for x in range(-240,241,5): river.append(map_point(Vector2(x,Map.river_z(x)),large))
	hud.draw_polyline(river,Color("78aaa5"),maxf(3,9*scale),true)
	hud.draw_set_transform(map_point(Map.LAKE,large),0,Map.LAKE_SIZE*scale)
	hud.draw_circle(Vector2.ZERO,1,Color("78aaa5"))
	hud.draw_set_transform(Vector2.ZERO)
	var road := PackedVector2Array()
	for z in range(-75,476,5): road.append(map_point(Vector2(Map.road_x(z),z),large))
	hud.draw_polyline(road,Color("b29b68"),maxf(2,3*scale),true)
	for route in Map.ROUTES:
		var points := PackedVector2Array()
		for p in route: points.append(map_point(p,large))
		hud.draw_polyline(points,Color("b29b68"),maxf(1.5,2.7*scale),true)
	var markers := Map.landmarks()
	for i in markers.size():
		var at := map_point(markers[i].get("location",markers[i].p),large)
		hud.draw_circle(at,7 if large else 3,Color("496b48"))
		if large:
			var glyph := {2:"pine",4:"windmill",6:"ruins",7:"rock"}
			if glyph.has(i):
				var texture: Texture2D = textures[glyph[i]]
				var size := Vector2(texture.get_width()*38.0/texture.get_height(),38)
				hud.draw_texture_rect(texture,Rect2(at-Vector2(size.x*.5,39),size),false,Color(1,1,1,.85))
			if i==3:
				for offset in [-11.0,0.0,11.0]:
					hud.draw_rect(Rect2(at+Vector2(offset-4,-18),Vector2(9,15)),Color("c5b084"))
					hud.draw_colored_polygon(PackedVector2Array([at+Vector2(offset-6,-18),at+Vector2(offset+6,-18),at+Vector2(offset,-25)]),Color("527081"))
			text(at+Vector2(10,5),str(i+1)+" "+markers[i].short,16,Color("335140"))
	var at := map_point(player,large)
	hud.draw_circle(at,6 if large else 4,Color("a84738"))
	hud.draw_arc(at,10 if large else 7,0,TAU,24,Color("fff2c6"),2,true)
	hud.draw_line(at,map_point(player+camera_forward()*18,large),Color("9e6543"),2,true)

func draw_minimap() -> void:
	panel(Rect2(1540,28,352,242),Color("e5dbb4"))
	text(Vector2(1560,58),"THE GREENSHIRE",17,Color("335140"))
	draw_map_contents(false)
	text(Vector2(1835,59),"N ↑",16,Color("335140"))
	text(Vector2(1560,249),"M  Open the regional map",14,Color("586d4c"))

func draw_region_map() -> void:
	hud.draw_rect(Rect2(0,0,1920,1080),Color(.08,.17,.14,1))
	panel(Rect2(360,95,1200,860),Color("e9dfbb"))
	text(Vector2(405,148),"THE GREENSHIRE",30,Color("294c3e"))
	text(Vector2(405,178),"Mosswood and the northern roads",18,Color("64734e"))
	text(Vector2(1465,152),"N ↑",24,Color("294c3e"))
	draw_map_contents(true)
	text(Vector2(1215,270),"PLACES TO ROAM",19,Color("294c3e"))
	var markers := Map.landmarks()
	for i in markers.size():
		text(Vector2(1215,310+i*46),str(i+1)+"  "+markers[i].short,20,Color("53694b"))
	text(Vector2(405,911),"1–8  Preview a destination     M / Esc  Return to the road",20,Color("294c3e"))

func visit(index: int) -> void:
	var marker: Dictionary = Map.landmarks()[clampi(index,0,7)]
	player = marker.p
	update_camera()
	velocity = Vector2.ZERO
	stride = 0
	mounted_rider.reset()
	region_map = false
	notice = marker.description
	notice_left = 6

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_C: curved = not curved
		KEY_G: grid = not grid
		KEY_F3: diagnostics = not diagnostics
		KEY_F4: hop_study = not hop_study
		KEY_TAB: show_map = not show_map
		KEY_M: region_map = not region_map
		KEY_ESCAPE:
			if region_map: region_map = false
			else: paused = not paused
		KEY_BRACKETLEFT: curvature = maxf(.0003,curvature-.0002)
		KEY_BRACKETRIGHT: curvature = minf(MAX_BEND,curvature+.0002)
		KEY_1: visit(0)
		KEY_2: visit(1)
		KEY_3: visit(2)
		KEY_4: visit(3)
		KEY_5: visit(4)
		KEY_6: visit(5)
		KEY_7: visit(6)
		KEY_8: visit(7)
		KEY_R:
			camera_yaw = 0
			paused = false
			visit(0)
		KEY_HOME:
			camera_yaw = 0
			rotate_camera(0,0)
		KEY_F:
			notice = "Explore the northern roads. M shows the connected region and its landmarks."
			for marker in Map.landmarks():
				if marker.name==near_landmark: notice = marker.description
			notice_left = 5
		KEY_F11: get_window().mode = Window.MODE_WINDOWED if get_window().mode==Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
