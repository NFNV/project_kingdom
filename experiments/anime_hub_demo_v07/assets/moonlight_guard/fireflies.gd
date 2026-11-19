@tool
extends Node2D
## One batched draw for animated painted insects. Clock is supplied by the host.
const ROOT := "res://experiments/anime_hub_demo_v07/assets/moonlight_guard/"
@export var area := Rect2(0,0,1920,1080):
	set(value):
		area = value
		if is_inside_tree(): rebuild()
@export_range(1,256) var amount := 80:
	set(value):
		amount = clampi(value,1,256)
		if is_inside_tree(): rebuild()
@export var pattern_seed := 1729:
	set(value):
		pattern_seed = value
		if is_inside_tree(): rebuild()
@export var insect_size := Vector2(7,13):
	set(value):
		insect_size = Vector2(maxf(1,value.x),maxf(value.x,value.y))
		if is_inside_tree(): rebuild()
@export_range(0,1) var night_weight := 0.0:
	set(value):
		night_weight = clampf(value,0,1)
		visible = night_weight>.005
		if is_instance_valid(batch): batch.material.set_shader_parameter("night_weight",night_weight)
		if is_instance_valid(glow_batch): glow_batch.material.set_shader_parameter("night_weight",night_weight)
@export_range(0,1) var ground_glow := 0.0:
	set(value):
		ground_glow = clampf(value,0,1)
		if is_instance_valid(glow_batch):
			glow_batch.visible = ground_glow>0
			glow_batch.material.set_shader_parameter("glow_strength",ground_glow)
var boundary := PackedVector2Array()
var batch: MultiMeshInstance2D
var glow_batch: MultiMeshInstance2D
var motes: Array[Dictionary] = []
var elapsed := 0.0

func _ready() -> void:
	# These ambient particles update every render frame, independently of physics.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	batch = MultiMeshInstance2D.new()
	batch.texture = load(ROOT+"firefly_flutter.png")
	batch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var material := ShaderMaterial.new()
	material.shader = preload("res://experiments/anime_hub_demo_v07/assets/moonlight_guard/fireflies.gdshader")
	batch.material = material
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_2D
	instances.use_custom_data = true
	instances.mesh = mesh
	instances.instance_count = amount
	batch.multimesh = instances
	add_child(batch)
	# Share the same instance transforms: one extra batch, no per-insect lights.
	glow_batch = MultiMeshInstance2D.new()
	glow_batch.multimesh = instances
	glow_batch.z_index = -5
	var glow_material := ShaderMaterial.new()
	glow_material.shader = preload("res://experiments/anime_hub_demo_v07/assets/moonlight_guard/firefly_ground_glow.gdshader")
	glow_batch.material = glow_material
	add_child(glow_batch)
	ground_glow = ground_glow
	rebuild()
	night_weight = night_weight

func rebuild() -> void:
	if not is_instance_valid(batch): return
	motes.clear()
	batch.multimesh.instance_count = amount
	var random := RandomNumberGenerator.new()
	random.seed = pattern_seed
	for index in amount:
		var at := Vector2.ZERO
		for attempt in 100:
			at = area.position+Vector2(random.randf(),random.randf())*area.size
			if boundary.is_empty() or Geometry2D.is_point_in_polygon(at,boundary): break
		var phase := random.randf()
		var size := random.randf_range(insect_size.x,insect_size.y)
		motes.append({"at":at,"phase":phase*TAU,"size":size,"speed":random.randf_range(.25,.65)})
		batch.multimesh.set_instance_custom_data(index,Color(phase,random.randf(),0,1))
	update_motes()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or night_weight<=.005: return
	elapsed += delta
	update_motes()

func update_motes() -> void:
	for index in motes.size():
		var mote: Dictionary = motes[index]
		var drift := Vector2(sin(elapsed*mote.speed+mote.phase)*18,cos(elapsed*mote.speed*.8+mote.phase)*10)
		var transform := Transform2D(0,Vector2.ONE*float(mote.size),0,mote.at+drift)
		batch.multimesh.set_instance_transform_2d(index,transform)
