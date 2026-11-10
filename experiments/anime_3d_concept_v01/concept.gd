extends Node3D

const M := preload("res://experiments/anime_3d_concept_v01/modeling.gd")
const Hero := preload("res://experiments/anime_3d_concept_v01/hero.tscn")
const Frog := preload("res://experiments/anime_3d_concept_v01/frog.tscn")
const Backdrop := preload("res://experiments/anime_3d_concept_v01/backdrop.gdshader")
const Waymarker := preload("res://experiments/anime_3d_concept_v01/waymarker.tscn")

const OVERVIEW := Vector3(0,.98,0)
const START_YAW := .28
var yaw := START_YAW
var tilt := .29
var distance := 8.8
var focus := OVERVIEW
var dragging := false
var hop_time := -1.0
var frog: Node3D
var hero: Node3D
var waymarker: Node3D
var camera: Camera3D
var caption: Label


func _ready() -> void:
	get_window().title = "Project Kingdom · Tabby Character Study"
	get_window().content_scale_size = Vector2i(1600,900)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	build_lighting()
	build_ground()
	hero = Hero.instantiate()
	hero.position = Vector3(-.74,0,.25)
	hero.rotation.y = .09
	add_child(hero)
	frog = Frog.instantiate()
	frog.position = Vector3(.99,0,.42)
	frog.rotation.y = -.19
	add_child(frog)
	waymarker = Waymarker.instantiate()
	waymarker.position = Vector3(-2.18,0,-.34)
	waymarker.rotation.y = -.27
	add_child(waymarker)

	camera = Camera3D.new()
	camera.fov = 33
	camera.current = true
	add_child(camera)
	build_hud()
	frame(1)


func _process(delta: float) -> void:
	if hop_time < 0.0:
		return
	hop_time += delta
	var phase := minf(hop_time / .72, 1.0)
	frog.position.y = sin(PI * clampf((phase-.16)/.69,0,1)) * .48
	var compression := .13 * (sin(PI * clampf(phase/.16,0,1)) + sin(PI * clampf((phase-.85)/.15,0,1)))
	frog.scale = Vector3(1+compression*.28,1-compression,1+compression*.35)
	if phase >= 1.0:
		frog.position.y = 0
		frog.scale = Vector3.ONE
		hop_time = -1.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				dragging = event.pressed
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					var direction := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
					distance = clampf(distance + direction*.45, 2.7, 12.0)
					update_camera()
	elif event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * .007
		tilt = clampf(tilt + event.relative.y * .005, -.04, 1.05)
		update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: frame(1)
			KEY_2: frame(2)
			KEY_3, KEY_R: frame(3)
			KEY_SPACE:
				if not frog.visible:
					frame(2)
				if hop_time < 0.0:
					hop_time = 0.0


func frame(subject: int) -> void:
	hero.visible = subject != 2
	frog.visible = subject != 1
	waymarker.visible = subject == 3
	match subject:
		1:
			focus = Vector3(hero.position.x,1.32,hero.position.z)
			distance = 5.6
			caption.text = "01 / Tabby adventurer"
		2:
			focus = Vector3(frog.position.x,.62,frog.position.z)
			distance = 4.5
			caption.text = "02 / Frog mount"
		3:
			focus = OVERVIEW
			distance = 8.8
			caption.text = "03 / Wayside diorama"
	yaw = .43 if subject == 1 else START_YAW
	tilt = .16 if subject == 1 else .29
	update_camera()


func update_camera() -> void:
	camera.position = focus + distance * Vector3(sin(yaw)*cos(tilt),sin(tilt),cos(yaw)*cos(tilt))
	camera.look_at(focus)


func build_lighting() -> void:
	var backdrop := WorldEnvironment.new()
	var atmosphere := Environment.new()
	var sky := Sky.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = Backdrop
	sky.sky_material = sky_material
	atmosphere.background_mode = Environment.BG_SKY
	atmosphere.sky = sky
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("dae7ff")
	atmosphere.ambient_light_energy = .61
	backdrop.environment = atmosphere
	add_child(backdrop)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-49,-34,0)
	key.light_color = Color("fff0d0")
	key.light_energy = 1.19
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 13.0
	key.shadow_blur = 2.1
	key.shadow_normal_bias = .75
	add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-26,152,0)
	rim.light_color = Color("b4daf5")
	rim.light_energy = .53
	add_child(rim)


func build_ground() -> void:
	var green := M.paint("88a862")
	var rim := M.paint("607b51")
	var soil := M.paint("6e6047")
	var earth := M.cylinder(self,"Earthen island",Vector3(0,-.285,0),2.84,2.62,.43,soil,64)
	earth.scale.z = .675
	var grass_edge := M.cylinder(self,"Grassy bank",Vector3(0,-.096,0),2.84,2.86,.15,rim,64)
	grass_edge.scale.z = .675
	var lawn := M.cylinder(self,"Meadow",Vector3(0,-.034,0),2.83,2.85,.065,green,64)
	lawn.scale.z = .675

	var path := SurfaceTool.new()
	path.begin(Mesh.PRIMITIVE_TRIANGLES)
	var last_left := Vector3.ZERO
	var last_right := Vector3.ZERO
	for step in 31:
		var z := lerpf(-1.71,1.84,step/30.0)
		var x := sin(z*1.72-.4)*.26 + z*.13
		var width := .41 + sin(z*5.2)*.04 + .04*z
		var left := Vector3(x-width,.006,z)
		var right := Vector3(x+width,.006,z)
		if step > 0:
			for vertex: Vector3 in [last_left,last_right,left,last_right,right,left]:
				path.add_vertex(vertex)
		last_left = left
		last_right = right
	path.generate_normals()
	M.piece(self,"Worn trail",path.commit(),M.paint("d3b582"),Vector3.ZERO)

	var stone := M.paint("ada88f")
	var pebble := M.paint("c2b99d")
	var pale := M.paint("fff4d9")
	var pollen := M.paint("f5c36c")
	var stalk := M.paint("577a47")
	var rng := RandomNumberGenerator.new()
	rng.seed = 927
	for index in 29:
		var x := rng.randf_range(-2.45,2.45)
		var z := rng.randf_range(-1.65,1.65)
		if Vector2(x/2.7,z/1.83).length_squared() > .94:
			continue
		if absf(x - (sin(z*1.72-.4)*.26 + z*.13)) < .54:
			var grit := M.ball(self,"Path grit",Vector3(x,.012,z),Vector3(rng.randf_range(.019,.049),.012,.028),pebble)
			grit.rotation.y = rng.randf_range(0,TAU)
			continue
		if Vector2(x+.74,z-.25).length() < .64 or Vector2(x-.99,z-.42).length() < .76:
			continue
		var size := rng.randf_range(.045,.15)
		M.ball(self,"Field stone",Vector3(x,.023,z),Vector3(size,size*.54,size*.8),stone)
		if index % 2 == 0:
			flower(Vector3(x+.09,0,z),rng.randf_range(.13,.25),stalk,pale,pollen)
	for at: Vector3 in [Vector3(-1.83,0,.9),Vector3(-1.58,0,.78),Vector3(1.8,0,-.76),Vector3(1.96,0,-.7),Vector3(1.61,0,.92)]:
		flower(at,.22,stalk,pale,pollen)
	for at: Vector3 in [Vector3(-2.12,0,-.45),Vector3(2.21,0,-.39),Vector3(-1.69,0,-1.05),Vector3(1.28,0,-1.26)]:
		M.ball(self,"Meadow clump",at+Vector3(0,.13,0),Vector3(.27,.20,.19),green)
		M.ball(self,"Clover leaves",at+Vector3(.13,.17,-.03),Vector3(.14,.14,.13),stalk)


func flower(at: Vector3, height: float, stalk: Material, pale: Material, pollen: Material) -> void:
	var top := at+Vector3(.037,height,0)
	M.limb(self,"Flower stem",at,top,.015,.015,stalk)
	for index in 5:
		var angle := TAU * index / 5.0
		var petal := M.ball(self,"Daisy petal",top+Vector3(cos(angle)*.038,.009,sin(angle)*.038),Vector3(.039,.014,.023),pale)
		petal.rotation.y = -angle
	M.ball(self,"Daisy heart",top+Vector3(0,.025,0),Vector3(.026,.015,.026),pollen)


func build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var title := Label.new()
	title.position = Vector2(49,33)
	title.text = "PROJECT KINGDOM   /   ART STUDY 01"
	title.add_theme_color_override("font_color",Color("30514f"))
	title.add_theme_font_size_override("font_size",20)
	hud.add_child(title)

	caption = Label.new()
	caption.position = Vector2(47,60)
	caption.text = "03 / Wayside diorama"
	caption.add_theme_color_override("font_color",Color("203c39"))
	caption.add_theme_font_size_override("font_size",40)
	hud.add_child(caption)

	var controls := Label.new()
	controls.position = Vector2(50,837)
	controls.text = "Drag  Orbit     ·     Scroll  Zoom     ·     1  Tabby     ·     2  Frog     ·     3  Diorama     ·     Space  Hop"
	controls.add_theme_color_override("font_color",Color("30514f"))
	controls.add_theme_font_size_override("font_size",20)
	hud.add_child(controls)
