extends SceneTree
const Moonlight := preload("res://experiments/anime_hub_demo_v07/tools/moonlight_forest.gd")
var checks := 0
var failures: Array[String] = []
var capture := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, words: String) -> void:
	checks += 1
	if not ok:
		failures.append(words)
		push_error(words)

func run() -> void:
	capture = "--capture-lighting" in OS.get_cmdline_user_args()
	var game: Node2D = load("res://experiments/anime_hub_demo_v07/demo.tscn").instantiate()
	game.save_path = "/tmp/kingdom-forest-lighting-test.json"
	root.add_child(game)
	game.auto_clock = false
	game.autosave_enabled = false
	game._load_zone(Moonlight.FOREST,"start")
	game.dialogue_left = 0
	game.talk_panel.hide()
	game.player.process_mode = Node.PROCESS_MODE_DISABLED
	for dog in game.dogs: dog.process_mode = Node.PROCESS_MODE_DISABLED
	var detail: Node2D = game.moonlight_area.forest_detail
	check(game.moonlight_area.lantern_lights.size()==2,"Both forest lanterns have reusable illumination")
	check(not game.interactables.has("moon_camp") and not game.interactables.has("moon_well"),"Removed camp and cache leave no interaction prompts")
	check(not game.moonlight_area.layout.has_node(Moonlight.FOREST+"/Camp") and not game.moonlight_area.layout.has_node(Moonlight.FOREST+"/Moonwell"),"Removed props leave no placement markers")
	check(not game.world.get_children().any(func(node): return node.scene_file_path.ends_with("treasure_chest.tscn")),"The forest contains no spawned treasure chest")
	check(not game.pieces.any(func(piece): return piece.texture.resource_path.ends_with("fountain.tres")),"The forest contains no fountain sprite")
	var fountain_blocker := false
	for polygon in game.blockers:
		var center := Vector2.ZERO
		for at in polygon: center += at
		center /= polygon.size()
		fountain_blocker = fountain_blocker or center.distance_to(Vector2(2520,840))<1
	check(not fountain_blocker,"Removed fountain leaves no old collision ellipse")
	var colors: Array[Color] = []
	var averages: Array[float] = []
	for phase in 4:
		game.clock = float(phase)
		game._update_lighting()
		game.player.sprite.modulate = game.actor_tint
		for dog in game.dogs: dog.sprite.modulate = game.actor_tint
		colors.append(detail.modulate)
		check(detail.modulate==game.backgrounds[0].modulate,"High-detail panels and base painting match at phase "+str(phase))
		check(game.ui.skill_label.modulate==Color.WHITE,"Time-of-day grading leaves HUD brightness intact")
		for lamp in game.moonlight_area.lantern_lights:
			check(is_equal_approx(lamp.night_weight,game.Mill.night_weight(phase)),"Lantern intensity follows the forest clock")
			check(lamp.ground.z_index<0 and lamp.halo.z_index>0,"Lantern floor light and glass halo have correct layering")
		if capture:
			for i in 4: await process_frame
			await RenderingServer.frame_post_draw
			var frame := root.get_texture().get_image()
			var luminance := 0.0
			var samples := 0
			# Sample the scene between the HUD regions at native QHD resolution.
			for y in range(300,1200,24):
				for x in range(360,2050,24):
					var pixel := frame.get_pixel(x,y)
					luminance += pixel.r*.2126+pixel.g*.7152+pixel.b*.0722
					samples += 1
			averages.append(luminance/samples)
			frame.save_png("/tmp/moonlight_forest_"+["dawn","day","dusk","night"][phase]+"_lighting.png")
	check(colors[0]!=colors[1] and colors[1]!=colors[2] and colors[2]!=colors[3],"Dawn, daylight, dusk and night have distinct forest palettes")
	check(colors[3].g<colors[1].g*.4,"Night painting is substantially darker than daytime")
	check(game.actor_tint.g>detail.modulate.g,"Characters remain more readable than the night ground")
	check(game.night_fireflies.amount==240,"Moonlight Forest has twice the original firefly population")
	check(game.night_fireflies.visible and game.night_fireflies.night_weight>.99,"Fireflies are fully visible at midnight")
	check(game.night_fireflies.ground_glow>0 and game.night_fireflies.glow_batch.visible,"Midnight fireflies have luminous ground pools")
	check(game.night_fireflies.batch.multimesh==game.night_fireflies.glow_batch.multimesh,"Ground light shares the existing particle instance buffer")
	check(game.night_fireflies.glow_batch.z_index+game.night_fireflies.z_index<0,"Ground light appears beneath actors and scenery")
	var previous: Color = detail.modulate
	game.clock = 3.999
	game._update_lighting()
	game.clock = 0
	var before_dawn: Color = detail.modulate
	game._update_lighting()
	check(absf(before_dawn.g-detail.modulate.g)<.01,"Night-to-dawn transition stays continuous")
	game.clock = 3
	game._update_lighting()
	check(detail.modulate==previous,"Revisiting the same time restores the same lighting")
	game.clock = 1
	game._update_lighting()
	check(not game.night_fireflies.visible and game.night_fireflies.night_weight==0,"Daylight hides both insects and their ground light")
	check(game.moonlight_area.lantern_lights.all(func(lamp): return not lamp.visible),"Daylight turns off both lantern halos and ground light")
	var legacy: Dictionary = game.make_save_document()
	legacy.state.moonlight.moonwell_claimed = true
	check(game.saves.validate(legacy),"Old saves with collected moonwell rewards still validate")
	if capture:
		check(averages[3]<averages[1]*.65,"Rendered midnight image is visibly darker than the daytime image")
		print("FOREST FRAME LUMINANCE dawn/day/dusk/night ",averages)
	game._load_zone(Moonlight.CISTERN,"start")
	game.clock = 3
	game._update_lighting()
	check(game.backgrounds[0].modulate==Color.WHITE,"Undercroft retains its existing indoor lighting")
	check(not is_instance_valid(game.night_fireflies),"Indoor rooms have no forest fireflies or light pools")
	game.queue_free()
	await process_frame
	print("MOONLIGHT LIGHTING CHECKS ",checks," FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
