extends RefCounted
# Eight-direction cutout rig. Every view shares timing, scale and ground anchor.
const ART := "res://experiments/overworld_2d_v01/art/rider/"
const ANCHOR := Vector2(128,225)
const HOP_DISTANCE := 6.0
# phase, elevation, body width/height, hind angle, foot lift, rider lag, pitch
const KEYS := [
	[0.00,0.0,1.0,1.0,0.0,0.0,0.0,0.0],
	[0.13,-3.0,1.055,.91,.16,0.0,1.5,.018],
	[0.25,7.0,.965,1.07,-.25,7.0,4.0,-.025],
	[0.43,30.0,1.0,1.015,.16,-7.0,1.0,-.018],
	[0.54,34.0,1.0,1.0,.34,-12.0,-2.0,0.0],
	[0.69,18.0,1.0,1.0,.18,-4.0,-3.0,.02],
	[0.79,0.0,1.025,.97,-.08,0.0,0.0,.025],
	[0.87,-3.0,1.065,.90,.11,0.0,3.5,.012],
	[1.00,0.0,1.0,1.0,0.0,0.0,0.0,0.0]
]
const DIRECTION_NAMES := ["N","NE","E","SE","S","SW","W","NW"]
var direction_index := 0
var mirror_view := false
static var hero_heads: Dictionary = {}
var textures: Dictionary = {}
var phase := 0.0
var clock := 0.0
var active := false
var landings := 0
var cycles := 0
var dust_left := 0.0
var speed := 0.0

func _init() -> void:
	if hero_heads.is_empty():
		var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART+"hero_reference.json"))
		for direction in reference.directions:
			var info: Dictionary = reference.directions[direction]
			var source := Image.load_from_file(ProjectSettings.globalize_path(info.source))
			var box: Array = info.crop
			var image := source.get_region(Rect2i(box[0],box[1],box[2],box[3]))
			image.generate_mipmaps()
			hero_heads[direction] = ImageTexture.create_from_image(image)
	for id in ["frog_body","hind_leg","hind_foot","fore_leg","frog_eye","saddle","cat_boot","cat_tail","cat_torso","cat_arm","backpack","cat_head","scarf","scarf_tail"]:
		textures[id] = load(ART+id+".svg")
	for view in ["n","ne","e","se","s"]:
		textures[view+"_hero_vest"] = load(ART+view+"_hero_vest.svg")
	for view in ["ne","e","se","s"]:
		for layer in ["body","face","head","torso","arm","boot","pack","fore"]:
			var id: String = view+"_"+layer
			textures[id] = load(ART+id+".svg")

func set_direction(direction: Vector2) -> void:
	if direction.length_squared()<.01:
		return
	var heading := atan2(direction.x,direction.y)
	var difference := wrapf(heading-direction_index*PI/4,-PI,PI)
	# Keep the current view across small boundary fluctuations.
	if absf(difference)<=PI/8+.07:
		return
	direction_index = posmod(roundi(heading/(PI/4)),8)

func direction_name() -> String:
	return DIRECTION_NAMES[direction_index]

func view_name() -> String:
	return ["n","ne","e","se","s","se","e","ne"][direction_index]

func reset() -> void:
	phase = 0
	active = false
	dust_left = 0
	speed = 0

func step(delta: float, travelled: float) -> void:
	clock += delta
	dust_left = maxf(0,dust_left-delta)
	speed = travelled/maxf(delta,.000001)
	var moving := travelled>.00001
	if moving and not active:
		active = true
		phase = 0
	if not active:
		return
	var previous := phase
	# Travel drives stride; after stopping, finish the current hop and settle.
	phase += travelled/HOP_DISTANCE if moving else delta/.62
	if previous<.79 and phase>=.79:
		landings += 1
		dust_left = .22
	if phase>=1:
		cycles += 1
		if moving:
			phase = fmod(phase,1.0)
		else:
			phase = 0
			active = false

func sample(at_phase: float) -> Dictionary:
	var p := clampf(at_phase,0,1)
	for i in range(1,KEYS.size()):
		if p<=KEYS[i][0]:
			var a: Array = KEYS[i-1]
			var b: Array = KEYS[i]
			var t := smoothstep(a[0],b[0],p)
			return {"elevation":lerpf(a[1],b[1],t),"width":lerpf(a[2],b[2],t),"height":lerpf(a[3],b[3],t),"hind":lerpf(a[4],b[4],t),"foot_lift":lerpf(a[5],b[5],t),"rider_lag":lerpf(a[6],b[6],t),"pitch":lerpf(a[7],b[7],t)}
	return {}

func pose() -> Dictionary:
	var result := sample(phase if active else 0)
	if not active:
		# Gentle breathing without moving the planted feet or changing the cat.
		result.height += sin(clock*2.2)*.005
	return result

func stage() -> String:
	if not active: return "Idle"
	if phase<.16: return "Crouch"
	if phase<.29: return "Push off"
	if phase<.60: return "Airborne"
	if phase<.79: return "Reach for landing"
	if phase<.91: return "Landing"
	return "Recover"

func part(canvas: Node2D, id: String, origin: Vector2, scale: float, pivot: Vector2, offset := Vector2.ZERO, angle := 0.0, stretch := Vector2.ONE, mirrored := false) -> void:
	var joint := Vector2(256-pivot.x,pivot.y) if mirrored else pivot
	var rotation := -angle if mirrored else angle
	var flip := -1.0 if mirrored else 1.0
	if mirror_view:
		joint.x = 256-joint.x
		offset.x = -offset.x
		rotation = -rotation
		flip = -flip
	var xaxis := Vector2(cos(rotation),sin(rotation))*scale*stretch.x*flip
	var yaxis := Vector2(-sin(rotation),cos(rotation))*scale*stretch.y
	canvas.draw_set_transform_matrix(Transform2D(xaxis,yaxis,origin+(joint-ANCHOR+offset)*scale))
	canvas.draw_texture_rect(textures[id],Rect2(-pivot,Vector2(256,256)),false)
	canvas.draw_set_transform(Vector2.ZERO)

func oval(canvas: Node2D, at: Vector2, size: Vector2, color: Color) -> void:
	canvas.draw_set_transform(at,0,size)
	canvas.draw_circle(Vector2.ZERO,1,color)
	canvas.draw_set_transform(Vector2.ZERO)

func draw(canvas: Node2D, at: Vector2, scale: float) -> void:
	mirror_view = direction_index>4
	if direction_index!=0:
		draw_directional(canvas,at,scale)
		return
	var p := pose()
	var lift: float = p.elevation
	var air := clampf(lift/34,0,1)
	oval(canvas,at+Vector2(0,3)*scale,Vector2(47-10*air,10-2*air)*scale,Color(.15,.25,.15,.27-.12*air))
	if dust_left>0:
		var spread := 1-dust_left/.22
		for side in [-1,1]:
			oval(canvas,at+Vector2(side*(32+spread*14),2-spread*5)*scale,Vector2(6+spread*4,2+spread*3)*scale,Color(.78,.73,.48,(1-spread)*.23))
	var body_offset := Vector2(0,-lift)
	var body_scale := Vector2(p.width,p.height)
	# Synchronized paired legs: a frog pushes with both hind legs together.
	for mirrored in [false,true]:
		part(canvas,"fore_leg",at,scale,Vector2(94,157),body_offset+Vector2(0,-air*6),p.hind*-.45,Vector2.ONE,mirrored)
		part(canvas,"frog_eye",at,scale,Vector2(99,143),body_offset,0,Vector2.ONE,mirrored)
		part(canvas,"hind_leg",at,scale,Vector2(90,185),body_offset,p.hind,Vector2.ONE,mirrored)
		var foot_offset := Vector2(0,-maxf(lift,0)+p.foot_lift)
		part(canvas,"hind_foot",at,scale,Vector2(83,214),foot_offset,p.hind*.6,Vector2.ONE,mirrored)
	part(canvas,"frog_body",at,scale,Vector2(128,185),body_offset,0,body_scale)
	part(canvas,"saddle",at,scale,Vector2(128,173),body_offset,p.pitch*.5)
	for mirrored in [false,true]:
		part(canvas,"cat_boot",at,scale,Vector2(109,148),body_offset,p.pitch,Vector2.ONE,mirrored)
	part(canvas,"cat_tail",at,scale,Vector2(113,168),body_offset+Vector2(0,p.rider_lag*.4),sin(clock*3.2)*.045+p.pitch*2)
	var rider := body_offset+Vector2(0,p.rider_lag)
	part(canvas,"cat_torso",at,scale,Vector2(128,154),rider,p.pitch)
	part(canvas,"n_hero_vest",at,scale,Vector2(128,154),rider,p.pitch)
	for mirrored in [false,true]:
		part(canvas,"cat_arm",at,scale,Vector2(109,115),rider,p.pitch*.7,Vector2.ONE,mirrored)
	part(canvas,"backpack",at,scale,Vector2(128,150),rider,p.pitch*.6)
	draw_hero_head(canvas,at,scale,rider+Vector2(0,p.rider_lag*.35),p.pitch*.5)
	part(canvas,"scarf_tail",at,scale,Vector2(115,115),rider,p.pitch+sin(clock*6.5)*.07+air*.13)
	part(canvas,"scarf",at,scale,Vector2(128,113),rider,p.pitch*.5)

func draw_directional(canvas: Node2D, at: Vector2, scale: float) -> void:
	var p := pose()
	var lift: float = p.elevation
	var air := clampf(lift/34,0,1)
	var view := view_name()
	var front := view=="s"
	var body_offset := Vector2(0,-lift)
	var rider := body_offset+Vector2(0,p.rider_lag)
	oval(canvas,at+Vector2(0,3)*scale,Vector2((47 if front else 53)-10*air,10-2*air)*scale,Color(.15,.25,.15,.27-.12*air))
	if dust_left>0:
		var spread := 1-dust_left/.22
		for side in [-1,1]:
			oval(canvas,at+Vector2(side*(32+spread*14),2-spread*5)*scale,Vector2(6+spread*4,2+spread*3)*scale,Color(.78,.73,.48,(1-spread)*.23))
	if front:
		draw_front_layers(canvas,at,scale,p,air,body_offset,rider)
		return
	# Far limbs appear behind the mount. Near limbs return after the torso.
	part(canvas,"hind_leg",at,scale,Vector2(90,185),body_offset+Vector2(7,-6),p.hind,Vector2(.92,.96),true)
	part(canvas,"hind_foot",at,scale,Vector2(83,214),Vector2(7,-maxf(lift,0)+p.foot_lift-6),p.hind*.6,Vector2(.92,.96),true)
	part(canvas,view+"_fore",at,scale,Vector2(168,216),fore_offset(p)+Vector2(-12,-6),p.hind*.22,Vector2(.94,p.height*.95))
	part(canvas,view+"_boot",at,scale,Vector2(130,150),body_offset+Vector2(15,-5),p.pitch,Vector2(.9,.97))
	part(canvas,view+"_body",at,scale,Vector2(128,185),body_offset,0,Vector2(p.width,p.height))
	part(canvas,"saddle",at,scale,Vector2(128,173),body_offset,p.pitch*.5,Vector2(.93,1))
	part(canvas,"cat_tail",at,scale,Vector2(113,168),body_offset+Vector2(-4,p.rider_lag*.4),sin(clock*3.2)*.045+p.pitch*2)
	if view in ["s","se","e"]:
		part(canvas,view+"_pack",at,scale,Vector2(104,139),rider,p.pitch*.5)
	part(canvas,view+"_torso",at,scale,Vector2(128,154),rider,p.pitch)
	part(canvas,view+"_hero_vest",at,scale,Vector2(128,154),rider,p.pitch)
	part(canvas,view+"_arm",at,scale,Vector2(139,117),rider,p.pitch*.7)
	if view=="ne":
		part(canvas,view+"_pack",at,scale,Vector2(128,150),rider,p.pitch*.6)
	draw_hero_head(canvas,at,scale,rider+Vector2(0,p.rider_lag*.35),p.pitch*.5)
	part(canvas,"scarf_tail",at,scale,Vector2(115,115),rider,p.pitch+sin(clock*6.5)*.07+air*.13)
	part(canvas,"scarf",at,scale,Vector2(128,113),rider,p.pitch*.5)
	part(canvas,view+"_boot",at,scale,Vector2(130,150),body_offset,p.pitch)
	part(canvas,"hind_leg",at,scale,Vector2(90,185),body_offset,p.hind)
	part(canvas,"hind_foot",at,scale,Vector2(83,214),Vector2(0,-maxf(lift,0)+p.foot_lift),p.hind*.6)
	part(canvas,view+"_fore",at,scale,Vector2(168,216),fore_offset(p),p.hind*.22,Vector2(1,p.height))
	part(canvas,view+"_face",at,scale,Vector2(144,166),body_offset)

func fore_offset(p: Dictionary) -> Vector2:
	# Plant the hands while crouching; tuck them toward the body during flight.
	return Vector2(0,-maxf(p.elevation,0)+p.foot_lift*.25)

func draw_front_layers(canvas: Node2D, at: Vector2, scale: float, p: Dictionary, air: float, body_offset: Vector2, rider: Vector2) -> void:
	# Front view has exactly two hind and two forelimbs. The head covers the
	# shoulder roots, keeping bent elbows readable without dangling strips.
	for side in [false,true]:
		part(canvas,"hind_leg",at,scale,Vector2(90,185),body_offset,p.hind,Vector2.ONE,side)
		part(canvas,"hind_foot",at,scale,Vector2(83,214),Vector2(0,-maxf(p.elevation,0)+p.foot_lift),p.hind*.6,Vector2.ONE,side)
	part(canvas,"s_body",at,scale,Vector2(128,185),body_offset,0,Vector2(p.width,p.height))
	part(canvas,"saddle",at,scale,Vector2(128,173),body_offset,p.pitch*.5,Vector2(.93,1))
	part(canvas,"cat_tail",at,scale,Vector2(113,168),body_offset+Vector2(-4,p.rider_lag*.4),sin(clock*3.2)*.045+p.pitch*2)
	part(canvas,"s_torso",at,scale,Vector2(128,154),rider,p.pitch)
	part(canvas,"s_hero_vest",at,scale,Vector2(128,154),rider,p.pitch)
	for side in [false,true]:
		part(canvas,"cat_arm",at,scale,Vector2(109,115),rider,p.pitch*.7,Vector2.ONE,side)
		part(canvas,"cat_boot",at,scale,Vector2(109,148),body_offset,p.pitch,Vector2.ONE,side)
	draw_hero_head(canvas,at,scale,rider+Vector2(0,p.rider_lag*.35),p.pitch*.5)
	part(canvas,"scarf_tail",at,scale,Vector2(115,115),rider,p.pitch+sin(clock*6.5)*.07+air*.13)
	part(canvas,"scarf",at,scale,Vector2(128,113),rider,p.pitch*.5)
	for side in [false,true]:
		part(canvas,"s_fore",at,scale,Vector2(95,216),fore_offset(p),p.hind*.22,Vector2(1,p.height),side)
	part(canvas,"s_face",at,scale,Vector2(128,173),body_offset)

func draw_hero_head(canvas: Node2D, at: Vector2, scale: float, offset: Vector2, angle: float) -> void:
	# Actual protagonist art in each view, including the separately drawn west views.
	var texture: Texture2D = hero_heads[direction_name().to_lower()]
	var width := 70.0
	var height := width*texture.get_height()/texture.get_width()
	var shift: float = {"n":0.0,"ne":8.0,"e":10.0,"se":6.0,"s":0.0}[view_name()]
	if direction_index>4:
		shift = -shift
		angle = -angle
	var anchor := at+(Vector2(shift,110-ANCHOR.y)+offset)*scale
	canvas.draw_set_transform(anchor,angle,Vector2.ONE*scale)
	canvas.draw_texture_rect(texture,Rect2(-width*.5,-height,width,height),false)
	canvas.draw_set_transform(Vector2.ZERO)
