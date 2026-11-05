extends Node2D
## The equipped offhand follows the existing eight drawn facings.
var actor: CharacterBody2D
var image: Sprite2D
var equipped := ""
const Pose := preload("res://experiments/anime_hub_demo_v07/tools/equipment_pose.gd")
const HEIGHT_SCALE := .127
var hand_anchor := Vector2.ZERO
var pose_key := ""

func _ready() -> void:
	image = Sprite2D.new()
	image.scale = Vector2(.109,HEIGHT_SCALE)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(image)
	sync_pose()

func sync_pose() -> void:
	var id: String = actor.hub.state.equipped_id("shield")
	var facing: String = actor.sprite.facing_direction
	var view_id := id+("_back" if facing in ["nw","n","ne"] else "")
	var was_visible := visible
	visible = actor.is_in_combat() and id!="" and actor.swing<=0 and actor.roll_left<=0
	if id!="" and equipped!=view_id:
		equipped = view_id
		image.texture = load("res://experiments/anime_hub_demo_v07/assets/items/"+view_id+".svg")
	if not visible: return
	var factor: float = actor.sprite.display_height/73.0
	hand_anchor = Pose.hand(actor,"shield")
	position = hand_anchor+Vector2(0,-4 if actor.guarding else -1)*factor
	# A buckler rests below the muzzle, even in the low running poses.
	position.y = maxf(position.y,Pose.face_bottom(actor)+(128*HEIGHT_SCALE+2)*factor)
	Pose.order(actor,self,facing in ["n","ne"] or not Pose.measured(actor,"shield"))
	image.scale = Vector2(.075 if facing in ["e","w"] else .109,HEIGHT_SCALE)*factor
	image.rotation = 0
	image.modulate = actor.sprite.modulate.lerp(Color("c7fff0"),.5 if actor.guarding and actor.guard_age<=actor.PARRY_WINDOW else 0)
	var key: String = actor.sprite.animation+"/"+str(actor.sprite.frame)
	if not was_visible or key!=pose_key: reset_physics_interpolation()
	pose_key = key
