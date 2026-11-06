extends RefCounted
# Eight-direction cutout rig. Every view shares timing, scale and ground anchor.
const ART := "res://experiments/overworld_2d_v01/art/rider/"
const HeroLook := preload("res://experiments/anime_hub_demo_v07/tools/hero_look.gd")
const DogArt := preload("res://experiments/anime_hub_demo_v07/tools/dog_art.gd")
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
# Joints projected on the visible flank, with the far-side pair tucked behind it.
# Each entry stores the near hip, near shoulder, far hip and optional far shoulder.
const PROFILE_JOINTS := {
	"ne": [Vector2(93,185), Vector2(167,174), Vector2(130,191)],
	"e": [Vector2(90,185), Vector2(174,180), Vector2(110,169), Vector2(186,171)],
	"se": [Vector2(87,186), Vector2(156,186), Vector2(111,174), Vector2(181,177)],
}
var light_tint := Color.WHITE
var direction_index := 0
var mirror_view := false
static var hero_heads: Dictionary = {}
static var mounted_dog_image: Image
static var mounted_dog_mask: Image
var textures: Dictionary = {}
var appearance := HeroLook.DEFAULT.duplicate()
var painted_heads: Dictionary = {}
var painted_dogs: Dictionary = {}
var painted_parts: Dictionary = {}
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
	for id in ["frog_body","hind_leg","hind_foot","profile_hind_foot","profile_fore","fore_leg","frog_eye","saddle","cat_boot","cat_tail","cat_torso","cat_arm","backpack","cat_head","scarf","scarf_tail"]:
		textures[id] = load(ART+id+".svg")
	for view in ["n","ne","e","se","s"]:
		textures[view+"_hero_vest"] = load(ART+view+"_hero_vest.svg")
	for view in ["ne","e","se","s"]:
		for layer in ["body","face","head","torso","arm","boot","pack"]:
			if view == "ne" and layer == "face":
				continue
			var id: String = view+"_"+layer
			textures[id] = load(ART+id+".svg")
	textures.s_fore = load(ART+"s_fore.svg")

func set_appearance(look: Dictionary) -> void:
	if appearance == look:
		return
	appearance = look.duplicate()
	painted_heads.clear()
	painted_dogs.clear()
	painted_parts.clear()

func painted(texture: Texture2D, direction := "", is_scarf := false, dog_pose: Dictionary = {}) -> Texture2D:
	# The rider is drawn into the overworld's shared, depth-sorted canvas. Cache
	# these small cutouts per look so other scenery can retain its own material.
	var palette_color: Color = HeroLook.SCARF_COLORS[int(appearance.scarf)] if is_scarf else HeroLook.COAT_COLORS[int(appearance.coat)]
	var eye_color: Color = HeroLook.EYE_COLORS[int(appearance.eyes)]
	var is_head := not direction.is_empty()
	var dog := not dog_pose.is_empty()
	var marks := int(appearance.markings) if is_head else 0
	var eyes := DogArt.eyes(dog_pose) if dog else HeroLook.eye_points(direction)
	var scarf_color: Color = HeroLook.SCARF_COLORS[int(appearance.scarf)]
	if palette_color==Color.WHITE and marks==0 and (eyes.x<0 or eye_color==Color.WHITE) and (not dog or scarf_color==Color.WHITE):
		return texture
	var image: Image
	var mask: Image
	var head := Rect2(0,0,1,1)
	if dog:
		var atlas := texture as AtlasTexture
		if mounted_dog_image==null:
			mounted_dog_image = atlas.atlas.get_image()
			mounted_dog_mask = dog_pose.palette_mask.get_image()
		image = mounted_dog_image.get_region(Rect2i(atlas.region))
		mask = mounted_dog_mask.get_region(Rect2i(atlas.region))
		var raw := DogArt.head_box(dog_pose)
		var original := Vector2(image.get_size())
		head = Rect2(raw.position/original,raw.size/original)
	else:
		image = texture.get_image()
	if is_head and image.get_width()>192:
		image.resize(192,roundi(image.get_height()*192.0/image.get_width()),Image.INTERPOLATE_LANCZOS)
		if dog:
			mask.resize(image.get_width(),image.get_height(),Image.INTERPOLATE_BILINEAR)
	image.convert(Image.FORMAT_RGBA8)
	var area := image.get_used_rect()
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var pixel := image.get_pixel(x,y)
			if pixel.a==0:
				continue
			var luma := pixel.get_luminance()
			var warm := smoothstep(.06,.22,pixel.r-pixel.g)*smoothstep(.09,.20,pixel.g-pixel.b)
			var fur := warm*smoothstep(.44,.70,pixel.r)
			var point := (Vector2(x,y)/Vector2(image.get_size())-head.position)/head.size
			var on_head := Rect2(0,0,1,1).has_point(point)
			var material_weights := Color.BLACK
			if dog:
				material_weights = mask.get_pixel(x,y)
				fur = material_weights.r
			var iris := 0.0
			if eyes.x>=0:
				var distance := ((point-Vector2(eyes.x,eyes.y))/Vector2(.044,.077)).length()
				distance = minf(distance,((point-Vector2(eyes.z,eyes.w))/Vector2(.044,.077)).length())
				iris = (1.0-smoothstep(.68,1.28,distance))*smoothstep(.075,.22,pixel.r-pixel.b)*smoothstep(.18,.4,pixel.r)
			var ink := pixel
			if is_scarf:
				ink = palette_color*(.30+1.45*luma)
			elif palette_color!=Color.WHITE:
				ink = ink.lerp(palette_color*(.37+.84*luma),fur*(1.0-iris))
			if marks==1 and on_head:
				ink = ink.lerp(ink+Color(.10,.07,.045,0),fur*(1.0-smoothstep(.40,.70,point.y)))
			elif marks==2 and on_head:
				var blaze := (1.0-smoothstep(.045,.105,absf(point.x-.5)))*smoothstep(.10,.28,point.y)*(1.0-smoothstep(.49,.70,point.y))
				ink = ink.lerp(Color(.95,.87,.72)*(.65+.38*luma),fur*blaze*.9)
			if eye_color!=Color.WHITE:
				ink = ink.lerp(eye_color*(.30+1.4*luma),iris)
			if dog and scarf_color!=Color.WHITE:
				ink = ink.lerp(scarf_color*(.30+1.45*luma),material_weights.g)
			ink.a = pixel.a
			image.set_pixel(x,y,ink)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

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
	var texture: Texture2D = textures[id]
	if id in ["scarf","scarf_tail","cat_tail"]:
		if not painted_parts.has(id):
			painted_parts[id] = painted(texture,"",id!="cat_tail")
		texture = painted_parts[id]
	canvas.draw_texture_rect(texture,Rect2(-pivot,Vector2(256,256)),false,light_tint)
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
	if appearance.species=="dog":
		draw_dog(canvas,at,scale,body_offset+Vector2(0,p.rider_lag),p.pitch)
	else:
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
	var joints: Array = PROFILE_JOINTS[view]
	draw_profile_hind(canvas,at,scale,p,joints[2],Vector2(.82,.88))
	var rear_diagonal := view == "ne"
	if rear_diagonal:
		draw_profile_fore(canvas,at,scale,p,joints[1],Vector2.ONE)
	else:
		draw_profile_fore(canvas,at,scale,p,joints[3],Vector2(.82,.88))
	if appearance.species=="cat":
		part(canvas,view+"_boot",at,scale,Vector2(130,150),body_offset+Vector2(15,-5),p.pitch,Vector2(.9,.97))
	part(canvas,view+"_body",at,scale,Vector2(128,185),body_offset,0,Vector2(p.width,p.height))
	part(canvas,"saddle",at,scale,Vector2(128,173),body_offset,p.pitch*.5,Vector2(.93,1))
	if appearance.species=="dog":
		draw_dog(canvas,at,scale,rider,p.pitch)
	else:
		part(canvas,"cat_tail",at,scale,Vector2(113,168),body_offset+Vector2(-4,p.rider_lag*.4),sin(clock*3.2)*.045+p.pitch*2)
		if view in ["se","e"]:
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
	draw_profile_hind(canvas,at,scale,p,joints[0],Vector2.ONE)
	if not rear_diagonal:
		draw_profile_fore(canvas,at,scale,p,joints[1],Vector2.ONE)
		part(canvas,view+"_face",at,scale,Vector2(144,166),body_offset)

func draw_profile_hind(canvas: Node2D, at: Vector2, scale: float, p: Dictionary, hip: Vector2, limb_scale: Vector2) -> void:
	var thigh_pivot := Vector2(90,185)
	var foot_pivot := Vector2(83,214)
	var hip_shift := hip - thigh_pivot + Vector2(0,-p.elevation)
	var bend: float = p.hind * .60
	part(canvas,"hind_leg",at,scale,thigh_pivot,hip_shift,bend,limb_scale)
	var ankle := hip + ((foot_pivot - thigh_pivot) * limb_scale).rotated(bend)
	# The ankle follows the thigh through the hop. Ground compression keeps the toes planted.
	ankle.y += -maxf(p.elevation,0.0) + float(p.foot_lift) * .35
	part(canvas,"profile_hind_foot",at,scale,foot_pivot,ankle-foot_pivot,bend*.6,limb_scale)

func draw_profile_fore(canvas: Node2D, at: Vector2, scale: float, p: Dictionary, shoulder: Vector2, limb_scale: Vector2) -> void:
	var fore_pivot := Vector2(165,181)
	var shoulder_shift := shoulder - fore_pivot + fore_offset(p)
	part(canvas,"profile_fore",at,scale,fore_pivot,shoulder_shift,p.hind*-.288,limb_scale*Vector2(1,p.height))

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
	if appearance.species=="dog":
		draw_dog(canvas,at,scale,rider,p.pitch)
	else:
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
	var direction := direction_name().to_lower()
	if not painted_heads.has(direction):
		painted_heads[direction] = painted(hero_heads[direction],direction)
	var texture: Texture2D = painted_heads[direction]
	var width := 70.0
	var height := width*texture.get_height()/texture.get_width()
	var shift: float = {"n":0.0,"ne":8.0,"e":10.0,"se":6.0,"s":0.0}[view_name()]
	if direction_index>4:
		shift = -shift
		angle = -angle
	var anchor := at+(Vector2(shift,110-ANCHOR.y)+offset)*scale
	canvas.draw_set_transform(anchor,angle,Vector2.ONE*scale)
	canvas.draw_texture_rect(texture,Rect2(-width*.5,-height,width,height),false,light_tint)
	canvas.draw_set_transform(Vector2.ZERO)

func draw_dog(canvas: Node2D, at: Vector2, scale: float, offset: Vector2, angle: float) -> void:
	var view := view_name()
	var entry := DogArt.cel("mounted",view)
	if not painted_dogs.has(view):
		painted_dogs[view] = painted(entry.texture,view,false,entry)
	var texture: Texture2D = painted_dogs[view]
	var draw_scale := 126.0/float(entry.height)
	var size := Vector2(entry.region[2],entry.region[3])*draw_scale
	var anchor := at+(Vector2(0,153-ANCHOR.y)+offset)*scale
	var turn := -1.0 if mirror_view else 1.0
	canvas.draw_set_transform_matrix(Transform2D(angle*turn,Vector2(turn*scale,scale),0,anchor))
	canvas.draw_texture_rect(texture,Rect2(-DogArt.vector(entry.anchor)*draw_scale,size),false,light_tint)
	canvas.draw_set_transform(Vector2.ZERO)
