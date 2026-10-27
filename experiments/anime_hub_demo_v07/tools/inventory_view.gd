extends Control
const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
const Art := preload("res://experiments/anime_hub_demo_v07/tools/equipment_art.gd")
const Slot := preload("res://experiments/anime_hub_demo_v07/tools/equipment_slot.gd")
const POSITIONS := {"head":Vector2(267,8),"chest":Vector2(32,165),"gloves":Vector2(32,315),"weapon":Vector2(32,465),"charm":Vector2(502,165),"legs":Vector2(502,315),"boots":Vector2(502,465)}
var hub: Node2D
var slots: Dictionary = {}
var grid: Array[Button] = []
var filters: Dictionary = {}
var selected := ""
var source := "bag"
var filter := "all"
var purse: Label
var stats_label: Label
var title: Label
var category: Label
var illustration: TextureRect
var description: Label
var comparison: Label
var primary_button: Button
var hint: Label
var character_image: TextureRect

func _ready() -> void:
	size = Vector2(1920,1080)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	UI.shade(self)
	var sheet := UI.panel(self,Vector2(180,100),Vector2(1560,870))
	UI.text(sheet,"THE TRAVELLER'S SATCHEL",Vector2(30,19),600,13,UI.GOLD)
	UI.text(sheet,"Equipment & provisions",Vector2(30,42),700,35,UI.INK,true)
	purse = UI.text(sheet,"",Vector2(785,53),370,20,UI.MUTED)
	var journal := UI.button(sheet,"Quest journal  /  J",Vector2(1240,36),Vector2(286,43))
	journal.pressed.connect(func(): hub.toggle_journal())
	var body := UI.panel(sheet,Vector2(24,110),Vector2(620,630))
	UI.text(body,"YOUR ADVENTURER",Vector2(22,18),210,12,UI.GOLD)
	var links := Control.new()
	links.size = body.size
	links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(links)
	links.draw.connect(func(): draw_links(links))
	character_image = UI.image(body,Art.icon("adventurer"),Vector2(151,112),Vector2(319,463))
	var name_label := UI.text(body,"Mosswood wanderer",Vector2(150,590),320,23,UI.INK,true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for key in hub.state.SLOTS:
		var button := Slot.new()
		button.view = self
		button.position = POSITIONS[key]
		button.size = Vector2(84,84)
		body.add_child(button)
		button.pressed.connect(func(): select(hub.state.equipped_id(key),"equipped",key))
		slots[key] = button
		var label := UI.text(body,hub.state.SLOT_NAMES[key].to_upper(),POSITIONS[key]+Vector2(-17,90),118,12,UI.MUTED)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bag := UI.panel(sheet,Vector2(670,110),Vector2(365,630))
	UI.text(bag,"BACKPACK",Vector2(17,18),330,13,UI.GOLD)
	for i in 4:
		var key: String = ["all","gear","food","quest"][i]
		var button := UI.button(bag,["All","Gear","Food","Quest"][i],Vector2(15+i*84,52),Vector2(79,34))
		button.add_theme_font_size_override("font_size",14)
		button.pressed.connect(func(): filter=key; refresh())
		filters[key] = button
	for index in 24:
		var button := Slot.new()
		button.view = self
		button.position = Vector2(16+(index%4)*84,108+(index/4)*83)
		button.size = Vector2(77,77)
		bag.add_child(button)
		button.pressed.connect(func(): select(button.item_id,"bag"))
		button.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.double_click and button.item_id!="":
				select(button.item_id,"bag")
				activate()
		)
		grid.append(button)
	var detail := UI.panel(sheet,Vector2(1060,110),Vector2(470,630))
	category = UI.text(detail,"ITEM DETAILS",Vector2(27,18),415,13,UI.GOLD)
	title = UI.text(detail,"Choose an item",Vector2(27,49),415,29,UI.INK,true)
	illustration = UI.image(detail,null,Vector2(132,125),Vector2(206,195))
	description = UI.text(detail,"",Vector2(27,343),415,18,UI.MUTED)
	comparison = UI.text(detail,"",Vector2(27,433),415,18,UI.INK)
	primary_button = UI.button(detail,"Equip",Vector2(27,560),Vector2(416,47))
	primary_button.pressed.connect(activate)
	var stats_box := UI.panel(sheet,Vector2(24,754),Vector2(1506,62),true)
	stats_label = UI.text(stats_box,"",Vector2(24,19),1450,19,Color("efe4c3"))
	hint = UI.text(sheet,"Select an item to compare. Drag gear onto its matching slot; drag it back to unequip.",Vector2(26,834),1170,16,UI.MUTED)
	var close := UI.button(sheet,"Return  /  I or Esc",Vector2(1275,825),Vector2(255,33))
	close.pressed.connect(func(): hub.toggle_backpack())
	refresh()
	hide()

func draw_links(node: Control) -> void:
	var targets := {"head":Vector2(309,158),"chest":Vector2(288,313),"gloves":Vector2(228,385),"weapon":Vector2(259,455),"charm":Vector2(344,286),"legs":Vector2(355,428),"boots":Vector2(358,532)}
	for key in POSITIONS:
		var start: Vector2 = POSITIONS[key]+Vector2(42,42)
		var end: Vector2 = targets[key]
		var middle := Vector2((start.x+end.x)*.5,start.y)
		node.draw_polyline(PackedVector2Array([start,middle,Vector2(middle.x,end.y),end]),Color(.65,.54,.32,.45),1.5,true)
		node.draw_circle(end,3,Color("c1a269"))

func open() -> void:
	if hub.state.count("warden_charm")>0:
		selected = "warden_charm"
		source = "bag"
	elif selected=="":
		selected = hub.state.equipped_id("weapon")
		source = "equipped"
	refresh()
	show()

func select(id: String, where: String, slot := "") -> void:
	selected = id
	source = where
	if id=="" and slot!="":
		filter = "gear"
	refresh()
	if id=="" and slot!="":
		title.text = hub.state.SLOT_NAMES[slot]+" slot"
		description.text = "Select a matching piece from your backpack, or drag it into this slot."
		illustration.texture = Art.ghost(slot)

func refresh() -> void:
	if not is_instance_valid(purse):
		return
	purse.text = "%d coins   ·   %d / %d hearts" % [hub.coins,hub.player.health,hub.player.maximum_health]
	var state = hub.state
	if selected!="" and state.definitions.has(selected) and state.definitions[selected].has("slot"):
		var key: String = state.definitions[selected].slot
		source = "equipped" if state.equipped_id(key)==selected else "bag"
	for key in slots:
		var id: String = state.equipped_id(key)
		slots[key].configure(id,"equipped",key)
		slots[key].mark(selected!="" and (id==selected or (source=="bag" and state.definitions[selected].get("slot","")==key)))
	var ids: Array[String] = []
	for id in state.definitions:
		if state.count(id)>0 and (filter=="all" or state.definitions[id].kind==filter):
			ids.append(id)
	ids.sort_custom(func(a: String,b: String): return state.definitions[a].name<state.definitions[b].name)
	for index in grid.size():
		var id: String = ids[index] if index<ids.size() else ""
		grid[index].configure(id,"bag","",state.count(id) if id!="" else 0)
		grid[index].mark(id!="" and id==selected and source=="bag")
	for key in filters:
		filters[key].add_theme_stylebox_override("normal",UI.style(true,filter==key))
	var stats: Dictionary = state.stats()
	stats_label.text = "HEARTS  %d / %d     •     SWORD  %d damage     •     WIND SLASH  %d damage / %.1f s     •     MOVEMENT  %d%%" % [hub.player.health,stats.hearts,stats.attack,stats.wind,stats.recharge,roundi(stats.speed*100)]
	refresh_details()

func refresh_details() -> void:
	var state = hub.state
	primary_button.disabled = true
	if selected=="" or not state.definitions.has(selected):
		category.text = "ITEM DETAILS"
		title.text = "Choose an item"
		illustration.texture = null
		description.text = "Inspect an equipped piece or an item in your backpack."
		comparison.text = ""
		primary_button.text = "Select an item"
		return
	var item: Dictionary = state.definitions[selected]
	title.text = item.name
	illustration.texture = Art.icon(selected,state.definitions)
	description.text = item.description
	if item.has("slot"):
		category.text = state.SLOT_NAMES[item.slot].to_upper()+("  ·  EQUIPPED" if source=="equipped" else "  ·  BACKPACK")
		var now: Dictionary = state.stats()
		var replacements := {}
		replacements[item.slot] = "" if source=="equipped" else selected
		var after: Dictionary = state.stats(replacements)
		comparison.text = "After %s:\nHearts %d (%+d)   •   Sword %d (%+d)\nSkill %.1f s (%+.1f)   •   Movement %d%%" % ["removing" if source=="equipped" else "equipping",after.hearts,int(after.hearts)-int(now.hearts),after.attack,int(after.attack)-int(now.attack),after.recharge,float(after.recharge)-float(now.recharge),roundi(after.speed*100)]
		primary_button.text = "Unequip to backpack" if source=="equipped" else "Equip in "+state.SLOT_NAMES[item.slot]
		primary_button.disabled = hub.player.swing>0 or (source=="bag" and state.count(selected)==0)
	elif item.kind=="food":
		category.text = "PROVISION  ·  %d IN BACKPACK" % state.count(selected)
		comparison.text = "Restores %d hearts." % int(item.heal)
		if item.get("refresh_skill",false):
			comparison.text += "\nAlso refreshes Wind Slash."
		primary_button.text = "Use provision"
		primary_button.disabled = state.count(selected)==0 or hub.player.swing>0 or (hub.player.health>=hub.player.maximum_health and not (item.get("refresh_skill",false) and hub.player.skill_cooldown>0))
	else:
		category.text = "QUEST ITEM  ·  %d IN BACKPACK" % state.count(selected)
		comparison.text = "Keep this for the person who needs it."
		primary_button.text = "Quest item"

func activate() -> void:
	if selected=="" or primary_button.disabled:
		return
	var item: Dictionary = hub.state.definitions[selected]
	if item.has("slot"):
		if source=="equipped":
			unequip(item.slot)
		else:
			equip(selected,item.slot)
	elif item.kind=="food":
		hub.use_item(selected)
	refresh()

func equip(id: String, destination: String) -> void:
	if hub.equip_item(id,destination):
		selected = id
		source = "equipped"
	refresh()

func unequip(slot: String) -> void:
	var id: String = hub.state.equipped_id(slot)
	if hub.unequip_item(slot):
		selected = id
		source = "bag"
	refresh()
