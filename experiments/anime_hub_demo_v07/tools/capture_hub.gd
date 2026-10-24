extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _save(name_text: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(ROOT+"previews/"+name_text+".png"))
	return image


func _place(at: Vector2) -> void:
	game.player.position = at
	game.player.intent = Vector2.ZERO
	game.player.velocity = Vector2.ZERO
	game.player.reset_physics_interpolation()
	game.camera.reset_physics_interpolation()
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.dialogue_left = 0
	await create_timer(.4).timeout


func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	await create_timer(2).timeout
	if "--humans" in OS.get_cmdline_user_args():
		await _capture_humans()
		quit()
		return
	await _place(Vector2(840,905))
	await _save("town_day")
	await _place(Vector2(970,810))
	await _save("fountain_close")
	await create_timer(.4).timeout
	await _save("fountain_close_motion")
	await _place(Vector2(344,637))
	await _save("bakery_entrance")
	game._load_zone("trail","town")
	await _place(game.Map.point(850,515))
	await _save("trail_day")
	game._load_zone("river","trail")
	game.clock = 3
	await _place(game.Map.point(750,590))
	await _save("river_night")
	game.clock = 1
	game._load_zone("bakery","town")
	await _place(Vector2(982,590))
	await _save("bakery_counter")
	game.interact("shop_vendor")
	await create_timer(.2).timeout
	await _save("bakery_shop")
	game.close_shop()
	game.clock = 3
	await create_timer(.3).timeout
	await _save("bakery_night")
	print("Captured close fountain, doorway, furnished bakery, shop and night interior.")
	quit()


func _capture_humans() -> void:
	# A wider overview shows all four placements; individual conversations use
	# the playable 1.5x follow camera, unchanged from normal play.
	game.camera.zoom = Vector2(1.25,1.25)
	await _place(Vector2(1000,810))
	await _save("human_npcs_day")
	game.clock = 3
	await create_timer(.3).timeout
	await _save("human_npcs_night")
	game.clock = 1
	game.camera.zoom = Vector2(1.5,1.5)
	for example in [["tomas",Vector2(800,820)],["alden",Vector2(1125,650)],["iris",Vector2(790,990)],["rhea",Vector2(1130,1010)]]:
		await _place(example[1])
		game.interact(example[0])
		await create_timer(.25).timeout
		await _save("human_"+example[0]+"_conversation")
	print("Captured four human NPC conversations and shared day/night lighting.")
