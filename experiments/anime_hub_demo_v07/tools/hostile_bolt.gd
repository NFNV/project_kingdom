extends Node2D
## Reusable ranged attack. Uses the same half-heart, guard and roll pipeline.
var hub: Node2D
var source: Node2D
var heading := Vector2.RIGHT
var travelled := 0.0
var damage := 1
const SPEED := 370.0
const REACH := 650.0

func _ready() -> void:
	add_to_group("hostile_bolts")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON

func _physics_process(delta: float) -> void:
	if hub.transitioning or not is_instance_valid(source) or not source.active or not hub.player.active:
		queue_free()
		return
	if hub.paused: return
	var step := minf(SPEED*delta,REACH-travelled)
	var next := position+Vector2(heading.x,heading.y*.65)*step
	var ray := PhysicsRayQueryParameters2D.create(get_parent().to_global(position),get_parent().to_global(next),1)
	var wall := get_world_2d().direct_space_state.intersect_ray(ray)
	if not wall.is_empty(): next = get_parent().to_local(wall.position)
	var segment := Vector2(next.x-position.x,(next.y-position.y)/.65)
	var relative := Vector2(hub.player.position.x-position.x,(hub.player.position.y-position.y)/.65)
	if relative.distance_to(Geometry2D.get_closest_point_to_segment(relative,Vector2.ZERO,segment))<=18 and hub.clear_line(position,hub.player.position):
		hub.player.receive_hit(heading,damage,100.0,source)
		queue_free()
	position = next
	travelled += step
	if travelled>=REACH or not wall.is_empty(): queue_free()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0,-25),atan2(heading.y*.65,heading.x))
	draw_line(Vector2(-19,0),Vector2(7,0),Color("b9a886"),2.5,true)
	draw_colored_polygon(PackedVector2Array([Vector2(13,0),Vector2(4,-3),Vector2(4,3)]),Color("e4e9dc"))
	draw_line(Vector2(-18,-4),Vector2(-12,0),Color("916e9f"),2,true)
