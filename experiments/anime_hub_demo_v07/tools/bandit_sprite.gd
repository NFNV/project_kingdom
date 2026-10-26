extends AnimatedSprite2D

const ROOT := "res://experiments/anime_hub_demo_v07/assets/bandits/"
const Style := preload("res://experiments/anime_hub_demo_v07/tools/art_style.gd")
static var resources: Dictionary = {}
static var meshes: Dictionary = {}
var actor_id := "raider"
var facing_direction := "se"
var display_height := 73.0
var state := "idle"
var phase := 0.0
var clock := 0.0
var body: Polygon2D
var current_key := ""
var pose_index := 0

static func bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0],Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect

func configure(role: String, height: float) -> void:
	actor_id = role
	display_height = height
	material = Style.character_material()
	if not resources.has(role):
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+role+"_catalog.json"))
		var image := Image.load_from_file(ProjectSettings.globalize_path(ROOT+catalog.asset))
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image,.70)
		var contours := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),1.2)
		var shapes: Dictionary = {}
		for direction in catalog.directions:
			var entries: Array[PackedVector2Array] = []
			for pose in catalog.directions[direction]:
				var center := Vector2(pose.region[0]+pose.region[2]*.5,pose.region[1]+pose.region[3]*.5)
				var closest := INF
				var selected := PackedVector2Array()
				for contour in contours:
					var rect := bounds(contour)
					if rect.size.y<80 or rect.size.x<50:
						continue
					var distance := rect.get_center().distance_squared_to(center)
					if distance<closest:
						closest = distance
						selected = contour
				entries.append(selected)
			shapes[direction] = entries
		image.generate_mipmaps()
		resources[role] = {"catalog":catalog,"texture":ImageTexture.create_from_image(image),"shapes":shapes}
	body = Polygon2D.new()
	body.texture = resources[role].texture
	body.use_parent_material = true
	add_child(body)
	# Register every view once at zone load, so the first attack/hurt pose cannot
	# trigger polygon tessellation in the middle of a fight.
	for heading in ["se","sw","ne","nw"]:
		for index in 8:
			_mesh(heading,index)
	set_pose("idle","se",0)

func direction_for(vector: Vector2) -> String:
	if vector.length_squared()<.01:
		return facing_direction
	return ("se" if vector.x>=0 else "sw") if vector.y>=0 else ("ne" if vector.x>=0 else "nw")

func tick(delta: float, distance: float, vector: Vector2, _running := false) -> void:
	clock += delta
	var heading := direction_for(vector)
	if distance>.025:
		phase = fposmod(phase+distance/65.0,1.0)
		set_pose("walk",heading,[1,2,3,2][int(phase*4)%4])
	else:
		set_pose("idle",heading,0)
	body.scale = Vector2(1.0,1.0+sin(clock*1.6)*.0015)

func set_pose(next_state: String, heading: String, index: int, _delta := 0.0) -> void:
	state = next_state
	facing_direction = heading if heading in ["se","sw","ne","nw"] else "se"
	pose_index = index
	var key := facing_direction+"/"+str(index)
	if current_key==key:
		return
	current_key = key
	var mesh := _mesh(facing_direction,index)
	body.uv = mesh.uv
	body.polygon = mesh.points
	body.polygons = mesh.faces
	body.scale = Vector2.ONE

func _mesh(heading: String, index: int) -> Dictionary:
	var key := actor_id+"/"+heading+"/"+str(index)+"/"+str(display_height)
	if meshes.has(key):
		return meshes[key]
	var poses: Array = resources[actor_id].catalog.directions[heading]
	var data: Dictionary = poses[index]
	var reference: Dictionary = poses[0]
	var base := display_height/float(reference.region[3])
	# Small pigment/ear differences must not make bodies swell between poses.
	var factor := base*clampf(float(reference.head_width)/float(data.head_width),.96,1.04)
	var uv: PackedVector2Array = resources[actor_id].shapes[heading][index]
	var points := PackedVector2Array()
	for point in uv:
		points.append((point-Vector2(data.head_x,data.foot_y))*factor)
	var triangles := Geometry2D.triangulate_polygon(points)
	var faces: Array[PackedInt32Array] = []
	for at in range(0,triangles.size(),3):
		faces.append(PackedInt32Array([triangles[at],triangles[at+1],triangles[at+2]]))
	var mesh := {"points":points,"uv":uv,"faces":faces}
	meshes[key] = mesh
	return mesh
