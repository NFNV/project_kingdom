@tool
extends Node2D
## Native-detail panels overlap in world space instead of stretching one plate.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/moonlight/panels/"
const PANEL_SIZE := Vector2(1152,648)
const STEP := Vector2(1024,576)
const MARGIN := Vector2(64,36)
const BLEND := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/panel_blend.gdshader")
var panel_root := ROOT
var animate_water := false
var door_open := true
var door_panel: Sprite2D

func _ready() -> void:
 for row in 3:
  for column in 3:
   var panel := Sprite2D.new()
   panel.texture = load(panel_root+"%d_%d.png" % [row,column])
   panel.centered = false
   panel.position = Vector2(column,row)*STEP-MARGIN
   panel.scale = PANEL_SIZE/panel.texture.get_size()
   var blend := ShaderMaterial.new()
   blend.shader = BLEND
   blend.set_shader_parameter("animate_water",animate_water)
   blend.set_shader_parameter("panel_origin",panel.position)
   panel.material = blend
   panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
   add_child(panel)
   if animate_water and row==0 and column==1: door_panel = panel
 set_door_open(door_open)

func set_door_open(opened: bool) -> void:
 door_open = opened
 if is_instance_valid(door_panel):
  door_panel.texture = load(panel_root+("0_1.png" if opened else "chapel_closed.png"))
