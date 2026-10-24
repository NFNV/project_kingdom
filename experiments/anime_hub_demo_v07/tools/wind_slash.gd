extends Node2D

var hub: Node2D
var heading := Vector2.RIGHT
var travelled := 0.0
var hit_ids: Dictionary = {}
const SPEED := 760.0
const REACH := 520.0


func _ready() -> void:
	add_to_group("wind_slashes")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func _physics_process(delta: float) -> void:
	if hub.transitioning or hub.zone!="wilds":
		queue_free()
		return
	if hub.paused:
		return
	var step := minf(SPEED*delta,REACH-travelled)
	var next := position+Vector2(heading.x,heading.y*.65)*step
	var ray := PhysicsRayQueryParameters2D.create(position,next,1)
	var obstruction := get_world_2d().direct_space_state.intersect_ray(ray)
	if not obstruction.is_empty():
		next = obstruction.position
	var end := Vector2(next.x-position.x,(next.y-position.y)/.65)
	for dog in hub.dogs:
		if not dog.active or hit_ids.has(dog.get_instance_id()):
			continue
		var relative := Vector2(dog.position.x-position.x,(dog.position.y-position.y)/.65)
		var nearest := Geometry2D.get_closest_point_to_segment(relative,Vector2.ZERO,end)
		if relative.distance_to(nearest)<=30 and hub.clear_line(position,dog.position):
			hit_ids[dog.get_instance_id()] = true
			dog.receive_hit(heading,3,310.0)
	position = next
	travelled += step
	if travelled>=REACH or not obstruction.is_empty() or hit_ids.size()>=3:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var alpha := minf(1.0,(REACH-travelled)/70.0)
	draw_set_transform(Vector2(0,-29),atan2(heading.y*.65,heading.x),Vector2(1,.75))
	draw_colored_polygon(PackedVector2Array([Vector2(-95,0),Vector2(-15,-24),Vector2(15,0),Vector2(-15,24)]),Color(.25,.8,1,.23*alpha))
	draw_arc(Vector2(-8,0),39,-1.45,1.45,32,Color(.3,.8,1,.18*alpha),22,true)
	draw_arc(Vector2(-8,0),39,-1.35,1.35,32,Color(.55,.95,1,.85*alpha),8,true)
	draw_arc(Vector2(-5,0),40,-1.25,1.25,32,Color(1,.98,.76,alpha),2.2,true)
	for i in 5:
		var phase := travelled*.04+i*1.37
		draw_circle(Vector2(-20-i*11,sin(phase)*20),1.8,Color(.7,1,1,.65*alpha))
