extends Polygon2D

const ROOT := "res://experiments/anime_hub_demo_v07/assets/combat/"
static var cached_shapes: Dictionary = {}
var poses: Dictionary
var current_pose := -1
var current_direction := ""

static func bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0],Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect

func _ready() -> void:
	poses = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json"))["directions"]
	texture = load(ROOT+"cat_sword_attack.png")
	if cached_shapes.is_empty():
		var image := Image.load_from_file(ProjectSettings.globalize_path(ROOT+"cat_sword_attack.png"))
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image,.86)
		var shapes := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),1.0)
		for direction in poses:
			var frames: Array[PackedVector2Array] = []
			for entry in poses[direction]:
				var center := Vector2(entry.region[0]+entry.region[2]*.5,entry.region[1]+entry.region[3]*.5)
				var closest := INF
				var selected := PackedVector2Array()
				for shape in shapes:
					if shape.size()<4:
						continue
					var rect := bounds(shape)
					if rect.size.x<70 or rect.size.y<100:
						continue
					var distance := rect.get_center().distance_squared_to(center)
					if distance<closest:
						closest = distance
						selected = shape
				frames.append(selected)
			cached_shapes[direction] = frames

func pose(facing: Vector2, progress: float, power: bool) -> void:
	var direction := ("se" if facing.x>=0 else "sw") if facing.y>=0 else ("ne" if facing.x>=0 else "nw")
	var first := .34 if power else .28
	var index := 0 if progress<first else (1 if progress<.53 else (2 if progress<.78 else 3))
	if current_pose!=index or current_direction!=direction:
		current_pose = index
		current_direction = direction
		var data: Dictionary = poses[direction][index]
		uv = cached_shapes[direction][index]
		var points := PackedVector2Array()
		for point in uv:
			points.append(point-Vector2(data.foot_x,data.foot_y))
		polygon = points
		scale = Vector2.ONE*data.display_scale
	position = Vector2(facing.x,facing.y*.65)*sin(progress*PI)*1.4
