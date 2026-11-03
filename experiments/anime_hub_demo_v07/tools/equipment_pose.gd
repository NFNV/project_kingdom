extends RefCounted
## Source-region paw coordinates are projected through the actual drawn frame.
const PATH := "res://experiments/anime_hub_demo_v07/assets/motion/equipment_grips.json"
static var poses: Dictionary = {}

static func hand(actor: CharacterBody2D, slot: String) -> Vector2:
	if poses.is_empty():
		poses = JSON.parse_string(FileAccess.get_file_as_string(PATH)).directions
	var sprite: AnimatedSprite2D = actor.sprite
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame) as AtlasTexture
	var state: String = sprite.state
	var data: Dictionary = poses[sprite.facing_direction][state][sprite.frame][slot]
	var point := Vector2(data.point[0],data.point[1])
	# Includes frame-specific scaling, registration, run lean and gait bob.
	return sprite.transform*(point+texture.margin.position+sprite.offset)

static func order(actor: CharacterBody2D, item: Node2D, behind: bool) -> void:
	# Keep equipment in the actor's y-sort group. Negative z_index would put
	# it behind other world objects rather than just behind its own body.
	item.z_index = 0
	item.show_behind_parent = false
	var body_index: int = actor.sprite.get_index()
	if behind:
		if item.get_index()>body_index: actor.move_child(item,body_index)
	elif item.get_index()!=actor.get_child_count()-1:
		actor.move_child(item,-1)

static func measured(actor: CharacterBody2D, slot: String) -> bool:
	return poses[actor.sprite.facing_direction][actor.sprite.state][actor.sprite.frame][slot].measured

static func face_bottom(actor: CharacterBody2D) -> float:
	var sprite: AnimatedSprite2D = actor.sprite
	var registration: Dictionary = sprite.metadata[sprite.facing_direction].body_registration[sprite.state]
	var width: float = registration.poses[sprite.frame].head_width*sprite.scale.x
	return sprite.body_origin.y+width*.62
