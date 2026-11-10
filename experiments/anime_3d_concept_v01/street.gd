extends Node3D

const M := preload("res://experiments/anime_3d_concept_v01/modeling.gd")
const Surfaces := preload("res://experiments/anime_3d_concept_v01/street_surfaces.gdshader")
const Hero := preload("res://experiments/anime_3d_concept_v01/hero.tscn")
const Frog := preload("res://experiments/anime_3d_concept_v01/frog.tscn")
const Waymarker := preload("res://experiments/anime_3d_concept_v01/waymarker.tscn")

const RENDER_SIZE := Vector2i(2560,1440)
const CAMERA_OFFSET := Vector3(-8.0,10.5,12.2)
const START := Vector3(.15,.13,2.16)
const WALK_SPEED := 2.65
const FOLLOW_OFFSET := Vector3(.86,0,-.06)
var hero: Node3D
var frog: Node3D
var walker: CharacterBody3D
var follower: CharacterBody3D
var camera: Camera3D
var walk_cycle := 0.0
var walk_weight := 0.0
var hop_cycle := 0.0
var eye := Vector3.ZERO
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	get_window().title = "Project Kingdom · Garden Lane"
	get_window().content_scale_size = RENDER_SIZE
	get_viewport().scaling_3d_scale = 1.0
	get_viewport().msaa_3d = Viewport.MSAA_4X
	rng.seed = 21893
	light_street()
	build_street()
	build_cast()
	camera = Camera3D.new()
	camera.fov = 34
	camera.current = true
	add_child(camera)
	eye = camera_target()
	update_camera(0.0)
	build_caption()


func _physics_process(delta: float) -> void:
	var arrows := Vector2(
		float(Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_UP))
	)
	var input := (Input.get_vector("move_left","move_right","move_up","move_down")+arrows).limit_length()
	var right := camera.global_basis.x
	var forward := -camera.global_basis.z
	right.y = 0
	forward.y = 0
	var direction := right.normalized()*input.x - forward.normalized()*input.y
	var speed := WALK_SPEED * (1.45 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)
	walker.velocity = Vector3(direction.x*speed,-3.5,direction.z*speed)
	if not walker.is_on_floor():
		walker.velocity.y = minf(walker.velocity.y,-5.0)
	var before := walker.position
	walker.move_and_slide()
	var moved := Vector2(walker.position.x-before.x,walker.position.z-before.z).length()
	if direction.length_squared() > .01:
		walker.rotation.y = lerp_angle(walker.rotation.y,atan2(direction.x,direction.z),1.0-exp(-delta*17.0))
	walk_cycle += moved * 8.9
	walk_weight = move_toward(walk_weight,1.0 if moved > .005 else 0.0,delta*8.0)
	hero.call("pose_walk",walk_cycle,walk_weight)

	var destination := walker.position + FOLLOW_OFFSET
	var flat := Vector3(destination.x-follower.position.x,0,destination.z-follower.position.z)
	var pace := (flat*4.6).limit_length(speed*1.08) if flat.length() > .16 else Vector3.ZERO
	follower.velocity = Vector3(pace.x,-3.5,pace.z)
	follower.move_and_slide()
	if follower.get_real_velocity().slide(Vector3.UP).length_squared() > .07:
		follower.rotation.y = lerp_angle(follower.rotation.y,atan2(flat.x,flat.z),1.0-exp(-delta*12.0))
		hop_cycle = fposmod(hop_cycle + delta*3.25,1.0)
	else:
		hop_cycle = move_toward(hop_cycle,1.0,delta*4.0)
	frog.position.y = sin(PI*hop_cycle)*.15
	update_camera(delta)


func camera_target() -> Vector3:
	# The framing leads into the lane and keeps the hero in the lower half.
	return Vector3(clampf(walker.position.x,-3.7,5.0)-.70,1.13,clampf(walker.position.z,-8.0,2.5)-2.59)


func update_camera(delta: float) -> void:
	eye = eye.lerp(camera_target(),1.0-exp(-delta*5.0))
	camera.position = eye + CAMERA_OFFSET
	camera.look_at(eye)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		walker.position = START
		follower.position = START+FOLLOW_OFFSET
		walker.rotation.y = -.44
		follower.rotation.y = -.44
		walk_weight = 0
		hop_cycle = 0
		eye = camera_target()
		update_camera(0.0)


func light_street() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("bdd7d3")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d1e2ef")
	env.ambient_light_energy = .65
	env.fog_enabled = true
	env.fog_light_color = Color("c7dfd6")
	env.fog_density = .0040
	env.ssao_enabled = true
	env.ssao_radius = 1.3
	env.ssao_intensity = 1.4
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-41,-48,0)
	sun.light_color = Color("fff0cc")
	sun.light_energy = 1.06
	sun.shadow_enabled = true
	sun.shadow_blur = 2.1
	sun.shadow_normal_bias = .75
	sun.directional_shadow_max_distance = 42.0
	add_child(sun)


func paint(base: String, variation: String, pattern := 0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = Surfaces
	material.set_shader_parameter("pigment",Color(base))
	material.set_shader_parameter("secondary",Color(variation))
	material.set_shader_parameter("pattern",pattern)
	return material


func solid(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)


func ramp(from: Vector3, to: Vector3, width: float) -> void:
	var side := (to-from).cross(Vector3.UP).normalized()*width*.5
	var points := PackedVector3Array()
	for edge: Vector3 in [from-side,from+side,to-side,to+side]:
		points.append(edge)
		points.append(Vector3(edge.x,-.18,edge.z))
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)


func ground_actor(at: Vector3, radius: float, height: float) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.position = at
	body.rotation.y = -.44
	body.collision_layer = 2
	body.floor_snap_length = .19
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collider.position.y = height*.5
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	return body


func build_cast() -> void:
	walker = ground_actor(START,.24,1.39)
	hero = Hero.instantiate()
	hero.scale = Vector3.ONE*.65
	walker.add_child(hero)
	follower = ground_actor(START+FOLLOW_OFFSET,.19,.41)
	frog = Frog.instantiate()
	frog.scale = Vector3.ONE*.42
	follower.add_child(frog)


func build_street() -> void:
	var grass := paint("628951","9db264",5)
	var asphalt := paint("808689","9da39a")
	var pavement := paint("b9aa82","e2d2a0",2)
	var curb := paint("b3b2a2","dfd7bb")
	var gravel := paint("aaa795","d7cfb2",2)
	M.box(self,"Garden ground",Vector3(0,-.19,-12),Vector3(120,.30,100),grass)
	M.box(self,"Asphalt road",Vector3(0,-.006,10.4),Vector3(115,.025,15.0),asphalt)
	M.box(self,"Stone sidewalk",Vector3(0,.061,1.9),Vector3(34,.123,2.45),pavement)
	M.box(self,"Curb lip",Vector3(0,.05,3.13),Vector3(34,.108,.12),curb)
	M.box(self,"Side lane",Vector3(-.16,.057,-6.86),Vector3(4.35,.11,15.3),gravel)
	M.box(self,"Cottage garden path",Vector3(5.10,.044,-1.77),Vector3(1.19,.085,5.9),pavement)
	solid(Vector3(0,-.57,-2),Vector3(32,1.12,29))
	solid(Vector3(0,.05,1.9),Vector3(31,.13,2.49))
	solid(Vector3(-.16,.049,-6.86),Vector3(4.35,.12,15.3))
	ramp(Vector3(0,.114,3.12),Vector3(0,0,3.43),31)
	ramp(Vector3(0,.114,.67),Vector3(0,-.01,.36),31)
	ramp(Vector3(2.01,.108,-6.86),Vector3(2.28,-.01,-6.86),15.3)
	ramp(Vector3(-2.33,.108,-6.86),Vector3(-2.60,-.01,-6.86),15.3)
	# Block the edge of the small walkable study beyond the visible set.
	solid(Vector3(-15.8,.7,-2),Vector3(.25,1.5,28))
	solid(Vector3(15.8,.7,-2),Vector3(.25,1.5,28))
	solid(Vector3(0,.7,-15.4),Vector3(32,1.5,.25))
	solid(Vector3(0,.7,9.4),Vector3(32,1.5,.25))

	var brick := paint("a45f4d","d48b70",1)
	var ivory := paint("c4c7b6","e6ddc1")
	var boards := paint("98b2ad","d5dfc4",4)
	var steel := paint("3d5050","556961")
	var metal_roof := paint("777658","a39c69")
	var blue_roof := paint("52686f","83938e",3)
	build_house(Vector3(-5.35,0,-2.55),Vector2(5.91,5.65),4.05,brick,metal_roof,ivory,true)
	build_house(Vector3(5.63,0,-4.78),Vector2(5.36,4.39),3.52,boards,blue_roof,ivory,false)
	build_house(Vector3(-5.73,0,-10.28),Vector2(5.32,4.54),3.6,boards,blue_roof,ivory,false)
	build_house(Vector3(4.88,0,-11.36),Vector2(5.40,3.83),3.56,paint("ac9a7e","e5d3a9",4),metal_roof,ivory,false)

	var fence_material := paint("aab7a9","e1e0c6")
	fence(Vector3(2.12,0,.53),Vector3(2.12,0,-9.43),fence_material)
	fence(Vector3(2.12,0,.53),Vector3(4.42,0,.53),fence_material)
	fence(Vector3(5.74,0,.53),Vector3(9.62,0,.53),fence_material)
	fence(Vector3(9.62,0,.53),Vector3(9.62,0,-8.39),fence_material)
	var stone := paint("a7a68d","cfcbab",3)
	M.box(self,"Garden pillar",Vector3(-2.09,.66,.36),Vector3(.46,1.32,.47),stone)
	M.box(self,"Pillar cap",Vector3(-2.09,1.36,.36),Vector3(.57,.11,.58),ivory)
	solid(Vector3(-2.09,.66,.36),Vector3(.48,1.34,.49))
	streetlamp(Vector3(-2.48,.115,1.56),steel)
	streetlamp(Vector3(3.65,.1,2.81),steel)
	streetlamp(Vector3(2.12,.08,-6.19),steel)

	var sign := Waymarker.instantiate() as Node3D
	sign.position = Vector3(6.7,.04,.83)
	sign.rotation.y = .14
	add_child(sign)
	plants()
	add_street_details(steel)


func build_house(at: Vector3, extent: Vector2, height: float, wall: Material, roof: Material, trim: Material, is_brick: bool) -> void:
	var width := extent.x
	var depth := extent.y
	var front := at.z+depth*.5
	M.box(self,"Foundation",at+Vector3(0,.16,0),Vector3(width+.12,.32,depth+.1),paint("847e6d","b5ad8b",3))
	M.box(self,"House walls",at+Vector3(0,height*.5,0),Vector3(width,height,depth),wall)
	solid(at+Vector3(0,height*.5,0),Vector3(width,height,depth))
	var gable := PrismMesh.new()
	var rise := 1.17
	gable.size = Vector3(width,rise,depth)
	M.piece(self,"Gable walls",gable,wall,at+Vector3(0,height+rise*.5,0))
	for side: float in [-1.0,1.0]:
		var roof_panel := M.box(self,"Roof slope",at+Vector3(side*width*.25,height+rise*.5+.08,0),Vector3(Vector2(width*.5,rise).length()+.4,.16,depth+.46),roof)
		roof_panel.rotation.z = -side*atan2(rise,width*.5)
		if is_brick:
			for seam in 11:
				var line := M.box(self,"Standing roof seam",Vector3(0,.093,lerpf(-depth*.49,depth*.49,seam/10.0)),Vector3(roof_panel.mesh.size.x,.038,.038),trim)
				line.reparent(roof_panel,false)
		for axis: float in [-1.0,1.0]:
			M.box(self,"Corner trim",at+Vector3(side*(width*.5-.07),height*.5,axis*(depth*.5-.04)),Vector3(.16,height,.16),trim)
	M.box(self,"Lintel",Vector3(at.x,height-.13,front+.075),Vector3(width+.13,.19,.15),trim)
	M.box(self,"Fascia trim",Vector3(at.x,height-.227,front+.11),Vector3(width+.19,.061,.11),trim)
	for side: float in [-1.0,1.0]:
		var gutter_x := at.x + side*(width*.5+.11)
		M.box(self,"Roof gutter",Vector3(gutter_x,height+.027,at.z),Vector3(.10,.08,depth+.5),roof)
	roof_chimney(at+Vector3(width*.192,height+rise*.62,-depth*.21),wall,trim)
	var window_glass := paint("3c565e","93ada9",6)
	for side: float in [-1.0,1.0]:
		var window_x := at.x+side*width*.278
		window_at(Vector3(window_x,1.83,front+.062),0.0,Vector2(.88,1.17),trim,window_glass)
		if not is_brick:
			shutters(Vector3(window_x,1.84,front+.128),trim)
		if is_brick:
			window_at(Vector3(at.x+width*.5+.055,1.83,at.z+side*depth*.243),PI*.5,Vector2(.80,1.12),trim,window_glass)
	var door := paint("446969","718f83",4)
	M.box(self,"Door frame",Vector3(at.x,1.13,front+.034),Vector3(1.27,2.2,.16),trim)
	M.box(self,"Painted door",Vector3(at.x,1.13,front+.126),Vector3(1.06,2.03,.075),door)
	M.box(self,"Transom",Vector3(at.x,1.84,front+.177),Vector3(.72,.47,.04),window_glass)
	M.ball(self,"Brass latch",Vector3(at.x+.36,1.015,front+.192),Vector3.ONE*.041,M.paint("b9a065"))
	var stair := paint("a79b79","c9b892")
	for step in 3:
		M.box(self,"Entrance step",Vector3(at.x,.06+step*.077,front+.54-step*.155),Vector3(1.57,.115,.22),stair)
	if not is_brick:
		var canopy := M.box(self,"Porch roof",Vector3(at.x,2.49,front+.42),Vector3(1.99,.13,.96),roof)
		canopy.rotation.x = -.14
		for side: float in [-1.0,1.0]:
			var x := at.x+side*.864
			M.box(self,"Porch post",Vector3(x,1.27,front+.77),Vector3(.11,2.40,.11),trim)
			M.box(self,"Porch rail",Vector3(x,.84,front+.438),Vector3(.095,.076,.66),trim)
			M.box(self,"Lower porch rail",Vector3(x,.34,front+.438),Vector3(.073,.054,.66),trim)
			for spindle in 4:
				var z := front+.19+spindle*.136
				M.box(self,"Porch spindle",Vector3(x,.581,z),Vector3(.037,.482,.039),trim)
	else:
		var oak := paint("6b5d48","96744f",4)
		var iron := paint("5b6158","838879")
		var terra := paint("a47157","c18a62")
		M.box(self,"Brick doorway sign",Vector3(at.x,2.54,front+.104),Vector3(1.31,.26,.073),oak)
		M.box(self,"Enamel inset",Vector3(at.x,2.54,front+.146),Vector3(1.15,.17,.027),iron)
		var lettering := Label3D.new()
		lettering.text = "GARDEN POST"
		lettering.font_size = 48
		lettering.pixel_size = .00325
		lettering.outline_size = 0
		lettering.modulate = Color("eedab0")
		lettering.position = Vector3(at.x,2.54,front+.165)
		add_child(lettering)
		M.box(self,"Meter box",Vector3(at.x+width*.409,.66,front+.126),Vector3(.28,.36,.13),iron)
		M.box(self,"Meter flap",Vector3(at.x+width*.409,.73,front+.203),Vector3(.217,.131,.024),trim)
		M.box(self,"Doorstep flower box",Vector3(at.x-width*.275,1.11,front+.20),Vector3(.86,.172,.28),terra)
		crown(Vector3(at.x-width*.275,1.23,front+.21),Vector3(.44,.13,.15),paint("52834c","8da45b",5),16)
		var pipe := paint("574942","80685a")
		M.curve(self,"Drainpipe",PackedVector3Array([
			Vector3(at.x+width*.43,.37,front+.1),Vector3(at.x+width*.43,.61,front+.16),
			Vector3(at.x+width*.43,2.92,front+.16),Vector3(at.x+width*.39,3.09,front+.16),
			Vector3(at.x+width*.23,3.09,front+.16),
		]),.035,pipe,1.0)


func roof_chimney(at: Vector3, wall: Material, trim: Material) -> void:
	M.box(self,"Chimney",at+Vector3(0,.30,0),Vector3(.53,1.0,.45),wall)
	M.box(self,"Chimney coping",at+Vector3(0,.80,0),Vector3(.65,.09,.54),trim)
	var clay := paint("94644e","be9270")
	for x: float in [-.133,.133]:
		var pot := at+Vector3(x,.942,0)
		M.cylinder(self,"Terracotta flue",pot,.087,.107,.21,clay,14)
		M.cylinder(self,"Flue rim",pot+Vector3(0,.106,0),.105,.104,.044,clay,14)
		M.cylinder(self,"Flue opening",pot+Vector3(0,.131,0),.074,.074,.01,paint("4b3e39","5f5146"),14)


func shutters(at: Vector3, trim: Material) -> void:
	var wood := paint("5b7976","81988a",4)
	for side: float in [-1.0,1.0]:
		var x := at.x+side*.56
		M.box(self,"Painted shutter",Vector3(x,at.y,at.z),Vector3(.194,1.10,.048),wood)
		for y: float in [-.35,.34]:
			M.box(self,"Shutter hinge",Vector3(x,at.y+y,at.z+.031),Vector3(.146,.029,.017),trim)


func window_at(at: Vector3, angle: float, size: Vector2, trim: Material, glass: Material) -> void:
	var anchor := Node3D.new()
	anchor.position = at
	anchor.rotation.y = angle
	add_child(anchor)
	M.box(anchor,"Window casing",Vector3.ZERO,Vector3(size.x,size.y,.12),trim)
	M.box(anchor,"Sash recess",Vector3(0,0,.066),Vector3(size.x-.12,size.y-.143,.031),paint("657169","889084"))
	M.box(anchor,"Window panes",Vector3(0,0,.084),Vector3(size.x-.19,size.y-.20,.024),glass)
	M.box(anchor,"Window mullion",Vector3(0,0,.101),Vector3(.042,size.y-.12,.041),trim)
	M.box(anchor,"Window crossbar",Vector3(0,.02,.102),Vector3(size.x-.12,.046,.041),trim)
	M.box(anchor,"Stone sill",Vector3(0,-size.y*.5+.002,.121),Vector3(size.x+.075,.083,.19),trim)


func fence(from: Vector3, to: Vector3, material: Material) -> void:
	var count := floori(from.distance_to(to)/.24)
	var along := to-from
	var anchor := Node3D.new()
	anchor.position = (from+to)*.5
	anchor.rotation.y = atan2(-along.z,along.x)
	add_child(anchor)
	for y: float in [.27,.61]:
		M.box(anchor,"Fence rail",Vector3(0,y,0),Vector3(along.length(),.081,.067),material)
	for index in count+1:
		var x := lerpf(-along.length()*.5,along.length()*.5,index/float(count))
		var post := M.box(anchor,"Picket",Vector3(x,.403,.048),Vector3(.116,.806,.065),material)
		post.rotation.z = rng.randf_range(-.018,.018)
		var tip := M.ball(anchor,"Rounded picket top",Vector3(x,.805,.048),Vector3(.058,.063,.032),material)
		tip.rotation.z = post.rotation.z
		if index % 6 == 0:
			M.box(anchor,"Fence post cap",Vector3(x,.874,.014),Vector3(.16,.045,.153),material)
	var span := Vector3(maxf(.11,absf(along.x)),.88,maxf(.11,absf(along.z)))
	solid(anchor.position+Vector3(0,.44,0),span)


func streetlamp(at: Vector3, steel: Material) -> void:
	var glow := M.paint("e9e4ca")
	M.cylinder(self,"Lamppost footing",at+Vector3(0,.145,0),.11,.16,.29,steel,10)
	M.cylinder(self,"Lamppost stem",at+Vector3(0,1.25,0),.046,.079,2.41,steel,14)
	M.curve(self,"Gooseneck",PackedVector3Array([
		at+Vector3(0,2.36,0),at+Vector3(0,2.68,0),
		at+Vector3(.10,2.91,0),at+Vector3(.29,2.98,0),
		at+Vector3(.49,2.86,0),at+Vector3(.54,2.63,0),
	]),.046,steel,.83)
	M.cylinder(self,"Lamp cap",at+Vector3(.54,2.64,0),.077,.094,.10,steel,16)
	M.ball(self,"Opal globe",at+Vector3(.54,2.46,0),Vector3(.163,.172,.163),glow)


func plants() -> void:
	var bark := paint("66563f","918160")
	var leaf := paint("37634d","83a65d",5)
	var warm_leaf := paint("4c7a4c","a4b365",5)
	for position: Vector3 in [Vector3(3.2,0,-4.88),Vector3(7.9,0,-1.70),Vector3(2.92,0,-8.95),Vector3(-2.7,0,-8.85)]:
		var top := position+Vector3(.21,2.9,-.14)
		M.limb(self,"Tree trunk",position,top,.11,.12,bark)
		for branch in 3:
			var angle := TAU*branch/3.0
			var tip := top+Vector3(cos(angle)*.72,-.34,sin(angle)*.72)
			M.limb(self,"Tree branch",position.lerp(top,.52),tip,.047,.048,bark)
			crown(tip+Vector3(0,.49,0),Vector3(.93,.78,.87),leaf,26)
	for position: Vector3 in [Vector3(2.85,.22,-.21),Vector3(3.92,.22,-.32),Vector3(6.64,.29,-.48),Vector3(7.39,.26,-.53),Vector3(2.56,.33,-3.3),Vector3(2.63,.29,-6.43),Vector3(-2.45,.31,-7.0),Vector3(8.77,.24,-1.13)]:
		crown(position,Vector3(.53,.44,.55),warm_leaf,24)
	var flower := M.paint("edc36a")
	for i in 25:
		var center := Vector3(lerpf(6.04,8.65,rng.randf()),rng.randf_range(.13,.41),rng.randf_range(-.54,-.05))
		M.ball(self,"Gold garden blooms",center,Vector3(.055,.033,.05),flower)
	var blades := MultiMesh.new()
	blades.transform_format = MultiMesh.TRANSFORM_3D
	var blade := PrismMesh.new()
	blade.size = Vector3(.055,.19,.018)
	blades.mesh = blade
	blades.instance_count = 420
	for index in blades.instance_count:
		var x := rng.randf_range(2.25,9.5)
		var z := rng.randf_range(-7.1,.43)
		if index % 2 == 0:
			z = rng.randf_range(-.66,.43)
		if absf(x-5.10) < .66:
			x += 1.45
		var basis := Basis(Vector3.UP,rng.randf()*TAU).rotated(Vector3.FORWARD,rng.randf_range(-.24,.24))
		blades.set_instance_transform(index,Transform3D(basis,Vector3(x,.055,z)))
	var grass := MultiMeshInstance3D.new()
	grass.multimesh = blades
	grass.material_override = warm_leaf
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass)


func add_street_details(iron: Material) -> void:
	var bronze := paint("786a4b","aaa17a")
	var dark := paint("393e39","586050")
	for x: float in [-4.2,2.38,7.16]:
		var center := Vector3(x,.017,3.35)
		M.box(self,"Storm drain",center,Vector3(.54,.019,.31),dark)
		for bar in 8:
			M.box(self,"Drain grate bar",center+Vector3(-.22+bar*.063,.014,0),Vector3(.019,.014,.284),iron)
		for edge: float in [-.15,.15]:
			M.box(self,"Drain frame",center+Vector3(0,.015,edge),Vector3(.55,.019,.026),iron)
	var cover := Vector3(-.47,.12,-2.44)
	M.cylinder(self,"Service cover",cover,.265,.265,.024,iron,32)
	M.cylinder(self,"Stamped center",cover+Vector3(0,.018,0),.206,.206,.012,bronze,28)
	for stripe in 6:
		var cut := M.box(self,"Cover groove",cover+Vector3(0,.027,-.139+stripe*.054),Vector3(.27,.009,.013),dark)
		cut.rotation.y = -.11

	var terra := paint("9e654f","dba17b")
	var leaves := paint("4e7954","a6b570",5)
	var pale := M.paint("f2ddd3")
	var yellow := M.paint("f3c373")
	for at: Vector3 in [Vector3(4.37,.02,-1.73),Vector3(5.91,.02,-1.52),Vector3(8.99,.02,-.09)]:
		M.cylinder(self,"Garden pot",at+Vector3(0,.14,0),.193,.137,.28,terra,16)
		M.cylinder(self,"Pot lip",at+Vector3(0,.282,0),.207,.207,.051,terra,16)
		crown(at+Vector3(0,.36,0),Vector3(.20,.19,.20),leaves,15)
		for index in 9:
			var angle := TAU*index/9.0
			var petal := at+Vector3(cos(angle)*.18,.414+sin(angle*3.0)*.064,sin(angle)*.16)
			M.ball(self,"Potted blossom",petal,Vector3(.050,.035,.043),pale if index%3==0 else yellow)
	for z: float in [-.17,-1.31,-2.7,-4.25,-6.1,-7.94]:
		crown(Vector3(2.145,.37,z),Vector3(.11,.38,.41),leaves,21)


func crown(at: Vector3, size: Vector3, material: Material, count: int) -> void:
	M.ball(self,"Leaf mass",at,size*.76,material)
	var leaves := MultiMesh.new()
	leaves.transform_format = MultiMesh.TRANSFORM_3D
	var leaf := SphereMesh.new()
	leaf.radial_segments = 8
	leaf.rings = 4
	leaves.mesh = leaf
	leaves.instance_count = count*2
	for index in leaves.instance_count:
		var direction := Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)).normalized()
		var diameter := rng.randf_range(.26,.51)*size.length()
		var basis := Basis.from_euler(Vector3(rng.randf(),rng.randf()*TAU,rng.randf()))
		basis = basis.scaled(Vector3(diameter,diameter*.47,diameter*.74))
		leaves.set_instance_transform(index,Transform3D(basis,at+direction*size*rng.randf_range(.72,.91)))
	var foliage := MultiMeshInstance3D.new()
	foliage.multimesh = leaves
	foliage.material_override = material
	add_child(foliage)


func build_caption() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var caption := Label.new()
	caption.position = Vector2(43,RENDER_SIZE.y-60)
	caption.text = "GARDEN LANE    /    WASD or arrows to walk    ·    Shift to run    ·    R to reset"
	caption.add_theme_font_size_override("font_size",28)
	caption.add_theme_color_override("font_color",Color("fff1d2"))
	caption.add_theme_color_override("font_shadow_color",Color("32413d"))
	caption.add_theme_constant_override("shadow_offset_y",3)
	hud.add_child(caption)
