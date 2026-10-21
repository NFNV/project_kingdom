extends SceneTree

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func _frames(count: int) -> void:
	for index in count:
		await physics_frame


func _run() -> void:
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _frames(3)
	var player: KingdomActor = game.player
	var world: KingdomMap = game.world
	var castle := world.castle
	var enemies: Array[Node] = get_nodes_in_group("enemies")
	_check(enemies.size() == 6, "The complete scene starts with six dog enemies.")
	_check(castle.remaining_defenders() == 3, "The objective starts with three designated sentries.")
	_check(player.health.current == 8, "The player starts with full health.")
	_check(player.faction == KingdomActor.Faction.CAT and player.player_controlled and not player.hostile,
		"The debug player is a Cat Kingdom warrior with player combat rules.")
	var dogs_are_hostile := true
	for enemy in enemies:
		if enemy.faction != KingdomActor.Faction.DOG or not enemy.hostile or enemy.player_controlled:
			dogs_are_hostile = false
	_check(dogs_are_hostile, "Dog Kingdom warriors occupy every enemy role.")
	_check(castle.owner_faction == KingdomActor.Faction.DOG, "The dogs initially own the keep.")
	for species in ["cat", "dog"]:
		var frames := load("res://resources/characters/%s_warrior.tres" % species) as SpriteFrames
		var valid := frames != null
		for animation in ["idle", "run", "attack", "guard"]:
			valid = valid and frames.has_animation(animation) and frames.get_frame_count(animation) == 4
			for index in frames.get_frame_count(animation):
				var frame := frames.get_frame_texture(animation, index) as AtlasTexture
				valid = valid and frame != null and frame.atlas != null and frame.get_size() == Vector2(320, 320)
		_check(valid, "%s warrior has four complete, consistently sized animation states." % species.capitalize())
	for actor in get_nodes_in_group("actors"):
		var controller: Node = actor.get_node_or_null("Controller")
		if controller != null:
			controller.set_physics_process(false)
		actor.move_intent = Vector2.ZERO

	# Movement exercises actual input actions and the running physics simulation.
	var input: Node = player.get_node("Controller")
	input.set_physics_process(true)
	var origin := Vector2(900, 1350)
	player.position = origin
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	var straight := player.position.distance_to(origin)
	player.position = origin
	Input.action_press("move_right")
	Input.action_press("move_up")
	await _frames(20)
	Input.action_release("move_right")
	Input.action_release("move_up")
	var diagonal := player.position.distance_to(origin)
	_check(straight > 65.0 and absf(diagonal - straight) < 7.0,
		"Diagonal input moves at the same speed as cardinal input.")
	await _frames(2)
	player.position = Vector2(165, 1030)
	Input.action_press("move_left")
	await _frames(25)
	Input.action_release("move_left")
	await _frames(2)
	_check(player.position.x >= 143.0, "The shore physically blocks movement into water.")
	input.set_physics_process(false)
	player.move_intent = Vector2.ZERO

	var route := world.find_path(Vector2(510, 1400), castle.capture_position())
	_check(route.size() > 5, "A navigable route connects the outpost to the keep.")
	var avoids_obstacles := true
	for point in route:
		for obstacle in world.obstacles:
			if obstacle.has_point(point):
				avoids_obstacles = false
	_check(avoids_obstacles, "The route avoids authored tree and building footprints.")

	# Isolate a real melee swing: front enemy, rear enemy, and friendly in range.
	for index in enemies.size():
		enemies[index].position = Vector2(320 + index * 80, 550)
	var front := enemies[0] as KingdomActor
	var behind := enemies[1] as KingdomActor
	player.position = Vector2(900, 1400)
	front.position = player.position + Vector2(64, 0)
	behind.position = player.position + Vector2(-64, 0)
	var friendly: KingdomActor = load("res://scenes/actors/actor.tscn").instantiate()
	friendly.faction = player.faction
	friendly.position = player.position + Vector2(55, 30)
	world.entities.add_child(friendly)
	await _frames(3)
	_check(player.try_attack(Vector2.RIGHT), "An available melee attack starts.")
	_check(not player.try_attack(Vector2.RIGHT), "An active swing cannot be restarted by repeated input.")
	await _frames(34)
	_check(front.health.current == 2, "The front enemy takes exactly one hit during an active swing.")
	_check(behind.health.current == 3, "The same swing does not hit an enemy behind the attacker.")
	_check(friendly.health.current == 3, "Melee damage does not affect the attacker's faction.")
	friendly.queue_free()
	front.position = player.position + Vector2(64, 0)
	front.knockback = Vector2.ZERO
	var wall := StaticBody2D.new()
	wall.position = player.position + Vector2(32, -12)
	wall.collision_layer = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 80)
	collision.shape = shape
	wall.add_child(collision)
	world.add_child(wall)
	await _frames(5)
	player.try_attack(Vector2.RIGHT)
	await _frames(34)
	_check(front.health.current == 2, "Melee cannot damage an enemy through solid scenery.")
	wall.queue_free()
	await _frames(2)

	# The same AI used in the level must be able to wind up and hurt the player.
	front.position = Vector2(1060, 1400)
	behind.position = Vector2(400, 550)
	player.position = Vector2(1000, 1400)
	var ai: KingdomEnemyController = front.get_node("Controller")
	ai.home = front.position
	ai.patrol_end = front.position + Vector2(30, 0)
	ai.set_physics_process(true)
	await _frames(60)
	_check(player.health.current < 8, "A nearby enemy detects, winds up, and damages the player.")
	ai.set_physics_process(false)
	front.move_intent = Vector2.ZERO
	var before := player.health.current
	player.health.invulnerability = 0.55
	_check(not player.receive_hit(1, Vector2.RIGHT) and player.health.current == before,
		"The damage grace period prevents immediate repeated hits.")
	player.health.reset()
	player.knockback = Vector2.ZERO
	player.position = Vector2(510, 1400)

	# Use a separate capturer so testing death does not end the live game session.
	castle.set_physics_process(false)
	var capturer: KingdomActor = load("res://scenes/actors/actor.tscn").instantiate()
	capturer.faction = player.faction
	capturer.position = castle.capture_position()
	world.entities.add_child(capturer)
	castle.player = capturer
	castle.advance_capture(3.0)
	_check(castle.progress == 0.0 and castle.state == KingdomCastle.State.LOCKED,
		"Living designated defenders prevent capture even while the player occupies the circle.")
	for defender in castle.defenders:
		defender.receive_hit(999, Vector2.ZERO)
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.health.is_dead():
			enemy.position = Vector2(400, 550)
	castle.advance_capture(1.0)
	_check(is_equal_approx(castle.progress, 0.2), "A cleared, occupied circle begins its five-second capture.")
	front.position = castle.capture_position() + Vector2(40, 0)
	castle.advance_capture(1.0)
	_check(castle.progress == 0.0 and castle.state == KingdomCastle.State.CONTESTED,
		"A surviving patrol entering the circle interrupts and resets capture.")
	front.position = Vector2(400, 550)
	castle.advance_capture(1.0)
	capturer.position += Vector2(200, 0)
	castle.advance_capture(1.0)
	_check(castle.progress == 0.0, "Leaving the circle resets capture progress.")
	capturer.position = castle.capture_position()
	capturer.receive_hit(999, Vector2.ZERO)
	castle.advance_capture(5.0)
	_check(castle.progress == 0.0, "A dead actor cannot capture the keep.")
	capturer.queue_free()
	player.position = castle.capture_position()
	castle.player = player
	var capture_events := {"count": 0}
	castle.captured.connect(func() -> void: capture_events["count"] += 1)
	castle.advance_capture(5.0)
	castle.advance_capture(5.0)
	_check(castle.owner_faction == KingdomActor.Faction.CAT and castle.progress == 1.0,
		"An uninterrupted capture transfers ownership to the player's Cat Kingdom.")
	_check(str(castle.get_node("Keep").texture.resource_path).contains("Red Buildings"),
		"Cat capture switches the keep to red faction artwork.")
	_check(capture_events["count"] == 1, "A captured keep emits its completion event once.")
	await _frames(48)
	_check(paused and game.hud.mode == "victory", "Completing the objective opens the victory screen.")
	game.hud.restart_requested.emit()
	await process_frame
	await _frames(3)
	_check(not paused and current_scene.player.health.current == 8,
		"Restart exits the result screen and restores player health.")
	_check(current_scene.world.castle.remaining_defenders() == 3,
		"Restart recreates the keep's defenders and capture objective.")
	_check(current_scene.player.faction == KingdomActor.Faction.CAT and current_scene.world.castle.owner_faction == KingdomActor.Faction.DOG,
		"Restart preserves the debug cat-player / dog-defender setup.")
	current_scene.hud.pause_requested.emit()
	_check(paused and current_scene.hud.mode == "paused", "Pause controls stop the simulation.")
	current_scene.hud.pause_requested.emit()
	_check(not paused and current_scene.hud.mode == "playing", "Resume restores the simulation.")
	print("\n%d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
