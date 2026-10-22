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
	await create_timer(3.0).timeout
	await _sample("town_walk_run_patrols_and_fountain",6.0)
	game._load_zone("bakery","town")
	game.player.position = Vector2(982,590)
	game.player.reset_physics_interpolation()
	await create_timer(1.0).timeout
	await _sample("furnished_bakery_follow_camera_and_fire",6.0)
	game.interact("shop_vendor")
	await _sample("bakery_vendor_interface_and_animation",6.0)
	game.close_shop()
	game._load_zone("trail","town")
	game.player.position = game.Map.point(850,515)
	game.player.reset_physics_interpolation()
	await create_timer(2.0).timeout
	await _sample("forest_trail_day_wind_and_clock",6.0)
	game.clock = 2.7
	await create_timer(1.0).timeout
	await _sample("forest_trail_day_night_crossfade",6.0)
	game._load_zone("river","trail")
	game.player.position = game.Map.point(750,590)
	game.player.reset_physics_interpolation()
	await create_timer(2.0).timeout
	await _sample("river_glade_twilight",6.0)
	root.mode = Window.MODE_MAXIMIZED
	DisplayServer.window_move_to_foreground()
	game.clock = 3.0
	await create_timer(2.0).timeout
	await _sample("maximized_river_at_night",6.0)
	game.player.intent = Vector2.ZERO
	var report := {"engine":Engine.get_version_info()["string"],"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"canvas":"1920x1080 fixed viewport; close actor-follow camera, animated fountain, authored bakery and forest plates", "max_fps":Engine.max_fps,"samples":results,"notes":"Graphical measurements after warmup; foreground focus is requested before each sample and actual focused fractions are recorded. Actual cat movement with a 1.7x following camera, animated civilians and friendly patrolling wardens, eight-direction drawn walk/run cycles, flowing water and splashes, bakery steam/fire, vendor interface, animated wind/leaves/fireflies, clock and background crossfades. All long frames retained. Maximize still renders the same 1080p canvas. Scene loads occur during short travel fades and outside steady-state samples."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()


func _sample(label: String, duration: float) -> void:
	DisplayServer.window_move_to_foreground()
	await create_timer(0.6).timeout
	var intervals: Array[float] = []
	var start := Time.get_ticks_usec()
	var previous := start
	var focused := 0
	while Time.get_ticks_usec()-start<duration*1000000:
		var seconds := (Time.get_ticks_usec()-start)/1000000.0
		if game.zone=="town":
			if seconds>duration*.5:
				Input.action_press("hub_run")
			else:
				Input.action_release("hub_run")
		var center := Vector2(970,810)
		if game.zone=="bakery":
			center = Vector2(982,650)
		if game.zone=="trail":
			center = game.Map.point(850,515)
		elif game.zone=="river":
			center = game.Map.point(750,590)
		var goal := center+Vector2(95*cos(seconds*.9),50*sin(seconds*.9))
		game.player.intent = game.Actor.ground_vector(goal-game.player.position).normalized()
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append((now-previous)/1000.0)
		previous = now
		focused += int(DisplayServer.window_is_focused())
	Input.action_release("hub_run")
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
