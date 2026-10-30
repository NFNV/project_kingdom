extends RefCounted

# One continuous area: six times the ground area of the earlier forest plates.
const SIZE := Vector2i(4608,2592)
const ENTRY := Vector2(420,1900)
const CAMPS := [Vector2(1550,1650),Vector2(2500,1050),Vector2(3610,1430),Vector2(3180,2180)]
const ROUTE := [ENTRY,Vector2(1100,1900),CAMPS[0],Vector2(2080,1500),CAMPS[1],Vector2(3100,1140),CAMPS[2],Vector2(3630,2000),CAMPS[3],Vector2(2200,2160),Vector2(1400,2200),ENTRY]


static func floor_polygon() -> PackedVector2Array:
	return PackedVector2Array([Vector2(120,120),Vector2(4488,120),Vector2(4488,2472),Vector2(120,2472)])


static func trees() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 718203
	for row in 14:
		for column in 25:
			var at := Vector2(100+column*183+rng.randf_range(-48,48),230+row*177+rng.randf_range(-42,42))
			# Branching clearings and a looping walking route remain unobstructed.
			var clearance := INF
			for index in ROUTE.size()-1:
				clearance = minf(clearance,at.distance_to(Geometry2D.get_closest_point_to_segment(at,ROUTE[index],ROUTE[index+1])))
			for camp in CAMPS:
				clearance = minf(clearance,at.distance_to(camp)-100)
			if clearance<150 or at.distance_to(ENTRY)<280:
				continue
			result.append({"at":at,"height":rng.randf_range(210,310),"asset":"elm_tree" if rng.randf()<.7 else "willow_tree"})
	return result


static func build(hub: Node2D) -> void:
	hub._solid(floor_polygon(),true)
	for tree in trees():
		var anchor: Node2D = hub._piece(tree.asset,tree.at,tree.height)
		# Unique phase avoids every crown moving in lockstep, shared image resources.
		var material: ShaderMaterial = anchor.get_child(0).material.duplicate()
		material.set_shader_parameter("phase",fmod(tree.at.x*.019+tree.at.y*.023,TAU))
		anchor.get_child(0).material = material
		hub._solid(hub._ellipse(tree.at+Vector2(0,-5),Vector2(20,13)))
	for pack in CAMPS.size():
		for member in 3:
			var id := "wild_dog_%d_%d" % [pack,member]
			var returning: bool = hub.forest_defeated.size()==12
			var casualties: Dictionary = hub.state.forest_patrol_defeated if returning else hub.forest_defeated
			if casualties.has(id):
				continue
			var at: Vector2 = CAMPS[pack]+[Vector2(-70,15),Vector2(65,20),Vector2(0,-60)][member]
			var dog = hub._actor(false,at,"mauler" if member==2 else "raider")
			dog.resident_id = id
			dog.set_meta("returning_patrol",returning)
			dog.enemy = true
			dog.home = at
			dog.patrol = PackedVector2Array([at,at+Vector2(65,30),at+Vector2(-45,38)])
			dog.patrol_wait = .5+member*.65+pack*.17
			dog.maximum_health = 3
			dog.health = 3
			if id==hub.GameState.CAPTAIN_ID and not returning:
				dog.captain = true
				dog.maximum_health = 8
				dog.health = 8
				dog.sprite.display_height *= 1.09
			dog.path_timer = (pack*3+member)*.037
			hub.dogs.append(dog)
	hub.combat_active = not hub.dogs.is_empty()
	hub.trail_effects = Node2D.new()
	hub.trail_effects.z_index = 2
	hub.zone_root.add_child(hub.trail_effects)
	hub.trail_effects.draw.connect(hub._draw_forest_air)


static func build_navigation(hub: Node2D) -> void:
	# Rasterize each tree only inside its padded bounds. Avoid N cells × N trees.
	var grid: AStarGrid2D = hub.navigation
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var cell := Vector2i(x,y)
			var at := grid.get_point_position(cell)
			var safe := Geometry2D.is_point_in_polygon(at,hub.FLOOR)
			if safe:
				for index in hub.FLOOR.size():
					if at.distance_to(Geometry2D.get_closest_point_to_segment(at,hub.FLOOR[index],hub.FLOOR[(index+1)%hub.FLOOR.size()]))<20:
						safe = false
						break
			grid.set_point_solid(cell,not safe)
	for polygon in hub.blockers:
		var bounds := Rect2(polygon[0],Vector2.ZERO)
		for vertex in polygon:
			bounds = bounds.expand(vertex)
		bounds = bounds.grow(22)
		var start := Vector2i(bounds.position/32)
		var end := Vector2i(bounds.end/32)+Vector2i.ONE
		for x in range(maxi(0,start.x),mini(grid.region.size.x,end.x+1)):
			for y in range(maxi(0,start.y),mini(grid.region.size.y,end.y+1)):
				var cell := Vector2i(x,y)
				var at := grid.get_point_position(cell)
				var blocked := Geometry2D.is_point_in_polygon(at,polygon)
				for i in polygon.size():
					if at.distance_to(Geometry2D.get_closest_point_to_segment(at,polygon[i],polygon[(i+1)%polygon.size()]))<20:
							blocked = true
							break
				if blocked:
					grid.set_point_solid(cell,true)
