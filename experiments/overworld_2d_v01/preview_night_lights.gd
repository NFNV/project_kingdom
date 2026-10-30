extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
func _initialize() -> void: run.call_deferred()
func run() -> void:
 world = load(ROOT+"world.tscn").instantiate()
 root.add_child(world)
 root.size = Vector2i(1920,1080)
 world.automated = true
 world.auto_clock = false
 world.set_physics_process(false)
 world.clock = 20
 world.notice_left = 0
 world.day_phase = 3
 var before := "--before" in OS.get_cmdline_user_args()
 for location in [["city",world.City.GATE+Vector2(-12,-10)],["shops",Vector2(-5,14)],["mill",world.Map.WINDMILL+Vector2(8,-24)]]:
  world.player = location[1]
  world.update_camera()
  for i in 3: await process_frame
  await RenderingServer.frame_post_draw
  var filename: String = "/tmp/overworld_lights_before_"+location[0]+".png" if before else ROOT+"previews/night_lights_"+location[0]+".png"
  root.get_texture().get_image().save_png(filename)
 print("Night lights captured: city, shops and mill")
 world.queue_free()
 await process_frame
 quit()
