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
	_check(game.interactables.size()==7,"All five residents, postbox and warden are interactive")
	_check(game.quest_stage==0 and not game.combat_active,"Demo starts with an available quest and optional combat")
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
	# Passive warden is harmless until explicitly challenged.
	_check(game.dogs.is_empty(),"No hostile wardens spawn before challenge")
	game.start_challenge()
	_check(game.dogs.size()==3 and game.combat_active,"Optional challenge spawns three opponents")
	for dog in game.dogs:
		dog.set_physics_process(false)
		dog.position = Vector2(1200,960)
	await _settle(Vector2(800,930))
	var victim = game.dogs[0]
	victim.position = Vector2(865,930)
	victim.grace = 0
	game.player.cooldown = 0
	_check(game.player.try_attack(Vector2.RIGHT),"Cat can start an aimed swing")
	_check(not game.player.try_attack(Vector2.RIGHT),"Attack cooldown prevents immediate repeated swings")
	game.player.resolve_hits()
	_check(victim.health==2,"Melee swing damages an in-range opponent")
	victim.grace = 0
	game.player.resolve_hits()
	_check(victim.health==2,"One swing cannot hit the same opponent twice")
	game.player.swing_hits.clear()
	victim.position = Vector2(730,930)
	game.player.resolve_hits()
	_check(victim.health==2,"Melee facing cone excludes opponents behind the cat")
	game.player.swing_hits.clear()
	game.player.position = Vector2(970,730)
	victim.position = Vector2(970,665)
	game.player.facing = Vector2.UP
	game.player.resolve_hits()
	_check(victim.health==2,"Melee cannot pass through the fountain")
	game.player.grace = 0
	game.player.health = 5
	_check(game.player.receive_hit(Vector2.LEFT),"Enemy damage reduces cat health")
	_check(game.player.health==4 and not game.player.receive_hit(Vector2.LEFT),"Damage grants temporary invulnerability")
	game.player.grace = 0
	game.player.health = 1
	game.player.receive_hit(Vector2.LEFT)
	_check(not game.combat_active and game.player.active and game.player.health==5,"Defeat safely ends challenge and restores the cat")
	_check(game.quest_stage==5,"Sparring defeat preserves completed deliveries")
	game.start_challenge()
	for dog in game.dogs:
		dog.set_physics_process(false)
		dog.health = 1
		dog.grace = 0
		dog.receive_hit(Vector2.RIGHT)
	_check(not game.combat_active and game.challenge_won,"All three opponents yielding wins the challenge")
	_check(game.victory_count==3,"Victory counts all three opponents")
	game.clock = 3.95
	game.advance_time()
	for tick in 30:
		await physics_frame
	_check(game.clock<0.1 and game.clock_target<0,"Night transitions into dawn without an out-of-range texture")
	var before_clock: float = game.clock
	var before_position: Vector2 = game.player.position
	game.set_paused(true)
	Input.action_press("hub_right")
	for tick in 30:
		await physics_frame
	Input.action_release("hub_right")
	_check(game.player.position.is_equal_approx(before_position),"Pause stops character simulation")
	_check(is_equal_approx(game.clock,before_clock),"Pause freezes the day/night clock")
	game.set_paused(false)
	_check(not game.pause_overlay.visible,"Resume hides pause interface")
	for action in InputMap.get_actions():
		if action.begins_with("hub_"):
			Input.action_release(action)
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Actual movement, obstacle navigation, proximity quest, melee, challenge outcomes, time wrap and pause at 1080p canvas."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"test_results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Playable hub: ",checks-failures.size(),"/",checks," checks passed.")
	quit(0 if failures.is_empty() else 1)
