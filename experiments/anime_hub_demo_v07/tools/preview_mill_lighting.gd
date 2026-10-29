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
func capture(phase: float) -> Image:
 game.clock = phase
 game._update_lighting()
 game._update_hud()
 game.camera.force_update_scroll()
 for i in 3: await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func sample_source(picture: Image, source: Vector2) -> Color:
 # The complete room occupies the viewport at 1.5x and shares this source UV.
 return picture.get_pixelv(Vector2i(source*Vector2(1920,1080)/Vector2(1672,941)))
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Mill lighting preview requires the native renderer")
  quit(1)
  return
 game = load(ROOT+"demo.tscn").instantiate()
 game.save_path = "/tmp/kingdom-mill-lighting-preview.json"
 root.add_child(game)
 root.size = Vector2i(1920,1080)
 game.autosave_enabled = false
 game.auto_clock = false
 game._load_zone("mill_room","mill_garden")
 game.player.position = game.Mill.room(1000,650)
 game.player.reset_physics_interpolation()
 game.dialogue_left = 0
 game.talk_panel.hide()
 game.ui.notice_left = 0
 var images := {}
 for item in [["dawn",0.0],["day",1.0],["dusk",2.0],["night",3.0],["before_dawn",3.85556]]:
  var picture := await capture(item[1])
  picture.save_png(ROOT+"previews/mill_room_"+item[0]+".png")
  images[item[0]] = picture
 var day: Image = images.day
 var night: Image = images.night
 check(sample_source(night,Vector2(790,370)).get_luminance()<sample_source(day,Vector2(790,370)).get_luminance()*.65,"Night removes the bright golden sunbeam on the floor")
 check(sample_source(night,Vector2(745,130)).get_luminance()<sample_source(day,Vector2(745,130)).get_luminance()*.55,"Night windows visibly replace daytime sky")
 var fire := sample_source(night,Vector2(950,265))
 var floor_color := sample_source(night,Vector2(1100,500))
 check(fire.r>fire.b*1.5 and fire.get_luminance()>floor_color.get_luminance()*1.5,"Fireplace remains warmly lit against the dim nighttime room")
 check(sample_source(images.before_dawn,Vector2(790,370)).is_equal_approx(sample_source(night,Vector2(790,370))),"05:08 has no returning daytime floor glare")
 var feet: Vector2 = game.player.get_global_transform_with_canvas().origin
 game.player.hide()
 var without_hero := await capture(3.85556)
 var top := 1080
 var bottom := 0
 for x in range(int(feet.x)-50,int(feet.x)+50):
  for y in range(int(feet.y)-135,int(feet.y)+20):
   var a: Color = images.before_dawn.get_pixel(x,y)
   var b: Color = without_hero.get_pixel(x,y)
   if maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))>.05:
    top = mini(top,y)
    bottom = maxi(bottom,y)
 check(bottom-top>=100,"Actual rendered cat occupies at least 100 pixels beside the furniture")
 FileAccess.open(ROOT+"mill_room_render_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Native 1920x1080 day/dawn/dusk/night/pre-dawn views, actual floor sunbeam removal, window darkness, warm hearth contrast and cat-to-room scale."},"  ")+"\n")
 print("MILL ROOM RENDER CHECKS ",checks-failures.size(),"/",checks)
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
