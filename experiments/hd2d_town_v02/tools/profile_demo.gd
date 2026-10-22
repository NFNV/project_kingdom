extends SceneTree

const ROOT := "res://experiments/hd2d_town_v02/"
var demo: Node3D
var results: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Frame-rate profiling requires a graphical renderer.")
		quit(1)
		return
	demo = load(ROOT + "demo.tscn").instantiate()
	root.add_child(demo)
	# Preserve the normal launch's VSync and frame cap for an honest comparison.
	await create_timer(2.0).timeout
	await _sample("normal_window", 4.0)
	root.mode = Window.MODE_MAXIMIZED
	await create_timer(1.0).timeout
	await _sample("maximized_window", 4.0)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	await create_timer(1.0).timeout
	demo.resident.position = demo.SPAWN
	demo.resident.velocity = Vector3.ZERO
	Input.action_press("hd_right")
	await _sample("walking", 4.0)
	Input.action_release("hd_right")
	var report := {"engine":Engine.get_version_info()["string"],"renderer":RenderingServer.get_current_rendering_method(),"vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,"screen_size":str(DisplayServer.screen_get_size()),"samples":results}
	FileAccess.open(ProjectSettings.globalize_path(ROOT + "previews/performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()


func _sample(label: String, duration: float) -> void:
	var intervals: Array[float] = []
	var focused := 0
	var start := Time.get_ticks_usec()
	var previous := start
	while Time.get_ticks_usec()-start < duration * 1000000.0:
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append((now-previous)/1000.0)
		previous = now
		if DisplayServer.window_is_focused():
			focused += 1
	intervals.sort()
	var count := intervals.size()
	var result := {"case":label,"fps":snappedf(count/((Time.get_ticks_usec()-start)/1000000.0),0.1),"p95_ms":snappedf(intervals[int(count*0.95)],0.01),"worst_ms":snappedf(intervals[-1],0.01),"focused_fraction":snappedf(float(focused)/count,0.01),"window_size":str(root.size),"render_size":str(root.get_texture().get_size()),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	results.append(result)
	print("PERFORMANCE ",JSON.stringify(result))
