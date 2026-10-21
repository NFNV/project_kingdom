class_name KingdomMelee
extends Node2D

# Gameplay timing is independent of the placeholder sprite's animation frames.
@export var reach: float = 90.0
@export var damage: int = 1
@export var windup: float = 0.18
@export var active_time: float = 0.13
@export var duration: float = 0.44
@export var recovery: float = 0.12

var direction: Vector2 = Vector2.RIGHT
var elapsed: float = 0.0
var cooldown: float = 0.0
var attacking: bool = false
var hit_targets: Array[int] = []
@onready var actor: KingdomActor = get_parent() as KingdomActor


func try_start(aim: Vector2) -> bool:
	if attacking or cooldown > 0.0 or actor.health.is_dead() or actor.stun_time > 0.0:
		return false
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	elapsed = 0.0
	attacking = true
	hit_targets.clear()
	return true


func advance(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if not attacking:
		return
	elapsed += delta
	if elapsed >= windup and elapsed < windup + active_time:
		_resolve_hits()
	if elapsed >= duration:
		attacking = false
		cooldown = recovery
	queue_redraw()


func cancel() -> void:
	attacking = false
	cooldown = recovery
	queue_redraw()


func _resolve_hits() -> void:
	var shape := CircleShape2D.new()
	shape.radius = reach
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, actor.global_position + Vector2(0, -12))
	query.collision_mask = 2
	query.exclude = [actor.get_rid()]
	var space := get_world_2d().direct_space_state
	for result in space.intersect_shape(query, 32):
		var target := result["collider"] as KingdomActor
		if target == null or target.faction == actor.faction or target.health.is_dead():
			continue
		if target.get_instance_id() in hit_targets:
			continue
		var offset := target.global_position - actor.global_position
		if not offset.is_zero_approx() and direction.dot(offset.normalized()) < 0.25:
			continue
		# A sword cannot damage through a tree trunk or the keep's footprint.
		var ray := PhysicsRayQueryParameters2D.create(
			actor.global_position + Vector2(0, -12),
			target.global_position + Vector2(0, -12), 1)
		if not space.intersect_ray(ray).is_empty():
			continue
		hit_targets.append(target.get_instance_id())
		target.receive_hit(damage, offset.normalized())


func _draw() -> void:
	if not attacking:
		return
	var center := Vector2(0, -28)
	var angle := direction.angle()
	if elapsed < windup:
		if actor.hostile:
			draw_arc(center, reach, angle - 1.05, angle + 1.05, 18,
				Color(1.0, 0.39, 0.29, 0.3), 3.0)
		return
	if elapsed > windup + active_time + 0.04:
		return
	var tint := Color(0.79, 0.94, 1.0, 0.85)
	if actor.faction == KingdomActor.Faction.CAT:
		tint = Color(1.0, 0.78, 0.53, 0.85)
	draw_arc(center, reach * 0.78, angle - 1.05, angle + 1.05, 20, tint, 6.0)
	draw_arc(center, reach * 0.91, angle - 0.8, angle + 0.9, 20,
		Color(1, 1, 0.88, 0.8), 2.0)
