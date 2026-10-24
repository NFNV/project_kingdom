extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame

func walk_to(at: Vector2, frames := 3600) -> void:
	var path: PackedVector2Array = game.find_path(game.player.position,at)
	check(not path.is_empty(),"Walkable route reaches "+str(at))
	game.player.route = path
	for tick in frames:
		await physics_frame
		if game.player.route.is_empty() or game.transitioning:
			break

func wait_travel(destination: String) -> void:
	for tick in 180:
		await physics_frame
		if game.zone==destination and not game.transitioning:
			break
	check(game.zone==destination and not game.transitioning,"Physical passage arrives in "+destination)

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	game.auto_clock = false
	await ticks(3)
	game.quest_stage = 2
	game.discoveries.old_elm = true
	game.clock = 1.25
	game.coins = 19
	game.inventory.tea = 2
	game.forest_defeated.test_previous_defeat = true
	var identity: int = game.player.get_instance_id()
	check(game.exits.has("north") and game.exits.north.to=="district","Garden Square's northern passage connects to Northgate")
	await walk_to(game.exits.north.at)
	await wait_travel("district")
	if game.zone!="district":
		print("NORTH ENTRY DEBUG ",game.player.position," ",game.player.route)
		quit(1)
		return
	check(game.player.get_instance_id()==identity,"The same cat and attached camera travel north")
	check(game.world_size==Vector2i(6400,3840) and game.navigation.region.size==Vector2i(200,120),"The district has a full-size 6400x3840 world and navigation grid")
	check(game.camera.limit_right==6400 and game.camera.limit_bottom==3840 and game.camera.zoom.x==1.5,"Camera follows through the large town at the player's existing zoom")
	check(game.Map.District.houses().size()==48 and get_nodes_in_group("district_buildings").size()==52,"Forty-eight homes, three shops and a civic hall are real separate buildings")
	check(game.residents.size()==14 and game.humans.size()==4 and game.dogs.size()==2,"Twenty animals, taller humans and peaceful strolling wardens populate the district")
	check(game.peaceful_mode and not game.combat_active and not game.player.try_attack() and not game.player.try_skill(),"The new town district remains peaceful")
	check(game.is_walkable(game.player.position,14),"Northern district arrival has a safe collision footprint")
	var aligned := true
	var styles: Dictionary = {}
	var front_directions: Dictionary = {}
	for building in get_nodes_in_group("district_buildings"):
		var sprite: Sprite2D = building.get_child(0)
		aligned = aligned and is_zero_approx(sprite.rotation) and is_equal_approx(sprite.scale.x,sprite.scale.y) and not sprite.flip_h
		var vertical: Vector2 = building.p(0,0,100)-building.p(0,0,0)
		aligned = aligned and vertical.is_equal_approx(Vector2(0,-100))
	check(aligned,"Actual wall geometry stays plumb and uses the street grid, not merely unrotated cutouts")
	for data in game.Map.District.houses():
		styles[data.style] = true
		front_directions[Vector2(data.front_axis,data.front_sign)] = true
		var door: Vector2 = game.Map.District.Layout.door_uv(data)
		var sidewalk: Vector2 = game.Map.District.Layout.sidewalk_uv(data)
		check((sidewalk[data.front_axis]-door[data.front_axis])*data.front_sign>0,"House front faces outward toward its own sidewalk: "+str(Vector2(data.u,data.v)))
		var step: Vector2 = game.Map.District.Layout.doorstep(data)
		check(game.is_walkable(step,14) and not game.find_path(game.player.position,step).is_empty(),"A physical path reaches the correctly placed doorstep: "+str(step))
	check(styles.size()==8 and front_directions.size()==4,"Eight distinct architectural recipes cover all four street-facing directions")
	var motion_before: Array[Vector2] = []
	for dog in game.dogs:
		motion_before.append(dog.position)
	for place in ["plaza","park","market","civic","west","east"]:
		await walk_to(game.Map.District.PLACES[place])
		check(game.player.position.distance_to(game.Map.District.PLACES[place])<48,"Actual walking reaches Northgate / "+place)
		check(game.is_walkable(game.player.position,14),"Town destination has a clear physical footprint: "+place)
		game.camera.force_update_scroll()
		if place=="east":
			check(game.camera.get_screen_center_position().x>4500,"Camera really follows into the far eastern neighbourhood")
		if place in ["plaza","park","civic"]:
			var id: String = "north_place_"+place
			await ticks(4)
			check(game.nearest==id,"The named landmark has a reachable E prompt: "+place)
			game.interact(id)
			check(game.district_places.has(id) and game.talk_text.text.length()>50,"Landmark conversation records the town visit: "+place)
	var strolling := false
	for i in game.dogs.size():
		strolling = strolling or game.dogs[i].position.distance_to(motion_before[i])>20
	check(strolling,"At least one friendly warden physically strolls through the streets")
	check(game.district_places.size()==3 and game.discoveries.size()==1,"Town places do not overwrite or inflate forest memories")
	var house: Dictionary = game.Map.District.houses()[0]
	check(not game.is_walkable(game.Map.District.iso(house.u,house.v),0),"House walls have solid ground footprints")
	var step: Vector2 = game.Map.District.Layout.doorstep(house)
	await walk_to(step)
	check(game.player.position.distance_to(step)<50,"The cat physically reaches a northern lot's actual front doorstep")
	var first = get_nodes_in_group("district_buildings")[0]
	var house_sprite: Sprite2D = first.get_child(0)
	var safe_at: Vector2 = game.player.position
	game.player.position = first.position+Vector2(0,-170)
	game._update_lighting()
	check(house_sprite.modulate.a<.5,"A building fades when it obscures the cat")
	game.player.position = game.Map.District.ENTRY
	game._update_lighting()
	check(house_sprite.modulate.a>.95,"Building opacity returns when the cat is clear")
	# Conversation uses the same proximity/navigation pipeline as other residents.
	var target: Dictionary = game.interactables.north_human_3
	await walk_to(target.at+Vector2(55,55))
	check(game.player.position.distance_to(target.at)<140,"The player can approach a human town resident")
	game.interact("north_human_3")
	check(game.talk_name.text.contains("Mira") and game.talk_text.text.contains("Northgate"),"The human has a distinct named town conversation")
	game.clock = 3
	game._update_lighting()
	check(game.actor_tint.g<.6 and house_sprite.modulate.g<.6,"Night lighting applies to town architecture and residents")
	game.clock = 1.25
	await walk_to(game.exits.south.at)
	await wait_travel("town")
	check(game.quest_stage==2 and game.coins==19 and game.inventory.tea==2 and game.discoveries.size()==1 and game.forest_defeated.has("test_previous_defeat"),"Round trip preserves errands, money, purchases, memories and forest combat progress")
	check(is_equal_approx(game.clock,1.25) and game.player.get_instance_id()==identity,"Clock and character identity survive the round trip")
	check(game.dogs.size()==3 and game.residents.size()==5 and game.humans.size()==4,"Original hub population returns without northern NPC leakage")
	check(game.district_places.size()==3 and game.is_walkable(game.player.position,14),"The southern arrival is safe and town exploration progress persists")
	await walk_to(game.exits.north.at)
	await wait_travel("district")
	check(game.district_places.size()==3 and game.humans.size()==4 and get_nodes_in_group("district_buildings").size()==52,"Reentry preserves exploration and recreates a single district population")
	game.set_paused(true)
	var before: float = game.elapsed
	await ticks(30)
	check(game.elapsed==before,"Pause freezes the new fountain, greenery and lamp animation clock")
	game.set_paused(false)
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"All residential door paths and four frontage directions; eight native architectural recipes with plumb walls; physical northern entry and southern return/reentry, large-map camera/navigation, all six district destinations, 52 uniformly scaled buildings and solid footprints, resident conversations and moving peaceful wardens, separate town exploration progress, day/night and occlusion, pause and preserved original gameplay state/populations."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"district_test_results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Northgate: ",checks-failures.size(),"/",checks," checks passed.")
	quit(0 if failures.is_empty() else 1)
