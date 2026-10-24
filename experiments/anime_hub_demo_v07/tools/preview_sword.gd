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
	await create_timer(2).timeout
	await save("sword_equipped")
	game.player.position = game.Map.Wilds.CAMPS[0]+Vector2(-100,0)
	game.player.facing = Vector2.RIGHT
	game.player.reset_physics_interpolation()
	game.camera.force_update_scroll()
	for dog in game.dogs:
		dog.set_physics_process(false)
	await create_timer(.3).timeout
	game.player.try_skill()
	await create_timer(.38).timeout
	game.player.sprite.modulate.a = 1
	game.player.weapon.modulate.a = 1
	await save("crescent_cleave")
	game.queue_free()
	await process_frame
	await process_frame
	root.canvas_transform = Transform2D.IDENTITY
	var stage := Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.size = Vector2(1920,1080)
	background.color = Color("dce6d4")
	stage.add_child(background)
	var title := Label.new()
	title.text = "ADVENTURER  /  EQUIPPED SWORD  /  EIGHT VIEWS"
	title.position = Vector2(90,45)
	title.add_theme_font_size_override("font_size",32)
	title.modulate = Color("294d3e")
	stage.add_child(title)
	var directions := ["e","se","s","sw","w","nw","n","ne"]
	for index in directions.size():
		var at := Vector2(260+(index%4)*460,470+(index/4)*440)
		var actor := CharacterBody2D.new()
		actor.set_script(load(ROOT+"tools/actor.gd"))
		actor.hub = stage
		actor.controlled = true
		actor.position = at
		actor.scale = Vector2(2.7,2.7)
		stage.add_child(actor)
		actor.set_physics_process(false)
		actor.sprite.set_pose("idle",directions[index],0)
		actor.weapon.sync_pose()
		var label := Label.new()
		label.text = directions[index].to_upper()
		label.position = at+Vector2(-20,35)
		label.add_theme_font_size_override("font_size",24)
		label.modulate = Color("294d3e")
		stage.add_child(label)
	await create_timer(.2).timeout
	await save("sword_eight_views")
	print("Captured equipped sword, actual Q cleave and all eight body/weapon views.")
	quit()
