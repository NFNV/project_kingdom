@tool
extends Path2D

@export_enum("Packed earth","Shell gravel") var surface := 0:
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
		var color := Color("d4ac73") if surface==0 else Color("f0d7a9")
		draw_polyline(curve.get_baked_points(),color,width,true)
