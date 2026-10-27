extends Node2D
const Style := preload("res://experiments/anime_hub_demo_v07/tools/art_style.gd")
const Art := preload("res://experiments/anime_hub_demo_v07/tools/equipment_art.gd")
var hub: Node2D
var kind := "counter"
var span := Vector2(2.8,.8)
var oak: Texture2D
var brick: Texture2D
var metal: Texture2D
var elapsed := 0.0
var illustration: Texture2D
var rack_blade: Texture2D

func p(u: float, v: float, height := 0.0) -> Vector2:
	return Vector2((u-v)*78,(u+v)*39-height)

func _ready() -> void:
	oak = Style.texture_for("oak")
	brick = Style.texture_for("brick")
	metal = Style.texture_for("slate")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if kind in ["counter","hearth","anvil"]:
		illustration = Art.prop("forge_"+kind)
	if kind=="rack":
		rack_blade = Art.icon("travel_sword")

func _process(delta: float) -> void:
	if kind=="hearth" and not hub.paused:
		elapsed += delta
		queue_redraw()

func box(w: float, d: float, height: float, tint: Color, texture: Texture2D) -> void:
	var a := p(-w*.5,-d*.5)
	var b := p(w*.5,-d*.5)
	var c := p(w*.5,d*.5)
	var e := p(-w*.5,d*.5)
	var up := Vector2(0,-height)
	var uv := PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
	draw_polygon(PackedVector2Array([e,c,c+up,e+up]),PackedColorArray([tint.darkened(.15)]),uv,texture)
	draw_polygon(PackedVector2Array([c,b,b+up,c+up]),PackedColorArray([tint.darkened(.30)]),uv,texture)
	draw_polygon(PackedVector2Array([a+up,b+up,c+up,e+up]),PackedColorArray([tint]),uv,texture)
	draw_polyline(PackedVector2Array([e+up,c+up,b+up]),Color("514b38"),2,true)

func _draw() -> void:
	draw_set_transform(Vector2(0,2),0,Vector2(1,.42))
	draw_circle(Vector2.ZERO,maxf(30,span.x*46),Color(.08,.11,.08,.2))
	draw_set_transform(Vector2.ZERO)
	if illustration!=null:
		var height: float = {"hearth":300.0,"counter":191.0,"anvil":112.0}[kind]
		var dimensions := illustration.get_size()*height/illustration.get_height()
		var offset := Vector2(-dimensions.x*.5,-dimensions.y+(span.x+span.y)*39*.5)
		draw_texture_rect(illustration,Rect2(offset,dimensions),false)
		if kind=="hearth":
			var data: Dictionary = Art.generation.assets.forge_hearth
			var region: Array = data.opaque_bounds
			var source: Array = data.effect_anchor
			var mouth := offset+Vector2((source[0]-region[0])/(region[2]-region[0]),(source[1]-region[1])/(region[3]-region[1]))*dimensions
			for i in 5:
				var at := mouth+Vector2((i-2)*5,2)
				var flame := 7+sin(elapsed*8+i*1.7)*3+i%2*3
				draw_colored_polygon(PackedVector2Array([at+Vector2(-3,0),at+Vector2(sin(elapsed*6+i)*2,-flame),at+Vector2(3,0)]),Color(1,.70,.27,.8))
		return
	if kind in ["counter","bench","crate"]:
		var height := 51.0 if kind=="counter" else 34.0
		box(span.x,span.y,height,Color("bd9e6c"),oak)
		for index in 4:
			var at := p(-span.x*.35+index*span.x*.22,span.y*.5,height-13)
			draw_circle(at,2,Color("dcc48b"))
		if kind=="counter":
			draw_line(p(-.6,0,54),p(.7,0,54),Color("b8c4bd"),5,true)
			draw_line(p(-.65,-.13,54),p(-.65,.13,54),Color("bda16b"),4,true)
			draw_circle(p(.8,.1,55),5,Color("bd8e45"))
		elif kind=="crate":
			draw_line(p(-.4,.43,2),p(.4,.43,32),Color("6c5d40"),5,true)
	elif kind=="anvil":
		box(.7,.6,35,Color("8b7251"),oak)
		var top := Vector2(0,-48)
		var outline := PackedVector2Array([Vector2(-48,-12),Vector2(10,-25),Vector2(60,-13),Vector2(28,0),Vector2(19,18),Vector2(-23,15),Vector2(-31,1)])
		for i in outline.size():
			outline[i] += top
		draw_colored_polygon(outline,Color("58666a"))
		draw_line(top+Vector2(-43,-13),top+Vector2(12,-24),Color("b5c1bd"),4,true)
		draw_line(top+Vector2(-12,-15),top+Vector2(18,-8),Color("bec9c1"),2,true)
	elif kind=="hearth":
		draw_set_transform(Vector2(38,-30))
		box(.65,.65,210,Color("88765c"),brick)
		draw_set_transform(Vector2.ZERO)
		box(span.x,span.y,119,Color("a78b72"),brick)
		var mouth := Vector2(-15,-50)
		draw_rect(Rect2(mouth-Vector2(41,38),Vector2(82,62)),Color("3c3025"))
		for ring in range(3,0,-1):
			draw_circle(mouth,22+ring*14,Color(1,.54,.14,.025))
		for i in 7:
			var at := mouth+Vector2((i-3)*9,13)
			var height := 23+sin(elapsed*7+i*1.5)*9+i%3*6
			draw_colored_polygon(PackedVector2Array([at+Vector2(-7,0),at+Vector2(sin(elapsed*9+i)*4,-height),at+Vector2(7,0)]),Color("f6ba60") if i%2 else Color("ffdf97"))
	elif kind=="rack":
		for v in [-.9,.9]:
			draw_line(p(0,v),p(0,v,128),Color("866b47"),9,true)
		for height in [32,112]:
			draw_line(p(0,-1.0,height),p(0,1.0,height),Color("a98a56"),8,true)
		for i in 3:
			var at := p(.12,-.65+i*.65,83)
			draw_set_transform(at,-PI/4)
			draw_texture_rect(rack_blade,Rect2(-29,-29,58,58),false)
			draw_set_transform(Vector2.ZERO)
