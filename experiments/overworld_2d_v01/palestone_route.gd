@tool
extends Path2D

@export_enum("Packed earth:0","Shell gravel:1","Dirt:3") var surface := 0:
	set(value):
		surface = value
		queue_redraw()
@export_range(1.0,20.0,.25) var width := 8.0:
	set(value):
		width = value
		queue_redraw()

func _ready() -> void:
	if Engine.is_editor_hint() and curve!=null:
		curve.changed.connect(queue_redraw)

func _draw() -> void:
	if Engine.is_editor_hint() and curve!=null and curve.point_count>1:
		var color := Color("f0d7a9") if surface==1 else Color("d4ac73")
		draw_polyline(curve.get_baked_points(),color,width,true)
