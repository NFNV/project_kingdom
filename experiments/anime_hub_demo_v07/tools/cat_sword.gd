extends Node2D

# The drawn attack already includes its blade; this rig carries it between
# attacks during the ten-second combat stance. Coordinates
# are in ground/world pixels so changing a pose never changes blade proportions.
const Pose := preload("res://experiments/anime_hub_demo_v07/tools/equipment_pose.gd")
var actor: CharacterBody2D
var hand_anchor := Vector2.ZERO
var near_hand := false
var pose_key := ""


func sync_pose() -> void:
	var facing: String = actor.sprite.facing_direction
	var was_visible := visible
	var dog: bool = actor.sprite.is_dog()
	var dog_attack: bool = dog and actor.swing>0
	visible = actor.is_in_combat() and actor.hub.state.equipped_id("weapon")!="" and (actor.swing<=0 or dog_attack) and actor.roll_left<=0
	if not visible: return
	# A relaxed low carry keeps the blade outside the face as an arm swings
	# across the chest. The separate attack art raises it for an actual strike.
	rotation = 2.0 if facing in ["n","ne"] else -2.0
	if facing=="nw":
		# Keep the grip behind the far arm and show the blade above the tail.
		rotation = 1.35
	scale = Vector2.ONE*actor.sprite.display_height/73.0*.82
	hand_anchor = actor.combat_art.dog_grip if dog_attack else Pose.hand(actor,"weapon")
	if dog_attack:
		rotation = actor.combat_art.dog_blade_angle
	position = hand_anchor-Vector2(0,-2).rotated(rotation)*scale
	near_hand = not dog and facing in ["e","se","s","ne"] and Pose.measured(actor,"weapon")
	var in_front: bool = actor.combat_art.dog_weapon_in_front if dog_attack else (facing not in ["n","nw"] if dog else near_hand)
	if dog_attack and not in_front:
		if get_index()>actor.combat_art.get_index():
			actor.move_child(self,actor.combat_art.get_index())
	else:
		Pose.order(actor,self,not in_front)
	modulate = actor.sprite.modulate
	var key: String = "attack/"+actor.combat_art.current_direction+"/"+str(actor.combat_art.current_pose) if dog_attack else actor.sprite.animation+"/"+str(actor.sprite.frame)
	if not was_visible or key!=pose_key: reset_physics_interpolation()
	pose_key = key
	queue_redraw()


func _draw() -> void:
	# Silhouette outline, cool steel facets, a brass crossguard and leather grip.
	draw_colored_polygon(PackedVector2Array([Vector2(-4,-9),Vector2(-4,-33),Vector2(0,-42),Vector2(4,-33),Vector2(4,-9)]),Color("283f46"))
	draw_colored_polygon(PackedVector2Array([Vector2(-2.5,-10),Vector2(-2.5,-32),Vector2(0,-38),Vector2(0,-10)]),Color("edf8ed"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-10),Vector2(0,-38),Vector2(2.5,-32),Vector2(2.5,-10)]),Color("8bb3c0"))
	draw_line(Vector2(-1,-29),Vector2(-1,-14),Color("ffffff"),.8,true)
	draw_line(Vector2(-7,-9),Vector2(7,-9),Color("35413a"),5,true)
	draw_line(Vector2(-6,-10),Vector2(6,-10),Color("e7bf66"),2.5,true)
	draw_line(Vector2(0,-7),Vector2(0,3),Color("4c3b2c"),4,true)
	for y in [-5,-2,1]:
		draw_line(Vector2(-1.5,y),Vector2(1.5,y-1),Color("ac8350"),1,true)
	draw_circle(Vector2(0,3),1.7,Color("a98552"),true,-1,true)
	draw_circle(Vector2(0,-10),2,Color("466e83"))
	if near_hand:
		# Reuse the actual drawn paw over the handle. This is a native texture
		# region, with the same registration transform, not an invented paw.
		var sprite: AnimatedSprite2D = actor.sprite
		var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame) as AtlasTexture
		var point: Vector2 = sprite.transform.affine_inverse()*hand_anchor-texture.margin.position-sprite.offset
		var radius := Vector2(10,10)
		draw_set_transform_matrix(transform.affine_inverse()*sprite.transform)
		draw_texture_rect_region(texture.atlas,Rect2(point-radius+texture.margin.position+sprite.offset,radius*2),Rect2(texture.region.position+point-radius,radius*2))
		draw_set_transform_matrix(Transform2D.IDENTITY)
