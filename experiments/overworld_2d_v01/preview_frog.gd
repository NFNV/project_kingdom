extends SceneTree
const ROOT := "res://experiments/overworld_2d_v01/"
var world: Node2D
var canvas: Node2D
var phase := 0.0
func _initialize() -> void:
	run.call_deferred()
func draw_review() -> void:
	canvas.draw_rect(Rect2(0,0,1920,1080),Color("294a3d"))
	var font := ThemeDB.fallback_font
	for i in 2:
		var x := 360+i*600
		canvas.draw_style_box(world.panel_style(Color("e9dfb9")),Rect2(x,80,560,920))
		canvas.draw_string(font,Vector2(x+30,135),"FRONT" if i==0 else "THREE-QUARTER",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("294a3d"))
		world.mounted_rider.direction_index = 4 if i==0 else 3
		world.mounted_rider.phase = phase
		world.mounted_rider.active = true
		world.mounted_rider.clock = phase*.66
		world.mounted_rider.draw(canvas,Vector2(x+280,930),3.1)
func run() -> void:
	world = load(ROOT+"world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.hide()
	canvas = Node2D.new()
	canvas.draw.connect(draw_review)
	root.add_child(canvas)
	for i in 40:
		phase = float(i%20)/20
		canvas.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image().get_region(Rect2i(240,52,774,615))
		image.resize(600,477,Image.INTERPOLATE_LANCZOS)
		image.save_png("/tmp/kingdom-frog-review/frame_%03d.png" % i)
	print("FROG REVIEW: front and diagonal, two complete hop cycles")
	quit()
