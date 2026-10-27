extends Button
const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
const Art := preload("res://experiments/anime_hub_demo_v07/tools/equipment_art.gd")
var view: Control
var item_id := ""
var origin := "bag"
var equipment_slot := ""
var quantity := 0

func configure(id: String, where: String, slot := "", amount := 0) -> void:
	item_id = id
	origin = where
	equipment_slot = slot
	quantity = amount
	focus_mode = Control.FOCUS_NONE
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_constant_override("icon_max_width",72)
	icon = Art.icon(id,view.hub.state.definitions) if id!="" else (Art.ghost(slot) if slot!="" else null)
	tooltip_text = view.hub.state.definitions[id].name if id!="" else (view.hub.state.SLOT_NAMES[slot]+" · drag a matching item here" if slot!="" else "Backpack")
	add_theme_color_override("icon_normal_color",Color.WHITE if id!="" else Color(.8,.76,.61,.42))
	mark(false)
	queue_redraw()

func mark(value: bool) -> void:
	for state in ["normal","hover","pressed"]:
		add_theme_stylebox_override(state,UI.style(true,value or state=="hover"))

func _draw() -> void:
	if quantity>1:
		var value := str(quantity)
		draw_string_outline(ThemeDB.fallback_font,Vector2(size.x-29,size.y-9),value,HORIZONTAL_ALIGNMENT_RIGHT,24,15,4,Color("243c35"))
		draw_string(ThemeDB.fallback_font,Vector2(size.x-29,size.y-9),value,HORIZONTAL_ALIGNMENT_RIGHT,24,15,Color("ffebbc"))

func _get_drag_data(_at: Vector2) -> Variant:
	if item_id=="":
		return null
	var preview := TextureRect.new()
	preview.texture = icon
	preview.size = Vector2(72,72)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"item":item_id,"origin":origin,"slot":equipment_slot}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if not data is Dictionary or not data.get("item") is String or not view.hub.state.definitions.has(data.item):
		return false
	if origin=="equipped":
		return data.get("origin")=="bag" and view.hub.state.definitions[data.item].get("slot","")==equipment_slot
	return data.get("origin")=="equipped" and data.get("slot") in view.hub.state.SLOTS

func _drop_data(_at: Vector2, data: Variant) -> void:
	if origin=="equipped":
		view.equip(data.item,equipment_slot)
	else:
		view.unequip(data.slot)
