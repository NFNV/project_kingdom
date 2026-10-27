extends Node2D

const ART := "res://experiments/anime_hub_assets_v06/"
const ROOT := "res://experiments/anime_hub_demo_v07/"
const Actor := preload("res://experiments/anime_hub_demo_v07/tools/actor.gd")
const Bandit := preload("res://experiments/anime_hub_demo_v07/tools/bandit.gd")
const Map := preload("res://experiments/anime_hub_demo_v07/tools/woodland_map.gd")
const Resident := preload("res://experiments/anime_hub_demo_v07/tools/resident_motion.gd")
const Human := preload("res://experiments/anime_hub_demo_v07/tools/human_resident.gd")
const HUMAN_ART := "res://experiments/anime_hub_assets_v08_humans/"
const Bakery := preload("res://experiments/anime_hub_demo_v07/tools/bakery_room.gd")
const FountainFX := preload("res://experiments/anime_hub_demo_v07/tools/fountain_fx.gd")
const Hud := preload("res://experiments/anime_hub_demo_v07/tools/hud.gd")
const Style := preload("res://experiments/anime_hub_demo_v07/tools/art_style.gd")
const Soundscape := preload("res://experiments/anime_hub_demo_v07/tools/soundscape.gd")
const GameState := preload("res://experiments/anime_hub_demo_v07/tools/game_state.gd")
const SaveStore := preload("res://experiments/anime_hub_demo_v07/tools/save_store.gd")
const Loot := preload("res://experiments/anime_hub_demo_v07/tools/loot_drop.gd")
var state: Node
var saves := SaveStore.new()
var save_path := SaveStore.DEFAULT_PATH
var backpack_open := false
const CYCLE_SECONDS := 1200.0
const SIZE := Vector2i(1920,1080)
const TIMES := ["Dawn","Noon","Dusk","Night"]
const TINTS := Style.LIGHTING
var FLOOR := PackedVector2Array([Vector2(760,465),Vector2(1150,460),Vector2(1315,570),Vector2(1590,735),Vector2(1360,835),Vector2(1460,990),Vector2(1270,1060),Vector2(410,1060),Vector2(500,925),Vector2(370,770),Vector2(350,720),Vector2(290,695),Vector2(245,635),Vector2(245,555),Vector2(330,550),Vector2(380,610),Vector2(465,630),Vector2(650,580)])
var town_floor := FLOOR.duplicate()
const OBJECTIVES := [
	"Visit Pippa at the blue bakery cart.",
	"Take the warm bread to Elder Mallow by the bench.",
	"Pick up a fruit basket from Moss at the green stall.",
	"Bring the fruit basket to Pip, the courier.",
	"Post Pip's letter in the red postbox.",
	"Morning rounds complete! Explore Mosswood through the southeast gate."
]
const QUEST_TARGETS := ["baker","elder","grocer","courier","postbox","warden"]
var zone := "town"
var zone_root: Node2D
var exits: Dictionary = {}
var near_exit := ""
var discoveries: Dictionary:
	get: return state.discoveries
var transitioning := false
var travel_cooldown := 0.0
var peaceful_mode := true
var forest_defeated: Dictionary:
	get: return state.forest_defeated
var forest_recoveries: int:
	get: return state.forest_recoveries
	set(value): state.forest_recoveries = value
var district_places: Dictionary:
	get: return state.district_places
var world_size := SIZE
var trail_effects: Node2D
var catalog: Dictionary
var world: Node2D
var player: CharacterBody2D
var dogs: Array = []
var residents: Array[Node2D] = []
var humans: Array[Node2D] = []
var human_catalog: Dictionary
var pieces: Array[CanvasItem] = []
var occluders: Array[Sprite2D] = []
var interactables: Dictionary = {}
var blockers: Array[PackedVector2Array] = []
var navigation := AStarGrid2D.new()
var backgrounds: Array[Sprite2D] = []
var actor_tint := Color.WHITE
var audio: Node2D
var ui
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
var quest_stage: int:
	get: return state.delivery_stage
	set(value): state.delivery_stage = value
var nearest := ""
var clock: float:
	get: return state.clock
	set(value): state.clock = value
var clock_target := -1.0
var auto_clock := true
var dialogue_left := 0.0
var elapsed := 0.0
var hud_timer := 0.0
var spawn := Vector2(840,905)
var ripples: Node2D
var victory_count := 0
var camera: Camera2D
var bakery_room: Node2D
var shopping := false
var coins: int:
	get: return state.coins
	set(value): state.coins = value
var inventory: Dictionary:
	get: return state.item_counts()
const GOODS := [
	{"id":"bread","name":"Warm sourdough","description":"Restore 2 hearts. H to eat a loaf on the trail.","price":2},
	{"id":"tea","name":"Meadow tea","description":"Restore 2 hearts and refresh Wind Slash.","price":3},
	{"id":"honey","name":"Valley honey","description":"Restore 3 hearts. Wildflowers from Mosswood.","price":4}
]


func _ready() -> void:
	get_window().title = "Project Kingdom — Garden Square"
	get_window().content_scale_size = SIZE
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().size = Vector2i(1280,720)
	Engine.max_fps = 60
	if OS.get_name()=="macOS" and DisplayServer.get_name()!="headless":
		# The engine cap provides pacing. Metal VSync showed long waits during
		# focus changes on the development Mac; keep gameplay responsive there.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.physics_ticks_per_second = 60
	get_tree().physics_interpolation = true
	state = GameState.new()
	state.name = "Journey"
	add_child(state)
	audio = Soundscape.new()
	audio.hub = self
	add_child(audio)
	_install_input()
	catalog = JSON.parse_string(FileAccess.get_file_as_string(ART+"catalog.json"))["assets"]
	human_catalog = JSON.parse_string(FileAccess.get_file_as_string(HUMAN_ART+"catalog.json"))["assets"]
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_load_zone("town","start")
	_build_ui()
	_update_lighting()
	_update_hud()
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_move_to_foreground()
	_say("Welcome to Garden Square", "Speak to Bram by the fountain for a forest quest. I opens your satchel; H eats bread. F5 saves your journey, F9 continues a saved one. The southeast gate leads to Mosswood.")
	if "--night" in OS.get_cmdline_user_args():
		clock = 3.0
	if "--bakery" in OS.get_cmdline_user_args():
		_load_zone("bakery","town")
	elif "--fountain" in OS.get_cmdline_user_args():
		player.position = Vector2(970,810)
		player.reset_physics_interpolation()
		camera.reset_smoothing()
		camera.force_update_scroll()
	elif "--trail" in OS.get_cmdline_user_args():
		_load_zone("trail","town")
	elif "--district" in OS.get_cmdline_user_args():
		_load_zone("district","town")
		_say("Welcome to Northgate", "The northern town opens into streets, wide sidewalks, Sunstone Plaza and Linden Park. E to chat; the southern avenue returns to Garden Square.")
	elif "--wilds" in OS.get_cmdline_user_args():
		_load_zone("wilds","river")
		_say("Briarwood Wilds", "Sword raiders slash and lunge; club maulers sweep wide. Sidestep red lanes or move behind amber warnings. Space / click to strike; Q fires Wind Slash. The west trail leads to safety.")
	elif "--river" in OS.get_cmdline_user_args():
		_load_zone("river","trail")
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()
	if "--continue" in OS.get_cmdline_user_args():
		load_game.call_deferred()


func _install_input() -> void:
	var bindings := {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"run":[KEY_SHIFT],"attack":[KEY_SPACE],"skill":[KEY_Q],"interact":[KEY_E],"time":[KEY_T],"pause":[KEY_ESCAPE],"restart":[KEY_R],"fullscreen":[KEY_F11],"journal":[KEY_J],"debug":[KEY_F3],"mute":[KEY_M],"bag":[KEY_I],"food":[KEY_H],"save":[KEY_F5],"load":[KEY_F9]}
	for action in bindings:
		var name := "hub_"+str(action)
		if not InputMap.has_action(name):
			InputMap.add_action(name)
			for key in bindings[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(name,event)


func zone_title() -> String:
	return Map.NAMES[zone]


func _load_zone(destination: String, entry: String) -> void:
	if is_instance_valid(player):
		player.get_parent().remove_child(player)
	if is_instance_valid(zone_root):
		remove_child(zone_root)
		zone_root.queue_free()
	shopping = false
	if is_instance_valid(ui):
		ui.merchant.hide()
	zone = destination
	world_size = Map.world_size(zone)
	peaceful_mode = zone!="wilds"
	combat_active = false
	backgrounds.clear()
	pieces.clear()
	occluders.clear()
	dogs.clear()
	residents.clear()
	humans.clear()
	interactables.clear()
	blockers.clear()
	ripples = null
	trail_effects = null
	bakery_room = null
	nearest = ""
	near_exit = ""
	zone_root = Node2D.new()
	add_child(zone_root)
	var files: Array = []
	if zone=="town":
		FLOOR = town_floor.duplicate()
		for time in TIMES:
			files.append(ART+"backgrounds/plaza_"+time.to_lower()+".png")
	elif zone=="bakery":
		FLOOR = Bakery.floor_polygon()
	elif zone=="district":
		FLOOR = Map.District.floor_polygon()
	elif zone=="wilds":
		FLOOR = Map.floor_for(zone)
		files = [ROOT+"assets/forest/briarwood_ground.png"]
	else:
		FLOOR = Map.floor_for(zone)
		var id := "mosswood" if zone=="trail" else "riverbend"
		files = [ROOT+"assets/forest/"+id+"_day.png",ROOT+"assets/forest/"+id+"_night.png"]
	for file in files:
		var plate := Sprite2D.new()
		plate.texture = load(file)
		plate.centered = false
		plate.scale = Vector2(world_size)/plate.texture.get_size()
		plate.z_index = -10+backgrounds.size()
		if zone=="wilds":
			var ground_material := ShaderMaterial.new()
			ground_material.shader = load(ROOT+"assets/forest/forest_floor.gdshader")
			plate.material = ground_material
		zone_root.add_child(plate)
		backgrounds.append(plate)
	world = Node2D.new()
	world.y_sort_enabled = true
	zone_root.add_child(world)
	if zone=="town":
		_build_plaza()
	elif zone=="bakery":
		_build_bakery()
	elif zone=="district":
		Map.District.build(self)
	elif zone=="wilds":
		Map.Wilds.build(self)
		for id in state.pending_loot:
			_add_loot(id)
	else:
		_build_forest()
	exits = Map.exits_for(zone)
	_build_navigation()
	if not is_instance_valid(player):
		player = _actor(true,Map.arrival(zone,entry))
	else:
		world.add_child(player)
		player.position = Map.arrival(zone,entry)
	player.active = true
	player.collision_layer = 2
	player.grace = 1.5 if zone=="wilds" else 0.0
	player.cooldown = 0
	player.swing = 0
	player.attack_kind = "light"
	player.attack_duration = Actor.Timing.LIGHT_DURATION
	player.skill_buffer = 0
	player.light_buffer = 0
	player.buffered_aim = Vector2.ZERO
	player.skill_launched = false
	player.windup = 0
	player.knockback = Vector2.ZERO
	player.sprite.modulate.a = 1
	player.intent = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.route.clear()
	player.stop_motion()
	player.reset_physics_interpolation()
	if not is_instance_valid(camera):
		camera = Camera2D.new()
		camera.name = "FollowCamera"
		camera.zoom = Vector2(1.5,1.5)
		camera.position = Vector2(0,-55)
		camera.position_smoothing_enabled = false
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = SIZE.x
		camera.limit_bottom = SIZE.y
		player.add_child(camera)
	camera.limit_right = world_size.x
	camera.limit_bottom = world_size.y
	camera.make_current()
	camera.reset_physics_interpolation()
	camera.reset_smoothing()
	camera.force_update_scroll()
	travel_cooldown = 1.2
	var markings := Node2D.new()
	markings.z_index = -1
	zone_root.add_child(markings)
	markings.draw.connect(_draw_exit_marks.bind(markings))
	markings.queue_redraw()
	_update_lighting()
	_update_hud()
	get_window().title = "Project Kingdom — "+zone_title()
	audio.bind_player(player)
	audio.enter_zone(zone)


func _build_forest() -> void:
	_solid(FLOOR,true)
	interactables = Map.landmarks(zone)
	if zone=="trail":
		_solid(_ellipse(Map.point(1100,540),Map.point(110,70)))
		_solid(_ellipse(Map.point(456,453),Map.point(47,37)))
		_piece("elm_tree",Vector2(-10,1040),350)
		_piece("willow_tree",Vector2(1970,765),300)
	else:
		_solid(_ellipse(Map.point(1085,540),Map.point(93,65)))
		_piece("elm_tree",Vector2(1910,1075),330)
		_piece("willow_tree",Vector2(-10,900),290)
	trail_effects = Node2D.new()
	trail_effects.z_index = 2
	zone_root.add_child(trail_effects)
	trail_effects.draw.connect(_draw_forest_air)


func _draw_exit_marks(node: Node2D) -> void:
	for id in exits:
		var at: Vector2 = exits[id]["at"]
		node.draw_set_transform(at,0,Vector2(1,.48))
		node.draw_arc(Vector2.ZERO,31,0,TAU,32,Color(.13,.25,.17,.7),6,true)
		node.draw_arc(Vector2.ZERO,31,0,TAU,32,Color(1,.86,.5,.95),2,true)
		node.draw_set_transform(Vector2.ZERO)
		var arrow := Vector2(1,.65).normalized() if id in ["southeast","river","wilds"] else Vector2(-1,-.2).normalized()
		if zone=="wilds":
			arrow = Vector2(-1,0)
		elif id=="wilds":
			arrow = Vector2(1,-.65).normalized()
		elif id=="north":
			arrow = Vector2(0,-1)
		elif zone=="district":
			arrow = Vector2(0,1)
		node.draw_line(at-arrow*14,at+arrow*16,Color("ffedb6"),3,true)
		node.draw_line(at+arrow*16,at+arrow.rotated(2.6)*13,Color("ffedb6"),3,true)
		node.draw_line(at+arrow*16,at+arrow.rotated(-2.6)*13,Color("ffedb6"),3,true)
		var sign := StyleBoxFlat.new()
		sign.bg_color = Color("294236")
		sign.border_color = Color("c4ab72")
		sign.set_border_width_all(1)
		sign.set_corner_radius_all(5)
		var label_y := -150.0 if id=="bakery" else -57.0
		node.draw_style_box(sign,Rect2(at+Vector2(-82,label_y),Vector2(164,29)))
		node.draw_string(ThemeDB.fallback_font,at+Vector2(-76,label_y+21),exits[id].get("sign","Mosswood" if zone=="town" else ("Garden Square" if id=="town" else ("Riverbend" if id=="river" else "Mosswood"))),HORIZONTAL_ALIGNMENT_CENTER,152,16,Color("fff1cb"))


func _draw_forest_air() -> void:
	if not is_instance_valid(trail_effects):
		return
	var night := clampf(1.0-actor_tint.g,0,1)
	for i in (75 if zone=="wilds" else 18):
		var at := Vector2(fposmod(i*173.7+elapsed*(7+i%3),world_size.x-80)+40,120+fposmod(i*167.3,world_size.y-240)+sin(elapsed*.7+i)*13)
		if night>.25:
			var alpha := (.35+.3*sin(elapsed*1.6+i))*night
			trail_effects.draw_circle(at,5,Color(.9,1,.4,alpha*.14))
			trail_effects.draw_circle(at,1.6,Color(.95,1,.52,alpha))
		else:
			trail_effects.draw_set_transform(at,sin(elapsed*.5+i)*.7,Vector2(1,.4))
			trail_effects.draw_circle(Vector2.ZERO,3,Color(.81,.82,.38,.38))
	trail_effects.draw_set_transform(Vector2.ZERO)


func request_travel(exit_id: String) -> void:
	if paused or shopping or transitioning or not exits.has(exit_id):
		return
	if exit_id=="bakery" or zone=="bakery":
		audio.play_event("door",player.position,-5)
	transitioning = true
	var target: Dictionary = exits[exit_id]
	_travel.call_deferred(target["to"],target["entry"])


func _travel(destination: String, entry: String) -> void:
	var tween := create_tween()
	tween.tween_property(ui.fade,"modulate:a",1.0,.22)
	await tween.finished
	_load_zone(destination,entry)
	dialogue_left = 0
	talk_panel.hide()
	if destination=="wilds":
		_say("Briarwood Wilds", "Dog bandits guard four woodland clearings. Space or left click to attack; Q fires Wind Slash. Dodge the red warning circles. Follow the western trail to retreat.")
	await get_tree().physics_frame
	tween = create_tween()
	tween.tween_property(ui.fade,"modulate:a",0.0,.28)
	await tween.finished
	transitioning = false


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
		occluders.append(sprite)
		sprite.material = load(ART+"godot/"+("elm_wind.tres" if id=="elm_tree" else "willow_wind.tres"))
	return anchor


func _actor(controlled: bool, at: Vector2, bandit_role := ""):
	var actor := CharacterBody2D.new()
	actor.set_script(Bandit if not bandit_role.is_empty() else Actor)
	if not bandit_role.is_empty():
		actor.variant = bandit_role
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
	zone_root.add_child(body)
	return body


func _animated_resident(id: String, asset: String, at: Vector2, height: float) -> Node2D:
	var anchor := Resident.new()
	anchor.hub = self
	anchor.asset = asset
	anchor.resident_id = id
	anchor.height = height*Actor.ANIMAL_SCALE
	anchor.position = at
	world.add_child(anchor)
	residents.append(anchor)
	pieces.append(anchor.sprite)
	return anchor


func _resident(id: String, name_text: String, asset: String, at: Vector2, height := 108.0) -> void:
	var anchor := _animated_resident(id,asset,at,height)
	var body := _solid(_ellipse(at+Vector2(0,-5),Vector2(21,13)))
	interactables[id] = {"name":name_text,"at":at,"anchor":anchor,"body":body,"height":anchor.height}


func _human_resident(id: String, name_text: String, asset: String, at: Vector2, facing: String) -> void:
	var human := Human.new()
	human.name = id
	human.hub = self
	human.asset = asset
	human.resident_id = id
	human.data = human_catalog[asset]
	human.position = at
	human.facing_direction = facing
	world.add_child(human)
	humans.append(human)
	pieces.append(human.sprite)
	var body := _solid(_ellipse(at+Vector2(0,-5),Vector2(22,14)))
	interactables[id] = {"name":name_text,"at":at,"anchor":human,"body":body,"height":human.height}


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
	_human_resident("rhea","Rhea · Wayfarer","human_wayfarer",Vector2(1085,980),"nw")
	_human_resident("alden","Captain Alden · Town Warden","human_warden",Vector2(1185,575),"sw")
	_human_resident("iris","Iris · Herbalist","human_herbalist",Vector2(730,940),"se")
	_human_resident("tomas","Tomas · Blacksmith","human_smith",Vector2(740,760),"se")
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
	for item in [["warden","Bram · Warden",Vector2(1150,850)],["guard_west","Oak · Warden",Vector2(760,545)],["guard_east","Fern · Warden",Vector2(1300,910)]]:
		var warden = _actor(false,item[2])
		warden.resident_id = item[0]
		warden.patrol_wait = 1.0+dogs.size()*1.7
		warden.patrol = {
			"warden":PackedVector2Array([Vector2(1150,850),Vector2(1040,925),Vector2(1160,955),Vector2(1210,860)]),
			"guard_west":PackedVector2Array([Vector2(760,545),Vector2(870,545),Vector2(820,590)]),
			"guard_east":PackedVector2Array([Vector2(1300,910),Vector2(1360,945),Vector2(1260,975)])
		}[item[0]]
		dogs.append(warden)
		interactables[item[0]] = {"name":item[1],"at":warden.position,"anchor":warden,"height":warden.sprite.display_height}
	# Animated water highlights are drawn over the painted water, using native 2D.
	ripples = FountainFX.new()
	ripples.hub = self
	ripples.position = Vector2(970,700)
	world.add_child(ripples)


func _furniture(id: String, at: Vector2, height: float) -> Node2D:
	var anchor := Node2D.new()
	anchor.name = id
	anchor.position = at
	world.add_child(anchor)
	var sprite := Sprite2D.new()
	sprite.texture = load(ROOT+"assets/bakery/"+id+".tres")
	sprite.centered = false
	sprite.offset = Vector2(-sprite.texture.get_width()/2.0,-sprite.texture.get_height())
	sprite.scale = Vector2.ONE*height/sprite.texture.get_height()
	anchor.add_child(sprite)
	pieces.append(sprite)
	return anchor


func _build_bakery() -> void:
	bakery_room = Bakery.new()
	bakery_room.hub = self
	bakery_room.z_index = -10
	zone_root.add_child(bakery_room)
	_solid(FLOOR,true)
	_furniture("bakery_shelf",Bakery.iso(.9,2.2),230)
	_solid(_ellipse(Bakery.iso(.9,2.2)+Vector2(0,-15),Vector2(88,31)))
	_furniture("bakery_oven",Bakery.iso(6.0,.9),205)
	_solid(PackedVector2Array([Vector2(1264,454),Vector2(1361,512),Vector2(1454,478),Vector2(1367,418)]))
	var vendor_at := Bakery.iso(4.3,1.55)
	var vendor := _animated_resident("shop_vendor","cat_baker",vendor_at,118)
	vendor.face_towards(Bakery.iso(4.5,4.2))
	var body := _solid(_ellipse(vendor_at,Vector2(20,12)))
	interactables["shop_vendor"] = {"name":"Clover · Bakery keeper","at":Bakery.iso(4.5,4.2),"anchor":vendor,"body":body,"height":vendor.height}
	_furniture("bakery_counter",Bakery.iso(4.6,3.25),186)
	_solid(PackedVector2Array([Vector2(939,464),Vector2(1155,551),Vector2(1204,504),Vector2(992,414)]))
	_furniture("bakery_table",Bakery.iso(2.5,5.8),150)
	_solid(_ellipse(Bakery.iso(2.5,5.8)+Vector2(0,-12),Vector2(94,37)))
	trail_effects = Node2D.new()
	trail_effects.z_index = 2
	zone_root.add_child(trail_effects)
	trail_effects.draw.connect(bakery_room.draw_air.bind(trail_effects))


func open_shop() -> void:
	shopping = true
	player.stop_motion()
	interactables["shop_vendor"]["anchor"].greet()
	dialogue_left = 0
	talk_panel.hide()
	prompt.hide()
	ui.merchant.show()
	ui.refresh_shop("Welcome in! Everything was baked this morning.")


func close_shop() -> void:
	shopping = false
	ui.merchant.hide()
	audio.play_event("ui_open",player.position,-12,.80)


func buy(index: int) -> bool:
	if not shopping or zone!="bakery" or index<0 or index>=GOODS.size():
		return false
	var product: Dictionary = GOODS[index]
	if coins<int(product["price"]):
		audio.play_event("ui_error",player.position,-10)
		ui.refresh_shop("A little short of coins for that one. Try something smaller.")
		return false
	if not state.add_item(product.id):
		ui.refresh_shop("Your satchel already holds plenty of that item.")
		return false
	coins -= int(product["price"])
	audio.play_event("ui_confirm",player.position,-8)
	ui.refresh_shop("%s tucked into your satchel. Thank you!" % product["name"])
	_update_hud()
	return true


func _add_loot(id: String) -> void:
	var key := "loot:"+id
	if interactables.has(key):
		return
	var coords: Array = state.pending_loot[id].position
	var at := Vector2(coords[0],coords[1])
	var drop := Loot.new()
	drop.hub = self
	drop.position = at
	world.add_child(drop)
	interactables[key] = {"name":"Collect bandit badge","at":at,"height":18.0,"anchor":drop}


func collect_loot(id: String) -> bool:
	var key := "loot:"+id
	if paused or transitioning or zone!="wilds" or not player.active or not interactables.has(key):
		return false
	if Actor.ground_vector(interactables[key].at-player.position).length()>150 or not clear_line(player.position,interactables[key].at):
		return false
	if not state.collect_loot(id):
		return false
	interactables[key].anchor.queue_free()
	interactables.erase(key)
	nearest = ""
	audio.play_event("coin",player.position,-9)
	ui.show_notice("Bandit badge collected  ·  %d in your satchel" % state.count("bandit_badge"))
	_update_hud()
	return true


func toggle_backpack() -> void:
	if transitioning or shopping or not player.active:
		return
	backpack_open = not backpack_open
	set_paused(backpack_open)
	if backpack_open:
		player.stop_motion()
		pause_overlay.hide()
	ui.satchel.visible = backpack_open
	ui.refresh_satchel()


func use_item(id: String) -> bool:
	if transitioning or shopping or (paused and not backpack_open) or not player.active or player.swing>0 or not state.definitions.has(id) or state.count(id)<=0:
		return false
	var item: Dictionary = state.definitions[id]
	if item.get("kind")!="food":
		return false
	var refresh: bool = bool(item.get("refresh_skill",false)) and player.skill_cooldown>0
	if player.health>=player.maximum_health and not refresh:
		ui.show_notice("You are already rested. Save that for the trail.")
		return false
	if not state.remove_item(id):
		return false
	player.health = mini(player.maximum_health,player.health+int(item.heal))
	if refresh:
		player.skill_cooldown = 0
	ui.show_notice("%s  ·  %d / %d hearts" % [item.name,player.health,player.maximum_health])
	audio.play_event("ui_confirm",player.position,-8)
	ui.refresh_satchel()
	_update_hud()
	return true


func toggle_charm() -> void:
	if not backpack_open:
		return
	if state.charm.get_item()!=null:
		state.unequip_charm()
	else:
		state.equip_charm()
	ui.refresh_satchel()
	_update_hud()


func make_save_document() -> Dictionary:
	return {"format":"project_kingdom","version":SaveStore.VERSION,"state":state.snapshot(),
		"player":{"zone":zone,"position":[player.position.x,player.position.y],"health":player.health,
		"facing":[player.facing.x,player.facing.y],"skill_cooldown":player.skill_cooldown}}


func save_game() -> bool:
	if transitioning or not player.active or player.swing>0 or player.windup>0:
		ui.show_notice("Finish your action before saving.")
		return false
	var result := saves.write_document(make_save_document(),save_path)
	ui.show_notice("Journey saved  ·  F9 to continue" if result else saves.last_error)
	ui.refresh_save_controls()
	return result


func load_game() -> bool:
	if transitioning:
		return false
	var document := saves.load_document(save_path)
	if document.is_empty():
		ui.show_notice(saves.last_error)
		return false
	backpack_open = false
	ui.satchel.hide()
	set_paused(false)
	state.restore(document.state,int(document.player.health))
	_load_zone(document.player.zone,"start")
	var coords: Array = document.player.position
	var at := Vector2(coords[0],coords[1])
	if not is_walkable(at,14):
		# An NPC may now occupy the saved spot, or geometry may have changed.
		var cell := _nav_cell(at)
		at = navigation.get_point_position(cell) if cell.x>=0 else Map.arrival(zone,"start")
	player.position = at
	player.facing = Vector2(document.player.facing[0],document.player.facing[1]).normalized()
	player.sprite.tick(0,0,player.facing)
	player.skill_cooldown = float(document.player.skill_cooldown)
	player.grace = .75
	player.reset_physics_interpolation()
	camera.reset_smoothing()
	camera.force_update_scroll()
	clock_target = -1
	dialogue_left = 0
	talk_panel.hide()
	_update_lighting()
	_update_hud()
	ui.show_notice("Journey restored from the backup save." if saves.used_backup else "Welcome back  ·  Your journey has been restored.")
	return true


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
	var grid_size := Vector2i(ceili(world_size.x/32.0),ceili(world_size.y/32.0))
	navigation.region = Rect2i(Vector2i.ZERO,grid_size)
	navigation.cell_size = Vector2(32,32)
	navigation.offset = Vector2(16,16)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	if zone in ["wilds","district"]:
		Map.Wilds.build_navigation(self)
		return
	for x in grid_size.x:
		for y in grid_size.y:
			var cell := Vector2i(x,y)
			navigation.set_point_solid(cell,not is_walkable(navigation.get_point_position(cell)))


func _nav_cell(point: Vector2) -> Vector2i:
	var center := Vector2i((point-Vector2(16,16))/32)
	var best := Vector2i(-1,-1)
	var best_distance := INF
	for x in range(maxi(0,center.x-5),mini(navigation.region.size.x,center.x+6)):
		for y in range(maxi(0,center.y-5),mini(navigation.region.size.y,center.y+6)):
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
	var path := navigation.get_point_path(start,end)
	if not path.is_empty() and clear_line(from,navigation.get_point_position(start)):
		return path
	# Padding can leave tiny disconnected pockets next to solid NPCs/props. The
	# geometrically closest free cell may belong to one of those pockets. Try
	# nearby joins, preserving physical clearance from the actor's actual feet.
	var starts := _nearby_nav_cells(from)
	var ends := _nearby_nav_cells(to)
	for alternative_start in starts:
		var join := navigation.get_point_position(alternative_start)
		if not _can_join_navigation(from,join):
			continue
		for alternative_end in ends:
			path = navigation.get_point_path(alternative_start,alternative_end)
			if not path.is_empty():
				return path
	return PackedVector2Array()


func _nearby_nav_cells(point: Vector2) -> Array[Vector2i]:
	var center := Vector2i((point-Vector2(16,16))/32)
	var cells: Array[Vector2i] = []
	for x in range(maxi(0,center.x-3),mini(navigation.region.size.x,center.x+4)):
		for y in range(maxi(0,center.y-3),mini(navigation.region.size.y,center.y+4)):
			var cell := Vector2i(x,y)
			if not navigation.is_point_solid(cell):
				cells.append(cell)
	cells.sort_custom(func(a: Vector2i,b: Vector2i): return navigation.get_point_position(a).distance_squared_to(point)<navigation.get_point_position(b).distance_squared_to(point))
	return cells.slice(0,12)


func _can_join_navigation(from: Vector2, to: Vector2) -> bool:
	if not clear_line(from,to):
		return false
	var steps := maxi(1,int(ceilf(from.distance_to(to)/8.0)))
	for i in range(steps+1):
		if not is_walkable(from.lerp(to,float(i)/steps),14):
			return false
	return true


func clear_line(from: Vector2, to: Vector2, exclude: Array[RID] = []) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(from,to,1,exclude)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _physics_process(_delta: float) -> void:
	if paused or shopping or transitioning or not is_instance_valid(player) or not player.active:
		return
	near_exit = ""
	if travel_cooldown<=0:
		for id in exits:
			var offset: Vector2 = exits[id]["at"]-player.position
			if Actor.ground_vector(offset).length()<130:
				near_exit = id
				if offset.length()<33:
					request_travel(id)
					return
	nearest = ""
	var distance := 150.0
	for id in interactables:
		if combat_active and id=="warden":
			continue
		var item: Dictionary = interactables[id]
		if item.has("anchor") and item["anchor"] is CharacterBody2D:
			item["at"] = item["anchor"].position
		var candidate: float = Actor.ground_vector(item["at"]-player.position).length()
		var quest_target: bool = zone=="town" and quest_stage<5 and id==QUEST_TARGETS[quest_stage]
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
	if paused or transitioning:
		return
	if id.is_empty() and near_exit!="":
		request_travel(near_exit)
		return
	if id.is_empty():
		id = nearest
	if id.is_empty():
		return
	if id.begins_with("loot:"):
		collect_loot(id.trim_prefix("loot:"))
		return
	audio.play_event("ui_open",player.position,-12)
	if interactables[id].has("anchor") and interactables[id]["anchor"].has_method("greet"):
		interactables[id]["anchor"].greet()
	var lines := {
		"baker":"The oven's warm and the square is waking up. Good to see you!",
		"elder":"A quiet bench, a warm breeze. A fine place to spend the morning.",
		"grocer":"Fresh apples from the valley. Even the wardens stop by for a bite.",
		"courier":"One square, a hundred stories. That's what I love about my rounds.",
		"bookseller":"This town was built around its spring. Some say the water remembers every wish.",
		"postbox":"A sturdy red postbox. Today's collection hasn't gone yet.",
		"rhea":"I've just come back from Mosswood. Take the southeast gate and follow the trail past the meadow. The river is worth the walk.",
		"alden":"Small paws or long strides, everyone is welcome here. Bram and I keep the square peaceful. Enjoy your visit.",
		"iris":"The meadow is full of chamomile. Clover brews it into a lovely tea at the Bluebird Bakery, under the blue awning.",
		"tomas":"Market carts, gate hinges, and that stubborn lamppost... I'm never short of work here. A town runs on the little things."
	}
	if zone=="bakery":
		if id=="shop_vendor":
			open_shop()
		return
	if zone=="district":
		if id.begins_with("north_place_"):
			district_places[id] = true
		_say(interactables[id]["name"],interactables[id]["text"])
		_update_hud()
		return
	if zone!="town":
		var landmark: Dictionary = interactables[id]
		discoveries[id] = true
		_say(landmark["name"],landmark["memory"])
		_update_hud()
		return
	if id in ["warden","guard_west","guard_east"]:
		if id=="warden":
			if not state.accepted:
				state.accept_quest()
				_say("Bram · Town warden","A few bandits are troubling Briarwood. Recover three of their badges and bring them to me: ten coins and a warden's charm are yours. Take the southeast gate, cross Riverbend, then follow the path beyond the bridge.")
			elif state.claim_reward():
				audio.play_event("victory",player.position,-5)
				_say("Bram · Town warden","Three badges, just as promised! Here are ten coins and a warden's charm. Open your satchel with I and equip it for an extra heart. Clover sells healing food inside the blue-awning bakery.")
			else:
				_say("Bram · Town warden",state.quest_text())
			_update_hud()
			return
		_say(interactables[id]["name"],"Safe travels, friend. The southeast gate leads into Mosswood. Follow the path to the river, and take your time — we'll look after the square.")
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
	if not peaceful_mode:
		return
	# Kept as a compatibility guard: conversations can never start combat.
	combat_active = false
	for dog in dogs:
		dog.enemy = false
		dog.windup = 0
		dog.swing = 0


func actor_yielded(actor_node) -> void:
	if zone!="wilds":
		return
	if actor_node==player:
		transitioning = true
		_recover_in_forest.call_deferred()
		return
	if not state.record_defeat(actor_node.resident_id,actor_node.position):
		return
	_add_loot(actor_node.resident_id)
	audio.play_event("coin",actor_node.position,-12)
	var fade: Tween = actor_node.create_tween()
	fade.tween_property(actor_node.sprite,"modulate:a",0.0,.35)
	combat_active = dogs.any(func(dog): return dog.active)
	if not combat_active:
		audio.play_event("victory",player.position,-5)
		_say("The forest is quiet", "All twelve bandits have fled. The clearings are safe to explore. Your coin rewards and progress will remain when you return.")
	_update_hud()


func _recover_in_forest() -> void:
	var fade := create_tween()
	fade.tween_property(ui.fade,"modulate:a",1.0,.3)
	await fade.finished
	forest_recoveries += 1
	state.health = state.maximum_health
	_load_zone("wilds","river")
	await get_tree().physics_frame
	_say("A moment to catch your breath", "You return to the sheltered western trail with full health. Defeated bandits stay defeated, and your coins are safe. Try drawing one pack away from the others.")
	fade = create_tween()
	fade.tween_property(ui.fade,"modulate:a",0.0,.3)
	await fade.finished
	transitioning = false


func advance_time() -> void:
	clock_target = floorf(clock)+1.0


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if not paused:
		elapsed += delta
		travel_cooldown = maxf(0,travel_cooldown-delta)
		if clock_target>=0:
			clock = move_toward(clock,clock_target,delta/2.0)
			if is_equal_approx(clock,clock_target):
				clock = fposmod(clock,4.0)
				clock_target = -1.0
		elif auto_clock:
			clock = fposmod(clock+delta*4.0/CYCLE_SECONDS,4.0)
		dialogue_left = maxf(0,dialogue_left-delta)
		talk_panel.visible = dialogue_left>0
		if is_instance_valid(ripples):
			ripples.queue_redraw()
		if is_instance_valid(trail_effects):
			trail_effects.queue_redraw()
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
	actor_tint = TINTS[base].lerp(TINTS[next],weight)
	if zone=="town":
		for i in 4:
			backgrounds[i].visible = i==base or (i==next and weight>0)
			backgrounds[i].modulate.a = weight if i==next else 1.0
			backgrounds[i].z_index = -9 if i==next else -10
	elif zone=="bakery":
		actor_tint = Color("fff1db").lerp(Color("c7b99e"),clampf(1.0-actor_tint.g,0,1)*.6)
		if is_instance_valid(bakery_room):
			bakery_room.queue_redraw()
	elif zone=="district":
		pass
	elif zone=="wilds":
		backgrounds[0].modulate = Color.WHITE.lerp(actor_tint,.85)
	else:
		var night_weights := [0.16,0.0,0.24,1.0]
		backgrounds[0].modulate = Color.WHITE.lerp(actor_tint,0.20)
		backgrounds[1].modulate.a = lerpf(night_weights[base],night_weights[next],weight)
	for piece in pieces:
		piece.modulate = actor_tint
	for foliage in occluders:
		if is_instance_valid(player) and player.position.y<foliage.get_parent().position.y:
			var local_point := foliage.to_local(player.global_position-Vector2(0,60))
			if foliage.get_rect().has_point(local_point):
				foliage.modulate.a = .34
	if is_instance_valid(ripples):
		ripples.modulate.a = clampf(actor_tint.g,0.4,1.0)
	if is_instance_valid(ui):
		ui.clock_dial.set_phase(clock)


func _build_ui() -> void:
	ui = Hud.new()
	ui.hub = self
	add_child(ui)
	objective = ui.objective
	status_label = ui.status_label
	talk_panel = ui.talk_panel
	talk_name = ui.talk_name
	talk_text = ui.talk_text
	prompt = ui.prompt
	prompt_text = ui.prompt_text
	quest_marker = ui.quest_marker
	pause_overlay = ui.pause_overlay


func _say(speaker: String, text: String) -> void:
	talk_name.text = speaker
	talk_text.text = text
	dialogue_left = 7.0
	talk_panel.visible = true


func _update_hud() -> void:
	if is_instance_valid(ui):
		ui.refresh()


func _update_prompt() -> void:
	prompt.visible = (not nearest.is_empty() or not near_exit.is_empty()) and (not combat_active or near_exit!="" or nearest.begins_with("loot:")) and not shopping and not transitioning and not paused
	if prompt.visible:
		var offset_y := -165.0 if dialogue_left>0 else 25.0
		prompt.position = (get_canvas_transform()*player.global_position+Vector2(-140,offset_y)).clamp(Vector2(15,170),Vector2(1620,940))
		prompt_text.text = "E   "+("Enter bakery" if near_exit=="bakery" else ("Go to "+exits[near_exit].get("sign","the next path") if near_exit!="" else interactables[nearest]["name"]))
	quest_marker.visible = zone=="town" and (quest_stage<5 or state.can_claim() or not state.accepted) and not transitioning
	if quest_marker.visible:
		var target_id: String = "warden" if state.can_claim() or quest_stage>=5 else QUEST_TARGETS[quest_stage]
		var target: Dictionary = interactables[target_id]
		var point: Vector2 = get_canvas_transform()*(target["at"]+Vector2(0,-target["height"]-24))
		quest_marker.position = point+Vector2(-14,-18+sin(elapsed*2.3)*5)
		quest_marker.visible = Rect2(20,190,1880,760).has_point(point)


func set_paused(value: bool) -> void:
	paused = value
	audio.set_paused(value)
	pause_overlay.visible = value
	for actor in [player]+dogs:
		if is_instance_valid(actor):
			actor.sprite.speed_scale = 0.0


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("hub_save"):
		save_game()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("hub_load"):
		load_game()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("hub_bag") or (backpack_open and event.is_action_pressed("hub_pause")):
		toggle_backpack()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("hub_food"):
		use_item("bread")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("hub_mute") and not event.is_echo():
		audio.set_muted(not audio.muted)
		get_viewport().set_input_as_handled()
		return
	# Skill input must not disappear into a GUI control or an in-progress slash.
	if event.is_action_pressed("hub_skill") and not event.is_echo():
		if player.try_skill():
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if shopping:
		if event.is_action_pressed("hub_pause") or event.is_action_pressed("hub_interact"):
			close_shop()
		elif event is InputEventKey and event.pressed:
			var index: int = event.physical_keycode-KEY_1
			if index>=0 and index<GOODS.size():
				buy(index)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("hub_pause"):
		set_paused(not paused)
	elif event.is_action_pressed("hub_restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("hub_fullscreen"):
		get_window().mode = Window.MODE_WINDOWED if get_window().mode==Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	elif event.is_action_pressed("hub_journal"):
		ui.journal_panel.visible = not ui.journal_panel.visible
	elif event.is_action_pressed("hub_debug"):
		ui.debug_visible = not ui.debug_visible
	elif not paused and not transitioning:
		if event.is_action_pressed("hub_skill"):
			player.try_skill()
		elif event.is_action_pressed("hub_interact"):
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
	var filename := zone+("_night.png" if "--night" in OS.get_cmdline_user_args() else "_day.png")
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/"+filename))
	print("Playable hub captured: ",filename)
	if "--quit-after-capture" in OS.get_cmdline_user_args():
		get_tree().quit()
