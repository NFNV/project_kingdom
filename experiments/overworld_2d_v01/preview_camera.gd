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
	world.notice_left = 0
	for heading in [["north",0.0],["east",PI/2],["south",PI],["west",-PI/2]]:
		world.camera_yaw = heading[1]
		world.player = world.City.CENTER-world.camera_forward()*27
		world.facing = world.camera_forward()
		world.rotate_camera(0,0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ROOT+"previews/mosswood_"+heading[0]+".png")
	world.player = world.City.GATE-Vector2(0,4)
	world.facing = Vector2(0,1)
	for i in 72:
		world.camera_yaw = i*TAU/72
		world.rotate_camera(0,0)
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		frame.resize(960,540,Image.INTERPOLATE_LANCZOS)
		frame.save_png("/tmp/kingdom-camera-frames/frame_%03d.png" % i)
	print("CITY ORBIT PREVIEW: four viewpoints and a full stationary-player camera orbit")
	quit()
