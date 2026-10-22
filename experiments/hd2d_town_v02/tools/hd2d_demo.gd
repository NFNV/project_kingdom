extends Node3D

const ROOT := "res://experiments/hd2d_town_v02/"
const RESIDENT := preload(ROOT + "tools/hd2d_resident.gd")
const GROUND := preload(ROOT + "tools/ground.gdshader")
const SPAWN := Vector3(1.0, 0.08, 3.65)
var camera: Camera3D
var resident: CharacterBody3D
var scenery: Node3D
var metadata: Dictionary
var textures: Dictionary = {}
var overview := false
var camera_anchor := Vector3(0, 1.5, 1)
var caption: Label
var time := 0.0
var motes: MultiMeshInstance3D
var mote_origins: Array[Vector3] = []
var box_batches: Dictionary = {}
var fps_label: Label
var fps_time := 0.0
var fps_frames := 0


func _ready() -> void:
	var window := get_window()
	window.title = "Project Kingdom — HD-2D Garden Street"
	window.content_scale_size = Vector2i(1280, 720)
	# Keep 3D rendering at 720p even when macOS resizes the Retina window.
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.size = Vector2i(1280, 720)
	_register_inputs()
	metadata = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/catalog.json"))
	_environment()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.7
	camera.position = camera_anchor + Vector3(13, 18, 23)
	add_child(camera)
	camera.look_at(camera_anchor)
	camera.current = true
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_far_enabled = true
	lens.dof_blur_far_distance = 40.0
	lens.dof_blur_far_transition = 7.0
	lens.dof_blur_near_enabled = true
	lens.dof_blur_near_distance = 18.0
	lens.dof_blur_near_transition = 5.0
	lens.dof_blur_amount = 0.06
	camera.attributes = lens
	scenery = Node3D.new()
	scenery.name = "IllustratedScenery"
	add_child(scenery)
	_build_ground()
	_build_neighborhood()
	_flush_box_batches()
	_build_resident()
	_build_motes()
	_build_hud()
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()


func _environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("bed6b9")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c9dfd6")
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	# Scenery has baked local shading; SSAO adds little to these flat cards.
	environment.ssao_enabled = false
	environment.ssao_radius = 1.0
	environment.ssao_intensity = 0.7
	environment.glow_enabled = false
	environment.glow_intensity = 0.3
	environment.glow_bloom = 0.03
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "LateAfternoonSun"
	sun.rotation_degrees = Vector3(-52, -120, 0)
	sun.light_color = Color("fff0c9")
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.shadow_blur = 1.3
	sun.directional_shadow_max_distance = 65.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)


func _build_ground() -> void:
	_plane(Vector3.ZERO, Vector2(120, 100), 0)
	_box(Vector3(0, -0.11, 0), Vector3(44, 0.3, 32), Color("71824d"), true, false)
	_plane(Vector3(0, 0.018, 0), Vector2(44, 5.1), 2)
	for z in [-3.8, 3.8]:
		_plane(Vector3(0, 0.025, z), Vector2(44, 2.5), 1)
		for x in range(-28, 28):
			_box(Vector3(x * 0.8, 0.045, signf(z) * 2.58), Vector3(0.78, 0.09, 0.2), Color("b7b099"))
	for x in range(-10, 11):
		_box(Vector3(x * 2.2, 0.023, 0), Vector3(0.85, 0.008, 0.055), Color("d5ccb0"))
	# Park walk and the cottage gate path.
	_plane(Vector3(-6.7, 0.03, -7.1), Vector2(9.5, 4.6), 1)
	_plane(Vector3(-5.4, 0.03, 6.3), Vector2(1.5, 3.8), 1)
	for x in [-9.5, 6.5]:
		for z in [-2.43, 2.43]:
			_box(Vector3(x, 0.03, z), Vector3(0.64, 0.025, 0.24), Color("3a4547"))
			for slot in 6:
				_box(Vector3(x - 0.26 + slot * 0.1, 0.048, z), Vector3(0.025, 0.008, 0.22), Color("8b8e7c"))
	# Invisible outer walls, keeping the illustrated block explorable.
	_box(Vector3(0, 1, -12), Vector3(34, 2, 0.2), Color.WHITE, true, false)
	_box(Vector3(0, 1, 10), Vector3(34, 2, 0.2), Color.WHITE, true, false)
	_box(Vector3(-15, 1, 0), Vector3(0.2, 2, 25), Color.WHITE, true, false)
	_box(Vector3(15, 1, 0), Vector3(0.2, 2, 25), Color.WHITE, true, false)


func _build_neighborhood() -> void:
	_card("cottage", Vector3(-7.6, 0.04, 6.2), 7.7)
	_obstacle(Vector3(-7.6, 0, 6.7), Vector3(4.7, 4, 2.8))
	_card("shop", Vector3(4.0, 0.04, -4.7), 7.1)
	_obstacle(Vector3(4.0, 0, -5.4), Vector3(4.9, 4, 2.4))
	# Park canopy and foreground framing, leaving the road unobstructed.
	var trees := [
		[Vector3(-12, 0, -8), 6.5], [Vector3(-7.5, 0, -10.5), 6.8],
		[Vector3(-1.8, 0, -10), 7.2], [Vector3(8.8, 0, -9.5), 6.0],
		[Vector3(13.2, 0, -7), 6.6], [Vector3(-1.9, 0, 5.9), 6.4],
		[Vector3(12.3, 0, 7.5), 7.0], [Vector3(-13.4, 0, 5.1), 5.8]
	]
	for entry in trees:
		_card("tree", entry[0], entry[1])
		_obstacle(entry[0], Vector3(0.55, 2, 0.55))
	for x in range(-20, 21, 4):
		_card("tree", Vector3(x, 0, -14), 6.7 + sin(x) * 0.6)
	for x in range(-17, 18, 2):
		_card("garden", Vector3(x, 0.04, 10.8 + sin(x) * 0.4), 2.1 + cos(x) * 0.3)
	for x in [-13.0, 14.0]:
		_card("tree", Vector3(x, 0, 11), 7.2)
	# Projected foliage masks supplement geometric shadows with fine leaf detail.
	for at in [Vector3(0.4, 0.3, 0.8), Vector3(9.3, 0.3, -0.4), Vector3(-8.0, 0.3, -1.2)]:
		var dapple := Decal.new()
		dapple.texture_albedo = load(ROOT + "assets/tree.png")
		dapple.size = Vector3(8.5, 2.5, 5.5)
		dapple.position = at
		dapple.rotation.y = -0.5
		dapple.modulate = Color(0.05, 0.09, 0.14, 0.48)
		dapple.albedo_mix = 1.0
		dapple.normal_fade = 0.0
		add_child(dapple)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9421
	for side in [-1.0, 1.0]:
		for index in 15:
			var x := -13.5 + index * 1.9
			if side < 0 and x > 0.4 and x < 7.5:
				continue
			if side > 0 and x > -6.3 and x < -4.7:
				continue
			var plant := _card("garden", Vector3(x, 0.04, side * 5.25 + rng.randf_range(-0.16, 0.16)), rng.randf_range(0.8, 1.12))
			plant.modulate = Color(rng.randf_range(0.92, 1.05), rng.randf_range(0.94, 1.04), 1.0)
	for x in [-10.0, -4.0, 1.3, 8.5]:
		_card("garden", Vector3(x, 0.03, -8.0), 1.25)
	for entry in [Vector3(-10, 0, 3.9), Vector3(3.0, 0, 3.9), Vector3(10.8, 0, -3.8), Vector3(-6.6, 0, -3.8)]:
		_card("lamp", entry, 3.5)
		_obstacle(entry, Vector3(0.32, 1, 0.32))
		var light := OmniLight3D.new()
		light.position = entry + Vector3(0, 2.8, 0)
		light.light_color = Color("ffcd78")
		light.light_energy = 0.65
		light.omni_range = 3.0
		add_child(light)
	_fence(-12.3, -6.3, 5.15)
	_fence(-4.6, -1.0, 5.15)
	_fence(-11.5, -1.0, -5.3, true)
	_bench(Vector3(-5.0, 0.04, -7.2))
	_bench(Vector3(10.5, 0.04, -6.1))
	_notice_board(Vector3(-0.3, 0, -4.8))
	if metadata.has("old_car"):
		_card("old_car", Vector3(6.3, 0.03, -0.8), 1.75)
		_obstacle(Vector3(6.3, 0, -0.8), Vector3(2.3, 1, 1.15))


func _build_resident() -> void:
	resident = RESIDENT.new()
	resident.name = "PlayableResident"
	resident.position = SPAWN
	resident.camera = camera
	add_child(resident)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.2
	capsule.height = 1.15
	collision.shape = capsule
	collision.position.y = 0.59
	resident.add_child(collision)
	var sprite := Sprite3D.new()
	var source: Texture2D = load(ROOT + "assets/resident_walk.png")
	for rect: Array in metadata["resident_walk"]["frames"]:
		var frame := AtlasTexture.new()
		frame.atlas = source
		frame.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		frame.margin = Rect2((180.0-rect[2])/2.0, 300-rect[3], 180-rect[2], 300-rect[3])
		resident.frames.append(frame)
	sprite.texture = resident.frames[0]
	sprite.pixel_size = 1.82 / 300.0
	sprite.position = camera.global_basis.y * 0.91
	_setup_card(sprite)
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	resident.add_child(sprite)
	resident.sprite = sprite
	# A soft native contact shadow keeps the animated feet grounded.
	var shadow := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.25
	disc.bottom_radius = 0.25
	disc.height = 0.003
	shadow.mesh = disc
	shadow.scale.z = 0.65
	shadow.position.y = 0.018
	var shadow_material := StandardMaterial3D.new()
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.albedo_color = Color(0.11, 0.16, 0.13, 0.28)
	shadow.material_override = shadow_material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	resident.add_child(shadow)


func _card(id: String, at: Vector3, height: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = id.capitalize()
	if not textures.has(id):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(ROOT + "assets/" + id + ".png")
		var rect: Array = metadata[id]["region"]
		atlas.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		textures[id] = atlas
	sprite.texture = textures[id]
	sprite.pixel_size = height / sprite.texture.get_height()
	_setup_card(sprite)
	scenery.add_child(sprite)
	sprite.position = at + camera.global_basis.y * height * 0.5
	return sprite


func _setup_card(sprite: Sprite3D) -> void:
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.9
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.shaded = false
	sprite.double_sided = true
	# Baked shading and the shared projected foliage masks provide card shadows.
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _plane(at: Vector3, size: Vector2, kind: int) -> void:
	var instance := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	var material := ShaderMaterial.new()
	material.shader = GROUND
	material.set_shader_parameter("surface_kind", kind)
	instance.material_override = material
	add_child(instance)


func _box(at: Vector3, size: Vector3, color: Color, solid := false, visible_mesh := true) -> void:
	if visible_mesh:
		# A handful of shared draw calls instead of a material/mesh per picket.
		if not box_batches.has(color):
			box_batches[color] = []
		box_batches[color].append(Transform3D(Basis.IDENTITY.scaled(size), at))
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		body.position = at
		add_child(body)


func _flush_box_batches() -> void:
	for color: Color in box_batches:
		var transforms: Array = box_batches[color]
		var instance := MultiMeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.95
		mesh.material = material
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = transforms.size()
		for index in transforms.size():
			multimesh.set_instance_transform(index, transforms[index])
		instance.multimesh = multimesh
		add_child(instance)
	box_batches.clear()


func _obstacle(at: Vector3, size: Vector3) -> void:
	_box(at + Vector3(0, size.y * 0.5, 0), size, Color.WHITE, true, false)


func _fence(left: float, right: float, z: float, iron := false) -> void:
	var color := Color("364e43") if iron else Color("e9dfbf")
	for y in [0.35, 0.88]:
		_box(Vector3((left + right) / 2.0, y, z), Vector3(right-left, 0.085, 0.095), color)
	var count := int((right-left) / 0.3)
	for index in count + 1:
		var x := lerpf(left, right, float(index) / count)
		_box(Vector3(x, 0.58, z), Vector3(0.075 if iron else 0.13, 1.16, 0.10), color)
		if index % 6 == 0:
			_box(Vector3(x, 0.66, z), Vector3(0.24, 1.32, 0.24), Color("a7a48c") if iron else Color("e9dfbf"))
	_obstacle(Vector3((left + right)/2, 0, z), Vector3(right-left, 1.2, 0.18))


func _bench(at: Vector3) -> void:
	_card("bench", at, 1.15)
	_obstacle(at, Vector3(1.8, 0.6, 0.8))


func _notice_board(at: Vector3) -> void:
	_card("notice_board", at, 2.0)
	_obstacle(at, Vector3(1.65, 1.8, 0.4))


func _build_motes() -> void:
	motes = MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := SphereMesh.new()
	mesh.radius = 0.014
	mesh.height = 0.028
	mesh.radial_segments = 4
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ffe6a7")
	material.emission_enabled = true
	material.emission = Color("e6c98a")
	material.emission_energy_multiplier = 1.2
	mesh.material = material
	multimesh.mesh = mesh
	multimesh.instance_count = 38
	motes.multimesh = multimesh
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(motes)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7184
	for index in 38:
		mote_origins.append(Vector3(rng.randf_range(-12, 12), rng.randf_range(0.3, 4.3), rng.randf_range(-7, 8)))


func _process(delta: float) -> void:
	time += delta
	fps_time += delta
	fps_frames += 1
	if fps_time >= 1.0:
		var resolution := get_viewport().get_texture().get_size()
		fps_label.text = "%d FPS  |  %d × %d" % [roundi(fps_frames/fps_time), int(resolution.x), int(resolution.y)]
		fps_time = 0.0
		fps_frames = 0
	var target := Vector3(0, 1.5, 1) if overview else Vector3(resident.position.x * 0.5, 1.5, resident.position.z * 0.35)
	camera_anchor = camera_anchor.lerp(target, 1.0-exp(-delta * 2.2))
	camera.position = camera_anchor + Vector3(13, 18, 23)
	camera.size = lerpf(camera.size, 18.0 if overview else 13.7, 1.0-exp(-delta * 3.0))
	for index in mote_origins.size():
		var p := mote_origins[index] + Vector3(sin(time * 0.2 + index) * 0.2, sin(time * 0.4 + index) * 0.12, cos(time * 0.15 + index) * 0.2)
		motes.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, p))


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("hd_quit"):
		get_tree().quit()
	elif event.is_action("hd_reset"):
		resident.position = SPAWN
		resident.velocity = Vector3.ZERO
	elif event.is_action("hd_camera"):
		overview = not overview
		caption.text = "GARDEN STREET   /   " + ("Overview" if overview else "Afternoon walk")
	elif event.is_action("hd_stats"):
		fps_label.visible = not fps_label.visible


func _register_inputs() -> void:
	var bindings := {"hd_left": [KEY_A, KEY_LEFT], "hd_right": [KEY_D, KEY_RIGHT], "hd_up": [KEY_W, KEY_UP], "hd_down": [KEY_S, KEY_DOWN], "hd_run": [KEY_SHIFT], "hd_camera": [KEY_TAB], "hd_reset": [KEY_R], "hd_quit": [KEY_ESCAPE], "hd_stats": [KEY_F3]}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	fps_label = Label.new()
	fps_label.text = "Measuring FPS…"
	fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fps_label.offset_left = -320
	fps_label.offset_right = -30
	fps_label.offset_top = 24
	fps_label.offset_bottom = 48
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.add_theme_font_size_override("font_size", 14)
	_style_label(fps_label)
	hud.add_child(fps_label)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 23)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var title := Label.new()
	title.text = "P R O J E C T   K I N G D O M"
	title.add_theme_font_size_override("font_size", 20)
	_style_label(title)
	column.add_child(title)
	caption = Label.new()
	caption.text = "GARDEN STREET   /   Afternoon walk"
	caption.add_theme_font_size_override("font_size", 12)
	_style_label(caption)
	column.add_child(caption)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	var controls := Label.new()
	controls.text = "WASD / Arrows   Move     Shift   Run     Tab   View     R   Reset     F3   FPS     Esc   Exit"
	controls.add_theme_font_size_override("font_size", 13)
	_style_label(controls)
	column.add_child(controls)


func _style_label(label: Label) -> void:
	label.add_theme_color_override("font_color", Color("fff2d6"))
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.14, 0.12, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.15, 0.13, 0.55))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _capture() -> void:
	for frame in 40:
		await get_tree().process_frame
	await get_tree().create_timer(1.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT + "previews/hd2d_demo.png"))
	print("HD-2D preview saved.")
	if "--quit-after-capture" in OS.get_cmdline_user_args():
		get_tree().quit()
