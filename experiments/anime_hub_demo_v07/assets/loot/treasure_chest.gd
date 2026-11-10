extends Node2D
## A reusable chest prop. The encounter owns interaction and loot.

@export var display_width := 108.0
@export var closed_texture: Texture2D
@export var opened_texture: Texture2D
var opened := false

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	reset()

func reset() -> void:
	opened = false
	show_pose(closed_texture)

func open() -> void:
	opened = true
	show_pose(opened_texture)

func show_pose(texture: Texture2D) -> void:
	sprite.texture = texture
	sprite.scale = Vector2.ONE * display_width / texture.get_width()
	sprite.offset = Vector2(0, 4.0 - texture.get_height() / 2.0)

func _draw() -> void:
	draw_set_transform(Vector2(0, -7), 0, Vector2(display_width * .49, display_width * .14))
	draw_circle(Vector2.ZERO, 1, Color(.16, .12, .10, .28), true, -1, true)
