class_name KingdomEnemyController
extends Node

enum State { PATROL, CHASE, RETURN }

var target: KingdomActor
var map: KingdomMap
var home: Vector2
var patrol_end: Vector2
var state: State = State.PATROL
var patrol_forward: bool = true
var path: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var repath_time: float = 0.0
var rest_time: float = 0.0
var chase_distance: float = 295.0
var leash_distance: float = 470.0
@onready var actor: KingdomActor = get_parent() as KingdomActor


func _physics_process(delta: float) -> void:
	actor.move_intent = Vector2.ZERO
	if actor.health.is_dead() or target == null or not is_instance_valid(target):
		return
	if target.health.is_dead() or actor.stun_time > 0.0:
		return
	var distance := actor.global_position.distance_to(target.global_position)
	var near_home := target.global_position.distance_to(home) < leash_distance
	if state != State.CHASE and distance < chase_distance and near_home:
		state = State.CHASE
		repath_time = 0.0
	if state == State.CHASE and (distance > chase_distance * 1.7 or not near_home):
		state = State.RETURN
		repath_time = 0.0
	actor.alert = state == State.CHASE
	if actor.melee.attacking:
		return
	var destination := home
	var speed_factor := 1.0
	match state:
		State.CHASE:
			if distance < 68.0:
				actor.try_attack(target.global_position - actor.global_position)
				return
			destination = target.global_position
		State.RETURN:
			if actor.global_position.distance_to(home) < 20.0:
				state = State.PATROL
				return
		State.PATROL:
			speed_factor = 0.45
			rest_time = maxf(0.0, rest_time - delta)
			if rest_time > 0.0:
				return
			destination = patrol_end if patrol_forward else home
			if actor.global_position.distance_to(destination) < 20.0:
				patrol_forward = not patrol_forward
				rest_time = 1.3
				repath_time = 0.0
				return
	repath_time -= delta
	if repath_time <= 0.0:
		path = map.find_path(actor.global_position, destination) if map != null else PackedVector2Array([destination])
		path_index = 0
		repath_time = 0.4
	while path_index < path.size() and actor.global_position.distance_to(path[path_index]) < 18.0:
		path_index += 1
	if path_index < path.size():
		actor.move_intent = actor.global_position.direction_to(path[path_index]) * speed_factor
