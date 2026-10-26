extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var checks := 0
var failures: Array[String] = []
var center := Vector2(1550,1650)

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame

func duel(dog, offset: Vector2) -> void:
	for other in game.dogs:
		other.set_physics_process(false)
	dog.set_physics_process(true)
	dog.position = center
	dog.home = center
	dog.health = 3
	dog.grace = 0
	dog.windup = 0
	dog.swing = 0
	dog.stagger = 0
	dog.cooldown = 0
	dog.knockback = Vector2.ZERO
	dog.alerted = true
	dog.returning = false
	dog.attacks_started = 0
	dog.state = "chase"
	dog.route.clear()
	dog.path_timer = 0
	dog.reset_physics_interpolation()
	game.player.position = center+Vector2(offset.x,offset.y*.65)
	game.player.stop_motion()
	game.player.knockback = Vector2.ZERO
	game.player.health = 5
	game.player.grace = 0
	game.player.reset_physics_interpolation()
	await ticks(2)

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	game.auto_clock = false
	game.player.automated = true
	game._load_zone("wilds","river")
	await ticks(180)
	check(game.dogs.filter(func(dog): return dog.variant=="raider").size()==8 and game.dogs.filter(func(dog): return dog.variant=="mauler").size()==4,"Four camps contain eight sword raiders and four club maulers")
	check(game.dogs.any(func(dog): return dog.patrol_distance>20),"Distant bandits physically walk their camp patrols")
	check(game.dogs.all(func(dog): return not dog.alerted and game.Actor.ground_vector(dog.position-dog.home).length()<135),"Patrols remain local and cannot chase from the entrance")
	var raider = game.dogs[0]
	var mauler = game.dogs[2]
	check(raider.sprite.actor_id=="raider" and mauler.sprite.actor_id=="mauler" and raider.sprite.body.texture!=mauler.sprite.body.texture,"Two enemy identities use actual separate artwork instead of recolored wardens")
	check(raider.sprite.display_height<mauler.sprite.display_height and mauler.sprite.display_height<109,"The mauler silhouette is broader/taller while animals remain smaller than humans")
	await duel(raider,Vector2(65,0))
	check(raider.windup>0 and raider.attack_kind=="slash" and game.player.health==5,"A nearby raider visibly anticipates a slash without early damage")
	var heading: Vector2 = raider.facing
	game.player.position = center-Vector2(65,0)
	await ticks(20)
	check(raider.facing==heading,"Warning aim stays locked when the cat steps behind the raider")
	await ticks(30)
	check(game.player.health==5 and raider.attacks_started==1,"Stepping behind the warning avoids the actual slash")
	await duel(raider,Vector2(65,0))
	await ticks(47)
	check(game.player.health==4,"Remaining in the slash deals exactly one hit")
	await duel(raider,Vector2(175,0))
	check(raider.attack_kind=="lunge" and raider.windup>0,"A raider at medium range selects the telegraphed lunge")
	game.player.position = center+Vector2(175,80*.65)
	await ticks(60)
	check(raider.position.x-center.x>70,"The lunge moves the real physics body forward")
	check(game.player.health==5,"Moving sideways outside the warning lane dodges the lunge")
	check(not raider.attack_contains(raider.position+Vector2(45,50*.65)),"Lunge damage cannot extend sideways beyond its drawn lane")
	await duel(raider,Vector2(175,0))
	await ticks(68)
	check(game.player.health==4 and raider.last_attack=="lunge","The committed lunge reaches a cat that stays in its lane")
	game.player.health = 5
	game.player.grace = 0
	game.player.knockback = Vector2.ZERO
	game.player.position = raider.position+Vector2(45,0)
	await ticks(8)
	check(game.player.health==5,"Entering lunge recovery cannot trigger a late hit")
	await duel(raider,Vector2(175,0))
	var polygon: PackedVector2Array = game._ellipse(center+Vector2(60,0),Vector2(15,25))
	var obstacle: StaticBody2D = game._solid(polygon)
	await ticks(65)
	check(raider.position.x<center.x+37 and game.player.health==5,"A solid trunk added after commitment stops the actual lunge and its damage")
	obstacle.queue_free()
	game.blockers.erase(polygon)
	await ticks(2)
	await duel(mauler,Vector2(110,0))
	check(mauler.attack_kind=="sweep" and mauler.windup>.9,"A club mauler has a distinct, slower sweep warning")
	await ticks(40)
	check(game.player.health==5 and mauler.windup>0,"The heavy sweep gives time to dodge before dealing damage")
	await ticks(30)
	check(game.player.health==4,"The larger heavy sweep hits a cat outside normal slash reach")
	await duel(mauler,Vector2(110,0))
	await ticks(40)
	game.player.position = center-Vector2(100,0)
	await ticks(35)
	check(game.player.health==5,"Moving behind the mauler escapes the actual wide sweep")
	await duel(raider,Vector2(65,0))
	check(raider.receive_hit(Vector2.LEFT),"A sword hit damages a winding-up bandit")
	check(raider.health==2 and raider.windup==0 and raider.swing==0 and raider.stagger>0 and raider.sprite.state=="hurt","Damage interrupts anticipation and displays the real drawn hurt pose")
	check(not raider.receive_hit(Vector2.LEFT) and raider.health==2,"The same impact cannot bypass hurt invulnerability")
	await ticks(15)
	check(raider.attacks_started==0 and game.player.health==5,"A staggered enemy cannot finish its cancelled attack")
	await duel(mauler,Vector2(110,0))
	game.set_paused(true)
	var warning: float = mauler.windup
	var at: Vector2 = mauler.position
	await ticks(60)
	check(mauler.windup==warning and mauler.position==at and game.player.health==5,"Pause freezes warning, movement and damage")
	game.set_paused(false)
	game.player.position = game.Map.Wilds.ENTRY
	await ticks(180)
	check(not mauler.alerted and mauler.position.distance_to(mauler.home)<135,"Leaving the territory cancels the attack and returns the enemy to its camp")
	await duel(mauler,Vector2(110,0))
	var coins: int = game.coins
	check(mauler.receive_hit(Vector2.RIGHT,3,310),"A three-damage skill can defeat a mauler")
	check(not mauler.active and mauler.sprite.pose_index==7 and game.coins==coins+2 and game.forest_defeated.has(mauler.resident_id),"Defeat shows recoil, cancels attacks and awards the unique reward")
	check(not mauler.receive_hit(Vector2.RIGHT,3) and game.coins==coins+2,"Defeated enemies cannot be hit again for duplicate coins")
	game._load_zone("river","wilds")
	await ticks(2)
	check(game.peaceful_mode and game.dogs.is_empty(),"Hostiles and their attacks cannot leak into Riverbend")
	game._load_zone("wilds","river")
	check(game.dogs.size()==11 and game.dogs.filter(func(dog): return dog.variant=="mauler").size()==3,"A defeated role stays defeated across travel")
	game._load_zone("town","forest")
	check(game.dogs.all(func(dog): return not dog.enemy and dog.sprite.actor_id=="warden"),"Town wardens retain their friendly blue artwork and behavior")
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Actual local patrols and mixed population, distinct artwork, locked telegraphs, physical slash/lunge/sweep damage and dodges, warning bounds, collision during a dash, recovery hit safety, interruption/hurt invulnerability, pause, leash, unique defeat rewards, persistent roles and friendly-town isolation."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"bandit_test_results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Bandits: ",checks-failures.size(),"/",checks," checks passed.")
	quit(0 if failures.is_empty() else 1)
