extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	world = load(ROOT+"world.tscn").instantiate()
	root.add_child(world)
	world.automated = true
	world.hop_study = true
	world.notice_left = 0
	world.set_physics_process(false)
	# Six exact poses captured through the same world renderer used in play.
	for stage in [["idle",0.0],["crouch",.13],["push_off",.25],["apex",.54],["reach",.69],["landing",.87]]:
		world.mounted_rider.active = stage[0]!="idle"
		world.mounted_rider.phase = stage[1]
		world.mounted_rider.clock = stage[1]*.66
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ROOT+"previews/hop_"+stage[0]+".png")
	# Real travel drives this capture, with a fixed simulation step for repeatability.
	world.mounted_rider.reset()
	for i in 80:
		world.move_player(Vector2(0,1),1.0/30)
		world.camera_ground = world.player-Vector2(0,28)
		world.clock += 1.0/30
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		frame.get_region(Rect2i(18,226,296,322)).save_png("/tmp/kingdom-hop-frames/frame_%03d.png" % i)
	print("NORTH HOP PREVIEW: six poses and eighty frames of actual roaming")
	quit()
