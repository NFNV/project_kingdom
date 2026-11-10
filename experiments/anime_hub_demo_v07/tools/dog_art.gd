extends RefCounted
## Full-figure painted cels with ground, eye, grip and saddle registration.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/avatar/"
const Look := preload("res://experiments/anime_hub_demo_v07/tools/hero_look.gd")
const DIRECTIONS := ["e","se","s","sw","w","nw","n","ne"]
const SHEETS := {"motion":"spaniel_motion.png","run":"spaniel_sprint.png","combat":"spaniel_combat.png","mounted":"spaniel_mounted.png"}
const WALK_STRIDE := [0,1,1,0,0,2,2,0]
const RUN_STRIDE := [0,0,1,1,2,2,3,3]

static var catalog: Dictionary = {}
static var sheets: Dictionary = {}
static var masks: Dictionary = {}
static var frames: SpriteFrames

static func cel(kind: String, direction: String, index := 0) -> Dictionary:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"spaniel_registration.json"))
	if not sheets.has(kind):
		sheets[kind] = load(ROOT+SHEETS[kind])
		masks[kind] = load(ROOT+str(SHEETS[kind]).get_basename()+"_palette.png")
	var canonical: String = Look.MIRRORED.get(direction,direction)
	var entry: Dictionary = catalog[kind][canonical][index]
	if not entry.has("texture"):
		var rect: Array = entry.region
		var atlas := AtlasTexture.new()
		atlas.atlas = sheets[kind]
		atlas.region = Rect2(rect[0],rect[1],rect[2],rect[3])
		atlas.filter_clip = true
		entry.texture = atlas
		entry.palette_mask = masks[kind]
	return entry

static func motion_frames() -> SpriteFrames:
	if frames==null:
		frames = SpriteFrames.new()
		frames.remove_animation("default")
		for direction in DIRECTIONS:
			for gait in ["idle","walk","run"]:
				var key := StringName(gait+"_"+direction)
				frames.add_animation(key)
				for index in (1 if gait=="idle" else 8):
					frames.add_frame(key,motion_cel(gait,direction,index).texture)
	return frames

static func motion_cel(state: String, direction: String, index: int) -> Dictionary:
	if state=="run":
		return cel("run",direction,RUN_STRIDE[index])
	return cel("motion",direction,0 if state=="idle" else WALK_STRIDE[index])

static func vector(point: Array) -> Vector2:
	return Vector2(point[0],point[1])

static func offset(entry: Dictionary, mirrored: bool) -> Vector2:
	var anchor := vector(entry.anchor)
	return Vector2(anchor.x-float(entry.region[2]) if mirrored else -anchor.x,-anchor.y)

static func point(entry: Dictionary, key: String, mirrored: bool) -> Vector2:
	var local := vector(entry[key])-vector(entry.anchor)
	return Vector2(-local.x,local.y) if mirrored else local

static func head_box(entry: Dictionary) -> Rect2:
	var box: Array = entry.head
	return Rect2(box[0],box[1],box[2],box[3])

static func eyes(entry: Dictionary) -> Vector4:
	var points: Array = entry.eyes
	return Vector4(points[0],points[1],points[2],points[3])

static func color_pose(material: ShaderMaterial, entry: Dictionary) -> void:
	var atlas: AtlasTexture = entry.texture
	var box := head_box(entry)
	box.position += atlas.region.position
	Look.set_head_box(material,box,atlas.atlas.get_size())
	material.set_shader_parameter("eye_points",eyes(entry))
	material.set_shader_parameter("dog_material_mask",entry.palette_mask)
