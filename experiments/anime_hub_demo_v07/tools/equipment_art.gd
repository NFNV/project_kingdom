extends RefCounted
const ROOT := "res://experiments/anime_hub_demo_v07/assets/"
static var textures: Dictionary = {}
static var generation: Dictionary = {}

static func icon(id: String, definitions: Dictionary = {}) -> Texture2D:
	var name: String = definitions.get(id,{}).get("icon",id)
	var path := ROOT+"equipment/"+name+".png"
	if not FileAccess.file_exists(path):
		path = ROOT+"items/"+id+".svg"
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return null
	if not textures.has(path):
		if path.ends_with(".png"):
			var source := Image.load_from_file(ProjectSettings.globalize_path(path))
			# Build a small mipmapped runtime texture; original art stays intact.
			var limit := 1152.0 if id=="adventurer" else 256.0
			var ratio := minf(1,limit/maxf(source.get_width(),source.get_height()))
			source.resize(maxi(1,int(source.get_width()*ratio)),maxi(1,int(source.get_height()*ratio)),Image.INTERPOLATE_LANCZOS)
			source.generate_mipmaps()
			textures[path] = ImageTexture.create_from_image(source)
		else:
			textures[path] = load(path)
	return textures[path]

static func ghost(slot: String) -> Texture2D:
	var path := ROOT+"equipment/slot_"+slot+".svg"
	if not textures.has(path):
		textures[path] = load(path)
	return textures[path]

static func prop(id: String) -> Texture2D:
	if generation.is_empty():
		generation = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"equipment/generation.json"))
	var key := "prop:"+id
	if not textures.has(key):
		var source := Image.load_from_file(ProjectSettings.globalize_path(ROOT+"equipment/"+id+".png"))
		var bounds: Array = generation.assets[id].opaque_bounds
		source = source.get_region(Rect2i(bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1]))
		var ratio := 512.0/maxf(source.get_width(),source.get_height())
		source.resize(maxi(1,int(source.get_width()*ratio)),maxi(1,int(source.get_height()*ratio)),Image.INTERPOLATE_LANCZOS)
		source.generate_mipmaps()
		textures[key] = ImageTexture.create_from_image(source)
	return textures[key]
