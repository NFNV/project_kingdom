extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var raider
var mauler
var elapsed := 0.0
var recording := false
var done: Dictionary = {}
var caption: Label
var center := Vector2(1550,1650)

func _initialize() -> void:
	_start.call_deferred()

func _start() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game.player.automated = true
	game._load_zone("wilds","river")
	game.dialogue_left = 0
	game.player.position = center-Vector2(140,0)
	game.player.reset_physics_interpolation()
	game.camera.force_update_scroll()
	if "--sheet" in OS.get_cmdline_user_args():
		_sheet.call_deferred()
		return
	if "--profile" in OS.get_cmdline_user_args():
		_profile.call_deferred()
		return
	game.ui.hide()
	for dog in game.dogs:
		dog.set_physics_process(false)
		dog.hide()
	raider = game.dogs[0]
	mauler = game.dogs[2]
	raider.show()
	mauler.show()
	raider.position = center+Vector2(15,0)
	mauler.position = center+Vector2(130,-30)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	caption = Label.new()
	caption.position = Vector2(35,30)
	caption.add_theme_font_size_override("font_size",25)
	caption.add_theme_color_override("font_outline_color",Color("17382c"))
	caption.add_theme_constant_override("outline_size",8)
	overlay.add_child(caption)
	recording = true

func once(id: String) -> bool:
	if done.has(id):
		return false
	done[id] = true
	return true

func duel(dog, distance: float) -> void:
	for other in [raider,mauler]:
		other.set_physics_process(false)
		other.hide()
	game.player.position = center-Vector2(100,0)
	game.player.stop_motion()
	game.player.knockback = Vector2.ZERO
	game.player.grace = 0
	game.player.health = 5
	game.player.reset_physics_interpolation()
	dog.position = game.player.position+Vector2(distance,0)
	dog.home = dog.position
	dog.windup = 0
	dog.swing = 0
	dog.cooldown = 0
	dog.stagger = 0
	dog.grace = 0
	dog.health = 3
	dog.alerted = true
	dog.returning = false
	dog.knockback = Vector2.ZERO
	dog.show()
	dog.set_physics_process(true)
	dog.reset_physics_interpolation()

func snapshot(id: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/bandit_"+id+".png"))

func _physics_process(delta: float) -> bool:
	if not recording:
		return false
	elapsed += delta
	game.player.intent = Vector2.ZERO
	var text := "FOREST BANDITS / SWORD RAIDER + CLUB MAULER"
	if elapsed>=.75 and elapsed<2.6:
		text = "RAIDER / LOCKED LUNGE LANE / SIDESTEP TO DODGE"
		if once("lunge"):
			duel(raider,175)
		if elapsed>=1.05 and elapsed<1.8:
			game.player.intent = Vector2.DOWN
		if elapsed>=.95 and once("lunge_warning"):
			snapshot("lunge_warning")
	elif elapsed>=2.6 and elapsed<4.2:
		text = "RAIDER / QUICK SLASH / INTERRUPT + RECOIL"
		if once("slash"):
			duel(raider,65)
		if elapsed>=2.85 and once("slash_warning"):
			snapshot("slash_warning")
		if elapsed>=3.1 and once("hurt"):
			raider.receive_hit(Vector2.RIGHT)
		if elapsed>=3.15 and once("hurt_capture"):
			snapshot("hurt")
	elif elapsed>=4.2 and elapsed<6.3:
		text = "MAULER / SLOW WIDE SWEEP / LONG RECOVERY"
		if once("sweep"):
			duel(mauler,110)
		if elapsed>=4.65 and once("sweep_warning"):
			snapshot("sweep_warning")
		if elapsed>=5.4 and once("sweep_contact"):
			snapshot("sweep_contact")
	elif elapsed>=6.3 and elapsed<7.3:
		text = "SWORD HIT / CANCELLED ENEMY WIND-UP"
		if once("player_attack"):
			duel(mauler,65)
			game.player.facing = Vector2.RIGHT
			game.player.cooldown = 0
			game.player.swing = 0
			game.player.try_attack()
		if elapsed>=6.55 and once("sword_hit"):
			snapshot("sword_hit")
	elif elapsed>=7.3:
		text = "WIND SLASH / DEFEAT + UNIQUE COIN REWARD"
		if once("skill"):
			duel(mauler,190)
			mauler.set_physics_process(false)
			game.player.facing = Vector2.RIGHT
			game.player.swing = 0
			game.player.cooldown = 0
			game.player.skill_cooldown = 0
			game.player.try_skill()
		if elapsed>=7.82 and once("skill_hit"):
			snapshot("skill_hit")
	caption.text = text
	if elapsed>=8.6:
		quit()
	return false

func _sheet() -> void:
	game.queue_free()
	await process_frame
	await process_frame
	root.canvas_transform = Transform2D.IDENTITY
	var stage := Node2D.new()
	root.add_child(stage)
	var backdrop := ColorRect.new()
	backdrop.size = Vector2(1920,1080)
	backdrop.color = Color("dee5d7")
	stage.add_child(backdrop)
	var title := Label.new()
	title.text = "RAIDER + MAULER / IDLE · LEFT STEP · PASS · RIGHT STEP · WIND-UP · STRIKE · RECOVER · HURT"
	title.position = Vector2(50,25)
	title.add_theme_font_size_override("font_size",25)
	title.modulate = Color("294d3e")
	stage.add_child(title)
	for row in 8:
		for column in 8:
			var art := preload("res://experiments/anime_hub_demo_v07/tools/bandit_sprite.gd").new()
			stage.add_child(art)
			art.configure("raider" if row<4 else "mauler",88)
			art.set_pose("review",["se","sw","ne","nw"][row%4],column)
			art.position = Vector2(130+column*234,190+row*123)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/bandit_pose_review.png"))
	print("Captured all 64 native enemy poses.")
	quit()

func _profile() -> void:
	var samples: Array = []
	for phase in [1.0,3.0]:
		game.clock = phase
		DisplayServer.window_move_to_foreground()
		await create_timer(2.0).timeout
		var started := Time.get_ticks_usec()
		var previous := started
		var intervals: Array[float] = []
		var spikes: Array = []
		var focused := 0
		while Time.get_ticks_usec()-started<6000000:
			var time := (Time.get_ticks_usec()-started)/1000000.0
			var goal := center+Vector2(cos(time)*170,sin(time)*90)
			game.player.health = 5
			game.player.intent = game.Actor.ground_vector(goal-game.player.position).normalized()
			await process_frame
			var now := Time.get_ticks_usec()
			var ms := (now-previous)/1000.0
			intervals.append(ms)
			if ms>33.33:
				spikes.append({"at_seconds":snappedf((now-started)/1000000.0,.01),"interval_ms":snappedf(ms,.01),"cpu_process_ms":snappedf(Performance.get_monitor(Performance.TIME_PROCESS)*1000,.01),"cpu_physics_ms":snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,.01),"focused":DisplayServer.window_is_focused()})
			previous = now
			focused += int(DisplayServer.window_is_focused())
		intervals.sort()
		var above_20 := 0
		for ms in intervals:
			above_20 += int(ms>20)
		var peak_path := 0.0
		for dog in game.dogs:
			peak_path = maxf(peak_path,dog.peak_navigation_ms)
		var result := {"phase":phase,"fps":snappedf(intervals.size()/((Time.get_ticks_usec()-started)/1000000.0),.1),"p95_ms":snappedf(intervals[int(intervals.size()*.95)],.01),"worst_ms":snappedf(intervals[-1],.01),"frames_above_20_ms":above_20,"focused_fraction":snappedf(float(focused)/intervals.size(),.01),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"peak_navigation_ms":peak_path,"spikes":spikes}
		samples.append(result)
		print("BANDIT PERFORMANCE ",JSON.stringify(result))
	var report := {"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"canvas":str(root.get_texture().get_size()),"camera_zoom":game.camera.zoom.x,"population":game.dogs.size(),"vsync_mode":DisplayServer.window_get_vsync_mode(),"samples":samples,"notes":"Live graphical measurements, 1080p internal canvas, normal 1.5x camera, actual player movement and combat AI for twelve mixed bandits in the full layered forest. Six seconds per phase after warmup; no movie mode. Normal macOS launch uses the 60 FPS engine cap with Metal VSync disabled after observed focus-change waits. Long intervals, CPU timing, focus state and navigation costs are retained rather than discarded."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"bandit_performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	quit()
