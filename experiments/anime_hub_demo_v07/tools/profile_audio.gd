extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var samples: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game.player.automated = true
	var cases := [["town",Vector2(840,905),1.0],["bakery",Vector2(982,590),1.0],["district",Vector2(3200,1530),1.0],["wilds",Vector2(1550,1650),1.0],["wilds",Vector2(1550,1650),3.0]]
	for item in cases:
		if game.zone!=item[0]:
			game._load_zone(item[0],"town")
		game.clock = item[2]
		game.dialogue_left = 0
		game.player.position = item[1]
		game.player.stop_motion()
		game.player.reset_physics_interpolation()
		game.camera.force_update_scroll()
		root.title = "Project Kingdom — sound and foreground performance check"
		DisplayServer.window_move_to_foreground()
		await create_timer(1.2).timeout
		var focus_started := Time.get_ticks_usec()
		var consecutive := 0.0
		var previous_focus := Time.get_ticks_usec()
		while consecutive<.6 and Time.get_ticks_usec()-focus_started<45000000:
			await process_frame
			var now := Time.get_ticks_usec()
			consecutive = consecutive+(now-previous_focus)/1000000.0 if DisplayServer.window_is_focused() else 0.0
			previous_focus = now
		var intervals: Array[float] = []
		var focused := 0
		var frames_running := 0
		var started := Time.get_ticks_usec()
		var previous := started
		var music_changes: int = game.audio.music_changes
		var events_before: int = game.audio.serial
		while Time.get_ticks_usec()-started<4000000:
			var time := (Time.get_ticks_usec()-started)/1000000.0
			var goal: Vector2 = item[1]+Vector2(cos(time)*65,sin(time)*35)
			game.player.health = 5
			game.player.intent = game.Actor.ground_vector(goal-game.player.position).normalized()
			if game.zone=="wilds" and game.player.cooldown<=0:
				game.player.try_attack()
			await process_frame
			var now := Time.get_ticks_usec()
			intervals.append((now-previous)/1000.0)
			previous = now
			focused += int(DisplayServer.window_is_focused())
			frames_running += int(Input.is_action_pressed("hub_run"))
		game.player.stop_motion()
		intervals.sort()
		var above_20 := 0
		for interval in intervals:
			above_20 += int(interval>20)
		var focused_fraction := float(focused)/intervals.size()
		var result := {"zone":item[0],"clock":item[2],"fps":snappedf(intervals.size()/((Time.get_ticks_usec()-started)/1000000.0),.1),"p95_ms":snappedf(intervals[int(intervals.size()*.95)],.01),"worst_ms":snappedf(intervals[-1],.01),"frames_above_20_ms":above_20,"focused_fraction":snappedf(focused_fraction,.01),"valid_foreground_sample":focused_fraction>=.95,"running_fraction":snappedf(float(frames_running)/intervals.size(),.01),"music":game.audio.music_id,"music_changes":game.audio.music_changes-music_changes,"effects_emitted":game.audio.serial-events_before,"effects_pool_size":game.audio.voices.size(),"audio_latency_ms":snappedf(AudioServer.get_output_latency()*1000,.1),"render_size":str(root.get_texture().get_size()),"window_size":str(root.size),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		samples.append(result)
		print("AUDIO FOREGROUND PERFORMANCE ",JSON.stringify(result))
	game.set_paused(true)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/audio_settings.png"))
	var report := {"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"audio_driver":AudioServer.get_driver_name(),"vsync_mode":DisplayServer.window_get_vsync_mode(),"samples":samples,"notes":"Actual foreground focus is measured on every frame. A sample is valid only at >=95% foreground focus; unfocused frames and all long intervals remain in the results. 1080p internal canvas, normal 1.5x follow camera, real movement, full world populations, actual combat, music crossfades, ambience and positional effects. Four-second samples follow warmup and a continuous focus gate. Native audio plays through the real output driver. No movie mode or concurrent rendering/encoding jobs."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"audio_performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()
