extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
func _initialize() -> void: run.call_deferred()
func capture(id: String) -> void:
 game._update_hud()
 for i in 3: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ROOT+"previews/defence_"+id+".png")
func run() -> void:
 if DisplayServer.get_name()=="headless": quit(1); return
 game = load(ROOT+"demo.tscn").instantiate()
 game.save_path = "/tmp/kingdom-defence-preview.json"
 root.add_child(game)
 game.auto_clock = false
 game.autosave_enabled = false
 game.dialogue_left = 0
 game.talk_panel.hide()
 game.ui.notice_left = 0
 game._load_zone("wilds","river")
 game.clock = 1
 game._update_lighting()
 var hero = game.player
 hero.automated = true
 hero.set_physics_process(false)
 hero.position = game.Map.Wilds.CAMPS[0]+Vector2(-75,45)
 hero.facing = Vector2.RIGHT
 hero.grace = 0
 for dog in game.dogs: dog.set_physics_process(false)
 var raider = game.dogs[0]
 raider.position = hero.position+Vector2(74,0)
 raider.facing = Vector2.LEFT
 raider.alerted = true
 raider.attack_kind = "slash"
 raider.windup = .20
 raider._update_animation(0,0)
 hero.enter_combat()
 hero.set_guard(true)
 hero.guard_age = .30
 hero.stamina = 63
 hero._update_animation(0,0)
 hero.shield.sync_pose()
 hero.queue_redraw()
 game.camera.force_update_scroll()
 await capture("guard")
 hero.guard_age = .05
 raider.windup = 0
 raider.try_attack()
 raider.swing = raider.attack_duration-.12
 raider.resolve_hits()
 hero.shield.sync_pose()
 hero.queue_redraw()
 await capture("parry")
 hero.set_guard(false)
 hero.roll_cooldown = 0
 hero.stamina = 100
 hero.intent = Vector2.RIGHT
 hero.try_roll()
 hero.roll_left = .30
 hero._update_animation(0,0)
 hero._update_combat_art()
 hero.shield.sync_pose()
 hero.queue_redraw()
 await capture("roll")
 hero.stop_motion()
 game.toggle_backpack()
 game.ui.satchel.select("trail_shield","equipped")
 await capture("equipment")
 game.toggle_backpack()
 game._load_zone("forge","district")
 game.shopping = true
 game.ui.forge_view.refresh()
 game.ui.forge_view.show()
 await capture("forge")
 print("DEFENCE PREVIEWS captured at ",root.get_texture().get_size())
 game.queue_free()
 await process_frame
 quit()
