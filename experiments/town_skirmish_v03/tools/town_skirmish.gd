extends "res://experiments/hd2d_town_v02/tools/hd2d_demo.gd"

const FIGHT_ROOT := "res://experiments/town_skirmish_v03/"
const FIGHTER := preload(FIGHT_ROOT+"tools/town_fighter.gd")
const BUILDING := preload(FIGHT_ROOT+"tools/town_building.gd")
const CAT_START := Vector3(-6,0.08,3.4)
const OBJECTIVE := Vector3(5,0.05,-3.5)
const RENDER_SIZE := Vector2i(1920,1080)
var fighters: Array = []
var buildings: Array[Node3D] = []
var solids: Array[Rect2] = []
var navigation: AStarGrid2D
var finished := false
var started := false
var won := false
var captured := 0.0
var defeated := 0
var health_label: Label
var objective_label: Label
var capture_bar: ProgressBar
var overlay: ColorRect
var result_label: Label
var flag_material: StandardMaterial3D
var objective_mesh: MeshInstance3D
var canopies: Array[Sprite3D] = []
var stats_start_usec := 0
var stats_last_usec := 0
var stats_count := 0
var stats_worst_ms := 0.0
var stats_text := "Measuring FPS…"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().physics_interpolation = true
	super._ready()
	get_window().title = "Project Kingdom — Cats & Dogs: Garden Hall"
	# Fixed native 1080p also prevents Retina/maximized windows multiplying GPU work.
	get_window().content_scale_size = RENDER_SIZE
	get_window().size = RENDER_SIZE
	Engine.max_fps = 60
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	# Render-time camera sampling follows the same interpolated position as the sprite.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.far = 80.0
	camera.size = 16.8
	camera_anchor = Vector3(resident.position.x*0.45,2.5,resident.position.z*0.25-3.2)
	camera.position = camera_anchor+Vector3(13,18,23)
	_build_navigation()
	_update_game_hud()


func _environment() -> void:
	super._environment()
	for node in get_children():
		if node is WorldEnvironment:
			node.environment.ssao_enabled = false
		elif node is DirectionalLight3D:
			node.directional_shadow_max_distance = 45.0
			node.shadow_normal_bias = 0.7


func _plane(at: Vector3, size: Vector2, kind: int) -> void:
	var instance := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	var material := ShaderMaterial.new()
	material.shader = preload("res://experiments/town_skirmish_v03/tools/town_ground.gdshader")
	material.set_shader_parameter("surface_kind",kind)
	instance.material_override = material
	add_child(instance)


func _build_neighborhood() -> void:
	for entry in [[Vector3(-7.4,0,-7.1),false],[Vector3(4.6,0,-7.1),true]]:
		var building := BUILDING.new()
		add_child(building)
		building.build(self,entry[0],entry[1])
		buildings.append(building)
	for entry in [[Vector3(-13,0,-9),6.4],[Vector3(-3.8,0,-12),7.0],[Vector3(10.5,0,-10),6.7],[Vector3(-11,0,6.8),6.1],[Vector3(-1.8,0,6.8),5.9],[Vector3(12.2,0,6.4),6.7]]:
		_card("tree",entry[0],entry[1])
		_obstacle(entry[0],Vector3(0.55,2,0.55))
	for x in range(-18,19,4):
		_card("tree",Vector3(x,0,-14),6.3)
	for x in range(-15,16,2):
		for z in [-5.35,5.35,10.2]:
			if z<0 and (absf(x+7.4)<2.9 or absf(x-4.6)<3.5):
				continue
			if z>0 and z<6 and x>-9 and x<-3:
				continue
			_card("garden",Vector3(x,0.04,z),1.7 if z>8 else 0.9)
	for entry in [Vector3(-11.0,0,-3.8),Vector3(-2.0,0,-3.8),Vector3(10,0,-3.8),Vector3(0,0,3.9)]:
		_card("lamp",entry,3.5)
		_obstacle(entry,Vector3(0.3,1,0.3))
	_fence(-12.0,-8.5,5.15)
	_fence(-3.6,1.8,5.15)
	_bench(Vector3(10.5,0.04,5.7))
	_notice_board(Vector3(-1.1,0,-5.0))
	_card("old_car",Vector3(11.3,0.05,1.3),1.6)
	_obstacle(Vector3(11.3,0,1.3),Vector3(2.2,1,1.0))
	for at in [Vector3(-4.5,0.3,1.2),Vector3(8,0.3,-0.3)]:
		var dapple := Decal.new()
		dapple.texture_albedo = load(ROOT+"assets/tree.png")
		dapple.size = Vector3(7.0,2.5,4.7)
		dapple.position = at
		dapple.modulate = Color(0.05,0.09,0.14,0.38)
		dapple.normal_fade = 0.0
		add_child(dapple)
	_build_objective()


func _obstacle(at: Vector3, size: Vector3) -> void:
	solids.append(Rect2(at.x-size.x/2.0,at.z-size.z/2.0,size.x,size.z))
	super._obstacle(at,size)


func _card(id: String, at: Vector3, height: float) -> Sprite3D:
	var card := super._card(id,at,height)
	if id=="tree":
		canopies.append(card)
	return card


func _flush_box_batches() -> void:
	super._flush_box_batches()
	for node in get_children():
		if node is MultiMeshInstance3D and node.multimesh.mesh is BoxMesh:
			var material := node.multimesh.mesh.material as StandardMaterial3D
			if material.albedo_color==Color("edc478"):
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				material.albedo_color = Color("dcb16b")


func _build_resident() -> void:
	resident = _spawn_fighter(CAT_START,true,true,false)
	_spawn_fighter(Vector3(-8.6,0.08,3.8),true,false,true)
	for point in [Vector3(-2.1,0.08,0.3),Vector3(-10,0.08,-1.8),Vector3(3.5,0.08,-1.3),Vector3(6.5,0.08,-2.6),Vector3(8.5,0.08,0.1),Vector3(7,0.08,3.4)]:
		_spawn_fighter(point,false,false,false)


func _spawn_fighter(at: Vector3, is_cat: bool, controlled: bool, ally: bool):
	var fighter := FIGHTER.new()
	fighter.town = self
	fighter.cat = is_cat
	fighter.controlled = controlled
	fighter.ally = ally
	fighter.position = at
	fighter.home = at
	fighter.patrol_end = at+Vector3(1.0,0,0.7)
	fighter.name = "CatPlayer" if controlled else ("CatGuard" if ally else "DogPatrol")
	add_child(fighter)
	fighter.reset_physics_interpolation()
	fighters.append(fighter)
	fighter.died.connect(_fighter_died)
	return fighter


func _register_inputs() -> void:
	super._register_inputs()
	if not InputMap.has_action("sk_attack"):
		InputMap.add_action("sk_attack")
	if not InputMap.has_action("sk_mouse_attack"):
		InputMap.add_action("sk_mouse_attack")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	if not InputMap.action_has_event("sk_attack",key):
		InputMap.action_add_event("sk_attack",key)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event("sk_mouse_attack",mouse):
		InputMap.action_add_event("sk_mouse_attack",mouse)


func _build_navigation() -> void:
	navigation = AStarGrid2D.new()
	navigation.region = Rect2i(0,0,60,44)
	navigation.cell_size = Vector2(0.5,0.5)
	navigation.offset = Vector2(-14.75,-11.75)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in 44:
		for x in 60:
			var cell := Vector2i(x,y)
			var p := navigation.get_point_position(cell)
			for solid in solids:
				if solid.grow(0.28).has_point(p):
					navigation.set_point_solid(cell,true)
					break


func _nearest_cell(point: Vector3) -> Vector2i:
	var raw := Vector2i(roundi((point.x-navigation.offset.x)/0.5),roundi((point.z-navigation.offset.y)/0.5))
	raw = Vector2i(clampi(raw.x,0,59),clampi(raw.y,0,43))
	if not navigation.is_point_solid(raw):
		return raw
	for radius in range(1,8):
		for dy in range(-radius,radius+1):
			for dx in range(-radius,radius+1):
				var cell := raw+Vector2i(dx,dy)
				if navigation.region.has_point(cell) and not navigation.is_point_solid(cell):
					return cell
	return raw


func find_path(start: Vector3, end: Vector3) -> PackedVector3Array:
	var path := PackedVector3Array()
	if navigation==null:
		return path
	for cell in navigation.get_id_path(_nearest_cell(start),_nearest_cell(end),true):
		var point := navigation.get_point_position(cell)
		path.append(Vector3(point.x,0.05,point.y))
	return path


func clear_line(from: Vector3, to: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(from+Vector3(0,0.7,0),to+Vector3(0,0.7,0),1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func mouse_aim(from: Vector3) -> Vector3:
	var pixel := get_viewport().get_mouse_position()
	var point = Plane(Vector3.UP,0.3).intersects_ray(camera.project_ray_origin(pixel),camera.project_ray_normal(pixel))
	return Vector3(point.x-from.x,0,point.z-from.z).normalized() if point!=null else resident.facing


func _physics_process(delta: float) -> void:
	if get_tree().paused or finished:
		return
	advance_capture(delta)


func advance_capture(delta: float) -> void:
	if finished or resident.health.is_dead():
		return
	var in_ring := Vector2(resident.position.x-OBJECTIVE.x,resident.position.z-OBJECTIVE.z).length()<1.55
	var contested := false
	for fighter in fighters:
		if is_instance_valid(fighter) and not fighter.cat and not fighter.health.is_dead() and fighter.global_position.distance_to(OBJECTIVE)<5.5:
			contested = true
	if in_ring and not contested:
		captured = minf(1.0,captured+delta/4.0)
	elif not in_ring:
		captured = maxf(0.0,captured-delta*0.12)
	if captured>=1.0:
		finish(true)


func _fighter_died(fighter) -> void:
	if fighter.controlled:
		finish(false)
	elif not fighter.cat:
		defeated += 1


func finish(victory: bool) -> void:
	if finished:
		return
	finished = true
	won = victory
	flag_material.albedo_color = Color("d78572") if victory else Color("658eae")
	_update_game_hud()


func restart_battle() -> void:
	get_tree().paused = false
	for fighter in fighters:
		if is_instance_valid(fighter):
			fighter.queue_free()
	fighters.clear()
	finished = false
	started = false
	won = false
	defeated = 0
	captured = 0.0
	flag_material.albedo_color = Color("658eae")
	_build_resident()
	camera_anchor = Vector3(resident.position.x*0.45,2.5,resident.position.z*0.25-3.2)
	_update_game_hud()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("hd_reset"):
		restart_battle()
	elif event.is_action("hd_quit") and not finished:
		get_tree().paused = not get_tree().paused
		_update_game_hud()
	else:
		super._unhandled_key_input(event)


func _process(delta: float) -> void:
	var previous_anchor := camera_anchor
	super._process(delta)
	var hero := resident.get_global_transform_interpolated().origin
	var target := Vector3(0,2.5,-2.2) if overview else Vector3(hero.x*0.45,2.5,hero.z*0.25-3.2)
	camera_anchor = previous_anchor.lerp(target,1.0-exp(-delta*2.8))
	camera.position = camera_anchor+Vector3(13,18,23)
	camera.size = 19.0 if overview else 16.8
	_fade_obstructing_canopies(delta)
	_update_game_hud()
	_update_frame_stats()


func _update_frame_stats() -> void:
	# Wall-clock timing also exposes stalls that an engine delta clamp can hide.
	var now := Time.get_ticks_usec()
	if stats_start_usec==0:
		stats_start_usec = now
		stats_last_usec = now
	else:
		stats_count += 1
		stats_worst_ms = maxf(stats_worst_ms,(now-stats_last_usec)/1000.0)
		stats_last_usec = now
		var elapsed := (now-stats_start_usec)/1000000.0
		if elapsed>=1.0:
			var resolution := get_viewport().get_texture().get_size()
			stats_text = "%d FPS  |  %d × %d\n%.1f ms max frame" % [roundi(stats_count/elapsed),int(resolution.x),int(resolution.y),stats_worst_ms]
			stats_start_usec = now
			stats_count = 0
			stats_worst_ms = 0.0
	fps_label.text = stats_text


func _fade_obstructing_canopies(delta: float) -> void:
	var hero := resident.get_global_transform_interpolated().origin
	var head := camera.unproject_position(hero+camera.global_basis.y*1.1)
	for card in canopies:
		var center := camera.unproject_position(card.global_position)
		var right := camera.unproject_position(card.global_position+camera.global_basis.x*card.texture.get_width()*card.pixel_size*0.5)
		var top := camera.unproject_position(card.global_position+camera.global_basis.y*card.texture.get_height()*card.pixel_size*0.5)
		var size := Vector2(absf(right.x-center.x)*2.0,absf(top.y-center.y)*2.0)
		var obscures := Rect2(center-size/2.0,size).has_point(head) and camera.global_basis.z.dot(card.global_position-hero)>0.15
		var alpha := lerpf(card.modulate.a,0.08 if obscures else 1.0,1.0-exp(-delta*12.0))
		card.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED if alpha<0.995 else SpriteBase3D.ALPHA_CUT_DISCARD
		card.modulate.a = alpha


func _build_objective() -> void:
	objective_mesh = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.43
	torus.outer_radius = 1.50
	torus.rings = 40
	torus.ring_segments = 6
	objective_mesh.mesh = torus
	objective_mesh.position = OBJECTIVE
	flag_material = StandardMaterial3D.new()
	flag_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flag_material.albedo_color = Color("658eae")
	objective_mesh.material_override = flag_material
	objective_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(objective_mesh)
	_box(OBJECTIVE+Vector3(1.8,1.1,0),Vector3(0.065,2.2,0.065),Color("74654b"))
	var flag := MeshInstance3D.new()
	var cloth := BoxMesh.new()
	cloth.size = Vector3(0.75,0.48,0.025)
	flag.mesh = cloth
	flag.position = OBJECTIVE+Vector3(2.18,1.86,0)
	flag.material_override = flag_material
	add_child(flag)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "BattleHUD"
	add_child(hud)
	var panel := Panel.new()
	panel.position = Vector2(36,32)
	panel.size = Vector2(568,225)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.055,0.105,0.095,0.88)
	background.border_color = Color(0.72,0.64,0.41,0.65)
	background.set_border_width_all(1)
	background.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel",background)
	hud.add_child(panel)
	_hud_label(hud,"P R O J E C T   K I N G D O M",Vector2(60,48),26)
	caption = _hud_label(hud,"",Vector2(60,88),16)
	caption.add_theme_color_override("font_color",Color("d7bf88"))
	health_label = _hud_label(hud,"",Vector2(60,130),20)
	objective_label = _hud_label(hud,"",Vector2(60,166),16)
	objective_label.size = Vector2(520,44)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	capture_bar = ProgressBar.new()
	capture_bar.position = Vector2(60,228)
	capture_bar.show_percentage = false
	capture_bar.add_theme_font_size_override("font_size",1)
	capture_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = Color("34463c")
	track.set_corner_radius_all(3)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = Color("d6bd7e")
	capture_bar.add_theme_stylebox_override("background",track)
	capture_bar.add_theme_stylebox_override("fill",fill)
	# Keep the engine's intrinsic minimum, then draw a slim track in screen space.
	capture_bar.size = Vector2(520,24)
	capture_bar.scale.y = 0.25
	hud.add_child(capture_bar)
	fps_label = _hud_label(hud,"Measuring FPS…",Vector2.ZERO,18)
	fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fps_label.offset_left = -360
	fps_label.offset_right = -36
	fps_label.offset_top = 36
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var controls := _hud_label(hud,"WASD  Move     SHIFT  Run     SPACE / CLICK  Attack     TAB  View     ESC  Pause     R  Restart     F3  FPS",Vector2.ZERO,18)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.offset_left = 36
	controls.offset_top = -54
	controls.offset_bottom = -24
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.06,0.12,0.11,0.78)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(overlay)
	result_label = Label.new()
	result_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size",42)
	_style_label(result_label)
	overlay.add_child(result_label)
	_update_game_hud()


func _hud_label(hud: CanvasLayer, text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	_style_label(label)
	hud.add_child(label)
	return label


func _update_game_hud() -> void:
	if health_label==null or not is_instance_valid(resident):
		return
	caption.text = "CAT OUTPOST   /   Retake Garden Hall"
	health_label.text = "CAT WARRIOR   %d / %d HP" % [resident.health.current,resident.health.maximum]
	objective_label.text = ("Clear dogs near the blue ring, then hold it · %d defeated" % defeated) if started else "Move or attack to begin · Retake the blue ring at Garden Hall"
	capture_bar.value = captured*100.0
	overlay.visible = finished or get_tree().paused
	result_label.text = ("GARDEN HALL SECURED\n\nR  Start again" if won else "CAT WARRIOR DOWN\n\nR  Try again") if finished else "PAUSED\n\nEsc  Resume     R  Restart"


func _capture() -> void:
	print("Preparing native 1080p preview.")
	await get_tree().create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(FIGHT_ROOT+"previews/town_skirmish.png"))
	print("Town skirmish preview saved.")
	if "--quit-after-capture" in OS.get_cmdline_user_args():
		get_tree().quit()
