extends RefCounted

const SITE := Vector2(-64, 315)
const HEALTH := 18
const HEARTS := 3
const ATTACKS := [
	{"name": "Sword sweep", "range": 10.0, "inner": 0.0, "width": 0.0, "damage": 1, "windup": 0.95},
	{"name": "Shield shockwave", "range": 24.0, "inner": 0.0, "width": 2.6, "damage": 1, "windup": 0.85},
	{"name": "Quake ring", "range": 22.0, "inner": 5.5, "width": 0.0, "damage": 1, "windup": 1.15},
]
const ENRAGED_ORDER := [1, 0, 2, 1]
const RECOVERY := 2.2
const ATLAS := "res://experiments/overworld_2d_v01/art/boss/stoneback.png"
const REGIONS := [
	Rect2(0, 0, 630, 545), Rect2(650, 0, 662, 545),
	Rect2(0, 545, 585, 654), Rect2(585, 545, 727, 654)
]
const FEET := [Vector2(351, 535), Vector2(371, 535), Vector2(322, 614), Vector2(456, 611)]

var phase := "idle"
var remaining := 0.0
var health := HEALTH
var atlas: Texture2D
var attack_index := 0
var next_attack := 0
var heading := Vector2.DOWN

func enraged() -> bool:
	return health <= HEALTH / 2

func attack() -> Dictionary:
	return ATTACKS[attack_index]

func attack_contains(offset: Vector2) -> bool:
	var pattern := attack()
	if pattern.width > 0.0:
		var forward := offset.dot(heading)
		return forward >= 0 and forward <= pattern.range and absf(offset.cross(heading)) <= pattern.width
	var distance := offset.length()
	return distance >= pattern.inner and distance <= pattern.range


func fighting() -> bool:
	return phase in ["guard", "warning", "sweep", "recover"]

func challenge() -> void:
	health = HEALTH
	attack_index = 0
	next_attack = 0
	set_phase("guard", 1.0)

func set_phase(next: String, seconds: float) -> void:
	phase = next
	remaining = seconds

func take_damage(damage: int) -> bool:
	if phase not in ["warning", "recover"] or damage <= 0:
		return false
	health = maxi(0, health - damage)
	if health == 0:
		phase = "defeated"
	return true

func tick(delta: float, player: Vector2, on_impact: Callable) -> void:
	if not fighting():
		return
	remaining -= delta
	if remaining > 0:
		return
	match phase:
		"guard":
			attack_index = ENRAGED_ORDER[next_attack % ENRAGED_ORDER.size()] if enraged() else next_attack % ATTACKS.size()
			next_attack += 1
			var aim := player - SITE
			heading = aim.normalized() if not aim.is_zero_approx() else Vector2.DOWN
			set_phase("warning", float(attack().windup) * (.82 if enraged() else 1.0))
		"warning":
			set_phase("sweep", .26)
			if attack_contains(player - SITE):
				on_impact.call(int(attack().damage))
		"sweep":
			set_phase("recover", RECOVERY * (.77 if enraged() else 1.0))
		"recover":
			set_phase("guard", .32 if enraged() else .55)
	return

func draw_sprite(canvas: Node2D, at: Vector2, depth: float, tint: Color) -> void:
	if atlas == null:
		atlas = load(ATLAS)
	var pose := ["guard", "warning", "sweep"].find(phase) + 1
	var size := clampf(900.0 * 8.3 / depth, 18, 410)
	var scale_factor := size / 535.0
	if phase == "defeated":
		tint = tint.darkened(.35)
	canvas.draw_set_transform(at, 0, Vector2(size * .33, size * .08))
	canvas.draw_circle(Vector2.ZERO, 1, Color(0.13, 0.17, 0.10, .35), true, -1, true)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_texture_rect_region(atlas, Rect2(at - FEET[pose] * scale_factor, REGIONS[pose].size * scale_factor), REGIONS[pose], tint)
