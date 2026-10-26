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

func mapped_head(art) -> Vector2:
	var source := Vector2(art.active_data.foot_x,art.active_data.head_center_y)
	for layer in art.layers:
		if not layer.visible:
			continue
		for face in layer.polygons:
			var a: Vector2 = layer.uv[face[0]]
			var b: Vector2 = layer.uv[face[1]]
			var c: Vector2 = layer.uv[face[2]]
			var ab := b-a
			var ac := c-a
			var ap := source-a
			var cross := ab.cross(ac)
			if absf(cross)<.0001:
				continue
			var u := ap.cross(ac)/cross
			var v := ab.cross(ap)/cross
			if u>=-.0001 and v>=-.0001 and u+v<=1.0001:
				return layer.polygon[face[0]]*(1-u-v)+layer.polygon[face[1]]*u+layer.polygon[face[2]]*v
	return Vector2(INF,INF)

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	game.auto_clock = false
	await ticks(3)
	var motion = game.player.sprite
	motion.set_pose("walk","e",5)
	motion.heading_angle = 0
	motion.phase = .68
	motion.tick(1.0/60,0,Vector2.ZERO)
	var before: float = motion.phase
	motion.tick(1.0/60,1,Vector2.RIGHT)
	check(motion.phase>before and motion.frame>=5,"A short stop resumes the same foot phase instead of snapping to the first step")
	motion.set_pose("walk","e",0)
	motion.heading_angle = 0
	var views: Dictionary = {}
	for tick in 9:
		motion.tick(1.0/60,1,Vector2.LEFT)
		views[motion.facing_direction] = true
	check(views.size()>=3 and motion.facing_direction=="w","Reversal pivots through drawn intermediate views within 150 ms")
	var stopped: float = motion.phase
	for tick in 20:
		motion.tick(1.0/60,0,Vector2.UP)
	check(motion.phase==stopped and motion.facing_direction=="n","A stationary turn faces correctly without walking in place")
	var art = game.player.combat_art
	for direction in ["se","sw","ne","nw"]:
		var vector: Vector2 = {"se":Vector2(1,1),"sw":Vector2(-1,1),"ne":Vector2(1,-1),"nw":Vector2(-1,-1)}[direction]
		for power in [false,true]:
			var keys: Dictionary = {}
			var phases: Dictionary = {}
			var grounded := true
			var aligned := true
			var head_size := true
			for frame in 61:
				art.pose(vector,frame/60.0,power)
				keys[art.current_key] = true
				phases[art.current_phase] = true
				var landmark := mapped_head(art)
				aligned = aligned and landmark.is_finite() and absf(landmark.x)<.1 and absf(landmark.y+art.display_head_height)<.1
				var feet_y := -INF
				for layer in art.layers:
					if layer.visible:
						for point in layer.polygon:
							feet_y = maxf(feet_y,point.y)
				grounded = grounded and absf(feet_y)<.8
				head_size = head_size and is_equal_approx(art.display_head_width,float(art.references[direction].width))
			check(keys.size()==8 and phases.has("draw") and phases.has("sheathe"),"Eight authored draw-to-sheathe poses play in "+direction+(" power" if power else " light"))
			check(grounded,"Actual rendered boots remain on their ground anchor in "+direction+(" power" if power else " light"))
			check(aligned and head_size,"Rendered mesh keeps the head registered and its size fixed in "+direction+(" power" if power else " light"))
	game._load_zone("wilds","river")
	for dog in game.dogs:
		dog.set_physics_process(false)
	var center: Vector2 = game.Map.Wilds.CAMPS[0]
	game.player.position = center
	game.player.facing = Vector2.RIGHT
	game.player.sprite.set_pose("idle","e",0)
	game.player.sprite.heading_angle = 0
	var left = game.dogs[0]
	var right = game.dogs[1]
	left.position = center-Vector2(75,0)
	right.position = center+Vector2(75,0)
	Input.action_press("hub_left")
	Input.action_press("hub_attack")
	await ticks(1)
	Input.action_release("hub_attack")
	check(game.player.facing.x<-.9 and game.player.combat_art.current_phase=="draw","Movement and attack pressed together use this tick's new direction and begin drawing")
	Input.action_release("hub_left")
	Input.action_press("hub_right")
	await ticks(10)
	check(game.player.facing.x<-.9 and left.health==3 and right.health==3,"Anticipation locks attack facing and cannot deal early damage")
	await ticks(7)
	check(left.health==2 and right.health==3,"The visible contact phase damages the correctly faced target exactly once")
	Input.action_release("hub_right")
	# Entering range during recovery cannot receive an old swing's late damage.
	await ticks(7)
	right.position = center-Vector2(70,10)
	await ticks(13)
	check(right.health==3 and not game.player.combat_art.visible and not game.player.weapon.visible,"Recovery and sheathing cannot hit late arrivals and end with empty hands")
	# Mouse follow-up uses buffered aim; Q has priority over that buffer.
	game.player.automated = true
	game.player.cooldown = 0
	game.player.try_attack(Vector2.RIGHT)
	await ticks(23)
	check(game.player.try_attack(Vector2.LEFT) and game.player.light_buffer>0,"A click during recovery queues the aimed next attack")
	for tick in 30:
		await physics_frame
		if game.player.facing.x<0 and game.player.swing>0:
			break
	check(game.player.facing.x<0 and game.player.swing>0,"The queued click starts an attack using its own saved aim")
	game.player.try_skill()
	await ticks(45)
	check(game.player.attack_kind=="wind" and game.player.light_buffer==0,"Queued Wind Slash takes priority and clears a pending light attack")
	game._load_zone("town","forest")
	check(game.player.light_buffer==0 and game.player.skill_buffer==0 and not game.player.combat_art.visible and not game.player.weapon.visible,"Zone travel clears animation buffers and restores the sheathed walking state")
	for action in ["hub_left","hub_right","hub_attack"]:
		Input.action_release(action)
	var report := {"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Foot-phase continuity, drawn turn progression and no wall treadmill; actual UV-to-rendered-head mapping and planted boots across every combat sample; eight authored phases, draw/sheathing, same-tick attack facing, contact-only hits, no recovery hits, buffered clicks, skill priority and zone resets."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"animation_test_results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Animation polish: ",checks-failures.size(),"/",checks," checks passed.")
	quit(0 if failures.is_empty() else 1)
