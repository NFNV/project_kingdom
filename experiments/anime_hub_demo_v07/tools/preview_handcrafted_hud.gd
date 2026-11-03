extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  push_error(message)
func capture(name: String) -> void:
 for i in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ROOT+"previews/hud_"+name+".png")
func run() -> void:
 if DisplayServer.get_name()=="headless": quit(1); return
 game = load(ROOT+"demo.tscn").instantiate()
 game.save_path = "/tmp/kingdom-handcrafted-hud-preview.json"
 root.add_child(game)
 game.auto_clock = false
 game.autosave_enabled = false
 game.dialogue_left = 0
 game.talk_panel.hide()
 game.ui.notice_left = 0
 game.clock = 1
 game._update_lighting()
 game._update_hud()
 check(game.ui.skill_panel.position.y>750 and game.ui.skill_panel.position.x<300,"Skill cross occupies the bottom-left screen area")
 check(game.ui.journal_panel.size.x<320 and game.ui.combat_panel.size.x<250 and game.ui.forest_map.size.x<180,"Journal, health and minimap occupy less screen space")
 check(game.ui.skill_panel.icon.size.x<85 and game.ui.skill_panel.icon.size.y<85 and game.ui.skill_button.size.x<90,"Painted skill icon stays inside its compact tile")
 check(game.ui.health_bar.size.y<=8 and game.ui.skill_bar.size.y<=4,"Health and cooldown meters retain their thin native geometry")
 check(game.ui.clock_dial.paintings.size()==4 and game.ui.clock_dial.paintings.all(func(art): return art.atlas!=null),"All four painted clock views are loaded")
 await capture("town_720")
 game._load_zone("wilds","river")
 for dog in game.dogs: dog.set_physics_process(false)
 game.player.automated = true
 game.player.position = game.Map.Wilds.CAMPS[0]-Vector2(230,0)
 game.player.reset_physics_interpolation()
 game.camera.force_update_scroll()
 for time in [["dawn",0.0],["day",1.0],["dusk",2.0],["night",3.0]]:
  game.clock = time[1]
  game._update_lighting()
  game._update_hud()
  check(is_equal_approx(game.ui.clock_dial.hour,fposmod((time[1]+1)*6,24)),"Painted clock keeps accurate time: "+time[0])
  await capture("wilds_"+time[0]+"_720")
 game.clock = 1
 game.player.skill_cooldown = 0
 game._update_lighting()
 game._update_hud()
 # Deliver actual viewport mouse events to exercise the relocated hit target.
 var at: Vector2 = game.ui.skill_button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.position = at
  event.global_position = at
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  root.push_input(event,true)
  await process_frame
 check(game.player.skill_cooldown>0,"Clicking the relocated icon triggers the actual Wind Slash ability")
 game.player.skill_cooldown = 3.25
 game.set_paused(true)
 game.pause_overlay.hide()
 game._update_hud()
 await capture("cooldown_720")
 check(game.ui.skill_panel.countdown.visible and absf(float(game.ui.skill_panel.countdown.text)-3.25)<.051,"The skill tile shows a visible cooldown countdown")
 game.set_paused(false)
 game.player.skill_cooldown = 0
 game._update_hud()
 root.size = Vector2i(1920,1080)
 await capture("wilds_day_1080")
 game._load_zone("mill_room","mill_garden")
 game.dialogue_left = 0
 game.talk_panel.hide()
 game._update_hud()
 await capture("mill_1080")
 check(not game.ui.skill_panel.visible,"Cozy interiors keep combat slots hidden")
 game.queue_free()
 await process_frame
 var world: Node2D = load("res://experiments/overworld_2d_v01/world.tscn").instantiate()
 root.add_child(world)
 world.auto_clock = false
 world.set_physics_process(false)
 world.visit(3)
 world.day_phase = 3
 world.notice_left = 0
 await capture("overworld_night_1080")
 check(world.clock_dial.paintings.size()==4 and world.clock_dial.hour==0,"Overworld shares the handcrafted clock and correct night state")
 FileAccess.open(ROOT+"handcrafted_hud_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Native 1280x720 and 1920x1080 HUD views, four painted time phases, compact layouts, actual relocated mouse hit target, cooldown feedback, indoor hiding and shared overworld clock."},"  ")+"\n")
 print("HANDCRAFTED HUD CHECKS ",checks-failures.size(),"/",checks)
 world.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
