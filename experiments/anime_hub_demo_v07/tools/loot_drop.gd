extends Node2D
## Small reusable native drawing; no new texture or per-frame image work.
var hub: Node2D
var age := 0.0

func _process(delta: float) -> void:
	if hub.paused:
		return
	age += delta
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0,2),0,Vector2(1,.45))
	draw_circle(Vector2.ZERO,18,Color(.08,.12,.08,.28))
	draw_arc(Vector2.ZERO,20+sin(age*2)*2,0,TAU,28,Color(.96,.82,.42,.65),2,true)
	draw_set_transform(Vector2(0,-8+sin(age*2)*2))
	draw_colored_polygon(PackedVector2Array([Vector2(-9,-3),Vector2(-6,-13),Vector2(6,-13),Vector2(10,-3),Vector2(8,5),Vector2(-8,5)]),Color("765839"))
	draw_line(Vector2(-6,-11),Vector2(6,-11),Color("dfc78d"),3,true)
	draw_circle(Vector2(0,-2),5,Color("d7b760"))
	draw_line(Vector2(-2,-3),Vector2(2,0),Color("4e624c"),2,true)
