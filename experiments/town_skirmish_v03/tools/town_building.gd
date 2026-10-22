extends Node3D

const ART := "res://experiments/town_skirmish_v03/assets/"
var town: Node3D
var origin: Vector3
var width: float
var height: float
var depth: float
var roof_rise: float
var shop := false
var plaster: ShaderMaterial
var slate: StandardMaterial3D
var glass: ShaderMaterial


func build(world: Node3D, at: Vector3, is_shop: bool) -> void:
	town = world
	origin = at
	position = at
	shop = is_shop
	name = "CommunityHall" if shop else "Cottage"
	width = 6.6 if shop else 5.5
	height = 3.5 if shop else 4.5
	depth = 4.0
	roof_rise = 1.8
	plaster = ShaderMaterial.new()
	plaster.shader = preload("res://experiments/town_skirmish_v03/tools/plaster.gdshader")
	plaster.set_shader_parameter("plaster_texture",load(ART+"warm_plaster.png"))
	plaster.set_shader_parameter("eave_height",height)
	slate = _textured("blue_slate.png")
	glass = ShaderMaterial.new()
	glass.shader = preload("res://experiments/town_skirmish_v03/tools/window.gdshader")
	var walls := MeshInstance3D.new()
	walls.name = "StraightWalls"
	var box := BoxMesh.new()
	box.size = Vector3(width, height, depth)
	walls.mesh = box
	walls.material_override = plaster
	walls.position.y = height/2.0 + 0.1
	add_child(walls)
	town._obstacle(origin, Vector3(width, height, depth))
	_box(Vector3(0, 0.15, 0), Vector3(width+0.12, 0.3, depth+0.12), "9c9c86")
	# Individual masonry blocks and capstones create small, real contact shadows.
	for row in 2:
		for column in int(width/0.55):
			var x := -width/2.0+0.28+column*0.55+row*0.13
			_box(Vector3(x,0.10+row*0.16,depth/2.0+0.07),Vector3(0.51,0.135,0.08),"aaa38c")
	_box(Vector3(0,0.38,depth/2.0+0.08),Vector3(width+0.18,0.1,0.23),"d8c295")
	for x in [-width/2.0+0.06, width/2.0-0.06]:
		_box(Vector3(x, height/2.0, depth/2.0+0.04), Vector3(0.13,height,0.15), "795a40")
	for y in [0.45, height]:
		_box(Vector3(0, y, depth/2.0+0.04), Vector3(width,0.13,0.16), "795a40")
	for y in [height-0.16,height-0.29]:
		_box(Vector3(0,y,depth/2.0+0.11),Vector3(width+0.18,0.065,0.24),"d8c295")
	_roof()
	_chimney(Vector3(-width*0.25,height+0.6,-0.65))
	if shop:
		_window(Vector3(-1.2,1.65,depth/2.0+0.06),2.45,1.65)
		_door(Vector3(1.75,0,depth/2.0+0.08))
		_awning()
		_box(Vector3(0,3.24,depth/2.0+0.11),Vector3(4.6,0.43,0.13),"3e6768")
		var sign := Label3D.new()
		sign.text = "GARDEN HALL"
		sign.font_size = 54
		sign.pixel_size = 0.009
		sign.modulate = Color("fff0c2")
		sign.position = Vector3(0,3.23,depth/2.0+0.29)
		sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sign)
	else:
		_box(Vector3(0,2.45,depth/2.0+0.04),Vector3(width,0.13,0.15),"795a40")
		for x in [-1.65,1.65]:
			_window(Vector3(x,1.55,depth/2.0+0.06),0.9,1.15)
		for x in [-1.6,0.0,1.6]:
			_window(Vector3(x,3.5,depth/2.0+0.06),0.85,1.05)
			_box(Vector3(x,2.8,depth/2.0+0.16),Vector3(1.0,0.22,0.32),"856342")
			town._card("garden",origin+Vector3(x,2.9,depth/2.0+0.20),0.44)
		_door(Vector3(0,0,depth/2.0+0.08))
		_porch()
	_gable_vent()
	# Gutter and downpipe follow the wall axes, never the billboard camera.
	for x in [-width/2.0-0.14,width/2.0+0.14]:
		_box(Vector3(x,height-0.12,0),Vector3(0.15,0.13,depth+0.7),"4c6679")
	_box(Vector3(width/2.0+0.10,height/2.0,depth/2.0-0.10),Vector3(0.075,height,0.075),"4c6679")
	for y in ([1.75] if shop else [1.55,3.5]):
		_window(Vector3(width/2.0+0.06,y,0),1.1,1.1,true)
	for step in 3:
		_box(Vector3(1.75 if shop else 0,0.04+step*0.045,depth/2.0+0.65-step*0.18),Vector3(1.55,0.1,0.65),"bdb69a")
	for x in [-width/2.0-0.25,width/2.0+0.25]:
		town._card("garden",origin+Vector3(x,0.08,depth/2.0+0.1),0.9)


func _textured(file: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(ART+file)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _box(at: Vector3, size: Vector3, color: String) -> void:
	town._box(origin+at,size,Color(color))


func _roof() -> void:
	var half := width/2.0+0.28
	var back := -depth/2.0-0.3
	var front := depth/2.0+0.3
	var ridge := height+roof_rise
	for side in [-1.0,1.0]:
		var vertices := [Vector3(0,ridge,back),Vector3(half*side,height-0.03,back),Vector3(half*side,height-0.03,front),Vector3(0,ridge,front)]
		_surface("RoofSlopeLeft" if side<0 else "RoofSlopeRight",vertices,[Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)],slate)
		_box(Vector3(half*side,height-0.06,0),Vector3(0.12,0.16,depth+0.7),"4c6679")
	for z in [-depth/2.0,depth/2.0]:
		_triangle([Vector3(-width/2.0,height,z),Vector3(width/2.0,height,z),Vector3(0,ridge,z)],plaster)
	_box(Vector3(0,ridge,0),Vector3(0.16,0.13,depth+0.7),"57789a")
	# Fascia boards use the same exact roof endpoints as the roof mesh.
	for side in [-1.0,1.0]:
		for z in [back,front]:
			var start := Vector3(0,ridge,z)
			var end := Vector3(half*side,height-0.03,z)
			_beam(start,end,0.13,0.12,"8a6947")
			_beam(start+Vector3(0,-0.14,0.01),end+Vector3(0,-0.14,0.01),0.065,0.14,"d8c295")
	# Segmented ridge caps give the roof a stronger silhouette at 1080p.
	for index in 15:
		_box(Vector3(0,ridge+0.06,lerpf(back,front,float(index)/14.0)),Vector3(0.23,0.08,0.27),"4c6679")


func _beam(start: Vector3, end: Vector3, h: float, d: float, hex: String) -> void:
	var color := Color(hex)
	if not town.box_batches.has(color):
		town.box_batches[color] = []
	var rotation := Basis(Vector3.BACK,atan2(end.y-start.y,end.x-start.x))
	town.box_batches[color].append(Transform3D(rotation*Basis.from_scale(Vector3(start.distance_to(end),h,d)),origin+(start+end)/2.0))


func _surface(label: String, vertices: Array, uvs: Array, material: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := [0,2,1,0,3,2] if vertices[1].x<0 else [0,1,2,0,2,3]
	for index in indices:
		tool.set_uv(uvs[index])
		tool.add_vertex(vertices[index])
	tool.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = tool.commit()
	instance.material_override = material
	add_child(instance)


func _triangle(vertices: Array, material: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Godot uses clockwise front faces. Front and rear gables face outwards.
	for index in ([0,2,1] if vertices[0].z>0 else [0,1,2]):
		tool.set_uv([Vector2(0,0),Vector2(1,0),Vector2(0.5,1)][index])
		tool.add_vertex(vertices[index])
	tool.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = "FrontGable" if vertices[0].z>0 else "RearGable"
	instance.mesh = tool.commit()
	instance.material_override = material
	add_child(instance)


func _window(at: Vector3, w: float, h: float, side := false) -> void:
	var u := Vector3.BACK if side else Vector3.RIGHT
	var normal := Vector3.RIGHT if side else Vector3.BACK
	_box(at-normal*0.015,Vector3(0.07,h+0.26,w+0.26) if side else Vector3(w+0.26,h+0.26,0.07),"795a40")
	_box(at,Vector3(0.09,h+0.2,w+0.2) if side else Vector3(w+0.2,h+0.2,0.09),"e1cca1")
	var pane := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(w,h)
	pane.mesh = quad
	pane.material_override = glass
	pane.position = at+normal*0.065
	if side:
		pane.rotation.y = PI/2.0
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pane)
	for x in [-w/2.0,0.0,w/2.0]:
		_box(at+u*x+normal*0.10,Vector3(0.06,h,0.045) if side else Vector3(0.045,h,0.06),"547875")
	for y in [-h/2.0,0.0,h/2.0]:
		_box(at+Vector3(0,y,0)+normal*0.10,Vector3(0.06,0.055,w) if side else Vector3(w,0.055,0.06),"547875")
	_box(at+Vector3(0,-h/2.0-0.13,0)+normal*0.09,Vector3(0.32,0.12,w+0.38) if side else Vector3(w+0.38,0.12,0.32),"d8c295")
	if w<1.3:
		for direction in [-1.0,1.0]:
			var shutter: Vector3 = at+u*direction*(w/2.0+0.24)+normal*0.015
			_box(shutter,Vector3(0.09,h,0.30) if side else Vector3(0.30,h,0.09),"3e6768")
			for slat in 7:
				_box(shutter+Vector3(0,-h*.4+slat*h*.13,0)+normal*.065,Vector3(0.05,0.025,0.24) if side else Vector3(0.24,0.025,0.05),"547875")


func _door(at: Vector3) -> void:
	_box(at+Vector3(0,1.04,0),Vector3(1.25,2.08,0.14),"d8c295")
	_box(at+Vector3(0,1.0,0.09),Vector3(1.05,1.94,0.1),"3e6768")
	for x in [-0.35,-0.17,0.0,0.17,0.35]:
		_box(at+Vector3(x,0.75,0.15),Vector3(0.015,1.3,0.01),"2e5356")
	_box(at+Vector3(0,1.55,0.16),Vector3(0.7,0.5,0.025),"b7c7b7")
	_box(at+Vector3(0.36,0.9,0.20),Vector3(0.07,0.07,0.06),"d0a35c")
	for y in [0.42,0.96]:
		_box(at+Vector3(0,y,0.155),Vector3(0.80,0.35,0.025),"547875")
	_box(at+Vector3(-0.42,0.1,0.38),Vector3(0.42,0.2,0.42),"985c43")
	town._card("garden",origin+at+Vector3(-0.42,0.2,0.38),0.60)


func _porch() -> void:
	var z := depth/2.0
	_surface("PorchRoof",[Vector3(-1.03,2.46,z+0.03),Vector3(1.03,2.46,z+0.03),Vector3(1.03,2.21,z+1.1),Vector3(-1.03,2.21,z+1.1)],[Vector2(0,0),Vector2(1,0),Vector2(1,0.5),Vector2(0,0.5)],slate)
	_box(Vector3(0,2.18,z+1.1),Vector3(2.16,0.13,0.13),"d8c295")
	for x in [-0.92,0.92]:
		_box(Vector3(x,1.12,z+0.93),Vector3(0.13,2.24,0.13),"d8c295")
		_box(Vector3(x,0.2,z+0.93),Vector3(0.23,0.38,0.23),"aaa38c")
		town._obstacle(origin+Vector3(x,0,z+0.93),Vector3(0.23,2.24,0.23))
		_beam(Vector3(x,1.72,z+0.93),Vector3(x-signf(x)*0.35,2.15,z+0.93),0.065,0.08,"8a6947")


func _gable_vent() -> void:
	var at := Vector3(0,height+0.57,depth/2.0+0.04)
	_box(at,Vector3(0.87,0.65,0.10),"d8c295")
	_box(at+Vector3(0,0,0.065),Vector3(0.70,0.49,0.06),"3e6768")
	for slat in 5:
		_box(at+Vector3(0,-0.18+slat*0.09,0.11),Vector3(0.62,0.025,0.06),"547875")


func _chimney(at: Vector3) -> void:
	_box(at,Vector3(0.65,1.9,0.65),"985c43")
	for row in 8:
		_box(at+Vector3(0,-0.8+row*0.22,0.335),Vector3(0.65,0.018,0.02),"c6a582")
	_box(at+Vector3(0,0.97,0),Vector3(0.82,0.16,0.82),"ccc6ad")
	_box(at+Vector3(0,1.08,0),Vector3(0.44,0.1,0.44),"3f4541")


func _awning() -> void:
	for odd in 2:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("f0e5c7") if odd==0 else Color("6089ae")
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for strip in range(odd,14,2):
			var left := -width/2.0+0.3+strip*(width-0.6)/14.0
			var right := left+(width-0.6)/14.0
			var vertices := [Vector3(left,2.95,depth/2.0+0.08),Vector3(right,2.95,depth/2.0+0.08),Vector3(right,2.62,depth/2.0+1.05),Vector3(left,2.62,depth/2.0+1.05)]
			for index in [0,1,2,0,2,3]:
				tool.add_vertex(vertices[index])
			_box(Vector3((left+right)/2.0,2.52,depth/2.0+1.05),Vector3(right-left,0.2,0.04),"f0e5c7" if odd==0 else "6089ae")
		tool.generate_normals()
		var instance := MeshInstance3D.new()
		instance.name = "StraightAwning"
		instance.mesh = tool.commit()
		instance.material_override = material
		add_child(instance)
