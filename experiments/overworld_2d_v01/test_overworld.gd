extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
const Map := preload("res://experiments/overworld_2d_v01/layout.gd")
var world: Node2D
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)
func ticks(count: int) -> void:
	for i in count:
		await physics_frame
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame
func count_3d(node: Node) -> int:
	var count := int(node is Node3D)
	for child in node.get_children():
		count += count_3d(child)
	return count
func run() -> void:
	world = load(ROOT+"world.tscn").instantiate()
	root.add_child(world)
	world.automated = true
	await ticks(2)
	check(world.mounted_rider.textures.size()==51 and not world.mounted_rider.textures.values().has(null),"Eight-direction mount has fifty-one valid shared drawing layers")
	var directional_cases := [["N",[KEY_W]],["NE",[KEY_W,KEY_D]],["E",[KEY_D]],["SE",[KEY_S,KEY_D]],["S",[KEY_S]],["SW",[KEY_S,KEY_A]],["W",[KEY_A]],["NW",[KEY_W,KEY_A]]]
	world.automated = false
	for item in directional_cases:
		world.visit(0)
		for code in item[1]: await key(code,true)
		await ticks(15)
		check(world.mounted_rider.direction_name()==item[0],"Physical keyboard movement selects mounted view "+item[0])
		for code in item[1]: await key(code,false)
		await ticks(15)
		check(world.mounted_rider.direction_name()==item[0],"Stopping retains mounted view "+item[0])
	world.automated = true
	world.visit(0)
	world.facing = Vector2(0,1)
	world.mounted_rider.set_direction(world.facing)
	var direction_rig = world.Rider.new()
	direction_rig.step(.1,2.7)
	var original_phase: float = direction_rig.phase
	var original_pose: Dictionary = direction_rig.pose()
	for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
		direction_rig.set_direction(direction)
	check(direction_rig.phase==original_phase and direction_rig.pose()==original_pose,"Turning preserves hop phase and body pose")
	direction_rig.set_direction(Vector2(0,1))
	for angle in [21.0,23.0,21.5,22.7,22.0]:
		direction_rig.set_direction(Vector2(sin(deg_to_rad(angle)),cos(deg_to_rad(angle))))
	check(direction_rig.direction_name()=="N","Direction hysteresis prevents flicker near the N/NE boundary")
	direction_rig.set_direction(Vector2(.707,.707))
	check(direction_rig.direction_name()=="NE","Committed diagonal turn selects NE")
	direction_rig.set_direction(Vector2.ZERO)
	check(direction_rig.direction_name()=="NE","Zero movement preserves the last facing")
	check(world.mounted_rider.hero_heads.size()==8 and not world.mounted_rider.hero_heads.values().has(null),"Mounted rider reuses all eight exact protagonist head views")
	check(count_3d(world)==0,"Prototype contains no 3D nodes")
	check(world.props.size()>250,"Deterministic region has trees, houses and rocks")
	check(world.can_stand(Map.START),"Starting meadow is clear")
	check(world.can_stand(Vector2(18,Map.river_z(18))),"Bridge center is walkable")
	check(not world.can_stand(Vector2(-20,Map.river_z(-20))),"River away from bridge blocks travel")
	check(not world.can_stand(Vector2(Map.BOUNDS.end.x+1,0)),"Region edge blocks travel")
	var obstacle: Dictionary = world.props[0]
	check(not world.can_stand(obstacle.p),"Scenery foot collider blocks movement")
	var worst := 0.0
	for curved in [false,true]:
		world.curved = curved
		for depth in ([18.0,28.0,40.0,55.0] if curved else [18.0,28.0,60.0,110.0,200.0]):
			for x in [-20.0,0.0,20.0]:
				var p: Vector2 = world.camera_ground+Vector2(x,depth)
				worst = maxf(worst,world.inverse_ground(world.project(p)).distance_to(p))
	check(worst<.02,"2D projection and ground shader inverse agree, flat and curved")
	# A strong globe silhouette must visibly arch across the width of the screen.
	var center_horizon: float = world.HORIZON+2*world.FOCAL*sqrt(world.curvature*(world.CAMERA_HEIGHT-world.curvature*784))
	var edge_horizon: float = world.HORIZON+2*world.FOCAL*sqrt(world.curvature*(1+pow(960.0/world.FOCAL,2))*(world.CAMERA_HEIGHT-world.curvature*784))
	check(edge_horizon-center_horizon>100,"Default curvature produces a pronounced arch across the screen")
	check(absf(world.project(world.player).y-(world.HORIZON+world.FOCAL*world.CAMERA_HEIGHT/28))<.01,"Stronger curvature keeps rider ground anchor stable")
	for strength in [.0003,world.DEFAULT_BEND,world.MAX_BEND]:
		world.curvature = strength
		var p: Vector2 = world.camera_ground+Vector2(12,45)
		check(world.inverse_ground(world.project(p)).distance_to(p)<.01,"Ground alignment at curvature %f" % strength)
	world.curvature = world.DEFAULT_BEND
	var normal_error := 0.0
	for strength in [.0003,world.DEFAULT_BEND,world.MAX_BEND]:
		world.curvature = strength
		for x in [-60.0,-25.0,0.0,25.0,60.0]:
			var p: Vector2 = world.camera_ground+Vector2(x,35)
			var tangent: Vector2 = (world.project(p+Vector2(.25,0))-world.project(p-Vector2(.25,0))).normalized()
			var sprite_up := Vector2.UP.rotated(world.surface_rotation(p))
			normal_error = maxf(normal_error,absf(tangent.dot(sprite_up)))
	check(normal_error<.001,"Scenery up is perpendicular to actual projected ground across all bend settings")
	check(world.surface_rotation(world.camera_ground+Vector2(-50,35))<0 and world.surface_rotation(world.camera_ground+Vector2(50,35))>0,"Scenery leans outward on both sides of dome")
	world.curved = false
	check(is_zero_approx(world.surface_rotation(world.camera_ground+Vector2(80,35))),"Flat mode returns scenery to upright")
	world.curved = true
	world.curvature = world.DEFAULT_BEND
	check(not world.inverse_ground(Vector2(960,200)).is_finite(),"Sky has no ground coordinate")
	world.curved = false
	var flat: Vector2 = world.project(world.camera_ground+Vector2(0,150))
	world.curved = true
	check(world.project(world.camera_ground+Vector2(0,150)).y>flat.y,"Curvature moves distant ground toward the lower horizon")
	check(world.project(world.camera_ground+Vector2(10,25)).x>world.project(world.camera_ground+Vector2(10,100)).x,"Perspective shrinks distant horizontal offsets")
	world.update_visible()
	var sorted := true
	for i in range(1,world.visible_props.size()):
		sorted = sorted and world.visible_props[i-1].p.y>=world.visible_props[i].p.y
	check(sorted,"Scenery and rider draw from far to near")
	check(world.visible_props.any(func(p: Dictionary): return p.kind=="rider"),"Rider participates in depth sorting")
	world.automated = false
	var start: Vector2 = world.player
	await key(KEY_W,true)
	await ticks(40)
	await key(KEY_W,false)
	await ticks(15)
	check(world.player.y>start.y+3,"Real W input moves the frog forward")
	check(world.camera_ground.distance_to(world.player-Vector2(0,28))<.001,"Camera tracks the logical player without projection drift")
	check(world.distance_walked>3 and world.stride>0,"Travel distance drives hopping animation")
	check(world.mounted_rider.landings>0,"Real roaming completes a hop and triggers landing")
	check(world.mounted_rider.sample(.13).elevation<0 and world.mounted_rider.sample(.54).elevation>30,"Hop has a grounded crouch and readable airborne apex")
	check(world.mounted_rider.sample(.87).height<.95,"Landing compresses the frog")
	check(world.mounted_rider.sample(.25).rider_lag!=world.mounted_rider.sample(.69).rider_lag,"Rider reacts to takeoff and descent with secondary motion")
	check(world.mounted_rider.sample(0)==world.mounted_rider.sample(1),"Loop returns to exactly the same body and limb pose")
	var max_jump := 0.0
	for i in 600:
		max_jump = maxf(max_jump,absf(world.mounted_rider.sample((i+1)/600.0).elevation-world.mounted_rider.sample(i/600.0).elevation))
	check(max_jump<1,"Hop elevation remains continuous between authored poses")
	var walk_rig = world.Rider.new()
	var run_rig = world.Rider.new()
	for i in 120:
		walk_rig.step(1.0/60,9.0/60)
		run_rig.step(1.0/60,16.0/60)
	check(run_rig.cycles>walk_rig.cycles,"Faster actual travel produces faster hops")
	world.automated = true
	world.intent = Vector2.ZERO
	await ticks(55)
	check(not world.mounted_rider.active and is_zero_approx(world.mounted_rider.pose().elevation),"Releasing movement finishes the hop and settles without freezing airborne")
	var cycles_before: int = world.mounted_rider.cycles
	await ticks(30)
	check(world.mounted_rider.cycles==cycles_before,"Idle does not keep starting hops")
	world.automated = false
	await key(KEY_F4,true)
	await key(KEY_F4,false)
	check(world.hop_study,"F4 opens live directional close-up")
	await key(KEY_W,true)
	for i in 50:
		await ticks(1)
		if world.mounted_rider.pose().elevation>20: break
	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	await key(KEY_W,false)
	var airborne_pose: Dictionary = world.mounted_rider.pose()
	await ticks(15)
	check(airborne_pose.elevation>20 and world.mounted_rider.pose()==airborne_pose,"Pausing midair preserves exact frog and rider pose")
	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	await ticks(60)
	check(not world.mounted_rider.active,"Resuming a stopped airborne hop settles naturally")
	await key(KEY_C,true)
	await key(KEY_C,false)
	check(not world.curved,"C toggles curvature through real input")
	await key(KEY_G,true)
	await key(KEY_G,false)
	check(world.grid,"G enables ground alignment grid")
	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	start = world.player
	var stopped_time: float = world.clock
	var stopped_pose: Dictionary = world.mounted_rider.pose()
	var stopped_rig_time: float = world.mounted_rider.clock
	await key(KEY_W,true)
	await ticks(15)
	await key(KEY_W,false)
	check(world.paused and world.player==start and world.clock==stopped_time,"Pause freezes travel and animation clock")
	check(world.mounted_rider.pose()==stopped_pose and world.mounted_rider.clock==stopped_rig_time,"Pause freezes exact rider pose and secondary motion")
	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	world.automated = true
	world.visit(1)
	var bridge_start: Vector2 = world.player
	for i in 240:
		world.move_player(Vector2(0,1),1.0/60)
	check(world.player.y>Map.river_z(18)+10,"Physically walk across the bridge to the far bank")
	check(world.player.y>bridge_start.y+25,"Bridge does not secretly teleport the player")
	world.player = Vector2(-20,Map.river_z(-20)-10)
	world.velocity = Vector2.ZERO
	for i in 180:
		world.move_player(Vector2(0,1),1.0/60)
	check(world.player.y<Map.river_z(-20)-Map.RIVER_HALF,"Repeated movement cannot cross river without bridge")
	world.visit(0)
	var reached := false
	for i in 3600:
		var next_z := minf(173,world.player.y+3)
		var target := Vector2(Map.road_x(next_z),next_z)
		world.move_player((target-world.player).normalized(),1.0/60)
		if world.player.y>=172:
			reached = true
			break
	check(reached,"Continuous road route connects meadow, bridge and forest without shortcuts")
	for i in 8:
		world.visit(i)
		check(world.can_stand(world.player),"Landmark shortcut %d arrives on clear ground" % i)
	world.automated = false
	await key(KEY_BRACKETRIGHT,true)
	await key(KEY_BRACKETRIGHT,false)
	check(world.curvature>world.DEFAULT_BEND,"Curvature strength adjusts via keyboard")
	await key(KEY_R,true)
	await key(KEY_R,false)
	check(world.player.distance_to(Map.START)<.01 and not world.paused,"Reset returns to the starting meadow")
	world.automated = false
	world.visit(0)
	await key(KEY_E,true)
	await ticks(30)
	await key(KEY_E,false)
	check(is_zero_approx(world.camera_yaw),"Holding E leaves the north-facing camera fixed")
	var before_camera_move: Vector2 = world.player
	var forward: Vector2 = world.camera_forward()
	await key(KEY_W,true)
	await ticks(30)
	await key(KEY_W,false)
	await ticks(15)
	check((world.player-before_camera_move).normalized().dot(forward)>.98,"W moves toward the fixed camera's north horizon")
	check(world.mounted_rider.direction_name()=="N","Walking north retains the correct mounted rear view")
	var yaw_before: float = world.camera_yaw
	await key(KEY_Q,true)
	await ticks(20)
	await key(KEY_Q,false)
	check(world.camera_yaw==yaw_before,"Holding Q leaves the camera fixed")
	await key(KEY_HOME,true)
	await key(KEY_HOME,false)
	check(is_zero_approx(world.camera_yaw),"Home cannot change the fixed north-facing view")
	world.paused = true
	await key(KEY_E,true)
	await ticks(10)
	await key(KEY_E,false)
	check(is_zero_approx(world.camera_yaw),"Paused game blocks held camera rotation")
	world.paused = false
	world.automated = true
	var fixed_error := 0.0
	var anchor_error := 0.0
	for yaw in [0.0,.7,PI/2,PI,-1.2,2.7]:
		world.camera_yaw = yaw
		world.update_camera()
		for flat_mode in [false,true]:
			world.curved = not flat_mode
			for depth in [22.0,35.0,50.0]:
				for x in [-15.0,0.0,15.0]:
					var point: Vector2 = world.camera_ground+world.world_vector(Vector2(x,depth))
					fixed_error = maxf(fixed_error,world.inverse_ground(world.project(point)).distance_to(point))
			anchor_error = maxf(anchor_error,world.project(world.player).distance_to(Vector2(960,world.HORIZON+world.FOCAL*world.CAMERA_HEIGHT/28)))
		world.update_visible()
		var depth_sorted := true
		for i in range(1,world.visible_props.size()):
			depth_sorted = depth_sorted and world.view_point(world.visible_props[i-1].p).y>=world.view_point(world.visible_props[i].p).y
		check(depth_sorted and is_zero_approx(world.camera_yaw),"Camera rejects yaw %.2f and preserves scenery depth order" % yaw)
	check(fixed_error<.01,"Ground/shader inverse agrees after six attempted camera headings")
	check(anchor_error<.01,"Locked tracking camera keeps the rider ground anchor fixed")
	world.facing = Vector2(0,1)
	world.camera_yaw = PI/2
	var phase_before: float = world.mounted_rider.phase
	world.rotate_camera(0,0)
	check(is_zero_approx(world.camera_yaw) and world.mounted_rider.direction_name()=="N","Legacy orbit caller cannot rotate the camera or change the stationary rider view")
	check(world.mounted_rider.phase==phase_before,"Fixed camera refresh does not restart the hop")
	world.camera_yaw = 0
	world.rotate_camera(0,0)
	world.curved = true
	var city_ids: Array = []
	var doors_correct := true
	for item in world.props:
		if item.kind=="city_building":
			city_ids.append(item.id)
			check(not world.can_stand(item.p),"City building footprint blocks travel: "+item.id)
			if item.style not in ["tower","wall"]:
				doors_correct = doors_correct and Vector2(0,-1).rotated(item.heading).dot(world.City.CENTER-item.p)>0
	check(city_ids.has("community_hall") and city_ids.has("clock_tower") and city_ids.has("bluebird_bakery") and city_ids.has("grocer"),"Chibi Mosswood includes main-city landmarks")
	check(doors_correct,"City entrances face into the plaza")
	check(not world.can_stand(world.City.CENTER),"Garden Square fountain has a collision footprint")
	check(world.can_stand(world.City.CENTER+Vector2(3,0)),"Paved fountain plaza has clear walking space")
	world.visit(3)
	await ticks(2)
	check(world.can_stand(world.player) and world.near_landmark.contains("MOSSWOOD"),"City shortcut arrives safely at the main-city entrance")
	var city_normal_error := 0.0
	for yaw in [0.0,PI/2,PI,-PI/2]:
		world.camera_yaw = yaw
		world.update_camera()
		var point: Vector2 = world.camera_ground+world.world_vector(Vector2(12,45))
		var up: Vector2 = (world.City.project(world,point,5)-world.City.project(world,point)).normalized()
		city_normal_error = maxf(city_normal_error,absf(up.dot(Vector2.RIGHT.rotated(world.surface_rotation(point)))))
	check(city_normal_error<.001,"City layout remains aligned to the curved surface under attempted camera changes")
	world.camera_yaw = 0
	world.update_camera()
	var hero_reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(world.Rider.ART+"hero_reference.json"))
	check(hero_reference.directions.size()==8 and hero_reference.directions.e.source.contains("anime_hub_demo_v07/assets/motion"),"Mounted identity references the playable protagonist's original artwork")
	# Larger region: verify navigable routes and water boundaries, not only teleports.
	check(Map.BOUNDS.get_area()>130000,"Region is more than three times the original map area")
	check(world.props.size()>850,"Expanded region contains distributed painted scenery")
	check(["windmill","ruins","willow","pine","rock"].all(func(id: String): return world.textures.has(id) and world.textures[id]!=null),"Painted landscape textures are cached and valid")
	check(not world.can_stand(Map.LAKE),"Lake water blocks walking")
	check(not world.can_stand(Vector2(Map.coast_x(350)+4,350)),"Open sea blocks walking")
	var route_clear := true
	var route_samples := 0
	for route in Map.ROUTES:
		for i in range(1,route.size()):
			var length: float = route[i-1].distance_to(route[i])
			for step in ceili(length*2)+1:
				var p: Vector2 = route[i-1].lerp(route[i],minf(1,step/(length*2)))
				if p.distance_to(Map.WINDMILL)<5 or p.distance_to(Map.RUINS)<5: continue
				route_samples += 1
				route_clear = route_clear and world.can_stand(p)
	check(route_clear and route_samples>1400,"Every branch road is walkable at half-unit spacing outside landmark footprints")
	# Walk an actual branching journey from the north bank to Windmill Ridge.
	world.player = Vector2(18,105)
	world.velocity = Vector2.ZERO
	var walked_route := true
	for target in [Vector2(-25,120),Vector2(-95,135),Map.WINDMILL+Vector2(10,-15)]:
		for i in 1800:
			if world.player.distance_to(target)<.4: break
			world.move_player((target-world.player).normalized(),1.0/60,true)
		walked_route = walked_route and world.player.distance_to(target)<.4
	check(walked_route,"Physical branching road journey reaches Windmill Ridge without teleporting")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4431
	var grid_correct := true
	for sample in 600:
		var point := Vector2(rng.randf_range(-240,240),rng.randf_range(-80,480))
		var brute: bool = Map.safe_ground(point)
		for item in world.props:
			if item.kind=="city_building": brute = brute and not world.City.blocks(item,point)
			else: brute = brute and point.distance_squared_to(item.p)>=pow(item.radius+.65,2)
		grid_correct = grid_correct and world.can_stand(point)==brute
	check(grid_correct,"Spatial collision grid agrees with a full scenery scan over 600 positions")
	world.visit(3)
	world.curved = true
	world.camera_yaw = 0
	world.update_camera()
	var city_left := INF
	var city_right := -INF
	for item in world.City.props():
		var position: Vector2 = world.project(item.p)
		city_left = minf(city_left,position.x)
		city_right = maxf(city_right,position.x)
	check(city_left>100 and city_right<1800 and city_right-city_left<1920*.38,"Whole miniature city fits together within the approach view")
	world.automated = false
	await key(KEY_M,true)
	await key(KEY_M,false)
	var map_start: Vector2 = world.player
	var map_time: float = world.clock
	await key(KEY_W,true)
	await ticks(20)
	await key(KEY_W,false)
	check(world.region_map and world.player==map_start and world.clock==map_time,"Regional map opens with M and freezes travel and animation")
	check(not world.scenery.visible and not world.terrain.visible,"Opaque regional map skips rendering the hidden world")
	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	check(not world.region_map and not world.paused,"Esc closes map and returns directly to roaming")
	check(world.scenery.visible and world.terrain.visible,"Closing region map restores world drawing")
	await key(KEY_M,true)
	await key(KEY_M,false)
	await key(KEY_8,true)
	await key(KEY_8,false)
	check(not world.region_map and world.player.distance_to(Map.COAST)<1,"Destination shortcut works from the regional map")
	world.automated = true
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"max_projection_roundtrip_error":worst,"scope":"Actual keyboard roaming, curvature controls, pause, camera alignment, inverse projection, sprite depth ordering, scenery collisions, river barrier, physical bridge crossing and continuous meadow-to-forest road travel, eight-direction mount layers and actual keyboard selection, facing retention, direction hysteresis, phase-preserving turns, crouch/push-off/flight/landing, smooth loop, idle settle, sprint cadence and frozen pause pose. Fixed north-facing keyboard steering, Q/E lock, ignored legacy orbit calls, six attempted heading changes with inverse projection and depth sorting, original protagonist identity, main-city landmarks and physical footprints. Expanded regional routes, physical windmill journey, miniature city framing, lake and sea barriers, spatial grid/brute-force agreement and regional-map controls. No 3D nodes and no game save I/O."}
	FileAccess.open(ROOT+"test_results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("OVERWORLD CHECKS ",checks-failures.size(),"/",checks)
	quit(0 if failures.is_empty() else 1)
