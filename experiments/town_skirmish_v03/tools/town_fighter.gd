extends CharacterBody3D

signal died(fighter)
const HEALTH := preload("res://scripts/combat/health.gd")
const CONTACT_SHADOW := preload("res://experiments/town_skirmish_v03/tools/contact_shadow.gdshader")
var town: Node3D
var cat := false
var controlled := false
var ally := false
var home := Vector3.ZERO
var patrol_end := Vector3.ZERO
var returning := false
var patrol_forward := true
var state := "patrol"
var health: Node
var visual: AnimatedSprite3D
var status: Label3D
var reach := 1.55
var facing := Vector3.RIGHT
var attacking := false
var attack_elapsed := 0.0
var cooldown := 0.0
var invincibility_flash := 0.0
var knockback := Vector3.ZERO
var hit_targets: Array[int] = []
var death_time := 0.0
var repath := 0.0
var path := PackedVector3Array()
var path_index := 0
var fx: MeshInstance3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	collision_layer = 2
	collision_mask = 3
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.15
	collision.shape = capsule
	collision.position.y = 0.59
	add_child(collision)
	health = HEALTH.new()
	health.maximum = 8 if controlled else (6 if ally else 3)
	add_child(health)
	health.reset()
	health.died.connect(_die)
	var shadow := MeshInstance3D.new()
	var shadow_mesh := PlaneMesh.new()
	shadow_mesh.size = Vector2(1.35,0.8)
	shadow.mesh = shadow_mesh
	shadow.position.y = 0.035
	var shadow_material := ShaderMaterial.new()
	shadow_material.shader = CONTACT_SHADOW
	shadow.material_override = shadow_material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	visual = AnimatedSprite3D.new()
	visual.sprite_frames = load("res://experiments/town_skirmish_v03/assets/characters/%s_warrior.tres" % ("cat" if cat else "dog"))
	visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visual.pixel_size = 2.5/320.0
	# Existing atlas margins put each pair of feet at y=288 of the 320px canvas.
	visual.position = town.camera.global_basis.y * (128.0*visual.pixel_size)
	visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	visual.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	visual.alpha_scissor_threshold = 0.85
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	visual.play("guard" if ally else "idle")
	status = Label3D.new()
	status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status.position.y = 1.95
	status.font_size = 32
	status.pixel_size = 0.009
	status.modulate = Color("ffbd8e")
	add_child(status)
	fx = MeshInstance3D.new()
	fx.mesh = ImmediateMesh.new()
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color("f6c773") if cat else Color("ef9176")
	fx.material_override = material
	add_child(fx)
	if controlled:
		var marker := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.28
		ring.outer_radius = 0.32
		ring.rings = 24
		ring.ring_segments = 6
		marker.mesh = ring
		marker.position.y = 0.06
		marker.material_override = material
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marker)
	_update_status()


func _physics_process(delta: float) -> void:
	if health.is_dead():
		death_time += delta
		visual.modulate.a = maxf(0.15 if controlled else 0.0,1.0-death_time*1.7)
		if not controlled and death_time > 0.7:
			queue_free()
		return
	if town.finished:
		visual.play("idle")
		return
	cooldown = maxf(0.0,cooldown-delta)
	invincibility_flash = maxf(0.0,invincibility_flash-delta)
	var movement := Vector3.ZERO
	if controlled:
		var input := Input.get_vector("hd_left","hd_right","hd_up","hd_down")
		if input.length_squared()>0.01 or Input.is_action_pressed("sk_attack") or Input.is_action_pressed("sk_mouse_attack"):
			town.started = true
		var right := Vector3(town.camera.global_basis.x.x,0,town.camera.global_basis.x.z).normalized()
		var forward := Vector3(-town.camera.global_basis.z.x,0,-town.camera.global_basis.z.z).normalized()
		movement = (right*input.x-forward*input.y).normalized()
		if Input.is_action_pressed("sk_attack"):
			try_attack(facing)
		elif Input.is_action_pressed("sk_mouse_attack"):
			try_attack(town.mouse_aim(global_position))
	elif not ally:
		movement = _ai(delta)
	var speed := (6.0 if Input.is_action_pressed("hd_run") else 4.0) if controlled else (2.2 if state=="chase" else 0.9)
	if movement.length_squared()>0.01 and not attacking:
		facing = movement.normalized()
	advance_attack(delta)
	velocity.x = movement.x * speed * (0.3 if attacking else 1.0) + knockback.x
	velocity.z = movement.z * speed * (0.3 if attacking else 1.0) + knockback.z
	velocity.y -= 20.0*delta
	knockback = knockback.move_toward(Vector3.ZERO,14.0*delta)
	move_and_slide()
	var horizontal_facing := facing.dot(town.camera.global_basis.x)
	if absf(horizontal_facing)>0.05:
		visual.flip_h = horizontal_facing<0
	var animation := "guard" if ally else ("attack" if attacking else ("run" if movement.length_squared()>0.01 else "idle"))
	if visual.animation != animation:
		visual.play(animation,0.55 if animation=="attack" and not controlled else 1.0)
	visual.modulate = Color(1.0,0.45,0.35) if invincibility_flash>0 else Color.WHITE
	if controlled and health.invulnerability>0:
		visual.modulate.a = 0.55 if fmod(health.invulnerability,0.12)<0.06 else 1.0
	_update_status()
	_draw_swing()


func try_attack(direction: Vector3) -> bool:
	if attacking or cooldown>0 or health.is_dead() or town.finished:
		return false
	facing = Vector3(direction.x,0,direction.z).normalized()
	if facing.is_zero_approx():
		facing = Vector3.RIGHT
	attacking = true
	attack_elapsed = 0.0
	hit_targets.clear()
	visual.play("attack",1.0 if controlled else 0.55)
	visual.set_frame_and_progress(0,0)
	return true


func advance_attack(delta: float) -> void:
	if not attacking:
		return
	attack_elapsed += delta
	var windup := 0.12 if controlled else 0.40
	if attack_elapsed >= windup and attack_elapsed < windup+0.15:
		resolve_hits()
	if attack_elapsed >= (0.44 if controlled else 0.72):
		attacking = false
		cooldown = 0.14 if controlled else 0.65


func resolve_hits() -> void:
	for target in town.fighters:
		if not is_instance_valid(target) or target==self or target.cat==cat or target.health.is_dead():
			continue
		var offset: Vector3 = target.global_position-global_position
		offset.y = 0
		if offset.length()>reach or facing.dot(offset.normalized())<0.20:
			continue
		if target.get_instance_id() in hit_targets or not town.clear_line(global_position,target.global_position):
			continue
		hit_targets.append(target.get_instance_id())
		target.receive_hit(1,offset.normalized())


func receive_hit(amount: int, direction: Vector3) -> bool:
	if not health.take_damage(amount,0.60 if controlled else 0.16):
		return false
	attacking = false
	cooldown = 0.18
	knockback = direction*3.5
	invincibility_flash = 0.12
	var number := Label3D.new()
	number.text = "−%d" % amount
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.position.y = 1.8
	number.font_size = 48
	number.pixel_size = 0.01
	number.modulate = Color("fff0b4")
	add_child(number)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(number,"position:y",2.5,0.5)
	tween.tween_property(number,"modulate:a",0.0,0.5)
	tween.chain().tween_callback(number.queue_free)
	return true


func _ai(delta: float) -> Vector3:
	if not town.started:
		return Vector3.ZERO
	var player = town.resident
	if player.health.is_dead():
		return Vector3.ZERO
	var offset: Vector3 = player.global_position-global_position
	offset.y = 0
	var distance := offset.length()
	var destination := home
	if distance<6.5 and player.global_position.distance_to(home)<13.0:
		state = "chase"
		destination = player.global_position
		if distance<1.25 and town.clear_line(global_position,player.global_position):
			try_attack(offset)
			return Vector3.ZERO
	elif global_position.distance_to(home)>1.1:
		state = "return"
	else:
		state = "patrol"
		destination = patrol_end if patrol_forward else home
		if global_position.distance_to(destination)<0.4:
			patrol_forward = not patrol_forward
	repath -= delta
	if repath<=0:
		path = town.find_path(global_position,destination)
		path_index = 0
		repath = 0.35
	while path_index<path.size() and Vector2(global_position.x-path[path_index].x,global_position.z-path[path_index].z).length()<0.35:
		path_index += 1
	if path_index>=path.size():
		return Vector3.ZERO
	var direction: Vector3 = path[path_index]-global_position
	direction.y = 0
	# Local separation keeps multiple dogs from occupying exactly the same route.
	for other in town.fighters:
		if not is_instance_valid(other) or other==self or other.health.is_dead():
			continue
		var away: Vector3 = global_position-other.global_position
		away.y = 0
		if away.length()>0.01 and away.length()<0.65:
			direction += away.normalized()*(0.65-away.length())*2.0
	return direction.normalized()


func _update_status() -> void:
	status.visible = not controlled and not health.is_dead() and (ally or state=="chase" or health.current<health.maximum)
	status.text = "CAT GUARD" if ally else ("!" if attacking and attack_elapsed<0.4 and not controlled else "%d / %d" % [health.current,health.maximum])


func _draw_swing() -> void:
	var mesh := fx.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if not attacking:
		return
	var angle := atan2(facing.z,facing.x)
	var radius := reach * (0.95 if attack_elapsed<(0.12 if controlled else 0.40) else 0.8)
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for index in 20:
		var a := angle-1.1+float(index)/20.0*2.2
		var b := angle-1.1+float(index+1)/20.0*2.2
		mesh.surface_add_vertex(Vector3(cos(a)*radius,0.075,sin(a)*radius))
		mesh.surface_add_vertex(Vector3(cos(b)*radius,0.075,sin(b)*radius))
	mesh.surface_end()


func _die() -> void:
	attacking = false
	status.visible = false
	visual.stop()
	(fx.mesh as ImmediateMesh).clear_surfaces()
	set_deferred("collision_layer",0)
	set_deferred("collision_mask",0)
	died.emit(self)
