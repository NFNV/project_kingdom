extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D

func _initialize() -> void:
	_run.call_deferred()

func save(name_text: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/"+name_text+".png"))

func _run() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game._load_zone("wilds","river")
	game.player.automated = true
	game.player.grace = 0
	game.dialogue_left = 0
	for dog in game.dogs:
		dog.set_physics_process(false)
	game.player.position = game.Map.Wilds.CAMPS[0]-Vector2(220,0)
	game.player.facing = Vector2.RIGHT
	game.player.reset_physics_interpolation()
	game.camera.force_update_scroll()
	await create_timer(1).timeout
	game.player.try_attack()
	await create_timer(.25).timeout
	await save("drawn_sword_attack")
	await create_timer(.7).timeout
	var key := InputEventKey.new()
	key.physical_keycode = KEY_Q
	key.pressed = true
	Input.parse_input_event(key)
	await create_timer(.48).timeout
	await save("wind_slash")
	key.pressed = false
	Input.parse_input_event(key)
	# Native art QA sheet: four real directions × eight actual attack stages.
	var motion_metadata: Dictionary = game.player.sprite.metadata
	var display_height: float = game.player.sprite.display_height
	game.queue_free()
	await process_frame
	await process_frame
	root.canvas_transform = Transform2D.IDENTITY
	var stage := Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.size = Vector2(1920,1080)
	background.color = Color("e1e8d5")
	stage.add_child(background)
	var title := Label.new()
	title.text = "DRAW · ANTICIPATE · EARLY SLASH · CONTACT · FOLLOW · SETTLE · RECOVER · SHEATHE"
	title.position = Vector2(90,25)
	title.add_theme_font_size_override("font_size",28)
	title.modulate = Color("294d3e")
	stage.add_child(title)
	for row in 4:
		for col in 8:
			var body := Polygon2D.new()
			body.set_script(load(ROOT+"tools/cat_combat.gd"))
			stage.add_child(body)
			var facing: Vector2 = [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)][row]
			body.configure_reference(motion_metadata,display_height)
			body.pose(facing,[.067,.208,.325,.417,.517,.617,.733,.9][col],false)
			body.position = Vector2(135+col*235,275+row*252)
			body.scale *= 2.25
	await create_timer(.2).timeout
	await save("polished_attack_phases")
	print("Captured drawn body attack, actual Q projectile, and all thirty-two registered combat poses.")
	quit()
