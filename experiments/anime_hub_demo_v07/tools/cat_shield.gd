extends Node2D
## The equipped offhand follows the existing eight drawn facings.
var actor: CharacterBody2D
var image: Sprite2D
var equipped := ""

func _ready() -> void:
	image = Sprite2D.new()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(image)
	sync_pose()

func sync_pose() -> void:
	var id: String = actor.hub.state.equipped_id("shield")
	visible = actor.active and id!="" and actor.swing<=0 and actor.roll_left<=0
	if not visible: return
	if equipped!=id:
		equipped = id
		image.texture = load("res://experiments/anime_hub_demo_v07/assets/items/"+id+".svg")
	var heading: Vector2 = Vector2(actor.facing.x,actor.facing.y*.65).normalized()
	var side := Vector2(-heading.y,heading.x)
	position = Vector2(0,-35)+heading*(13 if actor.guarding else 1)+side*7
	z_index = -1 if heading.y<-.2 else 1
	image.scale = Vector2(.105+.035*absf(heading.y),.14)
	image.rotation = -.12*heading.x if actor.guarding else .15*heading.x
	image.modulate = actor.hub.actor_tint.lerp(Color("c7fff0"),.5 if actor.guarding and actor.guard_age<=actor.PARRY_WINDOW else 0)
