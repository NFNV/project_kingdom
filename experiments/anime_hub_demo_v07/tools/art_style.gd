extends RefCounted

# One palette and one atlas for architecture, streets and cutaway interiors.
# Generated originals stay intact; Godot takes lossless texture regions at load.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/style/"
const FACADES := [Color("fff0cd"),Color("ecd7b8"),Color("dce3cd"),Color("f0d9bd"),Color("e4e7d7"),Color("fae7bd"),Color("e7dfc3"),Color("f1e1ce")]
const ROOFS := [Color("6a879f"),Color("b37758"),Color("6d8f85"),Color("8e8299"),Color("8d99a4"),Color("a89576"),Color("647e99"),Color("aa755d")]
const IVORY := Color("f8e7c5")
const TEAL := Color("557b76")
const OAK := Color("a58359")
const INK := Color("54666b")
const LIGHTING := [Color(1.0,.90,.83),Color.WHITE,Color(.89,.75,.73),Color(.47,.56,.77)]
const MATERIAL_CELLS := {"plaster":Vector2i(0,0),"slate":Vector2i(1,0),"paving":Vector2i(2,0),"oak":Vector2i(0,1),"street":Vector2i(1,1),"brick":Vector2i(2,1)}
const DETAIL_CELLS := {"casement":Vector2i(0,0),"arched_window":Vector2i(1,0),"teal_door":Vector2i(0,1),"oak_door":Vector2i(1,1)}
static var textures: Dictionary = {}
static var images: Dictionary = {}
static var character_grade: ShaderMaterial

static func texture_for(id: String) -> Texture2D:
	if textures.has(id):
		return textures[id]
	var detail := DETAIL_CELLS.has(id)
	var filename := "town_details_v1.png" if detail else "town_materials_v1.png"
	if id=="grass":
		filename = "park_grass_v1.png"
	if not images.has(filename):
		images[filename] = Image.load_from_file(ProjectSettings.globalize_path(ROOT+filename))
	var source: Image = images[filename]
	var region: Image
	if detail:
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json"))
		var rect: Array = catalog.detail_regions[id]
		region = source.get_region(Rect2i(rect[0],rect[1],rect[2],rect[3]))
		region = region.get_region(region.get_used_rect())
	elif id=="grass":
		region = source
	else:
		var cell: Vector2i = MATERIAL_CELLS[id]
		var size := source.get_size()/Vector2i(3,2)
		region = source.get_region(Rect2i(cell*size,size))
	region.generate_mipmaps()
	var texture := ImageTexture.create_from_image(region)
	textures[id] = texture
	return texture

static func character_material() -> ShaderMaterial:
	if character_grade==null:
		character_grade = ShaderMaterial.new()
		character_grade.shader = load(ROOT+"character_palette.gdshader")
	return character_grade
