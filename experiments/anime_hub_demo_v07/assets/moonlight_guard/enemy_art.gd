@tool
extends Node2D
## Reusable presentation only. AI, hitboxes and rewards belong to the encounter.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/moonlight_guard/"
@export_enum("ashen_vanguard","briar_spearman","gloam_arbalist","blackthorn_captain") var archetype := "ashen_vanguard":
	set(value):
		archetype = value
		if is_inside_tree(): refresh()
@export_range(30,500) var display_height := 90.0:
	set(value):
		display_height = value
		if is_inside_tree(): refresh()
@export_enum("se","sw","ne","nw") var facing := "se":
	set(value):
		facing = value
		if is_inside_tree(): sync_animation()
@export_enum("idle","walk","attack","windup","strike","recover","hurt") var action := "idle":
	set(value):
		action = value
		if is_inside_tree(): sync_animation()
var art: AnimatedSprite2D

func _ready() -> void:
	art = AnimatedSprite2D.new()
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.centered = false
	add_child(art)
	refresh()

func refresh() -> void:
	if not is_instance_valid(art): return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+archetype+"_catalog.json"))
	art.sprite_frames = load(ROOT+archetype+"_frames.tres")
	art.offset = Vector2(-float(data.canvas[0])*.5,-float(data.foot_line))
	art.scale = Vector2.ONE*display_height/float(data.reference_height)
	play_action(action,facing)

func play_action(next_action: String, heading := "") -> void:
	action = next_action
	if not heading.is_empty(): facing = heading
	sync_animation()

func sync_animation() -> void:
	if is_instance_valid(art) and art.sprite_frames.has_animation(action+"_"+facing):
		if not art.is_playing(): art.set_frame_and_progress(0,0)
		art.play(action+"_"+facing)
