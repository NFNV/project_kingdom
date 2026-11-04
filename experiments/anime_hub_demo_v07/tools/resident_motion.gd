extends Node2D

const Motion := preload("res://experiments/anime_hub_demo_v07/tools/motion_sprite.gd")
var hub: Node2D
var asset := "cat_baker"
var resident_id := ""
var height := 108.0
var sprite: AnimatedSprite2D
var gesture_wait := 5.0
var stops := PackedVector2Array()
var route := PackedVector2Array()
var stop_index := 0
var rest_left := 0.0
var stride := 0.0
var in_square := true


func _ready() -> void:
	var seed_phase := float(absi(hash(resident_id))%100)*.13
	gesture_wait = 4.0+fmod(seed_phase,6)
	sprite = Motion.new()
	add_child(sprite)
	sprite.configure(asset,height,seed_phase)


func _process(delta: float) -> void:
	if hub.paused or hub.transitioning:
		return
	if not in_square:
		return
	var distance := _stroll(delta)
	if distance > 0:
		stride = fposmod(stride + distance / 24.0, 1.0)
		sprite.position.y = -absf(sin(stride * TAU)) * 2.2
		sprite.rotation = sin(stride * TAU) * 0.032
		sprite.gesture_clock = -1
		sprite.tick(delta, 0.0, Vector2.ZERO)
		return
	sprite.position.y = move_toward(sprite.position.y, 0.0, delta * 20.0)
	sprite.rotation = move_toward(sprite.rotation, 0.0, delta * 0.35)
	gesture_wait -= delta
	if gesture_wait<=0:
		greet()
		gesture_wait = 8.0+float(absi(hash(resident_id))%50)*.1
	sprite.tick(delta,0.0,Vector2.ZERO)


func greet() -> void:
	sprite.greet()
	gesture_wait = 9.0


func face_towards(customer_position: Vector2) -> void:
	# These civilian sheets show a front-right view. Mirroring the sprite keeps
	# every idle/greeting frame facing the customer without moving its anchor.
	sprite.flip_h = customer_position.x < position.x


func _stroll(delta: float) -> float:
	if stops.is_empty() or hub.shopping or (hub.dialogue_left > 0 and hub.conversation_actor == resident_id):
		return 0.0
	rest_left -= delta
	if rest_left > 0:
		return 0.0
	if route.is_empty():
		stop_index = (stop_index + 1) % stops.size()
		route = hub.find_path(position, stops[stop_index])
		if route.is_empty():
			rest_left = 2.0
			return 0.0
	var target := route[0]
	var step := position.move_toward(target, 58.0 * delta)
	var distance := position.distance_to(step)
	if absf(step.x - position.x) > 0.05:
		face_towards(target)
	position = step
	if position.is_equal_approx(target):
		route.remove_at(0)
		if route.is_empty():
			rest_left = 2.5 + float(absi(hash(resident_id)) % 18) * 0.15
	return distance
