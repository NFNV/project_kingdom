@tool
extends RefCounted

const Ink := preload("res://experiments/anime_3d_concept_v01/ink.gdshader")
const Cel := preload("res://experiments/anime_3d_concept_v01/cel.gdshader")

static func paint(hex: String, tabby := false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = Cel
	material.set_shader_parameter("pigment", Color(hex))
	material.set_shader_parameter("tabby", tabby)
	return material


static func ink(material: Material, color: Color, width: float) -> void:
	var outline := ShaderMaterial.new()
	outline.shader = Ink
	outline.set_shader_parameter("ink",color)
	outline.set_shader_parameter("width",width)
	material.next_pass = outline


static func piece(parent: Node3D, title: String, geometry: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = geometry
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node


static func ball(parent: Node3D, title: String, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var geometry := SphereMesh.new()
	geometry.radial_segments = 32
	geometry.rings = 16
	var node := piece(parent, title, geometry, material, at)
	node.scale = radii * 2.0
	return node


static func box(parent: Node3D, title: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var geometry := BoxMesh.new()
	geometry.size = size
	return piece(parent, title, geometry, material, at)


static func limb(parent: Node3D, title: String, start: Vector3, end: Vector3, radius: float, depth: float, material: Material) -> MeshInstance3D:
	var axis := end - start
	var node := ball(parent, title, (start + end) * .5, Vector3(radius, axis.length() * .5 + radius * .55, depth), material)
	node.quaternion = Quaternion(Vector3.UP, axis.normalized())
	return node


# Each ring stores its center followed by horizontal and depth radii.
static func loft(parent: Node3D, title: String, rings: Array, material: Material) -> MeshInstance3D:
	var sections: Array[PackedVector3Array] = []
	const subdivisions := 4
	for index in (rings.size()-1)*subdivisions+1:
		var left := mini(floori(float(index)/subdivisions),rings.size()-2)
		var t := float(index-left*subdivisions)/subdivisions
		var a: Array = rings[left]
		var b: Array = rings[left+1]
		var before: Array = rings[maxi(0,left-1)]
		var after: Array = rings[mini(left+2,rings.size()-1)]
		var center: Vector3 = a[0].lerp(b[0],t)
		var radii := Vector2(a[1],a[2]).cubic_interpolate(Vector2(b[1],b[2]),Vector2(before[1],before[2]),Vector2(after[1],after[2]),t)
		var section := PackedVector3Array()
		for step in 40:
			var angle := TAU * step / 40.0
			section.append(center + Vector3(cos(angle)*maxf(radii.x,.002),0,sin(angle)*maxf(radii.y,.002)))
		sections.append(section)
	return piece(parent, title, skin(sections), material, Vector3.ZERO)


static func curve(parent: Node3D, title: String, points: PackedVector3Array, radius: float, material: Material, tip := 0.6) -> MeshInstance3D:
	var sections: Array[PackedVector3Array] = []
	var spine := PackedVector3Array()
	for index in points.size()-1:
		for step in 3:
			spine.append(points[index].cubic_interpolate(points[index+1],points[maxi(0,index-1)],points[mini(index+2,points.size()-1)],step/3.0))
	spine.append(points[-1])
	for index in spine.size():
		var tangent := (spine[mini(index+1, spine.size()-1)] - spine[maxi(0, index-1)]).normalized()
		var side := tangent.cross(Vector3.FORWARD).normalized()
		if side.is_zero_approx():
			side = Vector3.RIGHT
		var up := tangent.cross(side)
		var size := radius * lerpf(1.0, tip, float(index) / (spine.size()-1))
		var section := PackedVector3Array()
		for step in 12:
			var angle := TAU * step / 12.0
			section.append(spine[index] + size * (side * cos(angle) + up * sin(angle)))
		sections.append(section)
	return piece(parent, title, skin(sections, true), material, Vector3.ZERO)


static func skin(sections: Array[PackedVector3Array], reverse := false) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var width := sections[0].size()
	for row in sections.size() - 1:
		for column in width:
			var next := (column + 1) % width
			var a := sections[row][column]
			var b := sections[row][next]
			var c := sections[row + 1][column]
			var d := sections[row + 1][next]
			for vertex: Vector3 in ([a,c,b,b,c,d] if reverse else [a,b,c,b,d,c]):
				surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()


static func cylinder(parent: Node3D, title: String, at: Vector3, top: float, bottom: float, height: float, material: Material, sides := 32) -> MeshInstance3D:
	var geometry := CylinderMesh.new()
	geometry.top_radius = top
	geometry.bottom_radius = bottom
	geometry.height = height
	geometry.radial_segments = sides
	return piece(parent, title, geometry, material, at)
