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
	await create_timer(.5).timeout

func save(name_text: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/"+name_text+".png"))

func sample(name_text: String, center: Vector2) -> void:
	DisplayServer.window_move_to_foreground()
	var frames: Array[float] = []
	var started := Time.get_ticks_usec()
	var previous := started
	var focused := 0
	game.player.automated = true
	game.player.grace = 60
	while Time.get_ticks_usec()-started<6000000:
		var seconds := (Time.get_ticks_usec()-started)/1000000.0
		var goal := center+Vector2(80*cos(seconds*1.5),50*sin(seconds*1.5))
		game.player.intent = game.Actor.ground_vector(goal-game.player.position).normalized()
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append((now-previous)/1000.0)
		previous = now
		focused += int(DisplayServer.window_is_focused())
	game.player.stop_motion()
	frames.sort()
	var above_20 := 0
	var above_33 := 0
	for ms in frames:
		above_20 += int(ms>20)
		above_33 += int(ms>33.33)
	var result := {"case":name_text,"fps":snappedf(frames.size()/((Time.get_ticks_usec()-started)/1000000.0),.1),"p95_ms":snappedf(frames[int(frames.size()*.95)],.01),"p99_ms":snappedf(frames[int(frames.size()*.99)],.01),"worst_ms":snappedf(frames[-1],.01),"frames_above_20_ms":above_20,"frames_above_33_ms":above_33,"focused_fraction":snappedf(float(focused)/frames.size(),.01),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	samples.append(result)
	print("WILDS PERFORMANCE ",JSON.stringify(result))

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game._load_zone("wilds","river")
	game.dialogue_left = 0
	await create_timer(3).timeout
	await save("wilds_day")
	await sample("western_forest_walk",Vector2(850,1900))
	await place(game.Map.Wilds.CAMPS[0]+Vector2(-125,40))
	game.player.grace = 60
	await create_timer(.25).timeout
	await save("wilds_combat")
	await sample("active_three_dog_pack",game.Map.Wilds.CAMPS[0])
	game.clock = 3
	await place(game.Map.Wilds.CAMPS[2]+Vector2(-160,80))
	await create_timer(1).timeout
	await save("wilds_night")
	await sample("deep_forest_night_pack",game.Map.Wilds.CAMPS[2])
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"internal_canvas":str(root.get_texture().get_size()),"world_size":str(game.world_size),"trees":game.occluders.size(),"hostile_dogs":game.dogs.size(),"camera_zoom":game.camera.zoom.x,"samples":samples,"notes":"Native graphical renderer, six seconds per case after warmup; actual movement, active dog pursuit/attack telegraphs, shared wind shaders, layered tree occlusion, native HUD/minimap, 1080p internal canvas and 60 FPS cap. Temporary player invulnerability keeps the same encounter alive during each performance sample; normal demo health and combat remain unchanged."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"wilds_performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()
