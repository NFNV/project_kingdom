extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/assets/moonlight_guard/"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: run.call_deferred()

func check(ok: bool, words: String) -> void:
	checks += 1
	if not ok:
		failures.append(words)
		push_error(words)

func run() -> void:
	for role in ["ashen_vanguard","briar_spearman","gloam_arbalist","blackthorn_captain"]:
		var sample: Node2D = load(ROOT+role+".tscn").instantiate()
		root.add_child(sample)
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+role+"_catalog.json"))
		var frames: SpriteFrames = sample.art.sprite_frames
		check(frames.get_animation_names().size()==28,role+" has seven actions in four directions")
		var correct_canvas := true
		var valid_regions := true
		for animation in frames.get_animation_names():
			for index in frames.get_frame_count(animation):
				var texture: AtlasTexture = frames.get_frame_texture(animation,index)
				correct_canvas = correct_canvas and texture.get_size()==Vector2(data.canvas[0],data.canvas[1])
				valid_regions = valid_regions and Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region)
		check(correct_canvas,role+" frames share one registered canvas and boot baseline")
		check(valid_regions,role+" regions stay inside native source images")
		for heading in ["se","sw","ne","nw"]:
			sample.play_action("attack",heading)
			check(sample.art.animation=="attack_"+heading,role+" can select the "+heading+" attack")
		sample.queue_free()
	var game: Node2D = load("res://experiments/anime_hub_demo_v07/demo.tscn").instantiate()
	game.save_path = "/tmp/kingdom-guard-assets-test.json"
	root.add_child(game)
	game.auto_clock = false
	game.autosave_enabled = false
	for zone in ["town","district","trail","river","wilds","mill_garden","palestone_coast","moonlight_forest"]:
		game._load_zone(zone,"start")
		game.clock = 1
		game._update_lighting()
		check(is_instance_valid(game.night_fireflies),zone+" has reusable outdoor fireflies")
		check(not game.night_fireflies.visible and game.night_fireflies.night_weight==0,zone+" fireflies disappear at noon")
		game.clock = 3
		game._update_lighting()
		check(game.night_fireflies.visible and game.night_fireflies.night_weight>.99,zone+" fireflies appear at midnight")
		check(game.night_fireflies.batch.multimesh.instance_count==(240 if zone=="moonlight_forest" else 120),zone+" uses bounded MultiMesh particles")
		if zone=="town":
			for i in 12: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/moonlight_town_fireflies.png")
		await process_frame
	for zone in ["bakery","forge","mill_room","moonlight_passage","moonlight_cistern","moonlight_chapel","lighthouse_keeper","lighthouse_lantern"]:
		game._load_zone(zone,"start")
		check(not is_instance_valid(game.night_fireflies),zone+" remains indoors without ambient outdoor fireflies")
		await process_frame
	game.queue_free()
	await process_frame
	print("GUARD ASSET CHECKS ",checks," FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
