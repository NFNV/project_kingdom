extends Node2D

const ART := "res://experiments/anime_hub_assets_v08_humans/"
const DISPLAY_SCALE := 0.65
const Actor := preload("res://experiments/anime_hub_demo_v07/tools/actor.gd")
var hub: Node2D
var asset := "human_wayfarer"
var resident_id := ""
var data: Dictionary
var sprite: AnimatedSprite2D
var height := 172.0
var facing_direction := "sw"
var idle_clock := 0.0
var greeting_left := 0.0
var greeting_count := 0
var base_scale := 1.0


func _ready() -> void:
	height = float(data.recommended_height_at_1080p)*DISPLAY_SCALE
	idle_clock = float(absi(hash(resident_id))%100)*.11
	sprite = AnimatedSprite2D.new()
	sprite.material = preload("res://experiments/anime_hub_demo_v07/tools/art_style.gd").character_material()
	sprite.sprite_frames = load(ART+data.native_frames)
	sprite.centered = false
	sprite.offset = Vector2(-512,-984)
	sprite.speed_scale = 0
	add_child(sprite)
	_pose()
	queue_redraw()


func _process(delta: float) -> void:
	if hub.paused or hub.transitioning:
		return
	idle_clock += delta
	greeting_left = maxf(0,greeting_left-delta)
	if is_instance_valid(hub.player):
		var toward := Actor.ground_vector(hub.player.global_position-global_position)
		if toward.length()<220:
			face_towards(toward)
	_pose()


func face_towards(toward: Vector2) -> void:
	# Keep the current side close to either axis, so a nearby cat cannot cause
	# rapid front/back or left/right switches. Use actual views, never mirroring.
	var right := facing_direction in ["se","ne"]
	var down := facing_direction in ["se","sw"]
	if absf(toward.x)>18:
		right = toward.x>0
	if absf(toward.y)>18:
		down = toward.y>0
	facing_direction = ("se" if right else "sw") if down else ("ne" if right else "nw")


func greet() -> void:
	greeting_count += 1
	greeting_left = .55
	if is_instance_valid(hub.player):
		face_towards(Actor.ground_vector(hub.player.global_position-global_position))
	_pose()


func _pose() -> void:
	sprite.animation = "idle_"+facing_direction
	sprite.frame = 0
	base_scale = height/float(data.frames[facing_direction].height)
	var breath := sin(idle_clock*TAU/5.0)
	var nod := sin(PI*clampf(1.0-greeting_left/.55,0,1))*.008 if greeting_left>0 else 0.0
	# The source atlas ground anchor stays fixed as the torso gently rises/falls.
	sprite.scale = Vector2(1.0-breath*.0015+nod*.15,1.0+breath*.003-nod)*base_scale


func _draw() -> void:
	draw_set_transform(Vector2(0,-2),0,Vector2(1,.32))
	draw_circle(Vector2.ZERO,24*DISPLAY_SCALE,Color(.09,.13,.13,.22))
