extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures.append(message)
  push_error(message)
func frame() -> Image:
 for i in 3: await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func render(phase: float) -> Image:
 world.day_phase = phase
 world._process(0)
 return await frame()
func run() -> void:
 root.size = Vector2i(1920,1080)
 world = load(ROOT+"world.tscn").instantiate()
 root.add_child(world)
 world.automated = true
 world.auto_clock = false
 world.set_physics_process(false)
 world.set_process(false)
 world.clock = 10
 world.notice_left = 0
 world.player = world.City.GATE+Vector2(-12,-10)
 world.update_camera()
 for item in [["before_dawn",3.85556],["dawn",0.0],["before_dusk",1.999],["dusk",2.0]]:
  var picture := await render(item[1])
  picture.save_png(ROOT+"previews/grounded_"+item[0]+".png")
  world.celestial_layer.visible = false
  var backdrop := await frame()
  var show_moon: bool = world.Atmosphere.moon_is_visible(item[1])
  var active: Vector2 = world.Atmosphere.celestial_position(item[1],0,show_moon)
  var inactive: Vector2 = world.Atmosphere.celestial_position(item[1],0,not show_moon)
  var center: Color = picture.get_pixelv(Vector2i(active))
  check(center.get_luminance()>.7,"Active celestial body is bright and solid: "+item[0])
  check(picture.get_pixelv(Vector2i(inactive))==backdrop.get_pixelv(Vector2i(inactive)),"Inactive celestial body leaves no ghost in the sky: "+item[0])
 world.day_phase = 1
 for item in [["city_gate",world.City.GATE+Vector2(0,-5)],["watermill_approach",world.Map.WATERMILL+Vector2(8,-23)],["hamlet",world.Map.WINDMILL+Vector2(9,-22)]]:
  world.player = item[1]
  world.update_camera()
  var picture := await render(1)
  picture.save_png(ROOT+"previews/grounded_"+item[0]+".png")
 FileAccess.open(ROOT+"ground_contacts_render_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"scope":"Native GPU dawn/dusk/pre-dawn/pre-dusk celestial brightness and absent-body ghost checks, with rendered city, watermill and hamlet ground-contact previews."},"  ")+"\n")
 print("GROUNDED RENDER CHECKS ",checks-failures.size(),"/",checks)
 quit(0 if failures.is_empty() else 1)
