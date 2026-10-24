extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var samples: Array = []

func _initialize() -> void:
	_run.call_deferred()

func place(at: Vector2) -> void:
	game.player.position = at
	game.player.stop_motion()
	game.player.reset_physics_interpolation()
	game.camera.reset_physics_interpolation()
	game.camera.force_update_scroll()
	game.dialogue_left = 0
	await create_timer(.5).timeout

func save(name_text: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/"+name_text+".png"))

func sample(name_text: String, center: Vector2) -> void:
	DisplayServer.window_move_to_foreground()
	var intervals: Array[float] = []
	var started := Time.get_ticks_usec()
	var previous := started
	var focused := 0
	while Time.get_ticks_usec()-started<6000000:
		var seconds := (Time.get_ticks_usec()-started)/1000000.0
		var goal := center+Vector2(75*cos(seconds*1.1),35*sin(seconds*1.1))
		game.player.intent = game.Actor.ground_vector(goal-game.player.position).normalized()
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append((now-previous)/1000.0)
		previous = now
		focused += int(DisplayServer.window_is_focused())
	game.player.stop_motion()
	intervals.sort()
	var above_20 := 0
	var above_33 := 0
	for ms in intervals:
		above_20 += int(ms>20)
		above_33 += int(ms>33.33)
	var result := {"case":name_text,"fps":snappedf(intervals.size()/((Time.get_ticks_usec()-started)/1000000.0),.1),"p95_ms":snappedf(intervals[int(intervals.size()*.95)],.01),"p99_ms":snappedf(intervals[int(intervals.size()*.99)],.01),"worst_ms":snappedf(intervals[-1],.01),"frames_above_20_ms":above_20,"frames_above_33_ms":above_33,"focused_fraction":snappedf(float(focused)/intervals.size(),.01),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	samples.append(result)
	print("NORTHGATE PERFORMANCE ",JSON.stringify(result))

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game.player.automated = true
	game._load_zone("district","town")
	game.dialogue_left = 0
	await create_timer(3).timeout
	await save("district_day")
	await place(game.Map.District.PLACES.plaza)
	await save("district_plaza")
	await sample("plaza_day_fountain_and_residents",game.Map.District.PLACES.plaza)
	await place(game.Map.District.PLACES.park)
	await save("district_park")
	await sample("park_day_trees_and_neighbours",game.Map.District.PLACES.park)
	await place(game.Map.District.PLACES.market)
	await save("district_market")
	await place(game.Map.District.PLACES.civic)
	await save("district_civic")
	game.clock = 3
	await place(game.Map.District.iso(6.5,8.6))
	await save("district_night")
	await sample("night_street_lamps_and_patrols",game.Map.District.iso(6.5,8.6))
	game.clock = 1
	game.camera.zoom = Vector2(.27,.27)
	game.camera.limit_left = -600
	game.camera.limit_right = 7000
	game.camera.limit_top = -300
	game.camera.limit_bottom = 4200
	await place(Vector2(3200,1840))
	await save("district_overview")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"internal_canvas":str(root.get_texture().get_size()),"world_size":str(game.world_size),"buildings":get_nodes_in_group("district_buildings").size(),"residents":game.residents.size(),"humans":game.humans.size(),"patrolling_wardens":game.dogs.size(),"samples":samples,"notes":"Native M1 graphical samples at the normal 1.5x follow camera, 1080p internal canvas and 60 FPS cap, six seconds per case after warmup. Actual cat movement, opaque/fading building cutouts, repeated painted sidewalks, fountain, trees, idle NPCs and moving friendly patrols. Overview zoom is only for the last static capture, after performance sampling."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"district_performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()
