extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: run.call_deferred()

func check(ok: bool, words: String) -> void:
	checks += 1
	if not ok:
		failures.append(words)
		push_error(words)

func settle() -> void:
	for i in 4: await process_frame

func capture(label: String) -> void:
	if "--capture-health-ui" not in OS.get_cmdline_user_args(): return
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/kingdom_"+label+".png")

func freeze(game: Node2D) -> void:
	game.player.process_mode = Node.PROCESS_MODE_DISABLED
	for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
	game.dialogue_left = 0
	game.talk_panel.hide()

func run() -> void:
	var game: Node2D = load(ROOT+"demo.tscn").instantiate()
	game.save_path = "/tmp/kingdom-enemy-health-test.json"
	root.add_child(game)
	game.autosave_enabled = false
	game.auto_clock = false
	game._load_zone(game.Moonlight.CHAPEL,"start")
	freeze(game)
	game.player.position = Vector2(1400,870)
	game.player.reset_physics_interpolation()
	game.camera.force_update_scroll()
	var boss: Node2D = game.dogs.filter(func(dog): return dog.is_boss())[0]
	await settle()
	check(boss.level==12 and boss.enemy_name=="Blackthorn Captain","Blackthorn has a configured level and readable name")
	check(game.ui.boss_health.visible and game.ui.boss_health.target==boss,"Live chapel boss binds to the named health banner")
	check(game.ui.boss_health.mouse_filter==Control.MOUSE_FILTER_IGNORE,"The banner cannot block attacks or click-to-move")
	var banner_rect: Rect2 = Rect2(game.ui.boss_health.position,game.ui.boss_health.size)
	check(is_equal_approx(banner_rect.get_center().x,960) and banner_rect.position.y<40,"Boss banner occupies the upper center")
	var clock_rect: Rect2 = Rect2(game.ui.clock_dial.position,game.ui.clock_dial.size*game.ui.clock_dial.scale)
	check(not banner_rect.intersects(clock_rect),"Boss banner and illustrated clock do not overlap")
	check(game.dogs.filter(func(dog): return not dog.is_boss()).all(func(dog): return dog.level in [8,9]),"Dungeon mobs have role-specific level labels")
	await capture("blackthorn_health_full")
	var old_health: int = boss.health
	boss.receive_hit(Vector2.RIGHT,9,0,game.player)
	await settle()
	check(game.ui.boss_health.target.health==old_health-9,"Boss health readout follows actual incoming damage")
	await capture("blackthorn_health_damaged")
	game.set_paused(true)
	await settle()
	check(not game.ui.boss_health.visible,"Pause menus hide the combat banner")
	game.set_paused(false)
	await settle()
	check(game.ui.boss_health.visible,"Returning to gameplay restores the live boss banner")
	boss.grace = 0
	boss.receive_hit(Vector2.RIGHT,boss.health,0,game.player)
	await settle()
	check(not game.ui.boss_health.visible and game.ui.boss_health.target==null,"A defeated boss no longer leaves a stale health banner")
	check(game.ui.clock_dial.position==Vector2(848,7) and game.ui.clock_dial.scale==Vector2(.8,.8),"Clock returns to its normal placement after the boss fight")
	game._load_zone(game.Moonlight.CHAPEL,"start")
	freeze(game)
	await settle()
	check(game.ui.boss_health.visible and game.ui.boss_health.target.health==36,"A rematch binds the banner to the new full-health boss")
	game._load_zone("town","start")
	freeze(game)
	await settle()
	check(not game.ui.boss_health.visible,"Town has no hostile boss readout")
	game._load_zone("wilds","start")
	freeze(game)
	var rook: Node2D = game.dogs.filter(func(dog): return dog.captain)[0]
	game.player.position = rook.position+Vector2(150,0)
	await settle()
	check(rook.level==8 and rook.enemy_name=="Captain Rook","The named woodland captain uses the same level/name system")
	check(game.ui.boss_health.visible and game.ui.boss_health.target==rook,"Approaching Rook selects his banner")
	game.hide()
	game.ui.hide()
	game.camera.enabled = false
	var stoneback: RefCounted = load("res://experiments/overworld_2d_v01/stoneback.gd").new()
	var arena: Node2D = load("res://experiments/overworld_2d_v01/ivykeep_arena.gd").new()
	arena.boss = stoneback
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	check(arena.Boss.LEVEL==10 and stoneback.health==18,"Stoneback level metadata leaves existing boss health intact")
	await capture("stoneback_health_full")
	stoneback.set_phase("recover",2)
	stoneback.take_damage(6)
	arena.hud.queue_redraw()
	await capture("stoneback_health_damaged")
	check(stoneback.health==12,"Stoneback's shared banner follows the existing combat damage")
	arena.queue_free()
	game.queue_free()
	await process_frame
	print("ENEMY HEALTH UI CHECKS ",checks," FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
