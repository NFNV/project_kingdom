extends Control

# An original brass celestial dial, inspired by classic RTS day/night clocks.
# Native geometry keeps the clock crisp at any display scale.
var phase := 1.0
var hour := 12.0
var clock_text: Label
var phase_text: Label
var serif: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(280,212)
	clock_text = Label.new()
	clock_text.position = Vector2(54,146)
	clock_text.size = Vector2(172,36)
	clock_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_text.add_theme_font_size_override("font_size",25)
	clock_text.add_theme_color_override("font_color",Color("fff0c7"))
	if serif:
		clock_text.add_theme_font_override("font",serif)
	add_child(clock_text)
	phase_text = Label.new()
	phase_text.position = Vector2(30,178)
	phase_text.size = Vector2(220,28)
	phase_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_text.add_theme_font_size_override("font_size",13)
	phase_text.add_theme_color_override("font_color",Color("ead5a6"))
	add_child(phase_text)
	set_phase(phase)


func set_phase(value: float) -> void:
	phase = fposmod(value,4)
	hour = fposmod((phase+1)*6,24)
	if clock_text:
		clock_text.text = "%02d:%02d" % [int(hour),int(fposmod(hour,1)*60)]
		phase_text.text = ["D A W N","D A Y L I G H T","D U S K","M O O N L I G H T"][int(phase)]
	queue_redraw()


func _star(at: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 8:
		var r := radius if i%2==0 else radius*0.25
		points.append(at+Vector2(cos(i*PI/4),sin(i*PI/4))*r)
	draw_colored_polygon(points,color)


func _sun(at: Vector2, radius: float, strength := 1.0) -> void:
	for i in 12:
		var ray := Vector2.from_angle(i*TAU/12)
		draw_line(at+ray*(radius+4),at+ray*(radius+8),Color(1,.78,.29,strength),2,true)
	draw_circle(at+Vector2(0,2),radius+2,Color(.5,.27,.07,strength))
	draw_circle(at,radius,Color(1,.77,.25,strength))
	draw_circle(at+Vector2(-radius*.2,-radius*.25),radius*.65,Color(1,.91,.59,strength))


func _moon(at: Vector2, radius: float, sky: Color) -> void:
	draw_circle(at,radius,Color("e0e8ff"))
	draw_circle(at+Vector2(radius*.46,-radius*.28),radius*.87,sky)


func _draw() -> void:
	var center := Vector2(140,76)
	var gold := Color("c9a65b")
	var pale := Color("f3d58a")
	# Leaf-shaped wings and a carved plinth, rather than a flat HUD box.
	for side in [-1,1]:
		var wing := PackedVector2Array([center+Vector2(side*55,4),center+Vector2(side*125,-9),center+Vector2(side*101,18),center+Vector2(side*70,32)])
		draw_colored_polygon(wing,Color("243e3a"))
		draw_polyline(wing+PackedVector2Array([wing[0]]),gold,1.5,true)
		draw_line(center+Vector2(side*72,14),center+Vector2(side*109,1),gold,1,true)
		draw_circle(center+Vector2(side*116,-2),3,pale)
	draw_style_box(_plinth(),Rect2(61,136,158,70))
	draw_circle(center+Vector2(0,5),73,Color(0,0,0,.22))
	draw_circle(center,72,Color("403125"))
	draw_circle(center,70,gold)
	draw_circle(center,67,Color("765c38"))
	draw_circle(center,64,pale)
	var night := smoothstep(17.0,20.0,hour) if hour>=12 else 1.0-smoothstep(4.0,7.0,hour)
	var sky := Color("719c9a").lerp(Color("172744"),night)
	draw_circle(center,61,sky)
	for i in 12:
		var r := 59.0-i*2.0
		draw_circle(center+Vector2(0,-i*.4),r,sky.lightened(i*.006))
	# Day and night halves around the dial, with a moving jeweled hour pointer.
	draw_arc(center,67,PI,TAU,48,Color("f4ca72"),3,true)
	draw_arc(center,67,0,PI,48,Color("a6b8d3"),3,true)
	for i in 24:
		var ray := Vector2.from_angle(i*TAU/24-PI/2)
		draw_line(center+ray*54,center+ray*(59 if i%6==0 else 57),Color(pale,.8),1.5,true)
	var pointer := Vector2.from_angle((hour-12)*TAU/24-PI/2)
	_star(center+pointer*68,6,Color("fff2bd"))
	if hour>=6 and hour<18:
		_sun(center+Vector2(0,-8),19)
		# A gentle horizon line under the sun.
		draw_arc(center+Vector2(0,56),39,PI*1.14,PI*1.86,28,Color("abc3a9"),2,true)
	else:
		_moon(center+Vector2(-3,-9),24,sky.lightened(.045))
		_star(center+Vector2(29,-27),4,Color("d9e8ff"))
		_star(center+Vector2(-28,-36),3,Color("d9e8ff"))
		_star(center+Vector2(24,13),3,Color("d9e8ff"))
	_sun(center+Vector2(-57,41),7,.85)
	_moon(center+Vector2(57,41),10,Color("243e3a"))


func _plinth() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("243e3a")
	style.border_color = Color("c9a65b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	return style
