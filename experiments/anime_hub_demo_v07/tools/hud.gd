extends CanvasLayer

const FieldMap := preload("res://experiments/anime_hub_demo_v07/tools/field_map.gd")
const Hearts := preload("res://experiments/anime_hub_demo_v07/tools/heart_meter.gd")
const InventoryView := preload("res://experiments/anime_hub_demo_v07/tools/inventory_view.gd")
const JournalView := preload("res://experiments/anime_hub_demo_v07/tools/quest_journal.gd")
const ForgeShop := preload("res://experiments/anime_hub_demo_v07/tools/forge_shop.gd")
const SkillDock := preload("res://experiments/anime_hub_demo_v07/tools/skill_dock.gd")
const Clock := preload("res://experiments/anime_hub_demo_v07/tools/celestial_clock.gd")
const RenderSettings := preload("res://experiments/anime_hub_demo_v07/tools/render_settings.gd")
const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
var hub: Node2D
var serif: Font = UI.heading_font()
var objective: Label
var status_label: Label
var clock_dial: Control
var talk_panel: Panel
var talk_name: Label
var talk_text: Label
var prompt: Panel
var prompt_text: Label
var quest_marker: Label
var pause_overlay: Control
var fade: ColorRect
var journal_panel: Button
var minimap: FieldMap
var area_map: Control
var heart_icons: Node2D
var shown_health := Vector2i(-1,-1)
var debug_label: Label
var route_label: Label
var debug_visible := false
var merchant: Control
var shop_balance: Label
var shop_feedback: Label
var shop_satchel: Label
var shop_buttons: Array[Button] = []
var shop_names: Array[Label] = []
var shop_descriptions: Array[Label] = []
var shop_banner: Label
var shop_title: Label
var shopkeeper: Label
var shop_close: Button
var controls_label: Label
var combat_panel: Panel
var stamina_bar: ProgressBar
var skill_panel: SkillDock
var skill_label: Label
var skill_bar: ProgressBar
var skill_button: Button
var audio_sliders: Dictionary = {}
var audio_values: Dictionary = {}
var audio_mute: CheckBox
var satchel: Control
var journal_view: Control
var forge_view: Control
var satchel_health: Label
var satchel_quest: Label
var satchel_rows: Dictionary = {}
var food_buttons: Dictionary = {}
var charm_button: Button
var charm_description: Label
var save_button: Button
var load_button: Button
var notice: Panel
var notice_text: Label
var notice_left := 0.0
var inn_dialog: Control
var inn_title: Label
var inn_sleep_button: Button


func _ready() -> void:
	scale = Vector2.ONE*RenderSettings.SCALE
	var right_edge := 1894.0
	minimap = FieldMap.new()
	minimap.hub = hub
	add_child(minimap)
	minimap.position = Vector2(right_edge-minimap.size.x,22)
	clock_dial = Clock.new()
	clock_dial.position = Vector2(848,7)
	clock_dial.scale = Vector2(.8,.8)
	clock_dial.serif = serif
	add_child(clock_dial)
	journal_panel = UI.button(self,"",Vector2(right_edge-92,minimap.position.y+minimap.size.y+12),Vector2(92,108))
	journal_panel.tooltip_text = "Open the Traveller's Journal (J)"
	journal_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	journal_panel.pressed.connect(func(): hub.toggle_journal())
	UI.image(journal_panel,JournalView.COVER,Vector2(9,0),Vector2(76,101))
	var hotkey := panel(Vector2(60,75),Vector2(28,26),journal_panel,true)
	hotkey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label("J",Vector2(9,3),14,hotkey,18,Color("fff0c7"),true)
	var controls := panel(Vector2(284,1024),Vector2(795,30),null,true)
	controls_label = label("WASD walk · Shift run · E interact · Right click walk",Vector2(12,7),12,controls,770,Color("f0e4c8"))
	var actions := panel(Vector2(1570,1024),Vector2(324,30),null,true)
	label("I satchel · M map · N mute · Esc menu",Vector2(12,7),12,actions,0,Color("f0e4c8"))
	route_label = label("",Vector2(1170,989),14,self,720,Color("fff2ca"),true)
	route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	route_label.add_theme_color_override("font_shadow_color",Color("18372e"))
	route_label.add_theme_constant_override("shadow_offset_y",2)
	talk_panel = panel(Vector2(510,856),Vector2(900,128))
	talk_name = label("",Vector2(20,12),18,talk_panel,860,Color("8b6431"),true)
	talk_text = label("",Vector2(20,44),18,talk_panel,860,Color("33433a"))
	prompt = panel(Vector2.ZERO,Vector2(266,34),null,true)
	prompt_text = label("",Vector2(11,7),14,prompt,0,Color("fff2d2"))
	quest_marker = label("▼",Vector2.ZERO,23,self,0,Color("ffe0a0"))
	quest_marker.add_theme_color_override("font_outline_color",Color("63502d"))
	quest_marker.add_theme_constant_override("outline_size",5)
	debug_label = label("",Vector2(26,258),12,self,0,Color("fff1d2"))
	debug_label.add_theme_color_override("font_shadow_color",Color("20382d"))
	debug_label.add_theme_constant_override("shadow_offset_y",2)
	debug_label.hide()
	combat_panel = panel(Vector2(24,22),Vector2(144,66),null,true)
	heart_icons = Node2D.new()
	heart_icons.position = Vector2(8,7)
	combat_panel.add_child(heart_icons)
	heart_icons.draw.connect(func(): Hearts.draw_on(heart_icons,Vector2.ZERO,hub.player.health,hub.player.maximum_health))
	var bar_back := StyleBoxFlat.new()
	bar_back.bg_color = Color("132c25")
	bar_back.set_corner_radius_all(5)
	stamina_bar = ProgressBar.new()
	stamina_bar.position = Vector2(8,52)
	stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamina_bar.show_percentage = false
	stamina_bar.max_value = 100
	stamina_bar.add_theme_font_size_override("font_size",1)
	stamina_bar.add_theme_stylebox_override("background",bar_back.duplicate())
	var stamina_fill := bar_back.duplicate() as StyleBoxFlat
	stamina_fill.bg_color = Color("75c7c1")
	stamina_bar.add_theme_stylebox_override("fill",stamina_fill)
	combat_panel.add_child(stamina_bar)
	stamina_bar.size = Vector2(combat_panel.size.x-16,6)
	skill_panel = SkillDock.new()
	skill_panel.hub = hub
	skill_panel.serif = serif
	skill_panel.position = Vector2(28,816)
	add_child(skill_panel)
	skill_button = skill_panel.button
	skill_label = skill_panel.status
	skill_bar = skill_panel.recharge
	skill_panel.hide()
	pause_overlay = Control.new()
	pause_overlay.size = Vector2(1920,1080)
	add_child(pause_overlay)
	var shade := ColorRect.new()
	shade.color = Color(.035,.07,.06,.68)
	shade.size = Vector2(1920,1080)
	pause_overlay.add_child(shade)
	var menu := panel(Vector2(650,155),Vector2(620,760),pause_overlay)
	label("Rest a while",Vector2(42,36),37,menu,0,Color("2e4239"),true)
	label("Esc   Return to your walk\nR      Return to the title\nJ       Open your quest journal\nF11   Full screen",Vector2(44,105),21,menu,520,Color("52604d"))
	label("F5 save  ·  F9 continue  ·  I satchel  ·  H bread",Vector2(44,236),16,menu,530,Color("756a52"))
	save_button = action_button("Save journey",Vector2(44,270),Vector2(248,48),menu)
	save_button.pressed.connect(func(): hub.save_game())
	load_button = action_button("Continue saved journey",Vector2(306,270),Vector2(270,48),menu)
	load_button.pressed.connect(func(): hub.load_game())
	_build_audio_menu(menu)
	var title_button := action_button("Save and return to title",Vector2(44,623),Vector2(532,40),menu)
	title_button.pressed.connect(func(): hub.return_to_title())
	label("Autosaves at safe travel and quest milestones. F5 saves now.\nDay and night pass slowly: 20 minutes per full cycle.",Vector2(44,690),15,menu,530,Color("8b7654"))
	pause_overlay.hide()
	_build_merchant()
	_build_satchel()
	journal_view = JournalView.new()
	journal_view.hub = hub
	add_child(journal_view)
	objective = journal_view.guidance
	status_label = journal_view.footer
	area_map = FieldMap.new()
	area_map.hub = hub
	area_map.detailed = true
	area_map.hide()
	add_child(area_map)
	forge_view = ForgeShop.new()
	forge_view.hub = hub
	add_child(forge_view)
	notice = panel(Vector2(580,744),Vector2(760,44),null,true)
	notice_text = label("",Vector2(14,12),15,notice,732,Color("fff0cd"))
	notice_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.hide()
	_build_inn()
	fade = ColorRect.new()
	fade.size = Vector2(1920,1080)
	fade.color = Color("10241d")
	fade.modulate.a = 0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	hub.audio.settings_changed.connect(refresh_audio)
	refresh_audio()
	refresh_save_controls()

func _build_inn() -> void:
	inn_dialog = Control.new()
	inn_dialog.size = Vector2(1920,1080)
	add_child(inn_dialog)
	var shade := ColorRect.new()
	shade.size = Vector2(1920,1080)
	shade.color = Color(.035,.07,.06,.68)
	inn_dialog.add_child(shade)
	var card := panel(Vector2(610,365),Vector2(700,350),inn_dialog)
	label("A NIGHT AT WINDSONG",Vector2(34,25),14,card,630,Color("887043"))
	inn_title = label("Guest room",Vector2(34,58),30,card,630,Color("2e4239"),true)
	label("Fresh linen, a soft quilt, and the quiet hum of the mill.\nSleep until 7 AM and restore all your hearts.\nYour stay is complimentary.",Vector2(36,113),21,card,628,Color("52604d"))
	inn_sleep_button = action_button("Sleep until 7 AM",Vector2(35,245),Vector2(305,52),card)
	inn_sleep_button.focus_mode = Control.FOCUS_ALL
	inn_sleep_button.pressed.connect(func():
		if hub.zone=="mill_loft": hub.bakery_room.rest(hub.inn_bed)
	)
	var cancel := action_button("Keep exploring",Vector2(360,245),Vector2(305,52),card)
	cancel.focus_mode = Control.FOCUS_ALL
	cancel.pressed.connect(func(): hub.close_inn())
	label("Enter  Choose       Esc / E  Cancel",Vector2(35,316),14,card,630,Color("887043"))
	inn_dialog.hide()

func _build_audio_menu(menu: Control) -> void:
	label("SOUND",Vector2(44,344),14,menu,0,Color("887043"))
	var row := 0
	for key in ["master","music","ambience","effects"]:
		var y := 380+row*39
		label(key.capitalize(),Vector2(44,y),18,menu,0,Color("33433a"))
		var slider := HSlider.new()
		slider.position = Vector2(185,y+2)
		slider.size = Vector2(300,24)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = .01
		slider.value = hub.audio.levels[key]
		slider.value_changed.connect(func(value: float): hub.audio.set_volume(key,value))
		menu.add_child(slider)
		audio_sliders[key] = slider
		audio_values[key] = label("",Vector2(504,y),17,menu,0,Color("756a52"))
		row += 1
	audio_mute = CheckBox.new()
	audio_mute.position = Vector2(40,571)
	audio_mute.text = "Mute all   (M)"
	audio_mute.add_theme_font_size_override("font_size",18)
	audio_mute.add_theme_color_override("font_color",Color("33433a"))
	audio_mute.toggled.connect(func(value: bool): hub.audio.set_muted(value))
	menu.add_child(audio_mute)

func refresh_audio() -> void:
	for key in audio_sliders:
		audio_sliders[key].set_value_no_signal(hub.audio.levels[key])
		audio_values[key].text = "%d%%" % roundi(hub.audio.levels[key]*100)
	audio_mute.set_pressed_no_signal(hub.audio.muted)


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
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var trim := StyleBoxFlat.new()
	trim.bg_color = Color(0,0,0,0)
	trim.border_color = Color(.65,.53,.31,.28)
	trim.set_border_width_all(1)
	trim.set_corner_radius_all(6)
	inset.add_theme_stylebox_override("panel",trim)
	box.add_child(inset)
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,5)
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
	skill_panel.visible = hub.zone not in ["bakery","forge","mill_garden","mill_room","mill_loft"]
	skill_button.disabled = hub.peaceful_mode or hub.player.skill_cooldown>0 or not hub.player.active or int(hub.state.stats().attack)<=0
	skill_bar.max_value = float(hub.state.stats().recharge)
	skill_bar.value = skill_bar.max_value-hub.player.skill_cooldown
	skill_label.text = "Briarwood only" if hub.peaceful_mode else ("Queued" if hub.player.skill_buffer>0 else ("Ready" if hub.player.skill_cooldown<=0 else "Recharging  %.1f s" % hub.player.skill_cooldown))
	if int(hub.state.stats().attack)<=0:
		skill_label.text = "Equip a weapon"
	controls_label.text = "WASD · Space / Click sword · Q wind · F guard / parry · V / Ctrl roll" if hub.zone=="wilds" else "WASD walk · Shift run · V roll · E interact · Right click walk"
	if hub.zone=="town":
		objective.text = hub.OBJECTIVES[hub.quest_stage]
		status_label.text = "%d / 5 deliveries  ·  The wardens are friendly" % mini(hub.quest_stage,5)
	elif hub.zone in ["bakery","forge"]:
		objective.text = "Meet Tomas at the counter. E to browse equipment and hear his request." if hub.zone=="forge" else "Meet Clover at the counter. E to browse today's baking."
		status_label.text = "%d coins  ·  Front door leads back to %s" % [hub.coins,"Northgate" if hub.zone=="forge" else "the square"]
	elif hub.zone=="district":
		objective.text = "Explore Sunstone Plaza, Linden Park and the old town hall."
		status_label.text = "%d / 3 places visited  ·  The streets are peaceful" % hub.district_places.size()
	elif hub.zone in ["mill_garden","mill_room","mill_loft"]:
		objective.text = "Explore the backyard, meet the cats, or step inside Windsong Mill." if hub.zone=="mill_garden" else "Talk to Rowan by the counter, enjoy the tea corner and warm hearth."
		status_label.text = "South gate → The Greenshire" if hub.zone=="mill_garden" else "Stairs → Guest rooms · Front door → Garden"
	elif hub.zone=="wilds":
		objective.text = "Drive the dog bandits from the four forest clearings." if hub.combat_active else "Briarwood is quiet. Explore or take the western trail home."
		status_label.text = "%d / 12 bandits defeated  ·  %d coins" % [hub.forest_defeated.size(),hub.coins]
	else:
		objective.text = "Follow the woodland paths. Find a quiet place to take in the view."
		if hub.discoveries.size()==3:
			objective.text = "Every resting place discovered. Follow the trail home whenever you like."
		status_label.text = "%d / 3 forest memories  ·  E at a resting place" % hub.discoveries.size()
	if hub.state.tracked_quest=="briarwood_patrol":
		objective.text = hub.state.quest_text()
		status_label.text = "%d coins  ·  I satchel  ·  H healing bread" % hub.coins
	elif hub.state.tracked_quest=="emberforge_tools":
		objective.text = hub.state.smith_text()
		status_label.text = "%d coins  ·  J journal  ·  I equipment" % hub.coins
	elif hub.state.tracked_quest=="morning_rounds":
		objective.text = hub.OBJECTIVES[hub.quest_stage]
		status_label.text = "%d / 5 deliveries  ·  J journal" % mini(hub.quest_stage,5)
	if hub.zone=="wilds" and hub.forest_defeated.size()==12:
		var remaining: int = hub.dogs.filter(func(dog): return dog.active).size()
		status_label.text = "Returning patrol · %d bandits remain" % remaining if remaining>0 else "Patrol cleared · Leave and return for another"
		if remaining>0 and hub.state.rewarded:
			objective.text = "Fight the returning patrol. Original quest rewards are already secured."
	if hub.zone in ["mill_garden","mill_room","mill_loft"]:
		objective.text = "Explore the backyard, meet the cats, or step inside Windsong Mill." if hub.zone=="mill_garden" else "A warm hearth, meadow tea and Rowan's stories."
		status_label.text = "%d coins · I satchel · J journal · F5 save" % hub.coins
	if hub.zone=="mill_loft":
		objective.text = "Choose a guest room. E beside a bed to sleep until 7 AM and restore your hearts."
		status_label.text = "Complimentary stay · Stairs → Hearthroom"
	elif hub.zone=="mill_room":
		objective.text = "A warm hearth, meadow tea and three cozy guest rooms upstairs."
	if hub.state.tracked_quest==hub.GameState.STONEBACK_QUEST and hub.zone!="mill_loft":
		objective.text = hub.state.stoneback_text()
		status_label.text = "%d coins  ·  J journal  ·  I satchel" % hub.coins
	elif hub.state.tracked_quest==hub.GameState.LIGHTHOUSE_QUEST:
		objective.text = hub.state.lighthouse_text()
		status_label.text = "%d coins  ·  M atlas  ·  J journal" % hub.coins
	debug_label.visible = debug_visible
	debug_label.text = "%d FPS  ·  %d × %d  ·  %s  ·  F3 debug" % [Engine.get_frames_per_second(),RenderSettings.RENDER_SIZE.x,RenderSettings.RENDER_SIZE.y,hub.zone]
	var suffix := ""
	if hub.near_exit!="":
		suffix = "E  ·  "+hub.exits[hub.near_exit]["label"]
	route_label.text = suffix
	if hub.zone=="wilds" and suffix.is_empty() and hub.combat_active:
		var closest := INF
		var offset := Vector2.ZERO
		for dog in hub.dogs:
			if dog.active and dog.position.distance_to(hub.player.position)<closest:
				closest = dog.position.distance_to(hub.player.position)
				offset = dog.position-hub.player.position
		var direction := ("north" if offset.y<0 else "south")+("east" if offset.x>0 else "west")
		route_label.text = "Nearest bandits: %s  /  %d m" % [direction,ceili(closest/32.0)]
	refresh_save_controls()


func _process(delta: float) -> void:
	if is_instance_valid(hub.player):
		var health := Vector2i(hub.player.health,hub.player.maximum_health)
		if health!=shown_health:
			shown_health = health
			combat_panel.size.x = 12 + 44 * (health.y / Hearts.UNITS_PER_HEART)
			stamina_bar.size.x = combat_panel.size.x-16
			heart_icons.queue_redraw()
		stamina_bar.value = hub.player.stamina
	notice_left = maxf(0,notice_left-delta)
	if is_instance_valid(notice):
		notice.visible = notice_left>0

func world_to_ui(point: Vector2) -> Vector2:
	return get_final_transform().affine_inverse()*(hub.get_canvas_transform()*point)

func show_notice(message: String) -> void:
	notice.position.y = 54 if hub.paused or hub.shopping else (925 if hub.zone in ["mill_garden","mill_room","mill_loft"] else 744)
	notice_text.text = message
	notice_left = 4.0
	notice.show()


func refresh_save_controls() -> void:
	if is_instance_valid(load_button):
		load_button.disabled = not hub.saves.has_journey(hub.save_path)
		save_button.disabled = hub.transitioning or not hub.player.active


func action_button(text: String, at: Vector2, dimensions: Vector2, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size",17)
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("47755c") if state=="hover" else (Color("8a8e7b") if state=="disabled" else Color("335a48"))
		style.border_color = Color("b89b62")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override(state,style)
	button.add_theme_color_override("font_color",Color("fff1cf"))
	parent.add_child(button)
	return button


func _build_satchel() -> void:
	satchel = InventoryView.new()
	satchel.hub = hub
	add_child(satchel)

func refresh_satchel() -> void:
	if is_instance_valid(satchel):
		satchel.refresh()


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
	shop_banner = label("",Vector2(40,27),14,sheet,0,Color("967344"))
	shop_title = label("",Vector2(40,56),30,sheet,820,Color("304c3d"),true)
	shopkeeper = label("",Vector2(42,108),17,sheet,0,Color("826c4a"))
	shop_balance = label("",Vector2(640,111),17,sheet,225,Color("826c4a"))
	for index in hub.GOODS.size():
		var top: int = 162+index*95
		shop_names.append(label("",Vector2(44,top),22,sheet,500,Color("314b3d"),true))
		shop_descriptions.append(label("",Vector2(44,top+33),16,sheet,500,Color("80745b")))
		var button := Button.new()
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
	shop_close = close
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


func configure_shop(apothecary: bool) -> void:
	shop_banner.text = "GARDEN SQUARE APOTHECARY" if apothecary else "THE BLUEBIRD BAKERY"
	shop_title.text = "Potions for the road" if apothecary else "Good things, fresh from the oven"
	shopkeeper.text = "Iris  /  Apothecary" if apothecary else "Clover  /  Bakery keeper"
	shop_close.text = "Back to the square   /   E or Esc" if apothecary else "Back to the bakery   /   E or Esc"
	var stock: Array = hub.shop_stock()
	for index in shop_buttons.size():
		var available := index < stock.size()
		shop_names[index].visible = available
		shop_descriptions[index].visible = available
		shop_buttons[index].visible = available
		if available:
			var good: Dictionary = stock[index]
			shop_names[index].text = good.name
			shop_descriptions[index].text = good.description
			shop_buttons[index].text = "%d  ·  Buy / %d coins" % [index+1,good.price]


func refresh_shop(message: String) -> void:
	shop_balance.text = "Your purse: %d coins" % hub.coins
	shop_feedback.text = message
	var stock: Array = hub.shop_stock()
	var counts := PackedStringArray()
	for index in stock.size():
		var good: Dictionary = stock[index]
		counts.append("%d × %s" % [hub.state.count(good.id),good.name])
		shop_buttons[index].disabled = hub.coins<int(good.price)
	shop_satchel.text = "IN YOUR SATCHEL    " + "  /  ".join(counts)
