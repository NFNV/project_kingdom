@tool
extends Marker2D

const Map := preload("res://experiments/overworld_2d_v01/layout.gd")
const DECK := preload("res://experiments/overworld_2d_v01/art/region/riverbend_stone_deck.png")

func _ready() -> void:
	if Engine.is_editor_hint():
		set_notify_local_transform(true)
		snap_to_river()

func _notification(what: int) -> void:
	if what==NOTIFICATION_LOCAL_TRANSFORM_CHANGED and Engine.is_editor_hint():
		snap_to_river()

func snap_to_river() -> void:
	var site := Map.bridge_center(position.x)
	var snapped_position := Vector2(site.x,-site.y)
	if not position.is_equal_approx(snapped_position):
		position = snapped_position

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half_size := Vector2(Map.BRIDGE_HALF,Map.BRIDGE_HALF_LENGTH)
	draw_texture_rect(DECK,Rect2(-half_size,half_size*2),false)
	for side in [-1,1]:
		var x: float = Map.BRIDGE_RAIL_X*side
		draw_line(Vector2(x,-half_size.y),Vector2(x,half_size.y),Color("eee0be"),.65,true)
	var font := ThemeDB.fallback_font
	var at := Vector2(8,12)
	draw_string_outline(font,at,"Riverbend Bridge",HORIZONTAL_ALIGNMENT_LEFT,-1,10,3,Color("334934"))
	draw_string(font,at,"Riverbend Bridge",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff0ce"))
