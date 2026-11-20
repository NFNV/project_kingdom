extends RefCounted
## Shared enemy readouts: parchment lettering, antique brass and warm red paint.
const UI := preload("res://experiments/anime_hub_demo_v07/tools/rpg_ui.gd")
const INK := Color("20372f")
const GOLD := Color("c6a366")
const IVORY := Color("f7e6c3")
const BLOOD := Color("b95e5c")
const HIGHLIGHT := Color("e3a18a")
const BOSS_FRAME := preload("res://experiments/anime_hub_demo_v07/assets/hud/boss_banner_v2.tres")
static var boss_fill: StyleBoxFlat

static func fraction(health: int, maximum: int) -> float:
	return clampf(float(health)/maxi(1,maximum),0,1)

static func text(canvas: CanvasItem, value: String, at: Vector2, width: float, size: int, color := IVORY, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var font := UI.heading_font()
	canvas.draw_string_outline(font,at,value,align,width,size,3,Color("162b27"))
	canvas.draw_string(font,at,value,align,width,size,color)

static func bar(canvas: CanvasItem, rect: Rect2, health: int, maximum: int, border := 1.0) -> void:
	canvas.draw_rect(Rect2(rect.position+Vector2(0,1.5),rect.size),Color(0.03,.05,.04,.55))
	canvas.draw_rect(rect,GOLD.darkened(.25))
	var inner := rect.grow(-border)
	canvas.draw_rect(inner,Color("382e31"))
	var fill := Rect2(inner.position,Vector2(inner.size.x*fraction(health,maximum),inner.size.y))
	if fill.size.x>0:
		canvas.draw_rect(fill,BLOOD)
		canvas.draw_line(fill.position,fill.position+Vector2(fill.size.x,0),HIGHLIGHT,maxf(.6,border),true)

static func mob(canvas: CanvasItem, at: Vector2, level: int, health: int, maximum: int) -> void:
	text(canvas,"Lv %d" % level,at+Vector2(-34,-7),68,12)
	bar(canvas,Rect2(at+Vector2(-29,0),Vector2(58,5)),health,maximum,.75)

static func boss(canvas: CanvasItem, rect: Rect2, title: String, level: int, health: int, maximum: int) -> void:
	canvas.draw_texture_rect(BOSS_FRAME,rect,false)
	var font := UI.heading_font()
	var title_size := roundi(rect.size.y*.255)
	var title_width := rect.size.x*.60
	while font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x>title_width and title_size>12:
		title_size -= 1
	# The name is centered on the entire banner, independent of level digits.
	boss_text(canvas,title,rect.position+rect.size*Vector2(.20,.53),title_width,title_size)
	var medal_width := rect.size.x*.073
	var medal_left := rect.position.x+rect.size.x*.123-medal_width*.5
	boss_text(canvas,"Lv",Vector2(medal_left,rect.position.y+rect.size.y*.345),medal_width,roundi(rect.size.y*.105),Color("d6be89"))
	boss_text(canvas,str(level),Vector2(medal_left,rect.position.y+rect.size.y*.565),medal_width,roundi(rect.size.y*.215))
	var track := Rect2(rect.position+rect.size*Vector2(.10,.714),rect.size*Vector2(.80,.072))
	var fill := Rect2(track.position,Vector2(track.size.x*fraction(health,maximum),track.size.y))
	if boss_fill==null:
		boss_fill = StyleBoxFlat.new()
		boss_fill.bg_color = Color("ba655c")
		boss_fill.set_corner_radius_all(3)
	if fill.size.x>0:
		canvas.draw_style_box(boss_fill,fill)
		if fill.size.x>4:
			canvas.draw_line(fill.position+Vector2(2,1.4),fill.position+Vector2(fill.size.x-2,1.4),Color("efb99c"),1.0,true)

static func boss_text(canvas: CanvasItem, value: String, at: Vector2, width: float, font_size: int, color := IVORY) -> void:
	var font := UI.heading_font()
	canvas.draw_string(font,at+Vector2(0,1.3),value,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,Color(.025,.06,.045,.8))
	canvas.draw_string(font,at,value,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,color)
