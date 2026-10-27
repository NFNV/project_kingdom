extends CharacterBody2D

const ART := "res://experiments/anime_hub_assets_v06/"
const GROUND_Y := 0.65
const ANIMAL_SCALE := 0.675
const Motion := preload("res://experiments/anime_hub_demo_v07/tools/motion_sprite.gd")
const Sword := preload("res://experiments/anime_hub_demo_v07/tools/cat_sword.gd")
const SKILL_COOLDOWN := 6.0
const WindSlash := preload("res://experiments/anime_hub_demo_v07/tools/wind_slash.gd")
const CombatArt := preload("res://experiments/anime_hub_demo_v07/tools/cat_combat.gd")
const Timing := preload("res://experiments/anime_hub_demo_v07/tools/combat_timing.gd")
var hub: Node2D
var controlled := false
var enemy := false
var active := true
var sprite: AnimatedSprite2D
var facing := Vector2(1,1).normalized()
var intent := Vector2.ZERO
var route := PackedVector2Array()
var _health := 5
var _maximum_health := 5
var health: int:
	get: return hub.state.health if controlled and is_instance_valid(hub) and is_instance_valid(hub.state) else _health
	set(value):
		if controlled and is_instance_valid(hub) and is_instance_valid(hub.state):
			hub.state.health = value
		else:
			_health = value
var maximum_health: int:
	get: return hub.state.maximum_health if controlled and is_instance_valid(hub) and is_instance_valid(hub.state) else _maximum_health
	set(value): _maximum_health = value
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
var resident_id := ""
var patrol := PackedVector2Array()
var patrol_index := 1
var patrol_wait := 2.0
var moved_distance := 0.0
var home := Vector2.ZERO
var alerted := false
var weapon: Node2D
var skill_cooldown := 0.0
var attack_kind := "light"
var attack_duration := .46
var combat_art: Polygon2D
var skill_buffer := 0.0
var skill_launched := false
var skill_casts := 0
var light_buffer := 0.0
var buffered_aim := Vector2.ZERO
var swing_audio_played := false


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0
	shape.shape = circle
	add_child(shape)
	sprite = Motion.new()
	add_child(sprite)
	sprite.configure("cat" if controlled else "warden",108.0*ANIMAL_SCALE,float(get_instance_id()%37)*.13)
	if controlled:
		weapon = Sword.new()
		weapon.actor = self
		add_child(weapon)
		weapon.sync_pose()
		combat_art = CombatArt.new()
		add_child(combat_art)
		combat_art.configure_reference(sprite.metadata,sprite.display_height)
		combat_art.hide()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	queue_redraw()


static func ground_vector(vector: Vector2) -> Vector2:
	return Vector2(vector.x,vector.y/GROUND_Y)


func _physics_process(delta: float) -> void:
	if hub.paused or hub.transitioning or not active:
		return
	if hub.shopping:
		velocity = Vector2.ZERO
		sprite.tick(delta,0.0,facing)
		if is_instance_valid(weapon):
			weapon.sync_pose()
		return
	grace = maxf(0,grace-delta)
	cooldown = maxf(0,cooldown-delta)
	skill_cooldown = maxf(0,skill_cooldown-delta)
	light_buffer = maxf(0,light_buffer-delta)
	if skill_buffer>0:
		skill_buffer = maxf(0,skill_buffer-delta)
	flash = maxf(0,flash-delta*4)
	knockback = knockback.move_toward(Vector2.ZERO,1000*delta)
	if controlled:
		if not automated:
			intent = Input.get_vector("hub_left","hub_right","hub_up","hub_down")
			if intent.length()>0.1:
				route.clear()
			elif not route.is_empty():
				intent = follow_route()
		if intent.length()>.05 and swing<=0:
			facing = intent.normalized()
		if skill_buffer>0 and cooldown<=0 and swing<=0:
			skill_buffer = 0
			try_skill()
		if light_buffer>0 and skill_buffer<=0 and swing<=0 and cooldown<=0:
			var aim := buffered_aim
			light_buffer = 0
			try_attack(aim)
		if not automated and Input.is_action_pressed("hub_attack") and skill_buffer<=0:
			try_attack()

	else:
		intent = _enemy_intent(delta)
	if intent.length()>0.05 and windup<=0 and swing<=0:
		facing = intent.normalized()
	var speed := 215.0 if controlled else 118.0
	if controlled and Input.is_action_pressed("hub_run"):
		speed = 325.0
	if controlled:
		speed *= float(hub.state.stats().speed)
	if swing>0 or windup>0:
		speed *= 0.0 if controlled else 0.2
	if not controlled and hub.peaceful_mode:
		speed = 74.0
	var before := position
	velocity = Vector2(intent.x,intent.y*GROUND_Y)*speed+knockback
	move_and_slide()
	moved_distance = ground_vector(position-before).length()
	if intent.length()>.05 and swing<=0 and windup<=0:
		hub.audio.footsteps(self,moved_distance,controlled and Input.is_action_pressed("hub_run"))
	if windup>0:
		windup -= delta
		if windup<=0:
			try_attack()
	if swing>0:
		swing = maxf(0,swing-delta)
		var attack_elapsed := attack_duration-swing
		if controlled and attack_kind=="light" and attack_elapsed>=.17 and not swing_audio_played:
			swing_audio_played = true
			hub.audio.play_event("sword",position,-5)
		if attack_kind=="wind" and attack_elapsed>=Timing.WIND_RELEASE and not skill_launched:
			_launch_wind_slash()
		elif attack_kind=="light" and ((controlled and attack_elapsed>=Timing.LIGHT_CONTACT and attack_elapsed<=Timing.LIGHT_END_CONTACT) or (not controlled and attack_elapsed>=.10)):
			resolve_hits()
	_update_animation(delta,moved_distance)
	var tint: Color = hub.actor_tint
	if enemy:
		tint *= Color(1.0,.82,.72)
	sprite.modulate = tint.lerp(Color(1.0,0.4,0.3),flash)
	if grace>0 and controlled:
		sprite.modulate.a = 0.55 if int(grace*14)%2==0 else 1.0
	if is_instance_valid(weapon):
		weapon.sync_pose()
		_update_combat_art()
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
		return _friendly_intent(delta)
	if not enemy or not hub.combat_active or not hub.player.active:
		return Vector2.ZERO
	var offset: Vector2 = hub.player.position-position
	var distance := ground_vector(offset).length()
	var player_from_home := ground_vector(hub.player.position-home).length()
	if player_from_home>650 or ground_vector(position-home).length()>700:
		alerted = false
	if not alerted and distance<350 and player_from_home<600 and hub.clear_line(position,hub.player.position):
		alerted = true
	if not alerted:
		windup = 0
		path_timer -= delta
		if ground_vector(position-home).length()<28:
			route.clear()
			return Vector2.ZERO
		if path_timer<=0:
			path_timer = .7
			route = hub.find_path(position,home)
		return follow_route()
	if distance<78 and hub.clear_line(position,hub.player.position):
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
	if controlled and int(hub.state.stats().attack)<=0:
		return false
	if hub.peaceful_mode or hub.transitioning or hub.shopping:
		return false
	if not active or hub.paused:
		return false
	if cooldown>0 or swing>0:
		if controlled and aim.length()>.1 and attack_duration-swing>=(.49 if attack_kind=="wind" else .30) and skill_buffer<=0:
			light_buffer = .40
			buffered_aim = aim
			return true
		return false
	if not controlled and not enemy:
		return false
	if aim.length()>0.1:
		facing = ground_vector(aim).normalized()
	attack_kind = "light"
	attack_duration = Timing.LIGHT_DURATION if controlled else .32
	swing = attack_duration
	cooldown = .64 if controlled else 1.25
	swing_hits.clear()
	swing_audio_played = false
	return true


func try_skill() -> bool:
	if controlled and int(hub.state.stats().attack)<=0:
		return false
	if not controlled or not active or hub.peaceful_mode or hub.paused or hub.transitioning or hub.shopping:
		return false
	if skill_cooldown>0:
		return false
	if cooldown>0 or swing>0:
		skill_buffer = .70
		return true
	attack_kind = "wind"
	attack_duration = Timing.WIND_DURATION
	swing = attack_duration
	cooldown = .78
	light_buffer = 0
	skill_launched = false
	skill_buffer = 0
	skill_cooldown = float(hub.state.stats().recharge)
	hub.audio.play_event("wind_charge",position,-6)
	swing_hits.clear()
	route.clear()
	return true


func _launch_wind_slash() -> void:
	skill_launched = true
	skill_casts += 1
	hub.audio.play_event("wind_release",position,-3)
	var wave := WindSlash.new()
	wave.hub = hub
	wave.damage = int(hub.state.stats().wind)
	wave.heading = facing.normalized()
	wave.position = position+Vector2(facing.x,facing.y*GROUND_Y)*22
	hub.world.add_child(wave)
	wave.reset_physics_interpolation()


func _update_combat_art() -> void:
	var attacking := swing>0
	sprite.visible = not attacking
	combat_art.visible = attacking and active
	weapon.visible = false
	if attacking:
		combat_art.pose(facing,1.0-swing/attack_duration,attack_kind=="wind")
		combat_art.modulate = sprite.modulate


func resolve_hits() -> void:
	if hub.peaceful_mode:
		return
	var targets: Array = hub.dogs if controlled else [hub.player]
	for target in targets:
		if not target.active or target in swing_hits:
			continue
		var offset := ground_vector(target.position-position)
		if offset.length()>96.0 or (offset.length()>20 and facing.dot(offset.normalized())<.15):
			continue
		if not hub.clear_line(position,target.position):
			continue
		swing_hits.append(target)
		target.receive_hit(facing,int(hub.state.stats().attack) if controlled else 1)


func receive_hit(from: Vector2, damage := 1, force := 170.0) -> bool:
	if hub.peaceful_mode or hub.transitioning:
		return false
	if not active or grace>0:
		return false
	health = maxi(0,health-damage)
	grace = 0.75 if controlled else 0.28
	flash = 1.0
	knockback = Vector2(from.x,from.y*GROUND_Y)*force
	hub.audio.play_event("hurt_player" if controlled else "hit",position,-2)
	if enemy:
		alerted = true
	if health<=0:
		hub.audio.play_event("defeat",position,-8)
		active = false
		enemy = false
		velocity = Vector2.ZERO
		collision_layer = 0
		hub.actor_yielded(self)
	return true


func _friendly_intent(delta: float) -> Vector2:
	if patrol.is_empty() or not is_instance_valid(hub.player):
		return Vector2.ZERO
	var offset: Vector2 = hub.player.position-position
	if ground_vector(offset).length()<155:
		facing = ground_vector(offset).normalized()
		return Vector2.ZERO
	patrol_wait = maxf(0,patrol_wait-delta)
	if patrol_wait>0:
		return Vector2.ZERO
	if route.is_empty():
		var goal := patrol[patrol_index]
		if position.distance_to(goal)<18:
			patrol_index = (patrol_index+1)%patrol.size()
			patrol_wait = 2.5+patrol_index*.7
			return Vector2.ZERO
		route = hub.find_path(position,goal)
	return follow_route()


func _update_animation(delta: float, distance: float) -> void:
	var running := controlled and Input.is_action_pressed("hub_run")
	sprite.tick(delta,0.0 if controlled and swing>0 else distance,facing,running)
	direction = sprite.facing_direction


func stop_motion() -> void:
	intent = Vector2.ZERO
	velocity = Vector2.ZERO
	route.clear()
	sprite.set_pose("idle",direction,0)
	if is_instance_valid(weapon):
		weapon.sync_pose()
		_update_combat_art()


func _draw() -> void:
	if not active:
		return
	# Small contact shadow stays at the feet and shares the actor's ground sort.
	draw_set_transform(Vector2(0,-2),0,Vector2(1,0.34))
	draw_circle(Vector2.ZERO,24*ANIMAL_SCALE,Color(0.09,0.13,0.13,0.2))
	if windup>0:
		draw_circle(Vector2.ZERO,46,Color(1,.24,.12,.10))
		draw_arc(Vector2.ZERO,46,-PI/2,-PI/2+TAU*(1.0-windup/.70),36,Color(1,.3,.14,.9),3,true)
	draw_set_transform(Vector2.ZERO)
	if enemy and hub.combat_active:
		for i in maximum_health:
			draw_circle(Vector2((i-(maximum_health-1)*0.5)*10,-sprite.display_height-12),3,Color("eea07f") if i<health else Color("473e38"))
	if swing>0:
		var elapsed := attack_duration-swing
		var angle := atan2(facing.y*GROUND_Y,facing.x)
		draw_set_transform(Vector2(0,-31),angle,Vector2(1,0.66))
		if attack_kind=="wind":
			if elapsed>=.08 and elapsed<Timing.WIND_RELEASE:
				var charge := clampf((elapsed-.08)/(Timing.WIND_RELEASE-.08),0,1)
				draw_arc(Vector2.ZERO,24+charge*12,-1.8,1.8,32,Color(.7,.9,1,charge*.8),2,true)
		elif not controlled or (elapsed>=Timing.LIGHT_CONTACT and elapsed<=Timing.LIGHT_END_CONTACT):
			var progress := clampf((elapsed-Timing.LIGHT_CONTACT)/(Timing.LIGHT_END_CONTACT-Timing.LIGHT_CONTACT),0,1) if controlled else elapsed/attack_duration
			draw_arc(Vector2.ZERO,56,lerpf(-1.3,.4,progress),lerpf(.1,1.7,progress),20,Color(1,.93,.68,sin(progress*PI)*.9),4,true)
		draw_set_transform(Vector2.ZERO)
