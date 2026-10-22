extends Node2D

const ROOT := "res://experiments/anime_hub_assets_v06/"
const TIMES := ["dawn","noon","dusk","night"]
const DIRECTIONS := ["se","sw","ne","nw"]
var catalog: Dictionary
var stage: Node2D
var ui: CanvasLayer
var page := 0
var hour := 1
var elapsed := 0.0
var actors: Array[AnimatedSprite2D] = []
var tinted: Array[CanvasItem] = []
var backdrop: Sprite2D
var note: Label


func _ready() -> void:
	var window := get_window()
	window.title = "Project Kingdom — Hub asset review (no gameplay)"
	window.content_scale_size = Vector2i(1920,1080)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.size = Vector2i(1280,720)
	Engine.max_fps = 60
	catalog = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json"))["assets"]
	stage = Node2D.new()
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(stage)
	_build_ui()
	var args := OS.get_cmdline_user_args()
	for i in 4:
		if "--"+TIMES[i] in args:
			hour = i
	if "--characters" in args:
		page = 2
	elif "--buildings" in args:
		page = 1
	elif "--scenery" in args:
		page = 3
	_show(page)
	if "--capture" in args:
		_capture.call_deferred()


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var strip := ColorRect.new()
	strip.color = Color(0.045,0.08,0.07,0.94)
	strip.size = Vector2(1920,76)
	ui.add_child(strip)
	for i in 4:
		var button := Button.new()
		button.text = ["1  Hub assembly","2  Buildings","3  Characters","4  Scenery & stalls"][i]
		button.position = Vector2(24+i*235,16)
		button.size = Vector2(218,42)
		button.add_theme_font_size_override("font_size",18)
		button.pressed.connect(_show.bind(i))
		ui.add_child(button)
	for i in 4:
		var button := Button.new()
		button.text = TIMES[i].capitalize()
		button.position = Vector2(1390+i*128,16)
		button.size = Vector2(116,42)
		button.add_theme_font_size_override("font_size",18)
		button.pressed.connect(_set_hour.bind(i))
		ui.add_child(button)
	note = _label("",Vector2(28,1034),17,ui)


func _label(text: String, at: Vector2, size: int, parent: Node) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("fff2d6"))
	label.add_theme_color_override("font_shadow_color",Color("1c302c"))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(label)
	return label


func _show(index: int) -> void:
	page = index
	actors.clear()
	tinted.clear()
	backdrop = null
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()
	stage.y_sort_enabled = false
	if page==0:
		_hub()
	else:
		var paper := ColorRect.new()
		paper.color = Color("c5c9bd")
		paper.position = Vector2(0,76)
		paper.size = Vector2(1920,1004)
		stage.add_child(paper)
		if page==1:
			_gallery(["community_hall","bakery","grocer_shop","bookshop","ivy_cottage","balcony_cottage"],3,425.0)
		elif page==2:
			_gallery(["cat_adventurer","dog_warden","cat_baker","dog_grocer","cat_bookseller","cat_elder","dog_courier"],4,360.0)
		else:
			_gallery(["elm_tree","willow_tree","bakery_stall","produce_stall","fountain","bench","street_lamp","notice_board","postbox","flower_planter"],5,350.0)
		note.text = "Source asset review · Alpha preserved · Character walks are draft two-pose loops; NPCs have one standing view."


func _piece(id: String, at: Vector2, height: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ROOT+"godot/"+id+".tres")
	sprite.centered = false
	sprite.offset = Vector2(-sprite.texture.get_width()/2.0,-sprite.texture.get_height())
	sprite.scale = Vector2.ONE*height/sprite.texture.get_height()
	sprite.position = at
	if id=="elm_tree" or id=="willow_tree":
		sprite.material = load(ROOT+"godot/"+("elm_wind.tres" if id=="elm_tree" else "willow_wind.tres"))
	stage.add_child(sprite)
	return sprite


func _actor(id: String, at: Vector2, height: float) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load(ROOT+"godot/"+id+"_frames.tres")
	var frame = catalog[id]["sheet"]["frame_canvas"]
	sprite.centered = false
	sprite.offset = Vector2(-float(frame[0])/2.0,-float(frame[1])+24.0)
	sprite.scale = Vector2.ONE*height/(float(frame[1])-48.0)
	sprite.position = at
	stage.add_child(sprite)
	sprite.play("idle_se")
	actors.append(sprite)
	return sprite


func _gallery(ids: Array, columns: int, height: float) -> void:
	var cell_w := 1872.0/columns
	for i in ids.size():
		var id: String = ids[i]
		var x := 24.0+(i%columns)*cell_w+cell_w/2.0
		var y := 110.0+(i/columns)*448.0
		if id=="cat_adventurer" or id=="dog_warden":
			_actor(id,Vector2(x,y+height),height)
		else:
			var texture: Texture2D = load(ROOT+"godot/"+id+".tres")
			var fit := minf(height,(cell_w-48)*texture.get_height()/texture.get_width())
			_piece(id,Vector2(x,y+height),fit)
		_label(id.replace("_"," ").capitalize(),Vector2(x-cell_w/2.0+26,y+height+16),20,stage)


func _hub() -> void:
	stage.y_sort_enabled = true
	backdrop = Sprite2D.new()
	backdrop.centered = false
	stage.add_child(backdrop)
	# Static background architecture is already present. Separate building pieces
	# are reviewed on their own page, avoiding duplicate facades in this assembly.
	var items := [
		["notice_board",Vector2(1510,490),165.0],
		["bakery_stall",Vector2(560,625),205.0],
		["produce_stall",Vector2(1340,620),205.0],
		["cat_baker",Vector2(470,680),112.0],
		["dog_grocer",Vector2(1430,690),112.0],
		["fountain",Vector2(970,720),235.0],
		["cat_bookseller",Vector2(1640,700),112.0],
		["street_lamp",Vector2(365,715),235.0],
		["bench",Vector2(590,830),80.0],
		["cat_elder",Vector2(690,830),108.0],
		["postbox",Vector2(1490,785),110.0],
		["dog_courier",Vector2(1370,855),112.0],
		["elm_tree",Vector2(90,940),480.0],
		["willow_tree",Vector2(1930,960),500.0],
		["flower_planter",Vector2(1240,980),78.0]
	]
	# Sort the actual ground anchors, rather than each image's visual center.
	items.sort_custom(func(a,b):return a[1].y<b[1].y)
	for item in items:
		tinted.append(_piece(item[0],item[1],item[2]))
	tinted.append(_actor("cat_adventurer",Vector2(875,900),112.0))
	tinted.append(_actor("dog_warden",Vector2(1125,870),112.0))
	_set_hour(hour)
	note.text = "Asset assembly only · No gameplay/collision · Dawn / Noon / Dusk / Night select supplied backgrounds · Trees use wind materials."


func _set_hour(value: int) -> void:
	hour = value
	if backdrop==null:
		return
	backdrop.texture = load(ROOT+"backgrounds/plaza_"+TIMES[hour]+".png")
	backdrop.scale = Vector2(1920.0/backdrop.texture.get_width(),1080.0/backdrop.texture.get_height())
	var tint: Color = [Color(1.0,0.86,0.82),Color.WHITE,Color(0.86,0.69,0.65),Color(0.40,0.49,0.70)][hour]
	for item in tinted:
		item.modulate = tint


func _process(delta: float) -> void:
	elapsed += delta
	if page==2:
		var direction: String = DIRECTIONS[int(elapsed/2.0)%4]
		for actor in actors:
			if actor.animation!="walk_"+direction:
				actor.play("walk_"+direction)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_4:
			_show(event.physical_keycode-KEY_1)
		elif event.physical_keycode==KEY_ESCAPE:
			get_tree().quit()


func _capture() -> void:
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT+"previews"))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/review_%d_%s.png"%[page,TIMES[hour]]))
	print("Asset review captured: page ",page)
	if "--quit-after-capture" in OS.get_cmdline_user_args():
		get_tree().quit()
