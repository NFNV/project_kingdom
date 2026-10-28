extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
func _initialize() -> void: run.call_deferred()
func capture(id: String) -> void:
 world.update_camera()
 for i in 3: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ROOT+"previews/"+id+".png")
func run() -> void:
 root.size = Vector2i(1920,1080)
 world = load(ROOT+"world.tscn").instantiate()
 root.add_child(world)
 world.automated = true
 world.auto_clock = false
 world.set_physics_process(false)
 world.notice_left = 0
 world.clock = 10
 world.visit(3)
 world.notice_left = 0
 for phase in [["day",1.0],["night",3.0]]:
  world.day_phase = phase[1]
  world.camera_yaw = 0
  await capture("illustrated_city_"+phase[0])
 world.day_phase = 3
 for item in [["north",0.0],["east",PI/2],["south",PI],["west",-PI/2]]:
  world.camera_yaw = item[1]
  await capture("moon_direction_"+item[0])
 world.day_phase = 1
 world.camera_yaw = 0
 world.player = world.Map.WINDMILL+Vector2(8,-24)
 await capture("illustrated_hamlet")
 print("PAINTED CITY PREVIEW: day/night city, four fixed-direction moon views, illustrated hamlet")
 quit()
