@tool
extends Node2D
## Show the relevant painting while editing the room's placement markers.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/moonlight/"
const BACKGROUNDS := {"moonlight_forest":"forest_crossing.png","moonlight_passage":"castle_passage_v02.png","moonlight_cistern":"undercroft.png","moonlight_chapel":"chapel.png"}
const DETAIL_PREVIEWS := {"DetailPreview":"moonlight_forest","PassageDetailPreview":"moonlight_passage","CisternDetailPreview":"moonlight_cistern","ChapelDetailPreview":"moonlight_chapel"}
@export_enum("moonlight_forest","moonlight_passage","moonlight_cistern","moonlight_chapel") var preview_zone := "moonlight_forest":
	set(value):
		preview_zone = value
		if is_inside_tree(): show_room()
		queue_redraw()

func _ready() -> void:
	if Engine.is_editor_hint():
		var detail := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
		detail.name = "DetailPreview"
		add_child(detail)
		var passage := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
		passage.name = "PassageDetailPreview"
		passage.panel_root = ROOT+"passage_panels_v02/"
		add_child(passage)
		var cistern := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
		cistern.name = "CisternDetailPreview"
		cistern.panel_root = ROOT+"cistern_panels/"
		cistern.animate_water = true
		cistern.door_open = false
		add_child(cistern)
		var chapel := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
		chapel.name = "ChapelDetailPreview"
		chapel.panel_root = ROOT+"chapel_panels/"
		add_child(chapel)
		show_room()

func show_room() -> void:
	for room in get_children():
		room.visible = room.name==preview_zone or DETAIL_PREVIEWS.get(String(room.name),"")==preview_zone

func _draw() -> void:
	if not Engine.is_editor_hint(): return
	var texture: Texture2D = load(ROOT+BACKGROUNDS[preview_zone])
	draw_texture_rect(texture,Rect2(0,0,3072,1728),false)
