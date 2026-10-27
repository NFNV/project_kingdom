extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var flow: Node

func _initialize() -> void:
	run.call_deferred()

func capture(name: String) -> void:
	if is_instance_valid(game):
		game.ui.notice_left = 0
		game.ui.notice.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ROOT+"previews/"+name+".png")
	print("Equipment preview: ",name)

func fresh() -> void:
	if is_instance_valid(game):
		game.free()
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.save_path = "/tmp/kingdom-equipment-preview.json"
	game.auto_clock = false
	game.dialogue_left = 0
	game.talk_panel.hide()
	game.prompt.hide()
	game.quest_marker.hide()

func run() -> void:
	fresh()
	game.state.accept_quest()
	for i in 3:
		var id := "wild_dog_0_%d" % i
		game.state.record_defeat(id,Vector2(1550+i*30,1650))
		game.state.collect_loot(id)
	game.state.claim_reward()
	game.state.accept_smith_quest()
	game.state.record_defeat(game.GameState.CAPTAIN_ID,game.Map.Wilds.CAMPS[3])
	game.state.collect_loot(game.GameState.CAPTAIN_ID)
	game.state.claim_smith_reward()
	game.state.delivery_stage = 2
	game.coins = 74
	for id in game.state.FORGE_STOCK:
		game.state.buy_equipment(id)
	for id in ["leather_cap","reinforced_vest","hunter_boots","warden_charm"]:
		game.state.equip_item(id)
	game.state.add_item("bread",3)
	game.state.add_item("tea",2)
	game.player.health = 7
	game.toggle_backpack()
	game.ui.satchel.select("tempered_sword","bag")
	await create_timer(.3).timeout
	await capture("equipment_paper_doll")
	game.ui.satchel.select("swift_charm","bag")
	await capture("equipment_charm_comparison")
	game.toggle_backpack()
	game.toggle_journal()
	game.ui.journal_view.selected = "morning_rounds"
	game.ui.journal_view.refresh()
	await capture("equipment_quest_journal")
	game.toggle_journal()
	game.saves.write_document(game.make_save_document(),game.save_path)
	fresh()
	game._load_zone("forge","district")
	game.player.position = Vector2(930,665)
	game.player.reset_physics_interpolation()
	game.camera.force_update_scroll()
	game.dialogue_left = 0
	await create_timer(.6).timeout
	await capture("emberforge_interior")
	game.open_forge()
	await capture("emberforge_shop")
	game.free()
	flow = load(ROOT+"title.tscn").instantiate()
	flow.save_path = "/tmp/kingdom-equipment-preview.json"
	root.add_child(flow)
	await create_timer(.3).timeout
	await capture("equipment_title")
	flow.free()
	quit()
