extends Node
const ROOT := "res://experiments/anime_hub_demo_v07/"
const SLOT := "/tmp/kingdom-equipment-test.json"
const Store := preload("res://experiments/anime_hub_demo_v07/tools/save_store.gd")
var game: Node2D
var flow: Node
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

func approach(id: String) -> bool:
	if not game.interactables.has(id):
		check(false,"Missing interaction: "+id)
		return false
	game.player.route = game.find_path(game.player.position,game.interactables[id].at)
	for i in 2400:
		await get_tree().physics_frame
		if game.nearest==id:
			break
	check(game.nearest==id,"Physically approach "+id)
	game.player.stop_motion()
	return game.nearest==id

func travel(id: String, zone: String) -> bool:
	if not game.exits.has(id):
		check(false,"Missing connected exit: "+id)
		return false
	game.player.route = game.find_path(game.player.position,game.exits[id].at)
	for i in 3600:
		await get_tree().physics_frame
		if game.zone!=zone and game.near_exit==id and not game.transitioning and not game.exits[id].get("automatic",true):
			await key(KEY_E)
		if game.zone==zone and not game.transitioning:
			break
	var reached: bool = game.zone==zone and not game.transitioning
	check(reached,"Walk through the connected doorway: "+id+" → "+zone)
	if reached:
		check(game.is_walkable(game.player.position,14),"Door arrival is clear in "+zone)
	return reached

func mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	get_tree().root.push_input(event,true)
	await get_tree().process_frame

func mouse_move(at: Vector2, relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_tree().root.push_input(event,true)
	await get_tree().process_frame

func drag(from: Control, to: Control) -> void:
	var start := from.global_position+from.size*.5
	var end := to.global_position+to.size*.5
	await mouse_move(start,Vector2.ZERO)
	await mouse_button(start,true)
	await mouse_move(start+Vector2(25,0),Vector2(25,0))
	await mouse_move(end,end-start)
	await get_tree().process_frame
	await mouse_button(end,false)
	await ticks(2)

func run() -> void:
	for suffix in ["",".bak",".tmp",".auto",".auto.bak",".v1",".legacy_captain"]:
		if FileAccess.file_exists(SLOT+suffix):
			DirAccess.remove_absolute(SLOT+suffix)
	game = load(ROOT+"demo.tscn").instantiate()
	game.save_path = SLOT
	add_child(game)
	Engine.max_fps = 0
	game.auto_clock = false
	await ticks(3)
	check(game.state.equipment.size()==7,"Seven real GLoot slots represent helmet, chest, pants, gloves, boots, weapon and charm")
	check(game.state.equipped_id("chest")=="traveller_tunic" and game.state.equipped_id("legs")=="field_trousers","The cat starts with clothing in the correct body slots")
	check(game.state.maximum_health==5 and game.state.stats().attack==1,"Starting clothing preserves the original health and sword balance")
	await key(KEY_I)
	check(game.backpack_open and game.ui.satchel.visible and game.paused,"I opens the paper-doll inventory and pauses play")
	check(game.ui.satchel.slots.size()==7 and game.ui.satchel.grid.size()==24,"The actual equipment screen contains seven body targets and a 24-cell backpack")
	check(game.ui.satchel.character_image.texture!=null,"The character preview uses the prepared full-body illustration")
	var images := {}
	for slot in game.ui.satchel.slots.values():
		check(slot.icon!=null,"Each equipped/empty body slot has its own image")
		images[slot.icon.get_rid()] = true
	check(images.size()==7,"Body slots do not reuse one generic equipment image")
	check(not game.ui.satchel.slots.boots._can_drop_data(Vector2.ZERO,{"item":"travel_sword","origin":"bag"}),"A sword cannot be dropped into the boots slot")
	await key(KEY_ESCAPE)
	if not await approach("warden"):
		finish(); return
	await key(KEY_E)
	check(game.state.accepted,"Bram's first quest remains available alongside the new blacksmith quest")
	for pair in [["north","district"],["forge","forge"]]:
		if not await travel(pair[0],pair[1]):
			finish(); return
	check(game.humans.size()==1 and game.interactables.forge_smith.anchor.asset=="human_smith","Tomas is a real furnished-interior NPC")
	check(game.interactables.forge_smith.anchor.position.y<game.Forge.iso(4.4,3.1).y,"The smith stands behind the y-sorted counter")
	check(game.audio.music_id=="music_town" and game.audio.surface_at(game.player.position)=="stone","The workshop has indoor town audio and stone footfalls")
	if not await approach("forge_smith"):
		finish(); return
	await key(KEY_E)
	check(game.shopping and game.ui.forge_view.visible,"E at the counter opens the actual blacksmith interface")
	game.ui.forge_view.quest_button.pressed.emit()
	check(game.state.smith_accepted and game.state.smith_quest.started,"The actual Accept quest button starts the second Questify graph")
	check(get_tree().root.get_node("Questify").get_quests().size()==2,"Both quests coexist without replacing one another")
	game.ui.forge_view.buy_buttons.leather_cap.pressed.emit()
	check(game.coins==4 and game.state.count("leather_cap")==1,"The forge's Buy button grants an illustrated helmet and charges its price")
	check(not game.buy_forge("leather_cap") and game.coins==4,"Owned gear cannot be purchased twice")
	check(not game.buy_forge("reinforced_vest") and game.coins==4,"Unaffordable equipment cannot create debt or free items")
	await key(KEY_ESCAPE)
	await key(KEY_I)
	game.ui.satchel.select("leather_cap","bag")
	check(game.ui.satchel.primary_button.text.contains("Helmet") and game.ui.satchel.comparison.text.contains("(+1)"),"Selecting the helmet shows its target slot and real stat comparison")
	game.ui.satchel.primary_button.pressed.emit()
	check(game.state.equipped_id("head")=="leather_cap" and game.player.maximum_health==6,"The actual Equip button places the helmet and raises maximum health")
	check(game.state.count("leather_cap")==0,"An equipped piece is removed from the backpack")
	await key(KEY_I)
	for pair in [["district","district"],["south","town"],["southeast","trail"],["river","river"],["wilds","wilds"]]:
		if not await travel(pair[0],pair[1]):
			finish(); return
	var captain: Node2D
	for dog in game.dogs:
		dog.set_physics_process(false)
		if dog.resident_id==game.GameState.CAPTAIN_ID:
			captain = dog
	check(captain!=null and captain.captain and captain.health==8,"Rook is an eight-heart captain among the existing twelve bandits")
	game.player.route = game.find_path(game.player.position,game.Map.Wilds.CAMPS[3]+Vector2(-125,0))
	for i in 4800:
		await get_tree().physics_frame
		if game.player.route.is_empty():
			break
	check(game.player.position.distance_to(game.Map.Wilds.CAMPS[3])<220,"The far southeast clearing is physically connected to the forest entrance")
	game.player.automated = true
	game.player.stop_motion()
	game.player.position = captain.home+Vector2(110,0)
	game.player.reset_physics_interpolation()
	game.player.health = game.player.maximum_health
	game.player.grace = 0
	captain.alerted = true
	captain.cooldown = 0
	captain.set_physics_process(true)
	await ticks(5)
	check(captain.windup>1.0,"The stronger captain gives a longer visible sweep warning")
	await ticks(100)
	check(game.player.health==4,"Rook's committed sweep deals two actual hearts of damage")
	captain.set_physics_process(false)
	captain.windup = 0
	captain.swing = 0
	captain.grace = 0
	game.player.grace = 100
	game.player.position = captain.position-Vector2(75,0)
	game.player.facing = Vector2.RIGHT
	check(game.player.try_attack(Vector2.RIGHT),"The starter sword can attack Rook")
	await ticks(42)
	check(captain.health==7,"The starter sword deals one actual damage to the stronger enemy")
	for cast in 2:
		captain.grace = 0
		game.player.skill_cooldown = 0
		game.player.position = captain.position-Vector2(170,0)
		game.player.facing = Vector2.RIGHT
		check(game.player.try_skill(),"Wind Slash can be cast against Rook")
		await ticks(85)
	check(captain.health==1,"Two real starter Wind Slash projectiles remove six captain hearts")
	captain.grace = 0
	game.player.position = captain.position-Vector2(75,0)
	game.player.facing = Vector2.RIGHT
	game.player.try_attack()
	await ticks(42)
	check(not captain.active and game.forest_defeated.has(game.GameState.CAPTAIN_ID),"Actual combat defeats Rook and records his permanent identity")
	check(game.interactables["loot:"+game.GameState.CAPTAIN_ID].name.contains("tools"),"Rook's dropped pouch identifies the stolen tools")
	game.player.automated = false
	if not await approach("loot:"+game.GameState.CAPTAIN_ID):
		finish(); return
	await key(KEY_E)
	check(game.state.tools_recovered and game.state.count("smith_tools")==1,"Actual E collects the unique hammer and tongs")
	check(game.state.smith_quest.get_active_objectives()[0].id=="emberforge.return","Questify advances the blacksmith quest to its hand-in objective")
	# Fixed placements keep the subsequent three-target action deterministic;
	# the separate bandit suite tests pursuit and all ordinary attack patterns.
	var center: Vector2 = game.Map.Wilds.CAMPS[0]
	game.player.position = center
	game.player.stop_motion()
	game.player.facing = Vector2.RIGHT
	for i in 3:
		game.dogs[i].position = center+Vector2(150+i*115,0)
	game.player.skill_cooldown = 0
	game.player.try_skill()
	await ticks(85)
	check(game.forest_defeated.size()==4,"The original piercing skill still defeats three ordinary bandits")
	for id in ["wild_dog_0_0","wild_dog_0_1","wild_dog_0_2"]:
		if not await approach("loot:"+id):
			finish(); return
		await key(KEY_E)
	for pair in [["river","river"],["trail","trail"],["town","town"]]:
		if not await travel(pair[0],pair[1]):
			finish(); return
	if not await approach("warden"):
		finish(); return
	await key(KEY_E)
	check(game.state.rewarded and game.state.count("warden_charm")==1,"Bram's first quest can be completed during the new quest")
	for pair in [["north","district"],["forge","forge"]]:
		if not await travel(pair[0],pair[1]):
			finish(); return
	if not await approach("forge_smith"):
		finish(); return
	await key(KEY_E)
	check(game.ui.forge_view.quest_button.text.contains("Return"),"The actual shop interface offers the completed tools hand-in")
	game.ui.forge_view.quest_button.pressed.emit()
	check(game.state.smith_rewarded and game.state.smith_quest.completed and game.state.count("smith_tools")==0,"Hand-in consumes the tools and completes the second Questify graph")
	check(game.state.count("tempered_sword")==1 and game.coins==34,"Tomas grants one upgraded sword and exactly twelve coins")
	var balance: int = game.coins
	check(not game.smith_quest_action() and game.coins==balance,"The smith reward cannot be repeated")
	for id in ["reinforced_vest","hunter_boots","swift_charm"]:
		game.ui.forge_view.buy_buttons[id].pressed.emit()
	check(game.coins==0,"The remaining three upgrades cost the earned thirty-four coins")
	await key(KEY_ESCAPE)
	await key(KEY_I)
	var view = game.ui.satchel
	view.select("tempered_sword","bag")
	check(view.comparison.text.contains("Sword 2 (+1)"),"The new sword's comparison reflects a real damage upgrade")
	view.primary_button.pressed.emit()
	check(game.state.equipped_id("weapon")=="tempered_sword" and game.state.count("travel_sword")==1,"Weapon swaps return the old sword to the backpack")
	view.select("reinforced_vest","bag")
	view.primary_button.pressed.emit()
	view.select("warden_charm","bag")
	view.primary_button.pressed.emit()
	view.select("hunter_boots","bag")
	view.primary_button.pressed.emit()
	check(game.player.maximum_health==9 and game.state.stats().attack==2 and game.state.stats().speed>1.09,"Helmet, chest, charm, boots and sword all affect the real derived stats")
	view.select("swift_charm","bag")
	check(view.comparison.text.contains("(-1)") and view.comparison.text.contains("4.5"),"Charm comparison shows the heart-versus-recharge tradeoff")
	game.player.health = 9
	view.primary_button.pressed.emit()
	check(game.player.maximum_health==8 and game.player.health==8 and game.state.count("warden_charm")==1,"Swapping charms clamps health and returns the previous charm")
	check(is_equal_approx(game.state.stats().recharge,4.5),"The wind charm shortens actual skill recharge")
	var head = view.slots.head
	var backpack = view.grid[-1]
	await drag(head,backpack)
	check(game.state.equipped_id("head")=="" and game.state.count("leather_cap")==1,"A real pointer drag unequips the helmet into the backpack")
	var cap_cell: Control
	for cell in view.grid:
		if cell.item_id=="leather_cap":
			cap_cell = cell
	if cap_cell!=null:
		await drag(cap_cell,view.slots.head)
	check(game.state.equipped_id("head")=="leather_cap" and game.state.count("leather_cap")==0,"A real pointer drag equips the helmet in its body slot")
	var old_boots: String = game.state.equipped_id("boots")
	view.slots.boots._drop_data(Vector2.ZERO,{"item":"travel_sword","origin":"bag"})
	check(game.state.equipped_id("boots")==old_boots and game.state.count("travel_sword")==1,"A mismatched drop cannot move or duplicate equipment")
	await key(KEY_I)
	await key(KEY_J)
	check(game.journal_open and game.paused and game.ui.journal_view.visible,"J opens the proper quest journal")
	game.ui.journal_view.cards.morning_rounds.pressed.emit()
	game.ui.journal_view.track_button.pressed.emit()
	check(game.state.tracked_quest=="morning_rounds" and game.ui.journal_view.objectives.text.contains("Pippa"),"Journal cards display objectives and change the tracked quest")
	check(game.objective.text==game.OBJECTIVES[game.quest_stage],"The HUD actually follows the quest selected in the journal")
	await key(KEY_ESCAPE)
	check(not game.journal_open and not game.paused,"Esc closes the quest journal and resumes play")
	check(game.save_game(),"All seven slots and both completed quests serialize")
	game.state.unequip_item("chest")
	check(game.load_game() and game.state.equipped_id("chest")=="reinforced_vest" and game.state.smith_quest.completed,"Save/load restores the workshop location, armor and second Questify graph")
	check(game.zone=="forge" and game.state.tracked_quest=="morning_rounds","The new interior and tracked quest survive loading")
	await verify_combat_and_movement()
	await verify_title_and_autosave()
	verify_legacy_migration()
	finish()

func verify_combat_and_movement() -> void:
	game._load_zone("wilds","river")
	for dog in game.dogs:
		dog.set_physics_process(false)
	var target = game.dogs[0]
	var center: Vector2 = game.Map.Wilds.CAMPS[1]
	game.player.position = center
	game.player.stop_motion()
	game.player.automated = true
	game.player.facing = Vector2.RIGHT
	target.position = center+Vector2(75,0)
	target.grace = 0
	game.player.try_attack()
	await ticks(42)
	check(target.health==1,"The equipped upgraded sword deals two actual melee damage")
	target.maximum_health = 5
	target.health = 5
	target.grace = 0
	target.position = center+Vector2(180,0)
	game.player.skill_cooldown = 0
	game.player.try_skill()
	check(is_equal_approx(game.player.skill_cooldown,4.5),"Casting uses the equipped charm's 4.5-second cooldown")
	await ticks(21)
	var waves := get_tree().get_nodes_in_group("wind_slashes")
	check(waves.size()==1 and waves[0].damage==4,"The equipped sword gives the actual Wind Slash projectile four damage")
	game.player.swing = 0
	game.toggle_backpack()
	game.ui.satchel.select("travel_sword","bag")
	game.ui.satchel.primary_button.pressed.emit()
	game.toggle_backpack()
	await ticks(65)
	check(target.health==1,"A projectile retains its cast-time damage if the weapon is changed while it flies")
	game.toggle_backpack()
	game.ui.satchel.select("travel_sword","equipped")
	game.ui.satchel.primary_button.pressed.emit()
	game.toggle_backpack()
	check(not game.player.try_attack() and not game.player.try_skill(),"An empty weapon slot disables both actual weapon attacks")
	game.toggle_backpack()
	game.ui.satchel.select("tempered_sword","bag")
	game.ui.satchel.primary_button.pressed.emit()
	game.toggle_backpack()
	game._load_zone("town","start")
	var distances: Array[float] = []
	for id in ["trail_boots","hunter_boots"]:
		game.state.equip_item(id)
		game.player.position = Vector2(800,930)
		game.player.stop_motion()
		game.player.automated = false
		await ticks(2)
		var start: Vector2 = game.player.position
		Input.action_press("hub_right")
		await ticks(30)
		Input.action_release("hub_right")
		await ticks(1)
		distances.append(game.Actor.ground_vector(game.player.position-start).length())
	check(distances[1]/distances[0]>1.06 and distances[1]/distances[0]<1.14,"The boots increase real walking distance by approximately ten percent")
	game.player.stop_motion()
	game.save_game()

func verify_title_and_autosave() -> void:
	game.free()
	flow = load(ROOT+"title.tscn").instantiate()
	flow.save_path = SLOT
	add_child(flow)
	game = flow.game
	Engine.max_fps = 0
	check(flow.menu.visible and game.title_active and game.paused and not flow.continue_button.disabled,"The title detects saved progress and suspends gameplay")
	flow.continue_button.pressed.emit()
	check(not flow.menu.visible and game.autosave_enabled and not game.paused and game.state.smith_rewarded,"The actual Continue button restores the saved journey")
	check(flow.return_to_title() and flow.menu.visible,"Returning to title safely saves the current journey")
	flow.begin_new()
	check(flow.confirmation.visible and flow.game.state.smith_rewarded,"New Journey asks before replacing an existing autosave")
	flow.begin_new(true)
	game = flow.game
	Engine.max_fps = 0
	game.auto_clock = false
	check(game.coins==12 and not game.state.smith_accepted and game.state.equipped_id("chest")=="traveller_tunic","Confirmed New Journey resets quests and equipment")
	await ticks(75)
	check(FileAccess.file_exists(SLOT+".auto"),"A new session writes its own autosave slot")
	var store := Store.new()
	check(store.load_document(SLOT).state.smith.rewarded,"Starting a new journey preserves the old manual save")
	game.interact("warden")
	await ticks(75)
	check(store.latest_document(SLOT).state.quest.accepted and not store.latest_document(SLOT).state.smith.accepted,"Continue selects the newer autosave even when saves share a filesystem timestamp")
	check(store.latest_document(SLOT).state.coins==12,"A safe quest milestone autosaves the current state")
	if await travel("bakery","bakery"):
		await ticks(75)
		check(store.latest_document(SLOT).player.zone=="bakery","Safe physical travel creates an autosave in the destination")
	game._load_zone("wilds","river")
	game.player.stop_motion()
	var dog = game.dogs[0]
	dog.set_physics_process(false)
	dog.alerted = true
	dog.position = game.player.position+Vector2(180,0)
	var previous := FileAccess.get_file_as_string(SLOT+".auto")
	game.queue_autosave()
	await ticks(75)
	check(game.autosave_queued and FileAccess.get_file_as_string(SLOT+".auto")==previous,"Autosaving waits while an alerted enemy is nearby")
	dog.alerted = false
	await ticks(5)
	check(not game.autosave_queued and store.latest_document(SLOT).player.zone=="wilds","The queued autosave completes once the area is safe")
	game.autosave_enabled = false

func verify_legacy_migration() -> void:
	var store := Store.new()
	var legacy := {"format":"project_kingdom","version":1,"state":{"coins":23,"delivery_stage":2,"clock":2.25,"discoveries":["old_elm"],"district_places":[],"forest_defeated":["wild_dog_0_0","wild_dog_0_1","wild_dog_0_2"],"forest_recoveries":1,"loot":{},"items":{"bread":1,"tea":0,"honey":0,"bandit_badge":0,"travel_sword":0,"warden_charm":0},"equipment":{"weapon":"travel_sword","charm":"warden_charm"},"quest":{"accepted":true,"rewarded":true}},"player":{"zone":"town","position":[840,905],"health":4,"facing":[.7071,.7071],"skill_cooldown":2.0}}
	var path := SLOT+".v1"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var original := FileAccess.get_file_as_bytes(path)
	var upgraded := store.load_document(path)
	check(not upgraded.is_empty() and store.migrated and upgraded.version==2,"An actual version-1 disk save migrates to schema 2")
	check(FileAccess.get_file_as_bytes(path)==original,"Reading an old save leaves the original file byte-for-byte intact")
	if upgraded.is_empty():
		return
	check(upgraded.state.equipment.charm=="warden_charm" and upgraded.state.equipment.chest=="traveller_tunic","Migration keeps old equipment and supplies the new clothing slots")
	game.save_path = path
	check(game.load_game() and game.coins==23 and game.quest_stage==2 and game.player.health==4,"The migrated save restores the player's real progress and health")
	check(game.state.count("bread")==1 and game.state.quest.completed and game.state.maximum_health==6,"Old inventory, completed quests and charm benefits survive migration")
	legacy.state.forest_defeated.append(game.GameState.CAPTAIN_ID)
	legacy.state.items.bandit_badge = 1
	var cleared := store.upgrade(legacy)
	check(store.validate(cleared) and cleared.state.smith.tools_recovered and cleared.state.items.smith_tools==1,"A captain defeated in an old journey grants the recovered tools without respawning him")
	legacy.state.items.bandit_badge = 0
	legacy.state.loot[game.GameState.CAPTAIN_ID] = {"position":[3180,2120]}
	var pending := store.upgrade(legacy)
	check(store.validate(pending) and not pending.state.smith.tools_recovered and pending.state.items.smith_tools==0,"An old uncollected captain pouch keeps the tools on the ground")
	var invalid := upgraded.duplicate(true)
	invalid.state.equipment.head = "swift_charm"
	check(not store.validate(invalid),"Save validation rejects equipment in an incompatible body slot")
	invalid = upgraded.duplicate(true)
	invalid.state.items.travel_sword = 1
	check(not store.validate(invalid),"Save validation rejects a duplicated equipped item")
	invalid = upgraded.duplicate(true)
	invalid.state.smith.rewarded = true
	check(not store.validate(invalid),"Save validation rejects an unearned blacksmith reward")
	invalid = upgraded.duplicate(true)
	invalid.state.items.bread = -1
	check(not store.validate(invalid),"New slots cannot bypass existing item validation")

func finish() -> void:
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Real connected workshop travel and counter interaction, two Questify quests, actual captain combat and unique tools, shop purchases, paper-doll slots, real pointer drag/drop, stat comparison and derived melee/projectile/movement effects, journal tracking, full saves, title flow, safe autosaves and version-1 migration."}
	FileAccess.open(ROOT+"equipment_test_results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Equipment and Emberforge: ",checks-failures.size(),"/",checks)
	if is_instance_valid(flow):
		flow.free()
	elif is_instance_valid(game):
		game.free()
	get_tree().quit(0 if failures.is_empty() else 1)
