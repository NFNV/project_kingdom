extends Node2D

var hub: Node2D
var positions: Array[Vector2] = []
var redraw_left := 0.0

func _process(delta: float) -> void:
	if hub.paused:
		return
	redraw_left -= delta
	if redraw_left<=0:
		redraw_left = .1
		queue_redraw()

func _draw() -> void:
	var night := clampf((.9-hub.actor_tint.g)*1.8,0,1)
	if night<=0:
		return
	for at in positions:
		var strength := night*(.96+.04*sin(hub.elapsed*1.3+at.x))
		draw_set_transform(at,0,Vector2(1,.45))
		for ring in range(5,0,-1):
			draw_circle(Vector2.ZERO,ring*14,Color(1,.77,.35,strength*.025))
		draw_set_transform(Vector2.ZERO)
		draw_circle(at+Vector2(0,-153),9,Color(1,.84,.48,strength*.3))
		draw_circle(at+Vector2(0,-153),4,Color(1,.91,.66,strength*.8))
