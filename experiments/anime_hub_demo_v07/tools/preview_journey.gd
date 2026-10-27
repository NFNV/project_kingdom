extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D

func _initialize() -> void:
	run.call_deferred()

func capture(name: String) -> void:
	game.ui.notice_left = 0
	game.ui.notice.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ROOT+"previews/"+name+".png")
	print("Journey preview: ",name)

func run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.save_path = "/tmp/kingdom-journey-preview.json"
	game.auto_clock = false
	game.clock = 1
	game.dialogue_left = 0
	game.talk_panel.hide()
	game.prompt.hide()
	game.quest_marker.hide()
	game.state.accept_quest()
	for i in 3:
		var id := "wild_dog_0_%d" % i
		game.state.record_defeat(id,Vector2(1550+i*30,1650))
		game.state.collect_loot(id)
	game.state.claim_reward()
	game.state.add_item("bread",3)
	game.state.add_item("tea",2)
	game.state.add_item("honey")
	game.player.health = 4
	game.toggle_backpack()
	game.ui.satchel.primary_button.pressed.emit()
	await create_timer(.4).timeout
	await capture("journey_satchel")
	game.toggle_backpack()
	game.save_game()
	game.set_paused(true)
	await capture("journey_save_menu")
	game.free()
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game.state.accept_quest()
	game._load_zone("wilds","river")
	game.player.position = Vector2(1420,1690)
	game.player.automated = true
	game.player.stop_motion()
	game.player.reset_physics_interpolation()
	game.camera.force_update_scroll()
	for dog in game.dogs:
		dog.set_physics_process(false)
	game.dogs[0].receive_hit(Vector2.RIGHT,3)
	game.dialogue_left = 0
	game.talk_panel.hide()
	await create_timer(.6).timeout
	await capture("journey_badge_pickup")
	quit()
