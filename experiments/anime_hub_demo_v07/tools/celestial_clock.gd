extends Control
## Four original painted medallions share the game's dawn/noon/dusk/night clock.
const ATLAS := "res://experiments/anime_hub_demo_v07/assets/hud/celestial_medallions_v1.png"
var phase := 1.0
var hour := 12.0
var clock_text: Label
var phase_text: Label
var serif: Font
var paintings: Array[AtlasTexture] = []

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 size = Vector2(280,212)
 var atlas: Texture2D = load(ATLAS)
 var cell := atlas.get_size()*.5
 for i in 4:
  var painting := AtlasTexture.new()
  painting.atlas = atlas
  painting.region = Rect2(Vector2(i%2,i>>1)*cell,cell)
  painting.filter_clip = true
  paintings.append(painting)
 clock_text = Label.new()
 clock_text.position = Vector2(54,166)
 clock_text.size = Vector2(172,29)
 clock_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 clock_text.add_theme_font_size_override("font_size",24)
 clock_text.add_theme_color_override("font_color",Color("fff0cc"))
 if serif: clock_text.add_theme_font_override("font",serif)
 add_child(clock_text)
 phase_text = Label.new()
 phase_text.position = Vector2(30,193)
 phase_text.size = Vector2(220,18)
 phase_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 phase_text.add_theme_font_size_override("font_size",14)
 phase_text.add_theme_color_override("font_color",Color("d6c49c"))
 add_child(phase_text)
 set_phase(phase)

func set_phase(value: float) -> void:
 phase = fposmod(value,4)
 hour = fposmod((phase+1)*6,24)
 if clock_text:
  clock_text.text = "%02d:%02d" % [int(hour),int(fposmod(hour,1)*60)]
  phase_text.text = ["DAWN","DAYLIGHT","DUSK","MOONLIGHT"][int(phase)]
 queue_redraw()

func _draw() -> void:
 if paintings.size()!=4: return
 var rect := Rect2(48,0,184,184)
 var current := int(floorf(phase))%4
 var blend := smoothstep(.78,1.0,fposmod(phase,1))
 draw_texture_rect(paintings[current],rect,false)
 if blend>.001:
  draw_texture_rect(paintings[(current+1)%4],rect,false,Color(1,1,1,blend))
 var ribbon := StyleBoxFlat.new()
 ribbon.bg_color = Color("293c33")
 ribbon.border_color = Color("b69a66")
 ribbon.set_border_width_all(1)
 ribbon.set_corner_radius_all(7)
 draw_style_box(ribbon,Rect2(82,165,116,47))
 # Small pearl progresses around the engraved rim over the complete day.
 var angle := (hour-12)*TAU/24-PI/2
 var point := Vector2(140,92)+Vector2.from_angle(angle)*84
 draw_circle(point,3,Color("f6df9d"))
