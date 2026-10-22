extends SceneTree

const DEMO := preload("res://experiments/town_skirmish_v03/demo.tscn")
var game: Node3D
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = DEMO.instantiate()
	root.add_child(game)
	for tick in 15:
		await physics_frame
	_freeze_enemies()
	_check(not game.started,"Opening waits for the player's first action")
	_check(game.resident.cat and game.resident.controlled,"Cat is the playable fighter")
	_check(_dogs().size()==6,"Six dog patrols spawn")
	_check(game.fighters.size()==8,"Cat guard accompanies player")
	_check(game.resident.health.current==8,"Player starts with full health")
	_check(game.resident.is_on_floor(),"Player feet rest on native floor")
	_check(not game.textures.has("cottage") and not game.textures.has("shop"),"Angled building cards are not used")
	_check(game.buildings.size()==2,"Two actual 3D buildings")
	for building in game.buildings:
		_check(building.global_basis.is_equal_approx(Basis.IDENTITY),"Building shares street's world axes")
		var a: Vector3 = building.global_position+Vector3(-2,0,2)
		var b: Vector3 = building.global_position+Vector3(2,0,2)
		var screen_edge: Vector2 = (game.camera.unproject_position(b)-game.camera.unproject_position(a)).normalized()
		var street_edge: Vector2 = (game.camera.unproject_position(Vector3(2,0,0))-game.camera.unproject_position(Vector3(-2,0,0))).normalized()
		_check(screen_edge.dot(street_edge)>0.9999,"Foundation projects parallel to street")
		var roof_count := 0
		for node in building.get_children():
			if node is MeshInstance3D and node.mesh is ArrayMesh and node.material_override==building.plaster:
				var gable_normals: PackedVector3Array = node.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
				_check(gable_normals[0].z*node.mesh.get_aabb().get_center().z>0.1,"Gable faces outwards without double-sided material")
			if node is MeshInstance3D and node.material_override==building.slate:
				if node.name.begins_with("RoofSlope"):
					roof_count += 1
				var normals: PackedVector3Array = node.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
				_check(normals[0].y>0.1,"Roof slope normals face upward")
		_check(roof_count==2,"Roof has two connected 3D slopes")
	var start := Vector3(-5,0.06,0)
	var end := await _walk(start,["hd_right"],30)
	var distance := Vector2(end.x-start.x,end.z-start.z).length()
	_check(game.started,"Player movement starts the battle")
	_check(absf(distance-2.0)<0.15,"Player walking speed")
	end = await _walk(start,["hd_right","hd_up"],30)
	_check(absf(Vector2(end.x-start.x,end.z-start.z).length()-distance)<0.15,"Diagonal speed is normalized")
	end = await _walk(start,["hd_right","hd_run"],30)
	_check(absf(Vector2(end.x-start.x,end.z-start.z).length()-3.0)<0.2,"Shift runs faster")
	var route: PackedVector3Array = game.find_path(Vector3(-11,0,-7),Vector3(-3.5,0,-7))
	_check(route.size()>3,"Navigation routes around cottage")
	var avoids_walls := true
	for point in route:
		for solid in game.solids:
			if solid.grow(0.28).has_point(Vector2(point.x,point.z)):
				avoids_walls = false
	_check(avoids_walls,"Navigation avoids padded solid footprints")
	_check(game.clear_line(Vector3(-5,0,0),Vector3(-3,0,0)),"Road has clear line of sight")
	_check(not game.clear_line(Vector3(-7.4,0,-3),Vector3(-7.4,0,-10)),"Cottage blocks line of sight")
	game.resident.position = start
	game.resident.velocity = Vector3.ZERO
	var victim = _dummy(Vector3(-3.6,0.06,0),false)
	var friendly = _dummy(Vector3(-4,0.06,0.3),true)
	var behind = _dummy(Vector3(-6.2,0.06,0),false)
	var far = _dummy(Vector3(-2.5,0.06,0),false)
	_check(game.resident.try_attack(Vector3.RIGHT),"Player starts a melee swing")
	_check(not game.resident.try_attack(Vector3.RIGHT),"Swing cannot restart while active")
	game.resident.resolve_hits()
	_check(victim.health.current==2,"Melee hits enemy in facing cone")
	_check(friendly.health.current==3,"Melee does not damage friendly faction")
	_check(behind.health.current==3,"Melee excludes enemies behind player")
	_check(far.health.current==3,"Melee excludes out-of-range enemies")
	victim.health.invulnerability = 0
	game.resident.resolve_hits()
	_check(victim.health.current==2,"Each enemy is hit once per swing")
	game.resident.position = Vector3(-7.4,0.06,-4.2)
	var wall_victim = _dummy(Vector3(-7.4,0.06,-5.4),false)
	game.resident.facing = Vector3.FORWARD
	game.resident.hit_targets.clear()
	game.resident.resolve_hits()
	_check(wall_victim.health.current==3,"Melee cannot hit through a building")
	game.resident.attacking = false
	game.resident.cooldown = 0
	game.resident.position = Vector3(0,0.06,0)
	game.resident.health.invulnerability = 0
	var attacker = _dummy(Vector3(1,0.06,0),false)
	attacker.try_attack(Vector3.LEFT)
	attacker.advance_attack(0.20)
	_check(game.resident.health.current==8,"Dog windup gives warning before damage")
	attacker.advance_attack(0.25)
	_check(game.resident.health.current==7,"Dog strike deals damage after windup")
	_check(not game.resident.receive_hit(1,Vector3.LEFT),"Player has a damage grace period")
	var hunter = _dummy(Vector3(3.5,0.06,0),false)
	var intent: Vector3 = hunter._ai(0.1)
	_check(hunter.state=="chase" and intent.length()>0.1,"Dog chases nearby cat along a path")
	game.resident.position = Vector3(20,0.06,20)
	hunter._ai(0.1)
	_check(hunter.state!="chase","Dog leash stops pursuit outside its territory")
	game.resident.position = Vector3(0,0.06,2)
	game.resident.velocity = Vector3.ZERO
	_key(KEY_ESCAPE)
	_check(paused,"Esc pauses battle")
	var before: Vector3 = game.resident.position
	Input.action_press("hd_right")
	for tick in 10:
		await physics_frame
	Input.action_release("hd_right")
	_check(game.resident.position.is_equal_approx(before),"Paused player stays still")
	_key(KEY_ESCAPE)
	_check(not paused,"Esc resumes battle")
	game.restart_battle()
	await process_frame
	_freeze_enemies()
	game.resident.process_mode = Node.PROCESS_MODE_DISABLED
	game.resident.position = game.OBJECTIVE+Vector3(0,0.03,0)
	game.advance_capture(4.1)
	_check(game.captured==0,"Nearby living dogs contest capture")
	for dog in _dogs():
		dog.health.current = 0
	game.advance_capture(2.0)
	_check(absf(game.captured-0.5)<0.001,"Clear objective fills over four seconds")
	game.resident.position += Vector3(4,0,0)
	game.advance_capture(0.5)
	_check(game.captured<0.5,"Capture decays when cat leaves ring")
	game.resident.position = game.OBJECTIVE+Vector3(0,0.03,0)
	game.advance_capture(4.1)
	_check(game.finished and game.won,"Capturing square wins battle")
	_check(game.flag_material.albedo_color==Color("d78572"),"Captured objective changes to cat colors")
	_key(KEY_R)
	await process_frame
	_freeze_enemies()
	_check(not game.finished and not game.started and game.resident.health.current==8 and game.captured==0 and _dogs().size()==6,"R restores a fresh battle")
	game.resident.health.invulnerability = 0
	game.resident.receive_hit(20,Vector3.LEFT)
	_check(game.finished and not game.won and game.overlay.visible,"Player death shows defeat")
	_key(KEY_R)
	await process_frame
	_freeze_enemies()
	root.size = Vector2i(2560,1440)
	await process_frame
	await process_frame
	_check(root.get_texture().get_size()==Vector2(1920,1080),"Window resizing preserves render resolution")
	root.size = Vector2i(1280,720)
	print("Town skirmish: %d/%d checks passed." % [checks-failures,checks])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)


func _dummy(at: Vector3, cat: bool):
	var fighter = game._spawn_fighter(at,cat,false,false)
	fighter.process_mode = Node.PROCESS_MODE_DISABLED
	fighter.collision_layer = 0
	fighter.collision_mask = 0
	return fighter


func _dogs() -> Array:
	return game.fighters.filter(func(f):return is_instance_valid(f) and not f.cat)


func _freeze_enemies() -> void:
	for fighter in game.fighters:
		if not fighter.controlled:
			fighter.process_mode = Node.PROCESS_MODE_DISABLED


func _walk(start: Vector3, actions: Array, ticks: int) -> Vector3:
	game.resident.position = start
	game.resident.velocity = Vector3.ZERO
	await physics_frame
	for tick in ticks:
		for action: String in actions:
			Input.action_press(action)
		await physics_frame
	for action: String in actions:
		Input.action_release(action)
	var end: Vector3 = game.resident.position
	await physics_frame
	return end


func _key(key: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	game._unhandled_key_input(event)


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
