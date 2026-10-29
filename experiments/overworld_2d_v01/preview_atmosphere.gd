extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
func _initialize() -> void:
 run.call_deferred()
func frame(id: String) -> void:
 world.update_camera()
 world.mounted_rider.set_direction(world.view_vector(world.facing))
 for i in 3: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ROOT+"previews/"+id+".png")
func run() -> void:
 root.size = Vector2i(1920,1080)
 world = load(ROOT+"world.tscn").instantiate()
 root.add_child(world)
 world.automated = true
 world.set_physics_process(false)
 world.auto_clock = false
 world.clock = 20
 world.notice_left = 0
 world.player = world.Map.WINDMILL+Vector2(8,-24)
 for phase in [["dawn",0.0],["noon",1.0],["dusk",2.0],["night",3.0]]:
  world.day_phase = phase[1]
  await frame("painted_hamlet_"+phase[0])
 for location in [["watermill",world.Map.WATERMILL+Vector2(9,-20),0.0],["lighthouse",world.Map.LIGHTHOUSE-Vector2(12,22),.55],["forest",world.Map.FOREST,0.0],["town",world.Map.TOWN+Vector2(15,-25),0.0]]:
  world.player = location[1]
  world.camera_yaw = location[2]
  world.facing = world.camera_forward()
  for phase in [["day",1.0],["night",3.0]]:
   world.day_phase = phase[1]
   await frame("painted_"+location[0]+"_"+phase[0])
 world.region_map = true
 await frame("painted_region_map")
 print("ATMOSPHERE PREVIEWS: same hamlet at four phases; watermill, lighthouse, forest and town day/night; regional map")
 quit()
