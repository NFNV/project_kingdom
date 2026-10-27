extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var samples: Array = []
var first_inventory_ms := 0.0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game.player.automated = true
	game.state.accept_quest()
	game.state.accept_smith_quest()
	game.coins = 100
	for id in game.state.FORGE_STOCK:
		game.state.buy_equipment(id)
	for id in ["bread","tea","honey"]:
		game.state.add_item(id,3)
	var cases := [["town",Vector2(840,905),1.0,"world"],["bakery",Vector2(982,590),1.0,"world"],["forge",Vector2(960,625),1.0,"world"],["district",Vector2(3200,1530),1.0,"world"],["wilds",Vector2(1550,1650),1.0,"world"],["wilds",Vector2(1550,1650),3.0,"world"],["town",Vector2(840,905),1.0,"inventory"]]
	for item in cases:
		if game.zone!=item[0]:
			game._load_zone(item[0],"town")
		game.clock = item[2]
		game.dialogue_left = 0
		game.player.position = item[1]
		game.player.stop_motion()
		game.player.reset_physics_interpolation()
		game.camera.force_update_scroll()
		root.title = "Project Kingdom — equipment and foreground performance check"
		DisplayServer.window_move_to_foreground()
		if item[3]=="inventory":
			var opened := Time.get_ticks_usec()
			game.toggle_backpack()
			await RenderingServer.frame_post_draw
			first_inventory_ms = (Time.get_ticks_usec()-opened)/1000.0
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
		var started := Time.get_ticks_usec()
		var previous := started
		while Time.get_ticks_usec()-started<4000000:
			var time := (Time.get_ticks_usec()-started)/1000000.0
			if item[3]=="inventory":
				if intervals.size()%30==0:
					game.ui.satchel.select(game.state.FORGE_STOCK[(intervals.size()/30)%4],"bag")
			else:
				var goal: Vector2 = item[1]+Vector2(cos(time)*65,sin(time)*35)
				game.player.health = game.player.maximum_health
				game.player.intent = game.Actor.ground_vector(goal-game.player.position).normalized()
				if game.zone=="wilds" and game.player.cooldown<=0:
					game.player.try_attack()
			await process_frame
			var now := Time.get_ticks_usec()
			intervals.append((now-previous)/1000.0)
			previous = now
			focused += int(DisplayServer.window_is_focused())
		game.player.stop_motion()
		intervals.sort()
		var above_20 := 0
		for interval in intervals:
			above_20 += int(interval>20)
		var fraction := float(focused)/intervals.size()
		var result := {"zone":item[0],"mode":item[3],"clock":item[2],"fps":snappedf(intervals.size()/((Time.get_ticks_usec()-started)/1000000.0),.1),"p95_ms":snappedf(intervals[int(intervals.size()*.95)],.01),"worst_ms":snappedf(intervals[-1],.01),"frames_above_20_ms":above_20,"focused_fraction":snappedf(fraction,.01),"valid_foreground_sample":fraction>=.95,"render_size":str(root.get_texture().get_size()),"window_size":str(root.size),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"inventory_cells":game.ui.satchel.grid.size(),"equipment_slots":game.state.equipment.size(),"active_quests":root.get_node("Questify").get_active_quests().size(),"bandits":game.dogs.size(),"memory_mb":snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,.1)}
		samples.append(result)
		print("EQUIPMENT FOREGROUND PERFORMANCE ",JSON.stringify(result))
	var report := {"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"audio_driver":AudioServer.get_driver_name(),"samples":samples,"first_inventory_open_ms":snappedf(first_inventory_ms,.01),"notes":"1080p internal canvas in a 1280x720 window, normal 1.5x camera. Real movement, full zone populations, ordinary combat, two active event-driven Questify quests, actual GLoot equipment/bag, audio and animated forge. Inventory sample pauses the world and changes the selected item every 30 frames. Every real frame interval is retained; samples require >=95% actual foreground focus. Four-second samples after warmup and a continuous focus gate. First inventory open is reported separately. No movie mode, encoding or concurrent test jobs."}
	FileAccess.open(ROOT+"equipment_performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()
