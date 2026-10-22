extends Node2D

const ART := "res://experiments/anime_hub_assets_v06/"
const ROOT := "res://experiments/anime_hub_demo_v07/"
const Actor := preload("res://experiments/anime_hub_demo_v07/tools/actor.gd")
const SIZE := Vector2i(1920,1080)
const TIMES := ["Dawn","Noon","Dusk","Night"]
const TINTS := [Color(1.0,0.88,0.80),Color.WHITE,Color(0.86,0.70,0.67),Color(0.43,0.52,0.74)]
var FLOOR := PackedVector2Array([Vector2(760,465),Vector2(1150,460),Vector2(1315,570),Vector2(1590,735),Vector2(1360,835),Vector2(1460,990),Vector2(1270,1060),Vector2(410,1060),Vector2(500,925),Vector2(370,770),Vector2(430,685),Vector2(650,580)])
const OBJECTIVES := [
	"Visit Pippa at the blue bakery cart.",
	"Take the warm bread to Elder Mallow by the bench.",
	"Pick up a fruit basket from Moss at the green stall.",
	"Bring the fruit basket to Pip, the courier.",
	"Post Pip's letter in the red postbox.",
	"Morning rounds complete! Try Bram's sparring challenge."
]
const QUEST_TARGETS := ["baker","elder","grocer","courier","postbox","warden"]
var catalog: Dictionary
var world: Node2D
var player: CharacterBody2D
var dogs: Array = []
var pieces: Array[CanvasItem] = []
var interactables: Dictionary = {}
var blockers: Array[PackedVector2Array] = []
var navigation := AStarGrid2D.new()
var backgrounds: Array[Sprite2D] = []
var actor_tint := Color.WHITE
var ui: CanvasLayer
var objective: Label
var time_label: Label
var status_label: Label
var help_label: Label
var talk_panel: Panel
var talk_name: Label
var talk_text: Label
var prompt: Panel
var prompt_text: Label
var quest_marker: Label
var pause_overlay: Control
var paused := false
var combat_active := false
var challenge_won := false
var quest_stage := 0
var nearest := ""
var clock := 1.0
var clock_target := -1.0
var auto_clock := true
var dialogue_left := 0.0
var elapsed := 0.0
var hud_timer := 0.0
var spawn := Vector2(840,905)
var ripples: Node2D
var victory_count := 0


func _ready() -> void:
	get_window().title = "Project Kingdom — Garden Square"
	get_window().content_scale_size = SIZE
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().size = Vector2i(1280,720)
	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60
	get_tree().physics_interpolation = true
	_install_input()
	catalog = JSON.parse_string(FileAccess.get_file_as_string(ART+"catalog.json"))["assets"]
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for time in TIMES:
		var plate := Sprite2D.new()
		plate.texture = load(ART+"backgrounds/plaza_"+time.to_lower()+".png")
		plate.centered = false
		plate.scale = Vector2(SIZE)/plate.texture.get_size()
		add_child(plate)
		backgrounds.append(plate)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	_build_plaza()
	_build_navigation()
	player = _actor(true,spawn)
	_build_ui()
	_update_lighting()
	_update_hud()
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_move_to_foreground()
	_say("Welcome to Garden Square", "WASD to walk, Shift to run. Follow the gold marker to Pippa's cart; press E nearby.")
	if "--night" in OS.get_cmdline_user_args():
		clock = 3.0
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()


func _install_input() -> void:
	var bindings := {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"run":[KEY_SHIFT],"attack":[KEY_SPACE],"interact":[KEY_E],"time":[KEY_T],"pause":[KEY_ESCAPE],"restart":[KEY_R],"fullscreen":[KEY_F11]}
	for action in bindings:
		var name := "hub_"+str(action)
		if not InputMap.has_action(name):
			InputMap.add_action(name)
			for key in bindings[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(name,event)


func _piece(id: String, at: Vector2, height: float) -> Node2D:
	var anchor := Node2D.new()
	anchor.position = at
	world.add_child(anchor)
	var sprite := Sprite2D.new()
	sprite.texture = load(ART+"godot/"+id+".tres")
	sprite.centered = false
	sprite.offset = Vector2(-sprite.texture.get_width()/2.0,-sprite.texture.get_height())
	sprite.scale = Vector2.ONE*height/sprite.texture.get_height()
	anchor.add_child(sprite)
	pieces.append(sprite)
	if id.ends_with("tree"):
		sprite.material = load(ART+"godot/"+("elm_wind.tres" if id=="elm_tree" else "willow_wind.tres"))
	return anchor


func _actor(controlled: bool, at: Vector2):
	var actor := CharacterBody2D.new()
	actor.set_script(Actor)
	actor.hub = self
	actor.controlled = controlled
	actor.position = at
	world.add_child(actor)
	return actor


func _ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for i in 32:
		polygon.append(center+Vector2(cos(i*TAU/32),sin(i*TAU/32))*radius)
	return polygon


func _solid(polygon: PackedVector2Array, boundary := false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.polygon = polygon
	if boundary:
		shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	else:
		blockers.append(polygon)
	body.add_child(shape)
	add_child(body)
	return body


func _resident(id: String, name_text: String, asset: String, at: Vector2, height := 108.0) -> void:
	var anchor := _piece(asset,at,height)
	var body := _solid(_ellipse(at+Vector2(0,-5),Vector2(21,13)))
	interactables[id] = {"name":name_text,"at":at,"anchor":anchor,"body":body,"height":height}


func _build_plaza() -> void:
	_solid(FLOOR,true)
	_piece("fountain",Vector2(970,700),235)
	_solid(_ellipse(Vector2(970,675),Vector2(139,48)))
	_piece("bakery_stall",Vector2(560,625),205)
	_solid(_ellipse(Vector2(560,604),Vector2(90,28)))
	_piece("produce_stall",Vector2(1340,620),205)
	_solid(_ellipse(Vector2(1340,597),Vector2(90,27)))
	_resident("baker","Pippa · Baker","cat_baker",Vector2(485,694))
	_resident("grocer","Moss · Grocer","dog_grocer",Vector2(1430,707))
	_resident("elder","Elder Mallow","cat_elder",Vector2(660,850),104)
	_resident("bookseller","Sage · Bookseller","cat_bookseller",Vector2(1220,740))
	_resident("courier","Pip · Courier","dog_courier",Vector2(1365,850))
	_piece("bench",Vector2(590,829),80)
	_solid(_ellipse(Vector2(590,815),Vector2(57,17)))
	_piece("postbox",Vector2(1430,785),108)
	var post_body := _solid(_ellipse(Vector2(1430,777),Vector2(19,13)))
	interactables["postbox"] = {"name":"Postbox","at":Vector2(1430,785),"height":108,"body":post_body}
	_piece("notice_board",Vector2(1510,490),165)
	_piece("street_lamp",Vector2(365,715),235)
	_piece("elm_tree",Vector2(90,940),480)
	_piece("willow_tree",Vector2(1930,960),500)
	_piece("flower_planter",Vector2(1240,1020),78)
	_solid(_ellipse(Vector2(1240,1007),Vector2(52,16)))
	var warden = _actor(false,Vector2(1150,850))
	interactables["warden"] = {"name":"Bram · Warden","at":warden.position,"anchor":warden,"height":108}
	# Animated water highlights are drawn over the painted water, using native 2D.
	ripples = Node2D.new()
	ripples.position = Vector2(970,700)
	world.add_child(ripples)
	ripples.draw.connect(_draw_water)


func is_walkable(point: Vector2, padding := 20.0) -> bool:
	if not Geometry2D.is_point_in_polygon(point,FLOOR):
		return false
	for polygon in [FLOOR]+blockers:
		if polygon!=FLOOR and Geometry2D.is_point_in_polygon(point,polygon):
			return false
		for i in polygon.size():
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,polygon[i],polygon[(i+1)%polygon.size()]))<padding:
				return false
	return true


func _build_navigation() -> void:
	navigation.region = Rect2i(0,0,60,34)
	navigation.cell_size = Vector2(32,32)
	navigation.offset = Vector2(16,16)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in 60:
		for y in 34:
			var cell := Vector2i(x,y)
			navigation.set_point_solid(cell,not is_walkable(navigation.get_point_position(cell)))


func _nav_cell(point: Vector2) -> Vector2i:
	var center := Vector2i((point-Vector2(16,16))/32)
	var best := Vector2i(-1,-1)
	var best_distance := INF
	for x in range(maxi(0,center.x-5),mini(60,center.x+6)):
		for y in range(maxi(0,center.y-5),mini(34,center.y+6)):
			var cell := Vector2i(x,y)
			if not navigation.is_point_solid(cell):
				var distance := navigation.get_point_position(cell).distance_squared_to(point)
				if distance<best_distance:
					best_distance = distance
					best = cell
	return best


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := _nav_cell(from)
	var end := _nav_cell(to)
	if start.x<0 or end.x<0:
		return PackedVector2Array()
	return navigation.get_point_path(start,end)


func clear_line(from: Vector2, to: Vector2, exclude: Array[RID] = []) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(from,to,1,exclude)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _physics_process(_delta: float) -> void:
	if paused or not is_instance_valid(player):
		return
	nearest = ""
	var distance := 150.0
	for id in interactables:
		if combat_active and id=="warden":
			continue
		var item: Dictionary = interactables[id]
		var candidate: float = Actor.ground_vector(item["at"]-player.position).length()
		var quest_target: bool = id==QUEST_TARGETS[mini(quest_stage,5)]
		if candidate<150 and (candidate<distance or quest_target):
			var excluded: Array[RID] = []
			if item.has("body"):
				excluded.append(item["body"].get_rid())
			if clear_line(player.position,item["at"],excluded):
				distance = candidate
				nearest = id
				if quest_target:
					break


func interact(id := "") -> void:
	if paused or combat_active:
		return
	if id.is_empty():
		id = nearest
	if id.is_empty():
		return
	var lines := {
		"baker":"The oven's warm and the square is waking up. Good to see you!",
		"elder":"A quiet bench, a warm breeze. A fine place to spend the morning.",
		"grocer":"Fresh apples from the valley. Even the wardens stop by for a bite.",
		"courier":"One square, a hundred stories. That's what I love about my rounds.",
		"bookseller":"This town was built around its spring. Some say the water remembers every wish.",
		"postbox":"A sturdy red postbox. Today's collection hasn't gone yet."
	}
	if id=="warden":
		start_challenge()
		return
	var text: String = lines.get(id,"")
	if quest_stage<5 and id==QUEST_TARGETS[quest_stage]:
		text = [
			"Could you take this warm loaf to Elder Mallow? She's waiting by the bench. Bread collected!",
			"What a lovely surprise! Thank you. Moss has a fruit basket for Pip; could you help him next?",
			"Here's Pip's basket. You'll find the little courier near the red postbox. Fruit collected!",
			"My lunch! You're a lifesaver. Would you post this last letter for me? Letter collected!",
			"The letter slips into the box. Morning rounds complete! Everyone sends their thanks."
		][quest_stage]
		quest_stage += 1
	_update_hud()
	_say(interactables[id]["name"],text)


func start_challenge() -> void:
	if combat_active:
		return
	for dog in dogs:
		if is_instance_valid(dog):
			dog.queue_free()
	dogs.clear()
	combat_active = true
	player.health = player.maximum_health
	player.active = true
	player.grace = 1.5
	victory_count = 0
	var homes := [Vector2(600,975),Vector2(1125,980),Vector2(1240,820)]
	for home in homes:
		var dog = _actor(false,home)
		dog.enemy = true
		dog.health = 3
		dog.maximum_health = 3
		dog.cooldown = 1.5
		dogs.append(dog)
	_say("Bram · Friendly sparring", "Three wardens, three hits each. Space or left click to swing; keep moving. Red rings warn of a strike!")
	_update_hud()


func actor_yielded(actor) -> void:
	if actor==player:
		_end_challenge(false)
		return
	victory_count += 1
	var tween := create_tween()
	tween.tween_property(actor,"modulate:a",0.0,0.5)
	if victory_count>=dogs.size():
		_end_challenge(true)
	_update_hud()


func _end_challenge(won: bool) -> void:
	combat_active = false
	challenge_won = challenge_won or won
	for dog in dogs:
		dog.enemy = false
		dog.active = false
		dog.velocity = Vector2.ZERO
		var tween := create_tween()
		tween.tween_property(dog,"modulate:a",0.0,0.5)
	player.active = true
	player.health = player.maximum_health
	player.grace = 2.0
	player.knockback = Vector2.ZERO
	player.swing = 0
	if not won:
		player.position = spawn
		player.reset_physics_interpolation()
	_say("Bram · Warden", "Well played! The square has a new champion. Speak to me for another round." if won else "Good practice! Take a breath — your deliveries are safe. Speak to me whenever you'd like to try again.")
	_update_hud()


func advance_time() -> void:
	clock_target = floorf(clock)+1.0


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if not paused:
		elapsed += delta
		if clock_target>=0:
			clock = move_toward(clock,clock_target,delta/2.0)
			if is_equal_approx(clock,clock_target):
				clock = fposmod(clock,4.0)
				clock_target = -1.0
		elif auto_clock:
			clock = fposmod(clock+delta/60.0,4.0)
		dialogue_left = maxf(0,dialogue_left-delta)
		talk_panel.visible = dialogue_left>0
		ripples.queue_redraw()
		_update_lighting()
		_update_prompt()
	hud_timer += delta
	if hud_timer>=0.25:
		hud_timer = 0
		_update_hud()


func _update_lighting() -> void:
	var base := int(floorf(clock))%4
	var next := (base+1)%4
	var weight := smoothstep(0.35,1.0,fposmod(clock,1.0))
	for i in 4:
		backgrounds[i].visible = i==base or (i==next and weight>0)
		backgrounds[i].modulate.a = weight if i==next else 1.0
		# The next plate must draw over the base, including Night -> Dawn.
		backgrounds[i].z_index = -9 if i==next else -10
	actor_tint = TINTS[base].lerp(TINTS[next],weight)
	for piece in pieces:
		piece.modulate = actor_tint
	var night := clampf((1.0-actor_tint.g)*2.0,0.0,1.0)
	ripples.modulate = Color(1,1,1,1.0-night*0.55)
	var warden = interactables["warden"]["anchor"]
	warden.sprite.modulate = actor_tint


func _draw_water() -> void:
	for i in 3:
		var progress := fposmod(elapsed*0.25+i/3.0,1.0)
		ripples.draw_set_transform(Vector2(0,-60),0,Vector2(1,0.28))
		ripples.draw_arc(Vector2.ZERO,25+progress*70,0.1,2.9,42,Color(0.8,0.97,1,(1-progress)*0.26),1.5,true)
	ripples.draw_set_transform(Vector2.ZERO)


func _panel(at: Vector2, size: Vector2, parent: Node, color := Color("183533")) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color,0.93)
	style.border_color = Color(0.88,0.77,0.51,0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0,0,0,0.12)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	return panel


func _label(text: String, at: Vector2, font_size: int, parent: Node, width := 0.0, color := Color("fff1d2")) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width>0:
		label.size.x = width
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var title := _panel(Vector2(28,25),Vector2(390,125),ui)
	_label("PROJECT KINGDOM",Vector2(20,10),16,title,0,Color("d8c38e"))
	_label("Garden Square",Vector2(20,32),32,title)
	time_label = _label("",Vector2(20,81),18,title)
	var tasks := _panel(Vector2(1380,25),Vector2(512,152),ui)
	_label("MORNING ROUNDS",Vector2(20,12),16,tasks,0,Color("d8c38e"))
	objective = _label("",Vector2(20,42),21,tasks,472)
	status_label = _label("",Vector2(20,113),16,tasks)
	var controls := _panel(Vector2(28,1006),Vector2(1864,50),ui)
	_label("WASD / Arrows  Walk     Shift  Run     E  Talk / Use     Space / Left click  Swing     Right click  Walk to point",Vector2(18,12),18,controls)
	_label("T  Time     Esc  Pause     F11  Full screen",Vector2(1430,12),17,controls)
	talk_panel = _panel(Vector2(470,830),Vector2(980,144),ui)
	talk_name = _label("",Vector2(24,15),20,talk_panel,930,Color("f4cd7b"))
	talk_text = _label("",Vector2(24,49),21,talk_panel,930)
	prompt = _panel(Vector2.ZERO,Vector2(280,41),ui)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_text = _label("",Vector2(13,7),18,prompt)
	quest_marker = _label("▼",Vector2.ZERO,34,ui,0,Color("ffdb85"))
	quest_marker.add_theme_color_override("font_shadow_color",Color("453b2a"))
	quest_marker.add_theme_constant_override("shadow_offset_y",2)
	quest_marker.add_theme_color_override("font_outline_color",Color("453b2a"))
	quest_marker.add_theme_constant_override("outline_size",5)
	pause_overlay = Control.new()
	pause_overlay.size = Vector2(SIZE)
	ui.add_child(pause_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.04,0.09,0.09,0.65)
	shade.size = Vector2(SIZE)
	pause_overlay.add_child(shade)
	var menu := _panel(Vector2(650,350),Vector2(620,340),pause_overlay)
	_label("A moment in the square",Vector2(42,35),32,menu)
	_label("Esc  Resume\nR  Restart the demo\nF11  Toggle full screen\nClose the window to quit",Vector2(42,105),24,menu)
	pause_overlay.visible = false


func _say(speaker: String, text: String) -> void:
	talk_name.text = speaker
	talk_text.text = text
	dialogue_left = 7.0
	talk_panel.visible = true


func _update_hud() -> void:
	objective.text = "Spar with the three wardens. Watch for red strike rings." if combat_active else OBJECTIVES[quest_stage]
	if combat_active:
		status_label.text = "Sparring  %d / 3 yielded    Health  %d / %d" % [victory_count,player.health,player.maximum_health]
	else:
		status_label.text = "%d / 5 errands%s" % [mini(quest_stage,5),"   ·   Sparring champion" if challenge_won else "   ·   E near Bram to spar"]
	var base := int(floorf(clock))%4
	time_label.text = "%s  ·  %d FPS  ·  T to change time" % [TIMES[base],Engine.get_frames_per_second()]


func _update_prompt() -> void:
	prompt.visible = not nearest.is_empty() and not combat_active
	if prompt.visible:
		var offset_y := -165.0 if dialogue_left>0 else 25.0
		prompt.position = (player.global_position+Vector2(-140,offset_y)).clamp(Vector2(15,170),Vector2(1620,940))
		prompt_text.text = "E   "+interactables[nearest]["name"]
	quest_marker.visible = not combat_active
	if quest_marker.visible:
		var target: Dictionary = interactables[QUEST_TARGETS[mini(quest_stage,5)]]
		quest_marker.position = target["at"]+Vector2(-14,-target["height"]-38+sin(elapsed*2.3)*5)


func set_paused(value: bool) -> void:
	paused = value
	pause_overlay.visible = value
	for actor in [player,interactables["warden"]["anchor"]]+dogs:
		if is_instance_valid(actor):
			actor.sprite.speed_scale = 0.0 if value else 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("hub_pause"):
		set_paused(not paused)
	elif event.is_action_pressed("hub_restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("hub_fullscreen"):
		get_window().mode = Window.MODE_WINDOWED if get_window().mode==Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	elif not paused:
		if event.is_action_pressed("hub_interact"):
			interact()
		elif event.is_action_pressed("hub_time"):
			advance_time()
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index==MOUSE_BUTTON_LEFT:
				player.try_attack(get_global_mouse_position()-player.position)
			elif event.button_index==MOUSE_BUTTON_RIGHT:
				var goal := get_global_mouse_position()
				if is_walkable(goal,16):
					player.route = find_path(player.position,goal)
					dialogue_left = 0


func _capture() -> void:
	await get_tree().create_timer(3.0).timeout
	dialogue_left = 0
	talk_panel.hide()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT+"previews"))
	var filename := "night.png" if "--night" in OS.get_cmdline_user_args() else "playable.png"
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/"+filename))
	print("Playable hub captured: ",filename)
	if "--quit-after-capture" in OS.get_cmdline_user_args():
		get_tree().quit()
