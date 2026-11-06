extends RefCounted

const BASE_HEARTS := 3
const UNITS_PER_HEART := 2
const BASE_HEALTH := BASE_HEARTS * UNITS_PER_HEART
const EMPTY := preload("res://experiments/anime_hub_demo_v07/assets/field_ui/heart_empty.svg")
const FULL := preload("res://experiments/anime_hub_demo_v07/assets/field_ui/heart_full.svg")

static func amount(units: int) -> String:
	return str(units / 2) + (".5" if units % 2 else "")

static func draw_on(canvas: CanvasItem, at: Vector2, units: int, capacity: int, size := 40.0) -> void:
	for index in capacity / UNITS_PER_HEART:
		var rect := Rect2(at + Vector2(index * (size + 4), 0), Vector2.ONE * size)
		canvas.draw_texture_rect(EMPTY, rect, false)
		var fill := clampf((units - index * UNITS_PER_HEART) / float(UNITS_PER_HEART), 0, 1)
		if fill > 0:
			var source := Rect2(Vector2.ZERO, FULL.get_size() * Vector2(fill, 1))
			canvas.draw_texture_rect_region(FULL, Rect2(rect.position, rect.size * Vector2(fill, 1)), source)
