extends RefCounted
# Phase conventions match Garden Square: dawn=0, noon=1, dusk=2, midnight=3.
const CYCLE_SECONDS := 1200.0
const MOON_DIAMETER := 380.0
const SUN_DIAMETER := 230.0
const TINTS := [Color(1,.86,.73),Color.WHITE,Color(.93,.67,.66),Color(.37,.47,.72)]
const HAZE := [Color("c5aaa2"),Color("abcaaa"),Color("b5909f"),Color("283b64")]
const SKY_TINTS := [Color(1,.82,.78),Color.WHITE,Color(1,.65,.68),Color.WHITE]

static func sample(phase: float) -> Dictionary:
 var p := fposmod(phase,4)
 var base := floori(p)
 var weight := smoothstep(.08,.95,fposmod(p,1))
 var solar := sin(p*PI*.5)
 return {"tint":TINTS[base].lerp(TINTS[(base+1)%4],weight),"haze":HAZE[base].lerp(HAZE[(base+1)%4],weight),"sky_tint":SKY_TINTS[base].lerp(SKY_TINTS[(base+1)%4],weight),"night":smoothstep(0,.65,-solar),"lamps":1.0-smoothstep(.05,.45,solar),"twilight":pow(1-absf(solar),3),"solar":solar}

static var bloom: GradientTexture2D

static func glow(canvas: Node2D, at: Vector2, radius: float, strength: float, color := Color("ffca78"), core := true) -> void:
 if strength<.005: return
 if bloom==null:
  var gradient := Gradient.new()
  gradient.offsets = PackedFloat32Array([0,.18,.45,.75,1])
  gradient.colors = PackedColorArray([Color(1,1,1,.65),Color(1,1,1,.30),Color(1,1,1,.10),Color(1,1,1,.02),Color(1,1,1,0)])
  bloom = GradientTexture2D.new()
  bloom.width = 64
  bloom.height = 64
  bloom.gradient = gradient
  bloom.fill = GradientTexture2D.FILL_RADIAL
  bloom.fill_from = Vector2(.5,.5)
  bloom.fill_to = Vector2(1,.5)
 color.a = strength
 canvas.draw_texture_rect(bloom,Rect2(at-Vector2.ONE*radius*1.7,Vector2.ONE*radius*3.4),false,color)
 if core: canvas.draw_circle(at,maxf(1.1,radius*.10),Color(1,.9,.61,strength*.85))

static func celestial_position(phase: float, _camera_yaw: float, is_moon: bool) -> Vector2:
 # A gentle, periodic sky composition for the fixed camera. Both complete
 # silhouettes stay above the terrain and outside the clock/minimap panels.
 var angle := fposmod(phase,4)*PI*.5
 if is_moon:
  return Vector2(1290+40*sin(angle-PI*1.5),235+50*pow(cos(angle-PI),2))
 return Vector2(685+20*sin(angle-PI*.5),180+100*pow(cos(angle),2))

static func moon_is_visible(phase: float) -> bool:
 # Dawn (06:00) and dusk (18:00) switch the drawing, not its opacity.
 # Lighting and painted skies can still blend smoothly through twilight.
 return fposmod(phase,4)>=2.0

static func draw_celestials(world: Node2D, canvas: Node2D) -> void:
 var p: float = world.day_phase
 var show_moon := moon_is_visible(p)
 if not show_moon:
  var sun := celestial_position(p,world.camera_yaw,false)
  glow(canvas,sun,SUN_DIAMETER*.5,.24,Color("ffe6ac"),false)
  var size: Vector2 = world.sun_texture.get_size()
  size *= SUN_DIAMETER/maxf(size.x,size.y)
  canvas.draw_texture_rect(world.sun_texture,Rect2(sun-size*.5,size),false,Color.WHITE)
 else:
  var moon := celestial_position(p,world.camera_yaw,true)
  glow(canvas,moon,MOON_DIAMETER*.56,.38,Color("d7e3ff"),false)
  var size: Vector2 = world.moon_texture.get_size()
  size *= MOON_DIAMETER/maxf(size.x,size.y)
  canvas.draw_texture_rect(world.moon_texture,Rect2(moon-size*.5,size),false,Color(1.08,1.09,1.12,1))
 var night: float = world.lighting.night
 # Tiny silhouettes drift independently of the painted cloud layer.
 if not show_moon:
  for i in 4:
   var bearing: float = wrapf(world.clock*.01+i*.24-.8-world.camera_yaw,-PI,PI)
   if absf(bearing)>atan(1000.0/900.0): continue
   var bird := Vector2(960+900*tan(bearing),260+sin(world.clock*.13+i)*32+i*17)
   var flap := sin(world.clock*4+i)*3
   var tint := Color(.24,.37,.45,(1-night)*.55)
   canvas.draw_polyline(PackedVector2Array([bird+Vector2(-7,-2-flap),bird,bird+Vector2(7,-2-flap)]),tint,1.2,true)
