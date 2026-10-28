extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
var gallery: Node2D
var gallery_phase := 0.0
var gallery_active := false
func _initialize() -> void:
	run.call_deferred()
func draw_gallery() -> void:
	gallery.draw_rect(Rect2(0,0,1920,1080),Color("294a3d"))
	var font := ThemeDB.fallback_font
	gallery.draw_string(font,Vector2(30,42),"PROJECT KINGDOM  ·  EIGHT-DIRECTION MOUNT STUDY",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("f4e7bb"))
	for i in 8:
		var x := 20+(i%4)*475
		var y := 68+(i/4)*500
		gallery.draw_style_box(world.panel_style(Color("e9dfb9")),Rect2(x,y,450,470))
		gallery.draw_string(font,Vector2(x+22,y+40),world.Rider.DIRECTION_NAMES[i],HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("294a3d"))
		world.mounted_rider.direction_index = i
		world.mounted_rider.phase = gallery_phase
		world.mounted_rider.active = gallery_active
		world.mounted_rider.clock = gallery_phase*.66
		world.mounted_rider.draw(gallery,Vector2(x+225,y+420),1.65)
func run() -> void:
	world = load(ROOT+"world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.automated = true
	world.hop_study = true
	world.notice_left = 0
	for i in 8:
		world.mounted_rider.direction_index = i
		world.mounted_rider.phase = .54
		world.mounted_rider.active = true
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ROOT+"previews/direction_"+world.mounted_rider.direction_name()+".png")
	world.hide()
	gallery = Node2D.new()
	gallery.draw.connect(draw_gallery)
	root.add_child(gallery)
	gallery.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ROOT+"previews/eight_directions_idle.png")
	gallery_active = true
	gallery_phase = .54
	gallery.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ROOT+"previews/eight_directions_airborne.png")
	for i in 40:
		gallery_phase = float(i%20)/20.0
		gallery.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/kingdom-directions/frame_%03d.png" % i)
	print("EIGHT VIEWS: world captures, idle/airborne gallery and forty animation frames")
	quit()
