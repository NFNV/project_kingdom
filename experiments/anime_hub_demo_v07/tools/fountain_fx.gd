extends Node2D

# Registered to the original cutout: source pixels, not guessed world-space jets.
const SOURCE_ANCHOR := Vector2(767.5,948)
const SOURCE_SCALE := 235.0/886.0
var hub: Node2D
var streams := [
	[Vector2(642,278),Vector2(618,305),Vector2(608,430),Vector2(598,546)],
	[Vector2(903,278),Vector2(927,310),Vector2(937,440),Vector2(941,549)],
	[Vector2(695,353),Vector2(693,378),Vector2(694,413),Vector2(695,438)],
	[Vector2(850,354),Vector2(849,378),Vector2(850,411),Vector2(850,437)]
]


func curve(points: Array, t: float) -> Vector2:
	return points[0].bezier_interpolate(points[1],points[2],points[3],t)


func _draw() -> void:
	var time: float = hub.elapsed
	draw_set_transform(-SOURCE_ANCHOR*SOURCE_SCALE,0,Vector2.ONE*SOURCE_SCALE)
	for index in streams.size():
		var jet: Array = streams[index]
		var ribbon := PackedVector2Array()
		for step in 19:
			ribbon.append(curve(jet,step/18.0))
		draw_polyline(ribbon,Color(.37,.76,.86,.46),7,true)
		for streak in 8:
			var t := fposmod(time*1.05+streak/8.0+index*.19,1.0)
			var segment := PackedVector2Array()
			for step in 5:
				segment.append(curve(jet,clampf(t+step*.012,0,1)))
			draw_polyline(segment,Color(.88,.98,1,.4+.35*sin(t*PI)),2.6,true)
		var impact: Vector2 = jet[3]
		for drop in 7:
			var t := fposmod(time*1.7+drop/7.0+index*.17,1)
			var spread := sin(drop*4.7+index)*26
			var at := impact+Vector2(spread*t,-sin(t*PI)*22+t*5)
			draw_circle(at,2.2,Color(.87,.98,1,(1-t)*.85))
		for ring in 2:
			var t := fposmod(time*.85+ring*.5+index*.2,1)
			draw_set_transform((-SOURCE_ANCHOR+impact)*SOURCE_SCALE,0,Vector2(1,.3)*SOURCE_SCALE)
			draw_arc(Vector2.ZERO,8+38*t,0,TAU,32,Color(.85,.98,1,(1-t)*.6),2,true)
			draw_set_transform(-SOURCE_ANCHOR*SOURCE_SCALE,0,Vector2.ONE*SOURCE_SCALE)
	# Highlights stay on exposed pool water, clear of the central stone pedestal.
	for index in 9:
		var x := 540+index*57.0
		var y := 664+sin(index*1.8)*29
		var pulse := .22+.18*sin(time*2.6+index*1.7)
		draw_line(Vector2(x,y),Vector2(x+15+sin(time+index)*6,y-1),Color(.93,.99,1,pulse),2,true)
	draw_set_transform(Vector2.ZERO)
