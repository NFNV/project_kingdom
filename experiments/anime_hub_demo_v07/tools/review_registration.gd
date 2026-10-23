extends SceneTree

# Native Godot rendering only: the same unmodified PNGs, old and new registration.
const ROOT := "res://experiments/anime_hub_demo_v07/"
const Motion := preload("res://experiments/anime_hub_demo_v07/tools/motion_sprite.gd")
var stage: Node2D


func _initialize() -> void:
	root.content_scale_size = Vector2i(1920,1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.size = Vector2i(1280,720)
	_build.call_deferred()


func _label(caption: String, at: Vector2, size_px := 18) -> void:
	var label := Label.new()
	label.text = caption
	label.position = at
	label.add_theme_font_size_override("font_size",size_px)
	label.add_theme_color_override("font_color",Color("f3e5c4"))
	stage.add_child(label)


func _build() -> void:
	var front_review := "--front-cycle" in OS.get_cmdline_user_args()
	stage = Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.size = Vector2(1920,1080)
	background.color = Color("294036")
	stage.add_child(background)
	_label("DOWNWARD CYCLE / BEFORE AND AFTER" if front_review else "BODY ALIGNMENT / BEFORE AND AFTER",Vector2(35,18),27)
	_label("South-facing walk and run. New drawings keep the head/chest forward and the tail on the right." if front_review else "Each column is the next drawn pose. Same original artwork; only native registration and scale differ.",Vector2(35,58))
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"assets/motion/registration.json"))
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"assets/motion/cat_s_v1_reference.json")) if front_review else {}
	var old_frames := _old_south_frames(previous) if front_review else null
	var examples := [["s","walk"],["s","run"]] if front_review else [["e","walk"],["se","run"],["s","run"]]
	for group in examples.size():
		var direction: String = examples[group][0]
		var gait: String = examples[group][1]
		for comparison in 2:
			var baseline := 260.0+group*440+comparison*195 if front_review else 230.0+group*322+comparison*143
			_label(direction.to_upper()+" "+gait.to_upper()+"\n"+("BEFORE" if comparison==0 else "AFTER"),Vector2(28,baseline-90),17)
			for pose in 8:
				var at := Vector2(260+pose*215,baseline)
				_label(str(pose+1),at+Vector2(-5,6),15)
				var sprite := Motion.new()
				stage.add_child(sprite)
				sprite.position = at
				sprite.configure("cat",108)
				if front_review and comparison==0:
					sprite.sprite_frames = old_frames
					sprite.metadata["s"] = previous.calibration
				sprite.set_pose(gait,direction,pose)
				if comparison==0 and not front_review:
					var index := pose+(8 if gait=="run" else 0)
					var source: Dictionary = report["cat_"+direction].frames[index]
					var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(gait+"_"+direction,pose).duplicate()
					var margin: Array = source.foot_margin
					atlas.margin = Rect2(margin[0],margin[1],margin[2],margin[3])
					var original := Sprite2D.new()
					original.texture = atlas
					original.centered = false
					original.offset = Vector2(-256,-488)
					original.position = at
					original.scale = Vector2.ONE*sprite.base_scale
					stage.add_child(original)
					sprite.hide()
	await create_timer(.6).timeout
	root.grab_focus()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/"+("downward_cycle.png" if front_review else "body_registration.png")))
	print("Rendered complete before/after body-alignment cycles.")
	quit()


func _old_south_frames(previous: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var atlas: Texture2D = load(ROOT+"assets/motion/cat_s.png")
	for gait in ["walk","run","idle"]:
		var key: String = gait+"_s"
		frames.add_animation(key)
		var start: int = {"walk":0,"run":8,"idle":16}[gait]
		for index in (4 if gait=="idle" else 8):
			var source: Dictionary = previous.registration.frames[start+index]
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = Rect2(source.region[0],source.region[1],source.region[2],source.region[3])
			texture.margin = Rect2(source.margin[0],source.margin[1],source.margin[2],source.margin[3])
			texture.filter_clip = true
			frames.add_frame(key,texture)
	return frames
