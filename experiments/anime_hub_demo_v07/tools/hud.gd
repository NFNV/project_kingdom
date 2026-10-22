extends CanvasLayer

const Clock := preload("res://experiments/anime_hub_demo_v07/tools/celestial_clock.gd")
var hub: Node2D
var serif := SystemFont.new()
var objective: Label
var status_label: Label
var location_label: Label
var location_subtitle: Label
var clock_dial: Control
var talk_panel: Panel
var talk_name: Label
var talk_text: Label
var prompt: Panel
var prompt_text: Label
var quest_marker: Label
var pause_overlay: Control
var fade: ColorRect
var journal_panel: Panel
var debug_label: Label
var route_label: Label
var debug_visible := false
var merchant: Control
var shop_balance: Label
var shop_feedback: Label
var shop_satchel: Label
var shop_buttons: Array[Button] = []


func _ready() -> void:
	serif.font_names = PackedStringArray(["Georgia","Baskerville","Noto Serif","serif"])
	var location := panel(Vector2(28,28),Vector2(370,112))
	label("PROJECT KINGDOM  /  MOSSWOOD VALLEY",Vector2(18,12),11,location,0,Color("7b7159"))
	location_label = label("Garden Square",Vector2(18,30),29,location,0,Color("263e37"),true)
	location_subtitle = label("A small town, a wider world",Vector2(20,78),14,location,0,Color("756a52"))
	clock_dial = Clock.new()
	clock_dial.position = Vector2(859,7)
	clock_dial.scale = Vector2(.72,.72)
	clock_dial.serif = serif
	add_child(clock_dial)
	journal_panel = panel(Vector2(1498,28),Vector2(394,162))
	label("THE TRAVELLER'S JOURNAL",Vector2(20,13),12,journal_panel,0,Color("887043"))
	objective = label("",Vector2(20,41),20,journal_panel,350,Color("2e4239"),true)
	status_label = label("",Vector2(20,128),13,journal_panel,354,Color("7e7054"))
	var controls := panel(Vector2(28,1012),Vector2(746,44),null,true)
	label("WASD  walk     SHIFT  run     E  talk / use     Right click  walk to point",Vector2(16,11),15,controls,0,Color("f0e4c8"))
	var actions := panel(Vector2(1515,1012),Vector2(377,44),null,true)
	label("J  journal     T  time     Esc  pause     F11  full screen",Vector2(14,12),13,actions,0,Color("f0e4c8"))
	route_label = label("",Vector2(1140,972),17,self,720,Color("fff2ca"),true)
	route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	route_label.add_theme_color_override("font_shadow_color",Color("18372e"))
	route_label.add_theme_constant_override("shadow_offset_y",2)
	talk_panel = panel(Vector2(480,828),Vector2(960,146))
	talk_name = label("",Vector2(24,16),20,talk_panel,910,Color("8b6431"),true)
	talk_text = label("",Vector2(24,52),20,talk_panel,910,Color("33433a"))
	prompt = panel(Vector2.ZERO,Vector2(292,42),null,true)
	prompt_text = label("",Vector2(13,9),17,prompt,0,Color("fff2d2"))
	quest_marker = label("▼",Vector2.ZERO,29,self,0,Color("ffe0a0"))
	quest_marker.add_theme_color_override("font_outline_color",Color("63502d"))
	quest_marker.add_theme_constant_override("outline_size",5)
	debug_label = label("",Vector2(30,151),14,self,0,Color("fff1d2"))
	debug_label.add_theme_color_override("font_shadow_color",Color("20382d"))
	debug_label.add_theme_constant_override("shadow_offset_y",2)
	debug_label.hide()
	pause_overlay = Control.new()
	pause_overlay.size = Vector2(1920,1080)
	add_child(pause_overlay)
	var shade := ColorRect.new()
	shade.color = Color(.035,.07,.06,.68)
	shade.size = Vector2(1920,1080)
	pause_overlay.add_child(shade)
	var menu := panel(Vector2(650,330),Vector2(620,370),pause_overlay)
	label("Rest a while",Vector2(42,36),37,menu,0,Color("2e4239"),true)
	label("Esc   Return to your walk\nR      Begin a new day\nJ       Show or hide your journal\nF11   Full screen",Vector2(44,114),22,menu,520,Color("52604d"))
	label("Day and night pass slowly: 20 minutes per full cycle.",Vector2(44,312),16,menu,530,Color("8b7654"))
	pause_overlay.hide()
	_build_merchant()
	fade = ColorRect.new()
	fade.size = Vector2(1920,1080)
	fade.color = Color("10241d")
	fade.modulate.a = 0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)


func panel(at: Vector2, dimensions: Vector2, parent: Node = null, dark := false) -> Panel:
	var box := Panel.new()
	box.position = at
	box.size = dimensions
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("233d35") if dark else Color("f3ebd6")
	style.bg_color.a = .95
	style.border_color = Color("b49a67")
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.shadow_color = Color(0.05,.07,.04,.23)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0,3)
	box.add_theme_stylebox_override("panel",style)
	(parent if parent else self).add_child(box)
	# Fine inset brass line gives the parchment frame a finished edge.
	var inset := Panel.new()
	inset.position = Vector2(5,5)
	inset.size = dimensions-Vector2(10,10)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var trim := StyleBoxFlat.new()
	trim.bg_color = Color(0,0,0,0)
	trim.border_color = Color(.65,.53,.31,.28)
	trim.set_border_width_all(1)
	trim.set_corner_radius_all(6)
	inset.add_theme_stylebox_override("panel",trim)
	box.add_child(inset)
	return box


func label(text: String, at: Vector2, font_size: int, parent: Node, width := 0.0, color := Color("33433a"), heading := false) -> Label:
	var item := Label.new()
	item.text = text
	item.position = at
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",color)
	if heading:
		item.add_theme_font_override("font",serif)
	if width>0:
		item.size.x = width
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(item)
	return item


func refresh() -> void:
	location_label.text = hub.zone_title()
	location_subtitle.text = {"town":"Southeast gate  →  Mosswood Trail","trail":"Old elm paths  /  Riverbend to the southeast","river":"Riverbend Glade  /  The way home lies west","bakery":"Warm bread, meadow tea, and a place to rest"}[hub.zone]
	if hub.zone=="town":
		objective.text = hub.OBJECTIVES[hub.quest_stage]
		status_label.text = "%d / 5 deliveries  ·  The wardens are friendly" % mini(hub.quest_stage,5)
	elif hub.zone=="bakery":
		objective.text = "Meet Clover at the counter. E to browse today's baking."
		status_label.text = "%d coins  ·  Front door leads back to the square" % hub.coins
	else:
		objective.text = "Follow the woodland paths. Find a quiet place to take in the view."
		if hub.discoveries.size()==3:
			objective.text = "Every resting place discovered. Follow the trail home whenever you like."
		status_label.text = "%d / 3 forest memories  ·  E at a resting place" % hub.discoveries.size()
	debug_label.visible = debug_visible
	debug_label.text = "%d FPS  ·  1920 × 1080  ·  %s  ·  F3 debug" % [Engine.get_frames_per_second(),hub.zone]
	var suffix := ""
	if hub.near_exit!="":
		suffix = "E  ·  "+hub.exits[hub.near_exit]["label"]
	route_label.text = suffix


func _build_merchant() -> void:
	merchant = Control.new()
	merchant.size = Vector2(1920,1080)
	merchant.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(merchant)
	var shade := ColorRect.new()
	shade.size = merchant.size
	shade.color = Color(.035,.07,.05,.66)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	merchant.add_child(shade)
	var sheet := panel(Vector2(505,220),Vector2(910,640),merchant)
	label("THE BLUEBIRD BAKERY",Vector2(40,27),14,sheet,0,Color("967344"))
	label("Good things, fresh from the oven",Vector2(40,56),30,sheet,820,Color("304c3d"),true)
	label("Clover  /  Bakery keeper",Vector2(42,108),17,sheet,0,Color("826c4a"))
	shop_balance = label("",Vector2(640,111),17,sheet,225,Color("826c4a"))
	for index in hub.GOODS.size():
		var good: Dictionary = hub.GOODS[index]
		var top: int = 162+index*95
		label(good["name"],Vector2(44,top),22,sheet,500,Color("314b3d"),true)
		label(good["description"],Vector2(44,top+33),16,sheet,500,Color("80745b"))
		var button := Button.new()
		button.text = "%d  ·  Buy / %d coins" % [index+1,good["price"]]
		button.position = Vector2(608,top+4)
		button.size = Vector2(250,53)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size",18)
		for state in ["normal","hover","pressed","disabled"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("335a48") if state=="normal" else (Color("47755c") if state=="hover" else Color("283f32"))
			style.border_color = Color("b89b62")
			style.set_border_width_all(1)
			style.set_corner_radius_all(6)
			button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("font_color",Color("fff1cf"))
		button.pressed.connect(func(): hub.buy(index))
		sheet.add_child(button)
		shop_buttons.append(button)
	shop_feedback = label("",Vector2(44,469),18,sheet,810,Color("8a6035"))
	shop_satchel = label("",Vector2(44,518),15,sheet,810,Color("6a745b"))
	var close := Button.new()
	close.text = "Back to the bakery   /   E or Esc"
	close.position = Vector2(255,569)
	close.size = Vector2(400,42)
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size",17)
	for state in ["normal","hover","pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("47755c") if state=="hover" else Color("335a48")
		style.border_color = Color("b89b62")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		close.add_theme_stylebox_override(state,style)
	close.add_theme_color_override("font_color",Color("fff1cf"))
	close.pressed.connect(func(): hub.close_shop())
	sheet.add_child(close)
	merchant.hide()


func refresh_shop(message: String) -> void:
	shop_balance.text = "Your purse: %d coins" % hub.coins
	shop_feedback.text = message
	shop_satchel.text = "IN YOUR SATCHEL    %d loaves  /  %d teas  /  %d honey jars" % [hub.inventory.bread,hub.inventory.tea,hub.inventory.honey]
	for index in shop_buttons.size():
		shop_buttons[index].disabled = hub.coins<int(hub.GOODS[index]["price"])
