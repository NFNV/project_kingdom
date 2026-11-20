extends SceneTree
const Moonlight := preload("res://experiments/anime_hub_demo_v07/tools/moonlight_forest.gd")
var game: Node2D
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: run.call_deferred()

func check(ok: bool, words: String) -> void:
	checks += 1
	if not ok:
		failures.append(words)
		push_error(words)

func ticks(count: int) -> void:
	for i in count: await physics_frame

func room(zone: String) -> void:
	game._load_zone(zone,"start")
	game.player.process_mode = Node.PROCESS_MODE_DISABLED
	for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.health = game.player.maximum_health
	game.player.grace = 0
	game.player.guarding = false
	game.player.roll_left = 0

func screenshot(label: String, at: Vector2) -> void:
	if "--capture-encounters" not in OS.get_cmdline_user_args(): return
	game.player.position = at
	game.player.stop_motion()
	game.player.reset_physics_interpolation()
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.dialogue_left = 0
	game.talk_panel.hide()
	await ticks(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/moonlight_"+label+".png")

func run() -> void:
	game = load("res://experiments/anime_hub_demo_v07/demo.tscn").instantiate()
	game.save_path = "/tmp/kingdom-dungeon-encounters.json"
	root.add_child(game)
	game.autosave_enabled = false
	game.auto_clock = false
	game.state.moonlight = Moonlight.fresh_progress()
	for zone in [Moonlight.PASSAGE,Moonlight.CISTERN,Moonlight.CHAPEL]:
		room(zone)
		check(game.dogs.size()=={Moonlight.PASSAGE:3,Moonlight.CISTERN:4,Moonlight.CHAPEL:3}[zone],zone+" spawns its new encounter")
		for dog in game.dogs:
			check(game.is_walkable(dog.position,15),dog.resident_id+" stands on dry, accessible floor")
			check(dog.sprite.sprite_frames.resource_path.contains(dog.archetype),dog.resident_id+" uses its own painted directional art")
			check(Array(dog.patrol).all(func(at): return game.is_walkable(at,15)),dog.resident_id+" patrol remains on floor")
			for heading in ["se","sw","ne","nw"]:
				for action in ["idle","windup","strike","recover","hurt"]: dog.sprite.set_pose(action,heading,0)
			dog.sprite.set_pose("idle","se",0)
		await screenshot(zone+"_encounter",Vector2(1400,870) if zone==Moonlight.CHAPEL else Vector2(1536,1250) if zone!=Moonlight.CISTERN else Vector2(2360,1090))
	room(Moonlight.PASSAGE)
	var archer: Node2D = game.dogs.filter(func(dog): return dog.archetype=="gloam_arbalist")[0]
	game.player.position = archer.position-Vector2(220,0)
	archer.home = archer.position
	archer.alerted = true
	archer.process_mode = Node.PROCESS_MODE_INHERIT
	await ticks(150)
	archer.process_mode = Node.PROCESS_MODE_DISABLED
	check(archer.attacks_started>0 and archer.last_attack=="bolt","Crossbow soldier fires through its real AI and windup")
	check(game.player.health==game.player.maximum_health-1,"The moving bolt deals half a heart without freezing")
	check(get_nodes_in_group("hostile_bolts").is_empty(),"A hitting bolt is consumed")
	var spear: Node2D = game.dogs.filter(func(dog): return dog.archetype=="briar_spearman")[0]
	spear.attack_kind = "thrust"
	spear.facing = Vector2.RIGHT
	check(spear.attack_contains(spear.position+Vector2(170,0)),"Spear reaches farther than a normal slash")
	check(not spear.attack_contains(spear.position+Vector2(100,60)),"Spear thrust leaves a safe sidestep")
	room(Moonlight.CHAPEL)
	var boss: Node2D = game.dogs.filter(func(dog): return dog.is_boss())[0]
	check(boss.maximum_health==36 and boss.sprite.display_height>game.player.sprite.display_height*2,"Blackthorn has boss health and a larger silhouette")
	game.player.position = boss.position+Vector2(60,0)
	for kind in ["slash","sweep","lunge"]:
		boss.attack_kind = kind
		boss.cooldown = 0
		boss.stagger = 0
		boss.swing = 0
		boss.facing = Vector2.RIGHT
		game.player.grace = 0
		game.player.health = game.player.maximum_health
		check(boss.try_attack(),"Boss starts "+kind)
		boss.swing = boss.attack_duration-float(boss.profile().contact)-.01
		var old_health: int = game.player.health
		boss.resolve_hits()
		check(game.player.health==old_health-int(boss.profile().damage),kind+" deals the telegraphed half/full-heart damage")
		boss.resolve_hits()
		check(game.player.health==old_health-int(boss.profile().damage),kind+" cannot hit twice in one swing")
	boss.swing = 0
	boss.cooldown = 0
	boss.facing = Vector2.RIGHT
	boss.grace = 0
	var hp: int = boss.health
	boss.receive_hit(Vector2.LEFT,2,0,game.player)
	check(boss.health==hp-2,"Player melee damages Blackthorn")
	boss.grace = 0
	boss.stagger = 0
	game.player.position = boss.position+Vector2(160,0)
	game.player.health = game.player.maximum_health
	var slash: Node2D = load("res://experiments/anime_hub_demo_v07/tools/wind_slash.gd").new()
	slash.hub = game
	slash.position = game.player.position
	slash.heading = Vector2.LEFT
	game.world.add_child(slash)
	hp = boss.health
	await ticks(25)
	check(boss.health==hp-3,"Wind Slash travels and damages the chapel boss")
	boss.receive_parry()
	check(boss.stagger>=1.25 and boss.swing==0 and boss.windup==0,"Parrying interrupts and staggers Blackthorn")
	# Exercise continuous incoming damage through the actual physics loop.
	boss.stagger = 0
	boss.cooldown = 0
	boss.alerted = true
	game.player.position = boss.position+Vector2(75,0)
	game.player.grace = 0
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	await ticks(100)
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	check(boss.attacks_started>=4 and game.player.health<game.player.maximum_health,"Live boss AI attacks and incoming hits keep the game responsive")
	game.player.health = game.player.maximum_health
	boss.grace = 0
	boss.receive_hit(Vector2.RIGHT,boss.health,0,game.player)
	check(not boss.active and "vault_keeper" in game.state.moonlight.defeated,"Blackthorn defeat retains the stable saved boss ID")
	check(is_instance_valid(game.moonlight_area.chest),"Blackthorn defeat reveals the vault chest")
	var coins: int = game.coins
	game.moonlight_area.use("moon_chest")
	game.moonlight_area.use("moon_chest")
	check(game.coins==coins+100,"Boss chest reward remains one-time")
	check(Moonlight.progress_valid(game.state.moonlight),"New encounters preserve the existing progression schema")
	game.state.moonlight.winch = true
	game.request_travel("cistern")
	for i in 300:
		await physics_frame
		if game.zone==Moonlight.CISTERN and not game.transitioning: break
	check(game.zone==Moonlight.CISTERN,"Normal chapel exit returns to the Undercroft")
	for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
	game.request_travel("chapel")
	for i in 300:
		await physics_frame
		if game.zone==Moonlight.CHAPEL and not game.transitioning: break
	for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
	var rematch: Array = game.dogs.filter(func(dog): return dog.resident_id=="vault_keeper")
	check(game.zone==Moonlight.CHAPEL and rematch.size()==1,"Leaving and returning respawns the defeated boss")
	if rematch.is_empty():
		quit(1)
		return
	boss = rematch[0]
	check(boss.active and boss.health==boss.maximum_health and boss.attacks_started==0 and not boss.alerted,"Rematch starts with full health and fresh AI state")
	check(not is_instance_valid(game.moonlight_area.chest) and not game.interactables.has("moon_chest"),"Fresh encounter hides the previous victory chest")
	check(game.state.moonlight.vault_claimed and Moonlight.progress_valid(game.state.moonlight),"Rematches preserve collected loot and valid save history")
	boss.receive_hit(Vector2.RIGHT,boss.health,0,game.player)
	check(is_instance_valid(game.moonlight_area.chest) and game.moonlight_area.chest.opened,"Rematch victory reveals the already-looted chest")
	coins = game.coins
	game.moonlight_area.use("moon_chest")
	check(game.coins==coins,"Rematch victory cannot duplicate the one-time treasure reward")
	room(Moonlight.CISTERN)
	room(Moonlight.CHAPEL)
	boss = game.dogs.filter(func(dog): return dog.resident_id=="vault_keeper")[0]
	boss.receive_hit(Vector2.RIGHT,3,0,game.player)
	check(boss.health<boss.maximum_health,"A new fight can damage the rematched boss")
	room(Moonlight.CISTERN)
	room(Moonlight.CHAPEL)
	boss = game.dogs.filter(func(dog): return dog.resident_id=="vault_keeper")[0]
	check(boss.health==boss.maximum_health and boss.swing==0 and boss.windup==0,"Leaving an unfinished fight resets health and attack state")
	room(Moonlight.FOREST)
	game.clock = 1
	game._update_lighting()
	check(not game.night_fireflies.visible,"Moonlight Forest fireflies hide during daylight")
	game.clock = 3
	game._update_lighting()
	check(game.night_fireflies.visible and game.night_fireflies.night_weight>.99,"Moonlight Forest fireflies glow at midnight")
	await screenshot("forest_fireflies",Vector2(1536,1390))
	game.queue_free()
	await process_frame
	print("DUNGEON ENCOUNTER CHECKS ",checks," FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
