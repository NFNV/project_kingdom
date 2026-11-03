extends SceneTree
const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var title: Node
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  push_error(message)
func frame() -> void:
 for i in 4: await process_frame
func capture(name: String) -> void:
 await frame()
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 check(picture.get_size()==Vector2i(2560,1440),"Actual GPU render target is 2560x1440: "+name)
 picture.save_png(ROOT+"previews/qhd_"+name+".png")
func click(control: Control) -> void:
 var at := control.get_global_transform_with_canvas()*(control.size*.5)
 var motion := InputEventMouseMotion.new()
 motion.position = at
 motion.global_position = at
 root.push_input(motion,true)
 await process_frame
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.position = at
  event.global_position = at
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  root.push_input(event,true)
  await process_frame
func wait_travel(zone: String) -> void:
 for i in 300:
  await physics_frame
  if game.zone==zone and not game.transitioning: return
 check(false,"Travel reaches "+zone)
func run() -> void:
 if DisplayServer.get_name()=="headless": quit(1); return
 for suffix in ["",".auto",".bak",".auto.bak"]:
  var slot: String = "/tmp/kingdom-qhd-render-preview.json"+suffix
  if FileAccess.file_exists(slot): DirAccess.remove_absolute(slot)
 title = load(ROOT+"title.tscn").instantiate()
 title.save_path = "/tmp/kingdom-qhd-render-preview.json"
 root.add_child(title)
 game = title.game
 game.auto_clock = false
 await capture("title")
 title.finish_menu()
 game.autosave_enabled = false
 game.dialogue_left = 0
 game.talk_panel.hide()
 game.ui.notice_left = 0
 await capture("town")
 check(root.canvas_item_default_texture_filter==Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR,"HUD inherits smooth viewport filtering instead of pixel-art nearest sampling")
 check(game.ui.serif.multichannel_signed_distance_field and ThemeDB.fallback_font.multichannel_signed_distance_field,"Serif and regular HUD glyphs use scalable MSDF rendering")
 check(game.ui.clock_dial.paintings[0].atlas.get_image().has_mipmaps() and game.ui.skill_panel.icon.texture.get_image().has_mipmaps(),"Painted clock and skill icon have mipmaps for smooth reduction")
 check(root.size==Vector2i(1280,720),"The normal window size stays 1280x720 while rendering at 1440p")
 var frustum: Vector2 = Vector2(2560,1440)/game.camera.zoom
 check(frustum.distance_to(Vector2(1280,720))<.01,"Higher pixel density preserves the previous camera field of view")
 var ui_end: Vector2 = game.ui.get_final_transform()*Vector2(1920,1080)
 check(ui_end.distance_to(Vector2(2560,1440))<.01,"Logical HUD fills the complete higher-resolution target")
 var hero_pixel: Vector2 = game.player.get_global_transform_with_canvas().origin
 var roundtrip: Vector2 = game.ui.get_final_transform()*game.ui.world_to_ui(game.player.global_position)
 check(hero_pixel.distance_to(roundtrip)<.01,"World-following prompts map accurately into the scaled HUD")
 # Exercise a real title UI button and the scaled skill button's mouse hit area.
 title.show_title()
 await frame()
 for candidate in title.menu.find_children("*","Button",true,false):
  if candidate.text=="New journey":
   await click(candidate)
   break
 game = title.game
 game.auto_clock = false
 game.autosave_enabled = false
 game.autosave_queued = false
 check(not title.menu.visible,"Title menu mouse hit targets remain aligned at 1440p")
 game._load_zone("wilds","river")
 for dog in game.dogs: dog.set_physics_process(false)
 game.player.position = game.Map.Wilds.CAMPS[0]-Vector2(230,0)
 game.player.reset_physics_interpolation()
 game.camera.force_update_scroll()
 game._update_hud()
 await frame()
 await click(game.ui.skill_button)
 check(game.player.skill_cooldown>0,"Actual mouse click hits Wind Slash after HUD upscaling")
 await capture("combat")
 game._load_zone("mill_room","mill_garden")
 await capture("mill")
 game.request_travel("mill_loft")
 await wait_travel("mill_loft")
 await capture("inn")
 game._load_zone("town","overworld")
 game.request_travel("southwest")
 for i in 400:
  await physics_frame
  if is_instance_valid(game.overworld_travel) and is_instance_valid(game.overworld_travel.overworld) and not game.overworld_travel.overworld.transitioning: break
 if not is_instance_valid(game.overworld_travel):
  push_error("Overworld travel did not start")
  quit(1)
  return
 var overworld: Node2D = game.overworld_travel.overworld
 overworld.day_phase = 3
 overworld.notice_left = 0
 await capture("overworld_night")
 check(root.content_scale_mode==Window.CONTENT_SCALE_MODE_VIEWPORT and overworld.scale.is_equal_approx(Vector2.ONE*4/3),"Linked overworld keeps a true 1440p target and unchanged composition")
 game.overworld_travel.return_to_town()
 for i in 400:
  await physics_frame
  if not is_instance_valid(game.overworld_travel.overworld) and not game.transitioning: break
 await capture("return_to_town")
 root.size = Vector2i(1920,1080)
 await frame()
 check(root.get_texture().get_size()==Vector2(2560,1440),"Resizing the window does not lower internal resolution")
 FileAccess.open(ROOT+"render_1440_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"render_size":[2560,1440],"logical_size":[1920,1080],"scope":"Native GPU target dimensions in title, town, combat, mill, inn, linked overworld and return; matching camera framing, UI scale, world-to-HUD projection, actual skill click and resized output window. Isolated temporary save slot."},"  ")+"\n")
 print("1440P RENDER CHECKS ",checks-failures.size(),"/",checks)
 title.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
