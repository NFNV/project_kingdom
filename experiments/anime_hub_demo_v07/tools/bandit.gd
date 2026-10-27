extends "res://experiments/anime_hub_demo_v07/tools/actor.gd"

const BanditArt := preload("res://experiments/anime_hub_demo_v07/tools/bandit_sprite.gd")
const HitFeedback := preload("res://experiments/anime_hub_demo_v07/tools/hit_feedback.gd")
const ATTACKS := {
	"slash":{"warning":.55,"duration":.44,"contact":.10,"end":.22,"reach":96.0,"cosine":.40,"cooldown":1.25},
	"lunge":{"warning":.72,"duration":.58,"contact":.04,"end":.26,"reach":70.0,"cosine":.05,"cooldown":1.60},
	"sweep":{"warning":1.0,"duration":.72,"contact":.12,"end":.30,"reach":132.0,"cosine":-.15,"cooldown":1.90}
}
var variant := "raider"
var captain := false
var state := "patrol"
var stagger := 0.0
var returning := false
var attacks_started := 0
var hits_taken := 0
var last_attack := ""
var patrol_distance := 0.0
var peak_navigation_ms := 0.0

func _ready() -> void:
	super._ready()
	remove_child(sprite)
	sprite.queue_free()
	sprite = BanditArt.new()
	add_child(sprite)
	sprite.configure(variant,(118.0 if variant=="mauler" else 108.0)*ANIMAL_SCALE)
	attack_kind = "sweep" if variant=="mauler" else "slash"
	patrol_wait = .5

func profile() -> Dictionary:
	if captain:
		var data: Dictionary = ATTACKS[attack_kind].duplicate()
		data.warning += .25
		data.cooldown += .4
		return data
	return ATTACKS[attack_kind]

func _physics_process(delta: float) -> void:
	if hub.paused or hub.transitioning or not active:
		return
	grace = maxf(0,grace-delta)
	cooldown = maxf(0,cooldown-delta)
	stagger = maxf(0,stagger-delta)
	flash = maxf(0,flash-delta*4)
	knockback = knockback.move_toward(Vector2.ZERO,1000*delta)
	if hub.peaceful_mode or not enemy or not hub.combat_active or not hub.player.active:
		windup = 0
		swing = 0
		intent = Vector2.ZERO
	else:
		if alerted and (ground_vector(hub.player.position-home).length()>650 or ground_vector(position-home).length()>700):
			alerted = false
			returning = true
			windup = 0
			swing = 0
			route.clear()
			path_timer = 0
		if stagger>0:
			state = "hurt"
			intent = Vector2.ZERO
		elif windup>0:
			state = "windup"
			intent = Vector2.ZERO
			windup = maxf(0,windup-delta)
			if windup<=0:
				try_attack()
		elif swing>0:
			swing = maxf(0,swing-delta)
			var elapsed := attack_duration-swing
			state = "attack" if elapsed<=float(profile().end) else "recover"
			intent = facing if attack_kind=="lunge" and elapsed<float(profile().end) else Vector2.ZERO
		else:
			intent = _enemy_intent(delta)
	if intent.length()>.05 and windup<=0 and swing<=0 and stagger<=0 and state in ["patrol","return","chase"]:
		facing = intent.normalized()
	var speed := 136.0 if variant=="raider" else 105.0
	if state=="patrol":
		speed = 72.0 if variant=="raider" else 57.0
	elif state=="return":
		speed = 145.0
	elif state=="attack" and attack_kind=="lunge":
		speed = 480.0
	var before := position
	velocity = Vector2(intent.x,intent.y*GROUND_Y)*speed+knockback
	move_and_slide()
	moved_distance = ground_vector(position-before).length()
	if intent.length()>.05 and state in ["patrol","return","chase"]:
		hub.audio.footsteps(self,moved_distance)
	if state=="patrol":
		patrol_distance += moved_distance
	if swing>0:
		var elapsed := attack_duration-swing
		if elapsed>=float(profile().contact) and elapsed<=float(profile().end):
			resolve_hits()
	_update_animation(delta,moved_distance)
	sprite.modulate = hub.actor_tint.lerp(Color(1,.96,.72),flash*.85)
	queue_redraw()

func _enemy_intent(delta: float) -> Vector2:
	if not enemy or hub.peaceful_mode or not hub.combat_active:
		return Vector2.ZERO
	path_timer -= delta
	if returning:
		state = "return"
		if ground_vector(position-home).length()<24:
			returning = false
			patrol_wait = 1.8
			route.clear()
			return Vector2.ZERO
		return _toward(home,.45)
	var offset := ground_vector(hub.player.position-position)
	var distance := offset.length()
	if not alerted and distance<330 and ground_vector(hub.player.position-home).length()<600 and hub.clear_line(position,hub.player.position):
		alerted = true
		hub.audio.play_event("bandit_alert",position,-15)
		route.clear()
		path_timer = 0
	if not alerted:
		state = "patrol"
		patrol_wait = maxf(0,patrol_wait-delta)
		if patrol.is_empty() or patrol_wait>0:
			return Vector2.ZERO
		var goal := patrol[patrol_index]
		if ground_vector(goal-position).length()<18:
			patrol_index = (patrol_index+1)%patrol.size()
			patrol_wait = .8+patrol_index*.35
			route.clear()
			path_timer = 0
			return Vector2.ZERO
		return _toward(goal,.65)
	state = "chase"
	var attack_range := 200.0 if variant=="raider" else 122.0
	if distance<attack_range and cooldown<=0 and hub.clear_line(position,hub.player.position):
		attack_kind = "sweep" if variant=="mauler" else ("lunge" if distance>108 else "slash")
		facing = offset.normalized()
		windup = profile().warning
		state = "windup"
		route.clear()
		return Vector2.ZERO
	if distance<70 and cooldown>.25:
		facing = offset.normalized()
		return -offset.normalized()*.35
	if distance<90 and cooldown>0:
		facing = offset.normalized()
		return Vector2.ZERO
	return _toward(hub.player.position,.30)

func _toward(goal: Vector2, refresh: float) -> Vector2:
	if path_timer<=0:
		path_timer = refresh
		var started := Time.get_ticks_usec()
		route = hub.find_path(position,goal)
		peak_navigation_ms = maxf(peak_navigation_ms,(Time.get_ticks_usec()-started)/1000.0)
	return follow_route()

func try_attack(aim := Vector2.ZERO) -> bool:
	if not active or not enemy or hub.paused or hub.transitioning or hub.peaceful_mode or not hub.combat_active or cooldown>0 or swing>0 or stagger>0:
		return false
	if aim.length()>.1:
		facing = ground_vector(aim).normalized()
	windup = 0
	attack_duration = profile().duration
	swing = attack_duration
	cooldown = profile().cooldown
	swing_hits.clear()
	attacks_started += 1
	last_attack = attack_kind
	hub.audio.play_event("club" if variant=="mauler" else "sword",position,-6)
	state = "attack"
	return true

func attack_contains(point: Vector2) -> bool:
	var offset := ground_vector(point-position)
	if attack_kind=="lunge":
		return offset.dot(facing)>=0 and offset.dot(facing)<=70 and absf(offset.dot(facing.orthogonal()))<=30
	return offset.length()<=float(profile().reach) and (offset.length()<12 or facing.dot(offset.normalized())>=float(profile().cosine))

func resolve_hits() -> void:
	if hub.peaceful_mode or hub.paused or hub.transitioning or not active or not enemy:
		return
	var elapsed := attack_duration-swing
	if windup>0 or swing<=0 or elapsed<float(profile().contact) or elapsed>float(profile().end):
		return
	var target = hub.player
	if target.active and target not in swing_hits and attack_contains(target.position) and hub.clear_line(position,target.position):
		swing_hits.append(target)
		target.receive_hit(facing,2 if captain else 1,230.0 if variant=="mauler" else 155.0)

func receive_hit(from: Vector2, damage := 1, force := 170.0) -> bool:
	var accepted := super.receive_hit(from,damage,force)
	if not accepted:
		return false
	hits_taken += 1
	windup = 0
	swing = 0
	stagger = .34 if variant=="mauler" else .27
	cooldown = maxf(cooldown,.55)
	intent = Vector2.ZERO
	route.clear()
	state = "hurt"
	sprite.set_pose("hurt",sprite.direction_for(facing),7)
	var feedback := HitFeedback.new()
	feedback.hub = hub
	feedback.amount = damage
	feedback.heading = from
	feedback.position = position
	hub.world.add_child(feedback)
	if not active:
		var fall := create_tween()
		fall.tween_property(sprite,"rotation",-.18 if from.x<0 else .18,.22)
	queue_redraw()
	return true

func _update_animation(delta: float, distance: float) -> void:
	var heading: String = sprite.direction_for(facing)
	if stagger>0:
		sprite.set_pose("hurt",heading,7)
	elif windup>0:
		sprite.set_pose("windup",heading,4)
	elif swing>0:
		sprite.set_pose("strike" if state=="attack" else "recover",heading,5 if state=="attack" else 6)
	else:
		sprite.tick(delta,distance,facing)
	direction = sprite.facing_direction

func _draw() -> void:
	if not active or not is_instance_valid(sprite):
		return
	draw_set_transform(Vector2(0,-2),0,Vector2(1,GROUND_Y))
	draw_circle(Vector2.ZERO,19,Color(.09,.13,.13,.20))
	if windup>0:
		var strength := 1.0-windup/float(profile().warning)
		var tint := Color("eaaa57") if variant=="mauler" else Color("f07d66")
		if attack_kind=="lunge":
			var normal := facing.orthogonal()*30
			var tip := facing*210
			var area := PackedVector2Array([-normal,normal,tip+normal,tip+facing*22,tip-normal])
			draw_colored_polygon(area,Color(tint,.13+strength*.10))
			var outline := area.duplicate()
			outline.append(area[0])
			draw_polyline(outline,Color(tint,.80),2,true)
		else:
			var angle := facing.angle()
			var spread := acos(float(profile().cosine))
			var area := PackedVector2Array([Vector2.ZERO])
			for i in 25:
				area.append(Vector2.from_angle(angle-spread+i*spread/12.0)*float(profile().reach))
			draw_colored_polygon(area,Color(tint,.12+strength*.12))
			draw_arc(Vector2.ZERO,profile().reach,angle-spread,angle+spread,40,Color(tint,.85),2.5,true)
		draw_arc(Vector2.ZERO,22,-PI/2,-PI/2+TAU*strength,32,Color(tint,.95),3,true)
	draw_set_transform(Vector2.ZERO)
	if captain:
		draw_string_outline(ThemeDB.fallback_font,Vector2(-61,-sprite.display_height-35),"ROOK · CAPTAIN",HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color("293b33"))
		draw_string(ThemeDB.fallback_font,Vector2(-61,-sprite.display_height-35),"ROOK · CAPTAIN",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe3a5"))
	for i in maximum_health:
		draw_circle(Vector2((i-(maximum_health-1)*.5)*10,-sprite.display_height-12),3.0,Color("f3bd8a") if i<health else Color("4c4541"))
	if windup>0:
		draw_string_outline(ThemeDB.fallback_font,Vector2(-26,-sprite.display_height-25),attack_kind.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color("353d3a"))
		draw_string(ThemeDB.fallback_font,Vector2(-26,-sprite.display_height-25),attack_kind.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("fce5ae"))
