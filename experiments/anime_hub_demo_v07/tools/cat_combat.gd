extends Polygon2D

const ROOT := "res://experiments/anime_hub_demo_v07/assets/combat/"
const Timing := preload("res://experiments/anime_hub_demo_v07/tools/combat_timing.gd")
const HeroLook := preload("res://experiments/anime_hub_demo_v07/tools/hero_look.gd")
const DogArt := preload("res://experiments/anime_hub_demo_v07/tools/dog_art.gd")
const Art := preload("res://experiments/anime_hub_demo_v07/tools/art_style.gd")
static var cached_shapes: Dictionary = {}
static var cached_parts: Dictionary = {}
var catalogs: Dictionary = {}
var sheets: Dictionary = {}
var poses: Dictionary
var current_pose := -1
var current_direction := ""
var current_key := ""
var current_phase := ""
var references: Dictionary = {}
var layers: Array[Polygon2D] = []
var active_parts: Array = []
var active_data: Dictionary = {}
var display_head_width := 31.5
var display_head_height := 57.0
var appearance: Dictionary = {}
var dog_body: Sprite2D
var dog_grip := Vector2.ZERO
var dog_blade_angle := 0.0
var dog_weapon_in_front := true
var hero_height := 73.0

static func bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0],Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect

func _ready() -> void:
	material = Art.character_material()
	layers.append(self)
	for kind in ["attack","transition"]:
		var file := "catalog.json" if kind=="attack" else "transitions_catalog.json"
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+file))
		catalogs[kind] = catalog.directions
		sheets[kind] = load(ROOT+catalog.asset)
		if not cached_shapes.has(kind):
			var image := Image.load_from_file(ProjectSettings.globalize_path(ROOT+catalog.asset))
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(image,.86)
			var shapes := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),1.0)
			var registered: Dictionary = {}
			for direction in catalog.directions:
				var frames: Array[PackedVector2Array] = []
				for entry in catalog.directions[direction]:
					var center := Vector2(entry.region[0]+entry.region[2]*.5,entry.region[1]+entry.region[3]*.5)
					var closest := INF
					var selected := PackedVector2Array()
					for shape in shapes:
						if shape.size()<4:
							continue
						var rect := bounds(shape)
						if rect.size.x<70 or rect.size.y<100:
							continue
						var distance := rect.get_center().distance_squared_to(center)
						if distance<closest:
							closest = distance
							selected = shape
					frames.append(selected)
				registered[direction] = frames
			cached_shapes[kind] = registered
	poses = catalogs.attack

func set_appearance(look: Dictionary) -> void:
	if appearance == look:
		return
	appearance = look.duplicate()
	current_key = ""
	if look.species=="dog":
		polygon = PackedVector2Array()
		for layer in layers:
			if layer!=self:
				layer.hide()
		if dog_body==null:
			dog_body = Sprite2D.new()
			dog_body.centered = false
			add_child(dog_body)
		dog_body.material = HeroLook.palette(look)
		dog_body.show()
	else:
		if dog_body!=null:
			dog_body.hide()
		material = HeroLook.palette(look) if HeroLook.uses_palette(look) else Art.character_material()

func configure_reference(metadata: Dictionary, height: float) -> void:
	hero_height = height
	for direction in ["se","sw","ne","nw"]:
		var entry: Dictionary = metadata[direction]
		var idle: Dictionary = entry.body_registration.idle
		references[direction] = {"width":float(idle.poses[0].head_width)*float(idle.poses[0].scale)*height/float(entry.height),"height":float(idle.head_ground_height)*height/float(entry.height)}

func _parts_for(kind: String, direction: String, index: int, data: Dictionary) -> Array:
	var reference_width: float = references.get(direction,{"width":31.5}).width
	var key := kind+"/"+direction+"/"+str(index)+"/"+str(reference_width)
	if cached_parts.has(key):
		return cached_parts[key]
	var source: PackedVector2Array = cached_shapes[kind][direction][index]
	var neck := float(data.head_bottom_y)+6.0
	var boot := float(data.foot_y)-10.0/(reference_width/float(data.head_width))
	var edges := [-10000.0,neck,boot,10000.0]
	var parts: Array = []
	for band in 3:
		var clipping := PackedVector2Array([Vector2(-10000,edges[band]),Vector2(10000,edges[band]),Vector2(10000,edges[band+1]),Vector2(-10000,edges[band+1])])
		for piece in Geometry2D.intersect_polygons(source,clipping):
			if piece.size()<3:
				continue
			var triangles := Geometry2D.triangulate_polygon(piece)
			if triangles.is_empty():
				continue
			var faces: Array[PackedInt32Array] = []
			for at in range(0,triangles.size(),3):
				faces.append(PackedInt32Array([triangles[at],triangles[at+1],triangles[at+2]]))
			parts.append({"uv":piece,"faces":faces})
	cached_parts[key] = parts
	return parts

func pose(facing: Vector2, progress: float, power: bool) -> void:
	var duration := Timing.WIND_DURATION if power else Timing.LIGHT_DURATION
	var elapsed := clampf(progress,0,1)*duration
	var selection := Timing.selection(elapsed,power)
	var direction := ("se" if facing.x>=0 else "sw") if facing.y>=0 else ("ne" if facing.x>=0 else "nw")
	var kind: String = selection[1]
	var index: int = selection[2]
	var key := kind+"/"+direction+"/"+str(index)
	current_phase = selection[3]
	if appearance.get("species")=="dog":
		pose_dog(direction,elapsed,power)
		return
	if current_key!=key:
		current_key = key
		current_pose = index
		current_direction = direction
		active_data = catalogs[kind][direction][index]
		active_parts = _parts_for(kind,direction,index,active_data)
		while layers.size()<active_parts.size():
			var layer := Polygon2D.new()
			layer.use_parent_material = true
			add_child(layer)
			layers.append(layer)
		for i in layers.size():
			layers[i].visible = i<active_parts.size()
			if i<active_parts.size():
				layers[i].texture = sheets[kind]
				layers[i].uv = active_parts[i].uv
				layers[i].polygons = active_parts[i].faces
	var reference: Dictionary = references.get(direction,{"width":31.5,"height":57.0})
	var factor := float(reference.width)/float(active_data.head_width)
	var recover_start := .49 if power else .40
	var recover_end := .58 if power else .48
	var crouch := 6.0*smoothstep(.02,.17 if not power else .24,elapsed)*(1.0-smoothstep(recover_start,recover_end,elapsed))
	display_head_width = reference.width
	display_head_height = float(reference.height)-crouch
	var source_height := (float(active_data.foot_y)-float(active_data.head_center_y))*factor
	var extension := display_head_height-source_height
	var neck_y := (float(active_data.head_bottom_y)+6.0-float(active_data.foot_y))*factor
	for i in active_parts.size():
		var points := PackedVector2Array()
		for point in active_parts[i].uv:
			var local_point: Vector2 = (point-Vector2(active_data.foot_x,active_data.foot_y))*factor
			# Three affine bands preserve the head and boot artwork. Only the torso/
			# leg span eases between upright drawing/sheathing and a planted crouch.
			var weight := clampf((-10.0-local_point.y)/maxf(1.0,-10.0-neck_y),0,1)
			local_point.y -= extension*weight
			points.append(local_point)
		layers[i].polygon = points
	if not appearance.is_empty() and HeroLook.uses_palette(appearance):
		var source_width: float = active_data.head_width
		var head_x: float = active_data.foot_x
		var head_top := float(active_data.region[1])-1
		var head_bottom := float(active_data.head_bottom_y)+5
		HeroLook.set_head_box(material,Rect2(head_x-source_width*.75,head_top,source_width*1.5,head_bottom-head_top),sheets[kind].get_size())
		material.set_shader_parameter("eye_points",HeroLook.eye_points(direction))
	scale = Vector2.ONE
	position = Vector2.ZERO

func pose_dog(direction: String, elapsed: float, power: bool) -> void:
	var release := Timing.WIND_RELEASE if power else Timing.LIGHT_CONTACT
	var follow := .39 if power else .32
	var index := 0 if elapsed<release else (1 if elapsed<follow else 2)
	var entry := DogArt.cel("combat",direction,index)
	var mirror := HeroLook.MIRRORED.has(direction)
	var factor := hero_height/float(entry.height)
	dog_body.texture = entry.texture
	dog_body.flip_h = mirror
	dog_body.offset = DogArt.offset(entry,mirror)
	dog_body.scale = Vector2.ONE*factor
	DogArt.color_pose(dog_body.material,entry)
	dog_grip = DogArt.point(entry,"weapon",mirror)*factor
	var angle: float = [-.64,1.16,2.04][index]
	dog_blade_angle = -angle if mirror else angle
	dog_weapon_in_front = direction in ["se","sw"] or index==1
	current_pose = index
	current_direction = direction
