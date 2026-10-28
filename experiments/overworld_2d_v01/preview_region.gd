extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 root.size = Vector2i(1920,1080)
 world = load(ROOT+"world.tscn").instantiate()
 root.add_child(world)
 world.automated = true
 world.set_physics_process(false)
 for pair in [["miniature_mosswood",3],["windsong_ridge",4],["willowmere_lake",5],["ivykeep_ruins",6],["palestone_coast",7],["painted_briarwood",2]]:
  world.camera_yaw = 1.0 if pair[1]==7 else (-.25 if pair[1]==5 else 0.0)
  world.visit(pair[1])
  world.facing = world.camera_forward()
  world.rotate_camera(0,0)
  world.notice_left = 0
  for frame in 3: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ROOT+"previews/"+pair[0]+".png")
 world.region_map = true
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ROOT+"previews/greenshire_map.png")
 world.region_map = false
 world.visit(3)
 world.notice_left = 0
 for heading in [["north",0.0],["east",PI/2],["south",PI],["west",-PI/2]]:
  world.camera_yaw = heading[1]
  world.player = world.City.CENTER-world.camera_forward()*40
  world.rotate_camera(0,0)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ROOT+"previews/compact_city_"+heading[0]+".png")
 print("REGION PREVIEWS: six destinations, full map, four city headings")
 quit()
