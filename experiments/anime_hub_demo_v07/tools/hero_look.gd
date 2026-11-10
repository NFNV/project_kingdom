extends RefCounted

const DEFAULT := {"name":"Mosswood wanderer","species":"cat","coat":0,"markings":0,"eyes":0,"scarf":0}
const SPECIES := ["Cat", "Dog"]
const COATS := ["Golden", "Silver", "Chestnut", "Cream"]
const MARKINGS := ["Natural", "Soft", "Blaze"]
const EYES := ["Amber", "Jade", "Sky blue"]
const SCARVES := ["Crimson", "Forest", "Indigo", "Ochre"]
const COAT_COLORS := [Color.WHITE, Color("9aa9b5"), Color("a96f54"), Color("f7deb1")]
const EYE_COLORS := [Color.WHITE, Color("75db9b"), Color("85c8fa")]
const SCARF_COLORS := [Color.WHITE, Color("4fa987"), Color("6075c1"), Color("d9a44e")]
const MIRRORED := {"sw":"se", "w":"e", "nw":"ne"}
const CAT_EYE_POINTS := {
	"s":Vector4(.36,.75,.64,.75), "se":Vector4(.53,.73,.73,.72), "sw":Vector4(.47,.73,.27,.72),
	"e":Vector4(.72,.72,-1,-1), "w":Vector4(.28,.72,-1,-1)
}
const Palette := preload("res://experiments/anime_hub_demo_v07/assets/avatar/avatar_palette.gdshader")

static func valid(look: Variant) -> bool:
	if not look is Dictionary or not look.get("name") is String:
		return false
	var hero_name: String = look.name
	if hero_name.is_empty() or hero_name.length()>24 or hero_name != hero_name.strip_edges() or hero_name.contains("\n") or hero_name.contains("\r"):
		return false
	if look.get("species") not in ["cat","dog"]:
		return false
	for pair in [["coat",COATS],["markings",MARKINGS],["eyes",EYES],["scarf",SCARVES]]:
		var index: Variant = look.get(pair[0])
		if not (index is int or index is float) or int(index)!=index or index<0 or index>=pair[1].size():
			return false
	return true

static func uses_palette(look: Dictionary) -> bool:
	return look.species=="dog" or look.coat!=0 or look.markings!=0 or look.eyes!=0 or look.scarf!=0

static func normalized(look: Dictionary) -> Dictionary:
	if look.species=="dog":
		var original := DEFAULT.duplicate()
		original.name = look.name
		original.species = "dog"
		return original
	return {"name":look.name,"species":look.species,"coat":int(look.coat),"markings":int(look.markings),"eyes":int(look.eyes),"scarf":int(look.scarf)}

static func palette(look: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = Palette
	material.set_shader_parameter("coat", rgb(COAT_COLORS[int(look.coat)]))
	material.set_shader_parameter("eyes", rgb(EYE_COLORS[int(look.eyes)]))
	material.set_shader_parameter("scarf", rgb(SCARF_COLORS[int(look.scarf)]))
	material.set_shader_parameter("markings", int(look.markings))
	material.set_shader_parameter("dog_fur", look.species=="dog")
	return material

static func rgb(color: Color) -> Vector3:
	return Vector3(color.r,color.g,color.b)

static func set_head_box(material: ShaderMaterial, box: Rect2, texture_size: Vector2) -> void:
	var uv := Rect2(box.position/texture_size,box.size/texture_size)
	material.set_shader_parameter("head_box",Vector4(uv.position.x,uv.position.y,uv.size.x,uv.size.y))

static func eye_points(direction: String) -> Vector4:
	return CAT_EYE_POINTS.get(direction,Vector4(-1,-1,-1,-1))
