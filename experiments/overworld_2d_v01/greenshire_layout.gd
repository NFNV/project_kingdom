@tool
extends "res://experiments/overworld_2d_v01/palestone_layout.gd"

var woodland: Array[Dictionary] = []

func bake() -> void:
	clear_layout()
	woodland.clear()
	collect_layout(self)
	collect_layout($Palestone)
	collect_layout($MoonlightApproach)
	collect_props($Woodland,woodland)
	collect_props($LandmarkArt,props)
	bake_surfaces(Map.BOUNDS,2)

func bridge_site() -> Vector2:
	var marker := $Crossings/RiverbendBridge as Marker2D
	return Map.bridge_center(to_local(marker.global_position).x)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var bounds := Map.BOUNDS
	var frame := Rect2(bounds.position.x,-bounds.end.y,bounds.size.x,bounds.size.y)
	draw_rect(frame,Color("526d4e"))
	var forest := PackedVector2Array()
	for i in 60:
		var angle := float(i)/60.0*TAU
		var edge := Vector2(cos(angle)*128,sin(angle)*103)*(1.0+.07*sin(angle*7.0))
		forest.append(world_point(Vector2(-50,240)+edge))
	draw_colored_polygon(forest,Color("466249"))
	var sea := PackedVector2Array([world_point(Vector2(bounds.end.x,110)),world_point(bounds.end)])
	for z in range(roundi(bounds.end.y),109,-3):
		sea.append(world_point(Vector2(Map.coast_x(z),z)))
	draw_colored_polygon(sea,Color("407886"))
	var river := PackedVector2Array()
	for x in range(roundi(bounds.position.x),roundi(bounds.end.x)+1,2):
		river.append(world_point(Vector2(x,Map.river_z(x))))
	draw_polyline(river,Color("9b9f70"),Map.RIVER_HALF*2.0+2.4,true)
	draw_polyline(river,Color("5795a0"),Map.RIVER_HALF*2.0,true)
	draw_set_transform(world_point(Map.LAKE),0,Map.LAKE_SIZE)
	draw_circle(Vector2.ZERO,1.045,Color("9b9f70"),true,-1,true)
	draw_circle(Vector2.ZERO,1,Color("5795a0"),true,-1,true)
	draw_set_transform(Vector2.ZERO)
	draw_rect(frame,Color("869778"),false,.75)
	var font := ThemeDB.fallback_font
	draw_string(font,frame.position+Vector2(12,25),"THE GREENSHIRE",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("fff2ce"))
	draw_string(font,frame.position+Vector2(13,39),"OVERWORLD LAYOUT",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("d8dfbc"))
	draw_string(font,frame.position+Vector2(frame.size.x-33,25),"N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff2ce"))
	for marker in Map.landmarks():
		if marker.short=="Bridge":
			continue
		var at := world_point(marker.get("location",marker.p))
		draw_label(at,marker.short)
	draw_label(world_point(Map.LIGHTHOUSE),"Lighthouse")
	draw_label(world_point(Map.WATERMILL),"Watermill")

func draw_label(at: Vector2, label: String) -> void:
	var font := ThemeDB.fallback_font
	var baseline := at+Vector2(5,9)
	draw_circle(at,1.4,Color("fbdda6"),true,-1,true)
	draw_string_outline(font,baseline,label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,3,Color("334934"))
	draw_string(font,baseline,label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff0ce"))
