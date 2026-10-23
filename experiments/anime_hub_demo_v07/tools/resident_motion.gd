extends Node2D

const Motion := preload("res://experiments/anime_hub_demo_v07/tools/motion_sprite.gd")
var hub: Node2D
var asset := "cat_baker"
var resident_id := ""
var height := 108.0
var sprite: AnimatedSprite2D
var gesture_wait := 5.0


func _ready() -> void:
	var seed_phase := float(absi(hash(resident_id))%100)*.13
	gesture_wait = 4.0+fmod(seed_phase,6)
	sprite = Motion.new()
	add_child(sprite)
	sprite.configure(asset,height,seed_phase)


func _process(delta: float) -> void:
	if hub.paused or hub.transitioning:
		return
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
