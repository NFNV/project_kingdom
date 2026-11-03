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
const Shield := preload("res://experiments/anime_hub_demo_v07/tools/cat_shield.gd")
const MAX_STAMINA := 100.0
const ROLL_COST := 28.0
const ROLL_DURATION := .46
const PARRY_WINDOW := .18
const COMBAT_LINGER := 10.0
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
var shield: Node2D
var stamina := MAX_STAMINA
var stamina_delay := 0.0
var guarding := false
var guard_requested := false
var guard_age := 0.0
var parry_rearm := 0.0
var guard_break := 0.0
var roll_left := 0.0
var roll_cooldown := 0.0
var roll_heading := Vector2.ZERO
var defence_flash := 0.0
var defence_result := ""
var parries := 0
var blocks := 0
var dodges := 0
var riposte_left := 0.0
var combat_left := 0.0


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
		shield = Shield.new()
		shield.actor = self
		add_child(shield)
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
		combat_left = maxf(0,combat_left-delta)
		_update_defence(delta)
		if not automated:
			intent = Input.get_vector("hub_left","hub_right","hub_up","hub_down")
			if intent.length()>0.1:
				route.clear()
			elif not route.is_empty():
				intent = follow_route()
		if intent.length()>.05 and swing<=0 and roll_left<=0:
			facing = intent.normalized()
		if not automated:
			set_guard(Input.is_action_pressed("hub_guard"))
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
		if guarding: speed *= .38
		if guard_break>0: speed *= .3
	if swing>0 or windup>0:
		speed *= 0.0 if controlled else 0.2
	if not controlled and hub.peaceful_mode:
		speed = 74.0
	var before := position
	velocity = Vector2(intent.x,intent.y*GROUND_Y)*speed+knockback
	if controlled and roll_left>0:
		velocity = Vector2(roll_heading.x,roll_heading.y*GROUND_Y)*390.0
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
	if is_instance_valid(shield): shield.sync_pose()
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
	if controlled and (guarding or guard_break>0 or roll_left>0): return false
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
	if controlled:
		enter_combat()
	elif enemy:
		hub.player.enter_combat()
	return true


func try_skill() -> bool:
	if guarding or guard_break>0 or roll_left>0: return false
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
	enter_combat()
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
	weapon.sync_pose()
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
		var damage: int = int(hub.state.stats().attack) if controlled else 1
		if controlled and riposte_left>0:
			damage += 2
		if target.receive_hit(facing,damage) and controlled:
			riposte_left = 0


func receive_hit(from: Vector2, damage := 1, force := 170.0, source: Node2D = null) -> bool:
	if hub.peaceful_mode or hub.transitioning:
		return false
	# An incoming strike counts even when blocked, parried, rolled through,
	# or absorbed by post-hit invulnerability.
	if controlled and active:
		enter_combat()
	if not active or grace>0:
		return false
	if controlled:
		if roll_invulnerable():
			dodges += 1
			return false
		var incoming := ground_vector(source.position-position).normalized() if is_instance_valid(source) else -from.normalized()
		if guarding and facing.dot(incoming)>=.25:
			if guard_age<=PARRY_WINDOW:
				parries += 1
				guard_age = PARRY_WINDOW+1
				riposte_left = 1.6
				stamina = minf(MAX_STAMINA,stamina+14)
				_defence_feedback("PARRY",.65)
				hub.audio.play_event("hit",position,-5)
				if is_instance_valid(source) and source.has_method("receive_parry"): source.receive_parry()
				return false
			var cost := 23.0*damage/maxf(.1,float(hub.state.stats().guard))
			stamina_delay = .85
			if stamina>=cost:
				stamina -= cost
				blocks += 1
				knockback = Vector2(from.x,from.y*GROUND_Y)*force*.2
				_defence_feedback("BLOCK",.35)
				hub.audio.play_event("hit",position,-10)
				return false
			stamina = 0
			guarding = false
			guard_break = 1.0
			_defence_feedback("GUARD BROKEN",1.0)
	health = maxi(0,health-damage)
	grace = 0.75 if controlled else 0.28
	flash = 1.0
	if controlled:
		guarding = false
		roll_left = 0
		swing = 0
		skill_buffer = 0
		light_buffer = 0
		sprite.rotation = 0
		sprite.position = Vector2.ZERO
		_update_combat_art()
		if is_instance_valid(shield): shield.sync_pose()
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


func is_in_combat() -> bool:
	return controlled and active and combat_left>0 and not hub.peaceful_mode and not hub.shopping and not hub.title_active

func enter_combat() -> void:
	if not controlled or not active or hub.peaceful_mode or hub.transitioning or hub.paused or hub.shopping or hub.title_active:
		return
	combat_left = COMBAT_LINGER
	if is_instance_valid(weapon): weapon.sync_pose()
	if is_instance_valid(shield): shield.sync_pose()


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
	if controlled and roll_left>0:
		sprite.set_pose("idle",sprite.direction_for(roll_heading),0)
		var progress := 1.0-roll_left/ROLL_DURATION
		sprite.rotation = TAU*progress*(-1 if roll_heading.x<0 else 1)
		var pivot := Vector2(0,-sprite.display_height*.45)
		sprite.position = pivot-pivot.rotated(sprite.rotation)-Vector2(0,sin(progress*PI)*7)
		return
	sprite.rotation = 0
	sprite.position = Vector2.ZERO
	sprite.tick(delta,0.0 if controlled and swing>0 else distance,facing,running)
	direction = sprite.facing_direction


func stop_motion() -> void:
	guarding = false
	roll_left = 0
	if is_instance_valid(sprite):
		sprite.rotation = 0
		sprite.position = Vector2.ZERO
	intent = Vector2.ZERO
	velocity = Vector2.ZERO
	route.clear()
	sprite.set_pose("idle",direction,0)
	if is_instance_valid(weapon):
		weapon.sync_pose()
		_update_combat_art()
	if is_instance_valid(shield): shield.sync_pose()


func can_defend() -> bool:
	return controlled and active and not hub.paused and not hub.transitioning and not hub.shopping and not hub.title_active

func set_guard(held: bool) -> bool:
	var fresh_raise := held and not guard_requested
	guard_requested = held
	if not held:
		guarding = false
		return false
	if not can_defend() or hub.peaceful_mode or float(hub.state.stats().guard)<=0 or roll_left>0 or guard_break>0 or swing>0 or stamina<1:
		guarding = false
		return false
	if not guarding:
		guarding = true
		# Repeated taps during the lockout can still block, but cannot parry.
		guard_age = 0.0 if fresh_raise and parry_rearm<=0 else PARRY_WINDOW+1
		if fresh_raise: parry_rearm = .55
		route.clear()
	return true

func try_roll() -> bool:
	if not can_defend() or roll_left>0 or roll_cooldown>0 or guard_break>0 or stamina<ROLL_COST:
		return false
	if swing>0 and attack_duration-swing<(.36 if attack_kind=="wind" else Timing.LIGHT_END_CONTACT):
		return false
	roll_heading = intent.normalized() if intent.length()>.1 else facing.normalized()
	facing = roll_heading
	stamina -= ROLL_COST
	stamina_delay = .7
	roll_left = ROLL_DURATION
	roll_cooldown = .66
	guarding = false
	swing = 0
	cooldown = maxf(cooldown,.2)
	light_buffer = 0
	skill_buffer = 0
	knockback = Vector2.ZERO
	route.clear()
	hub.audio.play_event("sword",position,-17)
	return true

func roll_invulnerable() -> bool:
	var elapsed := ROLL_DURATION-roll_left
	return roll_left>0 and elapsed>=.06 and elapsed<=.32

func _update_defence(delta: float) -> void:
	roll_left = maxf(0,roll_left-delta)
	roll_cooldown = maxf(0,roll_cooldown-delta)
	guard_break = maxf(0,guard_break-delta)
	parry_rearm = maxf(0,parry_rearm-delta)
	riposte_left = maxf(0,riposte_left-delta)
	defence_flash = maxf(0,defence_flash-delta)
	stamina_delay = maxf(0,stamina_delay-delta)
	if guarding: guard_age += delta
	if stamina_delay<=0 and roll_left<=0 and guard_break<=0:
		stamina = minf(MAX_STAMINA,stamina+delta*(7 if guarding else 30))
	if guarding and (float(hub.state.stats().guard)<=0 or hub.peaceful_mode): guarding = false

func _defence_feedback(result: String, duration: float) -> void:
	defence_result = result
	defence_flash = duration


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
	if controlled and defence_flash>0:
		var ink := Color("b9f2e7") if defence_result=="PARRY" else Color("f3d093")
		draw_arc(Vector2(0,-34),27+(1.0-defence_flash)*12,0,TAU,40,Color(ink,minf(1,defence_flash*3)),2,true)
		draw_string_outline(ThemeDB.fallback_font,Vector2(-70,-sprite.display_height-18),defence_result,HORIZONTAL_ALIGNMENT_CENTER,140,12,3,Color("223a32"))
		draw_string(ThemeDB.fallback_font,Vector2(-70,-sprite.display_height-18),defence_result,HORIZONTAL_ALIGNMENT_CENTER,140,12,ink)
	if controlled and roll_left>0:
		for i in 3:
			var at := Vector2(-roll_heading.x,-roll_heading.y*GROUND_Y)*(15+i*11)
			draw_arc(at,6+i*2,0,PI,12,Color(.87,.81,.57,.35-i*.08),1.5,true)
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
