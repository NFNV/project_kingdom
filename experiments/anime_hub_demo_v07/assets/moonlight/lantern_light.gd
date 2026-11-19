extends Node2D
## Painted environments use additive light pools rather than shaded 2D lights.
const LIGHT := preload("res://experiments/anime_hub_demo_v07/assets/moonlight/lantern_light.gdshader")
@export var lamp_height := 150.0
@export_range(0,1) var night_weight := 0.0:
	set(value):
		night_weight = clampf(value,0,1)
		visible = night_weight>.005
		for layer in [ground,halo]:
			if is_instance_valid(layer): layer.material.set_shader_parameter("night_weight",night_weight)
var ground: MeshInstance2D
var halo: MeshInstance2D

func _ready() -> void:
	ground = light_layer(Vector2(360,200),Vector2.ZERO,.6,0.0,-2)
	# Match the glass chamber in the existing street-lamp painting.
	halo = light_layer(Vector2(65,65),Vector2(0,-lamp_height*.79),.55,1.2,2)
	night_weight = night_weight

func light_layer(size: Vector2, at: Vector2, energy: float, core: float, depth: int) -> MeshInstance2D:
	var layer := MeshInstance2D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	layer.mesh = mesh
	layer.position = at
	layer.z_index = depth
	var material := ShaderMaterial.new()
	material.shader = LIGHT
	material.set_shader_parameter("energy",energy)
	material.set_shader_parameter("core",core)
	layer.material = material
	add_child(layer)
	return layer
