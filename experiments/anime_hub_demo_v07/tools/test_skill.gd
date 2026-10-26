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

func key_q(pressed := true) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_Q
	key.pressed = pressed
	return key

func waves() -> Array:
	return get_nodes_in_group("wind_slashes")

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	game.auto_clock = false
	game.player.automated = true
	await ticks(3)
	check(is_instance_valid(game.player.weapon) and is_instance_valid(game.player.combat_art),"Cat has a sheathed walking state and a separate drawn combat body")
	check(not game.player.try_skill(),"The skill cannot harm peaceful town residents")
	game._update_hud()
	check(game.ui.skill_panel.visible and game.ui.skill_button.disabled and game.ui.skill_label.text.contains("Briarwood"),"Town UI explains where the skill becomes available")
	var feet: Vector2 = game.player.position
	for direction in ["e","se","s","sw","w","nw","n","ne"]:
		game.player.sprite.set_pose("idle",direction,0)
		game.player.weapon.sync_pose()
		check(not game.player.weapon.visible and game.player.weapon.z_index==0,"Walking cat keeps the sword sheathed in "+direction)
	for facing in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
		var regions: Dictionary = {}
		for progress in [.05,.4,.65,.9]:
			game.player.combat_art.pose(facing,progress,false)
			regions[game.player.combat_art.current_pose] = true
		check(regions.size()==4,"A directional attack has four genuinely different drawn body/arm/sword poses: "+str(facing))
	check(game.player.position==feet,"Previewing combat poses does not move the physics feet")
	game._load_zone("wilds","river")
	for dog in game.dogs:
		dog.set_physics_process(false)
	var center: Vector2 = game.Map.Wilds.CAMPS[0]
	game.player.position = center
	game.player.facing = Vector2.RIGHT
	game.player.stop_motion()
	game._update_hud()
	check(not game.ui.skill_button.disabled and game.ui.skill_button.text.contains("WIND"),"A distinct clickable Wind Slash button is ready in combat")
	var first = game.dogs[0]
	first.position = center+Vector2(75,0)
	game.player.try_attack()
	await ticks(5)
	check(game.player.combat_art.visible and not game.player.sprite.visible and not game.player.weapon.visible,"Drawn attack replaces the idle body and floating equipment during a swing")
	check(first.health==3,"Normal sword attack has anticipation before its hit")
	await ticks(10)
	check(first.health==2,"Normal sword attack still deals one actual damage")
	await ticks(25)
	check(not game.player.combat_art.visible and game.player.sprite.visible and not game.player.weapon.visible,"Attack recovers to the registered walking/idle character")
	# Reproduce the reported problem: Q pressed while Space is held mid-attack.
	first.health = 3
	first.grace = 0
	for dog in game.dogs:
		dog.health = 3
		dog.grace = 0
	first.position = center+Vector2(160,0)
	game.dogs[1].position = center+Vector2(260,10)
	game.dogs[2].position = center+Vector2(390,-10)
	game.dogs[3].position = center+Vector2(-90,0)
	game.player.automated = false
	Input.action_press("hub_attack")
	await ticks(4)
	check(game.player.swing>0 and game.player.attack_kind=="light","Holding Space starts a normal sword attack")
	Input.parse_input_event(key_q())
	await ticks(1)
	check(game.player.skill_buffer>0,"An actual Q press during a normal swing is queued instead of discarded")
	Input.parse_input_event(key_q(false))
	game._update_hud()
	check(game.ui.skill_label.text.contains("Queued"),"The interface acknowledges the queued skill")
	var coins: int = game.coins
	await ticks(40)
	Input.action_release("hub_attack")
	game.player.automated = true
	check(game.player.attack_kind=="wind" and game.player.skill_cooldown>0,"Queued Q takes priority over continued Space attacks")
	for tick in 30:
		if game.player.skill_casts==1:
			break
		await physics_frame
	check(game.player.skill_casts==1 and waves().size()==1,"The skill launches a real independent projectile after its windup")
	await ticks(45)
	check(not first.active and not game.dogs[1].active and not game.dogs[2].active,"The projectile travels beyond melee range and pierces three dogs for three damage each")
	check(game.dogs[3].health==3,"A projectile launched forward cannot hit a dog behind the cat")
	check(game.coins==coins+6 and game.forest_defeated.size()==3,"Projectile defeats use the normal unique coin rewards")
	check(not game.player.try_skill(),"The skill cannot be recast during its six-second cooldown")
	game._update_hud()
	check(game.ui.skill_button.disabled and game.ui.skill_label.text.contains("Recharging"),"The actual button and label show cooldown state")
	var cooldown: float = game.player.skill_cooldown
	game.set_paused(true)
	await ticks(60)
	check(game.player.skill_cooldown==cooldown,"Pause freezes skill recharge")
	game.set_paused(false)
	await ticks(360)
	game._update_hud()
	check(game.player.skill_cooldown==0 and not game.ui.skill_button.disabled,"The skill becomes usable again after recharge")
	# The clickable button is a second complete input path.
	game.ui.skill_button.pressed.emit()
	await ticks(19)
	check(game.player.skill_casts==2 and waves().size()==1,"Clicking the skill button launches the same actual projectile")
	game.set_paused(true)
	var wave: Node2D = waves()[0]
	var wave_at: Vector2 = wave.position
	await ticks(30)
	check(wave.position==wave_at,"Pause freezes an airborne wind slash")
	game.set_paused(false)
	await ticks(65)
	check(waves().is_empty(),"A projectile expires at its bounded travel distance")
	# A real forest trunk must stop the projectile before a dog behind it.
	var tree_at := Vector2.ZERO
	for tree in game.Map.Wilds.trees():
		if tree.at.x>500 and tree.at.x<4100 and tree.at.y>400 and tree.at.y<2200:
			tree_at = tree.at
			break
	var blocked = game.dogs[3]
	blocked.position = tree_at+Vector2(80,0)
	blocked.grace = 0
	game.player.position = tree_at-Vector2(60,0)
	game.player.facing = Vector2.RIGHT
	game.player.cooldown = 0
	game.player.swing = 0
	game.player.skill_cooldown = 0
	game.player.try_skill()
	await ticks(45)
	check(blocked.health==3 and waves().is_empty(),"A solid forest trunk stops the wave and protects a dog behind it")
	game.player.skill_cooldown = 0
	game.player.cooldown = 0
	game.player.swing = 0
	game.player.position = center
	game.player.try_skill()
	await ticks(19)
	check(waves().size()==1,"A fresh cast is visible before travel")
	cooldown = game.player.skill_cooldown
	game._load_zone("river","wilds")
	await ticks(2)
	check(waves().is_empty() and game.player.swing==0 and game.player.skill_buffer==0,"Travel removes airborne attacks and clears buffered input")
	check(game.player.skill_cooldown<=cooldown and game.player.skill_cooldown>0,"Travel cannot reset the skill's cooldown")
	check(not game.player.try_skill(),"Skill remains harmless in peaceful Riverbend")
	game._load_zone("bakery","town")
	game.player.skill_cooldown = 0
	game.shopping = true
	check(not game.player.try_skill(),"Shopping blocks the skill")
	game.shopping = false
	game._load_zone("wilds","river")
	game.transitioning = true
	check(not game.player.try_skill(),"Travel fades block the skill")
	game.transitioning = false
	game.player.active = false
	check(not game.player.try_skill(),"A defeated cat cannot cast")
	Input.action_release("hub_attack")
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Drawn four-phase attacks in four real directions, body/equipment visibility and feet, actual Q input buffered while Space stays held, priority over normal swings, clickable skill input, real piercing three-damage projectile at range, direction, walls, lifetime, cooldown UI/recharge, pause in flight, travel cleanup and peaceful/modal guards."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"skill_test_results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Sword & Wind Slash: ",checks-failures.size(),"/",checks," checks passed.")
	quit(0 if failures.is_empty() else 1)
