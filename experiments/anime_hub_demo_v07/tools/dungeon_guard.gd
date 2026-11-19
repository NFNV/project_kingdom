extends "res://experiments/anime_hub_demo_v07/tools/bandit.gd"
## Reusable enemies; placement, saved defeat IDs and rewards stay in the area.
const GuardSprite := preload("res://experiments/anime_hub_demo_v07/tools/dungeon_guard_sprite.gd")
const Bolt := preload("res://experiments/anime_hub_demo_v07/tools/hostile_bolt.gd")
@export_enum("ashen_vanguard","briar_spearman","gloam_arbalist","blackthorn_captain") var archetype := "ashen_vanguard"
var bolt_released := false

func _ready() -> void:
	if level==1: level = 12 if is_boss() else (9 if archetype=="ashen_vanguard" else 8)
	if is_boss() and enemy_name.is_empty(): enemy_name = "Blackthorn Captain"
	variant = "mauler" if archetype in ["ashen_vanguard","blackthorn_captain"] else "raider"
	super._ready()
	remove_child(sprite)
	sprite.queue_free()
	sprite = GuardSprite.new()
	add_child(sprite)
	sprite.configure(archetype,160.0 if is_boss() else (94.0 if archetype=="briar_spearman" else 87.0))
	maximum_health = 36 if is_boss() else (7 if archetype=="ashen_vanguard" else 5)
	health = maximum_health
	attack_kind = "slash"

func is_boss() -> bool: return archetype=="blackthorn_captain"

func profile() -> Dictionary:
	if attack_kind=="bolt":
		return {"warning":.95,"duration":.7,"contact":.12,"end":.25,"reach":490.0,"cosine":.99,"cooldown":2.25,"damage":1}
	if attack_kind=="thrust":
		return {"warning":.7,"duration":.6,"contact":.12,"end":.28,"reach":180.0,"cosine":.93,"cooldown":1.45,"damage":1}
	var data: Dictionary = ATTACKS[attack_kind].duplicate()
	if is_boss():
		data.warning = float(data.warning)+.22
		data.reach = float(data.reach)+25.0
		data.cooldown = float(data.cooldown)+.25
	return data

func _enemy_intent(delta: float) -> Vector2:
	path_timer -= delta
	if returning:
		state = "return"
		if ground_vector(position-home).length()<24:
			returning = false
			route.clear()
			patrol_wait = 1.5
			return Vector2.ZERO
		return _toward(home,.45)
	var offset := ground_vector(hub.player.position-position)
	var distance := offset.length()
	var sight: bool = hub.clear_line(position,hub.player.position)
	if not alerted and distance<(470 if archetype=="gloam_arbalist" else 360) and sight:
		alerted = true
		hub.audio.play_event("bandit_alert",position,-15)
		route.clear()
		path_timer = 0
	if not alerted:
		state = "patrol"
		patrol_wait = maxf(0,patrol_wait-delta)
		if patrol.is_empty() or patrol_wait>0: return Vector2.ZERO
		if ground_vector(patrol[patrol_index]-position).length()<18:
			patrol_index = (patrol_index+1)%patrol.size()
			patrol_wait = .8
			route.clear()
			path_timer = 0
			return Vector2.ZERO
		return _toward(patrol[patrol_index],.65)
	state = "chase"
	var reach := 145.0
	if archetype=="briar_spearman": reach = 175.0
	elif archetype=="gloam_arbalist": reach = 490.0
	elif is_boss(): reach = 210.0
	if distance<reach and cooldown<=0 and sight:
		attack_kind = "slash"
		if archetype=="briar_spearman": attack_kind = "thrust"
		elif archetype=="gloam_arbalist": attack_kind = "bolt"
		elif is_boss(): attack_kind = ["slash","sweep","lunge"][attacks_started%3]
		elif attacks_started%3==2: attack_kind = "sweep"
		facing = offset.normalized()
		windup = profile().warning
		state = "windup"
		route.clear()
		return Vector2.ZERO
	if archetype=="gloam_arbalist" and sight:
		facing = offset.normalized()
		if distance<160: return -facing*.4
		if distance<400: return Vector2.ZERO
	if distance<95 and cooldown>0:
		facing = offset.normalized()
		return Vector2.ZERO
	return _toward(hub.player.position,.3)

func try_attack(aim := Vector2.ZERO) -> bool:
	var accepted := super.try_attack(aim)
	if accepted: bolt_released = false
	return accepted

func attack_contains(point: Vector2) -> bool:
	if attack_kind=="thrust":
		var offset := ground_vector(point-position)
		return offset.dot(facing)>=0 and offset.dot(facing)<=180 and absf(offset.dot(facing.orthogonal()))<=26
	return super.attack_contains(point)

func resolve_hits() -> void:
	if attack_kind!="bolt":
		super.resolve_hits()
		return
	if bolt_released or not active or hub.paused or hub.transitioning: return
	bolt_released = true
	var bolt := Bolt.new()
	bolt.hub = hub
	bolt.source = self
	bolt.heading = facing
	bolt.position = position+Vector2(facing.x,facing.y*GROUND_Y)*23
	hub.world.add_child(bolt)

func _draw() -> void:
	if not active or not is_instance_valid(sprite): return
	draw_set_transform(Vector2(0,-2),0,Vector2(1,GROUND_Y))
	draw_circle(Vector2.ZERO,32 if is_boss() else 20,Color(.07,.09,.13,.25))
	if windup>0:
		var tint := Color("e9a77b")
		if attack_kind in ["bolt","thrust","lunge"]:
			var reach := float(profile().reach) if attack_kind!="lunge" else 240.0
			var width := 12.0 if attack_kind=="bolt" else 26.0
			var normal := facing.orthogonal()*width
			var polygon := PackedVector2Array([-normal,normal,facing*reach+normal,facing*reach-normal])
			draw_colored_polygon(polygon,Color(tint,.17))
			polygon.append(polygon[0])
			draw_polyline(polygon,Color(tint,.85),2,true)
		else:
			var spread := acos(float(profile().cosine))
			var area := PackedVector2Array([Vector2.ZERO])
			for i in 25: area.append(Vector2.from_angle(facing.angle()-spread+i*spread/12)*float(profile().reach))
			draw_colored_polygon(area,Color(tint,.2))
			draw_arc(Vector2.ZERO,profile().reach,facing.angle()-spread,facing.angle()+spread,40,Color(tint,.85),2,true)
	draw_set_transform(Vector2.ZERO)
	if not is_boss():
		EnemyHealth.mob(self,Vector2(0,-sprite.display_height-17),level,health,maximum_health)

