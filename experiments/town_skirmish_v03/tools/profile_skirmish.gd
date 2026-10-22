extends SceneTree

const ROOT := "res://experiments/town_skirmish_v03/"
var demo: Node3D
var results: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Combat profiling requires a graphical renderer.")
		quit(1)
		return
	demo = load(ROOT+"demo.tscn").instantiate()
	root.add_child(demo)
	root.grab_focus()
	var uncapped := "--uncapped" in OS.get_cmdline_user_args()
	if uncapped:
		# Headroom pass only. The separate capped pass uses normal launch settings.
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	# Benchmark health keeps all six dog AIs and melee active; balance is unchanged.
	demo.resident.position = Vector3(0,0.08,0)
	demo.resident.reset_physics_interpolation()
	var index := 0
	for fighter in demo.fighters:
		fighter.health.maximum = 9999
		fighter.health.current = 9999
		if not fighter.cat:
			var angle := index*TAU/6.0
			fighter.position = Vector3(cos(angle)*2.5,0.08,sin(angle)*1.5)
			fighter.home = fighter.position
			fighter.reset_physics_interpolation()
			index += 1
	Input.action_press("sk_attack")
	await create_timer(4.0).timeout
	await _sample("six_dogs_active_combat",8.0)
	root.mode = Window.MODE_MAXIMIZED
	await create_timer(2.0).timeout
	await _sample("maximized_active_combat",8.0)
	root.mode = Window.MODE_WINDOWED
	root.size = demo.RENDER_SIZE
	await create_timer(2.0).timeout
	Input.action_press("hd_run")
	await _sample("running_camera_and_combat",8.0,true)
	for action in ["sk_attack","hd_left","hd_right","hd_up","hd_down","hd_run"]:
		Input.action_release(action)
	var report := {
		"captured_at_utc":Time.get_datetime_string_from_system(true,true),
		"engine":Engine.get_version_info()["string"],
		"renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(),
		"vsync":DisplayServer.window_get_vsync_mode(),
		"max_fps":Engine.max_fps,
		"screen_size":str(DisplayServer.screen_get_size()),
		"target":"Native 1920x1080, 60 FPS; no dynamic resolution or 3D upscaling.",
		"shading":"Material-local cavity shading and contact shadows; full-resolution scene, FXAA, subtle DOF. Full-screen SSAO and bloom disabled.",
		"notes":"Benchmark-only high health preserves every combatant. Samples follow warmup and resize settling. Focus and long-frame counts are reported, not filtered out.",
		"samples":results
	}
	var filename := "headroom_1080p.json" if uncapped else "performance.json"
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"previews/"+filename),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()


func _sample(label: String, duration: float, moving := false) -> void:
	var intervals: Array[float] = []
	var focused := 0
	var above_20 := 0
	var above_33 := 0
	var start := Time.get_ticks_usec()
	var previous := start
	var actions := ["hd_right","hd_up","hd_left","hd_down"]
	while Time.get_ticks_usec()-start < duration*1000000.0:
		if moving:
			# A square route exercises movement/camera turns without running off-map.
			var direction := int((Time.get_ticks_usec()-start)/1000000.0)%4
			for index in 4:
				if index==direction:
					Input.action_press(actions[index])
				else:
					Input.action_release(actions[index])
		await process_frame
		var now := Time.get_ticks_usec()
		var interval := (now-previous)/1000.0
		intervals.append(interval)
		above_20 += int(interval>20.0)
		above_33 += int(interval>33.33)
		previous = now
		focused += int(DisplayServer.window_is_focused())
	intervals.sort()
	var count := intervals.size()
	var result := {
		"case":label,"frames":count,
		"fps":snappedf(count/((Time.get_ticks_usec()-start)/1000000.0),0.1),
		"p95_ms":snappedf(intervals[int(count*0.95)],0.01),
		"p99_ms":snappedf(intervals[int(count*0.99)],0.01),
		"worst_ms":snappedf(intervals[-1],0.01),
		"frames_above_20_ms":above_20,"frames_above_33_ms":above_33,
		"focused_fraction":snappedf(float(focused)/count,0.01),
		"window_size":str(root.size),"render_size":str(root.get_texture().get_size()),
		"render_scale":root.scaling_3d_scale,
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	}
	results.append(result)
	print("PERFORMANCE ",JSON.stringify(result))
