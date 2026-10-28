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
 world.player = world.City.GATE+Vector2(10,-18)
 for phase in [["dawn",0.0],["day",1.0],["dusk",2.0],["night",3.0]]:
  world.day_phase = phase[1]
  await capture("fixed_city_"+phase[0])
 world.day_phase = 1
 world.player = world.City.GATE+Vector2(-13,-10)
 await capture("fixed_city_side_approach")
 world.player = world.City.GATE+Vector2(0,-4)
 await capture("fixed_city_gate")
 print("FIXED CAMERA PREVIEW: all four phases, side approach and aligned town gate")
 quit()
