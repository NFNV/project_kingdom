extends Control

const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
const PAPER := preload("res://experiments/anime_hub_demo_v07/assets/field_ui/atlas_paper.png")
const INK := Color("294538")
const ROAD := Color("a68251")
const PLAYER := Color("aa4c3d")
const SHEET := Rect2(330,121,1260,838)

var hub: Node2D
var detailed := false
var font := ThemeDB.fallback_font
var serif := UI.heading_font()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if detailed:
		size = Vector2(1920,1080)
		var close := UI.button(self,"Close map   ·   M / Esc",Vector2(1261,867),Vector2(248,42))
		close.pressed.connect(func(): hub.toggle_map())
	else:
		size = Vector2(244,170)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = "Open area map (M)"

func _gui_input(event: InputEvent) -> void:
	if not detailed and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		hub.toggle_map()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

static func draw_paper(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(Rect2(rect.position+Vector2(0,5),rect.size),Color(.05,.07,.05,.35))
	canvas.draw_texture_rect(PAPER,rect,false)

static func draw_position(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	var diamond := PackedVector2Array([Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT])
	for i in diamond.size():
		diamond[i] = at + diamond[i] * radius
	canvas.draw_colored_polygon(diamond,PLAYER)
	diamond.append(diamond[0])
	canvas.draw_polyline(diamond,Color("fff4d7"),1.8,true)

static func draw_quest_pin(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	canvas.draw_circle(at,radius,INK,true,-1,true)
	canvas.draw_circle(at,radius-1.4,Color("edbc58"),true,-1,true)
	canvas.draw_line(at-Vector2(0,radius*.51),at+Vector2(0,radius*.12),INK,1.5,true)
	canvas.draw_circle(at+Vector2(0,radius*.48),1,INK,true,-1,true)

func _draw() -> void:
	if not is_instance_valid(hub.player):
		return
	if detailed:
		draw_rect(Rect2(Vector2.ZERO,size),Color(.035,.07,.06,.87))
		draw_paper(self,SHEET)
		draw_string(font,Vector2(406,193),"FIELD ATLAS",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("846036"))
		draw_string(serif,Vector2(406,239),hub.zone_title(),HORIZONTAL_ALIGNMENT_LEFT,1020,42,INK)
		draw_string(font,Vector2(406,271),"You are here",HORIZONTAL_ALIGNMENT_LEFT,-1,19,INK)
		draw_position(self,Vector2(390,264),7)
		draw_string(font,Vector2(1250,316),"PASSAGES",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
		var y := 356.0
		var index := 1
		for exit in hub.exits.values():
			draw_string(font,Vector2(1250,y),"%d   %s" % [index,exit.get("sign",exit.label)],HORIZONTAL_ALIGNMENT_LEFT,290,19,INK)
			y += 38
			index += 1
		if not hub.lighthouse_quest_target().is_empty():
			draw_quest_pin(self,Vector2(1260,y+19),9)
			draw_string(font,Vector2(1277,y+25),"Tracked objective",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
		draw_line(Vector2(1223,298),Vector2(1223,764),Color("b99c63"),1,true)
		draw_area(Rect2(412,296,773,514))
	else:
		draw_paper(self,Rect2(Vector2.ZERO,size))
		draw_string(serif,Vector2(13,28),hub.zone_title(),HORIZONTAL_ALIGNMENT_CENTER,size.x-26,18,INK)
		draw_area(Rect2(18,38,size.x-36,101))
		draw_string(font,Vector2(15,156),"M   Area map",HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)

func draw_area(rect: Rect2) -> void:
	if hub.FLOOR.is_empty():
		return
	var bounds := Rect2(hub.FLOOR[0],Vector2.ZERO)
	for point in hub.FLOOR:
		bounds = bounds.expand(point)
	for exit in hub.exits.values():
		bounds = bounds.expand(exit.at)
	bounds = bounds.grow(48)
	var ratio := minf(rect.size.x/bounds.size.x,rect.size.y/bounds.size.y)
	var origin := rect.get_center()-bounds.get_center()*ratio
	var outline := PackedVector2Array()
	for point in hub.FLOOR:
		outline.append(origin+point*ratio)
	if outline.size()>=3:
		draw_colored_polygon(outline,Color(.34,.49,.34,.24))
		outline.append(outline[0])
		draw_polyline(outline,Color(.29,.40,.27,.68),1.5 if detailed else 1.0,true)
	if hub.zone=="town":
		var fountain: Vector2 = origin+hub.PLAZA_FOUNTAIN*ratio
		draw_set_transform(fountain,0,Vector2(1,.55))
		draw_circle(Vector2.ZERO,144*ratio,ROAD,true,-1,true)
		draw_circle(Vector2.ZERO,118*ratio,Color("76a6a1"),true,-1,true)
		draw_circle(Vector2.ZERO,40*ratio,Color("e5cc94"),true,-1,true)
		draw_set_transform(Vector2.ZERO)
		if detailed:
			draw_string(serif,fountain+Vector2(-80,144*ratio*.55+24),"Fountain",HORIZONTAL_ALIGNMENT_CENTER,160,19,INK)
	elif hub.zone=="wilds":
		var route := PackedVector2Array()
		for point in hub.Map.Wilds.ROUTE:
			route.append(origin+point*ratio)
		draw_polyline(route,ROAD,4 if detailed else 2,true)
		for i in hub.Map.Wilds.CAMPS.size():
			var cleared := true
			for member in 3:
				cleared = cleared and hub.forest_defeated.has("wild_dog_%d_%d" % [i,member])
			draw_circle(origin+hub.Map.Wilds.CAMPS[i]*ratio,6 if detailed else 3,Color("68835a") if cleared else Color("b77252"),true,-1,true)
	elif hub.zone=="district":
		for road in hub.Map.District.ROADS:
			draw_line(origin+hub.Map.District.iso(road,0)*ratio,origin+hub.Map.District.iso(road,13)*ratio,ROAD,3 if detailed else 1,true)
			draw_line(origin+hub.Map.District.iso(0,road)*ratio,origin+hub.Map.District.iso(13,road)*ratio,ROAD,3 if detailed else 1,true)
		for id in ["plaza","park","market","civic"]:
			draw_circle(origin+hub.Map.District.PLACES[id]*ratio,6 if detailed else 3,Color("7a8858"),true,-1,true)
	var index := 1
	for exit in hub.exits.values():
		var at: Vector2 = origin+exit.at*ratio
		draw_circle(at,11 if detailed else 4,INK,true,-1,true)
		if detailed:
			draw_string(font,at+Vector2(-9,5),str(index),HORIZONTAL_ALIGNMENT_CENTER,18,14,Color("fff4d7"))
		index += 1
	var quest: Dictionary = hub.lighthouse_quest_target()
	if not quest.is_empty():
		var pin_size := 9.0 if detailed else 5.0
		draw_quest_pin(self,origin+quest.at*ratio+Vector2.UP*(pin_size+3),pin_size)
	draw_position(self,origin+hub.player.position*ratio,10 if detailed else 5)
