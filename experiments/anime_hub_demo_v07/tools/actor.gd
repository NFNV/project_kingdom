extends CharacterBody2D

const ART := "res://experiments/anime_hub_assets_v06/"
const GROUND_Y := 0.65
var hub: Node2D
var controlled := false
var enemy := false
var active := true
var sprite: AnimatedSprite2D
var facing := Vector2(1,1).normalized()
var intent := Vector2.ZERO
var route := PackedVector2Array()
var health := 5
var maximum_health := 5
var grace := 0.0
var cooldown := 0.0
var swing := 0.0
var windup := 0.0
var flash := 0.0
var knockback := Vector2.ZERO
var path_timer := 0.0
var swing_hits: Array = []
var direction := "se"
var automated := false


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0
	shape.shape = circle
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	var id := "cat_adventurer" if controlled else "dog_warden"
	sprite.sprite_frames = load(ART+"godot/"+id+"_frames.tres")
	var frame = hub.catalog[id]["sheet"]["frame_canvas"]
	sprite.centered = false
	sprite.offset = Vector2(-float(frame[0])/2.0,-float(frame[1])+24.0)
	sprite.scale = Vector2.ONE*108.0/(float(frame[1])-48.0)
	add_child(sprite)
	sprite.play("idle_se")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	queue_redraw()


static func ground_vector(vector: Vector2) -> Vector2:
	return Vector2(vector.x,vector.y/GROUND_Y)


func _physics_process(delta: float) -> void:
	if hub.paused or hub.shopping or hub.transitioning or not active:
		return
	grace = maxf(0,grace-delta)
	cooldown = maxf(0,cooldown-delta)
	flash = maxf(0,flash-delta*4)
	knockback = knockback.move_toward(Vector2.ZERO,1000*delta)
	if controlled:
		if not automated:
			intent = Input.get_vector("hub_left","hub_right","hub_up","hub_down")
			if intent.length()>0.1:
				route.clear()
			elif not route.is_empty():
				intent = follow_route()
			if Input.is_action_pressed("hub_attack"):
				try_attack()
	else:
		intent = _enemy_intent(delta)
	if intent.length()>0.05 and windup<=0 and swing<=0:
		facing = intent.normalized()
	var speed := 215.0 if controlled else 118.0
	if controlled and Input.is_action_pressed("hub_run"):
		speed = 325.0
	if swing>0 or windup>0:
		speed *= 0.2
	velocity = Vector2(intent.x,intent.y*GROUND_Y)*speed+knockback
	move_and_slide()
	if windup>0:
		windup -= delta
		if windup<=0:
			try_attack()
	if swing>0:
		swing = maxf(0,swing-delta)
		if swing<0.22:
			resolve_hits()
	_update_animation(intent.length()>0.05 and swing<=0 and windup<=0)
	var tint: Color = hub.actor_tint
	sprite.modulate = tint.lerp(Color(1.0,0.4,0.3),flash)
	if grace>0 and controlled:
		sprite.modulate.a = 0.55 if int(grace*14)%2==0 else 1.0
	queue_redraw()


func follow_route() -> Vector2:
	while not route.is_empty() and position.distance_to(route[0])<12:
		route.remove_at(0)
	if route.is_empty():
		return Vector2.ZERO
	return ground_vector(route[0]-position).normalized()


func _enemy_intent(delta: float) -> Vector2:
	if hub.peaceful_mode:
		windup = 0
		return Vector2.ZERO
	if not enemy or not hub.combat_active or not hub.player.active:
		return Vector2.ZERO
	var offset: Vector2 = hub.player.position-position
	if ground_vector(offset).length()<88 and hub.clear_line(position,hub.player.position):
		if cooldown<=0 and windup<=0 and swing<=0:
			facing = ground_vector(offset).normalized()
			windup = 0.70
		return Vector2.ZERO
	if windup>0:
		return Vector2.ZERO
	path_timer -= delta
	if path_timer<=0:
		path_timer = 0.35
		route = hub.find_path(position,hub.player.position)
	return follow_route()


func try_attack(aim := Vector2.ZERO) -> bool:
	if hub.peaceful_mode:
		return false
	if not active or hub.paused or cooldown>0 or swing>0:
		return false
	if not controlled and not enemy:
		return false
	if aim.length()>0.1:
		facing = ground_vector(aim).normalized()
	swing = 0.32
	cooldown = 0.48 if controlled else 1.25
	swing_hits.clear()
	return true


func resolve_hits() -> void:
	if hub.peaceful_mode:
		return
	var targets: Array = hub.dogs if controlled else [hub.player]
	for target in targets:
		if not target.active or target in swing_hits:
			continue
		var offset := ground_vector(target.position-position)
		if offset.length()>112 or (offset.length()>20 and facing.dot(offset.normalized())<0.15):
			continue
		if not hub.clear_line(position,target.position):
			continue
		swing_hits.append(target)
		target.receive_hit(facing)


func receive_hit(from: Vector2) -> bool:
	if hub.peaceful_mode:
		return false
	if not active or grace>0:
		return false
	health -= 1
	grace = 0.75 if controlled else 0.28
	flash = 1.0
	knockback = Vector2(from.x,from.y*GROUND_Y)*170
	if health<=0:
		active = false
		enemy = false
		velocity = Vector2.ZERO
		collision_layer = 0
		hub.actor_yielded(self)
	return true


func _update_animation(walking: bool) -> void:
	if facing.y>=0:
		direction = "se" if facing.x>=0 else "sw"
	else:
		direction = "ne" if facing.x>=0 else "nw"
	var animation := ("walk_" if walking else "idle_")+direction
	if sprite.animation!=animation:
		sprite.play(animation)
	sprite.speed_scale = 1.35 if controlled and Input.is_action_pressed("hub_run") else 1.0


func _draw() -> void:
	if not active:
		return
	# Small contact shadow stays at the feet and shares the actor's ground sort.
	draw_set_transform(Vector2(0,-2),0,Vector2(1,0.34))
	draw_circle(Vector2.ZERO,24,Color(0.09,0.13,0.13,0.2))
	if windup>0:
		draw_arc(Vector2.ZERO,46,0,TAU,36,Color(1,0.4,0.2,0.7),3,true)
	draw_set_transform(Vector2.ZERO)
	if enemy and hub.combat_active:
		for i in maximum_health:
			draw_circle(Vector2((i-(maximum_health-1)*0.5)*12,-120),4,Color("f7e4a3") if i<health else Color("6c5e54"))
	if swing>0:
		var progress := 1.0-swing/0.32
		var angle := atan2(facing.y*GROUND_Y,facing.x)
		draw_set_transform(Vector2(0,-45),angle,Vector2(1,0.66))
		draw_arc(Vector2.ZERO,65,lerpf(-1.3,0.4,progress),lerpf(0.1,1.7,progress),20,Color(1,0.93,0.68,sin(progress*PI)*0.9),5,true)
		draw_set_transform(Vector2.ZERO)
