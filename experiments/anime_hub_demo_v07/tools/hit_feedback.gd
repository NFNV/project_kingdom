extends Node2D

var hub: Node2D
var amount := 1
var heading := Vector2.RIGHT
var elapsed := 0.0

func _process(delta: float) -> void:
	if hub.paused or hub.transitioning:
		return
	elapsed += delta
	if elapsed>=.55:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var alpha := 1.0-smoothstep(.25,.55,elapsed)
	var center := Vector2(0,-35)
	if elapsed<.20:
		for i in 6:
			var angle := heading.angle()+i*TAU/6.0
			var normal := Vector2.from_angle(angle)
			draw_line(center+normal*(5+elapsed*40),center+normal*(12+elapsed*65),Color(1,.91,.60,alpha),2,true)
	var at := Vector2(-8,-77-elapsed*30)
	var text := "−"+str(amount)
	draw_string_outline(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,17,4,Color(.20,.24,.24,alpha))
	draw_string(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(1,.94,.73,alpha))
