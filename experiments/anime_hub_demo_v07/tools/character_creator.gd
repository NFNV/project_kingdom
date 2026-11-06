extends Control

signal accepted(appearance: Dictionary)
signal cancelled

const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
const Motion := preload("res://experiments/anime_hub_demo_v07/tools/motion_sprite.gd")
const Look := Motion.HeroLook
const Rider := preload("res://experiments/overworld_2d_v01/mounted_rider.gd")
enum Preview { FRONT, BACK, WALK, RUN, FROG }

var appearance := Look.DEFAULT.duplicate()
var name_field: LineEdit
var choices: Dictionary = {}
var palette_controls: Control
var dog_look: Label
var species_buttons: Array[Button] = []
var preview_buttons: Array[Button] = []
var preview: Node2D
var actor: AnimatedSprite2D
var rider: RefCounted
var preview_mode := Preview.FRONT

func _ready() -> void:
	size = Vector2(1920,1080)
	UI.shade(self)
	var sheet := UI.panel(self,Vector2(340,140),Vector2(1240,800))
	UI.text(sheet,"A NEW JOURNEY",Vector2(46,27),600,16,UI.GOLD)
	UI.text(sheet,"Create your adventurer",Vector2(44,55),1120,47,UI.INK,true)
	UI.text(sheet,"CHOOSE YOUR SPECIES",Vector2(45,148),480,14,UI.MUTED)
	for index in Look.SPECIES.size():
		var button := UI.button(sheet,Look.SPECIES[index],Vector2(45+index*268,178),Vector2(248,56))
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(func():
			appearance.species = Look.SPECIES[index].to_lower()
			update_preview())
		species_buttons.append(button)
	UI.text(sheet,"NAME",Vector2(45,265),480,14,UI.MUTED)
	name_field = LineEdit.new()
	name_field.position = Vector2(45,291)
	name_field.size = Vector2(516,49)
	name_field.max_length = 24
	name_field.placeholder_text = Look.DEFAULT.name
	name_field.add_theme_font_size_override("font_size",21)
	name_field.add_theme_color_override("font_color",Color("fff0ce"))
	name_field.add_theme_color_override("font_placeholder_color",Color("c4c4a7"))
	name_field.add_theme_stylebox_override("normal",UI.style(true))
	name_field.add_theme_stylebox_override("focus",UI.style(true,true))
	sheet.add_child(name_field)
	palette_controls = Control.new()
	palette_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(palette_controls)
	add_choice(palette_controls,"Coat","coat",Look.COATS,Vector2(45,373))
	add_choice(palette_controls,"Markings","markings",Look.MARKINGS,Vector2(313,373))
	add_choice(palette_controls,"Eyes","eyes",Look.EYES,Vector2(45,477))
	add_choice(palette_controls,"Scarf","scarf",Look.SCARVES,Vector2(313,477))
	dog_look = UI.text(sheet,"Original spaniel\nGolden coat · Amber eyes · Crimson scarf",Vector2(45,389),516,20,UI.MUTED)
	UI.text(sheet,"Your look travels with you through Mosswood and the Greenshire.",Vector2(45,605),520,18,UI.MUTED)

	var portrait := UI.panel(sheet,Vector2(601,145),Vector2(595,517),true)
	UI.text(portrait,"LIVE PREVIEW",Vector2(25,23),450,15,Color("e3c88f"))
	preview = Node2D.new()
	preview.position = Vector2(298,417)
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	portrait.add_child(preview)
	preview.draw.connect(draw_preview)
	actor = Motion.new()
	preview.add_child(actor)
	actor.configure("cat",285)
	for index in 5:
		var button := UI.button(portrait,["Front","Back","Walk","Run","Frog ride"][index],Vector2(24+index*111,452),Vector2(103,42))
		button.pressed.connect(func():
			preview_mode = index as Preview
			update_preview())
		preview_buttons.append(button)
	var back := UI.button(sheet,"Back",Vector2(45,701),Vector2(248,59))
	back.pressed.connect(func(): cancelled.emit())
	var start := UI.button(sheet,"Begin journey",Vector2(900,701),Vector2(296,59))
	start.pressed.connect(submit)
	update_preview()
	hide()

func add_choice(parent: Control, label: String, key: String, values: Array, at: Vector2) -> void:
	UI.text(parent,label.to_upper(),at,248,14,UI.MUTED)
	var choice := OptionButton.new()
	choice.position = at+Vector2(0,26)
	choice.size = Vector2(248,48)
	choice.add_theme_font_size_override("font_size",18)
	choice.add_theme_stylebox_override("normal",UI.style(true))
	for value in values:
		choice.add_item(value)
	choice.item_selected.connect(func(index: int):
		appearance[key] = index
		update_preview())
	parent.add_child(choice)
	choices[key] = choice

func open() -> void:
	appearance = Look.DEFAULT.duplicate()
	name_field.text = ""
	for choice: OptionButton in choices.values():
		choice.select(0)
	preview_mode = Preview.FRONT
	update_preview()
	show()
	species_buttons[0].grab_focus()

func submit() -> void:
	var entered := name_field.text.strip_edges()
	appearance.name = Look.DEFAULT.name if entered.is_empty() else entered
	if Look.valid(appearance):
		accepted.emit(Look.normalized(appearance))

func update_preview() -> void:
	for index in species_buttons.size():
		species_buttons[index].add_theme_stylebox_override("normal",UI.style(true,Look.SPECIES[index].to_lower()==appearance.species))
	for index in preview_buttons.size():
		preview_buttons[index].add_theme_stylebox_override("normal",UI.style(true,index==preview_mode))
	var look := Look.normalized(appearance)
	palette_controls.visible = look.species=="cat"
	dog_look.visible = not palette_controls.visible
	actor.set_appearance(look)
	actor.visible = preview_mode!=Preview.FROG
	var direction := ["s","n","se","se","se"][preview_mode] as String
	actor.heading_angle = actor.DIRECTIONS.find(direction)*PI/4
	actor.set_pose("idle",direction,0)
	if preview_mode==Preview.FROG:
		if rider==null:
			rider = Rider.new()
			rider.direction_index = 3
		rider.set_appearance(look)
	preview.queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	if preview_mode==Preview.FROG:
		rider.step(delta,delta*8.0)
		preview.queue_redraw()
	else:
		var direction := Vector2.DOWN if preview_mode==Preview.FRONT else (Vector2.UP if preview_mode==Preview.BACK else Vector2.ONE.normalized())
		var speed: float = 118.0 if preview_mode==Preview.WALK else (280.0*actor.display_height/108.0 if preview_mode==Preview.RUN else 0.0)
		actor.tick(delta,delta*speed,direction,preview_mode==Preview.RUN)

func draw_preview() -> void:
	if preview_mode==Preview.FROG:
		rider.draw(preview,Vector2.ZERO,1.64)
	else:
		preview.draw_set_transform(Vector2(0,-5),0,Vector2(72,14))
		preview.draw_circle(Vector2.ZERO,1,Color(.07,.13,.11,.48),true,-1,true)
		preview.draw_set_transform(Vector2.ZERO)
