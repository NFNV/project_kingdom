extends Node2D

const ROOT := "res://experiments/anime_hub_assets_v08_humans/"
const Motion := preload("res://experiments/anime_hub_demo_v07/tools/motion_sprite.gd")
const IDS := ["human_wayfarer","human_warden","human_herbalist","human_smith"]
const DIRECTIONS := ["se","sw","ne","nw"]
var catalog: Dictionary
var all_views := false
var view_index := 0
var content: Node2D


func _ready() -> void:
	get_window().title = "Project Kingdom — Human Asset Preview"
	get_window().content_scale_size = Vector2i(1920,1080)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().size = Vector2i(1280,720)
	Engine.max_fps = 60
	catalog = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json"))
	all_views = "--four-views" in OS.get_cmdline_user_args()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build()
	if "--capture" in OS.get_cmdline_user_args():
		_capture()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode==KEY_TAB:
		all_views = not all_views
		_build()
	elif event.keycode>=KEY_1 and event.keycode<=KEY_4:
		view_index = event.keycode-KEY_1
		all_views = false
		_build()


func _label(caption: String, at: Vector2, font_size := 22, color := Color("e9dec4")) -> void:
	var label := Label.new()
	label.text = caption
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	content.add_child(label)


func _build() -> void:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = Node2D.new()
	add_child(content)
	var background := ColorRect.new()
	background.size = Vector2(1920,1080)
	background.color = Color("233e36")
	content.add_child(background)
	_label("PROJECT KINGDOM  /  HUMAN CITIZENS",Vector2(55,35),34,Color("f4e8c8"))
	_label("Four adult humans. Painted anime style. Shared foot baseline and taller proportions than the animal citizens.",Vector2(55,86),22)
	if all_views:
		_turnarounds()
	else:
		_lineup()
	_label("TAB  scale lineup / all views       1–4  change facing       Directional idle assets; walk/run cycles are not included yet.",Vector2(55,1030),20,Color("c5c5a9"))


func _human(id: String, direction: String, at: Vector2, zoom: float) -> void:
	var asset: Dictionary = catalog.assets[id]
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load(ROOT+asset.native_frames)
	sprite.centered = false
	sprite.offset = Vector2(-512,-984)
	sprite.position = at
	sprite.animation = "idle_"+direction
	sprite.frame = 0
	sprite.speed_scale = 0
	var natural_height: float = asset.frames[direction].height
	sprite.scale = Vector2.ONE*float(asset.recommended_height_at_1080p)/natural_height*zoom
	content.add_child(sprite)


func _animal(id: String, at: Vector2, zoom: float) -> void:
	var sprite := Motion.new()
	content.add_child(sprite)
	sprite.position = at
	sprite.configure(id,108.0*zoom)
	sprite.set_pose("idle",DIRECTIONS[view_index],0)


func _lineup() -> void:
	var zoom := 2.5
	var baseline := 800.0
	var positions := [205.0,500.0,795.0,1090.0,1385.0,1680.0]
	_label("SCALE LINEUP  /  "+DIRECTIONS[view_index].to_upper(),Vector2(55,148),22,Color("d9bb78"))
	_label("Animals: 108 world pixels tall     Humans: 168–180     Displayed at the same 2.5× preview scale",Vector2(55,188),21)
	content.draw.connect(func():
		content.draw_line(Vector2(65,baseline),Vector2(1855,baseline),Color("ad9d70"),2.0)
		for x in positions:
			content.draw_set_transform(Vector2(x,baseline),0,Vector2(1,.28))
			content.draw_circle(Vector2.ZERO,43,Color(0.04,0.08,0.07,.25))
		content.draw_set_transform(Vector2.ZERO)
	)
	_animal("cat",Vector2(positions[0],baseline),zoom)
	_animal("warden",Vector2(positions[1],baseline),zoom)
	_label("Cat adventurer",Vector2(positions[0]-95,840),23)
	_label("108 px  ·  1.00×",Vector2(positions[0]-85,881),20)
	_label("Dog warden",Vector2(positions[1]-85,840),23)
	_label("108 px  ·  1.00×",Vector2(positions[1]-85,881),20)
	for index in IDS.size():
		var id: String = IDS[index]
		var asset: Dictionary = catalog.assets[id]
		var x: float = positions[index+2]
		_human(id,DIRECTIONS[view_index],Vector2(x,baseline),zoom)
		_label(asset.name,Vector2(x-85,840),23)
		_label("%d px  ·  %.2f×" % [asset.recommended_height_at_1080p,asset.height_vs_animals],Vector2(x-85,881),20)
	_label("All figures stand on the same baseline. Humans keep adult anatomy; animals retain their existing proportions.",Vector2(180,957),22)


func _turnarounds() -> void:
	for col in 4:
		_label(["FRONT RIGHT / SE","FRONT LEFT / SW","BACK RIGHT / NE","BACK LEFT / NW"][col],Vector2(320+col*430,126),20,Color("d9bb78"))
	for row in IDS.size():
		var id: String = IDS[row]
		var asset: Dictionary = catalog.assets[id]
		var baseline := 340.0+row*220.0
		_label(asset.name,Vector2(55,baseline-135),25)
		_label("%d world px" % asset.recommended_height_at_1080p,Vector2(55,baseline-94),19)
		for col in 4:
			_human(id,DIRECTIONS[col],Vector2(420+col*430,baseline),1.05)


func _capture() -> void:
	await get_tree().create_timer(.6).timeout
	get_window().grab_focus()
	await RenderingServer.frame_post_draw
	var filename := "human_turnarounds.png" if all_views else "human_scale_lineup.png"
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(ROOT+"previews/"+filename))
	print("Human preview rendered: ",filename)
	get_tree().quit()
