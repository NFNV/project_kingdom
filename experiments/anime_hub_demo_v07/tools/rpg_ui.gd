extends RefCounted
## Shared parchment, ink and brass treatment for the new RPG screens.
const INK := Color("2b423c")
const MUTED := Color("82765c")
const GOLD := Color("b89a61")
const PAPER := Color("f0e7d0")
const GREEN := Color("315b50")
static var serif: SystemFont

static func heading_font() -> Font:
	if serif==null:
		serif = SystemFont.new()
		serif.font_names = PackedStringArray(["Georgia","Baskerville","Noto Serif","serif"])
	return serif

static func style(dark := false, selected := false) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = Color("263f38") if dark else PAPER
	result.border_color = Color("e0bf79") if selected else GOLD.darkened(.2)
	result.set_border_width_all(3 if selected else 1)
	result.set_corner_radius_all(8)
	result.shadow_color = Color(0.05,.09,.06,.24)
	result.shadow_size = 5
	result.shadow_offset = Vector2(0,3)
	result.content_margin_left = 8
	result.content_margin_right = 8
	return result

static func panel(parent: Node, at: Vector2, dimensions: Vector2, dark := false) -> Panel:
	var result := Panel.new()
	result.position = at
	result.size = dimensions
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_stylebox_override("panel",style(dark))
	parent.add_child(result)
	return result

static func text(parent: Node, value: String, at: Vector2, width: float, font_size := 18, color := INK, heading := false) -> Label:
	var result := Label.new()
	result.text = value
	result.position = at
	result.size.x = width
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",color)
	if heading:
		result.add_theme_font_override("font",heading_font())
	parent.add_child(result)
	return result

static func button(parent: Node, value: String, at: Vector2, dimensions: Vector2) -> Button:
	var result := Button.new()
	result.text = value
	result.position = at
	result.size = dimensions
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_font_size_override("font_size",17)
	result.add_theme_color_override("font_color",Color("fff0ce"))
	result.add_theme_color_override("font_disabled_color",Color("c9c6ae"))
	for state in ["normal","hover","pressed","disabled"]:
		var box := style(true,state=="hover")
		box.bg_color = Color("476e59") if state=="hover" else (Color("626e5e") if state=="disabled" else GREEN)
		result.add_theme_stylebox_override(state,box)
	parent.add_child(result)
	return result

static func image(parent: Node, texture: Texture2D, at: Vector2, dimensions: Vector2) -> TextureRect:
	var result := TextureRect.new()
	result.position = at
	result.size = dimensions
	result.texture = texture
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

static func shade(parent: Control) -> void:
	var result := ColorRect.new()
	result.color = Color(.025,.055,.045,.76)
	result.size = Vector2(1920,1080)
	parent.add_child(result)
