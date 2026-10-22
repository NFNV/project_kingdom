extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _settle(at: Vector2) -> void:
	game.player.position = at
	game.player.intent = Vector2.ZERO
	game.player.velocity = Vector2.ZERO
	game.player.route.clear()
	game.player.knockback = Vector2.ZERO
	game.player.reset_physics_interpolation()
	await physics_frame
	await physics_frame


func _walk(at: Vector2, actions: Array, frames: int) -> Vector2:
	await _settle(at)
	for action in actions:
		Input.action_press(action)
	for tick in frames:
		await physics_frame
	for action in actions:
		Input.action_release(action)
	await physics_frame
	return game.player.position


func _travel_route(exit_id: String, expected_zone: String) -> void:
	var original: String = game.zone
	var at: Vector2 = game.exits[exit_id]["at"]
	var path: PackedVector2Array = game.find_path(game.player.position,at)
	_check(not path.is_empty(),"A walkable route reaches "+original+" / "+exit_id)
	game.player.route = path
	for tick in 1800:
		await physics_frame
		if game.zone==expected_zone and not game.transitioning:
			break
	_check(game.zone==expected_zone and not game.transitioning,"Walking through "+exit_id+" arrives in "+expected_zone)
	if game.zone!=expected_zone:
		print("TRAVEL DEBUG ",original," ",game.player.position," target ",at," route ",game.player.route)
	_check(game.is_walkable(game.player.position,14),"Arrival in "+expected_zone+" has a safe collision footprint")


func _visit_landmark(id: String) -> void:
	var path: PackedVector2Array = game.find_path(game.player.position,game.interactables[id]["at"])
	_check(not path.is_empty(),"Path reaches resting place "+id)
	game.player.route = path
	for tick in 1200:
		await physics_frame
		if game.nearest==id:
			break
	_check(game.nearest==id,"The cat physically reaches "+id)
	game.interact()
	_check(game.discoveries.has(id),"Proximity interaction records "+id)


func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	game.auto_clock = false
	for tick in 5:
		await physics_frame
	_check(root.get_texture().get_size()==Vector2(1920,1080),"Internal canvas is 1920x1080")
	_check(game.player.controlled,"Cat is controlled")
	_check(game.player.sprite.sprite_frames.has_animation("walk_nw"),"Registered directional character resources load")
	_check(game.interactables.size()==9,"All residents, postbox and three peaceful wardens are interactive")
	_check(game.quest_stage==0 and not game.combat_active,"Demo starts with an available quest and no combat")
	var start := Vector2(800,930)
	var end := await _walk(start,["hub_right"],30)
	var walk_distance: float = game.Actor.ground_vector(end-start).length()
	_check(absf(walk_distance-107.5)<8,"Keyboard walking uses configured speed")
	end = await _walk(start,["hub_right","hub_up"],30)
	_check(absf(game.Actor.ground_vector(end-start).length()-walk_distance)<8,"Diagonal input is normalized on the isometric ground plane")
	end = await _walk(start,["hub_right","hub_run"],30)
	_check(game.Actor.ground_vector(end-start).length()>walk_distance*1.4,"Shift runs faster")
	end = await _walk(Vector2(970,805),["hub_up"],90)
	_check(end.y>732 and end.y<805,"Player collides with the front of the fountain")
	end = await _walk(Vector2(800,1000),["hub_down"],90)
	_check(end.y<1047,"Painted foreground boundary prevents walking into baked walls")
	var route: PackedVector2Array = game.find_path(Vector2(730,675),Vector2(1210,675))
	_check(route.size()>8,"Click navigation finds a route around the fountain")
	var valid := true
	for point in route:
		valid = valid and game.is_walkable(point)
	_check(valid,"All path nodes clear padded obstacle footprints")
	_check(not game.clear_line(Vector2(730,675),Vector2(1210,675)),"Fountain blocks melee line of sight")
	_check(game.clear_line(Vector2(800,930),Vector2(1080,930)),"Open cobblestone lane has clear line of sight")
	await _settle(Vector2(730,675))
	game.player.route = route
	for tick in 450:
		await physics_frame
		if game.player.route.is_empty():
			break
	_check(game.player.position.distance_to(Vector2(1210,675))<45,"Actual click-to-walk motion reaches the far side of the fountain")
	# Reach each errand through the same pathfinder and proximity gate as the player.
	for id in ["baker","elder","grocer","courier","postbox"]:
		var target: Vector2 = game.interactables[id]["at"]
		game.player.route = game.find_path(game.player.position,target)
		for tick in 600:
			await physics_frame
			if game.nearest==id:
				break
		_check(game.nearest==id,"Can physically reach and interact with "+id)
		var before: int = game.quest_stage
		game.interact()
		_check(game.quest_stage==before+1,"Correct proximity interaction advances "+id+" errand")
	_check(game.quest_stage==5,"Full five-step delivery quest completes")
	game.interact("baker")
	_check(game.quest_stage==5,"Repeated NPC conversation cannot duplicate quest progress")
	# Talking to every warden and legacy challenge calls remain harmless.
	_check(game.dogs.size()==3,"Three peaceful dog wardens inhabit the town")
	for id in ["warden","guard_west","guard_east"]:
		game.interact(id)
	_check(not game.combat_active,"Warden conversation never starts a fight")
	game.start_challenge()
	_check(not game.combat_active,"Legacy challenge entry cannot enable combat")
	for dog in game.dogs:
		dog.enemy = true
		dog.cooldown = 0
	game.combat_active = true
	await _settle(Vector2(1110,850))
	var health_before: int = game.player.health
	for tick in 120:
		await physics_frame
	_check(game.player.health==health_before,"Even stale enemy flags cannot make wardens damage the cat")
	_check(not game.dogs[0].try_attack(),"Wardens cannot start an attack in peaceful mode")
	_check(not game.player.receive_hit(Vector2.LEFT),"Exploration player rejects damage")
	_check(not game.dogs[0].receive_hit(Vector2.LEFT),"Friendly wardens reject damage")
	game.start_challenge()
	_check(game.CYCLE_SECONDS==1200.0,"Full day/night cycle lasts twenty minutes")
	game.clock = 1.0
	game.auto_clock = true
	game._process(60.0)
	game.auto_clock = false
	_check(absf(game.clock-1.2)<0.001,"One real minute advances exactly one twentieth of a full cycle")
	game.ui.clock_dial.set_phase(1.0)
	_check(is_equal_approx(game.ui.clock_dial.hour,12.0),"Celestial dial shows noon for noon lighting")
	game.ui.clock_dial.set_phase(3.0)
	_check(is_equal_approx(game.ui.clock_dial.hour,0.0),"Celestial dial shows midnight for night lighting")
	game.clock = 1.4
	await _travel_route("southeast","trail")
	_check(game.quest_stage==5 and absf(game.clock-1.4)<.001,"Town errands and clock survive travel into the forest")
	_check(game.dogs.is_empty(),"Forest contains no hostile dog actors")
	for id in ["old_elm","meadow"]:
		await _visit_landmark(id)
	_check(game.discoveries.size()==2,"Both trail memories can be discovered")
	await _travel_route("river","river")
	await _visit_landmark("river_view")
	_check(game.discoveries.size()==3,"River viewpoint completes the forest journal")
	var across_bridge = game.Map.point(1200,100)
	var bridge_route: PackedVector2Array = game.find_path(game.player.position,across_bridge)
	_check(not bridge_route.is_empty(),"The footbridge connects both riverbanks")
	game.player.route = bridge_route
	for tick in 1200:
		await physics_frame
		if game.player.route.is_empty():
			break
	_check(game.player.position.distance_to(across_bridge)<50,"Actual walking crosses the bridge without entering the water")
	await _travel_route("trail","trail")
	await _travel_route("town","town")
	_check(game.quest_stage==5 and game.discoveries.size()==3,"Returning home preserves town and forest progress")
	_check(absf(game.clock-1.4)<.001,"The shared clock is not reset by any zone transition")
	_check(game.player.get_parent()==game.world,"The same playable cat transfers into the current ground-sorted scene")
	# Close camera follows the same actor across the new room and every return trip.
	_check(game.camera.get_parent()==game.player and is_equal_approx(game.camera.zoom.x,1.7),"Close camera is attached to the cat at 1.7x zoom")
	await _settle(Vector2(960,630))
	game.camera.force_update_scroll()
	var screen_before: Vector2 = game.get_canvas_transform()*game.player.position
	var camera_before: Vector2 = game.camera.get_screen_center_position()
	var end_camera := await _walk(Vector2(960,630),["hub_right"],20)
	game.camera.force_update_scroll()
	_check(game.camera.get_screen_center_position().x>camera_before.x+40,"Camera tracks real character movement")
	_check(absf((game.get_canvas_transform()*end_camera).x-screen_before.x)<3,"Following keeps the cat at a fixed horizontal screen position")
	var view_origin: Vector2 = game.get_canvas_transform().affine_inverse()*Vector2.ZERO
	var view_end: Vector2 = game.get_canvas_transform().affine_inverse()*Vector2(1920,1080)
	_check(view_origin.x>=-.1 and view_origin.y>=-.1 and view_end.x<=1920.1 and view_end.y<=1080.1,"Camera frustum stays inside painted scene bounds")
	await _settle(Vector2(485,755))
	game.camera.force_update_scroll()
	game._update_prompt()
	_check(game.prompt.visible and game.prompt.position.distance_to((game.get_canvas_transform()*game.player.position+Vector2(-140,-165 if game.dialogue_left>0 else 25)).clamp(Vector2(15,170),Vector2(1620,940)))<2,"NPC prompt projects world position through the moving camera")
	_check(is_instance_valid(game.ripples) and game.ripples.streams.size()==4,"Fountain has four registered animated spilling streams")
	var curve_before: Vector2 = game.ripples.curve(game.ripples.streams[0],.2)
	var curve_after: Vector2 = game.ripples.curve(game.ripples.streams[0],.7)
	_check(curve_after.y>curve_before.y+90,"Fountain streaks travel down the fountain into the basin")
	await _travel_route("bakery","bakery")
	_check(game.backgrounds.is_empty() and is_instance_valid(game.bakery_room),"Bakery uses an authored walkable room rather than a painted background")
	_check(game.interactables.has("shop_vendor"),"Bakery has its own vendor NPC")
	_check(game.camera.get_parent()==game.player,"The follow camera survives entering the house")
	game.player.route = game.find_path(game.player.position,game.interactables.shop_vendor.at)
	for tick in 500:
		await physics_frame
		if game.nearest=="shop_vendor":
			break
	_check(game.nearest=="shop_vendor","Cat physically reaches the customer side of the counter")
	_check(not game.is_walkable(Vector2(1080,490),0),"Sales counter has a solid collision footprint")
	_check(game.interactables.shop_vendor.anchor.position.y<game.world.get_node("bakery_counter").position.y,"Vendor is depth sorted behind the sales counter")
	game.interact()
	_check(game.shopping and game.ui.merchant.visible,"E opens the vendor's usable shop")
	var before_shop: Vector2 = game.player.position
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	game._unhandled_input(click)
	_check(game.player.route.is_empty(),"Shop input cannot click through to world navigation")
	Input.action_press("hub_right")
	for tick in 20:
		await physics_frame
	Input.action_release("hub_right")
	_check(game.player.position.is_equal_approx(before_shop),"Shopping prevents movement and accidental door travel")
	game.ui.shop_buttons[0].pressed.emit()
	_check(game.coins==10 and game.inventory.bread==1,"Buying a loaf charges two coins and puts bread in the satchel")
	_check(game.buy(1) and game.coins==7 and game.inventory.tea==1,"Tea has its own price and inventory entry")
	_check(game.buy(2) and game.coins==3 and game.inventory.honey==1,"Honey has its own price and inventory entry")
	_check(not game.buy(2) and game.coins==3 and game.inventory.honey==1,"Unaffordable purchases cannot create items or negative money")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	_check(not game.shopping and not game.paused and not game.ui.merchant.visible,"Escape closes shopping without also pausing the game")
	_check(not game.buy(0),"Purchasing outside a vendor conversation is rejected")
	await _travel_route("town","town")
	_check(game.quest_stage==5 and game.discoveries.size()==3 and game.coins==3 and game.inventory.bread==1,"Leaving the house preserves errands, forest memories, money and purchases")
	await _travel_route("bakery","bakery")
	_check(game.coins==3 and game.inventory.honey==1,"Reentering the bakery cannot reset or duplicate purchased goods")
	await _travel_route("town","town")
	game.clock = 3.95
	game.advance_time()
	for tick in 30:
		await physics_frame
	_check(game.clock<0.1 and game.clock_target<0,"Night transitions into dawn without an out-of-range texture")
	var before_clock: float = game.clock
	var before_position: Vector2 = game.player.position
	var before_water: float = game.elapsed
	game.set_paused(true)
	Input.action_press("hub_right")
	for tick in 30:
		await physics_frame
	Input.action_release("hub_right")
	_check(is_equal_approx(game.elapsed,before_water),"Pause freezes the fountain, steam and oven animation clock")
	_check(game.player.position.is_equal_approx(before_position),"Pause stops character simulation")
	_check(is_equal_approx(game.clock,before_clock),"Pause freezes the day/night clock")
	game.set_paused(false)
	_check(not game.pause_overlay.visible,"Resume hides pause interface")
	for action in InputMap.get_actions():
		if action.begins_with("hub_"):
			Input.action_release(action)
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Movement/collision, delivery quest, peaceful warden regression, twenty-minute clock, camera tracking/projection/limits, spilling fountain, furnished bakery entry/return, counter collision, vendor purchases and modal input, physical southeast exit, both forest areas, bridge, complete return journey and persistent progress."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"test_results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Playable hub: ",checks-failures.size(),"/",checks," checks passed.")
	quit(0 if failures.is_empty() else 1)
