extends SceneTree
# Native GPU regression: compare actual shader pixels on the same world ray.
# Run without --headless; the headless renderer cannot validate shader output.
const ROOT := "res://experiments/overworld_2d_v01/"
const FOCAL := 900.0
var checks := 0
var failures: Array[String] = []
var material: ShaderMaterial

func _initialize() -> void:
 run.call_deferred()

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures.append(message)
  push_error(message)

func capture(yaw: float, elapsed := 0.0, night := 0.0) -> Image:
 material.set_shader_parameter("camera_yaw",yaw)
 material.set_shader_parameter("world_time",elapsed)
 material.set_shader_parameter("night",night)
 for i in 3: await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()

func ray_pixel(bearing: float, yaw: float) -> int:
 return roundi(960+FOCAL*tan(wrapf(bearing-yaw,-PI,PI)))

func color_error(a: Color, b: Color) -> float:
 return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))

func image_error(a: Image, b: Image) -> float:
 var worst := 0.0
 for x in range(0,1920,17):
  for y in range(0,1080,17):
   worst = maxf(worst,color_error(a.get_pixel(x,y),b.get_pixel(x,y)))
 return worst

func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Sky projection checks require the native GPU renderer")
  quit(1)
  return
 root.size = Vector2i(1920,1080)
 root.content_scale_size = root.size
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var fixture := Image.create(1024,128,false,Image.FORMAT_RGBA8)
 for y in 128:
  for x in 1024:
   var angle := TAU*x/1023.0
   fixture.set_pixel(x,y,Color(.5+.4*sin(angle),.5+.4*cos(angle),.1+.7*y/127.0))
 fixture.generate_mipmaps()
 var texture := ImageTexture.create_from_image(fixture)
 var sky := TextureRect.new()
 sky.texture = texture
 sky.size = Vector2(1920,1080)
 material = ShaderMaterial.new()
 material.shader = load(ROOT+"sky.gdshader")
 material.set_shader_parameter("day_sky",texture)
 material.set_shader_parameter("night_sky",texture)
 material.set_shader_parameter("focal",FOCAL)
 sky.material = material
 root.add_child(sky)
 var north := await capture(0)
 # Sample fixed directions at multiple elevations, including the screen edges.
 for yaw in [-.2,.2]:
  var turned := await capture(yaw)
  var worst := 0.0
  for bearing in [-.58,0.0,.35,.58]:
   for y in [90,250,450]:
    var a := north.get_pixel(ray_pixel(bearing,0),y)
    var b := turned.get_pixel(ray_pixel(bearing,yaw),y)
    worst = maxf(worst,color_error(a,b))
  check(worst<.008,"Painted sky follows world rays at camera yaw %.1f, including edge perspective (error %.4f)" % [yaw,worst])
 var full_turn := await capture(TAU)
 check(image_error(north,full_turn)<=1.0/255.0+.00001,"A complete camera turn restores sky pixels within GPU rounding tolerance")
 var wrapped_left := await capture(-PI)
 var wrapped_right := await capture(PI)
 check(image_error(wrapped_left,wrapped_right)<=1.0/255.0+.00001,"Yaw wrapping at +/- PI cannot snap the sky")
 var later := await capture(0,600)
 check(north.get_data()==later.get_data(),"Elapsed time cannot drag the entire painted sky")
 # Cross the painted strip's blended wrap while tracking the same world point.
 var first := await capture(.8)
 var second := await capture(1.2)
 var worst_seam := 0.0
 for bearing in [1.0,1.0472,1.1]:
  worst_seam = maxf(worst_seam,color_error(first.get_pixel(ray_pixel(bearing,.8),200),second.get_pixel(ray_pixel(bearing,1.2),200)))
 check(worst_seam<.008,"World rays remain aligned through the painting wrap (error %.4f)" % worst_seam)
 var night_start := await capture(0,0,1)
 var night_later := await capture(0,600,1)
 var error_total := 0.0
 for x in range(40,1880,41):
  for y in range(30,480,37):
   error_total += color_error(night_start.get_pixel(x,y),night_later.get_pixel(x,y))
 check(error_total/(45*13)<.005,"Night painting and stars hold their positions while individual stars twinkle")
 sky.queue_free()
 await process_frame
 # Capture the real game after the fixture checks, using the existing artwork.
 var world := load(ROOT+"world.tscn").instantiate() as Node2D
 root.add_child(world)
 world.automated = true
 world.auto_clock = false
 world.set_physics_process(false)
 world.visit(3)
 world.notice_left = 0
 for phase in [["day",1.0],["night",3.0]]:
  world.day_phase = phase[1]
  for view in [["north",0.0],["turned",.4]]:
   world.camera_yaw = view[1]
   world.update_camera()
   for i in 3: await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(ROOT+"previews/sky_projection_"+phase[0]+"_"+view[0]+".png")
 FileAccess.open(ROOT+"sky_projection_results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"scope":"Native GPU pixel comparisons of angular sky/terrain alignment, edge perspective, full-turn and yaw-wrap continuity, painting-seam rays, time stability and stationary night painting with star twinkle."},"  ")+"\n")
 print("SKY PROJECTION CHECKS ",checks-failures.size(),"/",checks)
 quit(0 if failures.is_empty() else 1)
