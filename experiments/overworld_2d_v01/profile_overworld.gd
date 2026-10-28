extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
var samples: Array = []
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	root.size = Vector2i(1920,1080)
	world = load(ROOT+"world.tscn").instantiate()
	root.add_child(world)
	world.automated = true
	var stages := ["meadow_curved","meadow_flat","crossing","forest","hop_study","turning","mosswood","camera_orbit","windsong_ridge","willowmere_lake","ivykeep_ruins","palestone_coast","regional_map"]
	if "--meadow-only" in OS.get_cmdline_user_args(): stages = ["meadow_curved"]
	if "--final-smoke" in OS.get_cmdline_user_args(): stages = ["mosswood","meadow_flat","regional_map"]
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="): stages = [argument.trim_prefix("--stage=")]
	for stage in stages:
		world.curved = stage!="meadow_flat"
		world.hop_study = stage=="hop_study"
		world.region_map = stage=="regional_map"
		world.camera_yaw = 1.0 if stage=="palestone_coast" else 0.0
		world.camera_spin = 1.0 if stage=="camera_orbit" else 0.0
		world.visit({"crossing":1,"forest":2,"mosswood":3,"camera_orbit":3,"windsong_ridge":4,"willowmere_lake":5,"ivykeep_ruins":6,"palestone_coast":7,"regional_map":3}.get(stage,0))
		world.region_map = stage=="regional_map"
		world.notice_left = 0
		DisplayServer.window_move_to_foreground()
		root.grab_focus()

		await create_timer(1.0).timeout
		var gate_start := Time.get_ticks_usec()
		var consecutive := 0.0
		var last := gate_start
		while consecutive<.5 and Time.get_ticks_usec()-gate_start<8000000:
			await process_frame
			var now := Time.get_ticks_usec()
			consecutive = consecutive+(now-last)/1000000.0 if DisplayServer.window_is_focused() else 0.0
			last = now
		var intervals: Array[float] = []
		var focus := 0
		var directions_seen: Dictionary = {}
		var began := Time.get_ticks_usec()
		last = began
		var start: Vector2 = world.player
		var duration := 5200000 if stage=="camera_orbit" else 4000000
		while Time.get_ticks_usec()-began<duration:
			world.intent = Vector2.ZERO if stage in ["mosswood","camera_orbit","windsong_ridge","willowmere_lake","ivykeep_ruins","palestone_coast","regional_map"] else Vector2(0,1)
			if stage=="turning":
				var sector := mini(7,int((Time.get_ticks_usec()-began)/500000))
				world.intent = Vector2(sin(sector*PI/4),cos(sector*PI/4))
			if stage=="meadow_flat": world.intent = Vector2(.3,1).normalized()
			await process_frame
			var now := Time.get_ticks_usec()
			intervals.append((now-last)/1000.0)
			last = now
			focus += int(DisplayServer.window_is_focused())
			directions_seen[world.mounted_rider.direction_name()] = true
		world.intent = Vector2.ZERO
		world.camera_spin = 0
		var elapsed := (Time.get_ticks_usec()-began)/1000000.0
		intervals.sort()
		var over := 0
		for interval in intervals: over += int(interval>20)
		var fraction := float(focus)/intervals.size()
		var sample := {"stage":stage,"camera_yaw":world.camera_yaw,"directions_seen":directions_seen.keys(),"fps":snappedf(intervals.size()/elapsed,.1),"p95_ms":snappedf(intervals[int(intervals.size()*.95)],.01),"worst_ms":snappedf(intervals[-1],.01),"frames_above_20_ms":over,"focused_fraction":fraction,"valid_foreground_sample":fraction>=.95,"render_size":str(root.get_texture().get_size()),"visible_props":world.visible_props.size(),"travel_distance":snappedf(world.player.distance_to(start),.01),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		samples.append(sample)
		print("OVERWORLD PERFORMANCE ",JSON.stringify(sample))
		world.visit({"crossing":1,"forest":2,"mosswood":3,"camera_orbit":3,"windsong_ridge":4,"willowmere_lake":5,"ivykeep_ruins":6,"palestone_coast":7,"regional_map":3}.get(stage,0))
		await create_timer(.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ROOT+"previews/"+stage+".png")
	var report := {"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"samples":samples,"notes":"Native 1920x1080 render, 60 FPS cap, four-second foreground samples after warmup and continuous focus gate. Real movement, eight-direction protagonist mount, compact walled city, six painted scenery textures, branch roads, lake, sea and regional map; camera_orbit adds a full 5.2-second 2D orbit; hop_study also draws the live enlarged rider. Captures occur after measurement, no concurrent test or game processes. No 3D nodes, saved-game I/O or existing gameplay changes. Short steady-state test excludes loading."}
	FileAccess.open(ROOT+("performance_final_smoke.json" if "--final-smoke" in OS.get_cmdline_user_args() else ("performance_"+stages[0]+".json" if stages.size()==1 else "performance.json")),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()
