extends Node

const ROOT := "res://experiments/anime_hub_demo_v07/"
const SLOT := "/tmp/kingdom-journey-test.json"
const SaveStore := preload("res://experiments/anime_hub_demo_v07/tools/save_store.gd")
var game: Node2D
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(1)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await ticks(1)

func approach(id: String) -> void:
	game.player.route = game.find_path(game.player.position,game.interactables[id].at)
	for i in 1800:
		await get_tree().physics_frame
		if game.nearest==id:
			break
	check(game.nearest==id,"Physically reach interaction: "+id)
	game.player.stop_motion()

func travel(id: String, destination: String) -> void:
	game.player.route = game.find_path(game.player.position,game.exits[id].at)
	for i in 2400:
		await get_tree().physics_frame
		if game.zone==destination and not game.transitioning:
			break
	check(game.zone==destination and not game.transitioning,"Physically cross the connected exit: "+id+" → "+destination)
	check(game.is_walkable(game.player.position,14),"Safe arrival: "+destination)

func run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	add_child(game)
	game.save_path = SLOT
	Engine.max_fps = 0
	game.auto_clock = false
	await ticks(4)
	if "--verify-save" in OS.get_cmdline_user_args():
		verify_relaunch()
		finish("journey_relaunch_results.json")
		return
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SLOT+suffix):
			DirAccess.remove_absolute(SLOT+suffix)
	check(game.state.bag is Inventory and game.state.weapon is ItemSlot,"Actual GLoot bag and equipped sword are installed")
	check(game.state.weapon.get_item().get_title().contains("sword"),"Starting sword belongs to the equipment slot")
	check(game.coins==12 and game.player.health==5 and not game.state.accepted,"Fresh game has the original balance and an unaccepted forest quest")
	await approach("warden")
	await key(KEY_E)
	check(game.state.accepted and game.state.quest.started and not game.state.quest.completed,"Actual E accepts Bram's Questify quest")
	game.interact("warden")
	check(get_tree().root.get_node("Questify").get_quests().size()==1,"Repeated acceptance cannot duplicate a quest")
	check(game.state.quest.get_active_objectives().size()==1,"Questify exposes the first active objective")
	check(not game.state.claim_reward() and game.coins==12,"Reward cannot be claimed before completing the objectives")
	await travel("southeast","trail")
	await approach("old_elm")
	game.interact()
	await travel("river","river")
	await travel("wilds","wilds")
	check(game.player.health==5 and game.state.accepted,"Health and accepted quest survive normal exploration")
	# Exercise actual action timing and projectile collision, with fixed target
	# placements so the acceptance test is deterministic rather than an AI duel.
	for dog in game.dogs:
		dog.set_physics_process(false)
	var center: Vector2 = game.Map.Wilds.CAMPS[0]
	game.player.position = center
	game.player.reset_physics_interpolation()
	game.player.facing = Vector2.RIGHT
	game.player.stop_motion()
	game.player.grace = 100
	game.player.health = 2
	for i in 3:
		game.dogs[i].position = center+Vector2(120+i*125,0)
	await key(KEY_Q)
	await ticks(85)
	check(game.forest_defeated.size()==3 and game.coins==18,"A real Q projectile defeats three bandits and grants their unique coin drops")
	check(game.state.pending_loot.size()==3 and game.state.count("bandit_badge")==0,"Badges exist as world pickups, not automatic inventory rewards")
	check(game.state.quest.get_active_objectives()[0].id=="briarwood.collect","Questify advances to collecting the badges")
	var first_id := "wild_dog_0_2"
	check(not game.collect_loot(first_id),"Out-of-range loot cannot be collected")
	check(game.save_game(),"An in-progress forest quest saves to an isolated disk slot")
	var first_document: Dictionary = game.make_save_document()
	game.state.coins = 0
	game.state.pending_loot.clear()
	check(game.load_game(),"An in-progress forest save loads")
	check(game.coins==18 and game.state.pending_loot.size()==3 and game.player.health==2,"Load restores coins, damaged health and uncollected loot")
	check(game.dogs.size()==9 and game.state.quest.get_active_objectives()[0].id=="briarwood.collect","Load preserves defeated enemies and the active Questify objective")
	for dog in game.dogs:
		dog.set_physics_process(false)
	for id in game.state.pending_loot.keys().duplicate():
		await approach("loot:"+id)
		await key(KEY_E)
	check(game.state.count("bandit_badge")==3 and game.state.pending_loot.is_empty(),"Actual movement and E collect all three GLoot badge items")
	check(not game.collect_loot(first_id),"A collected badge cannot be collected twice")
	check(game.state.can_claim() and game.state.quest.get_active_objectives()[0].id=="briarwood.return","Questify now asks for a return to Bram")
	# Take the actual connected route back. Disable AI only for deterministic
	# acceptance travel; the separate bandit suite covers pursuit and damage.
	await travel("river","river")
	await travel("trail","trail")
	await travel("town","town")
	check(game.player.health==2,"Crossing safe-zone boundaries does not grant free healing")
	await approach("warden")
	await key(KEY_E)
	check(game.state.rewarded and game.state.quest.completed,"Returning to Bram completes the real Questify graph")
	check(game.coins==28 and game.state.count("bandit_badge")==0 and game.state.count("warden_charm")==1,"Hand-in consumes three badges and grants exactly ten coins and one charm")
	game.interact("warden")
	check(game.coins==28 and game.state.count("warden_charm")==1,"Repeated hand-in cannot duplicate rewards")
	await key(KEY_I)
	check(game.backpack_open and game.paused and game.ui.satchel.visible and not game.pause_overlay.visible,"I opens the satchel and pauses the world")
	game.ui.satchel.primary_button.pressed.emit()
	check(game.state.charm.get_item()!=null and game.state.count("warden_charm")==0 and game.player.maximum_health==6,"The actual equipment button transfers the charm into a GLoot slot and adds a maximum heart")
	game.ui.satchel.primary_button.pressed.emit()
	check(game.player.maximum_health==5 and game.state.count("warden_charm")==1,"Unequipping returns the charm without duplicating it")
	game.ui.satchel.primary_button.pressed.emit()
	await key(KEY_ESCAPE)
	check(not game.backpack_open and not game.paused,"Esc closes the satchel and resumes exploration")
	await travel("bakery","bakery")
	await approach("shop_vendor")
	await key(KEY_E)
	check(game.shopping,"The physical counter opens Clover's shop")
	game.ui.shop_buttons[0].pressed.emit()
	check(game.state.count("bread")==1 and game.coins==26,"The actual shop button buys food into GLoot")
	game.ui.shop_buttons[1].pressed.emit()
	check(game.state.count("tea")==1 and game.coins==23,"Tea purchases use the same shared inventory")
	await key(KEY_ESCAPE)
	await key(KEY_H)
	check(game.player.health==4 and game.state.count("bread")==0,"Actual H consumes one loaf and restores two hearts")
	game.state.add_item("bread",2)
	await key(KEY_I)
	game.ui.satchel.select("bread","bag")
	game.ui.satchel.primary_button.pressed.emit()
	check(game.player.health==6 and game.state.count("bread")==1,"The satchel's actual Use button consumes food while the world is paused")
	check(not game.use_item("bread") and game.state.count("bread")==1,"Full-health use never wastes food")
	game.player.skill_cooldown = 4
	check(game.use_item("tea") and game.player.skill_cooldown==0 and game.state.count("tea")==0,"Tea refreshes the real skill even at full health")
	check(not game.use_item("bandit_badge") and not game.use_item("not_an_item"),"Non-food and unknown items cannot be consumed")
	await key(KEY_I)
	await travel("town","town")
	game.quest_stage = 2
	game.clock = 2.25
	game.player.health = 4
	game.player.facing = Vector2(-1,1).normalized()
	var before_save: Dictionary = game.make_save_document()
	await key(KEY_F5)
	check(FileAccess.file_exists(SLOT) and game.saves.last_error.is_empty(),"Actual F5 writes a complete save")
	game.coins = 1
	game.quest_stage = 0
	game.player.health = 1
	await key(KEY_F9)
	check(game.coins==23 and game.quest_stage==2 and game.player.health==4,"Actual F9 restores saved money, delivery progress and health")
	check(game.zone=="town" and game.player.position.distance_to(Vector2(before_save.player.position[0],before_save.player.position[1]))<.01,"Load restores the saved zone and location")
	check(game.state.rewarded and game.state.quest.completed and game.player.maximum_health==6,"Load rebuilds completed Questify progress and the equipped GLoot charm")
	check(game.state.count("bread")==1 and game.state.discoveries.has("old_elm") and is_equal_approx(game.clock,2.25),"Load preserves items, discoveries and shared time")
	check(game.saves.validate(game.make_save_document()),"The restored game can be serialized again without drift")
	# Full-document validation and backup recovery must be non-destructive.
	var store := SaveStore.new()
	for mutation in ["version","negative_money","fractional_money","unknown_item","bad_equipment","bad_zone","invalid_health","duplicate_badge","duplicate_enemy","bad_quest","bad_position","bad_loot"]:
		var invalid: Dictionary = before_save.duplicate(true)
		match mutation:
			"version": invalid.version = 999
			"negative_money": invalid.state.coins = -1
			"fractional_money": invalid.state.coins = 1.5
			"unknown_item": invalid.state.items.script = "res://bad.gd"
			"bad_equipment": invalid.state.equipment.charm = "bread"
			"bad_zone": invalid.player.zone = "res://unknown_scene.tscn"
			"invalid_health": invalid.player.health = 99
			"duplicate_badge": invalid.state.items.bandit_badge = 999
			"duplicate_enemy": invalid.state.forest_defeated.append(invalid.state.forest_defeated[0])
			"bad_quest": invalid.state.quest.accepted = false
			"bad_position": invalid.player.position = [9999999,0]
			"bad_loot": invalid.state.loot.unknown_enemy = {"position":[1,1]}
		check(not store.validate(invalid),"Reject invalid save field: "+mutation)
	check(not store.write_document(before_save,"/no_such_kingdom_directory/journey.json"),"Unwritable save path reports failure")
	var safe_coins: int = game.coins
	var primary := FileAccess.open(SLOT,FileAccess.WRITE)
	primary.store_string('{"format":"project_kingdom","version":999}')
	primary.close()
	check(not game.load_game() and game.coins==safe_coins,"Future save versions never change live state or silently load an older backup")
	primary = FileAccess.open(SLOT,FileAccess.WRITE)
	primary.store_string("truncated save")
	primary.close()
	check(game.load_game() and game.saves.used_backup,"A corrupt primary falls back to the last validated backup")
	check(game.forest_defeated.size()==3 and game.state.pending_loot.size()==3,"Backup restores its own exact uncollected-loot state")
	check(game.saves.write_document(before_save,SLOT),"A valid new save can replace a corrupt primary without destroying its known-good backup")
	check(game.load_game(),"Final saved completed journey loads cleanly")
	game.ui.load_button.pressed.emit()
	check(game.state.rewarded and not game.paused,"Pause-menu Continue button loads the completed journey")
	game.set_paused(true)
	game.ui.save_button.pressed.emit()
	check(game.saves.last_error.is_empty(),"Pause-menu Save button writes the current journey")
	game.set_paused(false)
	# Exercise the save contract in every existing zone, independently of the
	# connected route assertions above. These slots never touch user progress.
	for zone in ["town","bakery","district","trail","river","wilds"]:
		game._load_zone(zone,"start")
		game.player.health = 3
		var document: Dictionary = game.make_save_document()
		check(game.saves.write_document(document,SLOT+".zones"),"Save complete data in zone: "+zone)
		game.save_path = SLOT+".zones"
		check(game.load_game() and game.zone==zone and game.player.health==3 and game.is_walkable(game.player.position,14),"Restore health and safe location in zone: "+zone)
		await ticks(2)
	game.save_path = SLOT
	game.load_game()
	await ticks(3)
	var node_count := get_tree().get_node_count()
	var cache = load("res://addons/gloot/core/prototree/proto_tree_cache.gd")
	var cached_count: int = cache._cache.size()
	for i in 12:
		game.load_game()
		await ticks(3)
	check(get_tree().get_node_count()<=node_count+2,"Repeated loads do not accumulate world, inventory or listener nodes")
	for i in 20:
		var fresh_state = load(ROOT+"tools/game_state.gd").new()
		add_child(fresh_state)
		fresh_state.free()
	check(cache._cache.size()==cached_count,"Twenty fresh journeys reuse one cached GLoot prototype resource")
	check(game.state.quest.completed and get_tree().root.get_node("Questify").get_quests().size()==1,"Repeated loads keep exactly one completed Questify graph")
	finish("journey_test_results.json")

func verify_relaunch() -> void:
	check(game.load_game(),"A separate process loads the prior process's disk save")
	check(game.coins==23 and game.quest_stage==2 and game.player.health==4,"Money, deliveries and health survive process restart")
	check(game.state.count("bread")==1 and game.state.rewarded and game.state.quest.completed,"Inventory and completed Questify progress survive process restart")
	check(game.state.charm.get_item()!=null and game.player.maximum_health==6,"Equipped GLoot charm survives process restart")
	check(game.forest_defeated.size()==3 and game.state.pending_loot.is_empty(),"Unique defeats and consumed badges survive process restart")
	check(game.zone=="town" and game.is_walkable(game.player.position,14),"Restart restores a walkable saved location")
	game.interact("warden")
	check(game.coins==23 and game.state.count("warden_charm")==0,"Restart cannot reissue a completed quest reward")

func finish(report_name: String) -> void:
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"engine":Engine.get_version_info().string,"save_slot":SLOT,"scope":"Connected travel, real E/Q/I/H/F5/F9 input, actual projectile defeats and pickups, GLoot food/equipment/shop, Questify objectives and unique hand-in, full save/load, corruption and schema rejection."}
	FileAccess.open(ROOT+report_name,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print(report_name,": ",checks-failures.size(),"/",checks)
	game.free()
	get_tree().quit(0 if failures.is_empty() else 1)
