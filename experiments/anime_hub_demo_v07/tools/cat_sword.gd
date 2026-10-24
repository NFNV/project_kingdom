extends Node2D

# Carrying rig only; drawn combat poses contain the actual held sword. Coordinates
# are in ground/world pixels so changing a pose never changes blade proportions.
const GRIPS := {
	"e":Vector2(16,-28),"se":Vector2(15,-27),"s":Vector2(-12,-27),
	"sw":Vector2(-16,-28),"w":Vector2(-17,-29),"nw":Vector2(-11,-32),
	"n":Vector2(12,-32),"ne":Vector2(16,-31)
}
var actor: CharacterBody2D


func sync_pose() -> void:
	var facing: String = actor.sprite.facing_direction
	position = GRIPS[facing]*actor.sprite.display_height/73.0
	rotation = -.42 if facing in ["s","sw","w","nw"] else .42
	show_behind_parent = facing in ["nw","n","ne"]

	modulate = actor.sprite.modulate
	visible = actor.active
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
	draw_circle(Vector2(0,4),3,Color("d8af5c"))
	draw_circle(Vector2(0,-10),2,Color("466e83"))
	# A small paw covers the grip, tying the equipment to the drawn character.
	draw_circle(Vector2(0,-2),3.1,Color("dfaa62"))
	draw_circle(Vector2(-.7,-3),1.7,Color("f4cf8f"))
