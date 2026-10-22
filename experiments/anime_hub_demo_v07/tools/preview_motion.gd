extends SceneTree

const Motion := preload("res://experiments/anime_hub_demo_v07/tools/motion_sprite.gd")
const ROOT := "res://experiments/anime_hub_demo_v07/"
var stage: Node2D
var samples: Array = []
var time := 0.0
var written := false


func _initialize() -> void:
	root.content_scale_size = Vector2i(1920,1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.size = Vector2i(1280,720)
	stage = Node2D.new()
	root.add_child.call_deferred(stage)
	_build.call_deferred()


func _label(text: String, at: Vector2, size_px: int) -> void:
	var item := Label.new()
	item.text = text
	item.position = at
	item.add_theme_font_size_override("font_size",size_px)
	item.add_theme_color_override("font_color",Color("f3e5c4"))
	stage.add_child(item)


func _build() -> void:
	var background := ColorRect.new()
	background.size = Vector2(1920,1080)
	background.color = Color("294036")
	stage.add_child(background)
	_label("PROJECT KINGDOM  /  CHARACTER MOTION",Vector2(50,25),26)
	_label("Eight directions. Separate walking, running, and blinking idle poses. Registered feet and shared scale.",Vector2(50,67),19)
	for row in 3:
		var state: String = ["walk","run","idle"][row]
		_label(state.to_upper(),Vector2(35,170+row*210),18)
		for col in 8:
			var direction: String = Motion.DIRECTIONS[col]
			var sprite := Motion.new()
			sprite.position = Vector2(220+col*222,310+row*210)
			stage.add_child(sprite)
			sprite.configure("cat",125)
			sprite.facing_direction = direction
			samples.append({"sprite":sprite,"state":state,"direction":direction})
			if row==0:
				_label(direction.to_upper(),Vector2(205+col*222,125),18)
	_label("LIFE IN THE SQUARE  /  Blinks, tail movement, greetings, and occupational gestures",Vector2(50,810),20)
	for index in 6:
		var id: String = ["warden","cat_baker","cat_elder","cat_bookseller","dog_grocer","dog_courier"][index]
		var sprite := Motion.new()
		sprite.position = Vector2(215+index*300,1030)
		stage.add_child(sprite)
		sprite.configure(id,136,index*.7)
		samples.append({"sprite":sprite,"state":"walk" if id=="warden" else "gesture","direction":"se"})
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()


func _process(delta: float) -> bool:
	time += delta
	for sample in samples:
		if sample["state"]=="idle":
			sample["sprite"].facing_direction = sample["direction"]
			sample["sprite"].tick(delta,0.0,Vector2.ZERO)
		elif sample["state"]=="gesture":
			if sample["sprite"].gesture_clock<0:
				sample["sprite"].greet()
			sample["sprite"].tick(delta,0.0,Vector2.ZERO)
		else:
			sample["sprite"].set_pose(sample["state"],sample["direction"],int(time*12)%8)
	return false


func _capture() -> void:
	await create_timer(1.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/character_motion.png"))
	quit()
