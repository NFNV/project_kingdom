extends RefCounted
## Rendering pixels are independent of the authored map and HUD coordinates.
const LOGICAL_SIZE := Vector2i(1920,1080)
const RENDER_SIZE := Vector2i(2560,1440)
const SCALE := 4.0/3.0

static func configure(window: Window) -> void:
	# CanvasLayer controls do not inherit the world's CanvasItem filter.
	window.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	# UI canvases scale independently of the viewport, so bitmap glyphs would
	# otherwise be enlarged at fractional sizes (including the clock's 0.8 scale).
	var fallback := ThemeDB.fallback_font as FontFile
	if fallback and not fallback.multichannel_signed_distance_field:
		fallback.multichannel_signed_distance_field = true
	window.content_scale_size = RENDER_SIZE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_factor = 1.0
