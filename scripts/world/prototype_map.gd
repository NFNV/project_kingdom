class_name KingdomMap
extends Node2D

const WORLD_SIZE := Vector2i(2560, 1792)
const TILE_SIZE := 64
const PROP_SCENE := preload("res://scenes/world/forest_prop.tscn")
const ROAD := [Vector2(455, 1395), Vector2(650, 1300), Vector2(815, 1220),
	Vector2(1020, 1110), Vector2(1150, 950), Vector2(1390, 855),
	Vector2(1600, 760), Vector2(1775, 680), Vector2(1930, 680)]

var navigation := AStarGrid2D.new()
var land: Dictionary = {}
var obstacles: Array[Rect2] = []
@onready var entities: Node2D = $Entities
@onready var castle: KingdomCastle = $Entities/Castle


func _ready() -> void:
	_build_terrain()
	_build_forest()
	_build_outpost()
	obstacles.append(Rect2(1790, 385, 280, 130))
	_build_navigation()
	$Trail.draw.connect(_draw_trail)
	queue_redraw()
	$Trail.queue_redraw()


func _build_terrain() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tiny_swords/Terrain/Tileset/Tilemap_color2.png") as Texture2D
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in 3:
		for x in 3:
			atlas.create_tile(Vector2i(x, y))
	tiles.add_source(atlas, 0)
	var ground: TileMapLayer = $Ground
	ground.tile_set = tiles
	for y in range(2, 26):
		for x in range(2, 38):
			if (x < 4 and y < 4) or (x > 35 and y < 4):
				continue
			if (x < 4 and y > 23) or (x > 35 and y > 23):
				continue
			land[Vector2i(x, y)] = true
	for cell: Vector2i in land:
		var atlas_cell := Vector2i(1, 1)
		if not land.has(cell + Vector2i.LEFT):
			atlas_cell.x = 0
		elif not land.has(cell + Vector2i.RIGHT):
			atlas_cell.x = 2
		if not land.has(cell + Vector2i.UP):
			atlas_cell.y = 0
		elif not land.has(cell + Vector2i.DOWN):
			atlas_cell.y = 2
		ground.set_cell(cell, 0, atlas_cell)
		# Border collision is separate from drawing, so actors cannot enter water.
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not land.has(cell + direction):
				var edge_center := Vector2(cell * TILE_SIZE) + Vector2(32, 32) + Vector2(direction) * 36.0
				var size := Vector2(64, 10) if direction.y != 0 else Vector2(10, 64)
				_add_wall(edge_center, size)


func _add_wall(center: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = center
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)


func _build_forest() -> void:
	# Authored groves leave a continuous route and generous combat clearings.
	var pines: Array[Vector2] = [
		Vector2(260, 410), Vector2(390, 355), Vector2(530, 400), Vector2(675, 340),
		Vector2(810, 385), Vector2(960, 335), Vector2(1100, 390), Vector2(1240, 325),
		Vector2(1370, 380), Vector2(1510, 340), Vector2(1635, 390), Vector2(2180, 375),
		Vector2(2290, 470), Vector2(2300, 660), Vector2(2250, 850), Vector2(2320, 1050),
		Vector2(2250, 1250), Vector2(2300, 1450), Vector2(2140, 1590),
		Vector2(1950, 1590), Vector2(1780, 1580), Vector2(1595, 1600),
		Vector2(1400, 1580), Vector2(1220, 1600), Vector2(1020, 1580),
		Vector2(830, 1610), Vector2(650, 1600), Vector2(260, 1530),
		Vector2(230, 1335), Vector2(245, 1130), Vector2(220, 925),
		Vector2(270, 735), Vector2(245, 550),
		Vector2(505, 700), Vector2(640, 620), Vector2(760, 720),
		Vector2(550, 940), Vector2(700, 900), Vector2(870, 840),
		Vector2(1080, 610), Vector2(1230, 570), Vector2(1370, 600),
		Vector2(1530, 500), Vector2(1890, 1090), Vector2(2050, 1040),
		Vector2(1730, 1240), Vector2(1845, 1390), Vector2(2050, 1320),
		Vector2(1270, 1340), Vector2(1430, 1260), Vector2(1490, 1440)]
	for index in pines.size():
		_add_prop(pines[index], KingdomProp.Kind.PINE if index % 3 != 0 else KingdomProp.Kind.BIRCH, index % 4 + 1)
	var bushes: Array[Vector2] = [Vector2(340, 470), Vector2(850, 500), Vector2(1150, 400),
		Vector2(1540, 450), Vector2(2130, 690), Vector2(2180, 970), Vector2(1590, 1140),
		Vector2(1460, 1380), Vector2(1010, 1430), Vector2(780, 1410), Vector2(390, 1500),
		Vector2(385, 1010), Vector2(790, 980), Vector2(1340, 1090), Vector2(1980, 1480)]
	for index in bushes.size():
		_add_prop(bushes[index], KingdomProp.Kind.BUSH, index % 4 + 1)
	var rocks: Array[Vector2] = [Vector2(410, 900), Vector2(895, 630), Vector2(1510, 1040),
		Vector2(1790, 970), Vector2(2120, 850), Vector2(1180, 1460), Vector2(340, 620)]
	for index in rocks.size():
		_add_prop(rocks[index], KingdomProp.Kind.ROCK, index % 4 + 1)


func _add_prop(point: Vector2, kind: KingdomProp.Kind, variant: int) -> void:
	var prop := PROP_SCENE.instantiate() as KingdomProp
	prop.position = point
	prop.kind = kind
	prop.variant = variant
	entities.add_child(prop)
	if kind != KingdomProp.Kind.BUSH:
		obstacles.append(Rect2(point + Vector2(-24, -34), Vector2(48, 48)))


func _build_outpost() -> void:
	_add_building("House1", Vector2(355, 1300), Vector2(128, 192), Vector2(0, -72), Rect2(310, 1245, 90, 58))
	_add_building("Tower", Vector2(390, 1115), Vector2(128, 256), Vector2(0, -98), Rect2(350, 1065, 80, 55))


func _add_building(filename: String, point: Vector2, _size: Vector2,
		offset: Vector2, footprint: Rect2) -> void:
	var building := StaticBody2D.new()
	building.position = point
	building.collision_layer = 1
	building.collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/tiny_swords/Buildings/Red Buildings/%s.png" % filename) as Texture2D
	sprite.position = offset
	building.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = footprint.size
	collision.shape = shape
	collision.position = footprint.get_center() - point
	building.add_child(collision)
	entities.add_child(building)
	obstacles.append(footprint)


func _build_navigation() -> void:
	navigation.region = Rect2i(Vector2i.ZERO, WORLD_SIZE / 32)
	navigation.cell_size = Vector2(32, 32)
	navigation.offset = Vector2(16, 16)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in navigation.region.size.y:
		for x in navigation.region.size.x:
			var cell := Vector2i(x, y)
			var point := Vector2(cell * 32) + Vector2(16, 16)
			var blocked := not land.has(Vector2i(floori(point.x / 64), floori(point.y / 64)))
			for obstacle in obstacles:
				if obstacle.grow(19.0).has_point(point):
					blocked = true
					break
			navigation.set_point_solid(cell, blocked)


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := _walkable_cell(from)
	var finish := _walkable_cell(to)
	if start.x < 0 or finish.x < 0:
		return PackedVector2Array()
	return navigation.get_point_path(start, finish)


func _walkable_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i(floori(point.x / 32), floori(point.y / 32))
	for radius in range(0, 5):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, y)
				if navigation.is_in_boundsv(candidate) and not navigation.is_point_solid(candidate):
					return candidate
	return Vector2i(-1, -1)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(WORLD_SIZE)), Color("426b70"))
	# Quiet water marks sit under the island rather than competing with the road.
	for index in 140:
		var point := Vector2((index * 193 + 37) % WORLD_SIZE.x, (index * 317 + 29) % WORLD_SIZE.y)
		draw_line(point, point + Vector2(16 + index % 21, 0), Color(0.58, 0.77, 0.74, 0.16), 2)
	for cell: Vector2i in land:
		draw_rect(Rect2(Vector2(cell * TILE_SIZE) + Vector2(0, 12), Vector2(64, 64)), Color("2f5355"))


func _draw_trail() -> void:
	var trail: Node2D = $Trail
	var points := PackedVector2Array(ROAD)
	trail.draw_polyline(points, Color("829b59"), 92.0, false)
	for point in ROAD:
		trail.draw_circle(point, 46.0, Color("829b59"))
	trail.draw_polyline(points, Color("acb37b"), 80.0, false)
	for point in ROAD:
		trail.draw_circle(point, 40.0, Color("acb37b"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 771
	for index in 270:
		var segment := index % (ROAD.size() - 1)
		var point: Vector2 = ROAD[segment].lerp(ROAD[segment + 1], rng.randf())
		point += Vector2(rng.randf_range(-27, 27), rng.randf_range(-27, 27))
		trail.draw_rect(Rect2(point.round(), Vector2(3, 2)), Color("88935e"))
	# Clearing and flagstone-like marks at the keep's approach.
	trail.draw_circle(Vector2(1930, 680), 137.0, Color("799555"))
	trail.draw_circle(Vector2(1930, 680), 123.0, Color("9fa76d"))
	for index in 14:
		var angle := TAU * index / 14.0
		var point := Vector2(1930, 680) + Vector2.from_angle(angle) * 130.0
		trail.draw_rect(Rect2(point.round() - Vector2(5, 3), Vector2(10, 6)), Color("ced0a0"))
