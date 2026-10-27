extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame

func place(at: Vector2) -> void:
	game.player.position = at
	game.player.stop_motion()
	game.player.knockback = Vector2.ZERO
	game.player.reset_physics_interpolation()
	await ticks(2)

func walk_to(at: Vector2) -> void:
	var path: PackedVector2Array = game.find_path(game.player.position,at)
	check(not path.is_empty(),"A route exists to "+str(at))
	game.player.route = path
	for tick in 2800:
		await physics_frame
		if game.player.route.is_empty() or game.transitioning:
			break

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	game.auto_clock = false
	await ticks(3)
	var identity: int = game.player.get_instance_id()
	game.quest_stage = 3
	game.discoveries.old_elm = true
	game.clock = 1.4
	game._load_zone("river","trail")
	await ticks(3)
	check(game.peaceful_mode and not game.combat_active,"Riverbend remains peaceful")
	await walk_to(game.exits.wilds.at)
	for tick in 180:
		await physics_frame
		if game.zone=="wilds" and not game.transitioning:
			break
	check(game.zone=="wilds" and not game.transitioning,"Physically crossing the river bridge enters Briarwood")
	if game.zone!="wilds":
		print("ENTRY DEBUG ",game.player.position," ",game.exits)
		quit(1)
		return
	check(game.player.get_instance_id()==identity,"The same cat and camera transfer into the large forest")
	check(game.world_size==Vector2i(4608,2592) and game.navigation.region.size==Vector2i(144,81),"Full forest has a full-size navigation grid")
	check(game.camera.limit_right==4608 and game.camera.limit_bottom==2592,"Follow camera can explore beyond the old scene bounds")
	check(game.occluders.size()>100,"Forest has independently layered animated trees")
	check(game.dogs.size()==12 and game.combat_active and not game.peaceful_mode,"Four packs of three hostile dogs inhabit only Briarwood")
	check(game.player.health==5 and game.is_walkable(game.player.position,14),"The sheltered entrance is a healthy safe spawn")
	await ticks(60)
	check(game.dogs.all(func(dog): return not dog.alerted),"Distant packs do not chase the player from the entrance")
	for dog in game.dogs:
		dog.set_physics_process(false)
	for camp in game.Map.Wilds.CAMPS:
		await walk_to(camp)
		check(game.player.position.distance_to(camp)<45,"Actual walking reaches the forest clearing at "+str(camp))
		check(game.is_walkable(game.player.position,14),"Clearings remain physically walkable")
	game.camera.force_update_scroll()
	check(game.camera.get_screen_center_position().x>1920,"The camera physically follows the cat deep into the large map")
	var dog = game.dogs[0]
	await place(dog.home+Vector2(-220,0))
	dog.set_physics_process(true)
	var dog_start: Vector2 = dog.position
	await ticks(50)
	check(dog.alerted and dog.position.distance_to(dog_start)>20,"A nearby bandit notices and physically chases the cat")
	await place(game.Map.Wilds.ENTRY)
	await ticks(250)
	check(not dog.alerted and dog.position.distance_to(dog.home)<135,"A bandit abandons a distant chase and resumes its bounded camp patrol")
	# Reset the duel onto the clearing, then step away during its visible windup.
	dog.position = dog.home
	dog.reset_physics_interpolation()
	dog.windup = 0
	dog.cooldown = 0
	dog.swing = 0
	await place(dog.home+Vector2(-65,0))
	game.player.grace = 0
	var health: int = game.player.health
	await ticks(20)
	check(dog.windup>0 and game.player.health==health,"Enemy attack has a readable warning before any damage")
	Input.action_press("hub_left")
	await ticks(35)
	Input.action_release("hub_left")
	check(game.player.health==health,"Moving out of the warning avoids the actual enemy swing")
	dog.position = dog.home
	dog.windup = 0
	dog.cooldown = 0
	dog.swing = 0
	await place(dog.home+Vector2(-65,0))
	await ticks(65)
	check(game.player.health<health,"Staying in melee range allows the real enemy attack to deal damage")
	dog.set_physics_process(false)
	dog.position = dog.home
	dog.knockback = Vector2.ZERO
	dog.grace = 0
	# Stop its attacks, but keep real hurt cooldown and knockback simulation.
	dog.enemy = false
	dog.set_physics_process(true)
	await place(dog.home+Vector2(-65,0))
	game.player.facing = Vector2.RIGHT
	game.player.cooldown = 0
	var coins: int = game.coins
	Input.action_press("hub_attack")
	await ticks(100)
	Input.action_release("hub_attack")
	check(not dog.active and dog.health==0,"Space attacks defeat a three-hit bandit through actual melee resolution")
	check(game.forest_defeated.size()==1 and game.coins==coins+2,"A defeat awards two coins and records that unique bandit")
	game.actor_yielded(dog)
	check(game.coins==coins+2,"Repeated defeat callbacks cannot duplicate rewards")
	# Pause must freeze an active battle, not just the interface.
	var enemy = game.dogs[1]
	enemy.set_physics_process(true)
	await place(enemy.home+Vector2(-70,0))
	game.set_paused(true)
	var before: Vector2 = enemy.position
	health = game.player.health
	await ticks(90)
	check(enemy.position==before and game.player.health==health,"Pause freezes enemy movement and damage")
	game.set_paused(false)
	enemy.set_physics_process(false)
	# Real damage callback schedules a checkpoint recovery and rebuilds remaining mobs.
	game.player.health = 1
	game.player.grace = 0
	game.player.receive_hit(Vector2.LEFT)
	await ticks(120)
	check(game.forest_recoveries==1 and game.player.active and game.player.health==5 and not game.transitioning,"Defeat recovers at the sheltered entrance with full health")
	check(game.player.position.distance_to(game.Map.Wilds.ENTRY)<5 and game.dogs.size()==11,"Recovery removes the defeated bandit without moving the entrance")
	check(game.coins==coins+2 and game.quest_stage==3 and game.discoveries.has("old_elm") and is_equal_approx(game.clock,1.4),"Recovery preserves coins, town errands, memories and the shared clock")
	# Actual retreat and reentry exercise combat isolation and population persistence.
	await walk_to(game.exits.river.at)
	await ticks(100)
	check(game.zone=="river" and game.peaceful_mode and not game.combat_active,"The western exit physically retreats to peaceful Riverbend")
	check(game.dogs.is_empty() and not game.player.receive_hit(Vector2.LEFT),"Combat and hostile actors cannot leak into Riverbend")
	await walk_to(game.exits.wilds.at)
	await ticks(100)
	check(game.zone=="wilds" and game.dogs.size()==11,"Reentering cannot respawn the rewarded bandit")
	for remaining in game.dogs:
		remaining.set_physics_process(false)
		remaining.grace = 0
		for hit in remaining.maximum_health:
			remaining.grace = 0
			remaining.receive_hit(Vector2.LEFT)
	check(game.forest_defeated.size()==12 and not game.combat_active,"Defeating all twelve clears the forest objective")
	check(game.coins==coins+24,"All unique bandits award exactly twenty-four coins")
	game._load_zone("wilds","river")
	check(game.dogs.is_empty() and not game.combat_active,"A cleared forest remains cleared on a later visit")
	game._load_zone("town","forest")
	await ticks(5)
	check(game.peaceful_mode and game.dogs.size()==3 and game.dogs.all(func(warden): return not warden.enemy),"Town wardens stay friendly after forest combat")
	check(not game.player.try_attack() and game.player.health==5,"Home restores health and rejects attacks")
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Physical bridge entry, large-map navigation and camera, all four clearings, local hostile packs, telegraphed attacks and movement dodge, actual Space melee damage, unique coin rewards, pause, checkpoint recovery, physical retreat and reentry, persistent clears and friendly town regression."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"wilds_test_results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Briarwood: ",checks-failures.size(),"/",checks," checks passed.")
	quit(0 if failures.is_empty() else 1)
