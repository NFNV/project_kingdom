extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var samples: Array = []

func _initialize() -> void:
	_run.call_deferred()

func place(zone: String, at: Vector2, clock := 1.0) -> void:
	DisplayServer.window_move_to_foreground()
	if game.zone!=zone:
		game._load_zone(zone,"town")
	game.clock = clock
	game.player.stop_motion()
	game.player.position = at
	game.player.reset_physics_interpolation()
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.dialogue_left = 0
	for i in 35:
		await process_frame

func capture(id: String) -> void:
	DisplayServer.window_move_to_foreground()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/style_"+id+".png"))

func sample(id: String, center: Vector2) -> void:
	DisplayServer.window_move_to_foreground()
	await create_timer(1.0).timeout
	var intervals: Array[float] = []
	var started := Time.get_ticks_usec()
	var previous := started
	var focused := 0
	while Time.get_ticks_usec()-started<5000000:
		var t := (Time.get_ticks_usec()-started)/1000000.0
		var goal := center+Vector2(45*cos(t),25*sin(t))
		game.player.intent = game.Actor.ground_vector(goal-game.player.position).normalized()
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append((now-previous)/1000.0)
		previous = now
		focused += int(DisplayServer.window_is_focused())
	game.player.stop_motion()
	intervals.sort()
	var above_20 := 0
	for ms in intervals:
		above_20 += int(ms>20)
	var result := {"case":id,"fps":snappedf(intervals.size()/((Time.get_ticks_usec()-started)/1000000.0),.1),"p95_ms":snappedf(intervals[int(intervals.size()*.95)],.01),"worst_ms":snappedf(intervals[-1],.01),"frames_above_20_ms":above_20,"focused_fraction":snappedf(float(focused)/intervals.size(),.01),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	samples.append(result)
	print("STYLE PERFORMANCE ",JSON.stringify(result))

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game.player.automated = true
	await place("town",Vector2(840,905))
	await capture("garden_square")
	await place("bakery",Vector2(982,590))
	await capture("bakery_day")
	await place("bakery",Vector2(982,590),3.0)
	await capture("bakery_night")
	await place("district",game.Map.District.PLACES.market)
	await capture("market")
	await place("district",game.Map.District.PLACES.plaza)
	await capture("plaza")
	await place("district",game.Map.District.PLACES.park)
	await capture("park")
	await place("district",game.Map.District.PLACES.market,3.0)
	await capture("market_night")
	if "--profile" in OS.get_cmdline_user_args():
		await place("district",game.Map.District.PLACES.plaza)
		await sample("northgate_painted_plaza",game.Map.District.PLACES.plaza)
		await place("district",game.Map.District.PLACES.market,3.0)
		await sample("northgate_night_street",game.Map.District.PLACES.market)
		await place("bakery",Vector2(982,590))
		await sample("painted_bakery_and_vendor",Vector2(982,590))
		var report := {"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"canvas":str(root.get_texture().get_size()),"camera_zoom":game.camera.zoom.x,"samples":samples,"notes":"Live graphical frame intervals at the normal 1.5x follow camera, 1920x1080 internal viewport and 60 FPS cap. Five seconds per case after warmup. House and ground paint are cached once, shared material/character textures are cached, original movement/navigation/animation stay active. Movie mode must not be used for performance measurements."}
		FileAccess.open(ProjectSettings.globalize_path(ROOT+"art_style_performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Captured unified town, bakery, plaza, park and night art.")
	quit()
