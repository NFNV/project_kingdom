extends SceneTree

# Local visual QA helper. Screenshots stay outside the source tree.
func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var view := "start"
	var output := "/tmp/kingdom-start.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--view="):
			view = argument.trim_prefix("--view=")
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	for actor in get_nodes_in_group("actors"):
		var controller: Node = actor.get_node_or_null("Controller")
		if controller != null:
			controller.set_physics_process(false)
	if view != "start":
		game.hud.intro_time = 0.0
		game.player.position = Vector2(1885, 745)
		game.player.get_node("Camera2D").reset_smoothing()
	if view == "keep":
		game.player.try_attack(Vector2.UP)
	elif view == "capture" or view == "victory":
		for defender in game.world.castle.defenders:
			defender.receive_hit(999, Vector2.ZERO)
			defender.hide()
		game.player.position = game.world.castle.capture_position()
		game.player.get_node("Camera2D").reset_smoothing()
		game.world.castle.advance_capture(5.0 if view == "victory" else 2.0)
		game.hud.refresh(game.player, game.world.castle)
		if view == "victory":
			game.hud.show_result(true)
			paused = true
	elif view == "pause":
		game._toggle_pause()
	elif view == "defeat":
		game.hud.show_result(false)
		paused = true
	for frame in 18:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(output)
	print("Preview: ", output, " (", result, ")")
	quit(result)
