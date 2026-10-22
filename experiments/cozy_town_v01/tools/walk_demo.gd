extends Node2D

const ROOT := "res://experiments/cozy_town_v01/"
const TOWN := preload(ROOT + "town_corner.tscn")
const RESIDENT := preload(ROOT + "tools/town_resident.gd")
const START := Vector2(345, 240)
var player: CharacterBody2D
var camera: Camera2D
var camera_caption: Label
var overview := true


func _ready() -> void:
	# Configure this window only; the project's main game and settings stay intact.
	var window := get_window()
	window.title = "Project Kingdom — Cozy Town Walk"
	window.content_scale_size = Vector2i(640, 384)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.size = Vector2i(1280, 768)
	_register_inputs()
	var town := TOWN.instantiate()
	add_child(town)
	var objects := town.get_node("TownObjects")
	var resident := objects.get_node("resident") as Node2D
	player = CharacterBody2D.new()
	player.name = "PlayableResident"
	player.set_script(RESIDENT)
	player.position = START
	player.collision_layer = 0
	player.collision_mask = 1
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	objects.add_child(player)
	resident.reparent(player, false)
	resident.position = Vector2.ZERO
	player.visual = resident
	var feet := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	feet.shape = circle
	feet.position.y = -4.0
	player.add_child(feet)
	_add_obstacles(objects)
	camera = Camera2D.new()
	camera.name = "TownCamera"
	camera.position = Vector2(320, 192)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 640
	camera.limit_bottom = 384
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()
	_add_hud()
	_update_camera_mode()


func _process(_delta: float) -> void:
	if not overview:
		camera.position = player.position + Vector2(0, -24)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("town_camera"):
		overview = not overview
		_update_camera_mode()
	elif event.is_action("town_reset"):
		reset_resident()
	elif event.is_action("town_quit"):
		get_tree().quit()


func reset_resident() -> void:
	player.position = START
	player.velocity = Vector2.ZERO
	player.visual.scale.x = 1.0
	if not overview:
		camera.position = player.position + Vector2(0, -24)
		camera.reset_smoothing()


func _update_camera_mode() -> void:
	camera.zoom = Vector2.ONE if overview else Vector2(2, 2)
	camera.position_smoothing_enabled = not overview
	camera.position = Vector2(320, 192) if overview else player.position + Vector2(0, -24)
	camera.reset_smoothing()
	camera_caption.text = "TOWN WALK  /  " + ("Overview" if overview else "Following resident")


func _register_inputs() -> void:
	var bindings := {
		"town_left": [KEY_A, KEY_LEFT], "town_right": [KEY_D, KEY_RIGHT],
		"town_up": [KEY_W, KEY_UP], "town_down": [KEY_S, KEY_DOWN],
		"town_run": [KEY_SHIFT], "town_camera": [KEY_TAB],
		"town_reset": [KEY_R], "town_quit": [KEY_ESCAPE]
	}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


func _add_obstacles(objects: Node2D) -> void:
	# Conservative building bounds keep this single-layer art readable while walking.
	# Other props use ground footprints, so the resident can pass under tree canopies.
	var footprints := {
		"house": Rect2(-58, -143, 116, 143),
		"community_shop": Rect2(-74, -143, 148, 143),
		"tree": Rect2(-6, -12, 12, 12),
		"fence": Rect2(-31, -8, 62, 8),
		"planter": Rect2(-13, -11, 26, 11),
		"notice_board": Rect2(-20, -9, 40, 9),
		"bench": Rect2(-23, -15, 46, 15),
		"street_lamp": Rect2(-4, -6, 8, 6),
		"old_car": Rect2(-38, -23, 76, 23)
	}
	for object in objects.get_children():
		if object == player:
			continue
		# The PackedScene path identifies repeated objects despite Godot's unique node names.
		var asset_id: String = object.scene_file_path.get_file().get_basename()
		if footprints.has(asset_id):
			_add_box(object, footprints[asset_id])
	_add_box(self, Rect2(-16, -16, 672, 16))
	# Leave the lower pavement strip to the controls, so the resident stays visible.
	_add_box(self, Rect2(-16, 355, 672, 45))
	_add_box(self, Rect2(-16, 0, 16, 384))
	_add_box(self, Rect2(640, 0, 16, 384))


func _add_box(parent: Node2D, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)
	parent.add_child(body)


func _add_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var title_background := ColorRect.new()
	title_background.color = Color("405d4ef2")
	title_background.position = Vector2.ZERO
	title_background.size = Vector2(640, 29)
	title_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(title_background)
	var title := _label("PROJECT KINGDOM", Vector2(13, 5), 15)
	hud.add_child(title)
	camera_caption = _label("", Vector2(421, 10), 10)
	hud.add_child(camera_caption)
	var controls_background := ColorRect.new()
	controls_background.color = Color("405d4ef2")
	controls_background.position = Vector2(0, 359)
	controls_background.size = Vector2(640, 25)
	controls_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls_background)
	hud.add_child(_label("WASD / Arrows: move   Shift: run   Tab: camera   R: reset   Esc: quit", Vector2(13, 365), 11))


func _label(text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f7e7bf"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
