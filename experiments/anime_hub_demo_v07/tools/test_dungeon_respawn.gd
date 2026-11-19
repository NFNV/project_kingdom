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

func freeze() -> void:
	game.player.process_mode = Node.PROCESS_MODE_DISABLED
	for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED

func enter(zone: String) -> void:
	game._load_zone(zone,"start")
	freeze()

func run() -> void:
	game = load("res://experiments/anime_hub_demo_v07/demo.tscn").instantiate()
	game.save_path = "/tmp/kingdom-dungeon-respawn-test.json"
	root.add_child(game)
	game.auto_clock = false
	game.autosave_enabled = false
	game.state.moonlight = Moonlight.fresh_progress()
	game.state.moonlight.winch = true
	game.state.moonlight.vault_claimed = true
	game.state.moonlight.defeated = ["glade_1","chapel_1","vault_keeper"]
	for zone in [Moonlight.PASSAGE,Moonlight.CISTERN]:
		var count: int = Moonlight.ROOM_ENEMIES[zone].size()
		enter(zone)
		check(game.dogs.size()==count,zone+" starts populated")
		var soldier: Node2D = game.dogs[0]
		soldier.receive_hit(Vector2.RIGHT,soldier.health,0,game.player)
		check(not soldier.active and soldier.resident_id in game.state.moonlight.defeated,"A killed soldier enters this room's casualty list")
		var deadline: float = game.state.moonlight.respawn_at[zone]
		check(absf(deadline-Time.get_unix_time_from_system()-300)<2,"A kill starts the five-minute cooldown")
		enter(Moonlight.FOREST)
		enter(zone)
		check(game.dogs.size()==count-1,"Early re-entry preserves a partial clear")
		for dog in game.dogs: dog.receive_hit(Vector2.RIGHT,dog.health,0,game.player)
		check(game.dogs.all(func(dog): return not dog.active),"The full room can be cleared")
		deadline = game.state.moonlight.respawn_at[zone]
		check(Moonlight.progress_valid(game.state.moonlight),"Timed casualties preserve valid journey state")
		check(game.save_game(),"The respawn deadline saves to disk")
		check(game.load_game(),"Timed room state loads through the normal save entry point")
		freeze()
		check(game.dogs.is_empty(),"Loading before expiry keeps the cleared room empty")
		check(is_equal_approx(float(game.state.moonlight.respawn_at[zone]),deadline),"Save/load retains the original cooldown deadline")
		game.state.moonlight.respawn_at[zone] = Time.get_unix_time_from_system()-1
		await process_frame
		check(game.dogs.is_empty(),"Expired enemies do not spawn around the player inside an occupied room")
		enter(Moonlight.FOREST)
		enter(zone)
		check(game.dogs.size()==count and game.combat_active,"Re-entry after expiry restores every room soldier and combat")
		check(game.dogs.all(func(dog): return dog.active and dog.health==dog.maximum_health and not dog.alerted),"Respawned soldiers have full health and fresh AI")
		check(not game.state.moonlight.respawn_at.has(zone),"The completed respawn consumes its old deadline")
		check(Moonlight.ROOM_ENEMIES[zone].all(func(id): return id not in game.state.moonlight.defeated),"Respawn removes only the room's old casualties")
		check(["glade_1","chapel_1","vault_keeper"].all(func(id): return id in game.state.moonlight.defeated),"Forest, chapel and boss history survives the room reset")
		check(game.state.moonlight.winch and game.state.moonlight.vault_claimed,"Door and one-time reward progress survives the room reset")
		# Migration of the old seven-field saves that made these rooms empty.
		game.state.moonlight.erase("respawn_at")
		game.state.moonlight.defeated.append_array(Moonlight.ROOM_ENEMIES[zone])
		check(Moonlight.progress_valid(game.state.moonlight),"Legacy permanent-clear saves remain accepted")
		enter(zone)
		check(game.dogs.size()==count,"Legacy cleared rooms are repopulated on entry")
		check(game.saves.validate(game.make_save_document()),"Migrated room state can be saved in the current journey format")
	var bad: Dictionary = game.state.moonlight.duplicate(true)
	for deadlines in [{"unknown_room":100.0},{Moonlight.CISTERN:-1.0},{Moonlight.PASSAGE:"tomorrow"},{Moonlight.PASSAGE:INF}]:
		bad.respawn_at = deadlines
		check(not Moonlight.progress_valid(bad),"Invalid respawn metadata is rejected: "+str(deadlines))
	game.queue_free()
	await process_frame
	print("DUNGEON RESPAWN CHECKS ",checks," FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
