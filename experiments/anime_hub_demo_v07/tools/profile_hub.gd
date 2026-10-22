extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var results: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Use a graphical renderer to measure actual FPS.")
		quit(1)
		return
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	root.grab_focus()
	DisplayServer.window_move_to_foreground()
	game.auto_clock = false
	game.player.automated = true
	game.dialogue_left = 0
	await create_timer(4.0).timeout
	await _sample("walking_noon",6.0)
	game.start_challenge()
	game.player.health = 9999
	for dog in game.dogs:
		dog.health = 9999
	Input.action_press("hub_attack")
	game.clock = 2.65
	await create_timer(2.0).timeout
	await _sample("three_dogs_and_background_crossfade",6.0)
	root.mode = Window.MODE_MAXIMIZED
	DisplayServer.window_move_to_foreground()
	await create_timer(2.0).timeout
	await _sample("maximized_three_dogs_and_crossfade",6.0)
	Input.action_release("hub_attack")
	game.player.intent = Vector2.ZERO
	var report := {"engine":Engine.get_version_info()["string"],"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"canvas":"1920x1080 fixed viewport; two full-size plates during transitions", "max_fps":Engine.max_fps,"samples":results,"notes":"Native graphical measurements after warmup. Benchmark health keeps three dog AIs and attacks active. All long frames retained. Maximize still renders the same fixed 1080p canvas."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()


func _sample(label: String, duration: float) -> void:
	var intervals: Array[float] = []
	var start := Time.get_ticks_usec()
	var previous := start
	var focused := 0
	while Time.get_ticks_usec()-start<duration*1000000:
		var seconds := (Time.get_ticks_usec()-start)/1000000.0
		var goal := Vector2(970+180*cos(seconds*0.9),900+65*sin(seconds*0.9))
		game.player.intent = game.Actor.ground_vector(goal-game.player.position).normalized()
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append((now-previous)/1000.0)
		previous = now
		focused += int(DisplayServer.window_is_focused())
	intervals.sort()
	var count := intervals.size()
	var above_20 := 0
	var above_33 := 0
	for ms in intervals:
		above_20 += int(ms>20)
		above_33 += int(ms>33.33)
	var result := {"case":label,"fps":snappedf(count/((Time.get_ticks_usec()-start)/1000000.0),0.1),"p95_ms":snappedf(intervals[int(count*0.95)],0.01),"p99_ms":snappedf(intervals[int(count*0.99)],0.01),"worst_ms":snappedf(intervals[-1],0.01),"frames_above_20_ms":above_20,"frames_above_33_ms":above_33,"focused_fraction":snappedf(float(focused)/count,0.01),"render_size":str(root.get_texture().get_size()),"window_size":str(root.size),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	results.append(result)
	print("PERFORMANCE ",JSON.stringify(result))
