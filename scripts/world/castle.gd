class_name KingdomCastle
extends Node2D

signal captured
enum State { LOCKED, READY, CAPTURING, CONTESTED, CAPTURED }

@export var capture_seconds: float = 5.0
@export var capture_radius: float = 112.0
var owner_faction: KingdomActor.Faction = KingdomActor.Faction.DOG
var state: State = State.LOCKED
var progress: float = 0.0
var player: KingdomActor
var defenders: Array[KingdomActor] = []
var pulse: float = 0.0
const ZONE_OFFSET := Vector2(0, 180)


func capture_position() -> Vector2:
	return global_position + ZONE_OFFSET


func remaining_defenders() -> int:
	var count := 0
	for defender in defenders:
		if is_instance_valid(defender) and not defender.health.is_dead():
			count += 1
	return count


func _physics_process(delta: float) -> void:
	pulse += delta
	advance_capture(delta)
	queue_redraw()


func advance_capture(delta: float) -> void:
	if state == State.CAPTURED:
		return
	if remaining_defenders() > 0:
		state = State.LOCKED
		progress = 0.0
		return
	state = State.READY
	if not is_instance_valid(player) or player.health.is_dead():
		progress = 0.0
		return
	if player.global_position.distance_to(capture_position()) > capture_radius:
		progress = 0.0
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is KingdomActor and enemy.faction != player.faction and not enemy.health.is_dead():
			if enemy.global_position.distance_to(capture_position()) < capture_radius + 40.0:
				state = State.CONTESTED
				progress = 0.0
				return
	state = State.CAPTURING
	progress = minf(1.0, progress + delta / capture_seconds)
	if progress >= 1.0:
		state = State.CAPTURED
		owner_faction = player.faction
		var color_name := KingdomActor.faction_building_color(owner_faction)
		$Keep.texture = load("res://assets/tiny_swords/Buildings/%s Buildings/Castle.png" % color_name) as Texture2D
		captured.emit()


func _draw() -> void:
	var color := Color("ebbd71")
	if state == State.LOCKED or state == State.CONTESTED:
		color = Color("d17e63")
	elif state == State.CAPTURED:
		color = KingdomActor.faction_color(owner_faction)
	draw_circle(ZONE_OFFSET, capture_radius, Color(color, 0.055))
	draw_arc(ZONE_OFFSET, capture_radius, 0, TAU, 64, Color(color, 0.6), 2)
	if progress > 0.0:
		draw_arc(ZONE_OFFSET, capture_radius - 7, -PI / 2.0, -PI / 2.0 + TAU * progress, 64, color, 5)
	var flag_color := Color("bd574e") if owner_faction == KingdomActor.Faction.CAT else Color("5294bb")
	var flag_base := ZONE_OFFSET + Vector2(-145, -4)
	draw_ellipse_shadow(flag_base)
	draw_line(flag_base, flag_base + Vector2(0, -92), Color("594c3f"), 5)
	draw_line(flag_base + Vector2(-1, -92), flag_base + Vector2(-1, -2), Color("d5ba82"), 2)
	var wave := sin(pulse * 3.0) * 2.0
	var cloth := PackedVector2Array([flag_base + Vector2(2, -89), flag_base + Vector2(43, -85 + wave),
		flag_base + Vector2(35, -71 + wave), flag_base + Vector2(43, -57 + wave), flag_base + Vector2(2, -62)])
	draw_colored_polygon(cloth, flag_color)
	draw_polyline(PackedVector2Array([cloth[0], cloth[1], cloth[2], cloth[3], cloth[4]]), Color("efd79b"), 2)
	var font := ThemeDB.fallback_font
	var title := "WILLOW KEEP"
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_style_box(_plaque(), Rect2(-width / 2.0 - 16, -282, width + 32, 34))
	draw_string(font, Vector2(-width / 2.0, -258), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e9dcaf"))


func draw_ellipse_shadow(point: Vector2) -> void:
	draw_set_transform(point, 0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 13, Color(0.12, 0.2, 0.15, 0.3))
	draw_set_transform(Vector2.ZERO)


func _plaque() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.18, 0.17, 0.9)
	style.border_color = Color("77805e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style
