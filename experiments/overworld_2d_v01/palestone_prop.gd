@tool
extends Marker2D

const Dressing := preload("res://experiments/overworld_2d_v01/region_dressing.gd")
const CONTACTS := "res://experiments/overworld_2d_v01/art/ground_contacts.json"
static var previews: Dictionary

@export_enum("palestone_cottage","coastal_lantern","coastal_pine","lakeside_alder","balcony_cottage","bakery","produce_stall","bench","flowers") var kind := "palestone_cottage":
	set(value):
		kind = value
		queue_redraw()
@export_range(.5,12,.1) var height := 4.5:
	set(value):
		height = value
		queue_redraw()
@export_range(0,8,.05) var radius := 1.8:
	set(value):
		radius = value
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if not previews.has(kind):
		var file: String = Dressing.CATALOG[kind]
		var texture: Texture2D = load(file)
		var contacts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTACTS)).assets
		var data: Dictionary = contacts[file]
		var bounds: Array = data.solid_bounds
		var source := Rect2(bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1])
		var foot := Vector2(data.contact_pixel[0],data.contact_pixel[1])
		previews[kind] = [texture,source,foot]
	var art: Array = previews[kind]
	var source: Rect2 = art[1]
	var factor := height/source.size.y
	var foot: Vector2 = art[2]
	draw_texture_rect_region(art[0],Rect2((source.position-foot)*factor,source.size*factor),source)
	if radius>0:
		draw_arc(Vector2.ZERO,radius,0,TAU,24,Color("f5cf88"),.22,true)
