class_name KingdomProp
extends StaticBody2D

enum Kind { PINE, BIRCH, BUSH, ROCK }
@export var kind: Kind = Kind.PINE
@export_range(1, 4) var variant: int = 1


func _ready() -> void:
	var filename: String
	var cell: Vector2i
	var frame_count: int
	var foot_offset: float
	match kind:
		Kind.PINE:
			filename = "Terrain/Resources/Wood/Trees/Tree%d.png" % (1 + (variant - 1) % 2)
			cell = Vector2i(192, 256)
			frame_count = 8
			foot_offset = -116.0
		Kind.BIRCH:
			filename = "Terrain/Resources/Wood/Trees/Tree%d.png" % (3 + (variant - 1) % 2)
			cell = Vector2i(192, 192)
			frame_count = 8
			foot_offset = -84.0
		Kind.BUSH:
			filename = "Terrain/Decorations/Bushes/Bushe%d.png" % variant
			cell = Vector2i(128, 128)
			frame_count = 8
			foot_offset = -32.0
		Kind.ROCK:
			filename = "Terrain/Decorations/Rocks/Rock%d.png" % variant
			cell = Vector2i(64, 64)
			frame_count = 1
			foot_offset = -16.0
	var texture := load("res://assets/tiny_swords/" + filename) as Texture2D
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 10.0)
	for index in frame_count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(Vector2(index * cell.x, 0), Vector2(cell))
		frames.add_frame("default", frame)
	var visual: AnimatedSprite2D = $Visual
	visual.sprite_frames = frames
	visual.position.y = foot_offset
	visual.play()
	visual.frame = (int(position.x) + int(position.y)) % frame_count
	# Sharing a shape resource is safe because individual props don't mutate it.
	if kind == Kind.BUSH:
		$Footprint.disabled = true
